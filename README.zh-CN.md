<div align="center">
  <img src="docs/srcs/star-project-icon.png" alt="STAR 项目图标" width="128">
  <h1>STAR</h1>
  <p><strong>Systematic Toolchain for AI Research</strong></p>
  <p><em>一个面向可复现、结构化 AI 研究的可复用项目基础。</em></p>
  <p><a href="https://wanghao9610.github.io/STAR/"><strong>文档站点</strong></a></p>
</div>

**语言：** [English](README.md) | 简体中文

STAR 是一个人工智能研究项目的工作底座，管的是从选题到成文这一整条链路：定下选题、读清相关工作、把想法写成计划、搭起代码与环境、把计划拆成可以各自单独验证的子问题、跑实验、判读跑出来的结果、拿这份判读回头改计划，随时能看到整条流程走到了哪一步，最后把定稿的计划编译成可直接写进论文的方法文档。它留下的是一份可追溯的实验记录——每次运行为回答哪个问题而跑、依赖哪些别的子问题、由哪条命令和哪份配置产生了这些数字、这些数字对照的是什么判据，以及据此做了什么决定。源代码、数据集、模型权重、实验输出和方法记录各有各的目录；所有实验都从同一个入口启动；研究者和 AI 编程助手读同一份项目规范。因为这份记录写在项目文件里而不是留在聊天窗口里，工作能跨会话接着做，隔很久之后也查得清楚。

STAR 不绑定具体框架：研究工作流只约定过程、文件位置和验证记录，你仍可自行选择模型技术栈、依赖管理工具和实验跟踪平台。

研究做到可以动笔时，[STAGE](https://github.com/wanghao9610/STAGE)（*Systematic Toolchain for Authoring, Guiding, and Editing*，面向学术写作的系统化工具链）是写作侧的伴侣仓库：STAR 负责推进研究、产出方法文档、实验结果和阶段小结；STAGE 把它们导入为只读的带指纹证据，在其上写出论文，因此稿件中的每个数字都能追回到产生它的那次实验。配对是可选的——STAR 本身并不依赖它。

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
- [研究工作流](#研究工作流)
  - [模型选择建议](#模型选择建议)
- [分工具配置（可选）](#分工具配置可选)
  - [会话钩子](#会话钩子)
  - [为状态收集脚本预先授权](#为状态收集脚本预先授权)
- [项目记忆](#项目记忆)
- [更新 STAR 的 skill 与工作流指南](#更新-star-的-skill-与工作流指南)
- [项目约定](#项目约定)
- [将 STAR 用于新项目](#将-star-用于新项目)
- [更新日志](#更新日志)
- [引用](#引用)
- [许可证](#许可证)

## 主要特性

- **统一的项目结构**：清晰组织代码、数据、权重、输出和研究记录。
- **跟着项目走的运行环境**：本机路径仅保存在本地 `.env` 文件中，不写入脚本。
- **统一的实验入口**：通过 `execs/run.sh` 查找并启动实验。
- **研究的每一步各有一个 skill**：一共十五个。其中十三个按研究推进的顺序依次是——把已经开工的项目不改动原有内容地接进来、收敛研究选题、写成计划、调研相关工作、搭建代码库、构建运行环境、把计划拆成可以各自单独验证的子问题、逐个实现并轻量验证、审查代码、对照计划的预期判读一次运行的结果、拿这些证据修订计划、把定稿计划编译成方法文档、把仓库整理到别人能照着跑起来的样子；另外两个任何时候都能调：汇报整条流程走到了哪一步、汇总最近一段的实验进展。
- **可回溯、也能接着做的研究过程**：计划放在 `metds/plans/`，每个计划执行过程的中间文件放在 `tasks/`，一次 run 产生的东西放在 `wkdrs/`——重新上手时读的是文件，不是聊天记录。
- **归项目所有的记忆**：一次会话学到、又没有任何计划或报告认领的事实——环境怪癖、长期偏好、走不通的路——记在 `.star/memory/` 里，并由钩子送到下一次会话面前，无论你用哪个工具驱动 STAR。
- **面向 AI 协作的规范**：为 Codex、Claude、DSH、Kimi Code、Cursor、Pi 和 Qwen Code 提供一致的项目约束和研究工作流，并支持中文与英文。
- **太大或只属于本机的东西不进版本库**：本地数据、模型权重、实验输出和环境配置默认不纳入版本控制，仓库里装的是代码和记录，不是数据。

十五个 skill 按研究阶段分组列在[研究工作流](#研究工作流)一节：各自负责什么、产出什么，以及在你所用工具里怎么调用；完整的端到端示例、生成文件清单和常见问题，见[研究工作流 Skills 使用指南](docs/mds/star-workflow/research-workflow-skills.zh-CN.md)。

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
├── .agents/skills/         # 凡遵循 AGENTS.md 约定的 agent 都会读的研究工作流技能
├── .claude/skills/         # Claude 使用的研究工作流技能
├── .cursor/skills/         # Cursor 使用的研究工作流技能
├── .dsh/skills/            # DeepSeek Harness 使用的研究工作流技能
├── .kimi-code/skills/      # Kimi Code 使用的研究工作流技能
├── .pi/skills/             # Pi 使用的研究工作流技能
├── .qwen/skills/           # Qwen Code 使用的研究工作流技能
├── .codex/skills/          # Codex 每个技能一份的清单，由 .agents/skills/ 用软链接指过来
├── .claude/hooks/          # Claude 的钩子：model-id 溯源、项目记忆、INVOLVE=low 放行编辑
├── .codex/hooks/           # Codex 的钩子：model-id 溯源、项目记忆、INVOLVE=low 放行编辑
├── .cursor/hooks/          # Cursor 的会话钩子
├── .dsh/hooks/             # DSH 的会话钩子，登记在 .dsh/hooks.json（见分工具配置）
├── .kimi-code/hooks/       # Kimi Code 的会话钩子（见分工具配置）
├── .pi/extensions/         # Pi 的扩展：STAR 的会话钩子，外加子代理、计划模式、结构化提问
├── .qwen/hooks/            # Qwen Code 的钩子：model-id 溯源、项目记忆、INVOLVE=low 放行编辑
├── .star/memory/           # 项目记忆：先前会话学到的事实（local/ 不入库）
├── .claude/commands/       # Claude Code 的斜杠命令 /star：把描述出来的需求分流到某个技能
├── .cursor/commands/       # 同一个 /star 命令，Cursor 版
├── .qwen/commands/         # 同一个 /star 命令，Qwen Code 版
├── .cursor/rules/          # Cursor 自动加载的项目规则
├── .pi/agents/             # star_subagent 的派发花名册：收集者、执行者、复核者
├── .pi/prompts/            # Pi 的斜杠命令：每个技能一个 /star-<名>，外加分流用的 /star
├── .pi/settings.json       # Pi 的项目设置：让技能发现不扫 .agents/skills
├── .pi/APPEND_SYSTEM.md    # Pi 常驻的项目规则：该按哪个技能根目录执行
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

`.github/` 里是 STAR 用来从同一份原稿生成七套 skill 树的生成器，以及保持它们同步的一致性检查，服务于 STAR 自身的维护，而非你的项目：若保留下来，它会在你每次推送到 `main` 时运行，并在你第一次修改 `AGENTS.md` 或删掉用不到的某套工具目录时失败。步骤 1b 的接入方式不会安装它。

如果 `YOUR_CODE_NAME/` 是从另一个 Git 仓库克隆而来，并且需要将其文件直接纳入当前项目，请在执行 `git add .` 前先运行 `rm -rf YOUR_CODE_NAME/.git` 删除内层 Git 元数据。

### 1b. 或者：接入一个已经存在的项目

如果项目已经开工——有真实代码、有能跑的环境、有几个月的提交、也已经拿到实验结果——那就把骨架装进它，而不是把它搬进 STAR。在那个仓库的根目录下执行：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o /tmp/star-update.sh
bash /tmp/star-update.sh --adopt
```

已经存在的东西一律不覆盖：每个已有文件都原样保留并列出。加上 `--tools claude`——或 `claude`、`codex`、`cursor`、`dsh`、`kimi`、`pi`、`qwen` 中任意几个，用逗号分隔——就只装你真正在用的那几棵工具树；不加则七棵全装。随后在该仓库里运行 `/star-proj-adopt`。它会勘察布局、写好 `.env`，用软链接连接你已有的数据 / 权重 / 输出目录而不搬动它们，包装你已有的启动命令，并记录下已经建成和已经跑过的东西。之后下面的第 2–4 步原样适用。

### 2. 配置本地运行环境

**环境依赖。** STAR 需要 `git` 与 `bash`；`execs/update.sh` 还需要 `curl`。会话钩子解析 JSON 载荷时优先用 `jq`，退回 `python3`，再退回 `grep` / `sed`，所以两个解析器都没有的机器照样能拿到项目记忆、提交守卫和模型 id。DSH 是唯一还需要另一个工具的宿主：没有 `zstd` 就根本恢复不出模型 id（见[分工具配置（可选）](#分工具配置可选)）。

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

此外可以加上 `INVOLVE=low|medium|high`，设定 STAR skills 在决策前询问的程度：`low` 在需要判断的地方直接采用推荐项，并把这次取值记录下来，在 Claude Code、Codex 和 Qwen Code 里还会跳过每次文件编辑前的权限弹窗——Cursor、DSH、Kimi Code 和 Pi 没有这样的弹窗可供档位回答，那里档位只管 skill 自己会问的那些问题；`medium`（默认）按文档提问；`high` 每一步都先确认。红线、每一次删除与覆盖、以及对你意图的任何歧义，这些强制确认点在任何档位都会询问；提交提议属于裁量题，`low` 档不问就提交，并在回复里点出每一次提交。若只想对单次运行生效，调用 skill 时附带同一参数即可，如 `star-plan-executor 00 involve=low`，前面加上你所用工具的前缀。完整规则见[研究工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md#7-对话纪律) §7.7。

另一个可选键 `STAR_LANG=en|zh` 给两件事固定同一种语言：agents 的对话回复，以及新生成的工作流文档（计划、报告）。未设时二者都跟随对话语言。无论设与未设，对话中明确提出时都以对话要求为准；已有文档则保持其 frontmatter 声明的语言不变。完整规则见[研究工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md#7-对话纪律) §7.6。

还有一个键 `STAR_REPOSITORY`，指定 `execs/update.sh` 从哪个仓库拉取后续的 skill 与工作流文档版本。它出厂就指向 STAR 本身，只有改从 fork 更新时才需要改动。详见[更新 STAR 的 skill 与工作流指南](#更新-star-的-skill-与工作流指南)。

再有一个键 `STAR_TOOLS`，指定同一个更新脚本安装并维护哪几棵 agent 工具树——写 `claude,pi` 就只维护这两棵，`all` 是全部（默认），`none` 只留共享骨架。没被选中的树既不写入也不删除，项目里原有的东西原样保留。同见 `STAR_REPOSITORY` 指向的那一节。

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

## 研究工作流

STAR 带十五个技能，覆盖从一个还说不清的兴趣到写得出的方法这一整条路线。其中十三个落在这条路线的某个确定位置上，另外两个任何时候都能调。下面按阶段列出：每段先说这一阶段在研究里对应什么，再列出属于它的技能和各自写下的东西。

**调用方式。** 下面各张技能表只写技能名、不带前缀；前缀取自你所用的工具，各家写法不同：

| 工具 | 调用写法 | 示例 |
| --- | --- | --- |
| Codex | `$star-<name>` | `$star-plan-coach 开放词汇检测` |
| Claude Code | `/star-<name>` | `/star-plan-coach 开放词汇检测` |
| Cursor | `/star-<name>` | `/star-plan-coach 开放词汇检测` |
| DSH | `/skill:star-<name>` | `/skill:star-plan-coach 开放词汇检测` |
| Kimi Code | `/skill:star-<name>` | `/skill:star-plan-coach 开放词汇检测` |
| Pi | `/star-<名>` | `/star-plan-coach 开放词汇检测` |
| Qwen Code | `/star-<name>` | `/star-plan-coach 开放词汇检测` |

七个 skill 是 slash-only——`star-proj-adopt`、`star-idea-storm`、`star-plan-coach`、`star-code-architect`、`star-plan-decomposer`、`star-plan-reviser`、`star-code-release`：只有被点名时才跑，因为每一个都坐在一个属于你的决定上。另外八个，任务明显匹配、目标又没有歧义时 agent 也可以自行启动；任何 skill 显式点名都始终有效。哪七个、为什么，以[规约 §10](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)（skill 名册）那张表为准，本节只是跟随它。

<div align="center">
  <img src="docs/srcs/star-research-workflow.png" alt="STAR 研究工作流：十三个 skill 的调用顺序与两个横向通读的 skill、各自的主要产物，以及每个叶子计划上的循环" width="100%">
</div>

**定下选题，并把它写成一份计划。** 研究是从一个还说不清、也没法验证的兴趣开始的。这一阶段把它收窄成一个可能被证伪的问题，写进一份说清楚“什么结果算支持它、什么结果算不支持”的计划，并把最贴近的工作读到能说出自己的方法和它们差在哪里。项目已经开工的，从下表第一行起步：先把已有的代码、数据、权重和跑过的实验接进同一套记录。

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `star-proj-adopt` | 把已经开工的项目不改动原有内容地接入：勘察已有仓库，配好 `.env`，用软链接连接已有的数据 / 权重 / 输出目录，包装已有启动命令，记录已经建成和已经跑过的东西。待计划树建好后，再回填那些已完成的叶子 | `metds/adopt.md`，以及获确认叶子上的 `exec_status:` / `exec_runs:` |
| `star-idea-storm` | 把模糊兴趣收敛成站得住的研究选题：发散候选方向、摘要级扫描领域、六维打分，最后连同首个验证实验定稿选题。点到的每篇论文都转录自抓取的记录 | `metds/ideas/<slug>_idea.md` |
| `star-plan-coach` | 通过分阶段提问，把研究想法写成一份计划 | `metds/plans/<数字>_<主题>_plan.md` |
| `star-refs-reviewer` | 调研与方法相关的工作：精读最贴近的论文写成分析笔记，并建立分好类的文献库，其中每一条都转录自抓取的记录。`survey` 把一整个领域分层读完，写成一份独立综述 | `metds/refs/<缩写>.md`、`metds/refs/reference.bib`、`metds/refs/refs_index.md`、`metds/refs/<slug>_survey.md` |

**把代码和环境准备到实验真能跑起来。** 在有东西能执行它之前，计划是验证不了的。这一阶段从一份打过分、而不是随手挑的参考实现搭起代码库，装上它需要的依赖；环境要到 import 过得去、框架看得见显卡、项目自己的入口跑得动，才算准备好。

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `star-code-architect` | 从打分选出的参考实现搭建 `${CODE_NAME}/` 或整理已有代码，并写下架构规范 | `${CODE_NAME}/` 及 `UPSTREAM.md`，外加 `metds/codearc.md` |
| `star-env-builder` | 依据 `.env` 构建 conda 环境或 venv，按 uv > pip > conda 的优先顺序解析并安装依赖，并对结果跑一遍三层的跑通性检查——先 import，再框架与显卡，最后项目入口。`add` 把新包安装进已有环境并记录 | 运行环境，以及 `wkdrs/env_<名称>_<日期>/ENV_REPORT.md` 和 `freeze.txt` |

**把计划拆成可以各自单独验证的子问题，一块一块做出来。** 整份计划是跑不动的，能跑的是带着自己那条完成判据的一小块。这一阶段先做拆分，再一次做一块：写出代码并轻量验证，重实验——长时间或多卡训练、以及花钱的接口调用——作为命令交回你手上运行；最后把写出来的代码对照项目规范、以及这个子计划当初承诺的东西各过一遍。

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `star-plan-decomposer` | 把总体计划拆成可以各自单独验证的子计划 | `metds/plans/<前缀>_<任务>_plan.md` |
| `star-plan-executor` | 实现并初步验证一个可执行的叶子计划 | `tasks/<计划名称>/` 下该计划自有的工具脚本与中间工作文件、代码，以及 `wkdrs/<运行名称>/EXEC_PLAN.md`、`EXEC_LOG.md` 和生成产物；经确认的偏差同步写回计划并带 Revision History 记录 |
| `star-code-reviewer` | 对照项目规范与计划承诺审查代码，并落实例行性修复——minor 直接改，major 经批准后改 | `wkdrs/<运行名称>/CODE_REVIEW_<日期>.md` 或 `wkdrs/reviews/code_<范围>_<日期>.md` |

**读实验结果，再把它带回计划。** 一次跑完的实验是证据，不是结论。这一阶段把产物和日志对照计划的预期核一遍，把指标对照完成判据和 baseline 打分——每个数字进报告前都按引用重新打开原文核实，站不住的降一档或丢弃——随后据此修订计划：哪条假设没站住、哪条判据定错了、下一步该做什么。

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `star-expt-analyst` | 对照计划的预期审计一个 run 的产出：产物清点、日志健康、指标对照完成判据打分，以及结果对该主张意味着什么 | `wkdrs/<运行名称>/EXPT_ANALYSIS_<日期>.md`，以及 `wkdrs/<运行名称>/analysis/` 下的图；`aggregate` 模式下的 `wkdrs/results/results.md`（限定范围时为 `wkdrs/results/results_<slug>.md`） |
| `star-plan-reviser` | 以执行证据审查一个计划并就地修订 | `wkdrs/<运行名称>/REVIEW_<日期>.md`，以及带 Revision History 的修订后计划 |

**把研究写成文字，并把仓库留成别人能照着跑起来的样子。** 走到这里，计划就是方法的定本，而仓库是读者真会去跑的那份东西。这一阶段把前者编译成能直接写进论文的文字，把后者收拾干净。

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `star-metd-summarize` | 在所有实验完成、计划定稿后，把计划树编译成可直接用于论文的方法文档，并把无计划覆盖之处转成 TODO | `metds/overview.md`、`dataset.md`、`framework.md`、`training.md`、`evaluation.md` |
| `star-code-release` | 把仓库整理到可发布状态：按已记录的放置规则把散落代码移入 `${CODE_NAME}/`，打磨对外发布的部分，从方法文档与结果汇总表编译出 README，并排查密钥凭据、机器本地路径和解析不了的命令 | `README.md` 与 `wkdrs/release/RELEASE_<日期>.md` |

**两个不属于任何一个阶段的技能。** 它们横向通读上面所有这些阶段，回答任何时刻都会冒出来的两个问题：现在走到哪一步、下一步该做什么；以及最近这一段实验到底做出了什么。两者都不写进计划，也不写进某次运行的目录。

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `star-flow-status` | 汇总整条流程的进度——计划树，以及已完成工作里缺失或过期的审查、分析、方法文档——并指出唯一的下一步 | 只读状态摘要 |
| `star-expt-digest` | 按时间轴汇总最近的实验进展：从上一份 digest 续接，或覆盖一个显式时间窗、一整个计划家族。把每个 run 的判定与关键指标从其分析报告中取出成表，推导相对上次的变化，并列出缺口 | `wkdrs/digests/EXPT_DIGEST_<日期>.md` |

### 模型选择建议

这些技能分成两类工作，两类各自侧重的模型能力不同。下列模型名截至 2026-07，会随时间过时；括号内是同档位的等效替代。

| 工作性质 | Skills | 建议模型 |
|---|---|---|
| **判断与写作**——研究方向、计划、相关工作如何定位本方法、结果意味着什么、方法表述 | `star-idea-storm`、`star-plan-coach`、`star-refs-reviewer`、`star-plan-decomposer`、`star-expt-analyst`、`star-plan-reviser`、`star-metd-summarize` | Claude Fable5 Extra、ChatGPT5.6 Sol High 或 Kimi K3 |
| **搭建与执行**——代码库、运行环境、执行计划、代码审查、进展汇总、全局状态、发布准备 | `star-proj-adopt`、`star-code-architect`、`star-env-builder`、`star-plan-executor`、`star-code-reviewer`、`star-expt-digest`、`star-flow-status`、`star-code-release` | Claude Opus4.8 Medium（Sonnet5 High）、ChatGPT5.6 Sol Medium（Terra High）、Cursor Grok4.5 High 或 Kimi K3 |

条件允许时，十五个 skill 均使用能力最强的可用模型，通常能获得最佳的整体效果。

这些技能会将决策和进度保存在项目文件中，避免仅依赖聊天记录。研究工作流同时支持中文和英文。

具体的调用方式、完整示例、生成文件和常见问题见[研究工作流 Skills 使用指南](docs/mds/star-workflow/research-workflow-skills.zh-CN.md)。所有 skill 共享的规则——git、红线、`.env` 运行时、日期、委派与对话纪律——见[研究工作流 Skill 通用规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)。

## 分工具配置（可选）

两项都不影响开始使用；用到哪个工具，再做哪一项。

### 会话钩子

会话开始时有两个钩子：一个记录各 skill 写进每份产物的模型 id，另一个把[项目记忆](#项目记忆)的索引送到 agent 面前。Claude、Codex 和 Qwen Code 还各带第三个钩子，它不是会话钩子：`.env` 写着 `INVOLVE=low` 时，它替你回答文件编辑前的权限弹窗，其他档位什么都不做。它和前两个一样随仓库注册好，分别在 `.claude/settings.json`、`.codex/hooks.json` 和 `.qwen/settings.json` 里。Cursor、DSH、Kimi Code 和 Pi 没有这个钩子：Cursor 没有任何在文件编辑之前触发的钩子，Kimi 的 `PermissionRequest` 只能旁观它旁边那个弹窗，Pi 根本不提供权限弹窗。DSH 也没有可回答的弹窗，但原因是它自己的：默认的 `workspace-write` 沙箱让项目内的编辑直接执行、不问；文件操作在那里唯一会发起的审批，是为写到工作区**之外**而一次性申请更宽的沙箱——而这个闸门在任何宿主上都不回答这种情况，因为它对项目根目录之外的路径本来就一概放行。何况那座桥也不会认 `allow`。七家还各带一个钩子，同样不是会话钩子，且任何档位都在跑：`star_commit_guard.sh` 会拒掉[工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) §1 明令禁止的 git 命令——整批或强制 stage、历史改写、以及暂存文件超过 10 MB 的提交。Claude、Codex、DSH、Kimi Code 与 Qwen Code 把它挂在 `PreToolUse` 上，Cursor 挂在 `beforeShellExecution` 上，Pi 挂在它的 `tool_call` 事件上——那都是各家裁决一条 shell 命令的地方。matcher 用的是各家自己的工具名：Claude、Codex 与 Kimi Code 是 `Bash`，Qwen Code 是 `run_shell_command`（它的 matcher 读的是工具标识符，不是界面上显示的名字），DSH 与 Pi 是小写的 `bash`。它是 `INVOLVE=low` 自行回答提交提议之后垫在底下的那层地板：被它拒掉的命令，归你自己运行。

如果你用 **Kimi Code** 或 **DSH** 驱动 STAR，每台机器运行一次对应的安装脚本，把钩子注册上，各 skill 也才能记录真实的 `model_id` 而不是 `unrecorded`：

```bash
bash .kimi-code/hooks/install.sh   # Kimi Code
bash .dsh/hooks/install.sh         # DSH
```

两者各自写进本机的全局配置——Kimi 是 `~/.kimi-code/config.toml`，DSH 是 `$DSH_HOME/cordis.patch.yml`——写之前先备份该文件；任一重复运行都不会有额外影响，运行一次即覆盖这台机器上的所有 STAR 项目。Codex、Claude、Cursor、Pi 和 Qwen Code 的两个钩子都随仓库一起注册好，用这五个 agent 可跳过本步。但在 Codex 上，注册好不等于会跑：项目级钩子要等项目被信任、钩子被批准之后才触发。请在 Codex CLI 里跑一次 `/hooks` 批准它们，之后每次钩子有改动都要重新批准。在那之前，每份报告里的 `model_id` 都是 `unrecorded`，记忆也一条都到不了会话，而且没有任何地方会提示你。在 Qwen Code 上，同样的坑只在你打开了目录信任（`security.folderTrust.enabled`，默认关闭）时才成立：未被信任的项目不会跑任何项目级钩子，同样没有任何地方提示你。另外 Qwen Code 优先读 `QWEN.md` 而不是 `AGENTS.md`，所以你的项目里若已有 `QWEN.md`，STAR 写在 `AGENTS.md` 里的规范就不会被装载——在 `QWEN.md` 里用 `@AGENTS.md` 引入它，或者把那个文件删掉。**Pi** 既不需要安装步骤，也没有注册文件：它自己就会发现 `.pi/extensions/star-hooks/index.ts`，由那个扩展把三个钩子全部接好——但要等项目获得信任之后，所以请回答 Pi 的信任提问，或运行 `/trust`，或设置 `defaultProjectTrust`。在那之前，任何项目级扩展都不加载，`.pi/skills/` 也找不到，`model_id` 一律是 `unrecorded`，`.pi/extensions/` 带来的子代理、计划模式和结构化提问也统统不存在——而且没有任何地方提示你。Pi 也是唯一一个模型 id 不会过期的运行时：扩展在每次提问前读当前模型，`/model` 一换就再注入一行新的。**DSH** 在安装脚本之外还多一步：脚本写下的那一行要加载 DSH 的 Claude Code 钩子桥，而它不是 dsh 的依赖，所以每个你会用到的 profile 都要执行一次 `dsh plugin --profile <名字> add @deepseek-ai/dsh-hooks-claude-code`——脚本会点名还缺它的 profile。那座桥解析配置路径时对齐的是启动 dsh 的目录，所以那一行能服务所有 STAR 项目；请在项目根目录启动 `dsh`，并用 `dsh --profile <名字> --dump-config` 核对结果。在那里恢复模型 id 需要 PATH 上有 `zstd`，因为 DSH 的会话日志按 Zstandard 分帧存放；没有它，`model_id` 就退回 `unrecorded`。在某个钩子出现之前就接入的项目，保留的是它自己的注册文件——`execs/update.sh` 从不覆盖它，只会把缺的那个钩子点名报出来；Pi 同样不受这一条影响，因为它的注册是代码，更新器每次都会替换。手动方式与细节见 [`.kimi-code/hooks.example.toml`](.kimi-code/hooks.example.toml)。各运行时上报什么、取不到时退回什么，见[模型 id 溯源](docs/mds/star-workflow/model_id_spec.zh-CN.md)。

### 为状态收集脚本预先授权

有六个 skill 在动手之前都要打开同一批计划、run 日志与报告：`star-flow-status`、`star-expt-digest`、`star-plan-decomposer`、`star-plan-executor`、`star-plan-reviser` 与 `star-metd-summarize`。它们不逐个打开文件，而是各自用一个只读脚本一次收齐——所用工具目录下、各 skill 自己目录里的 `scripts/scan.sh`。这是一次 shell 调用，所以 agent 第一次运行它时会请求授权。

全新安装的 Claude Code 无需任何设置：`.claude/settings.json` 已附带只针对这六个脚本的放行规则，不涉及其他任何命令。更早接入的项目会保留它自己的 `settings.json`——`execs/update.sh` 只在该文件缺失时安装它，绝不覆盖——因此需要自己补上这些规则：

```json
"permissions": {
  "allow": [
    "Bash(bash .claude/skills/star-flow-status/scripts/scan.sh)",
    "Bash(bash .claude/skills/star-flow-status/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-expt-digest/scripts/scan.sh)",
    "Bash(bash .claude/skills/star-expt-digest/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-decomposer/scripts/scan.sh)",
    "Bash(bash .claude/skills/star-plan-decomposer/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-executor/scripts/scan.sh)",
    "Bash(bash .claude/skills/star-plan-executor/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-reviser/scripts/scan.sh)",
    "Bash(bash .claude/skills/star-plan-reviser/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-metd-summarize/scripts/scan.sh)",
    "Bash(bash .claude/skills/star-metd-summarize/scripts/scan.sh:*)"
  ]
}
```

其他工具可在被询问时授权一次，或预先加入白名单：

| 工具 | 在哪里预先授权 |
|---|---|
| Codex | 其审批策略 / 沙箱设置（全局配置，非按项目） |
| Cursor | 应用设置里的命令白名单 |
| DSH | 全局 `$DSH_HOME/cordis.patch.yml`——DSH 不从项目里读取任何插件配置 |
| Kimi Code | 全局 `~/.kimi-code/config.toml`——Kimi Code 不读取项目级配置 |
| Pi | 无需预批：Pi 没有权限体系。`.pi/extensions/star-permission-gate.ts` 会在 `rm -rf`、`sudo`、`chmod 777` 前弹确认；无界面运行时直接拒绝 |
| Qwen Code | `.qwen/settings.json` 里的 `permissions.allow`，随仓库带好了扫描命令 |

该脚本只读：它遍历 `metds/` 与 `wkdrs/`，打印 frontmatter 与文件清单，不向任何地方写入。

## 项目记忆

一次会话学到、又没有任何计划、日志或报告认领的事实——某个 build 必须先 load 一个 module 才过、你的某项长期偏好、一个不值得再跑的实验——记在项目里的 `.star/memory/`，而不是你当时恰好在用的那个工具里。一事一文件，每条在 `.star/memory/MEMORY.md` 里占一行；会话钩子在每次会话开始时把这份索引送到 agent 面前，七个工具都是如此。

两条规则让它不会变成与真相竞争的第二个源头：

- **只有当项目里没有任何文件已经认领这条事实时，它才被记进去。** 结果属于那次运行的 `EXEC_LOG.md`，关于研究的决定属于它的计划，论文属于 `metds/refs/`。记忆装的是残余。
- **记忆与仓库里的文件冲突时，以文件为准**，随后把这条记忆改正或删掉。

只在这台机器上成立的事实放 `.star/memory/local/`，git 像忽略 `.env` 一样忽略它。任何东西都不会不打招呼就记下来：agent 提议，你来定——`.env` 里设 `INVOLVE=low` 则改为先记下再告诉你。四类记忆、文件格式，以及一条记忆怎么退场，见[项目记忆](docs/mds/star-workflow/memory_spec.zh-CN.md)。

## 更新 STAR 的 skill 与工作流指南

基于 STAR 创建项目后，可以只同步 STAR 后续发布的 skill 与研究工作流指南，而不改动项目代码、实验配置或 Git remote：

```bash
bash execs/update.sh
```

该命令默认从 STAR 的 `main` 分支更新以下路径——七棵工具树全在其中，除非 `STAR_TOOLS` 或 `--tools` 收窄了范围。`.agents/skills/` 不受这种收窄影响：`AGENTS.md` 约定把 skill 放在这里，所以无论点名了哪几棵树，每次运行都更新它，而且排在最前面。

- `.cursor/rules/skill-roots.mdc` 与 `.pi/APPEND_SYSTEM.md`——各个 skill 根目录归哪个工具所有，以及 Cursor 和 Pi 该跟随哪一份副本
- `.agents/skills/`——共享根目录，每次运行都更新——然后是 `.claude/skills/`、`.cursor/skills/`、`.dsh/skills/`、`.kimi-code/skills/`、`.pi/skills/`、`.qwen/skills/`
- `.codex/skills/`——Codex 读的那份每技能一份的清单，随它那棵树一起安装；上游 `.agents/skills/` 用软链接指过去，项目拿到的两边都是实文件
- `.claude/commands/`、`.cursor/commands/`、`.qwen/commands/` 与 `.pi/prompts/`——把描述出来的需求分流到某个 skill 的 `/star` 斜杠命令，外加 Pi 那份每个 skill 一条的 `/star-<名>`
- `.pi/agents/`、`.pi/extensions/star-plan-mode/`、`.pi/extensions/star-subagent/`、`.pi/extensions/star-permission-gate.ts` 与 `.pi/extensions/star-questionnaire.ts`——Pi 内核不自带的子代理、计划模式与结构化提问；你项目自己的扩展就放在它们旁边，不会被动到
- `.claude/hooks/`、`.codex/hooks/`、`.cursor/hooks/`、`.dsh/hooks/`、`.kimi-code/hooks/`、`.pi/extensions/star-hooks/`、`.qwen/hooks/`，以及注册它们的那几个文件（注册不是自动的那几家）`.dsh/hooks.json` 与 `.dsh/cordis.patch.yml`、`.kimi-code/hooks.example.toml`、`.pi/extensions/star-hooks/index.ts`——model-id 溯源、项目记忆、INVOLVE=low 放行编辑三个钩子
- `docs/mds/star-workflow/` 与 `docs/srcs/`——工作流文档，以及 STAR 自有页面使用的图标和流程图
- `execs/run.sh`——出厂的实验启动脚本；你对它的改动会被替换，而它所启动的实验脚本（`execs/scpts/` 下）属于项目自己，绝不会被动到
- `execs/update.sh`——更新脚本自己，好让你的项目建好之后上游才新增的路径仍然能到达它

agent 协作规范归项目自己所有：`AGENTS.md` 与抄录其正文的 `.cursor/rules/agent-instructions.mdc` 不在上面这份清单里。它们遵循与下文钩子注册配置相同的规则——仅在缺失时安装，除非加 `--force`，否则绝不覆盖。已经写了自己那一份的项目会原样保留；一份都没有的项目则从上游取得。

拉取来源由 `STAR_REPOSITORY` 指定，取值顺序为：环境变量、`.env`、内置默认值 `https://github.com/wanghao9610/STAR.git`。想长期跟随某个 fork，就写进 `.env`；只想临时改一次，在命令前加变量即可——`STAR_REPOSITORY=… bash execs/update.sh`。

七棵工具树里动哪几棵，由 `STAR_TOOLS` 指定，取值顺序相同：环境变量、`.env`、默认全部。在 `.env` 里写 `STAR_TOOLS=claude,pi` 就只维护这两棵；另外两个取值是 `all` 和 `none`，`none` 表示这次更新只剩共享骨架——现在共享骨架里也包含 `.agents/skills/`——工作流文档、`execs/run.sh`、更新脚本自己、`AGENTS.md`。没被选中的树完全不碰：不安装、不更新、也绝不删除，所以删掉了用不到的那几棵的项目，下次更新不会再被装回来；七棵都留着的项目不设这个键，行为和从前一样。收窄过的运行还只拉取它将要写入的那几棵，未提交改动的拦截也只覆盖这几棵。

钩子注册配置——`.claude/settings.json`、`.codex/hooks.json` 与 `.cursor/hooks.json`——仅在缺失时安装，除非加 `--force`，否则绝不覆盖。若保留下来的配置没有注册 STAR 钩子，命令会打印提示。

更新脚本自己也在更新范围内，于是它同步的清单会跟着上游长，而不是永远停在你项目创建时的那一份——斜杠命令和 Pi 的那几个扩展能到达更早创建的项目，靠的就是这一条。替换方式是改名而非就地覆盖，所以做替换的这一次运行仍用它启动时的那份副本跑完，新版本从下一次运行起生效；命令替换了自己时会明说，再跑一次就能收到新版更新器新增的路径。若项目的更新脚本比这条改动还早——它的 `Updated:` 那一行里没有 `execs/update.sh`——需要先手动刷新一次，这个循环才转得起来：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o execs/update.sh
```

命令的通用形式为 `bash execs/update.sh [--diff] [ref] [--tools LIST] [--skill NAME] [--force]`：

- `--diff` 在不改动任何文件的情况下预览更新，有可更新内容时以 `2` 退出，完全一致时以 `0` 退出，出错时以 `1` 退出——脚本因此能区分“有更新”与“检查本身失败”。
- `ref` 把更新固定到某个 tag 或分支。
- `--tools LIST` 把这一次运行限定在点名的那几棵树上——`claude,pi`、`all` 或 `none`——仅对本次覆盖 `STAR_TOOLS`。`.agents/skills/` 无论如何都会更新，所以删掉它会被下一次运行装回来，工具树则不会。名称不认识时命令会停止，并列出七个有效名称。
- `--skill NAME` 只更新共享根目录与其余六个工具目录中的这一个 skill——收窄过的话就是剩下的那几个目录——不动工作流文档和溯源钩子。名称无效、或本次范围内的上游 skill 目录中有任何一处缺少它，命令会停止且不覆盖任何文件。
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
- 删掉用不到的工具目录。`.agents/`（`AGENTS.md` 约定规定放技能的那个共享根目录）、`.claude/`、`.cursor/`、`.dsh/`、`.kimi-code/`、`.pi/`、`.qwen/` 装的是同一套十五个 skill，每套约 150 个文件；留下你所用 agent 会读的那一套，其余 `rm -rf` 即可。用 Codex 时 `.codex/` 要和 `.agents/` 一起留着：钩子在那里，`.agents/skills/` 在 Codex 扫描的路径上软链接过去的那十五份 per-skill 清单也在那里。用 `execs/update.sh` 接入或更新出来的项目里，每棵树都是各自独立的实文件副本，删除顺序无所谓——更新器复制时会把软链接指向的内容写成实文件。直接克隆 STAR、或用 GitHub 模板生成的仓库则不然：各家措辞完全一致的那批文件只在 `.agents/skills/` 下存一份，其余六棵靠相对软链接指过去。此时先用 `tar -chf - .claude/skills | tar -xf -`（树名换成你要留的那棵）把留下的那棵变成独立副本，它会把其中的软链接原地换成所指的文件（`-h` 表示跟随软链接，BSD 与 GNU 的 tar 都可用），`.agents/` 放到最后再删。删不是唯一的路：接入时用 `--tools` 点名要装哪几棵，`.env` 里的 `STAR_TOOLS` 则让之后的 `bash execs/update.sh` 不会把删掉的那几棵装回来——见[更新 STAR 的 skill 与工作流指南](#更新-star-的-skill-与工作流指南)。用 Pi 和 DSH 时这一步不只是可选：两者除了自己的根目录（`.pi/skills/`、`.dsh/skills/`）还会读 `.agents/skills/`，删掉 `.agents/` 就从源头消除了重名冲突——Pi 那边否则只能靠 `.pi/APPEND_SYSTEM.md` 去把 agent 劝回来，DSH 那边则由发现顺序自动定胜负，结果是对的，但你看不见。

只保留确实有助于研究的结构——STAR 应当服务于研究，而不是限制研究。骨架本身可独立使用：目录布局、`.env` 和 `execs/run.sh` 在完全不装任何 skill 的情况下也能工作，因此删掉全部工具目录同样是受支持的用法。

## 更新日志

按版本列出要点，最新在前。每个版本对应一个 git tag，因此 `bash execs/update.sh v0.1.0` 可将更新固定到该版本。

- **[v0.2.6](https://github.com/wanghao9610/STAR/tree/v0.2.6)**（2026-08-20）—— `.agents/skills/` 是凡遵循 `AGENTS.md` 约定的 agent 都会读的共享根目录，不是某一家宿主自己的私有目录，因此其中十五个 skill 的正文不再点名任何一家自有的工具——一律改用角色指代，读者统称 agent——也不再带任何一家的调用前缀，因为前缀各家写法不同，而各家自己清楚该怎么写。Codex 自己那份每个技能一份的清单——显示名、默认提示词，以及决定一个技能是否只在被点名时才跑的那个开关——迁到 `.codex/skills/<skill>/agents/openai.yaml`，再由 Codex 扫描的那个路径上的相对软链接指过去，因为 Codex 只会从技能目录内部读这份清单。`execs/update.sh` 现在每次运行都同步 `.agents/skills/`，排在最前，且不受 `--tools` 点名范围影响——它是 STAR 没有为其准备工具树的那类 agent 会读的那一份，所以删掉它会被下一次更新装回来，工具树则不会；`--tools codex` 现在只收窄到 `.codex`，项目拿到的仍是实文件，软链接在复制时被写成实文件。
- **[v0.2.5](https://github.com/wanghao9610/STAR/tree/v0.2.5)**（2026-08-19）—— 七棵工具树里措辞完全一致的那批文件改为只存一份，落在 `.agents/skills/` 下，其余六棵在相同路径上放一条相对软链接；每个 `SKILL.md`，以及凡是写了某家自有内置工具名的参考文档与模板，仍是各棵树各自的实文件。接入与更新不受影响：`execs/update.sh` 复制时会把软链接指向的内容写成实文件，项目拿到的仍是每棵树一份独立完整的副本。只有直接克隆本仓库才带着软链接，此时先用 `tar -chf - .claude/skills | tar -xf -` 把要留的那棵变成独立副本，再把 `.agents/` 放到最后删掉。
- **[v0.2.4](https://github.com/wanghao9610/STAR/tree/v0.2.4)**（2026-08-19）—— 一次运行拟出一张要你逐条接受或否决的清单时，不再一条一条问：规约 [§7.13](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 把整张清单定成一个问题——编号行连同"改什么、依据是什么"先摊在页面上，然后只问一次：*全部按清单采纳* / *除我点名的以外全部采纳* / *先解答我点名的几项* / *一项都不采纳*，被点出来的行进第二轮，形状照旧。`star-plan-reviser` 的修订候选与 `star-code-reviewer` 要问的那批修复就此不再逐条走；`star-code-architect`、`star-code-release`、`star-plan-executor`、`star-metd-summarize` 那几个本来就成批问的问题，补上了"先解释这几项"这条从来没有过的路；而必须单独问的仍旧单独问——红线上的一切、每一次删除与覆盖，以及放弃一个计划。引导式提问不受影响，因为每个答案决定下一个问什么的辅导连问没有拟好的东西可以摊开；`involve=high` 会把任何一张清单重新拆回一行一问。
<details>
<summary>更早的版本</summary>

- **[v0.2.3](https://github.com/wanghao9610/STAR/tree/v0.2.3)**（2026-08-19）—— `execs/update.sh` 不再把七棵工具树当成不可分的一整块：`--tools claude,pi` 把这次运行限定在点名的那几棵上，`.env` 里的 `STAR_TOOLS` 让这个选择长期生效，另外两个取值是 `all` 与 `none`——`none` 表示这次更新只剩共享骨架：工作流文档、`execs/run.sh`、更新脚本自己、`AGENTS.md`。没被选中的树完全不碰：`--adopt` 不装、更新不写、也绝不删除，所以删掉了用不到的那几棵的项目，下次更新不会再被装回来。收窄过的运行只拉取它将要写入的那几棵，未提交改动的拦截也只针对这几棵。
- **[v0.2.2](https://github.com/wanghao9610/STAR/tree/v0.2.2)**（2026-08-18）—— `star-code-reviewer` 的修复轮不再逐条问每一处例行修复：`minor` / `nit` 级的那些——docstring、注释、未使用的 import、引用全落在审查范围内的改名——直接改，改之前在摘要里点名，报告里记为 `applied unasked`；`blocker` / `major` 仍然逐条先问、任何参与度档位都问，删代码的修复不论严重度也照问，因为看着没人引用的符号可能是通过 registry 字符串取到的。可修项全是 minor 的那一轮，从此不为其中任何一条停下来问——为一处 docstring 问一次所花掉的注意力，正是报告本身需要的。`involve=high` 时不问的那一半重新交回用户，按同类合并。
- **[v0.2.1](https://github.com/wanghao9610/STAR/tree/v0.2.1)**（2026-08-18）—— 对照算法研究实际的推进方式复查流程后，补上"一个叶子一次 run"这个假设装不下的几类工作：一组配置（超参网格、多 seed 重复）现在是一个叶子，在 §3 声明轴与格数、按格落在 `wkdrs/<run>/cells/` 下、判据对整张网格说，分析报选中格时必须同时报同轴上的散布；重实验的预计与实际开销进入 `EXEC_LOG.md` 新增的"开销"一节，那是根计划 §4 算力预算唯一的对账处。方法还没定的时候，探针叶子是正当的一格——它的 §5 写成"看什么 → 哪种结果触发哪个决定"，数字只作未核实层，因此不会把一个猜想抬成主张；被否掉的方向除了留在原处的完整交代，还向上汇总一行到根计划 §5、紧挨着当初预测它的 kill-criteria，因为那棵子树此后不会再被打开。构建数据的叶子不再以文件数与校验和收尾（要关键统计量、写明抽样量的人工抽查、与评测集的重叠检查），消融选定的配置必须写成具名文件供下游叶子按路径引用；另修掉一处缺陷：编译方法文档所依据的抽取图，中文版把计划模板的五个小节名记成了旧名；升级换的是模板、不动已经写好的文件——已有的子计划与 `EXEC_LOG.md` 不会自动长出这些小节，下次调用对应技能时补上，或让 `star-plan-reviser` 在修订那份计划时带入。
- **[v0.2.0](https://github.com/wanghao9610/STAR/tree/v0.2.0)**（2026-08-18）—— 整套工作流的措辞从软件开发口径换成算法研发口径：落盘改成存成文件，冒烟测试改成跑通性检查（参考文件跟着改名），契约按语义拆成派给子代理的交办说明和它要还回来的格式约定，日志里说过的事在产物证实之前一律叫说法。`checkpoint` 现在只指模型权重——git 那一义叫阶段提交，动词那一义叫记录——共享规约的词汇表（[§0](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)）新增十一行把新说法钉死，而 git 自己的词、计划模板的小节名、ML 代码库里的注册器，以及任何被别的技能按字节读的字面量，一律不动。README 与使用指南按研究推进的五段重排——定选题并写成计划、把代码和环境准备到实验真能跑起来、拆成子问题一块块做、读结果再带回计划、写成文字并收拾仓库——指南开头还多了一张「从哪儿下手」的表，让人只读自己所在的那一节，而不是另外十四节。
- **[v0.1.46](https://github.com/wanghao9610/STAR/tree/v0.1.46)**（2026-08-13）—— `.pi/` 补上了 v0.1.44 只能替换掉的那三样机制，全部借自 pi 自己的 `examples/extensions`（MIT）：`star_subagent` 派发到新增的 `.pi/agents/` 花名册——收集者、执行者、复核者，对应规约 [§6](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 点名的三类受派方——`star_questionnaire` 负责提问，`/star-plan` 负责只读探索，外加 `rm -rf`、`sudo`、`chmod 777` 之前的确认框。它们占用的每一个名字都加了前缀，连注入的上下文标记也不例外：两个扩展抢同一个工具名或开关时，pi 会直接 `exit 1`、整个会话起不来，而这几份示例很多人也装在用户级；标记不加前缀的话，用户级那份会把这份注入的消息静默过滤掉；四样都要等项目获得信任才加载，没有它们时技能回落到规约 §6.1 的本地履行和纯文本提问。调用方式现在只剩 `/star-<名>`——`.pi/prompts/` 每个技能给一条命令，`enableSkillCommands: false` 去掉了并排的 `/skill:` 那条——钩子也搬进了 `.pi/extensions/star-hooks/`，因为空的 `.pi/hooks/` 是扩展目录的旧名，只要它存在 Pi 每次启动都会警告。
- **[v0.1.45](https://github.com/wanghao9610/STAR/tree/v0.1.45)**（2026-08-13）—— 第七棵技能树 `.dsh/` 把十五个 skill 带到 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)：它发现 `.dsh/skills/` 的优先级高于 `.agents/skills/`，调用写作 `/skill:star-*`。有三处只能重做、改名不管用：每条 description 都重写到 500 字符以内，因为 DSH 的目录会在那里静默截断，而切掉的正是末尾那句触发语；DSH 没有 agent 类型参数、没有进入 plan 模式的工具、工具名全小写，所以 `subagent_type`、`EnterPlanMode` 与 `Bash` 是被替换掉而不是换个写法；钩子经 DSH 的 Claude Code 桥从 `.dsh/hooks.json` 读取，由 `.dsh/hooks/install.sh` 每台机器注册一次。参与度闸门是有意缺席的——DSH 默认的 `workspace-write` 沙箱让项目内的编辑直接执行、不问，没有弹窗要它回答——而 `model_id` 从会话日志里恢复，需要 PATH 上有 `zstd`。
- **[v0.1.44](https://github.com/wanghao9610/STAR/tree/v0.1.44)**（2026-08-13）—— 第六棵技能树 `.pi/` 把十五个 skill 带到 [Pi](https://github.com/earendil-works/pi)：调用写作 `/skill:star-*`，工具名用 Pi 自己的小写内置名（`read`、`bash`、`edit`、`write`、`grep`、`find`、`ls`），三个钩子由一个 Pi 自动发现的 TypeScript 扩展接线——没有注册文件要合并，`model_id` 也不会过期：扩展在每次提问前读当前模型，`/model` 一换就再注入一行。Pi 不提供子代理、计划模式和权限弹窗，所以这是第一棵把这三样替换掉而不是改个名的树：提问一律纯文本，执行器自己守住「批准前不写文件、不跑命令」那道关，每一处派发都落回规约 §6.1 的本地履行。参与度闸门有意缺席——它是用来回答权限弹窗的，而这里没有弹窗；`.pi/APPEND_SYSTEM.md` 则解决该按哪份副本执行的问题，因为 Pi 也会读 `.agents/skills/`。
- **[v0.1.43](https://github.com/wanghao9610/STAR/tree/v0.1.43)** (2026-08-12) — 新的 `model_trail` 或 `## Revision History` 条目该落在哪一端，此前从没写出来过：规约 [§8](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 只说只追加，位置全靠暗示，于是 Claude Code 的会话把最新一条写在最后，Cursor 的会话把它顶到最上面。现在写明：新条目一律加在列表末尾、排在所有旧条目之下，不论在哪个运行时——三处写入者真正会读到的地方都补上了：§8、每份产物模板里 `model_trail` 那行注释，以及管着 Revision History 条目的那两个文件。整体重生成的视图不动，各自保持原有次序：这份更新日志、`MODEL_LEDGER.md` 和 `MEMORY.md` 索引都是最新在前。
- **[v0.1.42](https://github.com/wanghao9610/STAR/tree/v0.1.42)** (2026-08-12) — `star-plan-executor` 不再以"推荐审查"收尾：报告那一步只留报告要说的话，新增一步在同一轮里直接把 `star-code-reviewer` 对着这个叶子启动——规约 [§10.6](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 本来要的就是这个。唯一那个很窄的跳过备选（探索性叶子、交回的命令很便宜）仍然问一次，`low` 档取推荐项即启动审查。§10.6 也补上了"运行结束之后"是哪一刻：报告发出的同一轮，而不是等用户下一次开口。
- **[v0.1.41](https://github.com/wanghao9610/STAR/tree/v0.1.41)** (2026-08-12) — 哪些 skill 会提参与度档位此前是随机的：十二个会写文件的现在都在调用说明里提一句、排在描述之后，只读的报告型都不提——`star-flow-status` 除外，它按条装载规约 §7、偏偏不含剥离这个记号的那一条，于是保留一句机械说明，否则没有别处会说。`.claude` 与 `.qwen` 的参数提示按常用档位标注：三个改计划的标 `involve=high`，五个搭代码或执行的标 `involve=low`，其余跟 `.env` 里的 `INVOLVE`。`.qwen` 的中文提示同时补上了 v0.1.37–38 加描述时漏掉的那一格。
- **[v0.1.40](https://github.com/wanghao9610/STAR/tree/v0.1.40)** (2026-08-12) — `star-plan-executor` 与 `star-plan-decomposer` 的调用说明改按规约 [§7.12](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 写的次序出场——计划名、描述、`involve=`——不再把档位排在它要从中剥离的那段文字之前。那一句本身也随之写明：这个写法既不属于计划名也不属于描述，两者解析之前先剥离；解析没有变化，它本来就与位置无关。
- **[v0.1.39](https://github.com/wanghao9610/STAR/tree/v0.1.39)** (2026-08-11) — `star-plan-executor` 现在会在开工前判断这个叶子是否还是一个工作单元，依据都在计划自己的正文里：不止一条彼此独立的完成判据、不止一次越过红线、取数据与建代码跑实验混在一起，以及步骤超过 12 条、产物横跨互不相关的产物族这一对只在同时命中时才算数的弱信号。命中时先展示这个叶子会怎么分——2–5 个单元，每个带上它会拥有的那条完成判据，是草图而不是文件——并推荐 `star-plan-decomposer <叶子>`，把草图作为描述一并带过去；照原样执行仍是一个选项，代价会一并说明。恢复中的 run 不会被问，而画完的 `EXEC_PLAN` 会在审批确认点给同一个问题第二次读数，不额外花一趟往返。
- **[v0.1.38](https://github.com/wanghao9610/STAR/tree/v0.1.38)** (2026-08-11) — [§7.12](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 定义的描述铺到了名册其余部分：另外十一个 skill 也收参数之后的自由文本，各自写明它能做什么——引导这次运行看哪里、提供运行随后写进产物的文字——以及不能做什么：顶替确认点。与某个 skill 的参数都对不上的成句文本就是描述，运行照不带参数那样跑并先说明这一点；而形似参数、却什么都对不上的孤立词仍然是要问清的问题，不是可读的散文。第一个参数本来就是自由文本的三个——`star-idea-storm`、`star-plan-coach`、`star-refs-reviewer`——不用改，那个参数就是描述。
- **[v0.1.37](https://github.com/wanghao9610/STAR/tree/v0.1.37)** (2026-08-11) — 规约 [§7](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 新增第 12 条：`<skill> [目标] [描述] [involve=<档位>]` 是整份名册共用的形状，目标之后的自由文本就是用户用自己的话说明这次运行要做什么。它是线索而不是命令——可以引导运行、也可以提供运行随后写进文件的文字，但绝不顶替确认点、绝不替 §5.2 该问的目标做主、也绝不授权红线上的动作——由描述定下路径的运行还要在写入之前说明自己走的是哪条路，于是读错的代价是一行字，而不是一处改错。`star-plan-reviser` 第一个用它换掉关键词：`drop` 与 `undrop` 取消，「这条不做了，由 02 取代」既选定丢弃那条路，又成为写进计划的理由。
- **[v0.1.36](https://github.com/wanghao9610/STAR/tree/v0.1.36)** (2026-08-11) — 只装载自己要用的那几节规约的两个 skill——`star-refs-reviewer` 与 `star-expt-digest`——现在把摘录拆到同一条消息的两次调用里：大小上限是按每份工具结果算的，而七节挤在一次调用里已经逼近守着它的预算，只差约 10 字节。拆开后每次调用 12–17 KB，还留着增长空间，而装载代价不变：同一条消息里的多次调用之间只算一趟往返，不是各占一趟。一致性检查第 20 项随之改为读取文件里的每一个选择器、各自单独计量，并把散文、引用与所报总量对着它们的并集来核——预算也退回本轮之前的 28400 字节。
- **[v0.1.35](https://github.com/wanghao9610/STAR/tree/v0.1.35)** (2026-08-11) — 把十五个 skill 过了一遍找冗余，值得删的有两处。`star-flow-status` 那句「不设字数上限」放松了规约 [§7.1](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 的约 500 字上限，而优先级规则只允许 skill 收紧、不允许放松，于是把这条例外写回 §7.1——长度由必须逐条列出的内容决定的回复，改由形状约束——报告则改为援引它，而不是自称没有上限。`level:` 由模板写进每一份子计划，却没有任何 skill 读它，值又等于前缀的位数，删掉；其余看着重复的，要么是 CI 强制五棵树逐字一致的文本，要么边界早已写在可能混淆的地方。
- **[v0.1.34](https://github.com/wanghao9610/STAR/tree/v0.1.34)** (2026-08-11) — 新的丢弃字段照出来的五处遗留。`exec_status: skipped` 没有任何 skill 会写它，于是不再是合法取值，只在计划手工写过时仍被认得；而 `abandoned`——它此前既没有自己的状态符号，在方法文档的就绪门槛里也没有位置——现在有了自己的符号 `✖`（判读规范的示例树里就与那对已丢弃节点并排），像已丢弃的叶子一样退出执行进度的分母、不再让这个比值永久卡在 100% 以下，也能通过 `star-metd-summarize` 的就绪检查，同时一行内容都不进任何文档。代码审查过期那条检查改为比对该 run `EXEC_LOG.md` 里最新的日期——扫描给每个 run 打的日期行本来就收集了文件里的全部日期——而不是比对日志模板里从来就没有的步骤表日期列，正是后者让规范一直得承认这一行基本触发不了。
- **[v0.1.33](https://github.com/wanghao9610/STAR/tree/v0.1.33)** (2026-08-11) — 一份计划现在可以被放弃而不必删除：`star-plan-reviser <计划>` 加一句表达放弃这个方向的描述，就在该节点上写入 `dropped: <日期> — <原因>`——这条路跳过审查，因为丢弃记录的是已经做出的决定，理由直接取自你说的那句话——所有 skill 都按整棵子树继承来读这个字段，于是一行就把这个节点连同它的后代移出计数、覆盖检查与下一步动作。`star-flow-status` 把它们渲染成 `⊗`、括号里保留丢弃前的状态并排除在三个数之外，`star-plan-executor` 与 `star-plan-decomposer` 拒绝对它们动手，`star-metd-summarize` 也不从它们编译任何内容——而父计划保留 `children:` 条目与索引行，行上标 `— dropped <日期>`，所以「这条路试过」仍然读得到。丢弃不隐藏的是磁盘上还在的东西：仍依赖着被丢弃节点的活叶子、未合并的执行分支、它下面的 worktree，各自照旧得到一条失配标记。
- **[v0.1.32](https://github.com/wanghao9610/STAR/tree/v0.1.32)** (2026-08-11) — `star-flow-status` 现在把范围内的每个节点都单独打一行，那条约 500 词的回复预算——正是它逼着大树被折成"8 个叶子全部完成"这类句子——也取消了：报告该多长由它要展示的树决定，其余部分改由形状约束——每节点一行、每个计数一句、每条触发的检查一行。`PLAN_NAME` 参数从此收窄的不只是检查，还有渲染：Step 2 就把树剪到解析出的子树，三个计数也只在它上面算。它的 spec 新增限定范围一节，写明一个从不提问的 skill 碰上歧义名该怎么收场：数字前缀精确匹配足以分开两棵同 slug 的根，命中多份就每份都渲染，一份没命中就列出候选并停下。
- **[v0.1.31](https://github.com/wanghao9610/STAR/tree/v0.1.31)** (2026-08-11) — 七个 skill 派出的只读收集器——`star-code-reviewer`、`star-expt-analyst`、`star-plan-reviser`、`star-proj-adopt`、`star-code-architect`、`star-idea-storm`，以及 executor 的只读勘察步骤——在 `.claude/` 这一棵树里写明 `model: sonnet`，也只有它的宿主认这个参数：它们都是照写死的返回格式抄录、不下任何判断，而它引用的每一行，在进报告或进确认点之前主 agent 都要重开确认。判断或写作本身就是产出的那些委派仍用会话模型：executor 的步骤 agent、architect 的迁移执行者、`star-refs-reviewer` 的单篇笔记、`star-plan-coach` 的定稿盲读。`star-code-reviewer` 另外不再在任何规模下由主 agent 自己收集问题项——一直在讨论这份代码的上下文不是它的中立读者——改为按规模分派：约 50 个文件以内一个收集器，超过则每片 10–15 个文件。
- **[v0.1.30](https://github.com/wanghao9610/STAR/tree/v0.1.30)** (2026-08-10) — 先摆内容再提问的七个 skill——`star-plan-coach`、`star-idea-storm`、`star-plan-executor`、`star-code-release`、`star-metd-summarize`、`star-refs-reviewer`、`star-proj-adopt`——现在把这条要求同时写在"发问"那一端，而不只写在"写内容"那一端；后者正是 v0.1.29 在 `star-plan-decomposer` 身上认定为不够用的写法。每个 skill 的对话纪律多一行，点名它自己的那份内容——一批评分表不达标项、一张候选表、一批待同步修正——并带上随之而来的回看：选项上面空无一物，说明内容是被跳过了、不是被压缩了。这条规则没有写进规约 [§7.3](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)（十五个 skill 本可一并继承），因为 `star-refs-reviewer` 对该文档的按节载入距 28400 字节的预算只剩 49 字节余量。
- **[v0.1.29](https://github.com/wanghao9610/STAR/tree/v0.1.29)** (2026-08-10) — `star-plan-decomposer` 的子计划清单确认重新走提问工具，三个答案又能点选而不必手打，卡片写在同一条消息的正文里、排在这次调用之前。v0.1.28 把这次确认整段改成纯文本，依据是客户端可能吞掉同一轮里工具调用之前的文字；此后一次运行显示选轴那题上面的文字渲染正常，剩下的只有起草时跳过卡片一种，于是防跳过的那句话从"写内容"处挪到"发问"处。对话纪律随之改口：装不进选项的内容——某份子计划草稿、回写父计划的索引草稿、评分表不达标项——排在调用之前，而不是取代它。
- **[v0.1.28](https://github.com/wanghao9610/STAR/tree/v0.1.28)** (2026-08-10) — 确认型问题不再代替它所问的内容：`star-plan-coach` 与 `star-idea-storm` 的评分表不达标项、`star-plan-executor` 的待同步修正、`star-code-release` 与 `star-metd-summarize` 的分节变更清单，现在都在提问之前逐条落到正文。内容本来就装不进选项的地方——`star-refs-reviewer` 的约 15 篇排序候选、`star-proj-adopt` 无上界的 run 与叶子清单——改为给行编号、推荐标在表里、对着编号提问，因为规约 [§7.3](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 把一题的选项封在 4 个。`star-plan-decomposer` 的子计划清单与针对它的问题现在作为同一条消息发出，中间不隔工具调用——卡片写好后在同一轮里用提问工具确认，已经出现过用户只看到三个选项、上面什么都没有的情况。
- **[v0.1.27](https://github.com/wanghao9610/STAR/tree/v0.1.27)** (2026-08-10) — `star-plan-decomposer` 的子计划清单改为每个单元一张卡片——目标、步骤、产出物、完成判据——在请你确认之前就摆出来；此前展示的是一排标题，内容要等下一步才出现。卡片是草图不是草稿：六节仍由 Step 4 写，它展开拿到的那张卡片，起草若逼得卡片上某一条必须改，会明说。参与度档位不动：`low` 不问即采纳清单，卡片照样完整展示；`high` 另外在每份子计划写入前确认草稿。
- **[v0.1.26](https://github.com/wanghao9610/STAR/tree/v0.1.26)** (2026-08-09) — `star-refs-reviewer` 的精读笔记从至多一张架构图放宽到至多三张，选哪几张由论文本身的性质决定：整体展示方法的那张仍然优先占位，数据集论文的构造流水线、分析类论文主张所压的那张图、指标报不出来的定性对比，只在笔记正文带不动它时才留。每张留下的图都要配 2–4 句，说明它画了什么、该怎么读，只依据图注全文和正文里按编号引用它的句子写——这样写不出来的图就不留，两处都没说的细节标 `[unverified]`。笔记收集器为此在每条图注旁多返回 `referenced_at`，图注也不再截到 200 字符。
- **[v0.1.25](https://github.com/wanghao9610/STAR/tree/v0.1.25)** (2026-08-08) — 第五棵 skill 树 `.qwen/` 把十五个 skill 带到 Qwen Code：调用写法与 Claude、Cursor 相同（`/star-*`），四个钩子全部注册在项目自己的 `.qwen/settings.json` 里——参与度闸门也在其中，这是它第三次落地，因为 Qwen Code 的 `PreToolUse` 能回 `permissionDecision: "allow"`。移植写的是 Qwen Code 的工具标识符（`run_shell_command`、`read_file`），而不是它同时公布的界面展示名——它自带的 skill 从不写展示名——check 23 现在逐棵树钉住这个选择。`allowed-tools` 是有意不带的：Qwen Code 的 `allowedTools` 给的是本次会话内的免确认放行而不是收紧权限，照搬过去只会放宽 skill 能做的事，而不是限制它。
- **[v0.1.24](https://github.com/wanghao9610/STAR/tree/v0.1.24)** (2026-08-08) — run 可以住进 executor 自己创建的 `git worktree` 了：分支照旧隔离历史，树回答的是另一个正交的问题——checkout 正忙（HEAD 停在别的 run 的分支上、工作区有归属别人的未提交路径、交回用户的命令还没回收结果）——与分支在同一个审批确认点上定夺，进树的 run 一律带分支（规约 [§11.7–9](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)）。树建在 `../<根目录名>--wt/<run>`，链入 `.env`、`datas/`、`inits/`，路径以 `worktree:` 记进运行记录；合并在主 checkout 里 squash、什么都不用切，移除前先把非 md 产物挪出来——绝不带 `--force`，`star_commit_guard.sh` 现在直接拦下它。`star-flow-status` 在执行分支旁边列出 worktree，并标记被遗留的树。
- **[v0.1.23](https://github.com/wanghao9610/STAR/tree/v0.1.23)** (2026-08-08) — `star-code-reviewer` 不再让写代码的那段对话自己收集问题项：本会话此前写出或改过范围内文件时，小范围收集也交给一个带全部文件清单、上下文全新的只读收集器，并在报告范围行记下这次委派。作者重读自己的代码，读到的是当初产生它的那套推理；较大范围本就经收集器收集，这次补上的是小范围（≤ 约 20 个文件，diff 审查的常态）这个缺口。
- **[v0.1.22](https://github.com/wanghao9610/STAR/tree/v0.1.22)** (2026-08-08) — 执行分支改用 run 自己的名字 `<run>`，分支与 `wkdrs/<run>/` 直接同名、不必再剥前缀，各 skill 开场读取的那份分支清单也随之改成按 run 命名规则匹配的通配。另一条线上，`star-flow-status` 与 `star-expt-digest`——仓库里仅有的两个 `context: fork` skill——改从调用方式那一行的 `$ARGUMENTS` 占位符读参数：fork 看不到用户消息，宿主只能把参数追加在整份清单之后，`/star-flow-status 030` 因此稳定漏读、报出整棵树而非该计划的子树。不带参数时占位符在三条调用路径下都替换为空，不留字面量。
- **[v0.1.21](https://github.com/wanghao9610/STAR/tree/v0.1.21)** (2026-08-07) — 委派不再是例外：[§6](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 把这个决定交给主 agent，取消「同时最多三个」的死上限，也不再把会改文件的委派限定给 `star-plan-executor` 与 `star-code-architect`，`star-flow-status` 则去掉了全套 skill 里唯一一条禁止派 subagent 的硬规定。保留下来的都是本来就与谨慎无关的东西——并发委派之间文件归属互不重叠、主 agent 亲自重跑每个检查并独占判断、只读委派什么都不写，以及抓取型并行派发真正的边界所在：按 host 的请求预算。另一条线上，Claude 清单新增 `argument-hint` 与只覆盖当前轮次的 `allowed-tools`，并在 skill 新建文件而非编辑文件的路径上于 `Edit` 之外补上 `Write`；`allowed-tools` 是免确认授权，从不构成限制。
- **[v0.1.20](https://github.com/wanghao9610/STAR/tree/v0.1.20)** (2026-08-06) — 要修改既有代码的叶子可以在自己的分支上执行，改动挣到合并资格之前基础分支始终是准据：规约 [§11](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 让方案审批确认点推荐在 `exec/<run>` 上执行，选了分支就同时选了逐步提交，因为只有提交才会被合并。合并之前 run 写下的一切只存在于分支上，从基础分支看这个叶子就是还没做完，于是下游叶子自动保持受阻、一行新检查都不用写；合并是必问确认点、默认 squash，弃用时先把运行记录提交到基础分支，好让死路也留下证据。executor 周边：`star-code-reviewer` 按 `<base>...HEAD` 的 diff 审分支上的 run，`star-expt-digest` 把未合并分支列进缺口，`star_commit_guard.sh` 新增判定臂，拦下一键就能踩破这一切的写法。
- **[v0.1.19](https://github.com/wanghao9610/STAR/tree/v0.1.19)** (2026-08-06) — Kimi 树不再叫两个 Kimi Code CLI 根本没有的工具名：三十份清单把文件读取叫 `ReadFile`、把终端叫 `Shell`，而该宿主公布的是 `Read` 与 `Bash`——和 Claude 用的是同两个词——所以改动的四十六行里有四十五行与 Claude 对应行逐字节相同。这次撤销的重命名来自 [v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8)，那一版把 `.kimi-code` 按怀疑而不是按 Kimi 公布的清单一并扫了进去，这是同一个缺陷里更贵的那个方向：它留下一条「名字已经核对过」的记录，而核对过的名字没有人会再核对。新增的 check 23 逐棵树钉住各宿主公布的文件读取工具、终端与 `subagent_type` 取值；`.cursor` 也重读了一遍并刻意没有改动，因为 Cursor 公布的是能力而不是工具标识符。
- **[v0.1.18](https://github.com/wanghao9610/STAR/tree/v0.1.18)** (2026-08-06) — 论文的架构图现在会落进读它的那篇笔记里：`star-refs-reviewer` 的分析笔记可以在方法一节带一张图，靠图注而绝不靠编号来认定，并从论文自己的 arXiv HTML 渲染页取得。「没有」是一个成立的答案，它的两种成因用一行区分开——本就没有这类图的论文，和 arXiv 没有渲染的论文——而把结果图硬塞进这个空位会被评分表判为失败。取回来的内容原样写入 `metds/refs/figs/`，图下一行带着图号、图注首句、图片 URL 与抓取日期，所以从笔记里复制走的图仍然追得回来。
- **[v0.1.17](https://github.com/wanghao9610/STAR/tree/v0.1.17)** (2026-08-05) — 提交提议不再是一个你必须回答的问题：[§7.7](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 不再把它算作必问确认点，于是 `medium` 与 `high` 照旧问、`low` 不问直接做，而无论哪种，最后的回复都会点名做过的每一次提交。这个确认点真正守的从来不是提交本身，而是它旁边的暂存，所以 §1.4 补上了它一直需要的机制——运行开始时拍一张 `git status` 快照。四棵工具树同时新增 `star_commit_guard.sh`，拦下无差别或强制暂存、§1.3 点名的历史重写，以及任何暂存文件超过 10 MB 的提交。
- **[v0.1.16](https://github.com/wanghao9610/STAR/tree/v0.1.16)** (2026-08-05) — 参与度闸门接上了 Codex：`.codex/hooks/star_involve_gate.sh` 在 `.env` 为 `INVOLVE=low` 时，用一个 allow 回应 `PermissionRequest`——正是 CLI 即将等你回答之前触发的那个事件——放行 `apply_patch`。它不是把 Claude 那块直接搬过来：Codex 把一次编辑报成补丁信封而不是路径字段，所以路径取自信封自己的 `*** Add File:` 与 `*** Update File:` 头，且每一条都必须落在项目之内、根目录各点目录之外。四个宿主里只接上两个，是能力决定的而不是选择：Cursor 根本没有在文件编辑前触发的 hook，而 Kimi Code 的 `PreToolUse` 只写了 `deny`、没有 allow。
- **[v0.1.15](https://github.com/wanghao9610/STAR/tree/v0.1.15)** (2026-08-05) — `INVOLVE=low` 现在管得到权限确认框，而不只是 skill 主动问的那些问题：`.claude/hooks/star_involve_gate.sh` 对 `Edit`、`Write`、`NotebookEdit` 的 `PreToolUse` 回一个 allow，而项目之外的路径、以及项目根下每一个点目录仍然照常弹框，`Bash` 则根本不在匹配器里。它只挪权限确认框、别的一概不动，这正是 [§7.7](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 自己那条划分落到宿主上的样子——红线、提交提议、删除与覆盖、方案审批在 `low` 与在 `high` 完全一样地成立。同一版还给 `reference.bib` 每条记录加上 `% src:` 出处行，把论文笔记的头条数字连同数据集、指标与设定写进自足的一行，并让 §10.6 的接手规则学会混合情形。
- **[v0.1.14](https://github.com/wanghao9610/STAR/tree/v0.1.14)** (2026-08-04) — 十五个 skill 里有八个现在可以自己发起：规约 [§10](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 列出全部十五个并给七个标上 † 表示 slash-only，因为一个由 agent 自作主张走到的决定，等于没有人做过这个决定。被自行拾起并不改变运行随后的行为——红线、提交提议、删除与覆盖、每一个必问确认点，都与你亲手点名时一模一样——并有三条规则给它划出边界：目标不明就问而不猜、一次调用一个 skill、并在决策记录里留一行。光有权限什么也没动，因为每份技能文本仍然只是把命令打印给读者，所以 §10.6 补上这个缺口：一次运行以这八个之一收尾且目标已经确定时，就直接跑它，而不是把命令印出来。
- **[v0.1.13](https://github.com/wanghao9610/STAR/tree/v0.1.13)** (2026-08-04) — 每条文献记录都带上影响力分数：`star-refs-reviewer` 把年均引用、venue 分级与代码采纳按固定权重合成 0–10 的总分，数据全部来自本次运行中抓取并标注日期的指标——绝不靠印象，也绝不写进 `reference.bib` 字段。分数决定详略而不决定去留，「近比有名重要」依然负责挑核心集；新增的 `score` 模式用一次批量调用重抓整个 bib 的指标，让既有的文献库一条命令就能用上这个功能。同一版还让更新脚本永不覆盖 `AGENTS.md` 及镜像它的那条 Cursor 规则。
- **[v0.1.12](https://github.com/wanghao9610/STAR/tree/v0.1.12)** (2026-08-03) — 项目有了自己的记忆：一次会话学到的、而任何计划、日志或报告都不拥有的事实，记录在 `.star/memory/` 下，一个事实一个文件，旁边一行索引；第二个会话钩子会在每次会话开始时把这份索引摆到 agent 面前。`AGENTS.md` 新增 §10 承载全部写入规则——只记项目里没有文件已经拥有的事实、要提议而不要擅自、记忆与仓库文件冲突时以文件为准——于是「验证」挪到 §11，四棵 skill 树里所有对它的引用一并跟着挪。格式与退役规则见 [`memory_spec.md`](docs/mds/star-workflow/memory_spec.zh-CN.md)；只对某一台机器成立的事实放进 `.star/memory/local/`，像 `.env` 一样被 git 忽略。
- **[v0.1.11](https://github.com/wanghao9610/STAR/tree/v0.1.11)** (2026-08-03) — 项目指向了它写作侧的搭档 [STAGE](https://github.com/wanghao9610/STAGE)：首页副标题改为「Every STAGE needs a STAR」，结尾的行动号召新增「Pair it with STAGE」按钮，页脚新增 STAGE 链接，与 STAGE 一直保留的指向 STAR 的链接对称。两份 README 现在都以分工开篇——STAR 负责把研究跑起来，产出方法文档、结果与摘要；STAGE 以只读、带指纹的证据形式导入它们，并在其上写论文，于是稿子里的一个数字能回溯到产生它的那次运行。这种配对在两个方向上都是可选的。
- **[v0.1.10](https://github.com/wanghao9610/STAR/tree/v0.1.10)** (2026-08-02) — `star-plan-decomposer` 子计划清单确认点里的「调整粒度」有了明确行为，它是一个方向、并且优先问：*更粗*把同类别或有依赖关系的单元合并后重新展示清单，若合并会剩不到三个就询问是否就此打住而不是硬并到两个；*更细*绝不新增同级单元，而是把被点名太粗的单元带进递归步骤。更新脚本的上游变得可配置，`execs/update.sh` 依次从环境变量、`.env`、内置默认值解析 `STAR_REPOSITORY`，于是跟踪一个 fork 只需一行。更新集合还纳入了 `execs/run.sh`，而 `execs/scpts/` 下的实验脚本仍然属于项目自己、永不被触碰。
- **[v0.1.9](https://github.com/wanghao9610/STAR/tree/v0.1.9)** (2026-08-02) — 代码审查挪到了红线命令之前：`star-plan-executor` 为重型运行停下时，报告现在把 `star-code-reviewer` 写在它交回的命令上方，因为在算力开销之前抓到的缺陷只值一次审查，而同一个缺陷在之后被抓到，代价是算力加重跑。回环也一并闭合了——`CODE_REVIEW_<date>.md` 里日志没有记录为已了结的 blocker/major 问题项，会重新打开它们所落的那些步骤。`star-flow-status` 按同样的顺序推荐审查，评分表把只有那条尚未执行的命令才能产出的交付物记为 `pending` 而不是缺失。
- **[v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8)** (2026-08-01) — 每棵 skill 树都改为对照它自己宿主公布的工具清单与 `SKILL.md` 规范来核对，而不是对照另外几棵树怎么写：Cursor 树通过 `AskQuestion` 恢复了结构化提问，另外三棵树不再叫各自宿主从来没有过的工具名。Codex 根本没有读文件的工具，所以它的加载环节直说这一点、并把文件 `cat` 进 shell 调用；它的选择性委派也是可执行的——有边界的只读工作用 `spawn_agent` 配 `agent_type: explorer`，实现工作用 `worker`。四棵树的描述现在都落在规范的 1024 字符上限之内，检查项同时强制这个上限与各宿主的委派词汇。
- **[v0.1.7](https://github.com/wanghao9610/STAR/tree/v0.1.7)** (2026-08-01) — Kimi 版的 skill 树恢复了移植时被改写成散文的机制——`AskUserQuestion` 结构化提问、经 `EnterPlanMode`/`ExitPlanMode` 的计划模式审批、`Agent` 子代理派发——子代理类型映射为 Kimi 的 `explore`/`coder`，`multiSelect` 改为 Kimi 的参数名 `multi_select`。合法适配保留：`/skill:` 调用语法、`AGENTS.md` 引用、Kimi 版 model-id 措辞和 `kimi -p` 回退句。
- **[v0.1.6](https://github.com/wanghao9610/STAR/tree/v0.1.6)** (2026-07-30) — `star-flow-status` 的开场装载拆成同时发出的两条命令：大小固定的规约摘录，和随项目历史增长的采集摘要。两者原本共用一个结果大小上限，项目一旦有了历史，相加就会越限、双双被存成文件；拆开之后摘录必定完整送达，只有摘要还可能被存成文件。
- **[v0.1.5](https://github.com/wanghao9610/STAR/tree/v0.1.5)** (2026-07-30) — 又有四个 skill——`star-plan-decomposer`、`star-plan-executor`、`star-plan-reviser`、`star-metd-summarize`——改为通过共享的只读收集器读取计划树，而不再逐份打开计划；同一轮对话里的第二个 skill 可以复用它仍然看得见的那次开场加载，收集器的摘要除外。`star-plan-decomposer` 把三条分解轴改名为阶段、组件、实验，各自以该层所承载的单元命名。它只在代码能端到端跑通之后才推荐实验轴，该轴承载的是实验组，单条主张再深一位。
- **[v0.1.4](https://github.com/wanghao9610/STAR/tree/v0.1.4)** (2026-07-29) — 每个 skill 用一条消息完成开场装载，`SKILL_zh.md` 不再在运行时读取——它仍是供人阅读的完整镜像。其中两个 skill 只装载自己真正用到的规约章节。
- **[v0.1.3](https://github.com/wanghao9610/STAR/tree/v0.1.3)** (2026-07-29) — `star-refs-reviewer` 新增 `survey` 模式，把独立的领域综述写入 `metds/refs/`；追加模式新增 `add` 形式，一次可提交多篇论文。
- **[v0.1.2](https://github.com/wanghao9610/STAR/tree/v0.1.2)** (2026-07-28) — 一条措辞规则，写在 `AGENTS.md` §7 与规约 §7.11：写动作本身，不写它的名字。十五个 skill 全部按它审计过一遍。
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
