# Automatic EAP

![Network RADIUS Logo](img/networkradius-logo.png)

This repository provides a set of script and [Docker Containers](https://www.docker.com/resources/what-container) as a "proof-of-concept" which demonstrates the methods proposed in the [EAP Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/) document.

* [configure](configure.md) the system.
* build the [server containers](server.md)
* build the [client container](client.md)
* run the [client utility](util.md) to automatically look up the DNS
  CERT records, download the certificates, and create the `eapol_test`
  configuration file
* run [eapol_test](eapol_test.md) in order to verify that it works.

