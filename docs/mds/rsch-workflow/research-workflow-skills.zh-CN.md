# 研究工作流 Skills 使用指南

**语言：** [English](research-workflow-skills.md) | 简体中文

STAR 提供四个相互衔接的研究工作流 skill，用于把一个研究想法逐步变成可追踪的计划、可执行的任务和有验证记录的实现：

```text
研究想法
  → rsch-plan-coach：形成战略研究计划
  → rsch-plan-decomposer：拆成有依赖关系的执行子计划
  → rsch-plan-executor：实现并验证一个叶子子计划
  → rsch-plan-status：随时查看全局进度和下一步
```

这些 skill 把计划状态写进项目文件，因此可以跨对话、跨 session 继续工作，不依赖聊天记录保存上下文。

## 1. 调用方式

本文以 Codex 为例，使用 `$skill-name` 调用：

```text
$rsch-plan-coach 开放词汇检测与分割
$rsch-plan-decomposer 0_open-vocab-det-seg_plan.md
$rsch-plan-executor 00
$rsch-plan-status
```

在 Claude 和 Cursor 中，对应写法是 `/skill-name`：

```text
/rsch-plan-coach 开放词汇检测与分割
```

也可以直接用自然语言说明需求，例如“帮我把这份研究计划拆成可执行子计划”。显式写出 skill 名通常更容易确保调用正确。

需要指定计划时，`PLAN_NAME` 支持三种形式：

| 形式 | 示例 | 适用场景 |
| --- | --- | --- |
| slug | `open-vocab-det-seg` | 名称唯一时最简洁 |
| 数字前缀 | `00` | 计划树中前缀唯一时最快 |
| 完整文件名 | `00_mvp-3way-ablation_plan.md` | 最明确，推荐用于同名或多根计划 |

多个根计划目前都可能以 `0_` 开头，因此出现歧义时应使用 slug 或完整文件名。

## 2. 开始前的准备

- 在 STAR 项目根目录中使用这些 skill。
- 研究计划统一放在 `metds/plans/`。
- 执行代码前应存在本地 `.env`，并正确设置 `CODE_NAME`、`CONDA_HOME` 和 `PYTHON_HOME`。
- 可复用代码放在 `${CODE_NAME}/`，数据放在 `datas/`，模型权重放在 `inits/`，生成结果放在 `wkdrs/`。
- 中文和英文都受支持。skill 会跟随对话语言；已有计划继续使用其 frontmatter 中 `language` 指定的正文语言。

如果只是编写或拆解计划，不需要提前准备数据、权重或可运行代码；这些输入会在执行阶段检查。

## 3. `$rsch-plan-coach`：编写研究计划

### 什么时候用

- 只有一个初步 idea，不知道如何形成完整研究方案。
- 要编写或完善 research plan、proposal 或开题报告。
- 已有计划写到一半，希望从上次进度继续。
- 需要补强问题定义、相关工作、方法、实验或风险分析。

### 怎么调用

新建计划：

```text
$rsch-plan-coach 开放词汇检测与分割
```

续写已有计划：

```text
$rsch-plan-coach
```

不带主题时，skill 会扫描 `metds/plans/*_plan.md`。如果找到未完成计划，会询问是继续该计划还是新建计划。

### 它会做什么

skill 会一次只讨论一个问题，依次推进六个阶段：

1. 问题定义与动机；
2. 相关工作与定位；
3. 核心方法；
4. 实验与验证设计；
5. 风险与备选方案；
6. 里程碑与产出。

每完成一节，skill 会先整理成结构化正文，得到确认后立即写入计划文件，并更新该节状态。用户可以要求跳过某节、保留 `【待定】`，或者让 AI 先起草再确认。

### 主要输出

```text
metds/plans/0_<slug>_plan.md
```

例如：

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

计划中包含六个研究章节和对应状态。全部完成后，skill 会做一次质量检查，并在用户确认定稿后写入 `finalized` 日期。

### 使用建议

- 最初只需要提供一两句话的研究主题，不必先写完整 proposal。
- 不确定实验或指标时可以直接说“不知道”，skill 会给出 2–3 个候选方案。
- 关键章节尚未确认时不要急着拆解，否则下游子计划会出现较多 `【待定】`。

完整定义见 [`rsch-plan-coach/SKILL.md`](../../../.agents/skills/rsch-plan-coach/SKILL.md)。

## 4. `$rsch-plan-decomposer`：拆解执行子计划

### 什么时候用

- 根计划已经说明“为什么做”和“做什么”，现在需要明确“怎么做”。
- 要把方法、里程碑或实验设计拆成可执行任务。
- 某个已有子计划仍然太大，需要继续递归拆解。

### 怎么调用

```text
$rsch-plan-decomposer open-vocab-det-seg
$rsch-plan-decomposer 0
$rsch-plan-decomposer 0_open-vocab-det-seg_plan.md
```

如果不提供参数或匹配不唯一，skill 会列出候选计划供选择。

### 它会做什么

skill 先检查父计划是否足够完整，然后依次确认两个决定：

1. **拆分轴**：按里程碑/阶段、组件/模块，或 claim→实验拆分；
2. **子计划清单**：确认每个单元的目标、粒度、依赖和执行顺序。

确认后，skill 会自动为每个单元生成子计划。每份子计划都包含：

- 目标与非目标；
- 输入和上游依赖；
- 可逐项执行的任务分解；
- 明确路径的产出物；
- 可验证的完成判据；
- 局部风险与备选方案。

### 文件与依赖结构

子计划和父计划平铺在 `metds/plans/` 中，数字前缀表示层级：

```text
metds/plans/
├── 0_open-vocab-det-seg_plan.md
├── 00_mvp-3way-ablation_plan.md
├── 01_core-method-pipeline_plan.md
│   ├── 010_desc-generation_plan.md
│   └── 011_set-matching_plan.md
└── 02_full-experiments_plan.md
```

上面的缩进表示逻辑树；文件在磁盘上仍位于同一目录。每深入一层，前缀追加一位数字。每个节点最多有 10 个直接子计划；任务更多时应分两层拆解。

真正的父子关系以子计划 frontmatter 中的 `parent` 为准，执行顺序以 `depends_on` 为准。skill 还会在父计划中维护 `children` 和 `## Sub-plans` 索引。

继续拆解较粗的子计划：

```text
$rsch-plan-decomposer 01
```

### 使用建议

- 父计划的方法和里程碑还很模糊时，先回到 `$rsch-plan-coach` 补完。
- 一个子计划应当有一条能明确判断成功或失败的完成判据；“调研一下”或“尝试优化”还不够具体。
- 不要手工重排已使用的数字前缀，否则会破坏更深层计划和已有依赖引用。

完整定义见 [`rsch-plan-decomposer/SKILL.md`](../../../.agents/skills/rsch-plan-decomposer/SKILL.md)。

## 5. `$rsch-plan-executor`：执行一个叶子计划

### 什么时候用

- 子计划已经有明确的任务分解和完成判据，需要开始实现。
- 要从上次中断的位置继续执行。
- 需要把计划落实为代码、轻量验证和可审计的执行记录。

### 怎么调用

```text
$rsch-plan-executor 00
$rsch-plan-executor mvp-3way-ablation
$rsch-plan-executor 00_mvp-3way-ablation_plan.md
```

只有**叶子计划**可以执行。如果目标仍有 `children`，skill 会要求选择其中的叶子，或建议继续拆解。

### 执行前检查

skill 会先确认：

- 子计划 §3 的任务是否具体；
- §5 是否给出了可运行的完成判据；
- `depends_on` 中的上游计划是否已经完成；
- 所需数据、权重和代码模块是否存在；
- `.env` 中的项目路径与 Conda 环境是否可用。

缺少硬依赖时，skill 会报告具体 blocker，而不会伪造输入或跳过依赖。

### 它会做什么

1. 读取真实代码，建立“现状 vs 计划要求”的差距清单；
2. 把子计划细化为逐步的 `EXEC_PLAN`，每一步绑定文件、命令、产物和检查；
3. 只做与当前步骤直接相关的修改；
4. 运行最窄的轻量验证并把证据写入日志；
5. 达到子计划完成判据后，把执行状态更新为 `done`。

普通的范围内实现和轻量验证会按当前工具的权限模型继续进行；遇到会实质改变任务范围的选择时，skill 会停下来询问。

### STOP 线

以下工作不会由 skill 自动启动：

- 长时间或多卡训练/微调；
- 全量数据集评测；
- 大批量、按量计费的 API 调用；
- 可能覆盖重要产物的操作；
- 无法判断耗时或成本的任务。

skill 会准备好确切命令，写入执行日志的“待用户执行”区域，然后停下。用户完成命令后，再次调用同一计划即可从日志继续验证，不必从头开始。

### 主要输出

默认 run 名为 `<prefix>_<slug>`：

```text
wkdrs/00_mvp-3way-ablation/
├── EXEC_PLAN.md
├── EXEC_LOG.md
└── ...                     # 本轮生成的其他产物
```

- `EXEC_PLAN.md`：执行动作、文件、命令、产物、检查和 STOP 线；
- `EXEC_LOG.md`：每一步的状态、验证证据、blocker 和待用户命令；
- 计划文件只增加轻量的 `exec_status`、`exec_run` 和 `updated` 字段。

再次执行同一计划时，skill 以 `EXEC_LOG.md` 为真源，跳过已完成步骤，从第一个未完成步骤续跑。

完整定义见 [`rsch-plan-executor/SKILL.md`](../../../.agents/skills/rsch-plan-executor/SKILL.md)。

## 6. `$rsch-plan-status`：查看计划树状态

### 什么时候用

- 想知道整个研究计划进行到哪一步。
- 不确定接下来该拆解还是该执行哪个子计划。
- 想检查依赖、阻塞、待用户命令或计划是否过期。
- 开始新 session 前需要快速恢复上下文。

### 怎么调用

查看全部计划：

```text
$rsch-plan-status
```

只查看某个计划子树：

```text
$rsch-plan-status open-vocab-det-seg
$rsch-plan-status 01
```

### 它会报告什么

- 带状态的计划树；
- 战略章节完整度、拆解覆盖度和叶子执行进度；
- 每个叶子的依赖、日志步骤进度、阻塞或待用户命令；
- 唯一一个推荐的“下一步可执行叶子”及理由；
- 父计划更新晚于子计划、悬挂链接、坏依赖、孤儿 run 等 drift。

这是一个**严格只读**的 skill：只扫描 `metds/plans/` 和 `wkdrs/<run>/EXEC_LOG.md`，不会创建或修改任何文件。

完整定义见 [`rsch-plan-status/SKILL.md`](../../../.agents/skills/rsch-plan-status/SKILL.md)。

## 7. 一套完整的使用示例

下面是一条典型路径。

### 第一步：把 idea 写成计划

```text
$rsch-plan-coach 我想研究开放词汇检测与分割中更可靠的文本描述生成方法
```

经过分阶段问答后得到：

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

### 第二步：拆成执行单元

```text
$rsch-plan-decomposer open-vocab-det-seg
```

确认按里程碑拆分后，可能得到：

```text
00_mvp-3way-ablation_plan.md
01_core-method-pipeline_plan.md
02_full-experiments_plan.md
03_writing-submission_plan.md
```

### 第三步：确认下一项工作

```text
$rsch-plan-status open-vocab-det-seg
```

如果报告推荐 `00_mvp-3way-ablation`，执行：

```text
$rsch-plan-executor 00_mvp-3way-ablation_plan.md
```

### 第四步：在 STOP 线后续跑

如果日志中留下了一条需要用户运行的训练命令：

1. 按 `wkdrs/00_mvp-3way-ablation/EXEC_LOG.md` 运行命令；
2. 确认产物写入日志指定位置；
3. 再次调用 `$rsch-plan-executor 00`；
4. skill 会读取旧日志并从完成判据验证处继续。

### 第五步：循环推进

每完成一个叶子后运行：

```text
$rsch-plan-status
```

根据唯一的下一步建议继续执行，直到所有叶子完成；如果结果否定了父计划的关键假设，则回到 `$rsch-plan-coach` 修订战略，或用 `$rsch-plan-decomposer` 调整任务结构。

## 8. 常见问题

### 应该先用哪个 skill？

| 当前情况 | 使用 |
| --- | --- |
| 只有 idea，研究问题还没说清 | `$rsch-plan-coach` |
| 已有战略计划，需要拆成任务 | `$rsch-plan-decomposer` |
| 已有具体叶子任务，需要写代码和验证 | `$rsch-plan-executor` |
| 不知道当前进度或下一步 | `$rsch-plan-status` |

### 为什么 executor 不执行我指定的计划？

常见原因有三类：目标不是叶子、`depends_on` 尚未完成，或任务分解/完成判据仍有大量 `【待定】`。先运行 `$rsch-plan-status` 通常能看到具体原因。

### 为什么训练命令只写进日志，没有自动运行？

完整训练、全量评测和高成本调用越过 STOP 线。skill 负责把命令和输出位置准备到可复现状态，由用户决定何时占用资源运行。

### 如何跨 session 继续？

- coach 从计划 frontmatter 的章节状态继续；
- decomposer 从父子链接和已有子计划继续；
- executor 从 `exec_run` 指向的 `EXEC_LOG.md` 继续；
- status 可以在任何时候只读重建全局状态。

### 可以手工修改计划文件吗？

可以，但应保持 frontmatter 和正文一致，尤其是 `parent`、`children`、`depends_on`、`status`、`exec_status` 和 `exec_run`。修改父计划后，先运行 `$rsch-plan-status` 检查 drift，再决定是否重新拆解。

## 9. Skill 文件位置

不同工具使用各自适配的 skill 副本，不要混用其中的工具调用说明：

| 工具 | 权威目录 | 调用形式 |
| --- | --- | --- |
| Codex | `.agents/skills/` | `$rsch-plan-*` |
| Claude | `.claude/skills/` | `/rsch-plan-*` |
| Cursor | `.cursor/skills/` | `/rsch-plan-*` |

四个目录名分别是：

```text
rsch-plan-coach
rsch-plan-decomposer
rsch-plan-executor
rsch-plan-status
```
