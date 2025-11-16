#!/bin/bash
set -e
cd /opt/cribl/cribl/bin
./cribl start
systemctl enable cribl
