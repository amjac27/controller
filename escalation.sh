#!/bin/bash

cd $1
tar xzvf attack.tar.gz
pip3 install cryptography
python3 attack/start.py