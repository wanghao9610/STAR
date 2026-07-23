# 发布准备 — <项目>（<YYYY-MM-DD>）

<!-- 由 /star-code-release 写出（model_id: <模型 id，照抄运行时本会话为你声明的那串——Claude Code 在会话开始注入；仅当本会话未声明任何模型才写 "unrecorded">）。
     本次跑了哪些阶段：gather | polish | readme | check（或"完整流程"）。
     无话可说的节收缩为一行——绝不注水。 -->

## 1. 结论

<!-- 先给一行：只有在没有未清阻断项时才写 "release-ready"，否则写 "blocked (<n>)" 并点名阻断项。
     然后 2–3 行：本次运行改了什么，用户接下来必须决定什么。
     不虚高——未清的阻断项不是"小问题"。 -->

## 2. 来源就绪度

<!-- Step 0 打印的那张表，外加每一行对本次编译意味着什么。 -->

| 来源 | 状态 | 生产者 | 对本次运行的影响 |
|---|---|---|---|
| `metds/overview.md` | present / absent / stale | `/star-metd-summarize overview` | <它喂了 README 的哪一节，或留下了哪条 TODO> |
| `metds/results.md` | | `/star-expt-analyst aggregate` | |
| `metds/codearc.md` | | `/star-code-architect` | |
| `${CODE_NAME}/requirements*` | | `/star-env-builder` | |

## 3. 提升记录

<!-- 扫描找到的每个候选一行，按扫描顺序——包括原地保留的那些，它们是多数，也是预期结果。 -->

| # | 候选 | 通过 | 证据 | 目的地 | 动作 | 结果 |
|---|---|---|---|---|---|---|
| 1 | `<path>` | A / B / C / none | <README 的哪一节、计划 file:line、或账本的哪一行> | `<path>` | move / merge / keep in place / route | done / blocked / 未批准 |

**复核方式：** <每行重跑的 compileall 与残留引用 grep>

**被搞过期的计划文本：** <路径已移动的计划 file:line——路由给 `/star-plan-reviser`，或"无">

## 4. 打磨记录

<!-- 仅发布面：先给文件数，再每条 finding 一行——applied / skipped / reverted。
     发布面之外的 finding 单独列出待路由，绝不在此修复。 -->

| # | File:line | Finding | 结果 |
|---|---|---|---|
| P1 | `<file>:<line>` | <一行> | applied / skipped / reverted（<原因>） |

**发布面之外，路由给 `/star-code-reviewer`：** <数量与一行小结，或"无">

## 5. README 小节映射

<!-- 写了什么，各自来自哪里。TODO 行要点名由哪个生产者 skill 来填。 -->

| 小节 | 来源 | 状态 |
|---|---|---|
| 摘要 | `metds/overview.md`@<日期> | written / TODO（`/star-metd-summarize overview`）/ omitted（无来源） |
| 安装 | `requirements.txt`、`ENV_REPORT.md`@<日期> | |
| 结果 | `metds/results.md`@<日期> | |

**标为未验证的内容：** <带"尚未验证"行的小节及各自背后的叶子，或"无">

**保留的人工改动小节：** <文本与上次生成结果不同的小节，或"无——首次生成">

## 6. 体检结果

<!-- 取自 references/release_checklist_zh.md，阻断项在前，每条带 file:line 与修法。
     某一族没有发现时给一行："无 finding"。 -->

### Secret 与机器本地路径

- **BLOCKER** `<file>:<line>` — <什么> · 修法：<怎么改>

### 许可证与署名

### 命令可运行性

### 静态资源与链接

## 7. 等待用户

<!-- 发布命令，只准备不执行（`SKILL_zh.md` 核心原则 6）。每条给出：确切命令、它产生什么、
     它让什么变得不可逆。外加每个需要用户决定才能修的阻断项——选 license、
     误提交 secret 后是否重写历史。 -->

| 事项 | 命令 | 不可逆？ |
|---|---|---|
| <添加 remote> | `git remote add origin <URL>` | 否 |
| <发布> | `git push -u origin <branch>` | 是——从此公开 |

## 8. 下一步

<!-- 路由，最严重的在前：每条 README TODO 由哪个生产者来填、发布面之外的代码 finding 去哪里、
     哪些计划在提升之后需要 `/star-plan-reviser`、以及用户在发布前必须先决定什么。 -->
