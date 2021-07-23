# Building the Server Images

Build the server containers:

```
$ make docker.server.run
```

It will build and start up three containers tagged as given in the following list:

Container  | Description
------------- | -------------
networkradius/automatic-eap:server-www | NGINX service providing the cert files over the URL. e.g: http://certs.example.com/
networkradius/automatic-eap:server-dns | PowerDNS service providing the DNS service with the `_ca._cert._eap.example.com` and `_server._cert._eap.example.com` _IPKIX_ entries within a base64 string being the URL. e.g: `http://certs.example.com/.well-known/est/cacerts`
networkradius/automatic-eap:server-radius | FreeRADIUS service authenticating the `TTLS-PAP`, by default the user is `bob` and password is `hello` as it could be add extras users in [/etc/freeradius/mods-config/files/authorize](docker/server/radius/config/etc/freeradius/mods-config/files/authorize)

Next, build the [client images](client.md)

## Caveats!

The current containers are expected to running all services inside the same server using a single IP address. If you want to run then on separate addresses, please root through the code to change it. :)
