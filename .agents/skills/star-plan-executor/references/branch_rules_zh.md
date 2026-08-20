# 执行分支与 worktree 规则

规约 §11 背后的操作程序。Step 3 决定并创建；Step 4 把提交落在分支上；状态与文件规则了结分支——合并或弃用——连同安置它的 worktree。这里的每条 git 命令都归 executor 自己运行，写明交给用户的除外。

## 何时推荐开分支

依据 Step 2 的缺口清单：只要有 action 要**修改** `${CODE_NAME}/` 下已存在且被跟踪的文件 → 推荐 `branch: <run>`。只有"需新建"条目、或写入只落在 `tasks/<plan-name>/` 与 `wkdrs/<run>/` → `branch: none`。空代码库从不开分支。改动量、入口影响面、有多少其他计划碰同一批文件，只用来把推荐语说得更准，绝不取代这条规则。Step 3 由用户定夺——两个方向都正当——答案写进 EXEC_PLAN 的 `branch:`。

## 何时推荐进 worktree

分支问的是这个 run 的历史要不要隔离（上一节）；worktree 问的是被调用的 checkout 此刻腾不腾得出来（规约 §11.7）。Step 2 摸底时顺带查信号：HEAD 停在别的 run 的执行分支上；工作区未提交改动的路径归属别的 run 的记录；某份 EXEC_LOG 记着命令已交回用户、结果还没回收——可能有任务正在跑，任何命令都探测不了，所以要问用户；或用户明说要并行。任一信号命中 → 推荐 `worktree: ../<根目录名>--wt/<run>`；一个都没有 → `worktree: none`。进树的 run 一律带分支，即便缺口清单判的是 `branch: none`——树里的提交要有自己的归宿，而基础分支正被别的 checkout 检出（§11.8）。两行都在 Step 3 暂停时一并定夺。

## 确认点上的两问（Step 4）

两问都搭在批准 EXEC_PLAN 的那个确认点上，绝不单独发起一次调用。

- **分支**，当 Step 3 定了 `branch: <run>`（规约 §11）:点明它从哪个基础分支分出,选它就同时选了逐步提交——只有提交才会被合并——以及唯一前置条件:当前 checkout 上没有正在运行的任务;不选则照旧在基础分支上执行。
- **worktree**，当 Step 3 定了 `worktree: <path>`（§11.7）:点明推荐它的那个忙碌信号、路径、要补的链(`.env`、`datas/`、`inits/`),以及整个 run——提交、记录、后续 skill——从此都住在那棵树里,当前 checkout 原地不动;不选则在这里执行,等 checkout 忙完。

## 创建（Step 4，批准后）

1. 把 checkout 当前分支与短 SHA 记为 `base:`（`git rev-parse --abbrev-ref HEAD`、`git rev-parse --short HEAD`）。绝不假定是 `main`。
2. 前置条件已在 Step 3 暂停时说明：当前 checkout 没有正在运行的任务——跑着的任务会中途重读被切换的文件。checkout 正忙不再是等待的理由：它正是把这个 run 送进 worktree 的那个信号。
3. 只开分支：`git switch -c <run>`。运行前就有的未提交改动原样带过去；它们仍按既有改动点名，永不暂存（规约 §1.4）。
4. 进 worktree：在被调用的 checkout 里 `git worktree add <path> -b <run> <base>`——树、分支、起点一步成型，任何 checkout 都不切换。运行前的未提交改动留在原 checkout；树从 `base:` 干净地建出来。
5. 进 worktree：git 只把被跟踪的文件放进新树，所以从主 checkout 链入运行时——`.env`、`datas/`、`inits/`，`.star/memory/local/` 有则一并，全用绝对路径符号链接——然后对树里的 `.env` 重跑一次 §3 解析，证明解释器仍然可用。绝不链 `wkdrs/` 与 `tasks/`（§11.8）。树的绝对路径记进 EXEC_PLAN / EXEC_LOG frontmatter 的 `worktree:`；此后这个 run 的一切——委派、检查、提交、记录——都发生在树里，每份交办说明写明树根（`agent_dispatch_spec_zh.md`）。
6. 选了分支就同时选了逐 action 提交：没有提交的分支没有东西可合并。

## 分支上的提交（Step 5）

每个通过验证的 action，其提交把本 action 的文件**连同本 action 更新过的运行记录**一起暂存——`EXEC_LOG.md` 的行、`EXEC_PLAN.md` 的 synced 标记、子计划的 frontmatter——提交信息前缀按规约 §1.2。停在未提交状态的记录不会被合并，而且更糟：两个分支都有的文件上一处未提交的编辑，会在之后的 `git switch` 里跟着走，而不是留在分支上。

## 续跑（Step 7）

- 存在与 leaf 匹配的 `<prefix>_<slug>*` 分支，就是进行中的那次 run——即便基础 checkout 显示 leaf 未执行：基础分支是准据（规约 §11.3）。去分支上续跑。
- 记录里带 `worktree:` 的 run 住在那棵树里。先确认树还在（`git worktree list`），然后**在树里**续跑——被调用的 checkout 从不切换。记录在案的树从磁盘上消失了，是要上报的 blocker：`git worktree prune` 清掉过期元数据，绝不无声重建。
- 切换之前先 `git status`：无关的未提交改动逐一点名，切换等用户答复——他们自己提交或 stash，或说明这些路径不会相撞。绝不替他们 stash。
- 记录在案的 `branch:` 已不存在，是要上报的 blocker；绝不无声重建。

## 合并确认点（Step 7）

抵达条件：每个 action 都 `done`、§5 完成判据已验证、最新一份 `CODE_REVIEW_<date>.md` 没有悬而未决的 blocker/major——还没有审查时，Step 6 的报告已经把它启动了；用户可以豁免，豁免记进日志。然后发问，任何参与度档位都问，每个选项带后果：

1. **合并（推荐）。** 先把分支上还散着的运行记录提交掉。基础分支越过了 `base:` 就先把它 merge **进**执行分支——绝不 rebase（规约 §1.3）——在分支上重跑该 leaf 的轻量检查，冲突则停下：列出冲突文件，解法由用户定夺。squash 在检出着 `<base>` 的那棵树里跑——只开了分支的 run 先 `git switch <base>`；进了 worktree 的 run，主 checkout 本来就站在那里。然后 `git merge --squash <run>`，一次提交，信息为 `star-plan-executor: <run> — merge (squash), <N> steps, review <报告文件>`；用户想把逐 action 提交留在基础分支上时改用 `--no-ff`。合并之后：在基础分支上重跑该 leaf 的轻量检查（仅限 §2 允许的），在运行记录里填上 `merged:`。进了 worktree 的 run 接着了结那棵树——移除是删除，任何档位都问，因为未跟踪文件随树一起死：答应了就先把树里 `wkdrs/<run>/` 与 `tasks/<plan-name>/` 下非 md 的未跟踪产物挪到主 checkout 的相同路径，再 `git worktree remove <path>` 且绝不带 `--force`——git 因残留文件而拒绝，说明有东西漏挪了：去查，绝不硬闯（§11.9）。最后才是分支那一道——`<run>` 留还是删，和任何删除一样对待。
2. **暂不合并。** 分支留着；`star-flow-status` 会持续把合并列为这个 leaf 的待办后续。进了 worktree 的 run，树也跟着留。其余一切不变。
3. **弃用。** 在基础分支上 `git checkout <run> -- wkdrs/<run>/`，把这些记录连同子计划里这次 run 的条目、判它出局的结论一起提交（`exec_status: abandoned`，或改回 `pending` 等重跑——用户挑）。进了 worktree 的 run，先照上面把非 md 产物挪出来——负结果的产出也是证据——然后树的移除、分支的删除各问一道，任何档位都问。记录回到基础分支；代码不回。

## 其余 skill 看到什么

执行分支 `<run>` 被 checkout 期间，每个 skill 都作用在它上面：reviewer 的修复提交、analyst 的报告、reviser 对**这个** leaf 计划的编辑都落在分支上、随它一起合并。进了 worktree 的 run，家记在 `worktree:` 字段里——这些 skill 都在那棵树里工作，主 checkout 全程检出着基础分支。要提交与本次 run 无关内容的 skill 先说明并提议切回去（规约 §11）。`execs/update.sh` 只在基础分支上运行，绝不在这里。
