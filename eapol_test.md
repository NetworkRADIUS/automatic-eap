# Running eapol_test

From the [client container](client.md), run `eapol_test`:

```
root@automatic-eap-client:~# eapol_test -c /tmp/automatic-eap/eapol_ttls-pap.conf -a $RADIUS_IP -s testing123
...
SUCCESS
root@automatic-eap-client:~#
```

