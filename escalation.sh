#!/bin/bash
cd /tmp && tar -xzvf /tmp/attack.tar.gz && pip3 install cryptography && cd attack && python3 ./start.py