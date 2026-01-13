#!/usr/bin/env python3
import subprocess
import sys

# 普通用户名，根据您的实际情况修改
NORMAL_USER = "delo"

def main():
    print("1. 以root权限执行new.py...")
    # 直接运行new.py（当前是root）
    result1 = subprocess.run(["python3", "lock.py"])
    if result1.returncode != 0:
        print("lock.py执行失败")
        sys.exit(1)
    
    print("2. 切换到普通用户执行winset.py...")
    # 使用su切换到普通用户执行winset.py
    
    result2 = subprocess.run(["python3", "winset.py"])
    if result2.returncode != 0:
        print("winset.py执行失败")
        sys.exit(1)
    
    print("两个脚本都执行成功")
    sys.exit(0)

if __name__ == "__main__":
    main()
