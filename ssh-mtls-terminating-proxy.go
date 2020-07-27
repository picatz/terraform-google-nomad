package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"os"
	"os/exec"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"
)

type terraformOutputNode struct {
	Senstive bool   `json:"senstive"`
	Type     string `json:"type"`
	Value    string `json:"value"`
}

type terraformOutput struct {
	BastionPublicIP      terraformOutputNode `json:"bastion_public_ip"`
	BastionSSHPrivateKey terraformOutputNode `json:"bastion_ssh_private_key"`
	BastionSSHPublicKey  terraformOutputNode `json:"bastion_ssh_public_key"`
	NomadServerIP        terraformOutputNode `json:"server_internal_ip"`
	CACert               terraformOutputNode `json:"nomad_ca_cert"`
	CLICert              terraformOutputNode `json:"nomad_cli_cert"`
	CLIKey               terraformOutputNode `json:"nomad_cli_key"`
}

func getTerraformOutput() (*terraformOutput, error) {
	cmd := exec.Command("terraform", "output", "-json")
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(output))
		return nil, err
	}

	var tfOutput terraformOutput

	err = json.Unmarshal(output, &tfOutput)
	if err != nil {
		return nil, err
	}

	return &tfOutput, nil
}

var (
	nomadServerIP       string
	nomadBastionIP      string
	nomadBastionPrivKey string
	nomadCACert         string
	nomadCLICert        string
	nomadCLIKey         string
)

func errorAndExit(mesg interface{}) {
	fmt.Println(mesg)
	os.Exit(1)
}

func readFileContent(file string) string {
	f, err := os.Open(file)
	if err != nil {
		errorAndExit(err)
	}
	defer f.Close()

	bytes, err := ioutil.ReadAll(f)
	if err != nil {
		errorAndExit(err)
	}
	return string(bytes)
}

func init() {
	if len(os.Args) <= 1 {
		log.Println("Getting Terraform Output")
		tfOutput, err := getTerraformOutput()
		if err != nil {
			errorAndExit(err)
		}

		nomadBastionIP = tfOutput.BastionPublicIP.Value
		nomadServerIP = tfOutput.NomadServerIP.Value
		nomadBastionPrivKey = tfOutput.BastionSSHPrivateKey.Value
		nomadCACert = tfOutput.CACert.Value
		nomadCLICert = tfOutput.CLICert.Value
		nomadCLIKey = tfOutput.CLIKey.Value
	} else {
		var (
			nomadBastionSSHFile string
			nomadCACertFile     string
			nomadCLICertFile    string
			nomadCLIKeyFile     string
		)

		flag.StringVar(&nomadServerIP, "server-ip", "", "internal Nomad server IP")
		flag.StringVar(&nomadBastionIP, "bastion-ip", "", "external Nomad bastion IP")
		flag.StringVar(&nomadCACertFile, "ca-file", "", "mTLS certifcate authority file")
		flag.StringVar(&nomadCLICertFile, "cert-file", "", "mTLS client cert file")
		flag.StringVar(&nomadCLIKeyFile, "key-file", "", "mTLS client key file")

		flag.Parse()

		nomadBastionPrivKey = readFileContent(nomadBastionSSHFile)
		nomadCACert = readFileContent(nomadCACertFile)
		nomadCLICert = readFileContent(nomadCLICertFile)
		nomadCLIKey = readFileContent(nomadCLIKeyFile)
	}

	log.Printf("Bastion IP: %q", nomadBastionIP)
	log.Printf("Server IP: %q", nomadServerIP)
}

func sshAgent(privPEM string) (ssh.AuthMethod, error) {
	block, _ := pem.Decode([]byte(privPEM))
	if block == nil {
		return nil, errors.New("failed to parse PEM block containing the key")
	}

	pk, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	ak := agent.AddedKey{
		PrivateKey: pk,
	}

	sshAgent, err := net.Dial("unix", os.Getenv("SSH_AUTH_SOCK"))
	if err != nil {
		return nil, err
	}

	c := agent.NewClient(sshAgent)

	err = c.Add(ak)
	if err != nil {
		return nil, err
	}

	return ssh.PublicKeysCallback(c.Signers), nil
}

func main() {
	log.Println("Setting up SSH agent")
	sshAgent, err := sshAgent(nomadBastionPrivKey)
	if err != nil {
		errorAndExit(err)
	}

	sshConfig := &ssh.ClientConfig{
		User: "ubuntu",
		Auth: []ssh.AuthMethod{
			sshAgent,
		},
		// TODO(kent): don't use insecure ignore host key...
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	log.Println("Connecting to the bastion")
	conn, err := ssh.Dial("tcp", fmt.Sprintf("%s:22", nomadBastionIP), sshConfig)
	if err != nil {
		errorAndExit(err)
	}
	defer conn.Close()

	log.Println("Connecting to the server through the bastion")
	tconn, err := conn.Dial("tcp", fmt.Sprintf("%s:22", nomadServerIP))
	if err != nil {
		errorAndExit(err)
	}
	defer tconn.Close()

	log.Println("Wrapping the server connection with SSH through the bastion")
	stconn, chans, reqs, err := ssh.NewClientConn(tconn, fmt.Sprintf("%s:22", nomadServerIP), sshConfig)
	if err != nil {
		errorAndExit(err)
	}

	log.Println("Tunneling a connection to the server with SSH through the bastion")
	tclient := ssh.NewClient(stconn, chans, reqs)
	defer tclient.Close()

	log.Println("Loading the TLS data")
	nomadCert, err := tls.X509KeyPair([]byte(nomadCLICert), []byte(nomadCLIKey))
	if err != nil {
		errorAndExit(err)
	}

	// TODO(kent): don't use insecure skip verify...
	// if I use ServerName I get "x509: certificate signed by unknown authority" as an error
	tlsClientConfig := &tls.Config{
		Certificates: []tls.Certificate{nomadCert},
		ClientCAs:    x509.NewCertPool(),
		ClientAuth:   tls.RequireAndVerifyClientCert,
		MinVersion:   tls.VersionTLS12,
		// ServerName:         "localhost",
		InsecureSkipVerify: true,
	}

	tlsClientConfig.ClientCAs.AppendCertsFromPEM([]byte(nomadCACert))

	tlsClientConfig.BuildNameToCertificate()

	log.Println("Starting local listener on localhost:4646")
	ln, err := net.Listen("tcp", "localhost:4646")
	if err != nil {
		errorAndExit(err)
	}
	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Println(err)
			continue
		}

		go func(conn net.Conn) {
			nomad, err := tclient.Dial("tcp", "0.0.0.0:4646")
			if err != nil {
				log.Println(err)
				return
			}

			nomadWrap := tls.Client(nomad, tlsClientConfig)

			err = nomadWrap.Handshake()
			if err != nil {
				log.Println(err)
				return
			}

			copyConn := func(writer, reader net.Conn) {
				defer writer.Close()
				defer reader.Close()
				io.Copy(writer, reader)
			}

			go copyConn(conn, nomadWrap)
			go copyConn(nomadWrap, conn)
		}(conn)
	}
}
