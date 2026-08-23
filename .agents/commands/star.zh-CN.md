# 路由 STAR 请求

> 本文件是 [`star.md`](star.md) 的中文对照版。运行时路由以英文原文件为准。

使用下表把研究工作流请求准确路由到一个 STAR skill。

| Skill | | 用途 |
| --- | --- | --- |
| `star-code-architect` | † | 建立或重组代码库，并编写 `metds/codearc.md` |
| `star-code-release` | † | 准备仓库发布材料；绝不实际发布 |
| `star-code-reviewer` | | 按规约及计划承诺审查代码 |
| `star-env-builder` | | 根据 `.env` 构建并验证项目的 Python 运行时 |
| `star-expt-analyst` | | 按计划的完成标准判断一次运行的结果 |
| `star-expt-digest` | | 汇总实验计划最近的进展 |
| `star-flow-status` | | 展示计划树、进度和唯一的下一步行动 |
| `star-idea-storm` | † | 把模糊兴趣收敛为经过评分并最终确定的研究主题 |
| `star-metd-summarize` | | 把已完成的计划树汇编成可用于论文的方法文档 |
| `star-plan-coach` | † | 每次通过一个引导问题起草或重新打开研究计划 |
| `star-plan-decomposer` | † | 把完成的计划拆分成可执行的叶子子计划 |
| `star-plan-executor` | | 执行一个叶子子计划：规划、审批、编码并做轻量验证 |
| `star-plan-reviser` | † | 逐项依据执行证据修订计划 |
| `star-proj-adopt` | † | 在不扰动现有项目的前提下把它纳入 STAR |
| `star-refs-reviewer` | | 建立逐论文笔记和已验证的 `reference.bib` |

标有 † 的七个 skill 只能显式调用，因为每个都控制一项属于研究者的决定。通用 `/star` 路由绝不直接启动它们：先请求明确确认，给出准确的 `/star-<name> <argument>` 命令，然后等待。任务明确匹配时，可以选择其余八个 skill。

请求为空时选择 `star-flow-status`。否则，说明选中的 skill、选择它的一句话理由，并把原请求作为参数传入。未标记的 skill 应通过当前宿主的原生 skill 机制启动，并使用该宿主拥有的副本。如果两个 skill 同样合理，只问一个简洁问题，不要混合两者范围。绝不能绕过 skill，凭一般知识直接生成归它所有的产物。
