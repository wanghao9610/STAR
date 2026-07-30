<div align="center">
  <img src="docs/srcs/star-project-icon.png" alt="STAR 项目图标" width="128">
  <h1>STAR</h1>
  <p><strong>系统化 AI 研究工具链</strong></p>
  <p><em>一个面向可复现、结构化 AI 研究的可复用项目基础。</em></p>
  <p><a href="https://wanghao9610.github.io/STAR/"><strong>文档站点</strong></a></p>
</div>

**语言：** [English](README.md) | 简体中文

STAR 为人工智能研究项目提供了一个轻量起点。它把源代码、数据集、模型权重、实验输出和方法记录分别放在约定好的目录中，并给研究者和 AI 编程助手同一个实验入口、同一份项目规范。内置的研究工作流按“研究构想 → 计划 → 可执行子计划 → 实现与验证 → 状态追踪”依次推进，过程中把关键决策、任务依赖和验证记录写进项目文件，因此工作能跨会话接着做，过程也可事后追溯。

STAR 不绑定具体框架：研究工作流只约定过程、文件位置和验证记录，你仍可自行选择模型技术栈、依赖管理工具和实验跟踪平台。

## 目录

- [目录](#目录)
- [主要特性](#主要特性)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
  - [1. 使用 STAR 创建项目](#1-使用-star-创建项目)
  - [1b. 或者：接入一个已经存在的项目](#1b-或者接入一个已经存在的项目)
  - [2. 配置本地运行环境](#2-配置本地运行环境)
  - [3. 添加实验](#3-添加实验)
  - [4. 运行实验](#4-运行实验)
  - [5. 启动研究工作流](#5-启动研究工作流)
- [分工具配置（可选）](#分工具配置可选)
  - [model-id 溯源钩子](#model-id-溯源钩子)
  - [为状态收集脚本预先授权](#为状态收集脚本预先授权)
- [研究工作流](#研究工作流)
  - [模型选择建议](#模型选择建议)
- [更新 STAR 的 skill 与工作流指南](#更新-star-的-skill-与工作流指南)
- [项目约定](#项目约定)
- [将 STAR 用于新项目](#将-star-用于新项目)
- [更新日志](#更新日志)
- [引用](#引用)
- [许可证](#许可证)

## 主要特性

- **统一的项目结构**：清晰组织代码、数据、权重、输出和研究记录。
- **可迁移的运行环境**：本机路径仅保存在本地 `.env` 文件中，不写入脚本。
- **统一的实验入口**：通过 `execs/run.sh` 查找并启动实验。
- **完整的研究生命周期**：十五个相互配合的 skill，按运行顺序依次是——不改动原有内容地接入已经开工的项目、收敛研究选题、写成计划、调研相关工作、递归拆解计划、搭建代码库、构建运行环境、执行叶子计划、审查代码、分析实验结果、汇总阶段进展、以执行证据修订计划、汇报全局状态、把定稿计划编译成方法文档、把仓库整理到可发布状态。
- **可追踪、可恢复的研究过程**：将计划保存在 `metds/plans/`，将计划执行过程的中间文件保存在 `tasks/`，将生成的 run 产物保存在 `wkdrs/`，不依赖聊天记录保存上下文。
- **面向 AI 协作的规范**：为 Codex、Claude、Kimi Code 和 Cursor 提供一致的项目约束和研究工作流，并支持中文与英文。
- **适合大文件的安全默认配置**：本地数据、模型权重、实验输出和环境配置默认不纳入版本控制。

十五个 skill 各自负责什么、产出什么，以及在你所用工具里怎么调用，见[研究工作流](#研究工作流)；完整的端到端示例、生成文件清单和常见问题，见[研究工作流 Skills 使用指南](docs/mds/star-workflow/research-workflow-skills.zh-CN.md)。

## 项目结构

```text
star-ai-research/
├── code/                   # 项目核心代码（目录名由 CODE_NAME 配置）
├── docs/                   # 项目文档站点
│   ├── index.html          # GitHub Pages 文档入口
│   ├── htmls/              # HTML 文档页面
│   ├── mds/                # 按主题组织的 Markdown 文档
│   └── srcs/               # 文档图片及其他静态资源
├── datas/                  # 数据集及相关文件
├── inits/                  # 模型权重、检查点和初始化文件
├── tasks/                  # 按计划名称归档的执行过程中间文件
├── wkdrs/                  # 实验输出及每次运行产生的文件
├── metds/
│   ├── ideas/              # Idea storm 的选题探索与定稿的选题陈述
│   ├── plans/              # 研究计划及可执行子计划
│   ├── refs/               # 相关工作分析与可核验的 reference.bib
│   └── overview.md …       # 由计划编译而成的方法文档
├── execs/
│   ├── run.sh              # 实验统一入口
│   ├── update.sh           # 同步上游 STAR skill 与工作流指南
│   └── scpts/              # 各实验对应的 Shell 脚本
├── .agents/skills/         # Codex 使用的研究工作流技能
├── .claude/skills/         # Claude 使用的研究工作流技能
├── .cursor/skills/         # Cursor 使用的研究工作流技能
├── .kimi-code/skills/      # Kimi Code 使用的研究工作流技能
├── .claude/hooks/          # Claude 的 model-id 溯源钩子
├── .codex/hooks/           # Codex 的 model-id 溯源钩子
├── .cursor/hooks/          # Cursor 的 model-id 溯源钩子
├── .kimi-code/hooks/       # Kimi Code 的 model-id 溯源钩子（见分工具配置）
├── .cursor/rules/          # Cursor 自动加载的项目规则
├── .vscode/                # 编辑器与调试配置
├── .github/                # STAR 自身的维护 CI；用于你的项目时请删除
├── .env.example            # 本地运行环境配置示例
├── AGENTS.md               # AI 编程助手共享的协作规范
├── CLAUDE.md               # 指向 AGENTS.md 的符号链接，供 Claude Code 加载同一份规范
└── README.md
```

HTML 页面放在 `docs/htmls/`，按主题组织的 Markdown 文档放在 `docs/mds/`，图片及其他静态资源放在 `docs/srcs/`；`docs/index.html` 作为文档入口。研究计划、方法记录和研究设计记录则放在 `metds/` 中。

目录名中的缩写是有意为之：

| 目录 | 英文含义 | 存放内容 |
| --- | --- | --- |
| `datas/` | Data | 原始数据、处理后的数据或生成的数据集 |
| `inits/` | Initializations | 预训练权重、检查点和初始化文件 |
| `metds/` | Methodologies | 研究计划、设计说明和方法记录 |
| `execs/` | Executions | 启动器和实验脚本 |
| `scpts/` | Scripts | 可独立运行的实验定义 |
| `tasks/` | Tasks | 每个计划自有的工具脚本，以及执行该计划时产生的中间文件，按计划名称分目录保存 |
| `wkdrs/` | Work directories | run 日志、指标、预测结果及其他实验输出 |
| `mds/` | Markdowns | 按主题分组的 Markdown 文档 |
| `htmls/` | HTMLs | 渲染后的 HTML 文档页面 |
| `srcs/` | Static sources | 文档引用的图片及其他静态资源 |

例如，执行 `metds/plans/00_demo_plan.md` 时会新建 `tasks/00_demo/`。这个目录存放该计划自有的工具脚本——完成判据要跑的校验或索引脚本——以及执行过程的中间文件。生成的实验产物仍放在相应的 `wkdrs/<运行名称>/` 目录中。

## 快速开始

### 1. 使用 STAR 创建项目

可以将本仓库用作 GitHub 模板，也可以直接克隆或复制到新项目：

```bash
git clone https://github.com/wanghao9610/STAR
cd STAR
rm -rf .git
rm -rf .github        # STAR 上游维护用的 CI，只用于校验 STAR 自身的 skill 镜像。
cd ..
mv STAR YOUR_PROJ_NAME
cd YOUR_PROJ_NAME
mv code YOUR_CODE_NAME  # 也可以将现有代码库复制或克隆到 YOUR_CODE_NAME。
git init
git add .
git commit -m "First commit."
```

`.github/` 里是 STAR 用来保持四套 skill 镜像同步的一致性检查，服务于 STAR 自身的维护，而非你的项目：若保留下来，它会在你每次推送到 `main` 时运行，并在你第一次修改 `AGENTS.md` 或删掉用不到的某套工具目录时失败。步骤 1b 的接入方式不会安装它。

如果 `YOUR_CODE_NAME/` 是从另一个 Git 仓库克隆而来，并且需要将其文件直接纳入当前项目，请在执行 `git add .` 前先运行 `rm -rf YOUR_CODE_NAME/.git` 删除内层 Git 元数据。

### 1b. 或者：接入一个已经存在的项目

如果项目已经开工——有真实代码、有能跑的环境、有几个月的提交、也已经拿到实验结果——那就把骨架装进它，而不是把它搬进 STAR。在那个仓库的根目录下执行：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o /tmp/star-update.sh
bash /tmp/star-update.sh --adopt
```

已经存在的东西一律不覆盖：每个已有文件都原样保留并列出。随后在该仓库里运行 `/star-proj-adopt`。它会勘察布局、写好 `.env`，用软链接连接你已有的数据 / 权重 / 输出目录而不搬动它们，包装你已有的启动命令，并记录下已经建成和已经跑过的东西。之后下面的第 2–4 步原样适用。

### 2. 配置本地运行环境

复制环境配置示例文件：

```bash
cp .env.example .env
```

然后编辑 `.env`：

```dotenv
CODE_NAME=YOUR_CODE_NAME
ENV_NAME=your-env
CONDA_HOME=/path/to/conda
PYTHON_HOME=/path/to/conda/envs/your-env
```

- `CODE_NAME`：项目根目录下存放核心代码的目录名。
- `PYTHON_HOME`：决定运行环境，可以是环境目录，也可以是其中 Python 可执行文件的路径。
- `CONDA_HOME`：本机 Conda 的安装根目录；`ENV_NAME`：其中的环境名。

以 `PYTHON_HOME` 为准，因此有两种配置方式：

- **设置 `PYTHON_HOME`。** 直接按其取值使用，`CONDA_HOME` / `ENV_NAME` 可以留空。未设 `CONDA_HOME` 时不走 `conda activate`，直接调用该解释器——使用普通 `.venv` 时也是这种方式。
- **留空 `PYTHON_HOME`，同时设置 `CONDA_HOME` 与 `ENV_NAME`。** 此时 `PYTHON_HOME` 由 `$CONDA_HOME/envs/$ENV_NAME` 推导得出。

两者都不设置则报错。

此外可以加上 `INVOLVE=low|medium|high`，设定 STAR skills 在决策前询问的程度：`low` 在需要判断的地方直接采用推荐项，并把这次取值记录下来；`medium`（默认）按文档提问；`high` 每一步都先确认。红线、提交、删除这类安全确认点在任何档位都会询问。若只想对单次运行生效，调用 skill 时附带同一参数即可，如 `$star-plan-executor 00 involve=low`。完整规则见[研究工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md#7-对话纪律) §7.7。

另一个可选键 `STAR_LANG=en|zh` 给两件事固定同一种语言：agents 的对话回复，以及新生成的工作流文档（计划、报告）。未设时二者都跟随对话语言。无论设与未设，对话中明确提出时都以对话要求为准；已有文档则保持其 frontmatter 声明的语言不变。完整规则见[研究工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md#7-对话纪律) §7.6。

本地 `.env` 已被 Git 忽略，因此其中的机器相关路径不会被提交。

### 3. 添加实验

将可复用的项目代码放在 `CODE_NAME` 指定的目录中，再在 `execs/scpts/` 下添加实验脚本。例如：

```bash
#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${WORK_DIR}/baseline"
mkdir -p "${RUN_DIR}"

python "${CODE_DIR}/train.py" \
    --data-dir "${DATA_DIR}" \
    --output-dir "${RUN_DIR}" \
    "$@"
```

启动器会依据 `.env` 解析解释器——设置了 `CONDA_HOME` 时激活 Conda，否则直接使用 `PYTHON_HOME`——并向实验脚本导出以下路径变量：

```text
ROOT_DIR  CODE_DIR  DATA_DIR  INIT_DIR WORK_DIR  SCPT_DIR
```

### 4. 运行实验

```bash
# 查看可用的实验脚本
bash execs/run.sh --list

# 运行默认实验 execs/scpts/00_exp.sh
bash execs/run.sh

# 运行指定实验，并将其余参数传递给实验脚本
bash execs/run.sh 00_exp --config config.yaml
```

自带的 `00_exp.sh` 不做任何实际计算。它打印启动器解析出的解释器和六个导出路径，让全新检出的仓库有一条能跑出成功的命令，也便于确认 `.env` 配置无误。使用 STAR 创建项目时请将其替换为第一个实际实验。实验名称和输出目录应能区分不同任务、实验或重复运行，生成的文件放在 `wkdrs/<运行名称>/` 下。

### 5. 启动研究工作流

上面的骨架本身就能独立使用——目录布局、`.env` 和 `execs/run.sh` 不依赖任何 skill。若要接上研究工作流，请对照下表选择起点，并使用[研究工作流](#研究工作流)一节中你所用工具的前缀：

| 你的状态 | 起点 |
| --- | --- |
| 只有兴趣方向，尚未定题 | `star-idea-storm <你的兴趣方向>` |
| 已有选题，准备写计划 | `star-plan-coach <你的选题>` |
| 刚用步骤 1b 接入的既有项目 | `star-proj-adopt` |
| 回到一个已经在推进的项目 | `star-flow-status` |

最值得记住的是 `star-flow-status`：它会读取计划树和磁盘上的报告，直接给出下一步该做什么，因此你不必再回忆上次停在哪里。

## 分工具配置（可选）

两项都不影响开始使用；用到哪个工具，再做哪一项。

### model-id 溯源钩子

如果你用 **Kimi Code** 驱动 STAR，每台机器运行一次下面的命令，让各 skill 记录真实的 `model_id` 而不是 `unrecorded`：

```bash
bash .kimi-code/hooks/install.sh
```

它会把溯源钩子注册到你的全局 `~/.kimi-code/config.toml`，注册前先备份该文件；重复运行不会有额外影响，运行一次即覆盖所有 STAR 项目。Codex、Claude 和 Cursor 各自的钩子随仓库一起注册好，用这三个 agent 可跳过本步。但在 Codex 上，注册好不等于会跑：项目级钩子要等项目被信任、钩子被批准之后才触发。请在 Codex CLI 里跑一次 `/hooks` 批准它，之后每次钩子有改动都要重新批准。在那之前，每份报告里的 `model_id` 都是 `unrecorded`，而且没有任何地方会提示你。手动方式与细节见 [`.kimi-code/hooks.example.toml`](.kimi-code/hooks.example.toml)。

### 为状态收集脚本预先授权

有六个 skill 在动手之前都要打开同一批计划、run 日志与报告：`star-flow-status`、`star-expt-digest`、`star-plan-decomposer`、`star-plan-executor`、`star-plan-reviser` 与 `star-metd-summarize`。它们不逐个打开文件，而是各自用一个只读脚本一次收齐——所用工具目录下、各 skill 自己目录里的 `scripts/scan.sh`。这是一次 shell 调用，所以 agent 第一次运行它时会请求授权。

全新安装的 Claude Code 无需任何设置：`.claude/settings.json` 已附带只针对这六个脚本的放行规则，不涉及其他任何命令。更早接入的项目会保留它自己的 `settings.json`——`execs/update.sh` 只在该文件缺失时安装它，绝不覆盖——因此需要自己补上这些规则：

```json
"permissions": {
  "allow": [
    "Bash(bash .claude/skills/star-flow-status/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-expt-digest/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-decomposer/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-executor/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-reviser/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-metd-summarize/scripts/scan.sh:*)"
  ]
}
```

其他工具可在被询问时授权一次，或预先加入白名单：

| 工具 | 在哪里预先授权 |
|---|---|
| Codex | 其审批策略 / 沙箱设置（全局配置，非按项目） |
| Cursor | 应用设置里的命令白名单 |
| Kimi Code | 全局 `~/.kimi-code/config.toml`——Kimi Code 不读取项目级配置 |

该脚本只读：它遍历 `metds/` 与 `wkdrs/`，打印 frontmatter 与文件清单，不向任何地方写入。

## 研究工作流

STAR 提供十五个相互配合的技能，将模糊的研究兴趣转化为可追踪、可审计的执行流程。

**调用方式。** 前缀因工具而异，下表中的技能清单统一采用 Codex 写法：

| 工具 | 调用写法 | 示例 |
| --- | --- | --- |
| Codex | `$star-<name>` | `$star-plan-coach 开放词汇检测` |
| Claude Code | `/star-<name>` | `/star-plan-coach 开放词汇检测` |
| Cursor | `/star-<name>` | `/star-plan-coach 开放词汇检测` |
| Kimi Code | `/skill:star-<name>` | `/skill:star-plan-coach 开放词汇检测` |

每个 skill 都必须显式指名。四套工具都禁用了隐式调用，仅用自然语言描述需求不会启动任何 skill。

<div align="center">
  <img src="docs/srcs/star-research-workflow.png" alt="STAR 研究工作流：十三个 skill 的调用顺序与两个横向通读的 skill、各自的主要产物，以及每个叶子计划上的循环" width="100%">
</div>

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `$star-proj-adopt` | 把已经开工的项目不改动原有内容地接入：勘察已有仓库，配好 `.env`，用软链接连接已有的数据 / 权重 / 输出目录，包装已有启动命令，记录已经建成和已经跑过的东西。待计划树建好后，再回填那些已完成的叶子 | `metds/adopt.md`，以及获确认叶子上的 `exec_status:` / `exec_runs:` |
| `$star-idea-storm` | 把模糊兴趣收敛成站得住的研究选题：发散候选方向、摘要级扫描领域、六维打分，最后连同首个验证实验定稿选题。点到的每篇论文都转录自抓取的记录 | `metds/ideas/<slug>_idea.md` |
| `$star-plan-coach` | 通过分阶段提问明确研究想法 | `metds/plans/<数字>_<主题>_plan.md` |
| `$star-refs-reviewer` | 调研与方法相关的工作：精读最贴近的论文写成分析笔记，并建立分好类的文献库，其中每一条都转录自抓取的记录。`survey` 把一整个领域分层读完，写成一份独立综述 | `metds/refs/<缩写>.md`、`metds/refs/reference.bib`、`metds/refs/refs_index.md`、`metds/refs/<slug>_survey.md` |
| `$star-code-architect` | 从打分选出的参考实现搭建 `${CODE_NAME}/` 或整理已有代码，并写下架构规范 | `${CODE_NAME}/` 及 `UPSTREAM.md`，外加 `metds/codearc.md` |
| `$star-env-builder` | 依据 `.env` 构建 conda 环境或 venv，按 uv > pip > conda 的优先顺序解析并安装依赖，并做冒烟验证。`add` 把新包安装进已有环境并记录 | 运行环境，以及 `wkdrs/env_<名称>_<日期>/ENV_REPORT.md` 和 `freeze.txt` |
| `$star-plan-decomposer` | 将总体计划拆分成可验证的子计划 | `metds/plans/<前缀>_<任务>_plan.md` |
| `$star-plan-executor` | 实现并初步验证一个可执行的叶子计划 | `tasks/<计划名称>/` 下该计划自有的工具脚本与中间工作文件、代码，以及 `wkdrs/<运行名称>/EXEC_PLAN.md`、`EXEC_LOG.md` 和生成产物；经确认的偏差同步写回计划并带 Revision History 记录 |
| `$star-code-reviewer` | 对照项目规范与计划承诺审查代码，并落实经批准的例行性修复 | `wkdrs/<运行名称>/CODE_REVIEW_<日期>.md` 或 `wkdrs/reviews/code_<范围>_<日期>.md` |
| `$star-expt-analyst` | 对照计划的预期审计一个 run 的产出：产物清点、日志健康、指标对照完成判据打分，以及结果对该主张意味着什么 | `wkdrs/<运行名称>/EXPT_ANALYSIS_<日期>.md`，以及 `wkdrs/<运行名称>/analysis/` 下的图；`aggregate` 模式下的 `wkdrs/results/results.md`（限定范围时为 `wkdrs/results/results_<slug>.md`） |
| `$star-expt-digest` | 按时间轴汇总最近的实验进展：从上一份 digest 续接，或覆盖一个显式时间窗、一整个计划家族。把每个 run 的判定与关键指标从其分析报告中取出成表，推导相对上次的变化，并列出缺口 | `wkdrs/digests/EXPT_DIGEST_<日期>.md` |
| `$star-plan-reviser` | 以执行证据审查一个计划并就地修订 | `wkdrs/<运行名称>/REVIEW_<日期>.md`，以及带 Revision History 的修订后计划 |
| `$star-flow-status` | 汇总整条流程的进度——计划树，以及已完成工作里缺失或过期的审查、分析、方法文档——并指出唯一的下一步 | 只读状态摘要 |
| `$star-metd-summarize` | 在所有实验完成、计划定稿后，把计划树编译成可直接用于论文的方法文档，并把无计划覆盖之处转成 TODO | `metds/overview.md`、`dataset.md`、`framework.md`、`training.md`、`evaluation.md` |
| `$star-code-release` | 把仓库整理到可发布状态：按已记录的放置规则把散落代码移入 `${CODE_NAME}/`，打磨对外发布的部分，从方法文档与结果汇总表编译出 README，并排查密钥凭据、机器本地路径和解析不了的命令 | `README.md` 与 `wkdrs/release/RELEASE_<日期>.md` |

### 模型选择建议

不同阶段对模型能力的侧重有所不同。下列模型名截至 2026-07，会随时间过时；括号内是同档位的等效替代。

| 阶段 | Skills | 建议模型 |
|---|---|---|
| **判断与写作**——研究方向、计划、相关工作如何定位本方法、结果意味着什么、方法表述 | `$star-idea-storm`、`$star-plan-coach`、`$star-refs-reviewer`、`$star-plan-decomposer`、`$star-expt-analyst`、`$star-plan-reviser`、`$star-metd-summarize` | Claude Fable5 Extra、ChatGPT5.6 Sol High 或 Kimi K3 |
| **搭建与执行**——代码库、运行环境、执行计划、代码审查、进展汇总、全局状态、发布准备 | `$star-proj-adopt`、`$star-code-architect`、`$star-env-builder`、`$star-plan-executor`、`$star-code-reviewer`、`$star-expt-digest`、`$star-flow-status`、`$star-code-release` | Claude Opus4.8 Medium（Sonnet5 High）、ChatGPT5.6 Sol Medium（Terra High）、Cursor Grok4.5 High 或 Kimi K3 |

条件允许时，十五个 skill 均使用能力最强的可用模型，通常能获得最佳的整体效果。

这些技能会将决策和进度保存在项目文件中，避免仅依赖聊天记录。研究工作流同时支持中文和英文。

具体的调用方式、完整示例、生成文件和常见问题见[研究工作流 Skills 使用指南](docs/mds/star-workflow/research-workflow-skills.zh-CN.md)。所有 skill 共享的规则——git、红线、`.env` 运行时、日期、委派与对话纪律——见[研究工作流 Skill 通用规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)。

## 更新 STAR 的 skill 与工作流指南

基于 STAR 创建项目后，可以只同步 STAR 后续发布的 skill 与研究工作流指南，而不改动项目代码、实验配置或 Git remote：

```bash
bash execs/update.sh
```

该命令默认从 STAR 的 `main` 分支更新以下路径：

- `AGENTS.md` 与 `.cursor/rules/`——共享的 agent 协作规范，以及抄录其正文的 Cursor 规则；你对它们的改动会被替换
- `.agents/skills/`、`.claude/skills/`、`.cursor/skills/`、`.kimi-code/skills/`
- `.claude/hooks/`、`.codex/hooks/`、`.cursor/hooks/`、`.kimi-code/hooks/` 以及 `.kimi-code/hooks.example.toml`——model-id 溯源钩子
- `docs/mds/star-workflow/` 与 `docs/srcs/`——工作流文档，以及 STAR 自有页面使用的图标和流程图

钩子注册配置——`.claude/settings.json`、`.codex/hooks.json` 与 `.cursor/hooks.json`——仅在缺失时安装，除非加 `--force`，否则绝不覆盖。若保留下来的配置没有注册 STAR 钩子，命令会打印提示。如果项目是在钩子纳入更新范围之前基于 STAR 创建的，请先手动刷新一次更新脚本本身——`execs/update.sh` 不会覆盖自己：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o execs/update.sh
```

命令的通用形式为 `bash execs/update.sh [--diff] [ref] [--skill NAME] [--force]`：

- `--diff` 在不改动任何文件的情况下预览更新，有可更新内容时以 `2` 退出，完全一致时以 `0` 退出，出错时以 `1` 退出——脚本因此能区分“有更新”与“检查本身失败”。
- `ref` 把更新固定到某个 tag 或分支。
- `--skill NAME` 只更新四个工具目录中的这一个 skill，不动工作流文档和溯源钩子。名称无效、或上游四个 skill 目录中有任何一处缺少它，命令会停止且不覆盖任何文件。
- `--force` 更新同样这批路径，但解除两处拦截：这些路径下的未提交改动直接被覆盖而不再中止命令，钩子注册配置也改为覆盖而不再保留。它不扩大范围——上游没有的文件依旧原样保留，你自己放在这些目录下的 skill 和文档不会丢。

`bash execs/update.sh --help` 里有完整的用法摘要——选项变了它也跟着变，不会过期。

上游同路径文件会直接覆盖本地版本，上游新增文件也会被加入；更新范围内，仅存在于当前项目的自定义文件会保留。为避免误删自定义内容，上游已删除的文件不会在本地自动删除。更新不会修改其他目录、当前分支、Git remote 或暂存区。建议更新前提交当前工作，更新后使用 `git status` 和 `git diff` 检查并提交结果。

## 项目约定

1. 可复用的实现代码放在 `${CODE_NAME}/` 中。
2. 数据放在 `datas/`，模型权重放在 `inits/`，计划执行过程的中间文件放在 `tasks/` 下与计划同名的子目录中，生成的实验文件放在 `wkdrs/`。
3. 研究计划和方法记录放在 `metds/`，其中计划文件统一放在 `metds/plans/`。
4. 使用 `execs/run.sh` 作为统一入口，并将实验脚本放在 `execs/scpts/`。
5. 从 `.env` 读取运行环境路径，不要在代码或脚本中硬编码本机路径。
6. 为每次运行使用独立的输出目录，并记录复现实验所需的命令、配置和验证依据。
7. 保持修改小而明确；先运行最直接相关的检查，再根据影响范围扩大验证。

完整的协作与实现规范见 [`AGENTS.md`](AGENTS.md)。

## 将 STAR 用于新项目

使用 STAR 创建新的研究仓库时，建议完成以下调整：

- 将标题和项目简介替换为新研究项目的实际信息。
- 设置 `CODE_NAME`；如果需要，也可以将 `code/` 重命名为实际的源码目录。
- 添加项目的依赖声明和锁文件。
- 用第一个实际实验替换 `execs/scpts/00_exp.sh`。
- 说明数据集和预训练权重的获取方式，不要直接提交大文件。
- 明确预期输出、评估指标和复现命令。
- 更新 `LICENSE` 中的年份和版权所有者。
- 替换 `docs/htmls/star.html`、`docs/htmls/star_zh.html` 与 `docs/srcs/`——它们是 STAR 自己的落地页和图片，不属于你的项目。`docs/index.html` 和 `docs/index_zh.html` 是把这两个页面挂到站点根目录的软链接。两个页面之间的中英切换用的是绝对链接（`/STAR/index_zh.html`），要把其中的 `/STAR` 前缀改成你自己的仓库名，否则语言切换会失效。`docs/mds/star-workflow/` 保持不动，`execs/update.sh` 会负责更新它。
- 删掉用不到的工具目录。`.agents/`（Codex）、`.claude/`、`.cursor/`、`.kimi-code/` 各自是同一套十五个 skill 的完整副本，每套约 150 个文件；留下你所用 agent 会读的那一套，其余 `rm -rf` 即可。

只保留确实有助于研究的结构——STAR 应当服务于研究，而不是限制研究。骨架本身可独立使用：目录布局、`.env` 和 `execs/run.sh` 在完全不装任何 skill 的情况下也能工作，因此删掉全部工具目录同样是受支持的用法。

## 更新日志

按版本列出要点，最新在前。每个版本对应一个 git tag，因此 `bash execs/update.sh v0.1.0` 可将更新固定到该版本。

- **[v0.1.5](https://github.com/wanghao9610/STAR/tree/v0.1.5)** (2026-07-30) — 又有四个 skill——`star-plan-decomposer`、`star-plan-executor`、`star-plan-reviser`、`star-metd-summarize`——改用共享的只读采集脚本读计划树，不再逐个打开计划。同一轮对话里的第二个 skill 可以复用仍能看到的开场装载，采集脚本的摘要除外。`star-plan-decomposer` 的三条拆分轴改名为阶段、组件、实验，各自以该层所放的单元命名。实验轴只在代码已能端到端跑起来时才被推荐，它这一层放的是实验组，每条主张再深一位数字。`star-flow-status` 的开场装载拆成同时发出的两条命令——大小固定的规约摘录，和随项目历史增长的采集摘要——摘要大到无法完整返回时，不再把摘录一起拖下水。
- **[v0.1.4](https://github.com/wanghao9610/STAR/tree/v0.1.4)** (2026-07-29) — 每个 skill 用一条消息完成开场装载，`SKILL_zh.md` 不再在运行时读取——它仍是供人阅读的完整镜像。其中两个 skill 只装载自己真正用到的规约章节。
- **[v0.1.3](https://github.com/wanghao9610/STAR/tree/v0.1.3)** (2026-07-29) — `star-refs-reviewer` 新增 `survey` 模式，把独立的领域综述写入 `metds/refs/`；追加模式新增 `add` 形式，一次可提交多篇论文。
- **[v0.1.2](https://github.com/wanghao9610/STAR/tree/v0.1.2)** (2026-07-28) — 一条措辞规则，写在 `AGENTS.md` §7 与规约 §7.11：写动作本身，不写它的名字。十五个 skill 全部按它审计过一遍。
<details>
<summary>更早的版本</summary>

- **[v0.1.1](https://github.com/wanghao9610/STAR/tree/v0.1.1)** (2026-07-27) — `star-flow-status` 只扫描一次计划树，`star-expt-digest` 读同一份扫描结果。新增 `STAR_LANG` 用于固定回复与新生成文档的语言；`execs/update.sh` 增加 `AGENTS.md` 同步与 `--force`；溯源钩子改为在 skill 记录时读取模型 id。
- **[v0.1.0](https://github.com/wanghao9610/STAR/tree/v0.1.0)** (2026-07-24) — 第一个正式版本：面向 Codex、Claude、Cursor 和 Kimi 的十五个双语研究工作流 skill、model-id 溯源钩子、设定 skills 在决策前询问程度的 `INVOLVE=low|medium|high` 三档开关（默认 `medium`），以及支持钩子同步与 `--diff` 预览的更新脚本。
- **2026-07-15** — STAR 首个发布。

</details>

## 引用

如果 STAR 对你的研究有帮助，请按如下方式引用：

```bibtex
@misc{star2026,
  title = {{STAR}: Systematic Toolchain for AI Research},
  author = {Hao Wang},
  howpublished = {\url{https://github.com/wanghao9610/STAR}},
  year = {2026}
}
```

## 许可证

STAR 基于 [MIT 许可证](LICENSE) 发布。
