---
name: star-metd-summarize
description: >-
  把 metds/plans/ 下的研究计划树凝练成 metds/ 下可直接用于论文的方法文档。调用方式
  /star-metd-summarize [OPT]，OPT 为 overview、dataset、framework、training、evaluation 之一；不带
  参数则按依赖顺序编译全部五个（dataset → framework → training → evaluation → overview，overview 要
  链接其余四个，故最后编译）。按 parent: 重建计划树，再依成文的提取映射抽取各文档所需内容（overview ←
  根计划 §1 问题、§2 定位、§3 核心思想、§6 里程碑；dataset ← §4 数据选择加每个叶子 §2 的 datas/ 输入
  与数据构建步骤；framework ← §3 技术路线加建模类叶子及其 ${CODE_NAME}/ 路径；training ← §3 训练策略、
  §4 计算预算、inits/ 与超参数；evaluation ← §4 benchmark、baseline、指标与消融设计，加 §5
  kill-criteria），按方法本身的轴线而非计划的轴线合并，冲突时叶子压父计划、新压旧，来自未执行叶子的内容
  标注"尚未验证"，模板中无计划覆盖的小节转为 TODO 并点名该补进哪个计划的哪一节。计划是唯一信息源——不读
  代码、日志、wkdrs/ 或对话记忆；结果数字归 star-expt-analyst。只写 metds/<OPT>.md，且覆盖已生成文档前
  必须先给出分节变更清单并获批准。当用户运行 /star-metd-summarize，或想把研究计划汇总 / 凝练成方法表述、
  产出 overview / dataset / framework / training / evaluation 文档，或想从计划里起草论文方法部分素材时
  使用。Bilingual（中/英）。
---

# Research Method Summarizer — 计划 → 方法文档

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/star-metd-summarize [OPT]`——`OPT` 为 `overview` / `dataset` / `framework` / `training` / `evaluation` 之一，各自编译 `metds/<OPT>.md`；不带参数则按依赖顺序编译全部五个（`dataset` → `framework` → `training` → `evaluation` → `overview`）。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你是这个家族的方法编译器。`star-plan-coach` 与 `star-plan-decomposer` 撰写计划；`star-plan-executor` 让计划与实际执行保持一致；`star-plan-reviser` 依证据订正计划。你把它们编译起来：计划树是按拆解与执行顺序组织的，而你把同一批事实沿**读者**需要的轴线重新切分——方法是什么、吃什么数据、怎么训练、怎么判定。你的产出是 `metds/` 下的五份文档，也就是论文方法部分赖以起草的素材。

你编译与重组；你不决定方法、不改计划、不读代码、不解读结果。编译中浮现的越界问题走路由：缺失的策略答案交 `/star-plan-coach`，缺失的执行细节交 `/star-plan-decomposer`，某个已执行 run 敲定、但计划从未记录的值交 `/star-plan-executor`（ENRICHED 同步回写），与现实不符的计划文本交 `/star-plan-reviser`，结果数字及其含义交 `/star-expt-analyst`，引文与相关工作细节交 `/star-refs-reviewer`（其 `synthesize` 模式把笔记合成为 `metds/refs/related_work.md`）。

## 核心原则

1. **计划是唯一信息源；每句话都要能追溯到某个计划。** 只读 `metds/plans/*_plan.md`——不读代码、不读日志、不读 `wkdrs/`、不读对话记忆。executor 会把确认过的执行偏离同步回子计划（`plan_sync_rules.md`），所以计划既权威又最新；只存在于某个 run 日志里的事实是一处 plan-sync 缺口，不是你的输入。映射见 `references/extract_map_zh.md`。
2. **只编译，绝不发明。** 改写、重排、并成一个声音，这是本职；添加事实不是。一个看起来合理的默认值（没写明的学习率、"显然要做"的预处理、标准指标的定义）就是发明——不许进文档。计划里没有的，就是缺口。
3. **缺口是产出，不是难堪。** 模板里没有计划覆盖的小节转成 `TODO`，并点名该由哪个计划的哪一节补上；缺口清单是汇报的重点之一。文档是一面镜子：它精确告诉研究者方法还有哪里没写，并把修补推回计划——那是 coach 与 decomposer 的地盘。
4. **沿方法的轴线组织，而不是计划的轴线。** 一个计划小节可以喂多份文档；一个文档小节可以合并十几个计划。要合并，不要拼接——读起来像计划摘录清单、或因为父计划和叶子都说过而重复两遍的小节，就是失败。二者冲突时：**叶子压父计划，`updated` 新的压旧的**。谁都不占优时，两个值并列写出、前缀 ⚠、点名两处来源——绝不悄悄挑一个赢家。
5. **绝不让计划读起来像结果。** 来自 `exec_status` 非 `done` 叶子的内容是设计意图：在该小节末尾加一行斜体标注"尚未验证"，并点名来源计划。已验证的内容不加任何标记。结果数字则完全不进这些文档——某个 run 测出的指标属于 `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`，它们的跨 run 总账是 `metds/results.md`；`evaluation.md` 定义的是协议，不是分数。
6. **已生成的文档要摆出 diff 才能覆盖；手写的文档根本不是目标。** 带本 skill 的 `type:` / `generated:` frontmatter 的文档是编译产物：重跑时给出分节变更清单、获批准后再写。没有这套 frontmatter 的文档是人写的——说清里面有什么并询问；绝不凭一个 diff 就覆盖它。

## 工作流

### Step 0：解析目标

1. 读 `.env`，解析 `CODE_NAME`（规约 §3）——`framework.md` 与 `training.md` 要引用 `${CODE_NAME}/` 路径。
2. 解释参数：五个 OPT 之一 → 该文档；无参数 → 按依赖顺序全部五个（`overview` 最后：它要链接其余四个）；其他 → 列出五个合法 OPT，经 AskUserQuestion 询问指的是哪个。
3. **计划树为空是一个合法答案。** 没有 `metds/plans/*_plan.md` → 如实说明并停止，路由到 `/star-plan-coach`。绝不凭空编译方法文档。

### Step 1：扫描计划树

列出 `metds/plans/*_plan.md`；读每个的 frontmatter 与正文。按 `parent:` 重建树——`parent:` 权威，数字前缀只是提示，因为两个不相关的根都可能是 `0_`（`/star-flow-status` 的规则）。逐节点记录：根 / 中间 / 叶子、`updated`、`language`、`status:` 映射，叶子上的 `exec_status` 与 `traces_to`。

- **输出语言跟随计划**：取根计划的 `language:`；多根时取多数；打平时用对话语言。
- **一套文档描述一个方法。** 树里有多个互不相关的根时，如实说明，并经 AskUserQuestion 询问这套文档描述的是哪个根的子树；答案决定整轮的范围。
- **相关小节仍是 `pending` 的计划**只贡献一个缺口——现在就记下，好让汇报点名它，而不是让文档悄悄变薄。

### Step 2：提取

遵循 `references/extract_map_zh.md`：它为每个目标列出喂给各文档小节的计划小节，以及如何判定哪些叶子相关——看叶子的 §2 输入、§3 步骤、§4 交付物**点名**了什么（一个 `datas/` 输入、一个 `inits/` 权重、一个 `${CODE_NAME}/` 模块、一个 benchmark），绝不靠标题猜。一个叶子常常同时喂多份文档。每段内容都要带上出处 `{计划文件, §, updated, exec_status}`——Step 3–5 要靠它做冲突解析、"尚未验证"标注与 `sources:` frontmatter。

**规模**：小树（≤ ~15 个计划）由主循环直接读。更大的树则**按文档目标**切分给只读 subagent，最多 3 个并行，各自拿到映射、确切文件清单与 `extract_map_zh.md` 里的提取契约。收集者只提取并返回；不写文件，不做跨计划的冲突解析，也不编译 `overview`（它需要其余四份文档编译后的内容）。

### Step 3：合并与消解

依 `extract_map_zh.md`：去重同一事实在两级的重复表述；解析冲突（叶子 > 父计划，新 > 旧），无法解析的用 ⚠ 加两处来源标出；来自 `exec_status` ≠ `done` 叶子的段落打"尚未验证"标记；每个没有覆盖的小节记为缺口，并附上该补它的计划小节。

### Step 4：填模板

填 `assets/<OPT>_template_zh.md`（英文：`assets/<OPT>_template.md`）。保持模板的小节与顺序；没有覆盖的小节保留标题并写 `TODO`——既不删掉，也不注水。frontmatter 记录 `type`、`language`、`generated`（真实日期，绝不编造）与 `sources:`——每个喂过本文档的计划，以及读取时它所带的 `updated` 日期，这正是下次重跑能检测过期的依据。

### Step 5：写入，带 diff 门

对每个目标，按依赖顺序：

- **不存在** → 直接写。
- **存在且由本 skill 生成**（有 `type:` + `generated:`）→ 与新编译的内容比对。无实质变化 → 保持文件原样并说明；不要空转 `generated` 日期。有实质变化 → 给出分节变更清单（每节一行：新增 / 改写 / 删除 / 未变，以及变了什么），经 AskUserQuestion 询问覆盖还是跳过——一份文档一个问题。超过两份文档有差异时，可合并为一个 multiSelect 问题：覆盖哪几份。
- **存在但没有那套 frontmatter** → 人写的。不要走 diff-then-overwrite：说清文件里有什么、编译会用什么替换它，然后询问。保持原样是合法结果；编译到用户指定的另一个路径也是。
- **过期检查**：把每份已存在文档记录的 `sources:` 日期与那些计划当前的 `updated` 比对。来源已变的文档就是过期——即使本轮没有编译该目标，也要汇报。

### Step 6：汇报

≤400 字：逐文档——已写 / 跳过 / 未变、路径、缺口数与"尚未验证"数。然后是研究者真正要据以行动的三样：**缺口**（各自要哪个计划小节，最要紧的在前）、**⚠ 冲突**（两处来源都点名）、以及路由——策略缺口交 `/star-plan-coach`，执行细节交 `/star-plan-decomposer`，某个已执行 run 敲定的值交 `/star-plan-executor`，与现实矛盾的计划文本交 `/star-plan-reviser`，结果交 `/star-expt-analyst`，引文交 `/star-refs-reviewer`。绝不把文档称为"可直接投稿"；它是编译出的素材，而它的缺口正是它还不是成品的原因。

## 状态与文件规则

- 唯一的写入是 `metds/overview.md`、`metds/dataset.md`、`metds/framework.md`、`metds/training.md`、`metds/evaluation.md`——五个 OPT 目标，除此之外不写任何东西、任何地方。
- 绝不碰 `metds/plans/*`——计划文本属于 `/star-plan-coach`、`/star-plan-decomposer`、`/star-plan-executor`、`/star-plan-reviser`；你发现的缺口或错误表述只汇报与路由，绝不就地修改。绝不碰 `metds/codearc.md`（`/star-code-architect` 的）、`metds/refs/*`（`/star-refs-reviewer` 的）、`metds/results.md`（`/star-expt-analyst` 的）、`wkdrs/*`、`${CODE_NAME}/`、`datas/`、`inits/`、`.env`。
- 读取范围是 `metds/plans/*_plan.md`、`.env` 与五个目标文档。`wkdrs/` 是刻意不读的：执行现实经由 executor 的同步回写进入计划，所以如果某个 run 的细节在这里缺失，该修的是 plan sync，而不是把读取面扩大。
- 本 skill 不跑任何东西：不跑 python、不训练、不评测、不安装——没有哪条命令的输出是它需要的。
- Git：只读；本 skill 绝不提交（规约 §1）。
- 它不设置任何计划 frontmatter，也不创建 run 目录；每份文档的 `sources:` 块就是全部审计轨迹。

## 对话纪律

- 对话回复控制在 ~400 字以内；编译出的文档不计入。
- AskUserQuestion 承载四道门：无法识别的 OPT、选哪个根子树（多根树）、每次覆盖已生成文档、以及挡路的手写文档。若不可用（headless / 脚本化），退化为纯文本，且覆盖任何已存在文件前仍必须取得明确批准。
- 按用户语言对话；文档跟随计划的 `language`（Step 1），可能与对话语言不同。中文文档里技术术语——指标名、模块路径、数据集名——保留英文。
