# 研究工作流 Skill 通用规约

**语言：** [English](research-workflow-conventions.md) | 简体中文

STAR 研究工作流中每个 skill 都遵守的规则。十二个 skill——`star-idea-storm`、`star-plan-coach`、`star-refs-reviewer`、`star-code-architect`、`star-env-builder`、`star-plan-decomposer`、`star-plan-executor`、`star-code-reviewer`、`star-expt-analyst`、`star-plan-reviser`、`star-plan-status`、`star-metd-summarize`——各有自己的工作流、写入边界和质检表。它们共用的部分只在这里存一份。

**优先级。** 本文件是**基线**。某个 skill 的 `SKILL.md` 可以更**严**——更窄的写入边界、更低的阈值、额外的门、乃至"本 skill 永不提交"——更严者生效。skill 绝不放松本文件设下的规则。当 `SKILL.md` 里带有下述某条规则的一行摘要时，那一行是有约束力的提醒，本文件是完整规则。

本文件既是给 skill 的契约，也是给读者的说明：它写明了这套工作流会对你的仓库做什么、不会做什么。

## 1. Git

**永不提交的 skill**——git 只读使用（`status` / `diff` / `log`）：`star-plan-status`、`star-refs-reviewer`、`star-expt-analyst`、`star-metd-summarize`。

**可以提交的 skill**，及各自能 stage 的范围：

| Skill | 提交时机 | stage 范围 |
| --- | --- | --- |
| `star-idea-storm` | 会话结束时提供一次 | 本次会话创建或编辑过的 idea 文件 |
| `star-plan-coach` | 会话结束时提供一次 | 本次会话创建或编辑过的计划文件 |
| `star-plan-decomposer` | 运行结束时提供一次 | 本次所写子计划及父计划的索引更新 |
| `star-plan-reviser` | Step 7 有落笔修订时提供一次 | 目标计划，及一行目标变化时的父计划 |
| `star-code-architect` | 每个落地阶段或已验证的迁移组一次 | `${CODE_NAME}/` 及本 skill 拥有的规约文件 |
| `star-env-builder` | 每次运行至多一次 | 仅 `${CODE_NAME}/requirements*` |
| `star-plan-executor` | 每个已验证动作一次，且仅在门批准了 checkpoint 时 | 该动作触碰的文件 |
| `star-code-reviewer` | 修复轮之后可选的一次 | 仅修复轮触碰的文件 |

**通用规则：**

1. **只 stage 本次运行创建或编辑过的文件。** 绝不 `git add -A`，绝不 `git add .`。在科研仓库里，一次全量 add 会把 checkpoint、数据集和草稿一并卷进来。
2. **提交信息前缀就是 skill 自己的名字**：`star-plan-executor: <run> step 2 — <摘要>`、`star-plan-coach: <slug> — <里程碑>`。一个 skill，在提交历史里占一个命名空间。
3. **不推送、不改写历史**（`rebase`、`amend`、`reset --hard`）、**不切分支、不打 tag。** 分支和远端归用户。
4. **运行开始时就已有未提交改动的路径，永不 stage。** 询问时点名这些路径，让用户先自行提交或 stash——skill 的提交绝不能捆进不是它做的工作。
5. **绝不静默提交。** 每次提交要么被用户批准过的门覆盖，要么作为独立问题提出。拒绝始终是正当答案。
6. **绝不强制 add 被忽略的路径。** `.env`、`datas/`、`inits/`、`wkdrs/` 默认被 git 忽略，不进历史。（`tasks/` 目前是被跟踪的——见 `AGENTS.md` §5。）

**为什么重要。** `star-plan-reviser` 告诉用户"旧版本存于 git"；只有当计划写手真的提供了那些提交，这句话才成立。而在一个装着 `inits/` 和 `wkdrs/` 的项目里，一次手滑的 `git add -A`，差别是 40 KB 的 diff 和 40 GB 的 diff。

## 2. STOP 线

skill 可以改代码、跑**轻量验证**。任何**重的、贵的、不可逆的**动作都越过 STOP 线：把确切命令备好交回用户，然后停下。绝不自主启动——无论 skill 多有把握，也无论周边工作是否已被某个门批准。

**轻——skill 可以跑：**

- 单元测试与冒烟测试、import 检查、`python -m compileall`、小 batch 的一次前向。
- 小规模、**不微调**的子集推理——例如 MVP 完成判据："不训练，小子集，换掉文本输入做对比"。
- dry run、配置校验、shape / dtype 检查、几步过拟合的 sanity run。
- 任何在**普通资源上几分钟内跑完**、且只写在该 skill 写入边界之内的动作。

**越过 STOP 线——交回用户：**

- **长时或多卡训练 / 微调**——任何完整训练。
- **全量数据集评测**——耗时数小时或占用大量算力的。
- **高开销 API 调用**——按次计费的大批量 LLM / VLM 推理。
- **`sudo` 或系统包管理器**（apt、brew）、驱动或 CUDA toolkit 的系统级安装，以及 **CUDA 源码编译**（flash-attn 一类）。
- **删除任何环境**，以及覆盖用户可能想保留的产物。
- 任何**无法界定**开销或耗时的动作。拿不准时，就按 STOP 处理。

下载体积阈值是**各 skill 自定的**——`star-env-builder` 的安装计划一旦获批，框架级下载照跑；`star-code-architect` 则把超过约 1 GB 的交回用户。各 skill 写明自己的阈值；上面这份清单是无论如何都越线的部分。

**怎么交接。** 给用户确切命令，经 `.env` 环境（§3）调用，存在运行入口时经项目入口 `execs/run.sh`；说明它产出什么、落在哪；说明要带回什么输出才能验证判据。把命令写成可运行脚本是轻的；运行它不是。

## 3. `.env` 与项目运行时

`AGENTS.md` §6 的操作化版本。

1. **项目根的 `.env` 是 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME` 的唯一来源。** 绝不猜本地路径、绝不硬编码、绝不凭别的项目的记忆填。
2. **`.env` 缺失** → 从 `.env.example` 创建，请用户填好机器相关的值，在此之前停下。绝不为了继续跑而编造一个值。
3. **shell 是无状态的。** `source activate` 活不到下一条命令。把解释器一次性解析成绝对路径——`$CONDA_HOME/envs/<name>/bin/python` 或 `<project>/.venv/bin/python`——之后每条命令都走它。绝不用系统 python。
4. **只有 `star-env-builder` 创建、修复或改动环境。** 其他 skill 永不安装或升级任何东西。缺失的工具（ruff、matplotlib、bibtexparser、pandas）意味着**检查降级**：没有它照跑，在报告里说明，并路由到 `star-env-builder`。为了跑完自己的检查而去装它，超出边界。
5. 跑不了 python 的环境是**要上报的 blocker**，不是绕过去的问题。

## 4. 真实日期

1. **写进文件的每个日期都取自运行时的系统时钟**（`date +%Y-%m-%d`）。绝不凭记忆写日期、绝不从上下文推断、绝不照抄模板或示例里的那个。
2. **抓取日期**是实际抓取的那天。**报告日期**是报告写下的那天。**备份戳**是备份发生的那天。
3. 同一天重新生成的带日期文件覆盖当天那份；**换一天**则新写一份。正是这一点让一个 run 目录可以当时间线来读。

## 5. 计划名解析

1. **`PLAN_NAME` 对 `metds/plans/*_plan.md` 匹配**：按 slug（`open-vocab-det-seg`）、按数字前缀（`00`）或按完整文件名；`metds/plans/…` 路径也算。
2. **不存在或有歧义 → 列出最接近的候选**（前缀 + slug + 一行状态），问一个直接的问题。绝不猜用户指的是哪份计划。
3. **`parent:` 才权威；前缀只是提示。** 树从各文件的 `parent:` frontmatter 重建。数字前缀只供人类排序与提示——在"根取最小空闲数字"规则之前创建的项目里，两个无关的根可能共用一个数字。
4. **叶子 = `children:` 为空或缺失的计划。** 只有叶子可执行。
5. **`depends_on` 存兄弟前缀**，是 executor 与 `star-plan-status` 消费的机器可读执行顺序。它保持无环，并与父计划 `## Sub-plans` 索引一致。
6. **绝不重编号前缀。** 每个更深的前缀、每个 `parent:` / `traces_to` 引用都建立在它上面。

## 6. 委派

1. **默认本地执行。** 只委派边界清楚、彼此独立、且委派确实带来实质收益的工作。绝不给每个琐碎的顺序步骤都配一个 delegate。
2. **交给 delegate 的是**：确切的文件清单、它必须返回的 rubric 或契约、以及逐字写明的范围（"只做这些条目"）。并发的 delegate 之间**文件归属互不重叠**。
3. **主 agent 拥有集成与判断权。** 它亲自重跑每个检查，绝不轻信自报通过。delegate 绝不给整体结论打分。
4. **收集型 delegate**——常见情形，读日志、读论文、读包、读计划——只读取并返回填好的契约。它不写任何文件，也不读自己清单之外的东西。
5. **只有 `star-plan-executor` 会派出可以改文件的实现型 delegate**；那份契约是它自己的 `references/agent_dispatch_spec_zh.md`。

## 7. 对话纪律

工具中立的那一半。**怎么问**——AskUserQuestion、Codex 的结构化输入工具，还是纯文本——因平台而异，留在各自的 `SKILL.md` 里。

1. **每条聊天回复控制在约 400 字以内。** 写入磁盘的文件不计入。细节属于产物；回复是摘要。
2. **一次只问一个问题，拿到明确答复再行动。** 绝不打包批准、绝不默认同意。**headless 与脚本化运行同样适用**：skill 走到门口就停下等待，而不是径直往下走——见指南的"哪些环节可以无人值守？"。
3. **每个问题带 2–4 个具体选项并标出推荐**，用户始终可以在选项之外自由作答。确实开放的问题（最初的研究主题）可以不带选项。
4. **如实汇报。** 缺口绝不往上凑。跳过或降级的检查绝不说成跑过。没改动的文件、状态或计划，绝不说成或暗示改过。
5. **结论先行**，然后是证据，最后是通向下一个 skill 的路由。
6. **用用户的对话语言回复。** 文档正文语言跟随它自己 frontmatter 的 `language`（或其来源的），**不是**对话的——用中文讨论一份英文计划，写进那份计划的仍然是英文。中文文档里，技术名词、指标名、会议名、文件路径以及 `reference.bib` 内的全部内容一律保留英文。
