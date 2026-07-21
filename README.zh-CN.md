<div align="center">
  <img src="docs/srcs/star-project-icon.png" alt="STAR 项目图标" width="128">
  <h1>STAR</h1>
  <p><strong>系统化 AI 研究工具链</strong></p>
  <p><em>一个面向可复现、结构化 AI 研究的可复用项目基础。</em></p>
</div>

**语言：** [English](README.md) | 简体中文

STAR 为人工智能研究项目提供了一个轻量起点。它将源代码、数据集、模型权重、实验输出和方法文档分别放在约定好的目录中，并提供统一的实验入口，以及供研究者和 AI 编程助手共同遵循的项目规范。内置的研究工作流进一步串联“研究构想 → 计划 → 可执行子计划 → 实现与验证 → 状态追踪”，并将关键决策、任务依赖和验证记录沉淀到项目文件中，以便跨会话延续工作和审计研究过程。

STAR 不绑定具体框架：研究工作流只约定过程、文件位置和验证记录，你仍可自行选择模型技术栈、依赖管理工具和实验跟踪平台。

## 主要特性

- **统一的项目结构**：清晰组织代码、数据、权重、输出和研究记录。
- **可迁移的运行环境**：本机路径仅保存在本地 `.env` 文件中，不写入脚本。
- **统一的实验入口**：通过 `execs/run.sh` 查找并启动实验。
- **完整的研究生命周期**：通过十四个相互配合的 skill，引导把已经开工的项目无损接入、从模糊兴趣收敛出研究选题、计划成稿、相关工作调研（分析笔记与可核验文献库）、递归拆解、从参考实现奠基代码库、运行环境构建、叶子计划执行、对照规范与计划的代码审查、对照预期的实验结果分析、按时间轴汇总阶段进展、以执行证据修订计划、全局状态汇总，以及把成熟计划编译成方法文档。
- **可追踪、可恢复的研究过程**：将计划保存在 `metds/plans/`，将计划执行过程的中间文件保存在 `tasks/`，将生成的 run 产物保存在 `wkdrs/`，不依赖聊天记录保存上下文。
- **面向 AI 协作的规范**：为 Codex、Claude 和 Cursor 提供一致的项目约束和研究工作流，并支持中文与英文。
- **适合大文件的安全默认配置**：本地数据、模型权重、实验输出和环境配置默认不纳入版本控制。

十四个 skill 的职责、调用方式和完整示例见[研究工作流](#研究工作流)。

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
├── .cursor/rules/          # Cursor 自动加载的项目规则
├── .vscode/                # 编辑器与调试配置
├── .env.example            # 本地运行环境配置示例
├── AGENTS.md               # AI 编程助手共享的协作规范
└── README.md
```

HTML 页面放在 `docs/htmls/`，按主题组织的 Markdown 文档放在 `docs/mds/`，图片及其他静态资源放在 `docs/srcs/`；`docs/index.html` 作为文档入口。研究计划、方法说明和研究设计记录则放在 `metds/` 中。

部分目录使用了缩写：

| 目录 | 英文含义 | 存放内容 |
| --- | --- | --- |
| `datas/` | Data | 原始数据、处理后的数据或生成的数据集 |
| `inits/` | Initializations | 预训练权重、检查点和初始化文件 |
| `metds/` | Methodologies | 研究计划、设计说明和方法记录 |
| `execs/` | Executions | 启动器和实验脚本 |
| `scpts/` | Scripts | 可独立运行的实验定义 |
| `tasks/` | Tasks | 每个计划自有的工具脚本，以及执行该计划时产生的中间文件，按计划名称分目录保存 |
| `wkdrs/` | Work directories | run 日志、指标、预测结果及其他实验输出 |

例如，执行 `metds/plans/00_demo_plan.md` 时会新建 `tasks/00_demo/`，用于存放该计划自有的工具脚本（完成判据要跑的校验或索引脚本）以及执行过程的中间文件；生成的实验产物仍放在相应的 `wkdrs/<运行名称>/` 目录中。

## 快速开始

### 1. 使用 STAR 创建项目

可以将本仓库用作 GitHub 模板，也可以直接克隆或复制到新项目：

```bash
git clone https://github.com/wanghao9610/STAR
cd STAR
rm -rf .git
cd ..
mv STAR YOUR_PROJ_NAME
cd YOUR_PROJ_NAME
mv code YOUR_CODE_NAME  # 也可以将现有代码库复制或克隆到 YOUR_CODE_NAME。
git init
git add .
git commit -m "First commit."
```

如果 `YOUR_CODE_NAME/` 是从另一个 Git 仓库克隆而来，并且需要将其文件直接纳入当前项目，请在执行 `git add .` 前先运行 `rm -rf YOUR_CODE_NAME/.git` 删除内层 Git 元数据。

### 1b. 或者：接入一个已经存在的项目

如果项目已经开工——有真实代码、有能跑的环境、有几个月的提交、手里已经攥着结果——那就把骨架装进它，而不是把它搬进 STAR。在那个仓库的根目录下执行：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o /tmp/star-update.sh
bash /tmp/star-update.sh --adopt
```

已经存在的东西一律不覆盖：每个已有文件都被原样保留并列出。随后在该仓库里运行 `/star-proj-adopt`——它会勘察布局、写好 `.env`、用软链接触达你已有的数据 / 权重 / 输出目录而不搬动它们、包装你已有的启动命令，并记录下已经建成和已经跑过的东西。之后下面的第 2–4 步原样适用。

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
- `PYTHON_HOME`：运行环境的选择依据，可以是环境目录，也可以是该环境的 Python 可执行文件路径。
- `CONDA_HOME`：本机 Conda 的安装根目录；`ENV_NAME`：其中的环境名。

以 `PYTHON_HOME` 为准，因此有两种配置方式：

- **设置 `PYTHON_HOME`。** 直接按其取值使用，`CONDA_HOME` / `ENV_NAME` 可以留空。未设 `CONDA_HOME` 时不走 `conda activate`，直接调用该解释器——使用普通 `.venv` 时也是这种方式。
- **留空 `PYTHON_HOME`，同时设置 `CONDA_HOME` 与 `ENV_NAME`。** 此时 `PYTHON_HOME` 由 `$CONDA_HOME/envs/$ENV_NAME` 推导得出。

两者都不设置则报错。

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

启动器会激活配置好的 Conda 环境，并向实验脚本导出以下路径变量：

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

当前的 `00_exp.sh` 是空白占位脚本，使用 STAR 创建项目时请将其替换为第一个实际实验。实验名称和输出目录应能区分不同任务、实验或重复运行；生成的文件应放在 `wkdrs/<运行名称>/` 下。

## 研究工作流

STAR 提供十四个相互配合的技能，将模糊的研究兴趣转化为可追踪、可审计的执行流程：

<div align="center">
  <img src="docs/srcs/star-research-workflow.png" alt="STAR 研究工作流：十二个 skill 的调用顺序与两个横向通读的 skill、各自的主要产物，以及每个叶子计划上的回环" width="100%">
</div>

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `$star-proj-adopt` | 把已经开工的项目无损接入：勘察已有仓库，配好 `.env` 并用软链接触达已有的数据 / 权重 / 输出目录，包装已有启动命令，记录已经建成和已经跑过的东西；待计划树建好后，再回填那些已完成的叶子 | `metds/adopt.md`，以及获确认叶子上的 `exec_status:` / `exec_runs:` |
| `$star-idea-storm` | 把模糊兴趣收敛成站得住的研究选题：发散候选方向、摘要级扫描领域（每篇论文都转录自抓取的记录）、六维打分，最后连同首个验证实验定稿选题 | `metds/ideas/<slug>_idea.md` |
| `$star-plan-coach` | 通过分阶段提问明确研究想法 | `metds/plans/<数字>_<主题>_plan.md` |
| `$star-refs-reviewer` | 调研与方法相关的工作：精读最近邻论文写成分析笔记，并建立分好类、条条转录自抓取记录的文献库 | `metds/refs/<缩写>.md`、`metds/refs/reference.bib`、`metds/refs/refs_index.md` |
| `$star-code-architect` | 从打分参考实现奠基 `${CODE_NAME}/` 或整理已有代码，并沉淀架构规范 | `${CODE_NAME}/` 及 `UPSTREAM.md`，外加 `metds/codearc.md` |
| `$star-env-builder` | 依据 `.env` 构建 conda 环境或 venv，按 uv > pip > conda 阶梯解析并安装依赖，并做冒烟验证；`add` 把新包装进已有环境并记录 | 运行环境，以及 `wkdrs/env_<名称>_<日期>/ENV_REPORT.md` 和 `freeze.txt` |
| `$star-plan-decomposer` | 将战略研究计划拆分成可验证的子计划 | `metds/plans/<前缀>_<任务>_plan.md` |
| `$star-plan-executor` | 实现并初步验证一个可执行的叶子计划 | `tasks/<计划名称>/` 下该计划自有的工具脚本与中间工作文件、代码，以及 `wkdrs/<运行名称>/EXEC_PLAN.md`、`EXEC_LOG.md` 和生成产物；经确认的偏差同步写回计划并带 Revision History 记录 |
| `$star-code-reviewer` | 对照项目规范与计划承诺审查代码，并落笔经批准的机械修复 | `wkdrs/<运行名称>/CODE_REVIEW_<日期>.md` 或 `wkdrs/reviews/code_<范围>_<日期>.md` |
| `$star-expt-analyst` | 对照计划的预期审计一个 run 的产出：产物清点、日志健康、指标对照完成判据打分，以及结果对那条主张意味着什么 | `wkdrs/<运行名称>/EXPT_ANALYSIS_<日期>.md`，以及 `wkdrs/<运行名称>/analysis/` 下的图；`aggregate` 模式下的 `metds/results.md`（限定范围时为 `metds/results_<slug>.md`） |
| `$star-expt-digest` | 按时间轴汇总最近的实验进展：从上一份 digest 续接，或覆盖一个显式时间窗、一整个计划家族；把每个 run 的判定与头条指标从其分析报告中取出成表，推导相对上次的变化，并列出缺口 | `wkdrs/digests/EXPT_DIGEST_<日期>.md` |
| `$star-plan-reviser` | 以执行证据审查一个计划并就地修订 | `wkdrs/<运行名称>/REVIEW_<日期>.md`，以及带 Revision History 的修订后计划 |
| `$star-flow-status` | 汇总整条流程的进度——计划树，以及已完成工作里缺失或过期的审查、分析、方法文档——并指出唯一的下一步 | 只读状态摘要 |
| `$star-metd-summarize` | 把计划树编译成可直接用于论文的方法文档，标注哪些尚未验证，并把无计划覆盖之处转成 TODO | `metds/overview.md`、`dataset.md`、`framework.md`、`training.md`、`evaluation.md` |

### 模型选择建议

不同阶段对模型能力的侧重有所不同。头脑风暴并评判研究方向，编写、拆解和修订研究计划，判断相关工作如何定位本方法，解读实验结果意味着什么，以及把计划凝练成方法表述时，建议为 `$star-idea-storm`、`$star-plan-coach`、`$star-refs-reviewer`、`$star-plan-decomposer`、`$star-expt-analyst`、`$star-plan-reviser` 和 `$star-metd-summarize` 选用 Claude Fable5 Extra 或 ChatGPT5.6 Sol High；奠基代码库、构建环境、执行计划、审查代码、周期性进展汇总和全局状态汇总时，建议为 `$star-proj-adopt`、`$star-code-architect`、`$star-env-builder`、`$star-plan-executor`、`$star-code-reviewer`、`$star-expt-digest` 和 `$star-flow-status` 选用 Claude Opus4.8 Medium (Sonnet5 High)、ChatGPT5.6 Sol Medium（Terra High）或 Cursor Grok4.5 High。在条件允许的情况下，十四个工作流均使用能力最强的可用模型，通常能获得最佳的整体效果。

这些技能会将决策和进度保存在项目文件中，避免仅依赖聊天记录。研究工作流同时支持中文和英文。

具体的调用方式、完整示例、生成文件和常见问题见[研究工作流 Skills 使用指南](docs/mds/star-workflow/research-workflow-skills.zh-CN.md)；所有 skill 共享的规则——git、STOP 线、`.env` 运行时、日期、委派与对话纪律——见[研究工作流 Skill 通用规约](docs/mds/star-workflow/research-workflow-conventions.zh-CN.md)。

## 更新 STAR 的 skill 与工作流指南

基于 STAR 创建项目后，可以只同步 STAR 后续发布的 skill 与研究工作流指南，而不改动项目代码、实验配置或 Git remote：

```bash
bash execs/update.sh
```

该命令默认从 STAR 的 `main` 分支更新以下目录：

- `.agents/skills/`
- `.claude/skills/`
- `.cursor/skills/`
- `docs/mds/star-workflow/`

如需固定到某个 tag 或分支，可以将其作为参数传入：

```bash
bash execs/update.sh TAG_OR_BRANCH
```

如需只更新一个 skill，通过 `--skill` 传入其目录名：

```bash
bash execs/update.sh --skill star-plan-coach
```

该命令会更新三个工具目录中对应的 skill：

- `.agents/skills/star-plan-coach/`
- `.claude/skills/star-plan-coach/`
- `.cursor/skills/star-plan-coach/`

单 skill 模式不会更新 `docs/mds/star-workflow/` 下的工作流文档。如需从指定 tag 或分支更新某个 skill，可以组合 ref 和选项：

```bash
bash execs/update.sh TAG_OR_BRANCH --skill star-plan-coach
```

命令的通用形式为 `bash execs/update.sh [ref] [--skill NAME]`。如果 skill 名称无效，或上游三个 skill 目录中有任何一处缺少该 skill，命令会停止且不会覆盖本地文件。可运行 `bash execs/update.sh --help` 查看内置用法摘要。

上游同路径文件会直接覆盖本地版本，上游新增文件也会被加入；本次更新范围中仅存在于当前项目的自定义文件会保留。为避免误删自定义内容，上游已删除的文件不会在本地自动删除。更新不会修改其他目录、当前分支、Git remote 或暂存区。建议更新前提交当前工作，更新后使用 `git status` 和 `git diff` 检查并提交结果。

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
- 更新 `LICENCE` 中的年份和版权所有者。

只保留确实有助于研究的结构——STAR 应当服务于研究，而不是限制研究。

## 许可证

STAR 基于 [MIT 许可证](LICENCE) 发布。
