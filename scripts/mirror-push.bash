#!/bin/bash

# Rotate old logs out of the way
/usr/sbin/logrotate -f -s /srv/manpages.debian.org/debiman/logs/logrotate.status /srv/manpages.debian.org/debiman/logs/logrotate.conf

# Redirect stdout and stderr to the current logfiles
exec >/srv/manpages.debian.org/debiman/logs/stdout 2>/srv/manpages.debian.org/debiman/logs/stderr

# Run debiman
/srv/manpages.debian.org/debiman/run-debiman.bash

# Distribute the result to the static mirroring infrastructure.
static-update-component manpages.debian.org

# Distribute the auxserver index to dyn.manpages.debian.org hosts.
rsync /srv/manpages.debian.org/www/auxserver.idx cgi-grnet-01.debian.org:/srv/manpages.debian.org/auxserver.idx
