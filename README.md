# Automatic EAP

This repo provides a set of script and [Docker Containers](https://www.docker.com/resources/what-container) as a proof-of-concept to validate all the RFC [EAP Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/) purpose.

## Brief

The current containers are expected to running all services inside the same server using a single IP address. If you want to run separately, we are assuming that you know what you're doing.

## Build the Server

1. Copy the repo.

```
$ git clone https://github.com/NetworkRADIUS/automatic-eap
$ cd automatic-eap
```

2. Adjust the client and server certificates. (Do not touch the fields where you find the *@@DOMAIN@@* placeholder)

```
$ vi certs/server.cnf.tpl
$ vi certs/client.cnf.tpl
```

even the `CA` certificate if desired.

```
$ vi certs/ca.cnf
```

3. Set the `DOMAIN=...` in `Makefile`

```
$ vi Makefile
```

4. then, build the containers.

```
$ make docker.server.run
```

It will build and start up three containers tagged as the below list.

Container  | Description
------------- | -------------
networkradius/automatic-eap:service-www | NGINX service providing the cert files over the URL. e.g: http://certs.example.com/
networkradius/automatic-eap:service-dns | PowerDNS service providing the DNS service with the `_ca._cert._eap.example.com` and `_server._cert._eap.example.com` _IPKIX_ entries within a base64 string being the URL. e.g: `http://certs.example.com/.well-known/est/cacerts`
networkradius/automatic-eap:service-radius | FreeRADIUS service authenticating the `TTLS-PAP`, by default the user is `bob` and password is `hello` as it could be add extras users in [/etc/freeradius/mods-config/files/authorize](docker/server/radius/config/etc/freeradius/mods-config/files/authorize)

## Client

The _client_ container is a Linux host prepared to execute the [automatic-eap.py](docker/client/automatic-eap/automatic-eap.py) script and the [eapol_test](http://deployingradius.com/scripts/eapol_test/) (EAP testing tool). That such container is configured to use our DNS and RADIUS server, those IP addresses can be accessed over the variables `$RADIUS_IP` and `$DNS_IP` (in this case, properly set in /etc/resolv.conf)

1. Start the _client_ container within 

```
$ make docker.client.run
```

And execute the _automatic-eap.py_ to get similar output.

```
root@automatic-eap-client:~# automatic-eap.py --domain $DOMAIN --radius-server $RADIUS_IP --radius-user bob --radius-pass hello
[+] Automatic-EAP bootstrap for "example.com"
	[-] Lookup for 'CERT' DNS entry in: "_ca._cert._eap.example.com"
	 > ca_cert = "http://certs.example.com/.well-known/est/cacerts"
	[-] Downloading "http://certs.example.com/.well-known/est/cacerts" in "/tmp/automatic-eap/cacerts"
100% [................................................................................] 1842 / 1842
	[-] Showing certificate infos for "/tmp/automatic-eap/cacerts"
	 > Issued to = "Example Automatic-EAP Certificate Authority"
	 > Issued By = "Example Automatic-EAP Certificate Authority"
	[-] Lookup for 'CERT' DNS entry in: "_server._cert._eap.example.com"
	 > server_ca = "http://certs.example.com/.well-known/eap/server"
	[-] Downloading "http://certs.example.com/.well-known/eap/server" in "/tmp/automatic-eap/server"
100% [................................................................................] 3815 / 3815
	[-] Showing certificate infos for "/tmp/automatic-eap/server"
	 > Issued to = "Example Automatic-EAP Server Certificate"
	 > Issued By = "Example Automatic-EAP Certificate Authority"
	[-] Build the 'eapol_test' config in "/tmp/automatic-eap/eapol_ttls-pap.conf"
	File: /tmp/automatic-eap/eapol_ttls-pap.conf
	Radius Infos
		Server: 172.17.0.2
		Secret: testing123
		User: bob
		Pass: hello
root@automatic-eap-client:~#
```

Once without errors, you should be able to authenticate with "eapol_test" using the generated _/tmp/automatic-eap/eapol_ttls-pap.conf_ config settings.

Sample of generated eapol_ttls-pap.conf

```
root@automatic-eap-client:~# cat /tmp/automatic-eap/eapol_ttls-pap.conf
#
# Generated in /tmp/automatic-eap/eapol_ttls-pap.conf by Automatic-EAP
#
network={
	key_mgmt=WPA-EAP
	eap=TTLS
	identity="bob"
	anonymous_identity="anonymous@example.org"
	ca_cert="/tmp/automatic-eap/cacerts"
	password="hello"
	phase2="auth=PAP"
}
root@automatic-eap-client:~#
```

therefore, just test using `eapol_test`

```
root@automatic-eap-client:~# eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a $RADIUS_IP -s testing123 | tai
l -1
SUCCESS
root@automatic-eap-client:~#
```

## Tests

Once logged in the _client container_ using `make docker.client.run`, we could see each steps described for EAP Usability described [here](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/) like:


1. Checking the DNS _CERT_ entries using the *dig* tool:

1.1. for *_ca._cert._eap.example.com*

```
root@automatic-eap-client:~# dig _ca._cert._eap.example.com CERT +short
IPKIX 0 0 aHR0cDovL2NlcnRzLmV4YW1wbGUuY29tLy53ZWxsLWtub3duL2VzdC9jYWNlcnRz
root@automatic-eap-client:~#
```

1.2. for *_server._cert._eap.example.com*

```
root@automatic-eap-client:~# dig _server._cert._eap.example.com CERT +short
IPKIX 0 0 aHR0cDovL2NlcnRzLmV4YW1wbGUuY29tLy53ZWxsLWtub3duL2VhcC9z ZXJ2ZXI=
root@automatic-eap-client:~#
```

1.3. Decode the content

```
root@automatic-eap-client:~# dig _server._cert._eap.example.com CERT +short | sed 's/^IP.* 0 0 //g' | base64 -di
http://certs.example.com/.well-known/eap/server
root@automatic-eap-client:~#
```

```
root@automatic-eap-client:~# dig _ca._cert._eap.example.com CERT +short | sed 's/^IP.* 0 0 //g' | base64 -di
http://certs.example.com/.well-known/est/cacerts
root@automatic-eap-client:~#
```

2. Checking the certificate URL.

The server certificate

```
root@automatic-eap-client:~# curl -s http://certs.example.com/.well-known/eap/server | head
Bag Attributes
    localKeyID: B3 BE A0 D7 AC D0 0C 11 29 5B 7A 13 A0 B1 2F 50 C8 BE 12 32
subject=C = FR, ST = Radius, O = Example Inc., CN = Example Automatic-EAP Server Certificate, emailAddress = admin@example.com

issuer=C = FR, ST = Radius, L = Somewhere, O = Example Inc., emailAddress = admin@example.org, CN = Example Automatic-EAP Certificate Authority

-----BEGIN CERTIFICATE-----
MIIEETCCAvmgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBoTELMAkGA1UEBhMCRlIx
DzANBgNVBAgMBlJhZGl1czESMBAGA1UEBwwJU29tZXdoZXJlMRUwEwYDVQQKDAxF
eGFtcGxlIEluYy4xIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1wbGUub3JnMTQw
root@automatic-eap-client:~#
```
... and the CA certificate.

```
root@automatic-eap-client:~# curl -s http://certs.example.com/.well-known/est/cacerts | head
-----BEGIN CERTIFICATE-----
MIIFJDCCBAygAwIBAgIUazHdC1llMLn5SWwdJwyFS1gjsuYwDQYJKoZIhvcNAQEL
BQAwgaExCzAJBgNVBAYTAkZSMQ8wDQYDVQQIDAZSYWRpdXMxEjAQBgNVBAcMCVNv
bWV3aGVyZTEVMBMGA1UECgwMRXhhbXBsZSBJbmMuMSAwHgYJKoZIhvcNAQkBFhFh
ZG1pbkBleGFtcGxlLm9yZzE0MDIGA1UEAwwrRXhhbXBsZSBBdXRvbWF0aWMtRUFQ
IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0yMTA3MjEwMTAwNTJaFw0yMTA5MTkw
MTAwNTJaMIGhMQswCQYDVQQGEwJGUjEPMA0GA1UECAwGUmFkaXVzMRIwEAYDVQQH
DAlTb21ld2hlcmUxFTATBgNVBAoMDEV4YW1wbGUgSW5jLjEgMB4GCSqGSIb3DQEJ
ARYRYWRtaW5AZXhhbXBsZS5vcmcxNDAyBgNVBAMMK0V4YW1wbGUgQXV0b21hdGlj
LUVBUCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IB
root@automatic-eap-client:~#
```

3. Radius authentication

```
root@automatic-eap-client:~# radtest bob hello $RADIUS_IP 0 testing123
Sent Access-Request Id 205 from 0.0.0.0:35867 to 172.17.0.2:1812 length 73
	User-Name = "bob"
	User-Password = "hello"
	NAS-IP-Address = 172.17.0.5
	NAS-Port = 0
	Message-Authenticator = 0x00
	Cleartext-Password = "hello"
Received Access-Accept Id 205 from 172.17.0.2:1812 to 172.17.0.5:35867 length 32
	Reply-Message = "Hello, bob"
root@automatic-eap-client:~#
```

You could see all these commands using the command 'history'

e.g:

```
root@automatic-eap-client:~# history
    1  automatic-eap.py --domain $DOMAIN --radius-server $RADIUS_IP --radius-user bob --radius-pass hello
    2  eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a $RADIUS_IP -s testing123 | tail
    3  dig _ca._cert._eap.example.com CERT +short
    4  dig _server._cert._eap.example.com CERT +short
    5  dig _server._cert._eap.example.com CERT +short | sed 's/^IP.* 0 0 //g' | base64 -di
    6  dig _ca._cert._eap.example.com CERT +short | sed 's/^IP.* 0 0 //g' | base64 -di
    7  curl -s http://certs.example.com/.well-known/eap/server | head
    8  curl -s http://certs.example.com/.well-known/est/cacerts | head
    9  radtest bob hello $RADIUS_IP 0 testing123
   10  history
root@automatic-eap-client:~#
```