# 七棵树的剩余重复：按变体分组的共享方案

状态：全部已应用（2026-08-20）。第 6 节九条、第 3 节的变体分组、以及第 2.1 节末尾说的抹平调用前缀，三件都做完了，记在第 7–9 节。
写于 2026-08-20。

## 1. 现状与量化

`.github/scripts/port.sh`（从一份作者副本生成七棵树）以 `.claude/skills` 为唯一作者副本、
`.agents/skills` 为共享文件的实体所在，其余六棵树在生成文本与 `.agents` 完全一致时自动挂
相对软链。哪些文件是软链没有清单，`port.pl` 每次运行现算。

每棵树 187 个文件，其中 75 个已是软链（`.pi` 68 个）。剩下 112 个：

| 类别 | 数量 | 七棵树去重后的文本数 |
|---|---|---|
| `SKILL.md` / `SKILL_zh.md` | 30 | 全部 7 种。frontmatter 的 `description` 每家按自己的长度上限和触发词调，`port.pl` 要求 frontmatter 也相同才软链——结构上不可能共享，且实测零冗余 |
| references / assets | 82 | 见下 |

82 个 references/assets 按实际文本去重：

```
53 个：{agents} | {claude,cursor,pi,qwen} | {dsh,kimi-code}          3 种文本，存了 7 份
14 个：七棵树各不相同                                                  7 种文本，无冗余
 4 个：{agents} | 其余六棵树                                            2 种
 3 个：{agents} | {claude,cursor,qwen} | {dsh,kimi-code} | {pi}        4 种
 8 个：其他分组                                                        4–6 种
```

合计 **263 份是纯重复副本**，约 **1.37 MB**（这 82 个文件存 7 份共 2.9 MB，按文本去重后
1.6 MB）。以上是本文写就时的快照，文件数每周都在动，量级不变。

## 2. 单 hub 为什么接不住

差异的来源是技能调用前缀，各家写法不同且都是实质差异：

- `.agents`（中性树）：`star-env-builder`，没有斜杠命令
- claude / cursor / pi / qwen：`/star-env-builder`
- dsh / kimi-code：`/skill:star-env-builder`

57 个文件的唯一差异就是这一处；另有 18 个差在工具名（`Agent`、`AskUserQuestion`、`Bash`、
`Read`、`CLAUDE.md`），7 个差在 overrides（某棵树确实另说一套）。这些行多数出现在报告模板
里、是给用户照抄的命令，抹平会给错。

所以三种文本里只有中性那一种能放进 `.agents/skills`，另外两种在当前模型里没有家，只能各树
各存一份。

### 2.1 地板在哪：390 种文本

把两类文件分开量（含已经共享的，按内容去重）：

| | 副本数 | 不同文本 | 纯重复 |
|---|---|---|---|
| `SKILL.md` / `SKILL_zh.md`（30 个） | 210 | **210** | **0** |
| references / assets（157 个） | 1099 | 390 | 709 |

`SKILL` 那一类一份都不重复，而且**没有一个文件的正文在七棵树里相同**——不是 frontmatter
挡着，是正文本身就各写各的。这扇门是关死的。

references/assets 现在磁盘上有 644 份实体文件（其余靠软链），只有 390 种文本，所以
**254 份是纯重复**，约 1.37 MB。方案 A 把这 254 份全收掉，文本一个字不动；390 就是不改文本
时的地板。

要再往 390 以下走只能改文本，唯一有量级的抓手是调用前缀：把三种写法抹成一种，390 → 279，
且有 **47 个文件会在现有机制下自动变成全共享**，连 `port.pl` 都不用改。但代价是实的——这些
字符串多数不是给 agent 看的，是要被写进生成物的：`readme_map.md` 的
`` `TODO` → `/star-metd-summarize overview` `` 会落进 README，`digest_rubric.md` 的
"A provisional row always carries its routing: `/star-expt-analyst <run dir>`" 会落进摘要，
`status_spec.md` 那 26 行是打印给用户照抄的下一步命令。抹平之后 DSH 与 Kimi 的用户拿到的
命令是错的。逐行只抹掉装饰性的那部分（"which is `/star-expt-analyst`'s job" 这类）理论上
可行，但一个文件要所有出现都是装饰性才会塌缩，而 206 行里占大头的恰恰是要输出的那类——
收益低，且抹错一行用户就拿到错命令。不建议。

## 3. 方案：按变体分组，宿主仍在 `.agents` 下

### 3.1 分组与宿主选取

对每个相对路径，先算出七棵树各自的生成文本（`port.pl` 现在已经为 `.agents` 算了一遍，扩成
七遍即可），按 (frontmatter, body) 完全相同分组。宿主按固定优先级取组内第一棵树：

```
agents > claude > cursor > dsh > kimi-code > pi > qwen
```

- 含 `.agents` 的那组，宿主路径不变：`.agents/skills/<rel>`（今天就是这样）
- 其余每组，宿主路径为 `.agents/shared/<宿主树名>/<rel>`
- 组内其他树在原路径挂相对软链指向宿主
- 单成员组照旧写实体文件

分组每次运行现算，不记录在任何文件里——和今天"软链与否现算"是同一条原则。

### 3.2 为什么宿主放 `.agents/shared/` 而不是别处

三个位置都试过在纸面上推：

- **组内宿主树自己持有**（如 `.qwen/.../x.md` 软链到 `.claude/.../x.md`）：不需要新目录，但
  `execs/update.sh`（下游安装脚本）的 sparse-checkout 只无条件检出 `.agents/skills`，只装
  qwen 的下游项目会检出不到 `.claude`，软链解析不了。要修就得无条件检出全部七棵树。
- **`.agents/skills/<skill>/.variants/<树>/`**：`update.sh` 的 `SYNC_PATHS` 无条件包含
  `.agents/skills`，所以这些变体文件会被原样装进每个下游项目，成为下游的负担；而且
  `check_consistency.sh` 第 7 项断言 `.agents/skills` 里**一个调用记号都不能有**
  （`check_absent .agents/skills "/${skill}"` 与 `"skill:${skill}"`），带 `/star-` 的变体
  文本放进去会当场失败。
- **`.agents/shared/<树>/`**（推荐）：在 `.agents/skills` 之外，既不触发第 7 项断言，也不
  进 `SYNC_PATHS`，因而不装到下游；软链方向始终是"某棵树 → `.agents`"，与今天一致。

### 3.3 要改的三处

1. **`.github/scripts/port/port.pl`**（主要改动）。今天的 hub 预跑只生成 `.agents` 一棵的
   文本，用来做"文件还是软链"的判定；改成先生成七棵树的文本、分组、定宿主，再在每棵树的
   循环里写实体文件或挂软链。受影响的是那段判定块（约 40 行）和文件头部"只有一个 hub"的
   说明。`rel_list()` 仍只走 `.claude/skills`，不受影响。
2. **`execs/update.sh`**：两处 sparse-checkout 各加一个 `.agents/shared` 路径（全量分支的
   `SPARSE_PATHS`，以及 `--skill <name>` 单技能分支的 `sparse-checkout set` 行），让软链
   在打包时解析得到。`SYNC_PATHS` **不要**加——加了就会装到下游。
   下游安装本来就用 `find -L` 与 `tar -ch --hard-dereference` 解引用，装出来仍是实体文件，
   这一环不需要改。
3. **`.github/scripts/check_consistency.sh`**：预计不需要改。`mdgrep` 用的是 `find -L`，
   跟随软链，所以每棵树的词汇检查仍能看到宿主里的文本；`SKILL_ROOTS` 只列 `.agents/skills`，
   新目录不进文件清单对比。改完要实跑一遍确认。

### 3.4 影响不到的地方

- **下游项目**：`.agents/skills` 本来就在 `SYNC_PATHS` 里、每次都装；六棵树的软链在打包时
  被解引用成实体文件。也就是说这 246 份重复是**仓库内的**成本，下游项目无论如何都拿到实体
  文件，装出来的体积不变。
- **`equiv_check.sh`**（一致性检查器的等价性回归）：它从 `git archive HEAD` 取工作副本，
  结构变化后 goldens 需要按它自己的规矩先 `--regen` 再改，顺序不能反。

## 4. 代价与风险

- **宿主路径会漂移**。组的成员随措辞变化而变；组内第一棵树若离开该组，宿主路径就换一个树名，
  在 git 里表现为一次改名。今天"软链与实体文件互相翻转"已经是同一类现象，量级相当。
- **多一个概念**。`port.pl` 头部现在的说法是"一个 hub、一份共享文本"，改完要写成"一个 hub
  目录、每个变体一份"。这套工具的价值有一半在它的自述文档准确，这部分不能省。
- **收益是仓库体积与 diff 噪音**，不是维护成本。七份副本全是生成的，CI 每次证明它们与
  `.claude` 一致，人不会去手改；真正的收益是改一句话时 diff 从 7 处变成 3 处。

## 5. 不做的理由（对照）

保持单 hub 也是站得住的：这 246 份副本没有一份是手写的，`port.sh` 的检查每次证明它们是
`.claude` 加各自词汇表的产物，漂移会当场报错。付出的是 1.37 MB 和改一句话时的 diff 宽度。

## 6. 另有 9 处与本方案无关、可以立刻做的修改

这些是"差异既不实质也非树特定"的残留，删掉对应的 override 记录并重跑 `port.sh --write`
即可，已验证 `port.sh` 检查与 `check_consistency.sh` 全绿：

1. `agents.overrides` 里 `star-refs-reviewer/references/score_spec.md` 与 `_zh` 两条：
   `.agents` 把 "Digest ≤200 words / 摘要 ≤200 字" 改写成 "under about 200 words /
   约 200 字以内"。`.agents` 自己别处仍有 81 个 `≤`，不是风格政策。删掉后这两个文件七树
   一致，**12 份副本变软链**。
2. `agents.overrides` / `cursor.overrides` / `pi.overrides` 里
   `star-metd-summarize/references/extract_map.md` 的一条：把
   `marks verified work as design intent or the reverse` 倒写成
   `marks design intent as verified work or the reverse`——句尾有 "or the reverse"，同义。
3. `cursor.overrides` 与 `pi.overrides` 里同一文件的各两条：只是把源里 4 行硬折行接成 1 行，
   纯排版。

`.agents` 的 `extract_map.md` 另比源少两句：`the rule the sibling formats state
(scan_policy.md: never fill a field the record does not carry)` 与
`routed to star-plan-coach`。先前记为"疑似旧版残留"，核过之后改判为**刻意**：`.agents` 在
6 个 reference 文件、16 个跨度上都在压缩源里的说明性散文（`agent_dispatch_spec` 最多的一处
压掉 50%），这两句符合同一手法。因此不动，也不建议动。

## 7. 已应用（2026-08-20）

`tasks/tree-dedup/replay.sh` 把这九条一次做完，工作区不干净时会自己拒跑——`port.sh --write`
会重写每一棵树，别人在途的编辑会被卷进来。它用的 `drop_records.pl` 是删 override 记录的工具：
overrides 是按行数计长的格式，行工具改不动它。

改动落在 20 个文件上：3 份 overrides、`.agents` 的 3 个实体
文件、六棵树里 12 个由实体文件变成的软链（`extract_map.md` 在 cursor 与 pi 各改回源的折行）。
共享数 75 → 77。

验证：`port.sh` 检查全绿；`check_consistency.sh` 25 节全过；把带改动的树与干净 HEAD 各跑一次
`check_consistency.sh`，两份输出**逐字节相同**——没有任何计数移动，所以 `equiv_check.sh` 的
goldens 不会因此失效（`equiv_faults.tsv` 与 goldens 也都不提这两个文件，且 CI 只跑
`port.sh` 与 `check_consistency.sh`）。

## 8. 方案 A 已应用（2026-08-20）

`port.pl` 的判定块换成了分组：先生成七棵树的文本，按 (frontmatter, body) 分组，每组的文本存
一份，组内每棵树挂软链。改了三处，与第 3.3 节预判的一致，只有第三处比预判多一行：

1. `port.pl`——`store_hub` / `store_shared` / `link_to` 三个小函数，一个"先把七棵树都生成一遍
   再分组"的前置遍，一个把各组文本写进存储、并清掉上一轮遗留的遍。
2. `execs/update.sh`——两处 sparse-checkout 各加 `.agents/shared`。`SYNC_PATHS` 没加：加了就会
   装进每个下游项目。
3. `check_consistency.sh`——第 3.3 节预判"不用改"，实跑发现要改一行。"每个 reference 文件都
   被本 skill 里某个文件点名"那一项用 `grep -qrF` 递归搜索，而**递归 grep 不进软链**：BSD grep
   要 `-S` 才跟随，GNU grep 根本没有这个开关，`-R` 在 macOS 上也不跟随。点名它的那个文件一旦
   变成软链就被跳过，活着的引用会被报成孤儿。换成仓库里已有的 `find -L` 写法。

实现里踩到一个自己造的坑，记在这里以免重犯：**清理过期存储必须排在重挂软链之后**。第一版把
清理放在写存储的同一遍里，于是一个分组合并时，旧存储先被删、六棵树的软链还指着它——包括
`.claude/skills` 自己的软链，源文件当场少了 48 个。改法是两条：树循环不再从磁盘读文件，而是用
前置遍拍下的快照；清理挪到全部树都重挂完之后。

## 9. 抹平调用前缀已应用（2026-08-20）

三种写法合并成 `star-x` 一种，由 `tasks/tree-dedup/one_invocation.py` 一次做完：源文件 693 处、
七棵树的 150 份 SKILL frontmatter（frontmatter 不由 port.sh 生成，每家自调 description，只能直接
改）、三份 rules 里的前缀替换行、六份 overrides 的两侧。`/star-workflow` 是文档路径不是调用，
按 `(?!workflow)` 保留。

**没有跟着改的**：`.claude/commands/star.md`、`.cursor/commands/star.md`、`.qwen/commands/star.md`
与 `.pi/prompts/*.md`。这些文件本身就是各家的命令清单，里面的 `/star-plan-coach <argument>` 正是
用户要照着敲的那一行；把它也抹平，说明就成了错的。合计 21 处，都在 skill 树之外，port.sh 也不
管它们。

**代价（先前提过，此处记账）**：报告模板与"下一步"行现在给出的是 `star-expt-analyst <run dir>`
这样的裸名。Claude / Cursor / Pi / Qwen 的用户要自己补一个 `/`，DSH 与 Kimi 的用户要补
`/skill:`。生成物里的命令不再能原样照抄。

## 10. 结果

| | 文件数 | 体积 |
|---|---|---|
| 七棵树逻辑上各存一份 | 1324 | 10502 KB |
| 本次之前实际存储 | 859 | — |
| 方案 A 之后 | 600 | — |
| 抹平前缀之后（现在） | **488** | **5900 KB** |

488 = 209 种 SKILL 文本 + 279 种 reference/asset 文本。reference/asset 那半正好落在第 2.1 节
算出的预测上：不改文本时的地板是 390，抹平前缀后是 279。SKILL 那半从 210 掉到 209，是下面
那个副作用。`.agents/shared` 下 29 个文件，宿主三棵：claude、cursor、dsh。

有一个副作用值得记一笔：抹掉前缀之后，`star-plan-decomposer/SKILL_zh.md` 在 claude 与 kimi-code
两棵树里逐字节相同，成了**第一个变成软链的 SKILL 文件**。`port.pl` 头部原先写"没有哪个 SKILL.md
会是软链"，已经改掉。

验证：`port.sh` 检查全绿；`check_consistency.sh` 25 节全过，且输出与本次改动前**逐字节相同**——
没有任何计数移动，`equiv_check.sh` 的 goldens 不受影响；模拟只装一个 harness 的下游安装
（`tar -ch` 解引用），`.dsh/skills` 装出 187 个实体文件、0 个软链，逐字节与树中读到的一致。
