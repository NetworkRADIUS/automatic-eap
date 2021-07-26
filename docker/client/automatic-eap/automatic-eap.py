#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
# Author: Jorge Pereira <jpereira@networkradius.com>
# Project: https://github.com/NetworkRADIUS/automatic-eap/
#
# It is a POC which demonstrates the methods proposed in the EAP Usability
# https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/.
#
###

__project__ = "https://github.com/NetworkRADIUS/automatic-eap/"
__author__ = "Jorge Pereira <jpereira@networkradius.com>"
__version__ = "0.1a"

import argparse
import base64
import dns.resolver
import os, errno
import OpenSSL.crypto
import re
import sys
import shutil
import traceback
import wget
import uuid

from urllib.parse import urlparse

DEST_DIR = "/tmp/automatic-eap"

dns_server = None

def create_mobileconfig(args, _ca_cert, _server_cert):
	try:
		_destdir = os.path.dirname(args.output_file)
		if not os.path.isdir(_destdir):
			os.mkdir(_destdir)

		conf = """
<!-- Generated in {0} by Automatic-EAP -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>AutoJoin</key>
			<true/>
			<key>CaptiveBypass</key>
			<false/>
			<key>DisableAssociationMACRandomization</key>
			<false/>
			<key>EAPClientConfiguration</key>
			<dict>
				<key>AcceptEAPTypes</key>
				<array>
					<integer>21</integer>
				</array>
				<key>PayloadCertificateAnchorUUID</key>
				<array>
					<string>{1}</string>
				</array>
				<key>TLSMaximumVersion</key>
				<string>1.2</string>
				<key>TLSMinimumVersion</key>
				<string>1.0</string>
				<key>TLSTrustedServerNames</key>
				<array>
					<string>Certificate Common Name 2</string>
				</array>
				<key>TTLSInnerAuthentication</key>
				<string>PAP</string>
				<key>UserName</key>
				<string>{2}</string>
				<key>UserPassword</key>
				<string>{3}</string>
			</dict>
			<key>EncryptionType</key>
			<string>WPA</string>
			<key>HIDDEN_NETWORK</key>
			<false/>
			<key>IsHotspot</key>
			<false/>
			<key>PayloadDescription</key>
			<string>Configures Wi-Fi settings</string>
			<key>PayloadDisplayName</key>
			<string>Wi-Fi</string>
			<key>PayloadIdentifier</key>
			<string>com.apple.wifi.managed.{4}</string>
			<key>PayloadType</key>
			<string>com.apple.wifi.managed</string>
			<key>PayloadUUID</key>
			<string>{4}</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>ProxyType</key>
			<string>None</string>
			<key>SSID_STR</key>
			<string>SSID_NAME</string>
		</dict>
		<dict>
			<key>PayloadCertificateFileName</key>
			<string>cacerts.crt</string>
			<key>PayloadContent</key>
			<data>
			{5}
			</data>
			<key>PayloadDescription</key>
			<string>Adds a CA root certificate</string>
			<key>PayloadDisplayName</key>
			<string>Example Automatic-EAP Certificate Authority</string>
			<key>PayloadIdentifier</key>
			<string>com.apple.security.root.{6}</string>
			<key>PayloadType</key>
			<string>com.apple.security.root</string>
			<key>PayloadUUID</key>
			<string>{6}</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>PayloadDisplayName</key>
	<string>{7}</string>
	<key>PayloadIdentifier</key>
	<string>Automatic-EAP.12345</string>
	<key>PayloadRemovalDisallowed</key>
	<false/>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>{8}2</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
\n"""

		with open(args.output_file, 'w') as f:
			cert_file = open(_ca_cert, 'rb')
			cert_data = base64.b64encode(cert_file.read()).decode('ascii')
			cert_enco = '\n\t\t\t'.join(cert_data[i:i+52] for i in range(0, len(cert_data), 52))
			uuid1 = str(uuid.uuid4()).upper()
			uuid2 = str(uuid.uuid4()).upper()
			uuid3 = str(uuid.uuid4()).upper()
			uuid4 = str(uuid.uuid4()).upper()
			f.write(conf.format(args.output_file, uuid1, args.wifi_username, args.wifi_password,
								uuid2, cert_enco, uuid3, args.wifi_ssid, uuid4))
	except Exception as e:
		raise ValueError("Can't create {0}, error {1}".format(args.output_file, e))

def create_eapol_conf(args, _ca_cert, _server_cert):
	try:
		_destdir = os.path.dirname(args.output_file)
		if not os.path.isdir(_destdir):
			os.mkdir(_destdir)

		conf = """
#
# Generated in {0} by Automatic-EAP
#
# e.g:
#\teapol_test -c {0} -a {1} -s {2}
#
network={{
\tkey_mgmt=WPA-EAP
\teap=TTLS
\tidentity=\"{3}\"
\tanonymous_identity="@{5}"
\tca_cert=\"{6}\"
\tpassword=\"{4}\"
\tphase2=\"auth=PAP\"
}}\n"""

		with open(args.output_file, 'w') as f:
			f.write(conf.format(args.output_file, args.radius_server, args.radius_secret, args.radius_user, args.radius_pass, args.domain, _ca_cert))
	except Exception as e:
		raise ValueError("Can't create {0}, error {1}".format(args.output_file, e))

def show_cert(_cert_file):
	try:
		print("\t[-] Showing certificate infos for \"{0}\"".format(_cert_file))
		cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, open(_cert_file).read())
		print("\t > Issued to = \"{0}\"".format(cert.get_subject().CN))
		print("\t > Issued By = \"{0}\"".format(cert.get_issuer().CN))
	except Exception as e:
		raise ValueError("Can't load certificate file: {0}, error {1}".format(_cert_file, e))

def overwrite_url(_url, _host):
	try:
		parsed = urlparse(_url)
		parsed = parsed._replace(netloc = _host).geturl()

		return parsed
	except Exception as e:
		raise ValueError("Can't urlparse: {0}, error {1}".format(_url, e))

def downlod_file(_url, _dest):
	try:
		_destfile = "{0}/{1}".format(_dest, os.path.basename(_url))
		if os.path.isfile(_destfile):
			os.remove(_destfile)

		_destdir = os.path.dirname(_destfile)
		if not os.path.isdir(_destdir):
			os.mkdir(_destdir)

		print("\t[-] Downloading \"{0}\" in \"{1}\"".format(_url, _destfile))
		wget.download(_url, out = _destfile)
		print()

		return _destfile
	except Exception as e:
		raise ValueError("Can't download {0} in {1}, error {2}".format(_url, _dest, e))
#
# As the page 30 in https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/
# 6.2.  Bootstrapping via DNS ...............................   30
#
def dns_get_cert_url(_type, _domain):
	cert_domain = "{0}.{1}".format(_type, _domain)
	try:
		res = dns.resolver.Resolver(configure=True)

		print("\t[-] Lookup for 'CERT' DNS entry in: \"{0}\"".format(cert_domain))

		if dns_server:
			res.nameservers = [dns_server]

		for row in res.resolve(cert_domain, "CERT"):
			# As the 'CERT' layout described in https://datatracker.ietf.org/doc/html/rfc4398#section-2.2
			(_begin, _type, _tag, _algo, _cert, _end) = re.split(r"^(\d) (\d) (\d) (.+)$", str(row))

			# As described in https://datatracker.ietf.org/doc/draft-dekok-emu-eap-usability/
			# the type should be IPKIX (4)
			if _type != "4":
				raise ValueError("The CERT type should be 4 (IPKIX) instead of {0}".format(_type))

			return base64.b64decode(_cert).decode('ascii')
	except Exception as e:
		raise ValueError("Can't resolve cert {0}, error {1}".format(cert_domain, e))

def _main():
	global dns_server

	parser = argparse.ArgumentParser(description = "Bootstrap Automatic-EAP informations automatically")
	parser.add_argument("-d", "--domain", dest = "domain", help = "Domain to bootstrap the Automatic-EAP", required = True)
	parser.add_argument("-n", "--dns-server", dest = "dns_server", help = "DNS server address to use.", required = False)
	parser.add_argument("-c", "--cert-dest", dest = "cert_dest", help = "Certificate destination directory.", required = False, default = DEST_DIR)
	parser.add_argument("-H", "--overwrite-dns-cert-host", dest = "url_host", help = "Overwrite the HOST from DNS/CERT reply.", required = False)
	parser.add_argument("-t", "--config-type", dest = "config_type", help = "It must be 'eapol_test' or 'mobileconfig'", default = "eapol_test", required = False)
	parser.add_argument("-o", "--output-file", dest = "output_file", help = "Destination of generated eapol_test.conf file.", default = DEST_DIR+"/eapol_ttls-pap.conf", required = False)
	parser.add_argument("-S", "--wifi-ssid", dest = "wifi_ssid", help = "Wi-Fi SSID", required = False)
	parser.add_argument("-U", "--wifi-username", dest = "wifi_username", help = "Wi-Fi username", required = False)
	parser.add_argument("-P", "--wifi-password", dest = "wifi_password", help = "Wi-Fi password", required = False)
	parser.add_argument("-s", "--radius-server", dest = "radius_server", help = "RADIUS Server", default = "localhost", required = True)
	parser.add_argument("-e", "--radius-secret", dest = "radius_secret", help = "RADIUS Secret", default = "testing123", required = False)
	parser.add_argument("-u", "--radius-user", dest = "radius_user", help = "RADIUS User", required = True)
	parser.add_argument("-p", "--radius-pass", dest = "radius_pass", help = "RADIUS Pass", required = True)
	args = parser.parse_args()

	try:
		print("[+] Automatic-EAP bootstrap for \"{0}\"".format(args.domain))

		if args.dns_server:
			print("\t[-] Set specific DNS server: \"{0}\"".format(args.dns_server))
			dns_server = args.dns_server

		#
		# Lookup the _ca._cert ...
		#
		ca_cert_url = dns_get_cert_url("_ca._cert._eap", args.domain)
		print("\t > ca_cert = \"{0}\"".format(ca_cert_url))
		if args.url_host:
			ca_cert_url = overwrite_url(ca_cert_url, args.url_host)
		ca_cert_file = downlod_file(ca_cert_url, args.cert_dest)
		show_cert(ca_cert_file)

		#
		# Lookup the _server._cert ...
		#
		server_ca_url = dns_get_cert_url("_server._cert._eap", args.domain)
		print("\t > server_ca = \"{0}\"".format(server_ca_url))
		if args.url_host:
			server_ca_url = overwrite_url(server_ca_url, args.url_host)
		server_ca_file = downlod_file(server_ca_url, args.cert_dest)
		show_cert(server_ca_file)

		if args.config_type == "eapol_test":
			#
			# Generate eapol_test.conf
			#
			print("\t[-] Build the 'eapol_test' config in \"{0}\"".format(args.output_file))
			print("\tFile: {0}".format(args.output_file))
			print("\tRadius Information")
			print("\t\tServer: {0}".format(args.radius_server))
			print("\t\tSecret: {0}".format(args.radius_secret))
			print("\t\tUser: {0}".format(args.radius_user))
			print("\t\tPass: {0}".format(args.radius_pass))
			create_eapol_conf(args, ca_cert_file, server_ca_file)
		elif args.config_type == "mobileconfig":
			print("\t[-] Build the 'mobileconfig' config in \"{0}\"".format(args.output_file))
			create_mobileconfig(args, ca_cert_file, server_ca_file)
		else:
			raise ValueError("Invalid --config-type {0}, It must be 'eapol_test' or 'mobileconfig'".format(args.config_type))

	except Exception as e:
		print("** ERROR: {0}".format(str(e)))
		sys.exit(-1)

if __name__ == "__main__":
	_main()
