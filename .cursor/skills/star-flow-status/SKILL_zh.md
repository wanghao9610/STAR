---
name: star-flow-status
description: >-
  只读总览整条研究流程。扫描每个 metds/plans/*_plan.md，按 parent/prefix 重建拆解树，读取每个节点的
  章节状态、children、depends_on 与 exec_status（并读 wkdrs/<run>/EXEC_LOG.md 获取步级进度），然后渲染
  带状态的树、进度汇总、唯一的下一步动作，以及任何失配。同时检查周边阶段——想法、文献、代码审查、
  实验分析、方法文档——找出已完成工作里缺失或过期的后续环节。绝不写任何文件。只要用户运行
  /star-flow-status，或询问研究/计划的状态 / 总览 / 进度、接下来该做什么或执行什么、还欠着什么、某计划或
  其子计划进展到哪、想看计划树时，都应使用本 skill。Bilingual（中/英）。
---

# Research Flow Status — 只读总览

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。若 `SKILL_zh.md` 与 `SKILL.md` 冲突，以 `SKILL.md` 为准。

调用方式：`/star-flow-status [PLAN_NAME]`——不带参数则总览整条流程；带 slug / 数字前缀 / 文件名则把树和覆盖检查一起收敛到该计划的子树。调用里出现 `involve=<level>` 记号时，先剥离它再解析 `PLAN_NAME`（规约 §7.7）；除此之外它在这里不改变任何行为——本 skill 不提问。

**通用规约。** `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，更严处以本文件为准。只读汇报者用得上的部分——§0 词汇表、§5 计划名解析（仅当有 `PLAN_NAME` 要解析时）、§7 的汇报规则（其引言与第 1、4、5、6、11 条；第 2–3、7–10 条的提问机制管的是会提问的 skill，本 skill 从不提问）、§9 项目布局——随 Step 1 那一条装载消息一起到达。§8（产物登记表）是覆盖检查对账的注册表，只引用、不装载：spec 已逐项复述这些检查要读的文件名与状态字段，而 §8 其余部分——`model_id` / `model_trail`——管的是生产者，本 skill 不是。§1 git、§2 红线、§3 `.env` 运行时、§4 真实日期、§6 委派管的是会提交、会运行、会写文件的 skill，本 skill 一样都不做。真需要其中某节时，再整份读。

## 角色

你给研究者一张诚实的全景图：整条流程各自到哪了——计划树看到深处，周边阶段看个轮廓——以及一条清晰的"下一步该干什么"的建议。你是地图，不是司机：coach 定总体方向、decomposer 拆解、executor 干活、审计环节做判断——你只**读与报告**。

## 核心原则

1. **严格只读**。绝不创建、编辑或删除任何文件——不动计划、不动日志、不动 frontmatter。不做交互式决策树、不进 plan 模式、不派 Task subagent。用户想据此行动，就把他们指向对应 skill（`/star-proj-adopt`、`/star-idea-storm`、`/star-plan-coach`、`/star-refs-reviewer`、`/star-code-architect`、`/star-env-builder`、`/star-plan-decomposer`、`/star-plan-executor`、`/star-code-reviewer`、`/star-expt-analyst`、`/star-expt-digest`、`/star-plan-reviser`、`/star-metd-summarize`、`/star-code-release`）。
2. **文件是唯一依据**。你报告的一切都来自规约 §8 注册的产物：`metds/ideas/`、`metds/plans/`、`metds/refs/`、编译出的 `metds/*.md`，以及 `wkdrs/` 下的日志与报告（run 目录，外加 `wkdrs/reviews/`、`wkdrs/env_<name>_<date>/`、`wkdrs/digests/` 与 `wkdrs/results/`）。绝不凭对话记忆推断进度。字段缺失就写"未知"，不要猜。
3. **`parent:` 权威，前缀只是提示**。按每个文件的 `parent:` frontmatter 重建树，而非只看数字（两个不相关的根都可能是 `0_`）。层内顺序用 `depends_on`。
4. **只有计划树值得走一遍图，覆盖检查很薄**。计划树带顺序语义（`parent`、`depends_on`、`exec_status`）；其它阶段一律按注册表做"存在性 + 新鲜度"检查——绝不给本来没有顺序的产物硬造一套顺序。
5. **覆盖检查默认沉默**。只有 `references/status_spec_zh.md` 里的触发条件全部满足，某条信号才出现。进行中的工作永远不算欠账：还在跑的 run 什么都不欠。一条会给健康状态报警的覆盖检查，只会教会读者跳过它——那比没有更糟。
6. **一条建议，按优先顺序选出**。以唯一的下一步动作收尾，由 spec 里的优先顺序选出，并给出理由——不是给菜单。其余欠账留在覆盖检查列表里。若无合格者，说清是什么在挡路。

## 工作流

具体规则遵循 `references/status_spec_zh.md`（英文对话读 `references/status_spec.md`）——Step 1 那条消息会把它读进来；骨架如下：

**扫一次，然后只推理。** Step 1 用一条消息把本 skill 要读的东西——规约章节、spec、文件摘要——全部收齐，Step 2–9 都基于这次返回工作。不要再去打开摘要已覆盖的文件。只有两种情况值得二次读取：某段计划正文你需要原文引用而非计数；某个文件摘要只列出了它存在、没有打印其内容。本 skill 是整条流程里调用最频繁的一个，而"逐文件读一遍"或把装载本身拆成多条消息，正是拖慢它的原因——那一条消息里已经有的东西，再读一遍什么也换不来。

### Step 1：扫描
用一条消息装齐全部输入：一次 Bash 调用（以项目根目录为工作目录），外加同一条消息里单独读一次 spec：

```bash
sed -n '/^## 0\./,/^## 1\./p; /^## 5\./,/^## 6\./p' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
awk '/^## 7\./{s=1;n=0} /^## 8\./{s=0} s{if($0~/^[0-9]+\. /)n=int($0); if(n==0||n==1||n==4||n==5||n==6||n==11)print}' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
sed -n '/^## 9\./,$p' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
bash <本 skill 所在目录>/scripts/scan.sh --slim
```

一条消息、三份结果：规约摘录与收集脚本的摘要来自那次 Bash 调用，spec（`<本 skill 所在目录>/references/status_spec_zh.md`）来自同一条消息里单独发出的 `Read`。别把 spec `cat` 进命令里：每份工具结果各有自己的大小上限，Bash 结果一旦超过 30 KB 左右就会被落盘成文件，要再读一次才拿得回来——那正是"一条消息装齐"本来要省掉的那趟往返。项目一旦有了历史，光规约摘录加摘要就已经逼近这个上限，而 spec 还要再占 18 KB。不带 `PLAN_NAME` 时去掉 `'/^## 5\./,/^## 6\./p'` 这段范围——§5 就是用来解析它的。那行 awk 按条号选取 §7（引言加第 1、4、5、6、11 条）；若它什么都没打印——下游同步的规约副本过旧、条号可能不同——就改用 `sed -n '/^## 7\./,/^## 8\./p'` 装整节。摘要打印的每个路径都相对项目根目录。摘要部分是：每份计划的 frontmatter、`## Sub-plans` 索引与 §3/§5 的占位符计数（`[TBD]` 与 `【待定】` 一并计入）；每份 run 日志的 frontmatter、按标题计数后的正文、以及其中出现过的日期；run 目录之外每个注册产物的 frontmatter；以及 `metds/` 与 `wkdrs/` 深度 1 的文件清单。加上 spec 与规约章节，这就是 Step 2–9 的全部输入。

`--slim` 是项目有了历史之后还跑得起这一步的原因：它压缩的正是摘要里随历史增长、而非随计划树增长的那两部分，40 个 run 的项目上摘要少三分之一左右。超过六行的步骤表会变成表头行、`[tally] N data rows` 与每列的取值分布——`c3: done×7, blocked×1` 就是 Step 3 要的步骤计数，而写成 `N distinct` 的列是步骤名或日期，绝不会是状态列。六行及以内的表原样打印。未勾选的待办项与方向性信号从不被计数替代，所以待用户的叶子照样能看到它确切的命令。位于 run 目录内的产物不再打印 frontmatter——LISTING 里已经有它的文件名和文件名中的日期，而覆盖检查读的正是这些——被略过了多少个会打印出来。只有需要逐行读某个 run 的步骤时才去掉 `--slim`，并同时用 `--runs <该 run>` 收窄。

有了 `--slim`，下面这一步通常不必再做；历史特别长、且问题本身只针对某个子树时可以再收窄一层：`--runs <目录列表>` 把逐 run 的正文与日期行限制在这些 run 上。每个 run 的 frontmatter 照样打印，PLANS、LISTING 与 DIRS 也仍然覆盖全项目——子树本身要先靠每个计划的 `parent:` 才解析得出来，而未识别文件那一行是按全项目计数的。落在范围外的 run 会被点名为已省略，绝不悄悄丢掉。

脚本只收集，从不判断——它不认识状态符号、覆盖行、优先顺序，也不知道注册表期待哪些文件名，所有规则都留在本文件和 `references/status_spec_zh.md` 里。把它打印的内容当作原始文件内容来读，就像你自己逐个打开过一样。若脚本缺失或执行失败，退回逐文件读取，并在回复里说明这次走了退路。若无法解析出本 skill 自己的目录，仓库里任一份拷贝都可以——每份 `scripts/scan.sh` 逐字节相同，CI 会强制这一点：`bash "$(find . -path '*/skills/*/scripts/scan.sh' | head -1)"`。

若给了 `PLAN_NAME`，解析它并只保留该子树。扫描始终覆盖整个项目：要收敛出一棵子树，得先有所有计划的 `parent:`。

### Step 2：建树
按 `parent:` 把子节点链到父节点。兄弟按 `depends_on` 拓扑排序，缺失则回退到前缀顺序。标注每个节点为**根 / 内部 / 叶子**（叶子 = `children:` 为空或不存在）。

### Step 3：读各节点状态
- **总体计划节点**（根/内部）：coach 的 `status:` 映射——六节里有几节 `done` / `in_progress` / `pending` / `skipped`；是否设了 `finalized:`；是否已被拆解（有 `children:`）。
- **叶子**：`exec_status`（缺失默认 `pending`）与 `exec_runs`（最后一项是当前 run；更早的是重跑，有的话值得提到）。摘要里带着每一份 `wkdrs/<run>/EXEC_LOG.md`；从当前 run 那一段取步级进度（步 done / 总数、有无 `blocked`、有无"待用户执行"STOP 命令、有无记录的**方向性信号**）。

### Step 4：渲染树
每节点一行，按层级缩进，各带一个状态符号和简短状态（状态符号图例见 spec）。在叶子上显示 `depends_on`，并标出 blocked / 待用户 的叶子。

### Step 5：进度汇总
报三个数：总体方向完整度（各总体计划里 done 的章节数）、拆解覆盖度（叶子 vs 仍大到不能直接执行的节点）、执行进度（叶子 `done` / 总数，以及日志里步 done / 总数）。

### Step 6：覆盖检查
把 spec 覆盖表里的各条在收敛后的产物上过一遍：存在性与文件名日期看摘要的文件清单，状态字段看摘要里的产物 frontmatter——想法未立项、文献缺失、代码审查缺失或过期、实验分析缺失、结果汇总表过期、方法文档缺失或过期。只报触发的行，每行一句，并写明能补上它的 skill。一条都没触发则整段省略。

### Step 7：下一步动作
按优先顺序选出唯一的下一步：待用户的 STOP 命令 → 已完成工作的欠账 → 下一个可执行叶子 → 已定稿但未立项的想法。给一句话理由和确切命令。若无合格者，写明挡路者。

### Step 8：过期 / 失配检查
只标记、不修复：任何 `updated` 早于其父计划 `updated` 的叶子（父计划在拆解后可能已变 → 建议重跑 `/star-plan-decomposer`）；任何找不到对应文件的 `children:` 项、或未被父计划 `## Sub-plans` 列出的计划文件；任何解析不到兄弟的 `depends_on` 前缀。

### Step 9：未识别文件行
在摘要的文件清单上，数一数不匹配注册表任何模式的形似报告的文件（规则见 spec 里未识别文件行那一段）。报一行：数量 + 至多三个示例路径。数量为 0 则整行省略。这一行的作用是：当某个产出方 skill 改了输出命名时，让它被看见，而不是让对应的覆盖检查悄悄失效。

## 输出与对话纪律

- 顺序：树 → 进度汇总 → 覆盖检查 → 唯一的下一步 → 失配标记 → 未识别文件行。覆盖检查、失配、未识别文件行为空时各自省略。整条回复控制在约 500 字以内；用紧凑的树，而非每节点一段散文。
- 用用户的语言回复；即使计划与报告正文是 `zh`，树/标签跟随对话语言。
- 因为你什么都不写，没有审批确认点——也正因如此，绝不声称或暗示你改动了任何东西。
