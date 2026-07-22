<!-- Compiled by $star-code-release on <YYYY-MM-DD> · model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded"> · sources: <产物>@<日期>, … · report: wkdrs/release/RELEASE_<date>.md · Regenerate with $star-code-release readme; hand edits to a section are detected and kept. -->

<!-- 本模板用于 README.zh-CN.md；README.md 始终为英文，见 readme_template.md。
     小节类型见 references/readme_map_zh.md：(M) 始终出现，来源缺失时带 TODO；
     (O) 来源缺失时整节删掉——绝不注水。
     编译成文时删掉所有指引注释，只保留上面那行溯源标记。 -->

<div align="center">

<!-- (M §1) 只有图片文件确实存在时才放 logo。标题用项目名，与 CODE_NAME 不同时以项目名为准。
     标语取自 metds/overview.md 的核心想法，一行说清它做什么、给谁用，而不是把标题换个说法。 -->

<h1><项目名></h1>
<p><strong><一句话标语——用读者的话讲清主张></strong></p>

<!-- 只有计划或 bib 自条目点名了作者与单位时才写。绝不编造作者列表，绝不猜单位。 -->

<p><a href="<论文 URL>">论文</a> ·
   <a href="<项目主页>">项目主页</a> ·
   <a href="<权重 URL>">权重</a> ·
   <a href="#引用">引用</a></p>

<!-- 徽章行：只放目标确实存在的徽章——license（取自根 LICENSE）、arXiv（取自 bib 自条目）、stars。
     指向 404 的徽章比没有徽章更糟。 -->

</div>

<!-- 两份 README 都存在时才有这一行。 -->
**Language:** [English](README.md) | 简体中文

<!-- (M §1) teaser 图——只有文件在 docs/srcs/ 下存在时才放。alt 文本写清这张图展示了什么，
     供图片加载失败的读者阅读。 -->

<p align="center"><img src="docs/srcs/<teaser>.png" alt="<这张图展示了什么>" width="90%"></p>

## 📰 最新进展

<!-- (O §2) 倒序排列，只用真实日期，每条一行，取自根计划 §6 的里程碑与 digest 系列。
     宁可整节省略，也不要编一条首项出来。 -->

- **<YYYY-MM-DD>** —— <发生了什么>

## 摘要

<!-- (M §3) 取自 metds/overview.md：问题、gap、核心想法，按此顺序。三到六句。
     这一节和下一节是多数读者真正会读的部分——之后的一切都是写给已经决定试一试的读者的。 -->

<TODO：从 metds/overview.md 编译——运行 $star-metd-summarize overview>

## ✨ 亮点

<!-- (O §4) 取自 metds/overview.md 中写成可证伪主张的 contributions。三到五条，每条讲一件
     baseline 做不到的事。这里出现的数字，要么连同背后的 run 从 metds/results.md 抄来，
     要么就不该是数字。 -->

- **<主张>** —— <一行实质内容，不要形容词堆砌>

## 🏗️ 方法

<!-- (O §5) 取自 metds/framework.md：先把架构写成读者能一路跟下来的一条数据通路，再逐个组件
     配上 metds/codearc.md §4 给出的代码位置。架构图只在文件存在时才放。来自未执行叶子的内容
     保留它的*尚未验证*行。 -->

<p align="center"><img src="docs/srcs/<architecture>.png" alt="<这张图展示了什么>" width="90%"></p>

| 组件 | 作用 | 代码 |
|---|---|---|
| <组件> | <一行> | [`<path>`](<path>) |

## 🛠️ 安装

<!-- (M §6) 取自 ${CODE_NAME}/requirements* 与最新的 wkdrs/env_*/ENV_REPORT.md：python 版本、
     后端、以及当初实际用的安装阶梯。这里每条命令打印前都已解析（readme_map_zh.md 规则 2）——
     它是陌生人跑的第一条命令，也是他们据以判断这个仓库的那条。 -->

```bash
git clone <仓库 URL>
cd <仓库>

conda create -n <env> python=<版本> -y
conda activate <env>

pip install -r <CODE_NAME>/requirements.txt
```

<!-- 环境报告里标为需要用户自己动手的步骤——需要 CUDA 编译的扩展、需要源码构建的包——
     在这里单列一步并说明原因。 -->

## 📦 模型库

<!-- (O §8) 每个已发布 checkpoint 一行，取自 metds/results.md；只有文件在 inits/ 下的盘上或
     已公开发布时才给链接。列按账本实际携带的字段来；下面是社区通行形态。 -->

| 模型 | Backbone | 训练数据 | <指标> | 权重 |
|---|---|---|---|---|
| <名称> | <backbone> | <训练数据> | <数字，取自账本> | [下载](<URL>) |

## 📂 数据准备

<!-- (O §7) 取自 metds/dataset.md 以及数据就绪叶子点名的 datas/ 布局：用哪些数据集、从哪里
     获取、代码期望的目录树是什么。要把期望的目录树打印出来——这是数据一节从"描述性"变成
     "可用"的关键。 -->

```text
datas/
└── <数据集>/
    ├── <split>/
    └── <标注>
```

## 🚀 快速开始

<!-- (O §9) 从装好到跑出第一个结果的最短路径：一次推理调用、一个 demo 脚本、几行 Python。
     打印前先解析。 -->

```bash
<命令>
```

## 🔥 训练

<!-- (O §10) 取自 metds/training.md 与 execs/scpts/：先阶段流水线，再每阶段的命令，最后超参表。
     写清该 run 实际用的硬件——没有 GPU 数量和显存的命令是不可复现的。 -->

```bash
bash execs/scpts/<run>.sh
```

| 阶段 | 数据 | Epochs | LR | Batch | 硬件 |
|---|---|---|---|---|---|
| <阶段> | <数据> | <n> | <lr> | <bs> | <n×GPU> |

## 📊 评测

<!-- (O §11) 取自 metds/evaluation.md：协议、benchmark、指标，然后是复现每个已报告数字的命令。 -->

```bash
bash execs/scpts/<eval>.sh
```

## 📈 结果

<!-- (O §12) 取自 metds/results.md，别无他处。复现它的表格，并为每个数字带上背后的 run。
     被账本判为 invalid 或 inconclusive 而排除的数字，在这里完全不出现。
     与 baseline 的比较，需要该 baseline 的数字出现在同一张表里。 -->

| 方法 | <benchmark> | <指标> | Run |
|---|---|---|---|
| <baseline> | <benchmark> | <数字> | <来源> |
| **<ours>** | <benchmark> | **<数字>** | `<run>` |

## 🗂️ 仓库结构

<!-- (O §13) 取自 metds/codearc.md §1，裁剪到读者导航所需的程度——不是规范里那棵完整的注释树。 -->

```text
<code_name>/
├── <dir>/        # <职责>
└── <dir>/        # <职责>
```

## ✅ 待办

<!-- (O §14) 根计划 §6 中尚未 done 的里程碑，作为一份诚实的 roadmap。宁可省略，也不要承诺。 -->

- [ ] <里程碑>

## 📝 引用

<!-- (M §15) 取自 metds/refs/reference.bib 的自条目。没有时给带 TODO 的占位——
     绝不编造 venue、年份或作者列表。 -->

```bibtex
@article{<key>,
  title   = {<title>},
  author  = {<authors>},
  journal = {<venue>},
  year    = {<year>}
}
```

## 📄 许可证

<!-- (M §16) 根 LICENSE，加上上游许可证带来的任何约束（codearc.md §5）。有约束时要明确写出来——
     读者在基于它做二次开发之前需要知道。 -->

本项目以 <LICENSE> 许可证发布。<存在上游约束时在此写明。>

## 🙏 致谢

<!-- (M，当 UPSTREAM.md 存在时，§17) 先写上游代码库及其链接与许可证，再写本项目所基于的
     metds/refs/refs_index.md 中的核心工作。要具体，而不是把读过的东西列一遍。 -->

本项目基于 [<upstream>](<URL>)（<license>）构建。同时感谢 <核心工作> 的作者。

---

<sub>Built with [STAR](https://github.com/wanghao9610/STAR).</sub>
