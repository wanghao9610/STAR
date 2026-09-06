---
name: star-env-builder
description: >-
  从已有依赖来源创建、修复或扩展项目的 conda 环境或 venv，并核验导入、框架支持与入口。用于执行缺少可用
  解释器或需要新增包时；绝不删除已有环境。
---

# Research Env Builder

调用方式：`star-env-builder [ENV_NAME | add <包名>…] [描述]`。先解析 `add`，其后每个包名都属于该模式；否则使用给定环境名或 `.env` 的 `CODE_NAME`。自然语言可设定需求或授权构建；仅在环境目标、依赖选择、成本或破坏性处理尚未解决时提问。

**共享规约。** 先解析调用目标和模式，再读取 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md` 中本目标实际涉及的节；进入具体分支或模式时才读取它引用的 `references/` 与 `assets/`。从 `.env` 读取一次本次需要的 `STAR_LANG`、`INVOLVE`、`STAR_*_MODEL` 与运行时键；已有取值和仍逐字可见的规约内容直接复用。按规约 §7.6 解析语言：先看用户明确要求，再看有效的 `STAR_LANG`，最后取对话或调用文本语言；使用对应的本地化资源。`SKILL_zh.md` 仅供人阅读，运行时不装载。已有文档保持其 frontmatter 语言。清楚的自然语言指令可以同时选定目标、范围并授权对应动作；不要重复询问已经明确授权的事项。

**把档位模型传给受托者。** 派发前取 `claude` 条目，没有则取不带标签的备选。该档每次派发都把解析值传给 `Agent` 的 `model`；键为空则省略。模型须为当前工具所接受，后文规定的角色与写入限制照旧。盲读只拿产物与量表，不继承产出该工作的对话。模型不可用就留在这里并说明一条原因；派发被拒后，须确认它尚未开始工作才能退回本地。受托者从自己的会话溯源解析实际模型，不从请求中的别名或父会话转录取值。

## 角色

你负责给代码库一个能跑的运行时。上游的 `star-code-architect` 把 `${CODE_NAME}/` 搭了起来，但止步于环境——它的运行时跑通性检查步骤只准备安装命令并移交用户（红线）。下游的 `star-plan-executor` 所有命令都走 `.env` 指向的环境，并假设它可用。本 skill 产出这个环境：按 `.env` 解析出的 conda 环境或 `.venv`、缺失时补齐的 `${CODE_NAME}/requirements/` 依赖布局，以及 `wkdrs/` 下有证据支撑的环境报告。

你**构建环境，不实现也不重构研究代码。**写入 `${CODE_NAME}/` 的只有生成的 requirements 文件。若需要改代码才能让项目可导入，交棒给 `star-plan-executor`。

## 核心原则

1. **`.env` 是唯一路径来源；从不 activate**（规约 §3）。一次性解析出目标解释器——`ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` 或 `<项目根>/.venv/bin/python`——之后所有命令都走这个绝对路径。环境归本 skill 所有：只有它能创建、重命名环境或往里安装。
2. **展示安装计划，只问仍未解决的实质选择。**清楚要求构建或扩展指定环境，在依赖与成本未超出该请求时已授权对应计划。只有环境目标、依赖集、CUDA 选择、成本或已有环境处理仍未解决时才通过 AskUserQuestion 提问；已定内容自主执行。
3. **只改名，绝不删除。**已有环境重命名为 `<名称>_<YYYYMMDD>` 作备份——日期取运行时的 `date +%Y%m%d`，绝不编造。过期备份由用户自行清理。
4. **类别即策略；安装优先顺序是 uv > pip > conda。**framework（CUDA 耦合、锁定 wheel 源）/ runtime（普通 PyPI）/ optional（日志、可视化、开发附加）/ conda.txt（需系统隔离的项）。每类有自己的安装方式与失败处理：优先 uv，逐包改用 pip，conda 只用于白名单且仅限 conda 后端。策略见 `references/installer_policy_zh.md`。
5. **沿用已有的，只生成缺失的。**生成依赖时打包元数据优先于 import 扫描（`references/dependency_resolution_zh.md`），落入 requirements.txt 加 requirements/ 文件夹，构建验证通过后提交。
6. **证据式验收。**主 agent 亲自做三层跑通性检查（`references/runnable_check_spec_zh.md`），报告"验证了什么"并附证据，而不是一句"能用了"（CLAUDE.md §11）。报告与版本清单写入 `wkdrs/env_<ENV_NAME>_<日期>/`。

## 工作流

**本次运行在哪里执行。** Step 0 前按规约 §10.8 在 EXEC 档处理整次运行的交接。对具体环境、依赖集与成本的既有授权同样有效；只有必需决定仍未解决时才留在这里。

### Step 0：预检

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. `ENV_NAME` := 参数，否则 `CODE_NAME`。参数为 `add <包名>…` 则进入 **add 模式**：直接跳到 Step 8，目标是 `.env` 已指向的环境——不创建、不改名、不重建。
3. 探测并记录（供安装计划与报告用）：平台 + 架构；`nvidia-smi`（驱动支持的 CUDA 上限）；`nvcc --version` / `CUDA_HOME`（本机 toolkit，常缺失）；`$CONDA_HOME/bin/conda --version`；`uv --version`。
4. `${CODE_NAME}/` 缺失或实质为空 → 没有依赖来源；建议先跑 `star-code-architect`，用户仍想要则可只建裸环境（仅 python）。

### Step 1：选择后端（确定性）

- `CONDA_HOME` 非空**且**路径存在 → **conda 后端**：`$CONDA_HOME/bin/conda create -n <ENV_NAME> python=<X.Y> -y`。
- 否则 → **venv 后端**，位于 `<项目根>/.venv`：优先 `uv venv .venv --python <X.Y>`；其次 `$PYTHON_HOME/bin/python -m venv .venv`；最后 `python3 -m venv .venv`。此时 `ENV_NAME` 无意义——传了就说明一声再继续。
- Python 版本：`requires-python`（pyproject.toml）→ `python_requires`（setup.py / setup.cfg）→ 上游 README 声明的版本 → 默认 3.10。信号冲突 → 问。
- 记录 `ENV_PY`（绝对路径），之后每条命令都用它。

### Step 2：环境已存在时

- conda：`conda env list` 中已有 `<ENV_NAME>` → 先执行此前已明确的重建或修复选择；否则在**备份重建**、**原地验证修复**、**中止**之间问一次，并说明 clone 备份可能短暂翻倍磁盘占用。
- venv：`.venv` 已存在 → 同样执行既有选择或问一次；备份为 `mv .venv .venv_$(date +%Y%m%d)`。说明移动后的 venv 因脚本保留旧绝对路径，只是冻结备份。
- 备份名已被占用 → 追加 `-<HHMM>`（同样取自 `date`）。

### Step 3：解析依赖（先到先用）

方法与映射表见 `references/dependency_resolution_zh.md`。

1. `${CODE_NAME}/requirements.txt` 或 `${CODE_NAME}/requirements/` 已存在 → 按原样采用；绝不改写、重排或"优化"。
2. 否则读打包元数据——`pyproject.toml [project.dependencies]`、`setup.py` / `setup.cfg` 的 `install_requires`、`environment.yml`——转写进生成的 requirements 文件，版本约束逐字保留。
3. 否则 import 扫描：提取 `${CODE_NAME}/` 的 AST 顶层 import → 去掉 stdlib 与本地模块 → import 名映射到 PyPI 发行名（未知名先上 PyPI 验证）→ 写入布局，除已知耦合组外不锁版本。

生成布局：`requirements.txt` 只放 `-r requirements/framework.txt` 与 `-r requirements/runtime.txt`（optional 以注释给出）；`requirements/framework.txt` 开头写匹配好的 `--extra-index-url`；conda 专属项进 `requirements/conda.txt` 并注明"用 conda 装，不用 pip"。现在写好，Step 7 构建验证后再提交。

### Step 4：定下安装计划

展示后端、环境、Python 版本、依赖来源、包数与锁定、torch↔CUDA 匹配、大 wheel 下载量级、conda 专属项及未解决冲突。请求已授权这份确切计划、且没有新增实质成本或选择时，直接执行并记录授权；否则通过 AskUserQuestion 只问一次构建、调整或中止。绝不隐藏不确定项。

### Step 5：安装（uv > pip > conda）

策略、白名单与 wheel 源矩阵见 `references/installer_policy_zh.md`。顺序：`conda.txt`（仅 conda 后端）→ `framework.txt` → `runtime.txt` → `optional.txt`（仅当获批）→ 项目可编辑安装（`--no-deps -e`，有打包元数据时）。

- 有 uv → `uv pip install --python $ENV_PY -r <文件>`；无 uv → 问一次：装 uv / 本次改用 pip。
- 单包失败 → 改用 pip 重试（每包总计 ≤2 次）→ 仍失败：记录后继续装其余，最后统一解决或移交。
- venv 后端遇到 conda 专属项 → 停下来问：用户自行系统级安装 / 跳过 / 有 pip 替代品则用它。
- 需要源码编译的项（flash-attn 之类）→ 红线：把确切命令写进报告，不执行。
- 尊重已配置的 `PIP_INDEX_URL` / `UV_DEFAULT_INDEX`；绝不写全局配置。

### Step 6：跑通性检查（三层，主 agent 亲自跑）

规范与证据格式见 `references/runnable_check_spec_zh.md`。

- **L1 import**：framework + runtime（以及已安装的 optional）中每个发行包都能通过 `$ENV_PY` 导入并报出版本。
- **L2 框架**：`torch.cuda.is_available()` + 设备数 + 在设备上做一次小张量运算（macOS 用 mps；纯 CPU 机器如实注明，不算失败）。
- **L3 项目**：`$ENV_PY -m compileall -q ${CODE_NAME}`；已做可编辑安装则 `import <包名>`，否则跑最便宜的入口（`--help`，或 `pytest --collect-only -q`）。不碰数据、不碰权重、不下载——分钟级，不是小时级。

某层失败 → 按 traceback 诊断并修复（缺失的传递依赖补进对应的生成 requirements 文件），重跑；每层 ≤2 轮修复 → 仍失败：标记 `blocked` 并附错误尾部，相互独立的层继续跑。

### Step 7：报告、版本清单、提交

1. 按 `assets/env_report_template_zh.md` 写 `wkdrs/env_<ENV_NAME>_<YYYYMMDD>/ENV_REPORT.md`：身份信息 + `ENV_PY`、机器探测、备份改名、各类别安装结果、带证据的跑通性检查结果表、失败/blocked 项、待用户命令。
2. `uv pip freeze --python $ENV_PY`（或 `$ENV_PY -m pip freeze`）→ 同目录 `freeze.txt`。
3. 本次生成的 requirements 文件（含跑通性检查排错时补充的依赖）现在提交：`star-env-builder: add requirements layout`，只暂存 `${CODE_NAME}/requirements*`。
4. `.env` 的 `PYTHON_HOME` 解析不到刚验证过的 `ENV_PY` → 该项配置变更已有明确授权时更新；否则展示一行变更并询问，因为它会改变关键运行时输入。
5. 聊天汇报 ≤500 字：验证了什么（附证据）、失败项、待用户命令。**向下游交棒：**`star-plan-executor <leaf>` 现在有运行时了；`star-flow-status` 查看下一步。


### Step 8：新增依赖（仅 add 模式）

`add <包名>…` 只跑这一步，它的七项——解析 `ENV_PY`、给每个包定类别、安装前必须过的确认点、按 uv > pip > conda 分层安装、只针对新包的跑通性检查、依赖文件与报告的更新，以及收尾汇报——在 `references/add_mode_zh.md`，是这个模式时才读，之前不读。建环境或修环境的运行完全不读它。

## 状态与文件规则

- 只写这些位置：环境本身（`$CONDA_HOME/envs/` 之下或 `<项目根>/.venv`）、`${CODE_NAME}/requirements*`（仅在生成缺失布局或补验证过的缺口时）、`wkdrs/env_<ENV_NAME>_<日期>/`，以及——仅经用户明确确认——`.env` 里的 `PYTHON_HOME=` 一行。绝不碰源代码、`metds/plans/*` 或其他 skill 的产物。
- 绝不删除环境；备份一律用运行时真实日期改名。绝不编造时间戳。
- Git：每次运行至多一次提交——生成 requirements 文件时，或 add 模式下装包时——只 stage `${CODE_NAME}/requirements*`（规约 §1）。
- 签出停在并非本次运行目标的执行分支上时，提交会随那个叶子一起合并：在这种分支上提交之前先说明，并提议先切回去（规约 §11）。
- 已授权安装自主执行，包括已披露的框架级下载。STOP line 仍覆盖 `sudo` 或系统包管理器、驱动或 CUDA toolkit 系统安装、CUDA 源码编译、超过约 10 GB 的下载和删除环境；这些只准备准确命令。
- 尊重用户镜像配置（`PIP_INDEX_URL`、`UV_DEFAULT_INDEX`）；绝不写 `pip config`、`.condarc` 或 `uv.toml`。
- 重复调用：已有匹配的 `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` 且环境存在 → 优先走 **原地验证修复**（Step 2）——从报告中的失败项续跑，而不是重建。

## 对话纪律

- 按规约 §7.2 与 §7.7 处理。同一目标、包集与已披露成本的既有授权继续有效；只有这些实质输入仍未解决时才通过 AskUserQuestion 问一个具体问题，工具不可用时退回简洁纯文本。
- `ENV_REPORT.md` 正文语言跟随对话语言；中文报告中专业术语保留英文。
