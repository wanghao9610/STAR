# 执行分支与 worktree 规则

规约 §11 背后的操作程序。Step 3 决定并创建；Step 4 把提交落在分支上；Step 7 审查之后，续跑路径了结分支——合并或弃用——连同安置它的 worktree。这里的每条 git 命令都归 executor 自己运行，写明交给用户的除外。

对话或运行记录里已有明确、适用的决定，就满足相应授权点；引用它继续，不再重复询问。实现授权本身不等于合并、弃用、删除、覆盖授权，也不授权在相互竞争的用户意图或研究意图之间代选。生效档位为 `low` 且带合法 `auto=unattended` token 时，就是范围有限的 `star-auto` 授权；它只覆盖下文逐项写明、带守卫的推荐路径。

## 何时推荐开分支

依据 Step 2 的缺口清单：只要有 action 要**修改** `${CODE_NAME}/` 下已存在且被跟踪的文件 → 推荐 `branch: <run>`。只有"需新建"条目、或写入只落在 `tasks/<plan-name>/` 与 `wkdrs/<run>/` → `branch: none`。空代码库从不开分支。改动量、入口影响面、有多少其他计划碰同一批文件，只用来把推荐语说得更准，绝不取代这条规则。Step 3 先沿用用户已有的适用选择；没有时，`low` 采用并记录推荐项，`medium` 随计划一并问，`high` 把它作为未定裁量单独问。答案写进 EXEC_PLAN 的 `branch:`。

无人值守 auto 同样采用并记录推荐项，注明来自其有限授权。

## 何时推荐进 worktree

分支问的是这个 run 的历史要不要隔离（上一节）；worktree 问的是被调用的 checkout 此刻腾不腾得出来（规约 §11.7）。Step 2 摸底时顺带查信号：HEAD 停在别的 run 的执行分支上；工作区未提交改动的路径归属别的 run 的记录；某份 EXEC_LOG 记着命令已交回用户、结果还没回收——可能有任务正在跑，任何命令都探测不了；或用户明说要并行。任一信号命中 → 推荐 `worktree: ../<根目录名>--wt/<run>`；一个都没有 → `worktree: none`。进树的 run 一律带分支，即便缺口清单判的是 `branch: none`——树里的提交要有自己的归宿，而基础分支正被别的 checkout 检出（§11.8）。Step 3 先沿用已有适用决定；没有时，与分支决定一起按 involve 档位处理推荐项。尚未回收的交回命令足以推荐 worktree，无须探测或切换可能正忙的 checkout。

无人值守 auto 沿用同一条带守卫的推荐；它不授权触碰可能正忙的 checkout，也不授权暂存其中的改动。

## Step 3 的分支与 worktree 决定

两项都与 EXEC_PLAN 材料一并展示，并记录决定来源：用户先前选择、`low`/无人值守推荐项，或 `medium`/`high` 请求到的答案。`medium` 把两项未定选择一起问，`high` 分开问；已有决定绝不再问。

无人值守 auto 仍展示同样材料，并把有限授权写成决定来源。

- **分支**，当 Step 3 定了 `branch: <run>`（规约 §11）:点明它从哪个基础分支分出,选它就同时选了逐步提交——只有提交才会被合并——以及唯一前置条件:当前 checkout 上没有正在运行的任务;不选则照旧在基础分支上执行。
- **worktree**，当 Step 3 定了 `worktree: <path>`（§11.7）:点明推荐它的那个忙碌信号、路径、要补的链(`.env`、`datas/`、`inits/`),以及整个 run——提交、记录、后续 skill——从此都住在那棵树里,当前 checkout 原地不动;不选则在这里执行,等 checkout 忙完。

## 创建（Step 3，决定记下后）

1. 把 checkout 当前分支与短 SHA 记为 `base:`（`git rev-parse --abbrev-ref HEAD`、`git rev-parse --short HEAD`）。绝不假定是 `main`。
2. 可能正有任务运行的 checkout 不得切换——跑着的任务会中途重读被切换的文件。checkout 正忙正是把这个 run 送进 worktree 的信号。
3. 只开分支：`git switch -c <run>`。运行前就有的未提交改动原样带过去；它们仍按既有改动点名，永不暂存（规约 §1.4）。
4. 进 worktree：在被调用的 checkout 里 `git worktree add <path> -b <run> <base>`——树、分支、起点一步成型，任何 checkout 都不切换。运行前的未提交改动留在原 checkout；树从 `base:` 干净地建出来。
5. 进 worktree：git 只把被跟踪的文件放进新树，所以从主 checkout 链入运行时——`.env`、`datas/`、`inits/`，`.star/memory/local/` 有则一并，全用绝对路径符号链接——然后对树里的 `.env` 重跑一次 §3 解析，证明解释器仍然可用。绝不链 `wkdrs/` 与 `tasks/`（§11.8）。树的绝对路径记进 EXEC_PLAN / EXEC_LOG frontmatter 的 `worktree:`；此后这个 run 的一切——委派、检查、提交、记录——都发生在树里，每份交办说明写明树根（`agent_dispatch_spec_zh.md`）。
6. 选了分支就同时选了逐 action 提交：没有提交的分支没有东西可合并。

无人值守 auto 在已记录的决定里点明授权；带尚未回收任务记录的 checkout 视为正忙，因此绝不切换它。

## 分支上的提交（Step 4）

每个通过验证的 action，其提交把本 action 的文件**连同本 action 更新过的运行记录**一起暂存——`EXEC_LOG.md` 的行、`EXEC_PLAN.md` 的 synced 标记、子计划的 frontmatter——提交信息前缀按规约 §1.2。停在未提交状态的记录不会被合并，而且更糟：两个分支都有的文件上一处未提交的编辑，会在之后的 `git switch` 里跟着走，而不是留在分支上。

## 续跑（Step 0）

- 存在与 leaf 匹配的 `<prefix>_<slug>*` 分支，就是进行中的那次 run——即便基础 checkout 显示 leaf 未执行：基础分支是准据（规约 §11.3）。去分支上续跑。
- 记录里带 `worktree:` 的 run 住在那棵树里。先确认树还在（`git worktree list`），然后**在树里**续跑——被调用的 checkout 从不切换。记录在案的树从磁盘上消失了，是要上报的 blocker：`git worktree prune` 清掉过期元数据，绝不无声重建。
- 切换之前先 `git status`：无关的未提交改动逐一点名。绝不替用户 stash、暂存、覆盖或丢弃它们。只有已有适用决定明确说明路径不会相撞时才切换；否则询问用户要怎样保护这些工作。
- 记录在案的 `branch:` 已不存在，是要上报的 blocker；绝不无声重建。

## 合并授权点（Step 7 审查之后）

抵达条件：每个 action 都 `done`、§5 完成判据已验证、最新一份 `CODE_REVIEW_<date>.md` 没有悬而未决的 blocker/major——还没有审查时，Step 6 已经启动它，合并须等待结果。已有明确、适用的合并决定时直接引用并执行，不再重复询问；否则任何参与度档位都问，每个选项带后果：

1. **合并（推荐）。** 先把分支上还散着的运行记录提交掉。基础分支越过了 `base:` 就先把它 merge **进**执行分支——绝不 rebase（规约 §1.3）——然后检查整合后的 diff。已有实现/整合授权、预期的组合结果没有歧义、解法纯属机械时，可以解决常规冲突；随后重跑受整合影响的检查和该 leaf 的轻量检查。若冲突要求在用户改动、研究做法、目标或验收判据之间取舍，就列出文件并询问方向。单凭 `auto=unattended` token 永不取得冲突消解权。squash 在检出着 `<base>` 的那棵树里跑——只开了分支的 run 先 `git switch <base>`；进了 worktree 的 run，主 checkout 本来就站在那里。先运行 `git merge --squash <run>`，暂不提交；用户选择保留逐步历史时改用 `git merge --no-ff --no-commit <run>`。出现冲突时仍按上述规则处理。在这棵已整合的树上跑受影响的轻量检查。只有通过后，才在运行记录里设置 `merged:`，补充来源和验证证据，将这些记录与本次整合的改动按确切路径暂存，创建合并提交，信息为 `star-plan-executor: <run> — merge (squash), <N> steps, review <报告文件>`（选择保留历史时如实描述）。确认提交包含 `merged:` 记录。检查或提交失败时，保持 `merged:` 未设置，保留待整合状态与全部证据并报告；提交成功之前不宣称已合并，也不清理工作树。进了 worktree 的 run 接着了结那棵树——移除是删除，因为未跟踪文件会随树一起消失，所以需要具体授权：已有适用授权就直接沿用，否则再问。获授权后，先把树里 `wkdrs/<run>/` 与 `tasks/<plan-name>/` 下非 md 的未跟踪产物挪到主 checkout 的相同路径，保留原始日志与证据，检查 `git -C <path> status --porcelain`，仅在为空时执行不带 `--force` 的 `git worktree remove <path>`——git 因残留文件而拒绝，说明有东西漏挪了：去查，绝不硬闯（§11.9）。最后，除非用户另行授权删除，否则保留 `<run>`。
2. **暂不合并。** 分支留着；`star-flow-status` 会持续把合并列为这个 leaf 的待办后续。进了 worktree 的 run，树也跟着留。其余一切不变。
3. **弃用。** 需要明确、适用的用户授权；已有就直接沿用，不重复问，但绝不从实现或合并授权推断出来。在基础分支上 `git checkout <run> -- wkdrs/<run>/`，把这些记录连同子计划里这次 run 的条目、判它出局的结论一起提交（`exec_status: abandoned`，或改回 `pending` 等重跑——用户挑）。进了 worktree 的 run，先照上面把非 md 产物挪出来——负结果的产出也是证据——然后分别取得树移除与分支删除授权。记录和原始证据回到基础分支；代码不回。

无人值守 auto 绝不豁免审查。条件满足后，它的有限授权直接采用选项 1；只用 squash，绝不改用 `--no-ff`；基础分支变动无法干净合入、出现没有另行明确授权可解决的冲突、或检查失败时就停止。对于 worktree，只有上述产物与原始证据都已移出、`git -C <path> status --porcelain` 为空、且移除无需 `--force` 时，有限授权才覆盖移除；否则保留并报告确切路径或拒绝原因。已合并执行分支保留，因为 squash 后删除它需要强制操作。这份授权不覆盖弃用、覆盖、昂贵命令，也不覆盖替用户或研究意图作取舍。

## 其余 skill 看到什么

执行分支 `<run>` 被 checkout 期间，每个 skill 都作用在它上面：reviewer 的修复提交、analyst 的报告、reviser 对**这个** leaf 计划的编辑都落在分支上、随它一起合并。进了 worktree 的 run，家记在 `worktree:` 字段里——这些 skill 都在那棵树里工作，主 checkout 全程检出着基础分支。要提交与本次 run 无关内容的 skill 先说明并提议切回去（规约 §11）。`execs/update.sh` 只在基础分支上运行，绝不在这里。
