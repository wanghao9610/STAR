# 来源绑定与分析适用性

分析报告、结果表、方法文档、环境报告或纯工程执行记录写完后，以及消费者决定能否复用它们时，使用本约定。工具为 `bash .agents/skills/star-flow-status/scripts/source_state.sh --root <运行所在checkout>`，仅需 shell 工具、jq 和 git，不需要 Python 环境。判断及写入归各产物的生产者；状态查询不记录或修复元数据。

## 核验后记录

产物正文与来源信息最终写定后，运行 `record <产物> --kind <类型>`，按需重复以下选项，列出支撑结论的全部输入：

- `--file <路径>`：精确文件内容，包括原始指标、检查输出、配置、依赖定义或小型输入清单。明确不存在的文件按缺失记录，后来生成时使绑定失效。不散列整份数据集、权重文件或目录。
- `--document <路径>`：Markdown 内容，忽略工具自身的元数据块及 frontmatter 中的日期、模型来源字段。EXEC_PLAN、EXEC_LOG 影响结论时使用；正文变化仍有效。
- `--plan <路径>`：计划正文及语义关系，忽略记账字段与修订历史。分析报告和豁免需包含叶子及相关祖先计划。
- `--method-plan <路径>`：在上述内容之外保留计划和执行状态，以及是否已定稿。绑定方法文档所查阅的全部有效计划，包括就绪检查和来源选择；旧文档没引用的新相关计划不能漏掉。
- `--report <路径>`：当前有效的分析报告及其绑定证据，仅供结果表使用。过期或旧式分析须先由分析技能核验更新，再进入汇总。
- `--exemption <路径>`：当前有效的工程豁免及其证据，用于结果表中无指标的工程行。豁免撤销或证据变化后，下游表的绑定也会失效。

来源路径为相对于项目根目录的文件，允许沿已声明的输入软链读取，与项目数据和 worktree 输入一致。可写产物解析后必须仍在指定 checkout 内，文件本身不能是软链。工具保留已有正文字节；原末行没有换行时补一个分隔换行，清除绑定后保留该分隔符。在产物末尾写入一个保留的 `star-source-state` HTML 注释块，包含内容指纹、来源路径和类型；不复制来源内容，也不判定研究结论。来源改变后，生产者须核验再记录；只刷新散列值不能使过期结果重新有效。最后这次写入后也要运行正常的模型来源检查。

示例中的路径应替换为实际已核验范围：

```bash
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/01_demo/EXPT_ANALYSIS_2026-10-22.md --kind analysis --plan metds/plans/01_demo_plan.md --plan metds/plans/0_root_plan.md --document wkdrs/01_demo/EXEC_PLAN.md --file wkdrs/01_demo/metrics.json
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/results/results.md --kind results --report wkdrs/01_demo/EXPT_ANALYSIS_2026-10-22.md
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record metds/framework.md --kind method --method-plan metds/plans/0_root_plan.md --method-plan metds/plans/01_demo_plan.md
```

示例日期仅占位，不能抄成报告日期。方法文档使用配置中的代码路径等事实时，也绑定相应配置文件；只保存指纹。已有 `sources:` 日期保留为可读来源信息，不再用于判断时效。

## 只读检查

运行 `check <产物> --kind <类型>`，为**当前**应覆盖的每个来源补上 `--require <路径>`。输入清单来自当前范围，不从旧产物反推：分析需覆盖当前叶子及祖先约束，结果表需覆盖当前所有应汇总的分析报告及工程豁免日志，方法文档需覆盖当前查阅的有效计划。这样才能同时发现新增、修改和删除。结果表的输入分析也须逐个检查；表本身有效不能替过期分析恢复有效性。

JSON 结果与退出码区分 `current`（0，有效）、`stale`（1，内容改变或当前来源未覆盖）和 `unknown`（2，旧记录缺元数据、格式不支持或证据不可读）。非零结果都不能宣称最新，应转给生产者核验。日期和 mtime 不能使未知产物通过。旧记录在获授权的生产者运行中完成一次来源核验后补记；状态查询不得批量为历史报告盖章。

使用该 run 所在的 checkout。只有分支中的文本、无法在其对应位置核对来源文件时，报告时效未知，不用另一份 checkout 的文件代替。绑定有效只说明与所列输入一致，不证明范围完整或科学解释正确；后两项仍由生产者负责。

## 环境身份

环境生产者完成所需可运行检查及已获授权的 `.env` 更新后，仅为 `status: verified` 的报告记录：

```bash
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/env_demo_20261022/ENV_REPORT.md --kind environment --runtime "$ENV_PY" --file code/requirements.txt --file code/requirements/runtime.txt
```

包含构建所用的全部依赖定义、被引用的 requirements 文件及锁定/配置文件。报告的 `interpreter:` 标明受检解释器绝对路径。工具绑定其内容和已安装包的元数据（dist-info/egg-info、conda 记录），不执行解释器。包的新增、删除或版本变化都会使绑定失效。

状态查询按规约 §3（项目运行环境）从 `.env` 解析**当前**解释器，传给 `check <报告> --kind environment --runtime <当前解释器>`，并用 `--require` 列出当前依赖定义。读取该解释器最新的相关报告；报告为 partial/blocked 或证据冲突时，不回退到较旧的通过报告。解释器缺失、旧报告或绑定不匹配意味着需要核验，不等于必须重建。转给 `star-env-builder` 验证或修复；状态查询不安装软件。

包清单相同不能证明导入、设备或 editable 代码仍能运行。执行器使用 Python 前仍须做目标所需的最窄导入或入口检查；已知当前失败优先于相同指纹。`add` 后，只有原基线仍有效且检查覆盖全部安装变化，才能保留 verified。传递依赖升级或原基线不明确时，先补做受影响的可运行检查再记录；否则报告保持 partial/blocked。

## 纯工程任务的分析豁免

执行器仅在实际运行完全属于工程工作时，才能在收尾记录豁免：没有实验指标或研究结论，没有假设、baseline 或消融对比，没有数据划分/选择或改变评测的预处理，也没有训练、评测或付费推理运行。所有必需动作和交付物检查均须已核验。任务名称、样本小或证据缺失都不是豁免依据；不能把已有实验重新标为工程任务来隐藏结果。用户明确要求分析时仍执行分析。

在 EXEC_LOG 已有 Notes 中写入 `analysis: not applicable`、具体原因及验证证据，再绑定该日志本身：

```bash
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/01_demo/EXEC_LOG.md --kind analysis-exemption --reason "Packaging repair only; import checks verified." --plan metds/plans/01_demo_plan.md --plan metds/plans/0_root_plan.md --document wkdrs/01_demo/EXEC_PLAN.md --file code/package.py --file wkdrs/01_demo/import-check.log
```

包含实际改过的源码、配置和证据文件；已有代码审查回执时也包含它。执行器后续再写日志，应重新判断适用性，并在最终内容写定后记录。运行已需要分析时，在 Notes 中记录该决定，使用 `clear <EXEC_LOG路径> --kind analysis-exemption` 仅移除过期绑定，保留执行历史。实验指标缺失应照常转给分析，不能因此豁免。代码审查、运行授权、完成判据和计划层面问题继续独立适用。

状态查询仅在 `check EXEC_LOG.md --kind analysis-exemption` 返回 current 且覆盖当前计划时，省去自动的缺分析提醒。过期或格式不完整的豁免转回执行器重新分类；没有豁免则默认需要分析。汇总与 digest 消费者把当前有效的豁免 run 列为无指标的工程工作，排除于缺分析项及数值表之外；不伪造分析报告，也不把豁免当成已验证的研究结果。
