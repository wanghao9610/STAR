<div align="center">
  <img src="docs/srcs/star-project-icon.png" alt="STAR 项目图标" width="128">
  <h1>STAR</h1>
  <p><strong>Systematic Toolchain for AI Research</strong></p>
  <p><em>一个面向可复现、结构化 AI 研究的可复用项目基础。</em></p>
  <p><a href="https://wanghao9610.github.io/STAR/"><strong>文档站点</strong></a></p>
</div>

**语言：** [English](README.md) | 简体中文

STAR 为人工智能研究项目提供了一个轻量起点。它把源代码、数据集、模型权重、实验输出和方法记录分别放在约定好的目录中，并给研究者和 AI 编程助手同一个实验入口、同一份项目规范。内置的研究工作流按“研究构想 → 计划 → 可执行子计划 → 实现与验证 → 状态追踪”依次推进，过程中把关键决策、任务依赖和验证记录写进项目文件，因此工作能跨会话接着做，过程也可事后追溯。

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
- [分工具配置（可选）](#分工具配置可选)
  - [会话钩子](#会话钩子)
  - [为状态收集脚本预先授权](#为状态收集脚本预先授权)
- [研究工作流](#研究工作流)
  - [模型选择建议](#模型选择建议)
- [项目记忆](#项目记忆)
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
- **归项目所有的记忆**：一次会话学到、又没有任何计划或报告认领的事实——环境怪癖、长期偏好、走不通的路——记在 `.star/memory/` 里，并由钩子送到下一次会话面前，无论你用哪个工具驱动 STAR。
- **面向 AI 协作的规范**：为 Codex、Claude、Kimi Code、Cursor 和 Qwen Code 提供一致的项目约束和研究工作流，并支持中文与英文。
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
├── .qwen/skills/           # Qwen Code 使用的研究工作流技能
├── .claude/hooks/          # Claude 的钩子：model-id 溯源、项目记忆、INVOLVE=low 放行编辑
├── .codex/hooks/           # Codex 的钩子：model-id 溯源、项目记忆、INVOLVE=low 放行编辑
├── .cursor/hooks/          # Cursor 的会话钩子
├── .kimi-code/hooks/       # Kimi Code 的会话钩子（见分工具配置）
├── .qwen/hooks/            # Qwen Code 的钩子：model-id 溯源、项目记忆、INVOLVE=low 放行编辑
├── .star/memory/           # 项目记忆：先前会话学到的事实（local/ 不入库）
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

`.github/` 里是 STAR 用来保持五套 skill 镜像同步的一致性检查，服务于 STAR 自身的维护，而非你的项目：若保留下来，它会在你每次推送到 `main` 时运行，并在你第一次修改 `AGENTS.md` 或删掉用不到的某套工具目录时失败。步骤 1b 的接入方式不会安装它。

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

此外可以加上 `INVOLVE=low|medium|high`，设定 STAR skills 在决策前询问的程度：`low` 在需要判断的地方直接采用推荐项，并把这次取值记录下来，在 Claude Code 和 Codex 里还会跳过每次文件编辑前的权限弹窗；`medium`（默认）按文档提问；`high` 每一步都先确认。红线、提交、删除这类安全确认点在任何档位都会询问。若只想对单次运行生效，调用 skill 时附带同一参数即可，如 `$star-plan-executor 00 involve=low`。完整规则见[研究工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md#7-对话纪律) §7.7。

另一个可选键 `STAR_LANG=en|zh` 给两件事固定同一种语言：agents 的对话回复，以及新生成的工作流文档（计划、报告）。未设时二者都跟随对话语言。无论设与未设，对话中明确提出时都以对话要求为准；已有文档则保持其 frontmatter 声明的语言不变。完整规则见[研究工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md#7-对话纪律) §7.6。

还有一个键 `STAR_REPOSITORY`，指定 `execs/update.sh` 从哪个仓库拉取后续的 skill 与工作流文档版本。它出厂就指向 STAR 本身，只有改从 fork 更新时才需要改动。详见[更新 STAR 的 skill 与工作流指南](#更新-star-的-skill-与工作流指南)。

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

### 会话钩子

会话开始时有两个钩子：一个记录各 skill 写进每份产物的模型 id，另一个把[项目记忆](#项目记忆)的索引送到 agent 面前。Claude、Codex 和 Qwen Code 还各带第三个钩子，它不是会话钩子：`.env` 写着 `INVOLVE=low` 时，它替你回答文件编辑前的权限弹窗，其他档位什么都不做。它和前两个一样随仓库注册好，分别在 `.claude/settings.json`、`.codex/hooks.json` 和 `.qwen/settings.json` 里。Cursor 和 Kimi Code 没有这个钩子：Cursor 没有任何在文件编辑之前触发的钩子，而 Kimi 的 `PermissionRequest` 只能旁观它旁边那个弹窗。五家还各带一个钩子，同样不是会话钩子，且任何档位都在跑：`star_commit_guard.sh` 会拒掉[工作流规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) §1 明令禁止的 git 命令——整批或强制 stage、历史改写、以及暂存文件超过 10 MB 的提交。Claude、Codex、Kimi Code 与 Qwen Code 把它挂在 `PreToolUse` 上，Cursor 挂在 `beforeShellExecution` 上——那是 Cursor 里裁决一条 shell 命令的地方。matcher 用的是各家自己的工具名：前三家是 `Bash`，Qwen Code 是 `run_shell_command`——它的 matcher 读的是工具标识符，不是界面上显示的名字。它是 `INVOLVE=low` 自行回答提交提议之后垫在底下的那层地板：被它拒掉的命令，归你自己运行。

如果你用 **Kimi Code** 驱动 STAR，每台机器运行一次下面的命令，把两个钩子都注册上，各 skill 也才能记录真实的 `model_id` 而不是 `unrecorded`：

```bash
bash .kimi-code/hooks/install.sh
```

它会把两个钩子注册到你的全局 `~/.kimi-code/config.toml`，注册前先备份该文件；重复运行不会有额外影响，运行一次即覆盖所有 STAR 项目，而在记忆钩子出现之前就配好的机器，这次只补上缺的那一个。Codex、Claude、Cursor 和 Qwen Code 的两个钩子都随仓库一起注册好，用这四个 agent 可跳过本步。但在 Codex 上，注册好不等于会跑：项目级钩子要等项目被信任、钩子被批准之后才触发。请在 Codex CLI 里跑一次 `/hooks` 批准它们，之后每次钩子有改动都要重新批准。在那之前，每份报告里的 `model_id` 都是 `unrecorded`，记忆也一条都到不了会话，而且没有任何地方会提示你。在 Qwen Code 上，同样的坑只在你打开了目录信任（`security.folderTrust.enabled`，默认关闭）时才成立：未被信任的项目不会跑任何项目级钩子，同样没有任何地方提示你。另外 Qwen Code 优先读 `QWEN.md` 而不是 `AGENTS.md`，所以你的项目里若已有 `QWEN.md`，STAR 写在 `AGENTS.md` 里的规范就不会被装载——在 `QWEN.md` 里用 `@AGENTS.md` 引入它，或者把那个文件删掉。在某个钩子出现之前就接入的项目，保留的是它自己的注册文件——`execs/update.sh` 从不覆盖它，只会把缺的那个钩子点名报出来。手动方式与细节见 [`.kimi-code/hooks.example.toml`](.kimi-code/hooks.example.toml)。

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
| Qwen Code | `.qwen/settings.json` 里的 `permissions.allow`，随仓库带好了扫描命令 |

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
| Qwen Code | `/star-<name>` | `/star-plan-coach 开放词汇检测` |

七个 skill 是 slash-only——`star-proj-adopt`、`star-idea-storm`、`star-plan-coach`、`star-code-architect`、`star-plan-decomposer`、`star-plan-reviser`、`star-code-release`：只有被点名时才跑，因为每一个都坐在一个属于你的决定上。另外八个，任务明显匹配、目标又没有歧义时 agent 也可以自行启动；任何 skill 显式点名都始终有效。

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

## 项目记忆

一次会话学到、又没有任何计划、日志或报告认领的事实——某个 build 必须先 load 一个 module 才过、你的某项长期偏好、一个不值得再跑的实验——记在项目里的 `.star/memory/`，而不是你当时恰好在用的那个工具里。一事一文件，每条在 `.star/memory/MEMORY.md` 里占一行；会话钩子在每次会话开始时把这份索引送到 agent 面前，五个工具都是如此。

两条规则让它不会变成与真相竞争的第二个源头：

- **只有当项目里没有任何文件已经认领这条事实时，它才被记进去。** 结果属于那次运行的 `EXEC_LOG.md`，关于研究的决定属于它的计划，论文属于 `metds/refs/`。记忆装的是残余。
- **记忆与仓库里的文件冲突时，以文件为准**，随后把这条记忆改正或删掉。

只在这台机器上成立的事实放 `.star/memory/local/`，git 像忽略 `.env` 一样忽略它。任何东西都不会不打招呼就记下来：agent 提议，你来定——`.env` 里设 `INVOLVE=low` 则改为先记下再告诉你。四类记忆、文件格式，以及一条记忆怎么退场，见[项目记忆](docs/mds/star-workflow/memory_spec.zh-CN.md)。

## 更新 STAR 的 skill 与工作流指南

基于 STAR 创建项目后，可以只同步 STAR 后续发布的 skill 与研究工作流指南，而不改动项目代码、实验配置或 Git remote：

```bash
bash execs/update.sh
```

该命令默认从 STAR 的 `main` 分支更新以下路径：

- `.cursor/rules/skill-roots.mdc`——各个 skill 根目录归哪个工具所有，以及 Cursor 该跟随哪一份副本
- `.agents/skills/`、`.claude/skills/`、`.cursor/skills/`、`.kimi-code/skills/`、`.qwen/skills/`
- `.claude/hooks/`、`.codex/hooks/`、`.cursor/hooks/`、`.kimi-code/hooks/`、`.qwen/hooks/` 以及 `.kimi-code/hooks.example.toml`——model-id 溯源、项目记忆、INVOLVE=low 放行编辑三个钩子
- `docs/mds/star-workflow/` 与 `docs/srcs/`——工作流文档，以及 STAR 自有页面使用的图标和流程图
- `execs/run.sh`——出厂的实验启动脚本；你对它的改动会被替换，而它所启动的实验脚本（`execs/scpts/` 下）属于项目自己，绝不会被动到

agent 协作规范归项目自己所有：`AGENTS.md` 与抄录其正文的 `.cursor/rules/agent-instructions.mdc` 不在上面这份清单里。它们遵循与下文钩子注册配置相同的规则——仅在缺失时安装，除非加 `--force`，否则绝不覆盖。已经写了自己那一份的项目会原样保留；一份都没有的项目则从上游取得。

拉取来源由 `STAR_REPOSITORY` 指定，取值顺序为：环境变量、`.env`、内置默认值 `https://github.com/wanghao9610/STAR.git`。想长期跟随某个 fork，就写进 `.env`；只想临时改一次，在命令前加变量即可——`STAR_REPOSITORY=… bash execs/update.sh`。

钩子注册配置——`.claude/settings.json`、`.codex/hooks.json` 与 `.cursor/hooks.json`——仅在缺失时安装，除非加 `--force`，否则绝不覆盖。若保留下来的配置没有注册 STAR 钩子，命令会打印提示。如果项目是在钩子纳入更新范围之前基于 STAR 创建的，请先手动刷新一次更新脚本本身——`execs/update.sh` 不会覆盖自己：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o execs/update.sh
```

命令的通用形式为 `bash execs/update.sh [--diff] [ref] [--skill NAME] [--force]`：

- `--diff` 在不改动任何文件的情况下预览更新，有可更新内容时以 `2` 退出，完全一致时以 `0` 退出，出错时以 `1` 退出——脚本因此能区分“有更新”与“检查本身失败”。
- `ref` 把更新固定到某个 tag 或分支。
- `--skill NAME` 只更新五个工具目录中的这一个 skill，不动工作流文档和溯源钩子。名称无效、或上游五个 skill 目录中有任何一处缺少它，命令会停止且不覆盖任何文件。
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
- 删掉用不到的工具目录。`.agents/`（Codex）、`.claude/`、`.cursor/`、`.kimi-code/`、`.qwen/` 各自是同一套十五个 skill 的完整副本，每套约 150 个文件；留下你所用 agent 会读的那一套，其余 `rm -rf` 即可。

只保留确实有助于研究的结构——STAR 应当服务于研究，而不是限制研究。骨架本身可独立使用：目录布局、`.env` 和 `execs/run.sh` 在完全不装任何 skill 的情况下也能工作，因此删掉全部工具目录同样是受支持的用法。

## 更新日志

按版本列出要点，最新在前。每个版本对应一个 git tag，因此 `bash execs/update.sh v0.1.0` 可将更新固定到该版本。

- **[v0.1.33](https://github.com/wanghao9610/STAR/tree/v0.1.33)** (2026-08-11) — 一份计划现在可以被放弃而不必删除：`star-plan-reviser <计划> drop` 在该节点上写入 `dropped: <日期> — <原因>`——这个模式跳过审查，因为丢弃记录的是已经做出的决定——所有 skill 都按整棵子树继承来读这个字段，于是一行就把这个节点连同它的后代移出计数、覆盖检查与下一步动作。`star-flow-status` 把它们渲染成 `⊗`、括号里保留丢弃前的状态并排除在三个数之外，`star-plan-executor` 与 `star-plan-decomposer` 拒绝对它们动手，`star-metd-summarize` 也不从它们编译任何内容——而父计划保留 `children:` 条目与索引行，行上标 `— dropped <日期>`，所以「这条路试过」仍然读得到。丢弃不隐藏的是磁盘上还在的东西：仍依赖着被丢弃节点的活叶子、未合并的执行分支、它下面的 worktree，各自照旧得到一条失配标记。
- **[v0.1.32](https://github.com/wanghao9610/STAR/tree/v0.1.32)** (2026-08-11) — `star-flow-status` 现在把范围内的每个节点都单独打一行，那条约 500 词的回复预算——正是它逼着大树被折成"8 个叶子全部完成"这类句子——也取消了：报告该多长由它要展示的树决定，其余部分改由形状约束——每节点一行、每个计数一句、每条触发的检查一行。`PLAN_NAME` 参数从此收敛的不只是检查，还有渲染：Step 2 就把树剪到解析出的子树，三个计数也只在它上面算。它的 spec 新增收敛范围一节，写明一个从不提问的 skill 碰上歧义名该怎么收场：数字前缀精确匹配足以分开两棵同 slug 的根，命中多份就每份都渲染，一份没命中就列出候选并停下。
- **[v0.1.31](https://github.com/wanghao9610/STAR/tree/v0.1.31)** (2026-08-11) — 七个 skill 派出的只读收集器——`star-code-reviewer`、`star-expt-analyst`、`star-plan-reviser`、`star-proj-adopt`、`star-code-architect`、`star-idea-storm`，以及 executor 的只读勘察步骤——在 `.claude/` 这一棵树里写明 `model: sonnet`，也只有它的 harness 认这个参数：它们都是照写死的返回格式抄录、不下任何判断，而它引用的每一行，在进报告或进确认点之前主 agent 都要重开确认。判断或写作本身就是产出的那些委派仍用会话模型：executor 的步骤 agent、architect 的迁移执行者、`star-refs-reviewer` 的单篇笔记、`star-plan-coach` 的定稿盲读。`star-code-reviewer` 另外不再在任何规模下由主 agent 自己收集问题项——一直在讨论这份代码的上下文不是它的中立读者——改为按规模分派：约 50 个文件以内一个收集器，超过则每片 10–15 个文件。
<details>
<summary>更早的版本</summary>

- **[v0.1.30](https://github.com/wanghao9610/STAR/tree/v0.1.30)** (2026-08-10) — 先摆内容再提问的七个 skill——`star-plan-coach`、`star-idea-storm`、`star-plan-executor`、`star-code-release`、`star-metd-summarize`、`star-refs-reviewer`、`star-proj-adopt`——现在把这条要求同时写在"发问"那一端，而不只写在"写内容"那一端；后者正是 v0.1.29 在 `star-plan-decomposer` 身上认定为不够用的写法。每个 skill 的对话纪律多一行，点名它自己的那份内容——一批评分表不达标项、一张候选表、一批待同步修正——并带上随之而来的回看：选项上面空无一物，说明内容是被跳过了、不是被压缩了。这条规则没有写进规约 [§7.3](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)（十五个 skill 本可一并继承），因为 `star-refs-reviewer` 对该文档的按节载入距 28400 字节的预算只剩 49 字节余量。
- **[v0.1.29](https://github.com/wanghao9610/STAR/tree/v0.1.29)** (2026-08-10) — `star-plan-decomposer` 的子计划清单确认重新走提问工具，三个答案又能点选而不必手打，卡片写在同一条消息的正文里、排在这次调用之前。v0.1.28 把这次确认整段改成纯文本，依据是客户端可能吞掉同一轮里工具调用之前的文字；此后一次运行显示选轴那题上面的文字渲染正常，剩下的只有起草时跳过卡片一种，于是防跳过的那句话从"写内容"处挪到"发问"处。对话纪律随之改口：装不进选项的内容——某份子计划草稿、回写父计划的索引草稿、评分表不达标项——排在调用之前，而不是取代它。
- **[v0.1.28](https://github.com/wanghao9610/STAR/tree/v0.1.28)** (2026-08-10) — 确认型问题不再代替它所问的内容：`star-plan-coach` 与 `star-idea-storm` 的评分表不达标项、`star-plan-executor` 的待同步修正、`star-code-release` 与 `star-metd-summarize` 的分节变更清单，现在都在提问之前逐条落到正文。内容本来就装不进选项的地方——`star-refs-reviewer` 的约 15 篇排序候选、`star-proj-adopt` 无上界的 run 与叶子清单——改为给行编号、推荐标在表里、对着编号提问，因为规约 [§7.3](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 把一题的选项封在 4 个。`star-plan-decomposer` 的子计划清单与针对它的问题现在作为同一条消息发出，中间不隔工具调用——卡片写好后在同一轮里用提问工具确认，已经出现过用户只看到三个选项、上面什么都没有的情况。
- **[v0.1.27](https://github.com/wanghao9610/STAR/tree/v0.1.27)** (2026-08-10) — `star-plan-decomposer` 的子计划清单改为每个单元一张卡片——目标、步骤、产出物、完成判据——在请你确认之前就摆出来；此前展示的是一排标题，内容要等下一步才出现。卡片是草图不是草稿：六节仍由 Step 4 写，它展开拿到的那张卡片，起草若逼得卡片上某一条必须改，会明说。参与度档位不动：`low` 不问即采纳清单，卡片照样完整展示；`high` 另外在每份子计划写入前确认草稿。
- **[v0.1.26](https://github.com/wanghao9610/STAR/tree/v0.1.26)** (2026-08-09) — `star-refs-reviewer` 的精读笔记从至多一张架构图放宽到至多三张，选哪几张由论文本身的性质决定：整体展示方法的那张仍然优先占位，数据集论文的构造流水线、分析类论文主张所压的那张图、指标报不出来的定性对比，只在笔记正文带不动它时才留。每张留下的图都要配 2–4 句，说明它画了什么、该怎么读，只依据图注全文和正文里按编号引用它的句子写——这样写不出来的图就不留，两处都没说的细节标 `[unverified]`。笔记收集器为此在每条图注旁多返回 `referenced_at`，图注也不再截到 200 字符。
- **[v0.1.25](https://github.com/wanghao9610/STAR/tree/v0.1.25)** (2026-08-08) — 第五棵 skill 树 `.qwen/` 把十五个 skill 带到 Qwen Code：调用写法与 Claude、Cursor 相同（`/star-*`），四个钩子全部注册在项目自己的 `.qwen/settings.json` 里——参与度闸门也在其中，这是它第三次落地，因为 Qwen Code 的 `PreToolUse` 能回 `permissionDecision: "allow"`。移植写的是 Qwen Code 的工具标识符（`run_shell_command`、`read_file`），而不是它同时公布的界面展示名——它自带的 skill 从不写展示名——check 23 现在逐棵树钉住这个选择。`allowed-tools` 是有意不带的：Qwen Code 的 `allowedTools` 给的是本次会话内的免确认放行而不是收紧权限，照搬过去只会放宽 skill 能做的事，而不是限制它。
- **[v0.1.24](https://github.com/wanghao9610/STAR/tree/v0.1.24)** (2026-08-08) — run 可以住进 executor 自己创建的 `git worktree` 了：分支照旧隔离历史，树回答的是另一个正交的问题——checkout 正忙（HEAD 停在别的 run 的分支上、工作区有归属别人的未提交路径、交回用户的命令还没回收结果）——与分支在同一个审批确认点上定夺，进树的 run 一律带分支（规约 [§11.7–9](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)）。树建在 `../<根目录名>--wt/<run>`，链入 `.env`、`datas/`、`inits/`，路径以 `worktree:` 记进运行记录；合并在主 checkout 里 squash、什么都不用切，移除前先把非 md 产物挪出来——绝不带 `--force`，`star_commit_guard.sh` 现在直接拦下它。`star-flow-status` 在执行分支旁边列出 worktree，并标记被遗留的树。
- **[v0.1.23](https://github.com/wanghao9610/STAR/tree/v0.1.23)** (2026-08-08) — `star-code-reviewer` 不再让写代码的那段对话自己收集问题项：本会话此前写出或改过范围内文件时，小范围收集也交给一个带全部文件清单、上下文全新的只读收集器，并在报告范围行记下这次委派。作者重读自己的代码，读到的是当初产生它的那套推理；较大范围本就经收集器收集，这次补上的是小范围（≤ 约 20 个文件，diff 审查的常态）这个缺口。
- **[v0.1.22](https://github.com/wanghao9610/STAR/tree/v0.1.22)** (2026-08-08) — 执行分支改用 run 自己的名字 `<run>`，分支与 `wkdrs/<run>/` 直接同名、不必再剥前缀，各 skill 开场读取的那份分支清单也随之改成按 run 命名规则匹配的通配。另一条线上，`star-flow-status` 与 `star-expt-digest`——仓库里仅有的两个 `context: fork` skill——改从调用方式那一行的 `$ARGUMENTS` 占位符读参数：fork 看不到用户消息，harness 只能把参数追加在整份清单之后，`/star-flow-status 030` 因此稳定漏读、报出整棵树而非该计划的子树。不带参数时占位符在三条调用路径下都替换为空，不留字面量。
- **[v0.1.21](https://github.com/wanghao9610/STAR/tree/v0.1.21)** (2026-08-07) — 委派不再是例外：[§6](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 把这个决定交给主 agent，取消「同时最多三个」的死上限，也不再把会改文件的委派限定给 `star-plan-executor` 与 `star-code-architect`，`star-flow-status` 则去掉了全套 skill 里唯一一条禁止派 subagent 的硬规定。保留下来的都是本来就与谨慎无关的东西——并发委派之间文件归属互不重叠、主 agent 亲自重跑每个检查并独占判断、只读委派什么都不写，以及抓取型 fan-out 真正的边界所在：按 host 的请求预算。另一条线上，Claude 清单新增 `argument-hint` 与只覆盖当前轮次的 `allowed-tools`，并在 skill 新建文件而非编辑文件的路径上于 `Edit` 之外补上 `Write`；`allowed-tools` 是免确认授权，从不构成限制。
- **[v0.1.20](https://github.com/wanghao9610/STAR/tree/v0.1.20)** (2026-08-06) — 要修改既有代码的叶子可以在自己的分支上执行，改动挣到合并资格之前基础分支始终是准据：规约 [§11](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 让方案审批确认点推荐在 `exec/<run>` 上执行，选了分支就同时选了逐步 checkpoint 提交，因为只有提交才会被合并。合并之前 run 写下的一切只存在于分支上，从基础分支看这个叶子就是还没做完，于是下游叶子自动保持受阻、一行新检查都不用写；合并是必问确认点、默认 squash，弃用时先把运行记录提交到基础分支，好让死路也留下证据。executor 周边：`star-code-reviewer` 按 `<base>...HEAD` 的 diff 审分支上的 run，`star-expt-digest` 把未合并分支列进缺口，`star_commit_guard.sh` 新增判定臂，拦下一键就能踩破这一切的写法。
- **[v0.1.19](https://github.com/wanghao9610/STAR/tree/v0.1.19)** (2026-08-06) — Kimi 树不再叫两个 Kimi Code CLI 根本没有的工具名：三十份清单把文件读取叫 `ReadFile`、把终端叫 `Shell`，而该 harness 公布的是 `Read` 与 `Bash`——和 Claude 用的是同两个词——所以改动的四十六行里有四十五行与 Claude 对应行逐字节相同。这次撤销的重命名来自 [v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8)，那一版把 `.kimi-code` 按怀疑而不是按 Kimi 公布的清单一并扫了进去，这是同一个缺陷里更贵的那个方向：它留下一条「名字已经核对过」的记录，而核对过的名字没有人会再核对。新增的 check 23 逐棵树钉住各 harness 公布的文件读取工具、终端与 `subagent_type` 取值；`.cursor` 也重读了一遍并刻意没有改动，因为 Cursor 公布的是能力而不是工具标识符。
- **[v0.1.18](https://github.com/wanghao9610/STAR/tree/v0.1.18)** (2026-08-06) — 论文的架构图现在会落进读它的那篇笔记里：`star-refs-reviewer` 的分析笔记可以在方法一节带一张图，靠图注而绝不靠编号来认定，并从论文自己的 arXiv HTML 渲染页取得。「没有」是一等答案，它的两种成因用一行区分开——本就没有这类图的论文，和 arXiv 没有渲染的论文——而把结果图硬塞进这个空位会被评分表判为失败。取回来的内容原样写入 `metds/refs/figs/`，图下一行带着图号、图注首句、图片 URL 与抓取日期，所以从笔记里复制走的图仍然追得回来。
- **[v0.1.17](https://github.com/wanghao9610/STAR/tree/v0.1.17)** (2026-08-05) — 提交提议不再是一个你必须回答的问题：[§7.7](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 不再把它算作必问确认点，于是 `medium` 与 `high` 照旧问、`low` 不问直接做，而无论哪种，最后的回复都会点名做过的每一次提交。这个确认点真正守的从来不是提交本身，而是它旁边的暂存，所以 §1.4 补上了它一直需要的机制——运行开始时拍一张 `git status` 快照。四棵工具树同时新增 `star_commit_guard.sh`，拦下无差别或强制暂存、§1.3 点名的历史重写，以及任何暂存文件超过 10 MB 的提交。
- **[v0.1.16](https://github.com/wanghao9610/STAR/tree/v0.1.16)** (2026-08-05) — 参与度闸门接上了 Codex：`.codex/hooks/star_involve_gate.sh` 在 `.env` 为 `INVOLVE=low` 时，用一个 allow 回应 `PermissionRequest`——正是 CLI 即将等你回答之前触发的那个事件——放行 `apply_patch`。它不是把 Claude 那块直接搬过来：Codex 把一次编辑报成补丁信封而不是路径字段，所以路径取自信封自己的 `*** Add File:` 与 `*** Update File:` 头，且每一条都必须落在项目之内、根目录各点目录之外。四个 harness 里只接上两个，是能力决定的而不是选择：Cursor 根本没有在文件编辑前触发的 hook，而 Kimi Code 的 `PreToolUse` 只写了 `deny`、没有 allow。
- **[v0.1.15](https://github.com/wanghao9610/STAR/tree/v0.1.15)** (2026-08-05) — `INVOLVE=low` 现在管得到权限确认框，而不只是 skill 主动问的那些问题：`.claude/hooks/star_involve_gate.sh` 对 `Edit`、`Write`、`NotebookEdit` 的 `PreToolUse` 回一个 allow，而项目之外的路径、以及项目根下每一个点目录仍然照常弹框，`Bash` 则根本不在匹配器里。它只挪权限确认框、别的一概不动，这正是 [§7.7](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 自己那条划分落到 harness 上的样子——红线、提交提议、删除与覆盖、方案审批在 `low` 与在 `high` 完全一样地成立。同一版还给 `reference.bib` 每条记录加上 `% src:` 出处行，把论文笔记的头条数字连同数据集、指标与设定写进自足的一行，并让 §10.6 的接手规则学会混合情形。
- **[v0.1.14](https://github.com/wanghao9610/STAR/tree/v0.1.14)** (2026-08-04) — 十五个 skill 里有八个现在可以自己发起：规约 [§10](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md) 列出全部十五个并给七个标上 † 表示 slash-only，因为一个由 agent 自作主张走到的决定，等于没有人做过这个决定。被自行拾起并不改变运行随后的行为——红线、提交提议、删除与覆盖、每一个必问确认点，都与你亲手点名时一模一样——并有三条规则给它划出边界：目标不明就问而不猜、一次调用一个 skill、并在决策记录里留一行。光有权限什么也没动，因为每份契约仍然只是把命令打印给读者，所以 §10.6 补上这个缺口：一次运行以这八个之一收尾且目标已经确定时，就直接跑它，而不是把命令印出来。
- **[v0.1.13](https://github.com/wanghao9610/STAR/tree/v0.1.13)** (2026-08-04) — 每条文献记录都带上影响力分数：`star-refs-reviewer` 把年均引用、venue 分级与代码采纳按固定权重合成 0–10 的总分，数据全部来自本次运行中抓取并标注日期的指标——绝不靠印象，也绝不写进 `reference.bib` 字段。分数决定详略而不决定去留，「近比有名重要」依然负责挑核心集；新增的 `score` 模式用一次批量调用重抓整个 bib 的指标，让既有的文献库一条命令就能用上这个功能。同一版还让更新脚本永不覆盖 `AGENTS.md` 及镜像它的那条 Cursor 规则。
- **[v0.1.12](https://github.com/wanghao9610/STAR/tree/v0.1.12)** (2026-08-03) — 项目有了自己的记忆：一次会话学到的、而任何计划、日志或报告都不拥有的事实，记录在 `.star/memory/` 下，一个事实一个文件，旁边一行索引；第二个会话钩子会在每次会话开始时把这份索引摆到 agent 面前。`AGENTS.md` 新增 §10 承载全部写入规则——只记项目里没有文件已经拥有的事实、要提议而不要擅自、记忆与仓库文件冲突时以文件为准——于是「验证」挪到 §11，四棵 skill 树里所有对它的引用一并跟着挪。格式与退役规则见 [`memory_spec.md`](docs/mds/star-workflow/memory_spec.zh-CN.md)；只对某一台机器成立的事实放进 `.star/memory/local/`，像 `.env` 一样被 git 忽略。
- **[v0.1.11](https://github.com/wanghao9610/STAR/tree/v0.1.11)** (2026-08-03) — 项目指向了它写作侧的搭档 [STAGE](https://github.com/wanghao9610/STAGE)：首页副标题改为「Every STAGE needs a STAR」，结尾的行动号召新增「Pair it with STAGE」按钮，页脚新增 STAGE 链接，与 STAGE 一直保留的指向 STAR 的链接对称。两份 README 现在都以分工开篇——STAR 负责把研究跑起来，产出方法文档、结果与摘要；STAGE 以只读、带指纹的证据形式导入它们，并在其上写论文，于是稿子里的一个数字能回溯到产生它的那次运行。这种配对在两个方向上都是可选的。
- **[v0.1.10](https://github.com/wanghao9610/STAR/tree/v0.1.10)** (2026-08-02) — `star-plan-decomposer` 子计划清单确认点里的「调整粒度」有了明确行为，它是一个方向、并且优先问：*更粗*把同类别或有依赖关系的单元合并后重新展示清单，若合并会剩不到三个就询问是否就此打住而不是硬并到两个；*更细*绝不新增同级单元，而是把被点名太粗的单元带进递归步骤。更新脚本的上游变得可配置，`execs/update.sh` 依次从环境变量、`.env`、内置默认值解析 `STAR_REPOSITORY`，于是跟踪一个 fork 只需一行。更新集合还纳入了 `execs/run.sh`，而 `execs/scpts/` 下的实验脚本仍然属于项目自己、永不被触碰。
- **[v0.1.9](https://github.com/wanghao9610/STAR/tree/v0.1.9)** (2026-08-02) — 代码审查挪到了红线命令之前：`star-plan-executor` 为重型运行停下时，报告现在把 `star-code-reviewer` 写在它交回的命令上方，因为在算力开销之前抓到的缺陷只值一次审查，而同一个缺陷在之后被抓到，代价是算力加重跑。回环也一并闭合了——`CODE_REVIEW_<date>.md` 里日志没有记录为已了结的 blocker/major 问题项，会重新打开它们所落的那些步骤。`star-flow-status` 按同样的顺序推荐审查，评分表把只有那条尚未执行的命令才能产出的交付物记为 `pending` 而不是缺失。
- **[v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8)** (2026-08-01) — 每棵 skill 树都改为对照它自己 harness 公布的工具清单与 `SKILL.md` 规范来核对，而不是对照另外几棵树怎么写：Cursor 树通过 `AskQuestion` 恢复了结构化提问，另外三棵树不再叫各自 harness 从来没有过的工具名。Codex 根本没有读文件的工具，所以它的加载环节直说这一点、并把文件 `cat` 进 shell 调用；它的选择性委派也是可执行的——有边界的只读工作用 `spawn_agent` 配 `agent_type: explorer`，实现工作用 `worker`。四棵树的描述现在都落在规范的 1024 字符上限之内，检查项同时强制这个上限与各 harness 的委派词汇。
- **[v0.1.7](https://github.com/wanghao9610/STAR/tree/v0.1.7)** (2026-08-01) — Kimi 版的 skill 树恢复了移植时被改写成散文的机制——`AskUserQuestion` 结构化提问、经 `EnterPlanMode`/`ExitPlanMode` 的计划模式审批、`Agent` 子代理派发——子代理类型映射为 Kimi 的 `explore`/`coder`，`multiSelect` 改为 Kimi 的参数名 `multi_select`。合法适配保留：`/skill:` 调用语法、`AGENTS.md` 引用、Kimi 版 model-id 措辞和 `kimi -p` 回退句。
- **[v0.1.6](https://github.com/wanghao9610/STAR/tree/v0.1.6)** (2026-07-30) — `star-flow-status` 的开场装载拆成同时发出的两条命令：大小固定的规约摘录，和随项目历史增长的采集摘要。两者原本共用一个结果大小上限，项目一旦有了历史，相加就会越限、双双落盘；拆开之后摘录必定完整送达，只有摘要还可能落盘。
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
