# Step 8：Aggregate（仅 aggregate 模式）

在调用带 `aggregate` 时读。整轮分析与 `watch` 运行都不读本文件。本步骤依据的规则在 `aggregate_spec_zh.md`，与本文件一同读。

按 `references/aggregate_spec_zh.md` 编译结果汇总表：解析范围内的叶子；逐叶取其最新的 `EXPT_ANALYSIS_<日期>.md`（没有报告 → 记为缺口并转交，绝不去读原始 run；超过 ~6 份报告时按格式约定的**规模**一节把路径切成几遍来读）；**每个数字入表前，重开它引用的来源并确认**；按根 §4 的主张→实验映射与消融设计分组，绝不按 run 树分组；把 `invalid` / `inconclusive` 的 run 与复核未通过的数字连同原因排除到 §5，而 `not met` 的 run 留在它们该在的表里。把 `assets/results_template_zh.md`（英文：`assets/results_template.md`）填进由**范围**选定的那个目标——所有计划树写 `wkdrs/results/results.md`，限定到某棵子树时写 `wkdrs/results/results_<slug>.md`，绝不以其一覆盖其二——并遵守写入规则：已存在的 `type: results` 文件要先让变更清单获批；范围比本次编译更宽的文件绝不被收窄；人工撰写的文件绝不仅凭一个 diff 就覆盖。

简报 ≤500 字：汇总 / 排除 / 仍未测量的 run、关键指标表格，以及转交——缺报告的交 `/star-expt-analyst <slug>`，未执行的叶子交 `/star-plan-executor <slug>`。明说结果汇总表只报数字、不解释数字：说清某个变体*为什么*赢，需要一次这个 skill 并不运行的受控对比。

