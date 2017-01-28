#!/bin/bash
# To be used via a cronjob on DSA-maintained machines.

set -e

(cd /srv/manpages.debian.org/debiman/debian-assets && git pull)

ulimit -c unlimited
PATH=/srv/manpages.debian.org/debiman/mandoc-batch:$PATH \
TMPDIR=/srv/manpages.debian.org/tmp/ \
  flock /srv/manpages.debian.org/debiman/exclusive.lock \
  nice -n 5 \
  ionice -n 7 \
  /srv/manpages.debian.org/debiman/gopath/bin/debiman \
  -inject_assets=/srv/manpages.debian.org/debiman/debian-assets \
  -sync_codenames=oldstable,oldstable-backports,stable,stable-backports \
  -sync_suites=testing,unstable,experimental \
  -serving_dir=/srv/manpages.debian.org/www \
  -local_mirror=/srv/mirrors/debian $@

# reload the index
killall -HUP debiman-auxserver

# convert the index
TMPDIR=$(mktemp -d -p /srv/manpages.debian.org/tmp rwmap-tmpXXXXXX)
function cleanup {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

/srv/manpages.debian.org/debiman/gopath/bin/debiman-idx2rwmap -index=/srv/manpages.debian.org/www/auxserver.idx -output_dir=$TMPDIR
LC_ALL=C sort ${TMPDIR}/output.* > ${TMPDIR}/rwmap.txt
# Create an empty DB_BTREE berkeley db file: httxt2dbm does not offer changing
# the file format, but will respect the file format of an already existing
# output file.
echo -n H4sICEEvilgAA2VtcHR5My5kYm0A7dexCYBADIXhF+GK624DLVxAbJzBMVzBNRzO0tpJPDnlRLEW4f8gJCRkgCdJpmRonPw+hFg+7c7b1dguqmPv+nmdyrwvjl69/AEAAAAAgO+YHnk9mMu3O/I/AAAAAAD/sgEYIbKQACAAAA== | base64 -d | gunzip -c > ${TMPDIR}/rwmap.dbm
httxt2dbm -f DB -i ${TMPDIR}/rwmap.txt -o ${TMPDIR}/rwmap.dbm
# Currently unused, but would be better to keep around and sync once the static
# mirror infrastructure supports post-processing:
# mv ${TMPDIR}/rwmap.txt /srv/manpages.debian.org/www/rwmap.txt
mv ${TMPDIR}/rwmap.dbm /srv/manpages.debian.org/www/rwmap.dbm
