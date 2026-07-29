---
type: survey
topic: <综述的话题，用平实的话写>
language: <en | zh —— 按 Step 0.4 的规则>
generated: <YYYY-MM-DD，取自系统时钟>
sources:
  - <读过的方法来源，连同当时读到的 `updated:` —— 自由话题时整个键省略>
papers:
  deep: <计数>
  abstract: <计数>
  record: <计数>
model_id: <model id，照抄本会话 runtime 声明的值——会话没有任何声明时才写 "unrecorded">
model_trail:                    # 只追加：一次写入会话一条，绝不改写旧条目
  - { date: <YYYY-MM-DD>, model: <model id 或 "unrecorded">, skill: star-refs-reviewer, scope: <本会话写了什么> }
---

# <话题> —— 领域综述

<!-- 由 /star-refs-reviewer survey 写出。下文每条论断都能追溯到本轮抓取、列在 §12 的来源；
     其余一律标注为本综述自己的推断。没内容的节收缩成一行——绝不注水。 -->

## 1. TL;DR

<!-- 5–8 条要点：读者决定要不要读这张地图之前需要知道的结论。 -->

## 2. Scope & Method

<!-- 检索画像及其来源。每条检索式原样列出，附日期。计数账：
     found → deduplicated → screened → tiered。排除了什么，为何排除。 -->

## 3. Problem & Background

<!-- 领域自己怎么框定这个任务；全文要用的术语，在这里定义一次。 -->

## 4. Taxonomy

<!-- 一句话写明划分轴，被舍弃的轴写在旁边。然后是 3–8 支，每支一行。
     至多两层；每篇论文恰好落在一支上。 -->

## 5. Branches

<!-- 每支一小节：这批工作共享什么、在哪分岔，代表作行内引用 [@key]。
     是综合，绝不逐篇罗列。 -->

### 5.x <分支名>

## 6. Comparison

<!-- 只收精读层（deep）的论文作行。列要能区分、且每行都填得上——通常是：核心机制、
     监督/数据需求、基准与头条数字（数据集 + 指标一起写）、代码可得性、年份。
     抓回的来源填不上的格写 `—`。 -->

## 7. Evolution & Trends

<!-- 2–3 段，写领域怎么走到今天，带年份。记录层（record）的论文可以在这里被点名。 -->

## 8. Benchmarks & Evaluation Practice

<!-- 领域实际在报的数据集、split 与指标，以及可比性在哪里断掉。 -->

## 9. Open Problems & Gaps

<!-- 已综述的工作还做不到什么，批判地写——依据来源，不靠愿望。 -->

## 10. Relation to This Project

<!-- 仅当来源是计划或方法笔记；自由话题时本节收缩成一行。
     本项目落在分类体系的哪一支、哪些支与它竞争、它们都做不到什么。 -->

## 11. Read Next

<!-- 值得建一篇完整分析笔记的论文，每篇一句话理由，附 id 或 URL。
     单篇是 `/star-refs-reviewer <arxiv-id>`；整个清单一次 `/star-refs-reviewer add …`。 -->

## 12. Annotated References

<!-- 综述点名的每一篇。一篇一行：
     [@key] | 标题 | venue | 年份 | 层级（deep / abstract / record）| 记录 URL | fetched <YYYY-MM-DD> -->
