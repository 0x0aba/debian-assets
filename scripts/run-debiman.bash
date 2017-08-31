#!/bin/bash
# To be used via a cronjob on DSA-maintained machines.

set -e

(cd /srv/manpages.debian.org/debiman/debian-assets && git pull)

# Try to update the piuparts data files, but continue if they are not
# available.
(wget --ca-certificate=/etc/ssl/ca-debian/ca-certificates.crt https://piuparts.debian.org/for-manpages.d.o/stretch.json.gz -O /srv/manpages.debian.org/debiman/piuparts/.stretch.json.gz && mv /srv/manpages.debian.org/debiman/piuparts/.stretch.json.gz /srv/manpages.debian.org/debiman/piuparts/stretch.json.gz) || true

(wget --ca-certificate=/etc/ssl/ca-debian/ca-certificates.crt https://piuparts.debian.org/for-manpages.d.o/jessie.json.gz -O /srv/manpages.debian.org/debiman/piuparts/.jessie.json.gz && mv /srv/manpages.debian.org/debiman/piuparts/.jessie.json.gz /srv/manpages.debian.org/debiman/piuparts/jessie.json.gz) || true

(wget --ca-certificate=/etc/ssl/ca-debian/ca-certificates.crt https://piuparts.debian.org/for-manpages.d.o/sid.json.gz -O /srv/manpages.debian.org/debiman/piuparts/.unstable.json.gz && mv /srv/manpages.debian.org/debiman/piuparts/.unstable.json.gz /srv/manpages.debian.org/debiman/piuparts/unstable.json.gz) || true

(wget --ca-certificate=/etc/ssl/ca-debian/ca-certificates.crt https://piuparts.debian.org/for-manpages.d.o/experimental.json.gz -O /srv/manpages.debian.org/debiman/piuparts/.experimental.json.gz && mv /srv/manpages.debian.org/debiman/piuparts/.experimental.json.gz /srv/manpages.debian.org/debiman/piuparts/experimental.json.gz) || true

(wget --ca-certificate=/etc/ssl/ca-debian/ca-certificates.crt https://piuparts.debian.org/for-manpages.d.o/buster.json.gz -O /srv/manpages.debian.org/debiman/piuparts/.testing.json.gz && mv /srv/manpages.debian.org/debiman/piuparts/.testing.json.gz /srv/manpages.debian.org/debiman/piuparts/testing.json.gz) || true

ulimit -c unlimited
PATH=/srv/manpages.debian.org/debiman/mandoc-batch:$PATH \
TMPDIR=/srv/manpages.debian.org/tmp/ \
  flock /srv/manpages.debian.org/debiman/exclusive.lock \
  nice -n 5 \
  ionice -n 7 \
  /srv/manpages.debian.org/debiman/gopath/bin/debiman \
  -inject_assets=/srv/manpages.debian.org/debiman/debian-assets \
  -alternatives_dir=/srv/manpages.debian.org/debiman/piuparts/ \
  -sync_codenames=oldstable,oldstable-backports,stable,stable-backports \
  -sync_suites=testing,unstable,experimental \
  -serving_dir=/srv/manpages.debian.org/www \
  -local_mirror=/srv/mirrors/debian $@

# reload the index
pkill -u manpages -HUP -f debiman-auxserver

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
/usr/sbin/httxt2dbm -f DB -i ${TMPDIR}/rwmap.txt -o ${TMPDIR}/rwmap.dbm
# Currently unused, but would be better to keep around and sync once the static
# mirror infrastructure supports post-processing:
# mv ${TMPDIR}/rwmap.txt /srv/manpages.debian.org/www/rwmap.txt
mv ${TMPDIR}/rwmap.dbm /srv/manpages.debian.org/www/rwmap.dbm
