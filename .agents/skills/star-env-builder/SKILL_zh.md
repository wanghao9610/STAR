---
name: star-env-builder
disable-model-invocation: true
description: >-
  构建并验证项目的 Python 运行环境，让计划执行拥有可用解释器。读取 .env：有效的
  CONDA_HOME 会创建 conda 环境 ENV_NAME（参数；默认 CODE_NAME），否则在项目根目录
  创建 .venv。绝不删除现有环境——经用户确认后，先把它重命名为带日期的备份（真实
  运行日期），再重建。依赖按首个信号优先解析：现有 CODE_NAME/requirements* →
  包元数据（pyproject / setup.py / environment.yml）→ 扫描代码 import；生成结果
  写成两层布局（requirements.txt 引用
  requirements/framework|runtime|optional.txt；仅 conda 项写入
  requirements/conda.txt）。在单一安装计划审批门后，通过 uv > pip > conda 梯级
  安装，并按 CUDA 情况选择框架 wheel；随后做三层冒烟测试（import → 框架/GPU →
  项目入口），在 wkdrs/ 下写入 ENV_REPORT.md 和版本冻结文件。当用户调用
  $star-env-builder，或要求 Codex 创建/重建项目 conda env 或 venv、解析并安装依赖、
  验证运行环境时使用。支持中英文双语工作。
---

# 研究环境构建器

匹配用户使用的语言。中文对话加载 `*_zh.md` 资源；否则加载无后缀资源。

调用方式：`$star-env-builder [ENV_NAME | add <package>…]` —— 指定要创建的 conda 环境名；省略时使用 `.env` 中的 `CODE_NAME`。`add` 会把一个或多个包安装进 `.env` 已指向的环境，并记录到 requirements 布局中。

**共享约定。** 行动前阅读 `docs/mds/star-workflow/research-workflow-conventions.md`（中文：`research-workflow-conventions.zh-CN.md`）：§1 git、§2 STOP line、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话。这是所有 STAR skill 的共同基线；本文件规定此 skill 的专属规则，凡要求更严格之处以本文件为准。

## 角色

为代码库提供可用运行时。上游的 `$star-code-architect` 会把 `${CODE_NAME}/` 落盘，但止步于环境：它的 runtime-smoke 步骤只准备安装命令并交给用户（STOP line）。下游的 `$star-plan-executor` 通过 `.env` 环境运行每条命令，并假定该环境可用。本 skill 负责产出这个环境：从 `.env` 解析出的 conda env 或 `.venv`、缺失时在 `${CODE_NAME}/requirements/` 下生成的依赖布局，以及 `wkdrs/` 下有证据支撑的环境报告。

只构建环境；不要实现或重构研究代码。对 `${CODE_NAME}/` 的唯一写入是生成的 requirements 文件。若必须改代码才能让项目可 import，转交 `$star-plan-executor`。

## 核心原则

1. **`.env` 是唯一路径来源；绝不 activate**（约定 §3）。只解析一次目标解释器——`ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` 或 `<project>/.venv/bin/python`——之后每条命令都通过这个绝对路径运行。本 skill 拥有环境管理权：只有它可以创建、重命名环境或向环境安装内容。
2. **一道审批门；按情境提问。** 唯一审批门是安装计划审批（步骤 4）：审批前不安装任何内容；审批覆盖的内容在通过后自主执行。情境问题——覆盖现有环境、CUDA 不匹配、缺少 uv、venv 后端遇到 conda-only 依赖——出现时一次问一个；有 Codex 结构化用户输入工具时使用该工具，否则使用一个简洁的纯文本问题；每次标出推荐项，并在行动前等待明确答复。
3. **只重命名，绝不删除。** 现有环境通过重命名备份为 `<name>_<YYYYMMDD>`——日期必须在运行时由 `date +%Y%m%d` 取得，绝不编造。本 skill 永远不删除环境；陈旧备份由用户自行清理。
4. **分类即策略；梯级是 uv > pip > conda。** framework（与 CUDA 耦合、固定 index）/ runtime（普通 PyPI）/ optional（日志、可视化、开发 extras）/ conda.txt（需要系统隔离的项）。每类都有自己的安装路线和失败处理：优先 uv，按包回退到 pip；conda 仅用于白名单，且只在 conda 后端使用。策略见 `references/installer_policy.md`。
5. **采用现有内容；只生成缺失内容。** 现有 requirements 布局按原样安装，绝不重写。生成依赖时，先读包元数据，再扫描 import（`references/dependency_resolution.md`），写入两层布局；构建验证通过后，将其作为代码资产提交。
6. **以证据验收。** 亲自运行三层冒烟测试（`references/smoke_test_spec.md`），报告带证据的验证结果，而不是笼统声称“可用”（AGENTS.md §7）。聊天会结束，文件不会：报告与版本冻结文件写入 `wkdrs/env_<ENV_NAME>_<date>/`。

## 工作流

### 步骤 0：预检

1. 读取 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（约定 §3）。
2. `ENV_NAME` := 参数；省略时取 `CODE_NAME`。若参数为 `add <package>…`，则选择 **add 模式**：跳到步骤 8，以 `.env` 已指向的环境为目标——不创建、不重命名、不重建任何环境。
3. 探测并记录（用于安装计划和报告）：平台与架构；`nvidia-smi`（驱动支持的 CUDA 上限）；`nvcc --version` / `CUDA_HOME`（本地 toolkit，通常不存在）；`$CONDA_HOME/bin/conda --version`；`uv --version`。
4. 若 `${CODE_NAME}/` 缺失或实际上为空，则没有依赖来源；推荐先运行 `$star-code-architect`，同时允许用户坚持先构建一个只有 Python 的裸环境。

### 步骤 1：确定后端（确定性规则）

- `CONDA_HOME` 非空且路径存在 → **conda 后端**：`$CONDA_HOME/bin/conda create -n <ENV_NAME> python=<X.Y> -y`。
- 否则 → 项目 `<project>/.venv` 下的 **venv 后端**：优先 `uv venv .venv --python <X.Y>`；否则 `$PYTHON_HOME/bin/python -m venv .venv`；最后回退 `python3 -m venv .venv`。此时 `ENV_NAME` 参数没有意义——若用户传入了就说明，然后继续。
- Python 版本：`requires-python`（pyproject.toml）→ `python_requires`（setup.py / setup.cfg）→ 上游 README 声明的版本 → 默认 3.10。信号冲突时询问用户。
- 记录 `ENV_PY`（绝对路径），后续每条命令都使用它。

### 步骤 2：处理冲突

- conda：`conda env list` 中已存在 `<ENV_NAME>` → 用一个问题提供三个选项：**备份并重建**（通过 `conda rename` 重命名为 `<ENV_NAME>_$(date +%Y%m%d)`；旧版 conda 没有 `rename` 时用 `create --clone` + `remove`，并警告磁盘占用会暂时翻倍）/ **原地验证并修复**（跳过创建；对失败项跳到步骤 5，否则跳到步骤 6——这是上次运行中断后的恢复路径）/ **中止**（干净退出，不触碰任何内容）。
- venv：`.venv` 已存在 → 同样的三选一问题 → 备份命令为 `mv .venv .venv_$(date +%Y%m%d)`。在报告中注明：移动后的 venv 脚本内仍嵌有旧绝对路径，因此它只是供参考和回滚的冻结备份，不是可 activate 的环境。
- 备份名已占用 → 追加 `-<HHMM>`（同样从 `date` 获取）。

### 步骤 3：解析依赖（首个信号优先）

配方与映射表见 `references/dependency_resolution.md`。

1. `${CODE_NAME}/requirements.txt` 或 `${CODE_NAME}/requirements/` 已存在 → 原样采用；绝不重写、重排或“改进”。
2. 否则使用包元数据——`pyproject.toml [project.dependencies]`、`setup.py` / `setup.cfg` 的 `install_requires`、`environment.yml`——转录到两层布局，保留全部版本约束。
3. 否则扫描 import：对 `${CODE_NAME}/` 的顶层 import 做 AST 扫描 → 排除 stdlib 和本地模块 → 把 import 名映射到 PyPI distribution（在 PyPI 验证未知项）→ 写入布局；除已知耦合组合外，版本均不固定。

生成布局：`requirements.txt` 只包含 `-r requirements/framework.txt` 和 `-r requirements/runtime.txt` 行（optional 以注释引用）；`requirements/framework.txt` 开头写入匹配的 `--extra-index-url`；conda-only 项写入 `requirements/conda.txt`，并加上“由 conda 安装，而非 pip”的头部。此时写文件，在构建验证后的步骤 7 提交。

### 步骤 4：审批门——用户批准安装计划

以普通文本展示：后端 + 环境名 + Python 版本；采用的依赖来源；各类别包数量和显著 pin；torch↔CUDA 匹配（检测到的驱动上限与所选 wheel index）；大型 wheel 的粗略下载量；conda.txt 项；任何已标记的不确定性（CUDA 不匹配、未解析 import、版本冲突）。然后只问一个问题——有 Codex 结构化用户输入工具时使用该工具，否则用纯文本：*批准并构建* / *调整（说明调整内容）* / *中止*——等待明确答复。所有不确定性都在这里解决，绝不静默处理。

### 步骤 5：安装（分层梯级）

策略、白名单和 wheel index 矩阵见 `references/installer_policy.md`。顺序：`conda.txt`（仅 conda 后端）→ `framework.txt` → `runtime.txt` → `optional.txt`（仅在获批计划包含它时）→ 有包元数据时以 editable 模式安装项目（`--no-deps -e`）。

- 有 uv → `uv pip install --python $ENV_PY -r <file>`；无 uv → 只询问一次：安装 uv / 本次使用 pip。
- 单包失败 → 通过 pip 重试（每个包合计 ≤2 次尝试）→ 仍失败：记录并继续其余包，最后解决或交给用户。
- venv 后端遇到 conda-only 项 → 停下询问：用户自行在系统级安装 / 跳过 / 使用存在时的 pip 替代品。
- 源码构建项（flash-attn 等）→ STOP line：在报告中准备准确命令，不运行。
- 尊重已有 `PIP_INDEX_URL` / `UV_DEFAULT_INDEX`；绝不覆盖用户镜像，绝不写全局配置。

### 步骤 6：冒烟测试（三层，直接运行）

规范和证据格式见 `references/smoke_test_spec.md`。

- **L1 imports**：framework + runtime 中的每个 distribution（以及已安装的 optional）都通过 `$ENV_PY` import 并报告版本。
- **L2 framework**：`torch.cuda.is_available()` + 设备数量 + 在该设备上执行小型 tensor 运算（macOS 使用 mps；仅 CPU 机器记为符合预期，不算失败）。
- **L3 project**：`$ENV_PY -m compileall -q ${CODE_NAME}`；若已 editable 安装，则执行 `import <package>`，否则运行成本最低的入口（`--help` 或 `pytest --collect-only -q`）。不需要数据、权重或下载——耗时应是分钟，不是小时。

某层失败 → 根据 traceback 诊断并修复（缺失的传递依赖写入正确的生成 requirements 文件），重新运行该层；每层最多 2 轮修复 → 仍失败则以错误末尾信息标记为 `blocked`，并在各自独立时继续后续项。

### 步骤 7：报告、快照、提交

1. 用 `assets/env_report_template.md` 写入 `wkdrs/env_<ENV_NAME>_<YYYYMMDD>/ENV_REPORT.md`：环境身份 + `ENV_PY`、机器探测、备份重命名、各类别安装结果、带证据的冒烟矩阵、失败/blocked 项、等待用户运行的命令。
2. 运行 `uv pip freeze --python $ENV_PY`（或 `$ENV_PY -m pip freeze`）→ 在报告旁写入 `freeze.txt`。
3. 此次生成的 requirements 文件（包括冒烟诊断期间新增的依赖）现在提交：`star-env-builder: add requirements layout`，仅暂存 `${CODE_NAME}/requirements*`。
4. 若 `.env` 的 `PYTHON_HOME` 无法解析到刚验证的 `ENV_PY`，则下游 skill 无法从 `.env` 找到该运行时：提议把 `PYTHON_HOME` 指向刚构建的环境（conda：`$CONDA_HOME/envs/<ENV_NAME>`；venv：`<project>/.venv`）——只有得到明确确认才能修改。
5. 对话报告 ≤400 词：验证了什么（含证据）、失败项、等待用户运行的命令。**转交下游：** `$star-plan-executor <leaf>` 现在拥有运行时；`$star-plan-status` 显示下一项工作。

### 步骤 8：添加包（仅 add 模式）

环境已经存在；此模式向其中安装并记录安装内容。它不创建、重命名或重建任何环境——损坏的环境应通过完整运行处理（步骤 2 的*原地验证并修复*）。

1. 从 `.env` 解析 `ENV_PY`（原则 1）。没有可用解释器 → 说明情况并推荐完整运行 `$star-env-builder`；不安装任何内容。
2. 按 `references/installer_policy.md` 对每个包分类——framework / runtime / optional / conda-only——并说明分别写入哪个 requirements 文件。
3. **审批门**（原则 2——通过前不安装）：展示包、类别、将使用的版本与 index、下载量较大时的大小，以及任何 CUDA 耦合；询问*批准并安装* / *调整* / *中止*。
4. 通过梯级安装（uv > pip > conda；conda 仅在 conda 后端且只用于白名单）。源码构建项仍停在 STOP line：准备准确命令，不运行。
5. 仅对新包做冒烟测试（`references/smoke_test_spec.md`）：L1——每个包都通过 `$ENV_PY` import 并报告版本；新的 framework 包还要做 L2。失败 → 诊断并做一次有界重试，然后标记为 `blocked` 并报告；绝不让一个包处于已安装但未验证的状态。
6. 把每个已安装包追加到对应 requirements 文件，保留现有顺序和 pin。在最新的 `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md` 追加 `## Added <date>` 块（没有报告则新建）。提交：`star-env-builder: add <packages>`，仅暂存 `${CODE_NAME}/requirements*`。
7. 报告 ≤400 词：安装了什么、每个 requirements 文件新增了什么、冒烟证据、任何 blocked 或等待用户处理的内容。

## 状态与文件规则

- 写入范围仅限：环境本身（位于 `$CONDA_HOME/envs/` 或 `<project>/.venv`）、`${CODE_NAME}/requirements*`（只在生成缺失布局或填补已验证缺口时）、`wkdrs/env_<ENV_NAME>_<date>/`，以及——仅经用户明确确认——`.env` 的 `PYTHON_HOME=` 行。绝不触碰源代码、`metds/plans/*` 或其他 skill 的产出。
- 绝不删除环境；备份是带真实运行日期的重命名。绝不编造时间戳。
- Git：每次运行最多一个 commit——生成 requirements，或在 add 模式添加包——仅暂存 `${CODE_NAME}/requirements*`（约定 §1）。
- 审批门通过的安装自主运行，包括框架规模的下载。无论是否批准，以下始终在 STOP line：`sudo` 或系统包管理器（apt / brew）、驱动或 CUDA toolkit 的系统级安装、CUDA 源码编译（flash-attn 类构建）、超过约 10 GB 的下载、删除任何环境。把这些操作写成准确命令放入报告。
- 尊重用户镜像配置（`PIP_INDEX_URL`、`UV_DEFAULT_INDEX`）；绝不写入 `pip config`、`.condarc` 或 `uv.toml`。
- 重复调用语义：若存在匹配的 `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` 且环境仍在，优先选择**原地验证并修复**（步骤 2）——从报告中的失败处恢复，不要重建。

## 对话纪律

- 一次只问一个问题——有 Codex 结构化用户输入工具时使用该工具，否则用简洁纯文本——每次标出推荐项，并等待明确答复；安装计划必须明确批准后才能安装任何内容。
- `ENV_REPORT.md` 正文语言遵循对话语言；中文报告中的技术术语保留英文。
