---
name: star-env-builder
description: >-
  构建并验证项目的 Python 运行环境，让计划执行有可用的解释器。读取 .env：CONDA_HOME 有效则用它创建
  conda 环境 ENV_NAME（参数，缺省为 CODE_NAME）；否则在项目根创建 .venv。已存在的环境绝不删除——
  经用户确认后重命名为带日期的备份（运行时真实日期）再重建。依赖按"先到先用"解析：已有的
  CODE_NAME/requirements* → 打包元数据（pyproject / setup.py / environment.yml）→ 代码 import
  扫描，生成结果写入两层布局（requirements.txt 只引用 requirements/framework|runtime|optional.txt；
  conda 专属项进 requirements/conda.txt）。经由唯一一道安装计划门，用 uv > pip > conda 阶梯安装，
  框架 wheel 按探测到的 CUDA 匹配；随后分三层冒烟测试（import → 框架/GPU → 项目入口），把
  ENV_REPORT.md 和版本快照写入 wkdrs/。只要用户运行 /star-env-builder、想为项目创建或重建
  conda 环境或 venv、需要解析并安装依赖、或想验证运行环境时，都应使用本 skill。
  Bilingual (中/英) — also trigger in English whenever the user wants the project's conda
  env or venv created or rebuilt, needs dependencies resolved and installed, or wants the
  runtime environment verified.
---

# Research Env Builder — 研究环境构建师

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/star-env-builder [ENV_NAME | add <包名>…]`——要创建的 conda 环境名，不传则用 `.env` 中的 `CODE_NAME`；`add` 则把一个或多个包装进 `.env` 已指向的环境，并记入 requirements 布局。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你负责给代码库一个能跑的运行时。上游的 `star-code-architect` 把 `${CODE_NAME}/` 落了地，但止步于环境——它的运行时冒烟步骤只准备安装命令并移交用户（STOP 线）。下游的 `star-plan-executor` 所有命令都走 `.env` 指向的环境，并假设它可用。本 skill 就负责产出这个环境：按 `.env` 解析出的 conda 环境或 `.venv`、缺失时补齐的 `${CODE_NAME}/requirements/` 依赖布局，以及 `wkdrs/` 下有证据支撑的环境报告。

你**构建环境，不实现也不重构研究代码。**写入 `${CODE_NAME}/` 的只有生成的 requirements 文件。若需要改代码才能让项目可导入，交棒给 `star-plan-executor`。

## 核心原则

1. **`.env` 是唯一路径来源；从不 activate**（规约 §3）。一次性解析出目标解释器——`ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` 或 `<项目根>/.venv/bin/python`——之后所有命令都走这个绝对路径。环境归本 skill 所有：只有它可以创建、重命名环境或往里安装。
2. **一道门，场景化追问。**唯一的门是安装计划批准（Step 4）：门前不装任何东西；门覆盖的内容之后自主执行。场景化问题——覆盖已有环境、CUDA 不匹配、uv 缺失、venv 后端遇到 conda 专属依赖——遇到时用 AskUserQuestion 问，每次只问一题，都带推荐项。
3. **只改名，绝不删除。**已有环境通过重命名为 `<名称>_<YYYYMMDD>` 备份——日期用运行时的 `date +%Y%m%d` 获取，绝不编造。本 skill 永不删除任何环境；过期备份由用户自行清理。
4. **类别即策略；阶梯是 uv > pip > conda。**framework（CUDA 耦合、锁定 wheel 源）/ runtime（普通 PyPI）/ optional（日志、可视化、开发附加）/ conda.txt（需系统隔离的项）。每个类别有自己的安装路由与失败处理：优先 uv，逐包降级 pip，conda 只用于白名单且仅限 conda 后端。策略见 `references/installer_policy_zh.md`。
5. **沿用已有的，只生成缺失的。**已有 requirements 布局按原样安装，绝不改写。生成依赖时打包元数据优先于 import 扫描（`references/dependency_resolution_zh.md`），落入两层布局，构建验证通过后作为代码资产提交。
6. **证据式验收。**主循环亲自跑三层冒烟测试（`references/smoke_test_spec_zh.md`），报告"验证了什么"并附证据，而不是一句"能用了"（CLAUDE.md §7）。Chats end, files do not：报告与版本快照写入 `wkdrs/env_<ENV_NAME>_<日期>/`。

## 工作流

### Step 0：预检

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. `ENV_NAME` := 参数，否则 `CODE_NAME`。若参数是 `add <包名>…`，则选中 **add 模式**：直接跳到 Step 8，目标是 `.env` 已指向的那个环境——不创建、不改名、不重建。
3. 探测并记录（供安装计划与报告使用）：平台 + 架构；`nvidia-smi`（驱动支持的 CUDA 上限）；`nvcc --version` / `CUDA_HOME`（本机 toolkit，常缺失）；`$CONDA_HOME/bin/conda --version`；`uv --version`。
4. `${CODE_NAME}/` 缺失或实质为空 → 没有依赖来源；建议先跑 `/star-code-architect`，用户坚持则可只建裸环境（仅 python）。

### Step 1：选择后端（确定性）

- `CONDA_HOME` 非空**且**路径存在 → **conda 后端**：`$CONDA_HOME/bin/conda create -n <ENV_NAME> python=<X.Y> -y`。
- 否则 → **venv 后端**，位于 `<项目根>/.venv`：优先 `uv venv .venv --python <X.Y>`；其次 `$PYTHON_HOME/bin/python -m venv .venv`；最后 `python3 -m venv .venv`。此时 `ENV_NAME` 参数无意义——若传了就说明一声，然后继续。
- Python 版本：`requires-python`（pyproject.toml）→ `python_requires`（setup.py / setup.cfg）→ 上游 README 声明 → 默认 3.10。信号冲突 → 问。
- 记录 `ENV_PY`（绝对路径），之后每条命令都用它。

### Step 2：冲突处理

- conda：`conda env list` 中已有 `<ENV_NAME>` → 问一个三选项问题：**备份重建**（用 `conda rename` 改名为 `<ENV_NAME>_$(date +%Y%m%d)`；老版 conda 没有 `rename` 则 `create --clone` + `remove`，提示磁盘占用临时翻倍）/ **原地验证修复**（跳过创建；直接进 Step 5 处理失败项或 Step 6——上次运行被打断时的续跑路径）/ **中止**（干净退出，不动任何东西）。
- venv：`.venv` 已存在 → 同样的三选项 → 备份为 `mv .venv .venv_$(date +%Y%m%d)`。报告中注明：改名后的 venv 脚本里嵌着旧绝对路径——只是冻结备份，供查档回滚，不能直接激活。
- 备份名已被占用 → 追加 `-<HHMM>`（同样取自 `date`）。

### Step 3：解析依赖（先到先用）

方法与映射表见 `references/dependency_resolution_zh.md`。

1. `${CODE_NAME}/requirements.txt` 或 `${CODE_NAME}/requirements/` 已存在 → 按原样采用；绝不改写、重排或"优化"。
2. 否则读打包元数据——`pyproject.toml [project.dependencies]`、`setup.py` / `setup.cfg` 的 `install_requires`、`environment.yml`——转写进两层布局，版本约束逐字保留。
3. 否则 import 扫描：对 `${CODE_NAME}/` 做 AST 顶层 import 提取 → 去掉 stdlib 与本地模块 → import 名映射到 PyPI 发行名（未知名先上 PyPI 验证）→ 写入布局，除已知耦合组外不锁版本。

生成布局：`requirements.txt` 只放 `-r requirements/framework.txt` 与 `-r requirements/runtime.txt`（optional 以注释形式给出）；`requirements/framework.txt` 开头写匹配好的 `--extra-index-url`；conda 专属项进 `requirements/conda.txt` 并注明"用 conda 装，不用 pip"。文件现在写好，提交推迟到 Step 7 构建验证之后。

### Step 4：门——用户批准安装计划

以普通文本呈现：后端 + 环境名 + python 版本；采用的依赖来源；各类别包数与关键锁定；torch↔CUDA 匹配（探测到的驱动上限 vs 选定的 wheel 源）；大 wheel 的下载量级；conda.txt 项；已标记的不确定项（CUDA 不匹配、未解析 import、版本冲突）。随后用 AskUserQuestion 问：*批准并构建* / *调整（说明哪里）* / *中止*。所有不确定项在此处解决——绝不悄悄带过。

### Step 5：安装（阶梯路由）

策略、白名单与 wheel 源矩阵见 `references/installer_policy_zh.md`。顺序：`conda.txt`（仅 conda 后端）→ `framework.txt` → `runtime.txt` → `optional.txt`（仅当获批计划包含）→ 项目可编辑安装（`--no-deps -e`，有打包元数据时）。

- 有 uv → `uv pip install --python $ENV_PY -r <文件>`；无 uv → 问一次：装 uv / 本次改用 pip。
- 单包失败 → 降级 pip 重试（每包总计 ≤2 次）→ 仍失败：记录后继续装其余，最后统一解决或移交。
- venv 后端遇到 conda 专属项 → 停下来问：用户自行系统级安装 / 跳过 / 有 pip 替代品则用替代品。
- 需要源码编译的项（flash-attn 之类）→ STOP 线：把确切命令写进报告，不执行。
- 尊重已配置的 `PIP_INDEX_URL` / `UV_DEFAULT_INDEX`；绝不覆盖用户镜像，绝不写全局配置。

### Step 6：冒烟测试（三层，主循环亲自跑）

规范与证据格式见 `references/smoke_test_spec_zh.md`。

- **L1 import**：framework + runtime（以及已安装的 optional）中每个发行包都能通过 `$ENV_PY` 导入并报出版本。
- **L2 框架**：`torch.cuda.is_available()` + 设备数 + 在设备上做一次小张量运算（macOS 用 mps；纯 CPU 机器如实注明，不算失败）。
- **L3 项目**：`$ENV_PY -m compileall -q ${CODE_NAME}`；已做可编辑安装则 `import <包名>`，否则跑最便宜的入口（`--help`，或 `pytest --collect-only -q`）。不碰数据、不碰权重、不下载——分钟级，不是小时级。

某层失败 → 按 traceback 诊断并修复（缺失的传递依赖要补进对应的生成 requirements 文件），重跑该层；每层 ≤2 轮修复 → 仍失败：标记 `blocked` 并附错误尾部，相互独立的层继续跑。

### Step 7：报告、快照、提交

1. 按 `assets/env_report_template_zh.md` 写 `wkdrs/env_<ENV_NAME>_<YYYYMMDD>/ENV_REPORT.md`：身份信息 + `ENV_PY`、机器探测、备份改名、各类别安装结果、带证据的冒烟矩阵、失败/blocked 项、待用户命令。
2. `uv pip freeze --python $ENV_PY`（或 `$ENV_PY -m pip freeze`）→ 同目录 `freeze.txt`。
3. 本次生成的 requirements 文件（含冒烟诊断中补充的依赖）现在提交：`star-env-builder: add requirements layout`，只暂存 `${CODE_NAME}/requirements*`。
4. `.env` 的 `PYTHON_HOME` 解析不到刚验证过的 `ENV_PY` → 下游 skill 从 `.env` 解析运行时：主动提出把 `PYTHON_HOME` 指向刚建好的环境（conda：`$CONDA_HOME/envs/<ENV_NAME>`；venv：`<项目根>/.venv`）——必须经明确确认才写。
5. 聊天汇报 ≤400 字：验证了什么（附证据）、失败项、待用户命令。**向下游交棒：**`/star-plan-executor <leaf>` 现在有运行时了；`/star-plan-status` 查看下一步。


### Step 8：新增依赖（仅 add 模式）

环境已经存在；本模式只往里装，并记录装了什么。它不创建、不改名、不重建——环境坏了是一次完整 run 的事（Step 2 的*就地校验与修复*）。

1. 按原则 1 从 `.env` 解析 `ENV_PY`。没有可用解释器 → 如实说明并建议跑一次完整的 `/star-env-builder`；什么都不装。
2. 按 `references/installer_policy_zh.md` 给每个包归类——framework / runtime / optional / conda 专属——并说明各自会落进哪个 requirements 文件。
3. **门**（原则 2——门前不装任何东西）：呈现这些包、它们的类别、将要使用的版本与索引源、下载量大时给出量级、以及任何 CUDA 耦合；询问*批准并安装* / *调整* / *中止*。
4. 走阶梯安装（uv > pip > conda；conda 仅在 conda 后端下、且仅限白名单）。需要源码编译的项留在 STOP 线上：把确切命令备好，不要跑。
5. 只对新增的包做冒烟（`references/smoke_test_spec_zh.md`）：L1——每个包都能经 `$ENV_PY` 导入并报出版本；新增的 framework 包再加 L2。失败 → 诊断，有限重试一次，仍失败则标记 `blocked` 并汇报；绝不留下"装了但没验证"的包。
6. 把每个装好的包追加进它所属的 requirements 文件，保留该布局既有的顺序与锁定。在最新的 `wkdrs/env_<ENV_NAME>_<日期>/ENV_REPORT.md` 追加一个 `## Added <日期>` 块（没有报告就新写一份）。提交：`star-env-builder: add <包名>`，只暂存 `${CODE_NAME}/requirements*`。
7. 汇报 ≤400 字：装了什么、各 requirements 文件增加了什么、冒烟证据、blocked 或待用户处理的项。

## 状态与文件规则

- 只写这些位置：环境本身（`$CONDA_HOME/envs/` 之下或 `<项目根>/.venv`）、`${CODE_NAME}/requirements*`（仅在生成缺失布局或补验证过的缺口时）、`wkdrs/env_<ENV_NAME>_<日期>/`，以及——仅经用户明确确认——`.env` 里的 `PYTHON_HOME=` 一行。绝不碰源代码、`metds/plans/*` 或其他 skill 的产物。
- 绝不删除环境；备份一律用运行时真实日期改名。绝不编造时间戳。
- Git：每次运行至多一次提交——生成了 requirements 文件时，或 add 模式下装了包时——只 stage `${CODE_NAME}/requirements*`（规约 §1）。
- 门批准过的安装自主执行，包括框架级别的大下载。无论是否批准都在 STOP 线外：`sudo` 或系统包管理器（apt / brew）、驱动或 CUDA toolkit 的系统级安装、CUDA 源码编译（flash-attn 类构建）、超过约 10 GB 的下载、删除任何环境。这些以确切命令写进报告移交。
- 尊重用户镜像配置（`PIP_INDEX_URL`、`UV_DEFAULT_INDEX`）；绝不写 `pip config`、`.condarc` 或 `uv.toml`。
- 重复调用语义：若已有匹配的 `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` 且环境存在，优先走 **原地验证修复**（Step 2）——从报告中的失败项续跑，而不是重建。

## 对话纪律

- 门与所有场景化问题都走 AskUserQuestion——每次调用只问一题，都带推荐项。不可用时（无头/脚本化）回退为普通文本，仍一次一题；安装计划必须先收到明确的批准文字才能开始安装。
- 用户用什么语言就用什么语言对话；中文对话加载 `*_zh.md` 资源。
- `ENV_REPORT.md` 正文语言跟随对话语言；中文报告中专业术语保留英文。
