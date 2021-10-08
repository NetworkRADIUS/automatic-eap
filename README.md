# Automatic EAP

![Network RADIUS Logo](img/networkradius-logo.png)

This [repository](https://github.com/NetworkRADIUS/automatic-eap/) provides a set of script and [Docker Containers](https://www.docker.com/resources/what-container) as a "proof-of-concept" which demonstrates the methods proposed in the [EAP Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/) document.

## What is this?

Historically, 802.1X / EAP has been difficult to configure and use securely.

This repository contains sample code which shows that it can be
_trivial_ to configure client systems for many EAP types.  All that is
required is that the client system have:

1. A web root CA, so that it can securely verify web sites for downloads
2. a network connection
3. A user name to authenticate with, e.g. `john.doe@example.com`
4. A password to authenticate with, e.g. `superSecr3t`

_That's it_.

The `example.com` domain has some additional requirements.  It has to
have a DNS server, and then put a few special records into DNS.  It
has to have a web site which can host the certificates used for EAP.

For a (very long) description of this process, including many things not discussed here, see the [EAP Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/) document.

## Build Requirements

In order to use this repository, you will need:

* Docker
* GNU Make

This should work on most Linux systems, and on OSX.

## Getting it Done

* [configure](configure.md) the system.
* build the [server containers](server.md)
* build the [client container](client.md)
* run the [client utility](util.md) to automatically look up the DNS
  CERT records, download the certificates, and create the `eapol_test`
  configuration file
* run [eapol_test](eapol_test.md) in order to verify that it works.
* see [how it works](explanation.md)
