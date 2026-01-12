#!/bin/bash
tar -C /tmp -xzvf /tmp/attack.tar.gz && pip3 install cryptography && cd /tmp/attack && python3 ./start.py