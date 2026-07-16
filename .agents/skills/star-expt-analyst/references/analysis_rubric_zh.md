# 实验分析 Rubric

一个 run 如何被检查、记录什么、判定如何得出。每个 run 都过全部维度：A 与 B 说明存在什么，C 说明这个 run 可不可信，D 对照计划打分，E 说明它意味着什么，F 说明下一步归谁。一条观察必须给出维度、严重度、来源和影响——没有文件支撑的评论是印象，不是观察。

下文以 §n 引用的项目守则是 AGENTS.md 的编号章节；*计划*的 §1–§6 指子计划自己的章节。技能名裸写（`star-plan-executor`）；按当前工具调用技能的方式调用它们。

## 观察契约（结构化返回）

一条观察一个条目，按维度分组：

```yaml
- dimension: A | B | C | D | E
  severity: blocker | major | minor | nit
  source: <相对项目根的路径，+ 行号或键名>
  observation: <一句话——什么是真的>
  evidence: <引用的那行、那个数字，或 `ls` 的事实>
  implication: <这对 run 的判定意味着什么，一句话>
```

## 指标行契约

一条被打分的预期一个条目——记分卡就由它填充：

```yaml
- criterion: <计划的原话，引用>
  origin: sub-plan §5 | parent §4 | parent §5 kill-criterion | stated baseline
  metric: <来源打印出的名字>
  value: <来源打印出的原值——不要四舍五入成另一个判定>
  split: train | val | test | unknown
  threshold: <计划声明的阈值，或 "none stated">
  verdict: met | not met | unmeasurable
  source: <路径，+ 行号或 JSON 键>
```

收集器只返回这两个列表（外加 `files_read: <n>`），别的都不返回：不对 run 下判定、不做解读、不写文件。

## 严重度阶梯（观察）

- **blocker** —— run 的结果不可信或不可用：进程在产出结果前就死了、评测读了训练集、checkpoint 为空或损坏、日志里引用的指标在它所指的文件里根本不存在、完成判据所依赖的某个 §4 交付物缺失。
- **major** —— 实质改变解读：§5 判据未达标、训练出现 NaN/Inf、loss 发散、train↓/val↑ 背离、某条 STOP 线命令从未跑过、产物写在布局规则（§5）之外、指标只能从比计划暗示的更弱的来源拿到。
- **minor** —— 值得记录，不改变判定：可恢复的 warning 风暴、dataloader worker 死掉又重启、多出来一个没人承诺过的产物、指标报出的精度低于阈值所需。
- **nit** —— 细枝末节：产物命名不一致、日志没有时间戳。只在已经带有更高级别观察的 run 上报 nit。

严重度拿不准时，往低了判，并在 `implication` 里说明为什么。

## run 判定阶梯

只取一个，作为报告头条：

- **met** —— 每条 §5 判据都被检查且达标，且没有 blocker 级问题动摇它们。
- **partially met** —— 部分达标、部分未达标，但都检查过了。
- **not met** —— 判据检查过且未达标。这是一个真实的、可上报的结果。
- **inconclusive** —— 用来判断的证据根本不在：STOP 线命令从未跑过、run 提前停了、指标哪里都找不到。它不是 "not met" 的同义词——要说清缺的是哪份证据、什么能产出它。
- **invalid** —— 结果存在但不可信：泄漏、崩溃的 run 被标成 done、指标取自错误的 split。绝不把它软化成 "partially met"；invalid 的 run 是重跑，不是解读。

## A. 产物清点

- 每个 §4 交付物，按其声明的路径：`present` / `missing` / `unexpected`（在磁盘上，但哪里都没承诺过）。
- 按产物类型做轻量完整性检查：文件非空；JSON/CSV 可解析且含有计划点名的字段；checkpoint 既不是 0 字节，也不会小到与该架构不相称；图片能打开；目录里的文件数大致符合预期（例如每个保存的 epoch 一个 checkpoint）。
- 布局符合度（§5）：生成的输出在 `wkdrs/<run>/`、数据在 `datas/`、权重在 `inits/`；`metds/` 里和包内部没有留下生成物。
- 记录这个 run 在磁盘上的真实体积——研究者决定留哪些东西时需要它。

不算观察：正常 run 会留下的常规残渣（`__pycache__/`、`events.out.tfevents.*`、`.lock`、编辑器临时文件）；框架不问自答写出来的产物（config 快照、`latest.ckpt` 软链）。

## B. 完成度核实

- EXEC_LOG 里每个标了 `done` 的步骤：它点名的产物存在吗？与该步骤声称产出的东西相符吗？`done` 而产物不存在是 **blocker**——日志对现实的描述是错的。
- 每条 "Awaiting user" STOP 线条目：`用户已跑`（它承诺的输出存在）还是 `仍待跑`（不存在）。绝不因为时间过去了就假定它跑过了。
- EXEC_LOG 的 frontmatter `status` 与它自己的步骤行：日志写 `done` 却有 `blocked` 行，或写 `in_progress` 却每行都 `done`，这种不一致值得一条 minor 观察。
- 未同步的 "Pending amendments"，以及任何记录在案的 **Strategy signal**：带进报告——那是 executor 自己留下的"计划与现实已经分叉"的记号。

规则：日志是声明，磁盘是证据。核实沿这个方向做，绝不反过来。

## C. 日志健康

扫描这个 run 写下的每份日志（`*.log`、stdout 捕获、`wkdrs/<run>/` 下的框架日志）。

**致命信号**（blocker）：traceback；`CUDA out of memory`；`Killed` / OOM-killer；记录在案的非零退出码；终结了 run 的 NCCL / 分布式超时；日志在某个 epoch 中途截断、没有完成标记，而该步骤却声称 `done`。

**数值信号**（major）：loss 或梯度里出现 `nan` / `inf`；loss 从第一步起就是平的（什么都没在学）；loss 发散；梯度 overflow 刷屏且再没恢复；指标在每个 epoch 完全相同（权重被冻住，或评测压根没重跑）。

**动态信号**（major 或 minor，按差距的严重程度）：train loss 在降而 val loss 在升（过拟合）——说明从第几个 epoch 开始；val 指标在 run 结束前很久就已平台化（算力浪费，或学习率有问题）；指标在中途见顶，而被 checkpoint 下来的不是那个点。

**值得提一句的 warning**（minor）：dataloader worker 反复死掉重启；checkpoint 保存失败后重试；混合精度 overflow 警告；数据集规模悄悄小于计划 §2 所写。

不算观察：deprecation 警告、tqdm/进度条噪音、框架 banner 刷屏、计划本来就要求的 early stopping。

### 读大日志

绝不整体载入几 MB 的日志。按顺序：grep 上面那些致命与数值模式；读**头部**（config 回显——它记录了实际跑的是什么，包括 split、seed 和数据路径，泄漏也正是在这里露馅）；读**尾部**（最终汇总与指标）；再按 epoch 标记抽样中段以还原趋势。行号要引自真实文件，好让 Step 4 能重开它们。

## D. 指标 vs 预期

- 每个指标从可得的最权威来源提取，顺序为：run 写出的结果 JSON/CSV > 评测日志的最终汇总段 > TB event 文件（仅当 tensorboard 已安装）> 训练日志里最后一条匹配行。记下用的是哪一档；只能靠最弱一档才拿到的判据，值得记一条关于该 run 报告方式的 minor 观察。
- 每条准绳打成一个指标行：先 §5 完成判据，再父计划 §4 指标，再计划写明的任何 baseline。
- **split 纪律**：每个数字都要点名它来自哪个 split。若计划给了阈值却没说 split（"mAP ≥ 30"），报出计划 §5 上下文所暗示的那个 split 的数字，点明这处歧义，并且绝不挑那个好看的 split。
- **未声明预期**是一个合法的行：报出数字，`threshold` 留 `none stated`，不给它打分。不打分的数字是诚实的；倒推出来的阈值不是。
- **unmeasurable** 意思是这个数字磁盘上哪里都没有。说明什么能产出它，并把那条命令交还——绝不自己跑（见 STOP 线）。
- 数值按来源打印的原样引用。四舍五入到翻转判定（29.96 → "30，达标"）是 blocker 级的报告错误。

## E. 解读

- **对照主张**：子计划的 `traces_to` 点名了这个 run 服务于父计划的哪条主张或哪一节。如实说明结果是支持它、推翻它，还是让它悬着——"悬着"的话，还缺什么。
- **kill-criteria**：把结果对照父计划 §5 的 kill-criteria，以及计划称为廉价早期测试的任何 MVP 完成判据。命中就是**策略信号**：在报告里突出、路由出去（F），绝不软化。能早早杀掉一个坏点子的计划，是在起作用。
- **泄漏与"过好"检查**——接受一个强结果之前先跑这些：训练 config 的数据路径里点到了 val/test split 吗？val ≈ train 到了不合常理的程度吗？这个数字在第一次跑就超过了已发表的 SOTA 吗？指标是不是贴着天花板（1.000、100%）？checkpoint 是不是在它被报告的同一个 split 上选出来的？任何一条命中 → 在用户排除之前，判定就是 `invalid`。
- **把局限当局限写**：单 seed 不是显著性；子集不是 benchmark；没有 baseline 的指标不叫提升；单次 run 的差距若小于该框架已知的方差，就不算结果。写出这个 run *没有*显示什么。

## F. 路由

每个未决项映射到恰好一个归属；分析师自己除报告外什么都不写。

| 分析发现了什么 | 路由给 |
| --- | --- |
| 步骤未完成、某步 `blocked`，或 STOP 线命令仍待跑 | `star-plan-executor`（恢复该 run） |
| §5 判据已达标——该 run 需要终验与 `exec_status` | `star-plan-executor`（finalize 归它；分析师绝不翻状态） |
| 计划文本已不能描述实际做了什么、产出了什么 | `star-plan-reviser`（据证据修订，逐项批准） |
| 命中父计划 kill-criterion，或 `traces_to` 的主张被推翻 | `star-plan-reviser`（据证据修订）→ `star-plan-coach`（重审方法与风险）→ `star-plan-decomposer`（重新划分子计划） |
| 日志指向代码缺陷（bug、路径写错、指标接错） | `star-code-reviewer`（限定到本计划） |
| import 报错、CUDA 缺失、run 需要的包没装 | `star-env-builder` |
| 只有跑一次新 run 才能产出的指标 | 用户——一条备好的命令，绝不在这里执行 |
