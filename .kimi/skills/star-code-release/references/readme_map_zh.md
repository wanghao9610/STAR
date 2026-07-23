# README 抽取映射表

哪份产物喂哪一节、来源缺失时怎么办、内容如何誊写。README 就按这张表编译——表里没有来源的节不该出现在 README 里，表里没列的来源也不为它而读。

参考形态取自研究仓库的共识做法（GroundingDINO、YOLO-World、LLaVA、SAM 的顺序大体一致）：身份 → 它是什么 → 怎么装 → 能下载什么 → 怎么跑 → 跑出了什么 → 怎么引用。STAR 加的是：上面每一节背后都有一个文件。

## 小节表

`M` = 必备：该节始终出现，来源缺失时带一条 `TODO`。`O` = 空则省略：没有来源就没有这一节——绝不注水。

| # | 小节 | 类型 | 主来源 | 辅助来源 | 来源缺失时 |
|---|---|---|---|---|---|
| 1 | 头部——标题、标语、徽章、teaser | M | `metds/overview.md` §问题 + §核心想法 | 仓库目录名、`.env` 的 `CODE_NAME`、`metds/refs/reference.bib` 自条目 | 标题取仓库名/`CODE_NAME`；标语写 `TODO` → `/skill:star-metd-summarize overview` |
| 2 | News / Updates | O | 根计划 §6 带日期的里程碑、`wkdrs/digests/EXPT_DIGEST_*.md` | — | 省略——没人写过的 news 不是 news |
| 3 | Abstract / Introduction | M | `metds/overview.md`——问题、gap、核心想法 | 根计划 §1–§2 | `TODO` → `/skill:star-metd-summarize overview` |
| 4 | Highlights / Contributions | O | `metds/overview.md` 的 contributions（写成可证伪主张的那些） | — | 省略 |
| 5 | Method / Architecture | O | `metds/framework.md`——数据通路、逐组件细节 | `metds/codearc.md` §4 计划组件映射，给出每个组件的代码指针 | 省略；在报告里注明这是缺得最大的一节 |
| 6 | Installation | M | `${CODE_NAME}/requirements*`、最新 `wkdrs/env_*/ENV_REPORT.md`（python 版本、后端、安装阶梯、`ENV_PY`） | `.env.example` | `TODO` → `/skill:star-env-builder` |
| 7 | Data preparation | O | `metds/dataset.md`——清单、预处理、构造数据 | 数据就绪叶子在 §3 点名的 `datas/` 布局 | 省略 |
| 8 | Model Zoo / Checkpoints | O | `metds/results.md` 中点名权重的行 | `inits/`，取实际存在的路径 | 省略。**绝不**链接既不在盘上、也未公开发布的 checkpoint |
| 9 | Quick start / Demo | O | `codearc.md` §2 点名的入口 | `execs/run.sh` | 没有可解析的入口就省略 |
| 10 | Training | O | `metds/training.md`——阶段流水线、超参表、复现命令 | `execs/scpts/*.sh` | 省略 |
| 11 | Evaluation | O | `metds/evaluation.md`——协议、benchmark、指标、消融设计 | `execs/scpts/` 下的评测脚本 | 省略 |
| 12 | Results | O | `metds/results.md`——**数字的唯一来源** | — | 省略。绝不从 `EXPT_ANALYSIS` 报告或 digest 重建表格 |
| 13 | Repository structure | O | `metds/codearc.md` §1 目录布局 | — | 省略 |
| 14 | TODO / Roadmap | O | 根计划 §6 中尚未 `done` 的里程碑 | — | 省略 |
| 15 | Citation | M | `metds/refs/reference.bib` 自条目 | 根计划 §1 取标题 | 给带 `TODO` 的占位 BibTeX——绝不编造 venue、年份或作者列表 |
| 16 | License | M | 根 `LICENSE` | `metds/codearc.md` §5 上游许可证的约束 | 用一行点名文件缺失；体检清单会把它记为阻断项 |
| 17 | Acknowledgement | 有 `UPSTREAM.md` 时为 M | `${CODE_NAME}/UPSTREAM.md` | `metds/refs/refs_index.md` 的核心论文 | 只有在既无上游、也无核心论文基座时才省略 |
| 18 | 页脚——Built with STAR | M | — | — | 始终存在 |

## 誊写规则

编译出来的 README 和写出来的 README，区别就在这几条。

1. **数字是抄的，不是算的。** §8 和 §12 里每个数值都从 `metds/results.md` 原样誊写，连同账本引用的 run 名一起。被账本排除的数字（它的 `invalid` / `inconclusive` 小节里那些）根本不进 README——加注解也不行。账本不存在时，§12 省略，报告路由到 `/skill:star-expt-analyst aggregate`。
2. **命令先解析再打印。** 对每条命令：脚本文件存在、它点名的每个配置路径存在、它调用的模块在 `.env` 解释器下可导入。能解析 → 按脚本或 `metds/training.md` 的记录原样打印。解析不了 → 删掉，或放在一条明确的*尚未验证*行下并说明缺什么。一份 install 或 train 命令在全新 clone 上跑不通的 README，是研究仓库失去读者最常见的方式。
3. **路径先检查再链接。** 图片、权重、配置和相对链接都指向确实存在的文件。`metds/framework.md` 引用了但 `docs/srcs/` 里没有的 teaser 图，结果是没有图——而不是一个坏掉的 `<img>`。
4. **主张要带证据。** "state of the art"、"outperforms"、"best"、"significantly" 只在 `metds/results.md` 带有支持该说法的结论时才出现。对具名 baseline 的比较句，需要该 baseline 的数字出现在同一张账本表里。其余一律只描述，不排名。
5. **未验证的内容要标出来，不藏起来。** 来自 `exec_status` 非 `done` 叶子的内容——从未端到端跑过的训练配方、从未执行过的评测协议——保留一行斜体说明它尚未验证，与 `/skill:star-metd-summarize` 的纪律一致。把意图当事实静默呈现的 README，正是这条规则要挡住的失败。
6. **按读者的轴归并。** 一份方法文档可能喂三节，一节也可能归并四份。要重写成一个声音——读起来像摘抄拼接、或者把上一节说过的话再说一遍的小节，就是失败的。两个来源冲突时，`generated:` 较新者胜，并在报告里点名该冲突。
7. **篇幅本身是一种设计。** 头部到 §4 是多数读者真正会读的部分。§1–§4 合计控制在约 400 词以内；细节下沉到为它准备的那些小节，其余链接到 `metds/`。

## 溯源标记

编译出的 README 第一行，位于标题之前：

```html
<!-- Compiled by /skill:star-code-release on <YYYY-MM-DD> · model_id: <id 或 unrecorded> · sources: metds/overview.md@<generated>, metds/framework.md@<generated>, metds/results.md@<generated>, metds/codearc.md@<updated>, … · report: wkdrs/release/RELEASE_<date>.md · Regenerate with /skill:star-code-release readme; hand edits to a section are detected and kept. -->
```

它是 HTML 注释，不是 YAML frontmatter：README 里的 frontmatter 会被 GitHub 渲染成页首的一张表。按规约 §8，这条标记就是本产物的 header line——它带 `model_id`，并为每个来源记下读取时该来源所带的日期，这正是让 README 的过期可以靠比对而不是靠文件 mtime 发现的原因。

重跑时，标记里的 `sources:` 日期用于识别哪些来源动了；而某一节的文本若与所记来源应产生的结果不同，就按人工改动处理，默认保留。
