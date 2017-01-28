#!/bin/bash
# To be used via an @reboot cronjob on DSA-maintained machines.

exec /srv/manpages.debian.org/debiman/gopath/bin/debiman-auxserver \
  -index=/srv/manpages.debian.org/www/auxserver.idx \
  -inject_assets=/srv/manpages.debian.org/debiman/debian-assets
