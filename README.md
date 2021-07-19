# Automatic EAP

## Certificates

Edit the `CA` files.

```
$ vi certs/ca.cnf
$ vi certs/server.cnf
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
