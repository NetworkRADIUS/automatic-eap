# How does this work?

The idea is that the user enters a name `john.doe@example.com` for
WiFi access.

Behind the scenes, the system runs a utility which does:

* DNS lookups for various CERT records in the `example.com` domain

* discovers that those CERT records point to certificates on the web

* downloads those certificates

* discovers that those certificates contain things like SSID information

* uses the SSID, certificate, and name to run EAP

* uses the downloaded certificates to verify that the EAP server has the correct certificate for `example.com`

* prompts the user for a password, and sends that to the EAP server

* obtains network access.

Please read the [EAP
Usability](https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/)
document for a complete technical description.

Note that in this entire process, all that the user has done is to
enter two pieces of information: _name_, and _password_.  Pretty much
nothing else is required in order to configure EAP.

No magical settings.

No MDM downloads.

It can't get simpler.
