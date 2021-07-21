automatic-eap.py --domain $DOMAIN --radius-server $RADIUS_IP --radius-user bob --radius-pass hello
eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a $RADIUS_IP -s testing123 | tail
dig _ca._cert._eap.example.com CERT +short
dig _server._cert._eap.example.com CERT +short
dig _server._cert._eap.example.com CERT +short | sed 's/^IP.* 0 0 //g' | base64 -di
dig _ca._cert._eap.example.com CERT +short | sed 's/^IP.* 0 0 //g' | base64 -di
curl -s http://certs.example.com/.well-known/eap/server | head
curl -s http://certs.example.com/.well-known/est/cacerts | head
radtest bob hello $RADIUS_IP 0 testing123
