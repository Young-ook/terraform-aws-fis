#!/bin/bash -x

BZT_DIR=/opt/bzt
mkdir -p $BZT_DIR

cat <<EOF >> $BZT_DIR/config.yaml
${config}
EOF

cat <<EOF >> $BZT_DIR/test.py
${task}
EOF

### Setup taurus
pip3 install bzt zope.event
chmod 644 $BZT_DIR/config.yaml $BZT_DIR/test.py

### How to run test
# First, chage the working directory that you have permission to write a log fils.
# And run taurus test suite  with config file.
# ~$ cd $HOME
# ~$ bzt /opt/config.yaml
