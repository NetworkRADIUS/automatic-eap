# Running the Automatic EAP utility

## eapol_test

Inside of the [client container](client.md), execute the [automatic-eap.py](docker/client/automatic-eap/automatic-eap.py) script to get output as follows:

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

The utility program will generate a sample `eapol_test` configuration file:

```
root@automatic-eap-client:~# cat /tmp/automatic-eap/eapol_ttls-pap.conf
#
# Generated in /tmp/automatic-eap/eapol_ttls-pap.conf by Automatic-EAP
#
network={
	key_mgmt=WPA-EAP
	eap=TTLS
	identity="bob"
	anonymous_identity="@example.com"
	ca_cert="/tmp/automatic-eap/cacerts"
	password="hello"
	phase2="auth=PAP"
}
root@automatic-eap-client:~#
```

You can then run [eapol_test](eapol_test.md) in order to authenticate
to the RADIUS server.

## .mobileconfig


```
root@automatic-eap-client:~# automatic-eap.py --domain $DOMAIN --radius-server $RADIUS_IP -o /tmp/automatic-eap/MyWiFi.mobileconfig -t mobileconfig --radius-user bob --radius-pass hello --wifi-username bob --wifi-password hello --wifi-ssid MyWiFi
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
	[-] Build the 'mobileconfig' config in "/tmp/automatic-eap/MyWiFi.mobileconfig"
root@automatic-eap-client:~#
```

Once this has run, you could copy the [MyWiFi.mobileconfig](MyWiFi.mobileconfig) from the container to your host.

e.g:

```
$ docker cp automatic-eap-client:/tmp/automatic-eap/MyWiFi.mobileconfig ~/Downloads/
```

Then, you should be able to authenticate using such [MyWiFi.mobileconfig](MyWiFi.mobileconfig).