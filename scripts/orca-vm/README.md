# 每工作区环境（本机 Docker）

本目录实现 `orca.yaml` 里 `docker-sandbox` recipe 的全部生命周期脚本。每个 Orca
工作区都会从一个预先建好的镜像启动一个一次性容器，容器内跑 headless 的
`orca serve`，桌面端以 `pairingCode` 配对。

## 一次性准备

```bash
# 1. 建基础镜像（需要 Docker Desktop 已启动、gh 已登入）
bash scripts/orca-vm/docker-base-image.sh

# 2. 把 claude 与 codex 登入一次，并把登入状态固化成 :auth 镜像
bash scripts/orca-vm/docker-base-auth.sh start
#    照它印出的两行在自己的终端跑完登入（会给 URL 与配对码）
bash scripts/orca-vm/docker-base-auth.sh finish

# 3. 静态检查与端到端自测
orca vm recipe doctor docker-sandbox --json
orca vm recipe doctor docker-sandbox --provision --json
```

## 文件

| 文件                            | 作用                                                      |
| ------------------------------- | --------------------------------------------------------- |
| `Dockerfile`                    | 基础镜像：Node 24、pnpm、git、gh、Orca server、预热的仓库 |
| `bin/orca-git-askpass`          | 镜像内的 git 凭据助手，只从 `GH_TOKEN` 取值               |
| `bin/orca-sync-repo`            | 把预热 checkout 同步到目标 ref，commit 变了才重装依赖     |
| `bin/orca-serve-recipe`         | 启动 `orca serve --recipe-json` 并回传那份 JSON           |
| `docker-base-image.sh`          | 下载并校验 Orca server tarball，建基础镜像                |
| `docker-base-auth.sh`           | `start`／`finish` 两段：登入 agent，提交 `:auth` 镜像     |
| `docker-create.sh`              | 每个工作区的 create：起容器、同步仓库、启动 runtime       |
| `docker-suspend.sh`             | `docker stop`                                             |
| `docker-resume.sh`              | 重启容器与 runtime，并重发 recipe JSON（端口会变）        |
| `docker-destroy.sh`             | `docker rm -f`                                            |
| `docker-*.cmd`                  | Windows 包装：Orca 用 `cmd.exe` 跑 recipe，无法直接跑 `.sh` |
| `docker-state.json`             | 非机密的接线值：镜像名、端口、仓库 URL／ref、projectRoot  |

在 macOS／Linux 桌面上使用时，把 `orca.yaml` 的四个命令指向同名的 `.sh`。

## 约定与注意事项

- **机密一律不落盘**。GitHub token 只经 `docker run --env` 临时传进容器，供
  `orca vm env doctor` 的 dry-run push 使用；agent 的登入状态只存在 `:auth` 镜像里。
  基础镜像与 auth 容器都不带 token，所以 `docker commit` 不会把它固化进镜像。
- **镜像 tag 是固定的**（`orca-xihan-ui:base`、`orca-xihan-ui:auth`），所以
  `docker-state.json` 里的 `snapshotId` 从一开始就填好，脚本不需要在运行时改写它。
  这是跟云端 provider（快照 id 随机）唯一的差别。
- **提交 `:auth` 镜像前会清掉 Orca runtime 的 user-data 目录**。那里面有配对密钥与
  设备注册表，固化进镜像会让所有工作区共用同一个身份。
- **`docker stop` 之后 Docker 会重新分配宿主端口**，所以 `resume` 必须重发
  recipe JSON，不能复用 create 时那份。
- 镜像里没有装 Chromium。要跑 `pnpm test:browser`，在容器内执行
  `cd ui && pnpm exec playwright install --with-deps chromium`（需要 root）。
