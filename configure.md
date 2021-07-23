# Configuring the system

## Copy the repository:

```
$ git clone https://github.com/NetworkRADIUS/automatic-eap
$ cd automatic-eap
```

## Edit the certificates

You can edit the client and server certificates to add local information such as names, addresses, etc.  Do not touch the fields which have the *@@DOMAIN@@* placeholder, as they will be filled in automatically.

This step is not necessary, but can be used to easily modify the data
inside of the certificates.

```
$ vi certs/server.cnf.tpl
$ vi certs/client.cnf.tpl
```

edit the `CA` certificate if desired:

```
$ vi certs/ca.cnf
```

3. Set the `DOMAIN=...` in the `Makefile`

```
$ vi Makefile
...
# DNS settings
DOMAIN := example.com
DNS_RECORDS := www certs foo|192.168.10.55 bar|192.168.10.52
DNS_CERT_CA_PATH := http://certs.example.com/.well-known/est/cacerts
DNS_CERT_SERVER_PATH := http://certs.example.com/.well-known/eap/server
```

Then, build the [server containers](server.md).  The build scripts
will take those parameters, and create the necessary DNS zones, web
sites, etc.
