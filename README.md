# Automatic EAP

This repo provides a set of script and containers allowing to validate the RFC [EAP Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/).

## Brief

The current containers are expected to running all services inside the same server using single IP address. If you want to run separately, we are assuming that you know what you're doing.

## Build

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

Also the `CA` certificate if desired.

```
$ vi certs/ca.cnf
```

3. then, build the containers.

```
$ make DOMAIN=mydomain.com docker.server.run
```

It will build three containers tagged as the below list.

Container  | Description
------------- | -------------
networkradius/automatic-eap:service-www  | NGINX service providing the cert files over HTTP.
networkradius/automatic-eap:service-dns  | PowerDNS service providing the `DOMAIN=mydomain.com`
networkradius/automatic-eap:service-radius  | FreeRADIUS service authenticating the TTLS-PAP

4. Once it's done

## Testing

1. Start the _client_ container.

```
$ make docker.client.run
```

And execute the _automatic-eap.py_ to get similar output.

```
root@automatic-eap-client:~# automatic-eap.py --domain $DOMAIN --radius-server $RADIUS_IP --radius-user bob --radius-pass hello
[+] Automatic-EAP bootstrap for "example.com"
	[-] Lookup the domain: "_ca._cert._eap.example.com"
	 > ca_cert = "http://certs.example.com/.well-known/est/cacerts"
	[-] Save "http://certs.example.com/.well-known/est/cacerts" in "/tmp/automatic-eap/cacerts"
100% [................................................................................] 1842 / 1842
	> Issued to = "Example Automatic-EAP Certificate Authority"
	> Issued By = "Example Automatic-EAP Certificate Authority"
	[-] Lookup the domain: "_server._cert._eap.example.com"
	 > server_ca = "http://certs.example.com/.well-known/eap/server"
	[-] Save "http://certs.example.com/.well-known/eap/server" in "/tmp/automatic-eap/server"
100% [................................................................................] 3815 / 3815
	> Issued to = "Example Automatic-EAP Server Certificate"
	> Issued By = "Example Automatic-EAP Certificate Authority"
	[-] Generate the "/tmp/automatic-eap/eapol_ttls-pap.conf"
# Command to validate:
eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a 172.17.0.2 -s testing123
root@automatic-eap-client:~#
```

Once it's done without errors, you should be able to authenticate with "eapol_test" using the generated _/tmp/automatic-eap/eapol_ttls-pap.conf_ config settings.

```
root@automatic-eap-client:~# eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a 172.17.0.2 -s testing123 | tail
EAPOL: SUPP_BE entering state IDLE
eapol_sm_cb: result=1
EAPOL: Successfully fetched key (len=32)
PMK from EAPOL - hexdump(len=32): 6e ab 5c 14 c2 38 59 b1 85 9d e6 10 73 ba 43 ca 41 79 4a 1b bd 9e c9 08 bc 21 c9 f7 1d 06 8a c8
No EAP-Key-Name received from server
WPA: Clear old PMK and PTK
EAP: deinitialize previously used EAP method (21, TTLS) at EAP deinit
ENGINE: engine deinit
MPPE keys OK: 1  mismatch: 0
SUCCESS
root@automatic-eap-client:~#
```

## RADIUS

### Args

```
RADIUS_CLIENTS="client1|ipaddr1|secret1 clientN|ipaddrN|secretN"
RADIUS_USERS="user1|pass1 userN|passN"
```

## DNS

It creates the domain zone adding the subdomains `www` pointing to the container ip address.

### Args

```
docker run -dit --name service-dns \
		-e DOMAIN="example.com" \
		-e DNS_RECORDS="www ftp|192.168.10.55" \
		-e DNS_CERT_CA_PATH="http://certs.example.com/.well-known/est/cacerts" \
		-e DNS_CERT_SERVER_PATH="http://certs.example.com/.well-known/eap/server" \
		-p 53:53/udp freeradius/automatic-eap:service-dns
```

i.e: By default, the parameter `DNS_RECORDS="foo bar:ipaddr` will use the _container ipaddr_ if not informed.

```
$ dig @127.0.0.1 _ca._cert._eap.example.com CERT +short
$ dig @127.0.0.1 _server._cert._eap.example.com CERT +short
```

## Build & Run Images

It will build and start up the `dns, www and radius` containers.

```
$ make docker.server.run
```

## Tests

Check DNS entries

```
$ dig @127.0.0.1 _ca._cert._eap.example.com CERT +short
IPGP 0 0 aHR0cDovL2NlcnRzLmV4YW1wbGUuY29tLy53ZWxsLWtub3duL2VzdC9j YWNlcnRz
$ dig @127.0.0.1 _ca._cert._eap.example.com CERT +short | sed 's/IPGP 0 0 //g' | base64 -d
http://certs.example.com/.well-known/est/cacerts
$
$ dig @127.0.0.1 _server._cert._eap.example.com CERT +short
IPGP 0 0 aHR0cDovL2NlcnRzLmV4YW1wbGUuY29tLy53ZWxsLWtub3duL2VhcC9z ZXJ2ZXI=
$ dig @127.0.0.1 _server._cert._eap.example.com CERT +short | sed 's/IPGP 0 0 //g' | base64 -d
http://certs.example.com/.well-known/eap/server
$
```

Validate web server

```
$ curl http://example.com/.well-known/est/cacerts
$ curl http://example.com/.well-known/eap/server
```
