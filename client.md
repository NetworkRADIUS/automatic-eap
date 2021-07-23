# Building the Client Image

The _client container_ is a Linux host which will run the [automatic-eap.py](docker/client/automatic-eap/automatic-eap.py) script, and the [eapol_test](http://deployingradius.com/scripts/eapol_test/) (EAP testing tool). The container is configured to use local DNS and RADIUS server, those IP addresses can be accessed over the variables `$RADIUS_IP` and `$DNS_IP` (in this case, set in `/etc/resolv.conf`)

Start the client container with:

```
$ make docker.client.run
```

This will drop you into a shell, where you can run the [EAP download utility](util.md).
