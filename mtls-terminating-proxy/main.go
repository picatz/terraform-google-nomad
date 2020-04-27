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
)

var (
	lbIP         string
	nomadCACert  string
	nomadCLICert string
	nomadCLIKey  string
)

func errorAndExit(mesg interface{}) {
	fmt.Println(mesg)
	os.Exit(1)
}

func readFileContent(file string) string {
	f, err := os.Open(file)
	if err != nil {
		errorAndExit(fmt.Errorf("%s %w", file, err))
	}
	defer f.Close()

	bytes, err := ioutil.ReadAll(f)
	if err != nil {
		errorAndExit(fmt.Errorf("%s %w", file, err))
	}
	return string(bytes)
}

func init() {
	var (
		nomadCACertFile  string
		nomadCLICertFile string
		nomadCLIKeyFile  string
	)

	flag.StringVar(&lbIP, "lb-ip", "", "internal Nomad server IP")
	flag.StringVar(&nomadCACertFile, "ca-file", "", "mTLS certifcate authority file")
	flag.StringVar(&nomadCLICertFile, "cert-file", "", "mTLS client cert file")
	flag.StringVar(&nomadCLIKeyFile, "key-file", "", "mTLS client key file")

	flag.Parse()

	nomadCACert = readFileContent(nomadCACertFile)
	nomadCLICert = readFileContent(nomadCLICertFile)
	nomadCLIKey = readFileContent(nomadCLIKeyFile)

	log.Printf("Load Balancer IP: %q", lbIP)
}

func main() {
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
			nomad, err := net.Dial("tcp", fmt.Sprintf("%s:4646", lbIP))
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
