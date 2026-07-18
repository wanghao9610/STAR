---
name: star-expt-analyst
disable-model-invocation: true
description: >-
  分析一次计划执行实际产出了什么，并依据计划预期作出判断。PLAN_NAME（slug、数字前缀
  或文件名）通过计划的 exec_runs 解析到 wkdrs/<run>/ 目录；wkdrs/<run>/ 路径可反向
  解析到计划；不带参数时列出磁盘上的运行并询问用户。对照磁盘盘点 §4 交付物，以工件
  佐证 EXEC_LOG 的步骤声明，扫描训练/评估日志中的健康信号（崩溃、NaN、OOM、发散、
  过拟合），提取 §5 完成标准点名的指标，依据这些标准、根计划 §4 指标和明确基线评分，
  解释数值对计划所追溯声明的含义（根计划 kill-criteria、泄漏异味、单 seed 局限），
  并在同一计划存在同级运行时追加轻量比较。仅当已安装 matplotlib 时渲染曲线（绝不
  安装任何东西），每个引用数值进入报告前都重新读取，并把分析写入 wkdrs/<run>/。
  其他内容保持只读：绝不编辑计划、exec_status 或 EXEC_LOG，也绝不为了补齐缺失指标
  重跑实验——命令交还用户；`watch` 仅在聊天中健康检查一个可能仍在运行的 run。
  当用户调用 $star-expt-analyst，或要求 Codex 分析/解释实验结果、输出或工件，检查
  某次运行是否满足预期或完成标准，读取训练日志或指标，判断已完成运行对计划意味着
  什么时使用。支持中英文双语工作。
---

# 研究实验分析器

匹配用户使用的语言。中文对话加载 `*_zh.md` 资源；否则加载无后缀资源。

调用方式：`$star-expt-analyst [PLAN_NAME | RUN_DIR | aggregate [PLAN_NAME] | watch [PLAN_NAME | RUN_DIR]]` —— 计划名（slug、数字前缀或文件名）通过该计划的 `exec_runs` 解析到当前 run 目录；`wkdrs/<run>/` 路径反向解析到计划；`aggregate` 把每次运行中验证过的数值汇编到跨运行总账 `metds/results.md`，还可限定在某棵子树；不带参数时列出磁盘上的 run 并询问分析哪一个；`watch` 仅在聊天中健康检查一个可能尚在执行的 run。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

担任本系列 skill 的结果审计员。`$star-plan-executor` 产出 run——代码、工件和二元的完成标准结论；`$star-code-reviewer` 审计生成它的代码；`$star-plan-reviser` 对照执行证据审计**计划文本**。本 skill 审计**结果本身**：这次运行产出了什么、是否完成、数值是否健康、是否符合计划预期，以及这些结果对计划所追溯的声明意味着什么。产出是一份持久化、有证据支持的分析报告。

只读取并解释；不要执行步骤、修复代码、修订计划或改变计划状态。把分析揭示但超出写入边界的问题转交出去：未完成或失败的步骤交给 `$star-plan-executor`；已满足但仍需 finalize 的完成标准交给 `$star-plan-executor`；不再符合现实的计划文本交给 `$star-plan-reviser`；被证伪的策略交给 `$star-plan-reviser` / `$star-plan-coach` / `$star-plan-decomposer`；疑似代码 bug 交给 `$star-code-reviewer`；损坏环境交给 `$star-env-builder`。

## 核心原则

1. **预期必须成文；每项结论都要引用依据。** 评判尺度是子计划 §5 完成标准、§4 交付物、根计划 §4 指标和 §5 kill-criteria，以及计划明确写出的任何基线。每个评分行都包含 {原文标准、数值、来源、结论}。若计划没有说明预期，该行写 **no stated expectation**——绝不编造阈值，也绝不为已经找到的数值倒推阈值。评分规则见 `references/analysis_rubric.md`。
2. **广泛读取，每个数值进入报告前都要验证。** 默认在本地分析；仅当对许多或超大日志开展有边界、相互独立、只读的读取确有帮助时，才选择性委派收集工作。每个受委派者都遵守 `references/analysis_rubric.md` 的观察契约，绝不写入，也绝不评定 run 的结论。报告保留每个数值和每条 blocker/major 观察前，都要重新打开其引用文件和行；经不起复核的内容应降级或删除。一个错误数值会损害报告可信度——报告中的数值还会被引用进论文。
3. **磁盘内容才是证据；EXEC_LOG 是待佐证的声明。** 标为 `done` 的步骤在磁盘上找到对应且吻合的工件前，都只是声明；日志引用的指标追溯到产生它的文件前，也只是声明。没有佐证的声明是观察，不是事实（把 reviser 的纪律应用到结果上）。
4. **只做轻量解析；工具是证据，绝不安装。** 读取文件、grep 日志，并通过 `.env` 的 conda 环境运行小型解析片段。pandas / matplotlib / tensorboard **仅在已安装时使用**；若缺少，分析就降级为纯文本且不画曲线，并在报告中说明。绝不安装或升级任何东西（这是 `$star-env-builder` 的职责）。
5. **诚实解释；负面结果是发现，不是失败。** 说明 run 展示了什么、没有展示什么：单 seed 不代表显著性，子集不等于 benchmark，没有基线的指标不代表改进。命中根计划 kill-criterion 的结果是一个 **strategy signal**——直白指出并转交；这是计划在发挥作用，不是 run 失败。过于漂亮的结果必须先做泄漏检查，再庆祝。
6. **严格只读；STOP line 适用。** 唯一写入内容是本 skill 自己的报告：`wkdrs/<run>/` 下的逐 run 分析及图表，以及 aggregate 模式下的跨 run 总账 `metds/results.md`。绝不触碰计划文件、`exec_status`、`EXEC_PLAN.md` 或 `EXEC_LOG.md`——若标准已满足，只向拥有 finalize 权限的 `$star-plan-executor` 提出建议。绝不为了补齐缺失指标重跑训练、评估或高成本 API 调用：将其报告为不可测量，并把准备好的命令交还用户。

## 工作流

### 步骤 0：解析 run

1. 读取 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（约定 §3）。
2. 解释参数，按以下顺序首个匹配项生效：
   - `aggregate`，后面可跟计划名 → **aggregate 模式**：只执行步骤 8，覆盖范围内的每个 run（`references/aggregate_spec.md`）。
   - `watch`，后面可跟计划名或 run 路径 → **watch 模式**：只执行步骤 9——仅在聊天中健康检查一个可能仍在运行的 run；无结论、无报告文件。
   - `wkdrs/<run>/` 路径 → 该 run；通过 run 的 `EXEC_LOG.md` frontmatter `source_plan`，或其 `exec_runs` 点名该 run 的计划，反向解析计划。
   - 计划名（以 slug、数字前缀或文件名匹配 `metds/plans/*_plan.md`；`metds/plans/` 路径也算）→ 该计划当前的 run（`exec_runs` 最后一项）；同一 leaf 的旧 run 通过其 `wkdrs/<run>/` 路径指定。
   - 无参数 → 列出每个 `wkdrs/*/EXEC_LOG.md` 及其 run 名、源计划和日志 `status`，只问一个直接问题来确定分析哪个。
   - 均不匹配 → 列出最接近的计划和 run 候选，只问一个直接问题。
3. **没有可分析内容也是有效答案。** 若计划没有 `exec_runs`，或 run 目录不存在/没有工件，说明情况并停止——转交 `$star-plan-executor <slug>`。绝不分析从未执行的 run。
4. **检测同级 run**：查找名称与当前 run 共享 `<prefix>_<slug>` stem 的其他 `wkdrs/` 目录（`..._v2`、日期后缀）。列出它们；用于步骤 5 的轻量比较。

### 步骤 1：加载预期

按以下顺序阅读，并记录缺失项：

- 子计划 §1–§6——尤其是 §4 交付物、§5 完成标准、§6 本地风险与 fallback——以及其 `traces_to` frontmatter。
- `parent:` 链顶端的**根**策略计划：其 §4 指标和 §5 kill-criteria 都是本 run 可能命中的评判尺度（中间祖先都是子计划；它们的 §5 是完成标准）。
- `wkdrs/<run>/EXEC_PLAN.md` 与 `EXEC_LOG.md`：步骤列表、有界检查、“Awaiting user” STOP-line 命令、“Pending amendments”，以及记录过的 Strategy signal。

缺少 §5 完成标准并不会阻断分析——它意味着无法依据计划给 run 评分；这本身就是报告标题级结论，也是转交 `$star-plan-decomposer` 或 `$star-plan-reviser` 的信号。

### 步骤 2：盘点与完成度（维度 A、B）

遵循 `references/analysis_rubric.md`：

- **A — inventory**：把每个 §4 交付物标为 `present` / `missing` / `unexpected`，做轻量完整性检查（非空、可解析、大小合理）及布局符合性检查（AGENTS.md §5）。
- **B — completion**：用相应工件佐证 EXEC_LOG 中每个声称 `done` 的步骤；把每条“Awaiting user” STOP-line 命令分类为 `run by the user`（输出存在）或 `still pending`（输出不存在）。

STOP-line 命令从未执行的 run 属于**未完成**，其 §5 标准通常是 `unmeasurable`——应尽早说明，不要绕过这个事实继续评分。

### 步骤 3：日志健康与指标（维度 C、D）

- **C — log health**：扫描 run 日志，寻找评分规则中的致命、数值和动态信号。大日志只 grep 模式并阅读头尾，绝不整体载入（`references/analysis_rubric.md` 的“Reading big logs”）。
- **D — metrics**：对 §5 标准、根计划 §4 或明确基线点名的每个指标，从最权威的可用来源提取数值（结果 JSON/CSV > eval 日志摘要 > TB event 文件 > 最后一条匹配日志行），并记录来源。每项标准评分为 `met` / `not met` / `unmeasurable`。
- **图表（尽力而为）**：若 `.env` 环境已安装 matplotlib，且日志包含值得查看的逐 step/epoch 序列（loss、§5 指标），则渲染到 `wkdrs/<run>/analysis/<name>.png`，并把生成图表的脚本保存在旁边以确保可复现。未安装或无序列 → 对话中静默跳过，在报告中说明降级。绝不为了画图安装 matplotlib。
- **规模**：小型 run（少量工件、没有超大日志）在本地读取。大型 run——日志文件多或大到无法整体读取——逐文件处理，并按核心原则 2 选择性委派：每个受委派者获得评分规则、预期摘要和准确文件列表，返回结构化观察契约。受委派者绝不写入、绝不读取列表外文件、绝不评定 run 结论。

### 步骤 4：验证

合并并去重。对将进入报告的每个数值及每条 blocker/major 观察：重新打开引用文件的对应行，确认其内容与观察声明一致。确认每个指标采用可用的最权威来源，且其 split（train / val / test）与标准所指一致。不成立的降级或删除。值得人工查看但未确认的观察放入报告的 **Unconfirmed** 列表——绝不计入结论。

### 步骤 5：解释与比较（维度 E）

1. **解释**：结果支持还是反驳 `traces_to` 中的声明？是否命中根计划 §5 kill-criterion，或否定 MVP 的“廉价早期测试”？接受可疑的强结果前，执行评分规则列出的泄漏检查。明确说明 run 的局限（seed、split 大小、它没有证明什么）。
2. **比较（轻量）**：若步骤 0 找到同级 run，只从其报告或日志提取 §5 标准点名的 headline 指标，与当前 run 并列成表；用一行说明数值相对哪个 run 向何方向变化。**不要**把差异归因于某个原因：解释某个变体*为何*胜出需要本 skill 不会运行的受控比较。若用户需要下一变体，推荐 `$star-plan-executor`。

### 步骤 6：持久化报告

填写 `assets/expt_analysis_template.md`（中文：`assets/expt_analysis_template_zh.md`；报告遵循计划 frontmatter 的 `language`，否则遵循对话语言）：范围与证据基础、结论、完成标准记分卡、工件与完成度、日志健康、指标与比较（含图表）、解释、建议与转交。写入 `wkdrs/<run>/EXPT_ANALYSIS_<YYYY-MM-DD>.md`。只用真实日期，绝不编造；同一天对同一 run 的第二次分析覆盖原文件，之后日期的分析写自己的文件。

**run 结论**只能是 `met` / `partially met` / `not met` / `inconclusive`（缺少证据，例如 STOP-line 命令未运行）/ `invalid`（结果存在但不可信，例如泄漏、崩溃的 run 却标为 done、指标来自错误 split）。选择诚实结论；`inconclusive` 和 `invalid` 都是有效答案，不是未能得出结论。

### 步骤 7：摘要与转交

以结论开头，控制在约 400 词以内：run 结论和 §5 记分卡各一行、任何 blocker/major 观察、带来源的 headline 指标、存在时的同级比较，以及图表位置。随后按维度 F 转交：未完成步骤或等待中的 STOP-line 命令 → `$star-plan-executor <slug>`；§5 已满足 → `$star-plan-executor <slug>` 验证并 finalize（它拥有 `exec_status`）；计划文本不再真实 → `$star-plan-reviser <slug>`；命中 kill-criterion 或声明被证伪 → `$star-plan-reviser`（依据证据修订）/ `$star-plan-coach`（重新审视方法与风险）/ `$star-plan-decomposer`（重新界定范围）；日志暗示代码 bug → `$star-code-reviewer <slug>`；import 错误或环境损坏 → `$star-env-builder`。最后给出报告路径。

### 步骤 8：汇总（仅 aggregate 模式）

按 `references/aggregate_spec.md` 编译总账：解析范围内的 leaf；每个 leaf 取最新的 `EXPT_ANALYSIS_<date>.md`（没有报告 → 记录缺口并转交，绝不读取原始结果）；**每个数值进入总账前，都要重新打开其引用来源并确认**——报告需要验证，并非复制许可；依据根计划 §4 的 claim→experiment 映射和 ablation 设计分组，绝不按 run 树分组；把 `invalid` / `inconclusive` run 和复核失败项连同理由排除到 §5，同时把 `not met` run 保留在表格中。填写 `assets/results_template.md`（中文：`assets/results_template_zh.md`）并在写入门后生成 `metds/results.md`：已有 `type: results` 文件需要先批准变更列表；手写文件绝不只凭 diff 覆盖。

摘要 ≤400 词：汇总/排除/仍未测量的 run 数、headline 表格和转交——缺报告交给 `$star-expt-analyst <slug>`，未执行 leaf 交给 `$star-plan-executor <slug>`。明确说明总账只报告数值，不解释数值：判断变体*为何*胜出需要本 skill 不会运行的受控比较。

### 步骤 9：观察（仅 watch 模式）

快速健康检查一个可能仍在执行的 run——只包含维度 C 和存活性，不含其他维度。仅在聊天中输出：无结论、无报告文件、无图表；可按需重复运行。

1. 按步骤 0 解析 run。没有 run 目录或其中尚无日志 → 说明并停止；没有可观察内容。
2. 扫描日志中的维度 C 致命、数值和动态信号（crash、traceback、NaN/Inf、OOM、发散、平台期）——grep 模式并读头尾，绝不整体读取大日志。
3. 存活性与进度：最新日志/工件的 mtime（“上次写入在 N 分钟前”），以及最新进度行——step / epoch / eval 及其数值，按日志原文引用。
4. 报告 ≤200 词，以存活性开头：仍活跃还是从何时起停滞、最新进度行、任何致命或异常信号及其 `file:line`，再给一个后续行动——继续等待；致命信号 → 停止任务，通过 `$star-plan-executor <slug>` 修复并重启；import 或环境错误 → `$star-env-builder`。明确说明尚未对 run 评分：结束后由完整流程（`$star-expt-analyst <slug>`）评分。

## 状态规则

- 唯一写入是 `wkdrs/<run>/EXPT_ANALYSIS_<YYYY-MM-DD>.md`、渲染图表时的 `wkdrs/<run>/analysis/`（`.png` 文件及生成脚本），以及——仅 aggregate 模式——`metds/results.md`。其他任何位置都不写。watch 模式完全不写入——全部产出就是聊天摘要。
- 绝不触碰：`metds/plans/*`——包括 `exec_status`、`exec_runs` 和 `updated`（标准已满足时只向拥有 finalize 权限的 `$star-plan-executor` 提建议）；`wkdrs/<run>/EXEC_PLAN.md` 和 `EXEC_LOG.md`（executor 日志是证据，不是草稿——这里发现的 Strategy signal 只报告并转交，不写回日志）；`${CODE_NAME}/`；`metds/codearc.md`；`UPSTREAM.md`；`.env`。
- 绝不移动、重命名或删除任何工件、日志或 checkpoint——run 目录是证据基础，分析绝不改变自己的证据。
- 所有命令都通过 `.env` 的 conda 环境运行；不用系统 Python；绝不安装或升级包。解析片段以内联方式运行；唯一留在磁盘上的脚本是 `analysis/` 下图表自己的绘图脚本。
- 不做重任务：不训练、不运行评估、不做全数据集遍历、不调用高成本 API——executor 的 STOP line 同样适用。若取得指标需要运行任务，则该指标是 `unmeasurable`；把准备好的命令交还用户。
- Git：只读；本 skill 从不提交（约定 §1）。
- 本 skill 不设置计划 frontmatter，也不创建 run 目录；其审计轨迹是报告文件。
- 工作流要求提问时，一次只问一个直接问题（分析哪个 run、处理歧义匹配），并要求明确答复。由于本 skill 不在自己的报告之外写入，因此没有审批门——也正因如此，绝不陈述或暗示已更改计划、状态或日志。报告遵循计划 frontmatter 的 `language`，否则遵循对话语言。
