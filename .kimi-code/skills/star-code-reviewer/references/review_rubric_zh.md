# 代码审查 Rubric

finding 如何形成、分级、返回。读代码本身，别只读名字：范围内每个文件过全部维度（F 仅计划模式）。一条 finding 必须给出维度、严重度、违反的规则、确切位置和具体修法——没有成文准绳支撑的抱怨是风格偏好，不是 finding。两个维度重叠时（unused import 既是 C 也是 E），只记一次，归入更具体的维度。

下文以 §n 引用的项目守则是 AGENTS.md 的编号章节；架构规则在 metds/codearc.md。

## Finding 契约（结构化返回）

每条 finding 一个条目，按文件顺序：

```yaml
- file: <相对项目根的路径>
  line: <首个受影响行>
  dimension: A | B | C | D | E | F
  severity: blocker | major | minor | nit
  rule: <违反的规则，如 "§6：禁止硬编码本地路径">
  issue: <一句话——哪里不对>
  evidence: <出问题的代码片段或一行引文>
  fix: <一句话的具体改法，或直接给出替换文本>
```

收集器只返回这个列表（外加 `files_reviewed: <n>`），不返回其他：不写散文结论、不动手修、不写任何文件。

## 严重度阶梯

- **blocker**——会弄坏东西，或违反项目硬约束：语法/导入错误、硬编码的机器本地绝对路径、写出到布局规则之外、改动了改名残留清单上的名称。
- **major**——以误导或劣化代码库的方式违反成文约定：§3 任务声称完成但代码缺失/不完整、§4 交付物不在、公共 class 没有 docstring、模块放置违反 codearc.md 的放置规则、无人要求的 speculative 功能或单用途抽象、已有 helper 覆盖的重复逻辑。
- **minor**——不产生误导的规范缺口：公共函数缺单行 docstring、不符 PEP 8 的命名、死分支、身兼数职的过长函数。
- **nit**——打磨项：复述显而易见内容的注释、同一文件内命名风格不一致。只对已有更高级 finding 的文件报 nit；nit 绝不主导一份报告。

严重度拿不准时往低定，并在 `issue` 里说明原因。

## A. Docstring 与注释

- 每个公共 class 有 docstring 说明职责；构造参数/属性不自明时一并说明。
- 每个公共函数/方法至少一行 docstring 说明做什么或返回什么；签名不平凡的按周边代码已用的风格（Google / NumPy / reST——绝不互相转换）写 Args/Returns。
- 暴露公共 API 的模块带模块级 docstring。
- 注释解释**为什么**（约束、不明显的决策），而不是下一行**是什么**；没有与代码矛盾的过期注释；没有被注释掉的代码块。

不算 finding：几行长、名字即文档的 `_private` helper；名字说明测试内容的测试函数。

## B. 命名

- PEP 8：函数/变量 `snake_case`，class `PascalCase`，模块常量 `UPPER_CASE`，模块/包名小写。
- 名字表意：没有 `data2`、`tmp_fn`、`do_stuff`；布尔量读作谓词（`is_`、`has_`）；有歧义的量带单位（`timeout_s`）。
- 遵循 metds/codearc.md 记录的命名约定与周边代码的 upstream 风格（§3：匹配现有风格，即便不是你的选择）。

不算 finding：紧凑作用域里的惯用短名（`i`、`x`、`df`、`cfg`）；审查范围外 upstream 继承的名称；残留清单名称（被人改动才升级为 blocker）。

## C. 简洁性（§2）

- 不做任务或计划没要求的功能；没有只有一个调用点的可配置性。
- 没有单用途抽象：只有一个子类的基类、只造一种产品的工厂、只有一个实现的接口。
- 没有死代码：无引用的函数/类/分支、不可达代码、过期开关。区分本项目引入的死代码（finding，可修）与 upstream 继承的死代码（只报告——§3，绝不删）。
- 没有已有 helper 覆盖的重复逻辑——fix 里引用那个 helper。
- 一个函数做一件事；需要一段话才能概括的函数是拆分候选（minor）。

## D. STAR 项目约定

- **禁止硬编码机器本地路径**（`/Users/...`、`/home/...`、`C:\...`）；机器相关根路径来自 `.env` / 环境变量 / 配置（§6）。一律 blocker。
- 数据从 `datas/` 读、权重从 `inits/` 读、生成输出写 `wkdrs/`；运行时不写 `metds/`、不写包自身（§5）。
- 新模块放在 codearc.md 放置规则与计划组件映射指定的位置。
- 运行时假设与项目一致：入口按 `.env` conda 环境 / `execs/run.sh` 运行；不假设系统 python shebang；可复用启动脚本放 `execs/scpts/`。
- 改名残留（codearc.md §7）——registry 字符串、config `type:` 键、checkpoint `state_dict` 前缀、logger/项目名——原样不动。

## E. 正确性 smell（仅报高置信）

只报眼前代码能证明的：

- unused imports/变量（有 ruff/flake8 输出时相互印证；先确认"未用"的 import 不是副作用导入再标）。
- 可变默认参数；裸 `except:` / `except Exception: pass` 吞错误；不用上下文管理器打开文件/进程；`== None` 比较；没有占位符的 f-string；明显写反或差一的条件。
- 范围内的签名/调用不匹配（compileall 和 ruff 抓一部分；其余读调用点）。

不算这里的 finding：假想的竞态、性能猜测、说不出具体输入的"如果…可能失败"。需要调试器才能确认的，至多进报告的 Unconfirmed 列表。

## F. 计划符合度（仅计划模式）

对照磁盘打分，绝不对照 EXEC_LOG 声明：

- §3 每个任务一行：`implemented`（代码存在且做了任务说的事——引用模块/函数）/ `partial`（起步了；点名缺口）/ `missing`（没找到代码；说明找过哪里）。
- §4 中属于代码、或由范围内代码产出的每个交付物：在声明的路径上吗？
- §5 完成判据：检查它的机制存在（测试、评测脚本、断言）——静态核实机制本身；跑重检查是 executor 的事，不是 reviewer 的。
- 交叉核对 EXEC_LOG：声称改过的文件确实存在且含有该改动；没有对应代码的声明是 major finding。

符合度行进报告的记分卡一节，与 A–E findings 分开。
