# 通俗化改写对照表

STAR 全仓库术语改写的执行契约。中英两侧同改。

**来源：** 5 个只读调查员分别扫 `SKILL_zh.md` / `references/*_zh.md` / `assets+docs` / `SKILL.md` / `references+docs(en)`，结果去重合并，计数经手工复核。

**适用范围：** `.claude/skills`、`.agents/skills`、`.cursor/skills`、`.kimi-code/skills` 四棵树 + `docs/mds/star-workflow/` + `README*.md`。

**验证：** 每一波改完跑 `bash .github/scripts/check_consistency.sh`，必须全绿（check 11 校验三棵树标题结构一致）。

**已定的三条口径：**
1. ledger 三名统一为**结果汇总表 / 模型记录表**（英文 results table / model record file，文件名 `MODEL_LEDGER.md` 不动）。
2. strategic 统一为**总体计划 / 方向性信号**（英文 top-level plan / plan-level finding）。
3. **只改挡路的比喻，保留文风。** 判据：不懂这个词就不知道该干什么的（涟漪图、水位线、coverage band、飘红）一律改；纯修辞但操作说明就在同一句里的（引桥、last mile、on-ramp、记时者）保留。

---

## 0. 绝不改动（先看这一节）

改了会破坏功能或丢失触发能力。

**写进文件的字面枚举值** —— 中文行文里也保持英文原样：
`keep in place`、`move` / `merge` / `route`、`plan-referenced`、`tier: report-backed|provisional`、
`ADDED` / `MODIFIED` / `REMOVED` / `ENRICHED`、
`exec_status` 的取值（`pending`/`in_progress`/`done`/`blocked`/`skipped`/`abandoned`）、
`finalized:`、`traces_to`、`depends_on`、`model_trail`、`covers.through`、`exec_runs`、`children`、`parent`、
`severity: blocker | major | minor | nit`（`blocker` 是严重度标签，**不是**可以翻译的行文用词）、
`MODEL_LEDGER.md` / `type: model_ledger` / `ledger` 模式名、
`full` / `append` / `verify` / `organize` 等模式取值

**跨 skill 的字面标签** —— 一处改了，读它的地方必须同步改：
`**Plan-level finding**`（原 `**Strategy signal**`）由 executor 写入 `EXEC_LOG.md`，
由 `star-flow-status/scripts/scan.sh` 与 `star-expt-digest/scripts/scan.sh` 按字面 grep。
本次改名后 scan.sh 已同时匹配新旧四种写法，使用户仓库里已有的 `EXEC_LOG.md` 仍能被索引。

**标准术语** —— 本来就通用，改了反而更差：
leaf / 叶子、DAG、frontmatter、commit / 提交、run、skill、subagent、rubric（英文侧）、
冒烟测试、backfill、kill-criterion、done-criterion、provenance、
门槛、基线、线性、时间线、管线、落盘

**description 里的触发关键词** —— 改写描述时必须原样保留：
`README`、`brainstorm`、`头脑风暴`、`backfill`、`watch`、`aggregate`、
`reference implementation`、`scaffold`、`refactor`、`conda env`、`venv`

---

## 1. 中文：错译与语义错误（必改）

| 现有 | 次数 | 改为 | 说明 |
|---|---|---|---|
| 飘红 | 1 | 大面积缺失 / 大片标红 | **语义正好相反**：中文（股市/报表）"飘红"＝情况好，原文指状况糟 |
| 活性 | 4 | 是否还在运行 / 存活情况 | liveness 误译成化学"活性" |
| 平台化 | 1 | 进入平台期 / 不再提升 | plateaued 误译成商业"平台化" |
| 字形 | 8 | 状态符号 | glyph 误译成排版"字形"；✔ ◐ ○ ⊘ 不是字 |
| 自审线 | 5 | 自审行 | line 此处指"一行输出" |
| 抬头 | 3 | 文件头 / 开头说明行 | 中文"抬头"是发票收件栏 |
| 词干 | 2 | 共同前缀 | stem 误译成语言学术语 |
| 单测量级的命令 | 1 | 单元测试量级的命令 | 断句歧义 |
| 越阈 | 1 | 越过阈值 | 生造缩略 |
| 裸写 | 1 | 直接写出 | 不成词 |
| 保持窄 | 1 | 只管一小块 | 形容词误用 |
| 化了妆的 Park | 1 | 变相搁置 | 英文词 + 直译 |

## 2. 中文：一物多名（统一）

| 现有并存写法 | 次数 | 统一为 |
|---|---|---|
| 台账 / 总账 / 账本 | 34 / 32 / 28 | **结果汇总表**（`results.md`）、**模型记录表**（`MODEL_LEDGER.md`） |
| 战略 / 策略（同一个 strategic） | 56 / 49 | **总体计划**（strategy plan）、**方向性信号**（strategy signal） |
| 修复 pass / 修复轮 | 14 / — | **修复轮** |
| 誊写 / 转录 / 抄录 / 原样抄 | 4 / 15 / 6 | **原样转录** |
| 审计痕迹 / 审计线索 | 5 / 3 | **审计线索** |
| 回环 / 循环 | 4 / — | **循环** |
| 数据通路 / 数据流 | 4 / 4 | **数据流** |
| 差距清单 / 缺口 | 1 / 81 | **缺口清单** |
| 收集器 / 收集者 | 11 / 3 | **收集器** |
| claim / 主张 / 声明 | 76 / 22 | **主张** |
| blocker / 阻塞 / 阻断项 | 38 | **阻塞项** |
| 交接物 / 交付物 | 1 / — | **交付物** |
| 有界重试 / 有限重试 | 2 / 2 | **有限重试** |

## 3. 中文：直译比喻（读不通）

| 现有 | 次数 | 改为 | 备注 |
|---|---|---|---|
| 点名 | 153 | **写明** / 指明 / 列出 | 按语境三选一；主语是文件用"写明"，动作是挑出用"指明" |
| 路由 | 73 | **转交** / 转给 | |
| 提升（promote 义） | 49 | **收编** / 移入 | 只改"把文件搬进代码库"义；指标变好的"提升"保留 |
| 契约 | 30 | **格式约定** / 返回格式 | |
| 阶梯 | 30 | **优先顺序**（安装/抓取）/ **分级**（严重度/核实） | 按语境二选一 |
| 喂 / 喂回 | 27 | **输入给** / 回传 | |
| 头条 | 26 | **关键指标**（metric 义）/ **核心结论**（小节名） | |
| 发布面 / 关注面 / 运行面 | 20/3/1 | **对外发布的部分** / 关注点 / 启动方式 | |
| 水位线 | 17 | **上次覆盖到的日期** | |
| 报告支撑 | 16 | **有分析报告依据的** | |
| 廉价 | 13 | **低开销** / 轻量 | 中文"廉价"带贬义 |
| 准绳 | 13 | **评判依据** / 检查项 | |
| 落笔 | 12 | **已写入** | |
| 奠基 | 12 | **搭建** / 初始化 | "奠基代码库"动宾不通 |
| 指针（指文档） | 12 | **索引** / 跳转说明 | 避免与 C 指针混淆 |
| 临时（provisional 义） | 11 | **未核实** | 原义是"没核实过"，不是"随手跑的" |
| 落位 | 10 | **确定去处** | `计划组件落位映射` → `计划各组件对应的代码路径` |
| 载荷 | 10 | **抓取到的原始内容** | |
| 拥挤度 | 8 | **竞争激烈程度** | |
| 涟漪图 / 涟漪意识 | 8 | **影响范围** / 连带影响 | |
| 基座 | 8 | **文献基础** | |
| 真源 | 7 | **唯一依据** | |
| 定日期 | 7 | **判定日期** | |
| 从句 | 6 | **半句话** | "用一个从句"无法执行 |
| 记号（token 义） | 6 | **这个写法** | |
| 消费（consume 义） | 5 | **读取** / 依据 | |
| 播种（seed 义） | 5 | **以…为起点生成** | |
| 反馈回流 | 5 | **向上反馈** | |
| 有界 | 5 | **有限次** / 范围受限 | |
| 触达 | 4 | **接通** / 指向 | |
| 残渣 | 4 | **残留** | `移动残渣` → `搬移后的残留引用` |
| 扇出 | 4 | **并行分派** | |
| 薄指针 / 常驻指针 | 4 | **一小段指路说明** | |
| 分线 / 本线 / 跨线 | 4 | **分组** / 本组 / 跨组 | lane，避免与管线/时间线撞 |
| 归宿 | 3 | **去处** | |
| 爆炸半径 | 3 | **影响范围** | |
| "过好"检查 | 3 | **结果好得反常的排查** | |
| 挂回 | 3 | **对应回** | |
| 报告形文件 | 3 | **形似报告的文件** | |
| 逃生选项 | 2 | **兜底选项** | |
| 承重的公式 | 2 | **关键公式** | |
| 保险丝 | 2 | **兜底检查** | |
| 招式 | 2 | **发散手法** | |
| 无损接入 | 2 | **不改动原有内容地接入** | 避免与"无损压缩"混 |
| 回灌 | 2 | **写回** | |
| 同门契约 | 1 | **对应的规范** | |
| 在盘 | 4 | **在磁盘上是否存在** | |
| 主循环 | 36 | **主 agent** | 指跑 skill 的本体，不是程序循环 |
| 生产者 | 17 | **产出方** | |
| 机械（mechanical） | 14 | **纯格式不改行为的**（修复）/ **基础配置**（设置） | |
| 归拢 | 9 | **收集** | |
| 赌注 | 10 | **关键假设** | |
| 平台/其他单点比喻 | — | 逐句改写 | 引桥、记时者、阵容、决赛方向、块头、旗子、不问自答、睁着眼批准 |

## 4. 中文：夹用英文（有现成中文词）

| 现有 | 次数 | 改为 |
|---|---|---|
| finding | 55 | **问题项** |
| rubric | 52 | **评分表**（首次出现可括注 rubric） |
| Park | 20 | **搁置** |
| delta | 16 | **变更项**（改动义）/ **差值**（数值义） |
| drift | 11 | **失配** |
| secret | 9 | **密钥与凭据** |
| closest works / why now | 12 | **最接近的工作** / **为什么是现在** |
| delegate（名词） | 7 | **子代理** |
| sanity 检查 | 6 | **合理性检查** |
| smell | 4 | **可疑写法** |
| scratch | 4 | **草稿文件** |
| greenfield | 4 | **空代码库（从零起步）** |
| checkpoint（动词） | 3 | **记入** | 名词的模型 checkpoint 保留 |
| vendor（动词） | 2 | **把第三方源码拷进仓库** |
| surgical | 2 | **精准克制** |
| tie-break | 1 | **打平时的取舍依据** |
| Chats end, files do not | 1 | **对话会结束，文件不会**（漏译） |

## 5. 英文侧

| 现有 | 次数 | 改为 |
|---|---|---|
| ledger / ledgered (v.) | 153 | 名词 → **results table**（`results.md`）/ **model record file**（`MODEL_LEDGER.md`，文件名不动）；动词 → **record** |
| strategy plan / strategy signal | 33+ | **top-level plan** / **plan-level finding** |
| surface | 61 | 动词 → **report**；`release surface` → **the files a reader will open**；`run surface` → **launch entry point**；`test surface` → **existing tests** |
| main loop | 34 | **the main agent** |
| strategy signal | 33 | **plan-level finding** |
| land / landed | 33 | **finished** / **writes** / **is in place**（按义） |
| …boundary（write/read/fix/…） | 31 | **what it may write** / **what it never writes** |
| ladder | 29 | **install order** / **priority order** / **search order** / **severity levels**（按义） |
| owed / owes / debt | 27 | **outstanding follow-up** |
| collector (delegate) | 26 | **read-only subagent** |
| residual | 21 | **names left unchanged on purpose** |
| sync-back | 19 | **write the change back into the plan** |
| lane | 18 | **area** |
| crowdedness | 18 | **how crowded the area is** |
| artifact registry | 17 | **output table** |
| rollup | 16 | **summary counts**（status）/ **summary of the children**（reviser）/ **combined table**（digest） |
| watermark | 16 | **last covered date** |
| involve dial | 15 | **involve level**（`.env` 里本来就是三档，没有"旋钮"） |
| yardstick | 13 | **review rules** |
| coverage band | 15 | **follow-up checks** |
| self-audit line | 12 | **unrecognized-files line** |
| forest | 11 | **all plan trees** |
| coarse | 11 | **too big to run** |
| bound check | 10 | **the step's own check** |
| glyph | 8 | **status symbol** |
| ripple map | 8 | **knock-on effects** |
| code home | 8 | **a place for the code to live** |
| price (v.) | 7 | **show what it would cost** |
| cadence | 6 | **periodically** |
| feedback reflux | 5 | **route it back to the plan** |
| carve-out | 5 | **one exception** |
| revive-when line | 5 | **a note on what would make it worth revisiting** |
| greenfield | 5 | **empty codebase** |
| clobber | 4 | **overwrite** |
| fuse | 3 | **the check that catches registry drift** |
| blast radius | 3 | **how far the change reaches** |
| load-bearing | 3 | **the formulas the method depends on** |
| thin pointer | 2 | **a short cross-reference** |
| legible | 2 | **understandable to an outsider** |
| harness（实验义） | 2 | **experiment setup** |
| keep-set | 1 | **which directions to keep** |
| concern lane | 1 | **one per topic** |
| re-cut | 1 | **reorganize** |
| "the tree is the engine" | 1 | 删掉格言，保留后半句实义 |
| "the family's last mile" | 1 | **the last step before the work goes public** |
| "You are the on-ramp" | 1 | **You get an existing project set up; you don't run it** |
| "Smoke the new packages" | 1 | **Smoke-test only the new packages** |

## 6. 英文词汇表 §0 的定义重写

术语保留但一句话定义要改写（现在是名词堆叠）：

- `strategy plan` → 定义改为 "the plan `star-plan-coach` writes, covering problem through milestones"
- `finalized:` → 点名是哪三个 skill（decomposer / architect / metd-summarize）
- `exec_status:` → "terminal" 改成 "final: nothing more is needed on that leaf"
- `traces_to` → "which claim in the root plan this sub-plan supports"
- `depends_on` → "the prefixes of sibling plans that must finish first"
- `model_trail` → "one line per writing session, added never edited"
- `collector delegate` → 整行改为 `read-only subagent`

并补进词汇表（现在正文当术语用却没定义）：`coverage band`→`follow-up checks`、`self-audit line`、`rollup`、`strategy signal`、`watermark`、`bound check`、`main loop`

---

## 7. 执行记录

**做法：** Phase A 用 `rewrite.sh` 跑无歧义的 1:1 替换（约 190 条规则，四棵树 + docs + README 一起），
Phase B 派 6 个 subagent 按文件集切分处理一词多义的部分（每个 agent 独占若干 skill 的全部四棵树，避免并发写冲突）。

**规模：** 554 个文件，+5598 / −5567 行。

**踩过的坑（复用本脚本时注意）：**
1. bash 3.2 不支持 `[[:ascii:]]` 字符类，该测试静默失败会让所有 ASCII 规则丢掉词边界保护
   （`Park` 因此改坏了 `Parked`）。已改为显式可打印 ASCII 范围判断。
2. perl 处理中文模式必须带 `-Mutf8`，否则脚本源码里的 CJK 模式一个都匹配不上（静默返回 0）。
3. `rubric` 出现在文件名 `review_rubric_zh.md` 里；无保护的替换会把反引号里的路径改坏。
   验收方式：遍历所有反引号 `references/…` 路径，确认文件真实存在。
4. 把带空格的英文词换成中文词会留下 `按六维 评分表 打分` 这类多余空格，需要单独一轮清理。
5. 子串陷阱：`在盘上`→`在磁盘上上`、`确定日期` 含 `定日期`、`集群节点名` 含 `点名`。

**验收：** `bash .github/scripts/check_consistency.sh` 全部 13 项通过；
所有反引号资源路径可解析；`scan.sh` 语法通过且四棵树字节一致。
