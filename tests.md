## Tests

Once logged in the [client container](client.md) using `make docker.client.run`, we can see each of steps described in the [EAP Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/) document, such as:


1. Checking the DNS _CERT_ entries using the *dig* tool:

1.1. for *_ca._cert._eap.example.com*

```
root@automatic-eap-client:~# dig _ca._cert._eap.example.com CERT +short
IPKIX 0 0 aHR0cDovL2NlcnRzLmV4YW1wbGUuY29tLy53ZWxsLWtub3duL2VzdC9jYWNlcnRz
root@automatic-eap-client:~#
```

1.2. Checking for *_server._cert._eap.example.com*

```
root@automatic-eap-client:~# dig _server._cert._eap.example.com CERT +short
IPKIX 0 0 aHR0cDovL2NlcnRzLmV4YW1wbGUuY29tLy53ZWxsLWtub3duL2VhcC9z ZXJ2ZXI=
root@automatic-eap-client:~#
```

1.3. Decoding the content

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

2. Checking the certificate URLs

The server certificate:

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

You can see all these commands using the command 'history'

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
