# 方法文档来源刷新：修复与验证（2026-10-30）

<!-- 由 skill-creator 写出；用户授权：在上一轮三项改进建议后请求“修复”。
model_id: gpt-6-astra
-->

已落实 `code_diff_2026-10-27.md` 的三项建议。保留先前未提交改动与历史报告，没有提交 Git。

## 修改

- `.agents/skills/star-metd-summarize/SKILL.md` 第 5 步（比较并写入已有文档）集中维护三个分支：有效且正文未变时不写；过期或缺少绑定时先核验，再仅刷新必要元数据；正文有实质变化时遵循覆盖授权。仅刷新记录时保留正文、`generated` 和既有 `model_trail`，追加本次写入记录。
- 中英文 `references/extract_map` 保留变更清单格式，改为引用上述步骤。Claude 覆盖记录仅适配需要调用询问工具的独立句子；六套宿主文件由生成器同步。
- 第 6 步（报告写入结果）要求仅刷新元数据时使用 `written`，并说明正文和生成日期未变；`unchanged` 留给整份文件未写入的情况。
- `.github/scripts/tests/test_source_state.sh` 新增 3 个完整方法文档用例，覆盖有效、过期和旧文档缺少绑定的情形，检查正文、生成日期、模型历史的字节保留，以及有效记录的幂等性。

## 自动检查

| 命令 | 结果 |
| --- | --- |
| `bash .github/scripts/tests/test_source_state.sh` | 48 个用例通过，新增 3 个 |
| `bash .github/scripts/port.sh --write` 后运行 `--check` | 六套树各 180/180 文件复现，无差异 |
| `bash .github/scripts/check_consistency.sh` | 全部通过 |
| 通过 `.env` 的 `PYTHON_HOME/bin/python` 运行 skill-creator 的 `scripts/quick_validate.py .agents/skills/star-metd-summarize` | `Skill is valid!` |
| `git diff --check` | 退出码 0 |

验证版本为 HEAD `7fd415ad28c8a40d103fdc93c18873e3a47a702f` 加工作区改动。`git hash-object` 输出：技能正文 `ce7c4b176b7b5189063c99f471fab3963e931970`；来源绑定测试 `c0cfe7cbf350bb0735e38387b64546ef176d6180`。

## 独立执行验证

按 skill-creator 的独立执行验证流程，三名新上下文执行者在隔离临时项目中实际运行技能及 shell 工具，不接收预期答案、旧审查或补丁说明。派发使用 EXEC 配置 `gpt-6.1-sol`、`high`。分工为 a/b、c、d/e；第三名完成后另执行 f，文件互不重叠。

每个项目包含修订后的技能、来源工具与规约、一份已定稿根计划、一份已完成叶计划、已有方法文档，以及无秘密的 `.env`。基础方法为 `max(x, 0)`，实现路径为 `code/clamp.py`。源日期和文档生成日期均为测试固定值 `2026-10-22`。

各项目使用相同请求：

> Use star-metd-summarize framework to reconcile the existing framework document with the current plans. Preserve existing prose unless I approve a section-level change list.

只允许持久写入各自的 `metds/framework.md`。执行者指出 helper 原子写入需要临时同目录文件后，测试授权明确包括由 helper 自行清理的 `.source-state.*` 文件；没有修改技能来绕过写入范围。

| 情形 | 输入差异 | 实际行为 | 最终来源状态与退出码 |
| --- | --- | --- | --- |
| a：有效文档 | 完整有效绑定 | 整份文件未写入 | `current`，0 |
| b：正文不受来源修改影响 | 根计划新增交接完成的 Scheduling 段落 | 核验后只刷新绑定与写入者记录，未询问正文覆盖授权 | `current`，0 |
| c：旧生成文档 | 没有绑定，正文及来源记录完整 | 核验后补绑定并追加写入者记录 | `current`，0 |
| d：正文变化且来源冲突 | 计划公式变为 `max(x, 1)`，描述仍保留原行为 | 展示小节变更及冲突，返回覆盖问题，未写入或刷新绑定 | `stale`，1 |
| e：无法完成来源核验 | 根仍列出叶计划，但叶文件缺失 | 报告缺失来源，保留文档和绑定 | `unknown`，2 |
| f：正文变化但来源一致 | 两份计划统一改为 `code/clamp_v2.py` | 列出组件与模块表的路径更新，返回覆盖问题，未写入或刷新绑定 | `stale`，1 |

f 单独覆盖无来源冲突的正文变化，避免只由 d 的冲突阻止写入。以上问题均作为测试结果返回，没有向真实用户请求批准测试文档。

主执行者通过项目解释器重新读取前后文件，逐字节比较正文和计划文件；检查生成日期、历史条目、最后一条写入者与 `model_id` 一致，确认无残留临时文件；并分别运行以下只读检查，核对退出码与 JSON 状态：

```sh
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$CASE_ROOT" check metds/framework.md --kind method --require metds/plans/0_root_plan.md --require metds/plans/00_clamp_plan.md --require .env
```

主执行者得到 `PASS: 6 forward scenarios; all source plans unchanged`。a、d、e、f 整份文档未变，SHA-256 均为 `7d0cb4b60933ffce37e5ac0afad9be9bbcf7580103f0f47f5402fda067374fd9`。b 从该值变为 `0a35655a117e5dd1bc4d8b13cd65bc59d39c7b983cd034237c31fe962c736414`；c 从 `9d60bbf0640a1f83e03539e9074e796e81b61b46551f6e6178b614cbce2c69d9` 变为 `42dc7302992b9a433bb750fa04e4fdd4cd8f524f7da90fc4b8e320a1332fe9a4`。b/c 正文与原生成日期完全保留，原模型历史保留并各追加一条记录。执行者的最终回复明确说明仅更新来源及必要元数据。

隔离执行者未收到精确运行时模型标识、来源 resolver 或写后检查命令，因此测试产物按规约记录 `unrecorded`，没有把派发参数当作运行时自报证据。该限制不影响本轮正文、来源有效性及授权分支的验证，也不表示验证了所有宿主的交互行为。

本次只修改技能文字、生成副本和相关测试；未启动实验、修改研究计划或改写历史报告。
