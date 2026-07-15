# STAR — AI 研究项目启动模板（开发中）

> 一个面向可复现、结构化 AI 研究的通用项目模板。

**语言：** [English](README.md) | 简体中文

STAR 为人工智能研究项目提供了一个轻量起点。它将源代码、数据集、模型权重、实验输出和方法文档分别放在约定好的目录中，并提供统一的实验入口，以及供研究者和 AI 编程助手共同遵循的项目规范。

本模板不绑定具体框架：你可以自行选择模型技术栈、依赖管理工具和实验跟踪平台。

## 主要特性

- **统一的项目结构**：清晰组织代码、数据、权重、输出和研究记录。
- **可迁移的运行环境**：本机路径仅保存在本地 `.env` 文件中，不写入脚本。
- **统一的实验入口**：通过 `execs/run.sh` 查找并启动实验。
- **面向 AI 协作的规范**：为 Codex、Claude Code 和 Cursor 提供一致的项目约束。
- **从计划到执行的研究工作流**：支持编写、拆解、执行和跟踪研究计划。
- **适合大文件的安全默认配置**：本地数据、模型权重、实验输出和环境配置默认不纳入版本控制。

## 项目结构

```text
star-ai-research/
├── code/                   # 项目核心代码（目录名由 CODE_NAME 配置）
├── docs/                   # 项目文档
├── datas/                  # 数据集及相关文件
├── inits/                  # 模型权重、检查点和初始化文件
├── wkdrs/                  # 实验输出及每次运行产生的文件
├── metds/
│   └── plans/              # 研究计划及可执行子计划
├── execs/
│   ├── run.sh              # 实验统一入口
│   └── scpts/              # 各实验对应的 Shell 脚本
├── .agents/skills/         # Codex 使用的研究工作流技能
├── .claude/skills/         # Claude Code 使用的研究工作流技能
├── .cursor/rules/          # Cursor 自动加载的项目规则
├── .vscode/                # 编辑器与调试配置
├── .env.example            # 本地运行环境配置模板
├── AGENTS.md               # AI 编程助手共享的协作规范
└── README.md
```

将安装指南、使用说明和设计参考等面向项目使用者的文档放在 `docs/` 中；研究计划、方法说明和研究设计记录则放在 `metds/` 中。

部分目录使用了缩写：

| 目录 | 英文含义 | 存放内容 |
| --- | --- | --- |
| `datas/` | Data | 原始数据、处理后的数据或生成的数据集 |
| `inits/` | Initializations | 预训练权重、检查点和初始化文件 |
| `metds/` | Methodologies | 研究计划、设计说明和方法记录 |
| `execs/` | Executions | 启动器和实验脚本 |
| `scpts/` | Scripts | 可独立运行的实验定义 |
| `wkdrs/` | Work directories | 日志、指标、预测结果及其他实验输出 |

## 快速开始

### 1. 基于模板创建项目

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

### 2. 配置本地运行环境

复制环境配置模板：

```bash
cp .env.example .env
```

然后编辑 `.env`：

```dotenv
CODE_NAME=YOUR_CODE_NAME
CONDA_HOME=/path/to/conda
PYTHON_HOME=/path/to/conda/envs/your-env
```

- `CODE_NAME`：项目根目录下存放核心代码的目录名。
- `CONDA_HOME`：本机 Conda 的安装根目录。
- `PYTHON_HOME`：Conda 环境目录，或该环境的 Python 可执行文件路径。

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
ROOT_DIR  CODE_DIR  DATA_DIR  INIT_DIR
WORK_DIR  SCPT_DIR
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

当前的 `00_exp.sh` 是空白占位脚本，使用模板时请将其替换为第一个实际实验。实验名称和输出目录应能区分不同任务、实验或重复运行；生成的文件应放在 `wkdrs/<运行名称>/` 下。

## 研究工作流

STAR 提供四个相互配合的技能，将研究想法转化为可追踪、可审计的执行流程：

| 技能 | 用途 | 主要输出 |
| --- | --- | --- |
| `$rsch-plan-coach` | 通过分阶段提问明确研究想法 | `metds/plans/0_<主题>_plan.md` |
| `$rsch-plan-decomposer` | 将战略研究计划拆分成可验证的子计划 | `metds/plans/<前缀>_<任务>_plan.md` |
| `$rsch-plan-executor` | 实现并初步验证一个可执行的叶子计划 | 代码，以及 `wkdrs/<运行名称>/EXEC_PLAN.md` 和 `EXEC_LOG.md` |
| `$rsch-plan-status` | 汇总计划树进度并指出下一个可执行任务 | 只读状态摘要 |

典型流程如下：

```text
研究想法
    → 研究计划
    → 可执行子计划
    → 实现与验证
    → 状态汇总与下一步行动
```

这些技能会将决策和进度保存在项目文件中，避免仅依赖聊天记录。研究工作流同时支持中文和英文。

## 项目约定

1. 可复用的实现代码放在 `${CODE_NAME}/` 中。
2. 数据放在 `datas/`，模型权重放在 `inits/`，生成的实验文件放在 `wkdrs/`。
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

只保留确实有助于研究的结构——模板应当服务于研究，而不是限制研究。

## 许可证

本模板基于 [MIT 许可证](LICENCE) 发布。
