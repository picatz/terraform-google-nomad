package main

import (
	"crypto/tls"
	"crypto/x509"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"os"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"
)

var (
	nomadServerIP       string
	nomadBastionIP      string
	nomadCAFile         string
	nomadClientCertFile string
	nomadClientKeyFile  string
)

func errorAndExit(mesg interface{}) {
	fmt.Println(mesg)
	os.Exit(1)
}

func init() {
	flag.StringVar(&nomadServerIP, "server-ip", "", "internal Nomad server IP")
	flag.StringVar(&nomadBastionIP, "bastion-ip", "", "external Nomad bastion IP")
	flag.StringVar(&nomadCAFile, "ca-file", "", "mTLS certifcate authority file")
	flag.StringVar(&nomadClientCertFile, "cert-file", "", "mTLS client cert file")
	flag.StringVar(&nomadClientKeyFile, "key-file", "", "mTLS client key file")

	flag.Parse()

	if nomadServerIP == "" {
		errorAndExit("--server-ip not given")
	}

	if nomadBastionIP == "" {
		errorAndExit("--bastion-ip not given")
	}

	if nomadCAFile == "" {
		errorAndExit("--ca-file not given")
	}

	if nomadClientCertFile == "" {
		errorAndExit("--cert-file not given")
	}

	if nomadClientKeyFile == "" {
		errorAndExit("--key-file not given")
	}
}

func sshAgent() ssh.AuthMethod {
	if sshAgent, err := net.Dial("unix", os.Getenv("SSH_AUTH_SOCK")); err == nil {
		return ssh.PublicKeysCallback(agent.NewClient(sshAgent).Signers)
	}
	return nil
}

func main() {
	sshConfig := &ssh.ClientConfig{
		User: "ubuntu",
		Auth: []ssh.AuthMethod{
			sshAgent(),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	conn, err := ssh.Dial("tcp", fmt.Sprintf("%s:22", nomadBastionIP), sshConfig)
	if err != nil {
		errorAndExit(err)
	}
	defer conn.Close()

	tconn, err := conn.Dial("tcp", fmt.Sprintf("%s:22", nomadServerIP))
	defer tconn.Close()

	stconn, chans, reqs, err := ssh.NewClientConn(tconn, fmt.Sprintf("%s:22", nomadServerIP), sshConfig)
	if err != nil {
		errorAndExit(err)
	}

	tclient := ssh.NewClient(stconn, chans, reqs)
	defer tclient.Close()

	nomadCert, err := tls.LoadX509KeyPair(nomadClientCertFile, nomadClientKeyFile)
	if err != nil {
		errorAndExit(err)
	}

	caFile, err := os.Open(nomadCAFile)
	if err != nil {
		errorAndExit(err)
	}
	defer caFile.Close()

	nomadCA, err := ioutil.ReadAll(caFile)
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

	tlsClientConfig.ClientCAs.AppendCertsFromPEM(nomadCA)

	tlsClientConfig.BuildNameToCertificate()

	log.Println("Starting local listener on localhost:4646")
	ln, err := net.Listen("tcp", "localhost:4646")
	if err != nil {
		errorAndExit(err)
	}
	for {
		conn, err := ln.Accept()
		if err != nil {
			errorAndExit(err)
		}
		log.Printf("Accepted conn %q", conn.RemoteAddr())
		go func(conn net.Conn) {
			nomad, err := tclient.Dial("tcp", "0.0.0.0:4646")
			if err != nil {
				errorAndExit(err)
			}

			nomadWrap := tls.Client(nomad, tlsClientConfig)

			err = nomadWrap.Handshake()
			if err != nil {
				errorAndExit(err)
			}

			copyConn := func(writer, reader net.Conn) {
				defer writer.Close()
				defer reader.Close()

				_, err := io.Copy(writer, reader)
				if err != nil {
					errorAndExit(err)
				}
				log.Printf("Done with conn %q", conn.RemoteAddr())
			}

			go copyConn(conn, nomadWrap)
			go copyConn(nomadWrap, conn)
		}(conn)
	}

}
