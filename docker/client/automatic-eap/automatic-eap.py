#!/usr/bin/env python3
# Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
# Author: Jorge Pereira <jpereira@freeradius.org>
# -*- coding: utf-8 -*-
#
# The python script should take one parameter: domain name.
#
# $ ./setup.py example.com
#
# the script will do the following:
#
# * look up _ca._cert._eap.example.com
# * download the certificate at that URL and save it to a file.
# * look up _server._cert._eap.example.com
# * download the certificate at that URL, and save it to a different file
# * create a wpa_supplicant.conf file which uses TTLS, and user@example.com, and verifies the server via the downloaded CA
#
# The user SHOULD then be able to run eapol_test ... args, and verify that he can be authenticated to the RADIUS server.
###

__author__ = 'Jorge Pereira <jpereira@freeradius.org>'
__version__ = "0.1a"

import argparse
import base64
import dns.resolver # pip3 install dnspython
import os, errno
import OpenSSL.crypto
import re
import sys
import shutil
import traceback
import wget

from urllib.parse import urlparse

RADIUS_USER = "bob"
RADIUS_PASS = "hello"

default_cert_dest = "/etc/certs"

def show_cert(_cert_file):
	cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, open(_cert_file).read())
	print("    > Issued to = \"{0}\"".format(cert.get_subject().CN))
	print("    > Issued By = \"{0}\"".format(cert.get_issuer().CN))

def overwrite_url(_url, _host):
	parsed = urlparse(_url)
	parsed = parsed._replace(netloc = _host).geturl()
	return parsed

def downlod_file(_url, _dest):
	_destfile = _dest + "/" + os.path.basename(_url)
	_destdir = os.path.dirname(_destfile)

	if os.path.isfile(_destfile):
		os.remove(_destfile)

	if not os.path.isdir(_destdir):
		os.mkdir(_destdir)

	print("  [*] Downloading {0} in {1}".format(_url, _destfile))
	wget.download(_url, out = _destfile)
	print()

	return _destfile

def dns_get_cert_url(_type, _domain, _dns_server):
	res = dns.resolver.Resolver(configure=False)
	cert_domain = _type + "." + _domain

	print("  [+] Lookup the domain: {0}".format(cert_domain))

	if _dns_server:
		res.nameservers = [_dns_server]

	try:
		for row in res.resolve(cert_domain, "CERT"):
			# As described in https://datatracker.ietf.org/doc/html/rfc4398#section-2.2
			(_begin, _type, _tag, _algo, _cert, _end) = re.split(r"^(\d) (\d) (\d) (.+)$", str(row))
			#print("\t# Debug: _type='{0}', _tag='{1}', _algo='{2}', _cert='{3}'".format(_type, _tag, _algo, _cert))
			return base64.b64decode(_cert).decode('ascii')
	except Exception as e:
		raise ValueError("Can't resolve {0}".format(cert_domain))

def build_wpa_conf(_wpa_conf, _ca_cert, _server_cert):
	with open(_wpa_conf, 'w') as f:
		f.write("# Generated by Automatic-EAP\n")
		f.write("network = {\n")
		f.write("\tssid=\"example\"\n")
		f.write("\tscan_ssid=1\n")
		f.write("\tkey_mgmt=WPA-EAP\n")
		f.write("\teap=PEAP\n")
		f.write("\tidentity=\"{0}\"\n".format(RADIUS_USER))
		f.write("\tpassword=\"{0}\"\n".format(RADIUS_PASS))
		f.write("\tca_cert=\"{0}\"\n".format(_ca_cert))
		f.write("\tphase1=\"peaplabel=0\"\n")
		f.write("\tphase2=\"auth=MSCHAPV2\"\n")
		f.write("}\n")

def _main():
	parser = argparse.ArgumentParser(description = "Bootstrap Automatic-EAP informations automatically")
	parser.add_argument("-d", "--domain", dest = "domain", help = "Domain to bootstrap the Automatic-EAP", required = True)
	parser.add_argument("-s", "--dns-server", dest = "dns_server", help = "DNS server address to use", required = False)
	parser.add_argument("-c", "--cert-dest", dest = "cert_dest", help = "Certificate destination directory", required = False, default = default_cert_dest)
	parser.add_argument("-u", "--overwrite-host", dest = "url_host", help = "Overwrite the certificate URL host", required = False)
	parser.add_argument("-w", "--wpa-supplicant-dest", dest = "wpa_conf", help = "Destination of wpa_supplicant.conf", default = "/etc/wpa_supplicant.conf", required = False)
	args = parser.parse_args()

	try:
		print("[+] Bootstrapping Automatic-EAP for \"{0}\"".format(args.domain))

		if args.dns_server:
			print("  [*] Set specific DNS server: {0}".format(args.dns_server))

		# Lookup the _ca._cert ...
		ca_cert_url = dns_get_cert_url("_ca._cert._eap", args.domain, args.dns_server)
		print("      ca_cert = '{0}'".format(ca_cert_url))
		if args.url_host:
			ca_cert_url = overwrite_url(ca_cert_url, args.url_host)
		ca_cert_file = downlod_file(ca_cert_url, args.cert_dest)
		show_cert(ca_cert_file)

		# Lookup the _server._cert ...
		server_ca_url = dns_get_cert_url("_server._cert._eap", args.domain, args.dns_server)
		print("      server_ca = '{0}'".format(server_ca_url))
		if args.url_host:
			server_ca_url = overwrite_url(server_ca_url, args.url_host)
		server_ca_file = downlod_file(server_ca_url, args.cert_dest)
		show_cert(server_ca_file)

		# Generate wpa_supplicant.conf
		print("    [*] Generate the '{0}'".format(args.wpa_conf))
		build_wpa_conf(args.wpa_conf, ca_cert_file, server_ca_file)

	except Exception as e:
		print("** ERROR: {0}".format(str(e)))
		sys.exit(-1)

if __name__ == "__main__":
	_main()
