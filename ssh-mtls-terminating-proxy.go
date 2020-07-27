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
	"sync"

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
	ServerInternalIP     terraformOutputNode `json:"server_internal_ip"`
	NomadCACert          terraformOutputNode `json:"nomad_ca_cert"`
	NomadCLICert         terraformOutputNode `json:"nomad_cli_cert"`
	NomadCLIKey          terraformOutputNode `json:"nomad_cli_key"`
	ConsulCACert         terraformOutputNode `json:"consul_ca_cert"`
	ConsulCLICert        terraformOutputNode `json:"consul_cli_cert"`
	ConsulCLIKey         terraformOutputNode `json:"consul_cli_key"`
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
	serverInternalIP  string
	bastionExternalIP string
	bastionSSHPrivKey string
	nomadCACert       string
	nomadCLICert      string
	nomadCLIKey       string
	consulCACert      string
	consulCLICert     string
	consulCLIKey      string
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

		bastionExternalIP = tfOutput.BastionPublicIP.Value
		serverInternalIP = tfOutput.ServerInternalIP.Value
		bastionSSHPrivKey = tfOutput.BastionSSHPrivateKey.Value
		nomadCACert = tfOutput.NomadCACert.Value
		nomadCLICert = tfOutput.NomadCLICert.Value
		nomadCLIKey = tfOutput.NomadCLIKey.Value
		consulCACert = tfOutput.ConsulCACert.Value
		consulCLICert = tfOutput.ConsulCLICert.Value
		consulCLIKey = tfOutput.ConsulCLIKey.Value
	} else {
		var (
			nomadBastionSSHFile string
			nomadCACertFile     string
			nomadCLICertFile    string
			nomadCLIKeyFile     string
		)

		flag.StringVar(&serverInternalIP, "server-ip", "", "internal Nomad server IP")
		flag.StringVar(&bastionExternalIP, "bastion-ip", "", "external Nomad bastion IP")
		flag.StringVar(&nomadBastionSSHFile, "bastion-ssh-file", "", "ssh key file")
		flag.StringVar(&nomadCACertFile, "ca-file", "", "mTLS certifcate authority file")
		flag.StringVar(&nomadCLICertFile, "cert-file", "", "mTLS client cert file")
		flag.StringVar(&nomadCLIKeyFile, "key-file", "", "mTLS client key file")

		flag.Parse()

		bastionSSHPrivKey = readFileContent(nomadBastionSSHFile)
		nomadCACert = readFileContent(nomadCACertFile)
		nomadCLICert = readFileContent(nomadCLICertFile)
		nomadCLIKey = readFileContent(nomadCLIKeyFile)
	}

	log.Printf("Bastion IP: %q", bastionExternalIP)
	log.Printf("Server IP: %q", serverInternalIP)
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
	sshAgent, err := sshAgent(bastionSSHPrivKey)
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
	conn, err := ssh.Dial("tcp", fmt.Sprintf("%s:22", bastionExternalIP), sshConfig)
	if err != nil {
		errorAndExit(err)
	}
	defer conn.Close()

	log.Println("Connecting to the server through the bastion")
	tconn, err := conn.Dial("tcp", fmt.Sprintf("%s:22", serverInternalIP))
	if err != nil {
		errorAndExit(err)
	}
	defer tconn.Close()

	log.Println("Wrapping the server connection with SSH through the bastion")
	stconn, chans, reqs, err := ssh.NewClientConn(tconn, fmt.Sprintf("%s:22", serverInternalIP), sshConfig)
	if err != nil {
		errorAndExit(err)
	}

	wg := sync.WaitGroup{}

	wg.Add(2)

	go func() {
		defer wg.Done()
		log.Println("Tunneling a new connection for Nomad to the server with SSH through the bastion")
		tclient := ssh.NewClient(stconn, chans, reqs)
		defer tclient.Close()

		log.Println("Loading Nomad TLS data")
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

		log.Println("Starting Nomad local listener on localhost:4646")
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
	}()

	go func() {
		defer wg.Done()
		log.Println("Tunneling a new connection for Consul to the server with SSH through the bastion")
		tclient := ssh.NewClient(stconn, chans, reqs)
		defer tclient.Close()

		log.Println("Loading Consul TLS data")
		consulCert, err := tls.X509KeyPair([]byte(consulCLICert), []byte(consulCLIKey))
		if err != nil {
			errorAndExit(err)
		}

		// TODO(kent): don't use insecure skip verify...
		// if I use ServerName I get "x509: certificate signed by unknown authority" as an error
		tlsClientConfig := &tls.Config{
			Certificates: []tls.Certificate{consulCert},
			ClientCAs:    x509.NewCertPool(),
			ClientAuth:   tls.RequireAndVerifyClientCert,
			MinVersion:   tls.VersionTLS12,
			// ServerName:         "localhost",
			InsecureSkipVerify: true,
		}

		tlsClientConfig.ClientCAs.AppendCertsFromPEM([]byte(consulCACert))

		tlsClientConfig.BuildNameToCertificate()

		log.Println("Starting Consul local listener on localhost:8500")
		ln, err := net.Listen("tcp", "localhost:8500")
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
				consul, err := tclient.Dial("tcp", "0.0.0.0:8501")
				if err != nil {
					log.Println(err)
					return
				}

				consulWrap := tls.Client(consul, tlsClientConfig)

				err = consulWrap.Handshake()
				if err != nil {
					log.Println(err)
					return
				}

				copyConn := func(writer, reader net.Conn) {
					defer writer.Close()
					defer reader.Close()
					io.Copy(writer, reader)
				}

				go copyConn(conn, consulWrap)
				go copyConn(consulWrap, conn)
			}(conn)
		}
	}()

	wg.Wait()
}
