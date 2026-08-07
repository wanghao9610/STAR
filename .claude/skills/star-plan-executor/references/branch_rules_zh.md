# 执行分支规则

规约 §11 背后的操作程序。Step 4 决定并创建；Step 5 把提交落在分支上；Step 7 了结分支——合并或弃用。这里的每条 git 命令都归 executor 自己运行，写明交给用户的除外。

## 何时推荐开分支

依据 Step 2 的缺口清单：只要有动作要**修改** `${CODE_NAME}/` 下已存在且被跟踪的文件 → 推荐 `branch: exec/<run>`。只有"需新建"条目、或写入只落在 `tasks/<plan-name>/` 与 `wkdrs/<run>/` → `branch: none`。空代码库从不开分支。改动量、入口影响面、有多少其他计划碰同一批文件，只用来把推荐语说得更准，绝不取代这条规则。Step 4 由用户定夺——两个方向都正当——答案写进 EXEC_PLAN 的 `branch:`。

## 创建（Step 4，批准后）

1. 把 checkout 当前分支与短 SHA 记为 `base:`（`git rev-parse --abbrev-ref HEAD`、`git rev-parse --short HEAD`）。绝不假定是 `main`。
2. 前置条件已在确认点上说明：当前 checkout 没有正在运行的任务——跑着的任务会中途重读被切换的文件。checkout 正忙，就晚些执行，或由用户自备 `git worktree`、在里面调用 executor。
3. `git switch -c exec/<run>`。运行前就有的未提交改动原样带过去；它们仍按既有改动点名，永不暂存（规约 §1.4）。
4. 选了分支就同时选了每步 checkpoint 提交：没有提交的分支没有东西可合并，所以不存在无提交的分支运行。

## 分支上的提交（Step 5）

每个通过验证的步骤，其提交把本步的文件**连同本步更新过的运行记录**一起暂存——`EXEC_LOG.md` 的行、`EXEC_PLAN.md` 的 synced 标记、子计划的 frontmatter——提交信息前缀按规约 §1.2。停在未提交状态的记录不会被合并，而且更糟：两个分支都有的文件上一处未提交的编辑，会在之后的 `git switch` 里跟着走，而不是留在分支上。

## 续跑（Step 7）

- 存在与叶子匹配的 `exec/<prefix>_<slug>*` 分支，就是进行中的那次 run——即便基础 checkout 显示叶子未执行：基础分支是准据（规约 §11.3），"基础上没做完"加"分支存在"读作：去分支上续跑。
- 切换之前先 `git status`：无关的未提交改动逐一点名，切换等用户答复——他们自己提交或 stash，或说明这些路径不会相撞。绝不替他们 stash。
- 记录在案的 `branch:` 已不存在，是要上报的 blocker；绝不无声重建。

## 合并确认点（Step 7）

抵达条件：每一步都 `done`、§5 完成判据已验证、最新一份 `CODE_REVIEW_<date>.md` 没有悬而未决的 blocker/major——还没有审查时，Step 8 的简报已经把它启动了；用户可以豁免，豁免记进日志。然后发问，任何参与度档位都问，每个选项带后果：

1. **合并（推荐）。** 先把分支上还散着的运行记录提交掉。基础分支越过了 `base:` 就先把它 merge **进**执行分支——绝不 rebase（规约 §1.3）——在分支上重跑该叶子的轻量检查，冲突则停下：列出冲突文件，解法由用户定夺。然后 `git switch <base>`、`git merge --squash exec/<run>`，一次提交，信息为 `star-plan-executor: <run> — merge (squash), <N> steps, review <报告文件>`；用户想把逐步提交留在基础分支上时改用 `--no-ff`。合并之后：在基础分支上重跑该叶子的轻量检查（仅限 §2 允许的），在运行记录里填上 `merged:`，再问删除那一道——`exec/<run>` 留还是删，和任何删除一样对待。
2. **暂不合并。** 分支留着；`star-flow-status` 会持续把合并列为这个叶子的待办后续。其余一切不变。
3. **弃用。** 在基础分支上 `git checkout exec/<run> -- wkdrs/<run>/`，把这些记录连同子计划里这次 run 的条目、判它出局的结论一起提交（`exec_status: abandoned`，或改回 `pending` 等重跑——用户挑）。这之后才提出删分支，任何档位都问。记录回到基础分支；代码不回。

## 其余 skill 看到什么

`exec/<run>` 被 checkout 期间，每个 skill 都作用在它上面：reviewer 的修复提交、analyst 的报告、reviser 对**这个**叶子计划的编辑都落在分支上、随它一起合并。要提交与本次 run 无关内容的 skill 先说明并提议切回去（规约 §11）。`execs/update.sh` 只在基础分支上运行，绝不在这里。
