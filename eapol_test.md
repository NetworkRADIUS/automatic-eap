# Running eapol_test

From the [client container](client.md), run `eapol_test`:

```
root@automatic-eap-client:~# eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a $RADIUS_IP -s testing123
...
SUCCESS
root@automatic-eap-client:~#
```

For testing, the password is hard-coded in the `eapol_ttls-pap.conf` file.

In the real world, the EAP client would prompt the user for a
password.

[How does this work](explanation.md)?
