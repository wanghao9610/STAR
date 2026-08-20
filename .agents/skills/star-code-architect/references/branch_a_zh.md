# 分支 A——从参考实现搭建

在 Step 0 选定本分支时读：`${CODE_NAME}/` 缺失或只有占位文件。走分支 B 的运行（`${CODE_NAME}/` 已有真实代码）不读本文件。带 GitHub URL 的调用从 Step A4 进入，跳过 A1–A3。

## Step A1：构建检索要素

从计划提取：任务领域、方法关键词、框架及版本约束、§2/§4 写明的 baseline、数据集与工具需求。检索前以短块展示要素。方法见 `references/repo_rubric_zh.md`。

## Step A2：检索并入围

优先 `gh search repos` / `gh api`（结构化 stars / license / pushed_at），配合网页检索计划中 baseline 的官方实现。入围 5–10 个；跳过已归档、仅 demo、awesome 清单类仓库；fork 让位于源仓库。`gh` 不可用或未登录则改用网页检索。确实找不到合格候选就如实说明，给出：细化检索要素 / 以最小骨架从零起步。

## Step A3：评分

按评分表（`references/repo_rubric_zh.md`）给每个候选打分：计划贴合度 30、完整性 20、许可证 15、活跃度 15、代码质量 10、环境匹配 10。浅读各库 README（必要时加 setup 文件）——此时不克隆。

## Step A4：确认点 1——用户选定参考库

呈现 top 3–5，一个候选一行：一句话贴合理由、许可证、stars、最近更新、主要风险。推荐得分最高的一个，始终保留一条退路（"都不合适——细化检索 / 从零起步"），并问用哪个。若以 URL 调用，也要展示该库的许可证、活跃度与风险，确认后再克隆。

## Step A5：克隆到位

1. 浅克隆到临时目录；记下 URL、commit SHA、commit 日期、许可证。
2. 若实现只是某个大仓库的子目录，与用户确认子路径，只取该部分。
3. 删除 `.git`；内容移入 `${CODE_NAME}/`；上游 `LICENSE` 与 `CITATION*` 文件原位保留。
4. 按 `assets/upstream_template.md` 写 `${CODE_NAME}/UPSTREAM.md`（该文件一律英文，无 `_zh` 版本）。
5. 提交 import（只暂存 `${CODE_NAME}/`）：`star-code-architect: import <repo> @ <short-sha>`。

## Step A6：保守改名

按 `references/rebrand_checklist_zh.md` 执行：顶层包目录、全部 import、打包元数据（`setup.py` / `pyproject.toml` 包名、packages、console 入口）、README 标题与安装片段。每改一处：grep 旧名确认计数按预期下降，再跑 `python -m compileall -q ${CODE_NAME}`（无需装依赖）。禁改清单上的名称（注册表字符串、配置 `type:` 键、checkpoint `state_dict` 前缀、logger/wandb 项目名）进入**残留表**，写入 `codearc.md` §7。提交：`star-code-architect: rebrand to <CODE_NAME>`。

## Step A7：运行时跑通性检查（含红线）

若 `.env` 指向的 conda 环境可用，通过它跑 `python -c "import <package>"`。建环境与装依赖通常是重操作：准备好确切命令（`conda create …`、`pip install -r …`）；纯 Python 轻量安装需用户当场明确同意才执行；涉及 CUDA 编译或超过约 1 GB 下载一律移交用户（红线，见 `references/orchestration_spec_zh.md`）。记录哪些已跑、哪些待用户执行。整套环境构建可交棒给 `star-env-builder`——后端选择、依赖解析、按优先顺序安装与跑通性检查都由它在自己的安装计划确认点下完成。

## Step A8：勘察这份克隆

先数这份克隆的 `.py` 文件数。在轻量模式阈值以下：以一次只读扫描补全 Step C1 的仓库地图（`references/survey_spec_zh.md`）——评分阶段已覆盖粗粒度结构，直接内联完成。超过阈值：照原样走 Step B1 的各组，或只走 C1 真正需要的三组（结构与依赖、配置系统、训练/评测入口）。参考实现通常远在阈值之上，而这一遍是 C1 定架构和迁移表的唯一输入。

