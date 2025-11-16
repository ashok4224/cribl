#!/bin/bash
set -e
yum update -y
yum install -y curl wget unzip jq
mkdir -p /opt/cribl
cd /opt/cribl
wget https://cdn.cribl.io/cribl-4.0.0.tgz -O cribl.tgz
tar -xzf cribl.tgz
