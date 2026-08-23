# 上游来源

> 本文件是 `upstream_template.md` 的中文对照版，仅供人阅读。实际生成的 `UPSTREAM.md` 始终用英文填写；运行时请使用英文模板。

<!-- 只记录事实元数据；架构摘要写在 metds/codearc.md §5（上游来源与改造策略）。 -->

- **来源**：<仓库 URL>
- **model_id**：<写入时运行时声明的模型 ID；若运行时未声明则写 "unrecorded"——见 docs/mds/star-workflow/model_id_spec.zh-CN.md>
- **提交**：`<完整 SHA>`（<提交日期，YYYY-MM-DD>）
- **子路径**：<单体仓库中的子路径，或 —>
- **克隆日期**：<YYYY-MM-DD>
- **许可证**：<SPDX 标识符>——原始文本保存在 `LICENSE`
- **引用**：<保留的上游 CITATION.cff / 论文引用，或 —>
- **重命名为**：由 star-code-architect 改为 `<CODE_NAME>`（包名 + import + 打包元数据；有意保留的上游名称见 `metds/codearc.md` §7（残留风险与操作说明））
- **本地分化起点**：<首个本地提交 SHA——完成导入提交后填写>

绝不能删除或改写上游的 `LICENSE` 与 `CITATION*` 文件。发布基于该代码的工作时，保留上述归属信息，并遵守此处注明的许可证。
