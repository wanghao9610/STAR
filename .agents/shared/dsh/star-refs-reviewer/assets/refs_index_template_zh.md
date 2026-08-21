# Reference Index —— <主题>（<YYYY-MM-DD>）

<!-- 由 /skill:star-refs-reviewer 写出（model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded"——见 docs/mds/star-workflow/model_id_spec.zh-CN.md>）。本文件是 reference.bib 的审计线索：每条条目的出处都记在这里，
     因此 bib 里的任何字段都能对照它来自的那条记录复查。没有这里的行，条目就不允许存在。 -->

## 1. 范围

<!-- 驱动本次检索的方法来源（metds/<文件>.md、metds/plans/ 下的某个计划，或用户给的 topic），
     以及从中提取的画像。跑了哪些检索式。存放原始内容的运行缓存：wkdrs/refs_<date>/raw/。
     模式：full | append | verify | organize。 -->

## 2. 核心论文

| Citekey | 笔记 | 会议/期刊 | 为什么是核心 | 精读深度 | 影响力分 | Model |
| --- | --- | --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | [CLIP.md](CLIP.md) | <ICML 2021> | <一句话> | full | <9.6> | <model id> |

## 3. 类别

| 类别 | 条目数 | 范围 |
| --- | --- | --- |
| <具体的类名> | <n> | <一行> |
| **合计** | **<n>** | |

## 4. 出处（Provenance）

<!-- reference.bib 每条一行——100% 覆盖，无例外。"来源"是字段转录自的那条记录。
     自拟缩写标 †，arXiv-only 标 ‡。这里的记录 URL 与抓取日期，
     就是该条目在 reference.bib 里那行 `% src:` 的内容。 -->

| Citekey | 来源 | 记录 URL | 抓取日期 |
| --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | DBLP | <https://dblp.org/rec/conf/icml/...bib> | <YYYY-MM-DD> |

## 5. 影响力评分

<!-- 每条一行，算式与分档见 references/refs_rubric_zh.md"影响力分"一节：子指标带各自的抓取
     日期，然后是加权总分。`*` 标残缺总分（某分量没抓到，权重已归一化）；`new` 标发表 ≤18 个月
     的论文。星标只给论文自己页面挂出的仓库——unofficial 仓库在此登记，绝不计分。指标会漂移：
     日期说明新鲜度，/skill:star-refs-reviewer score 重建整表。 -->

| Citekey | 年均引用（抓取日） | 发表档 | 星标（仓库，抓取日） | 总分 |
| --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | <6100（YYYY-MM-DD）> | <10> | <30.1k（openai/CLIP，YYYY-MM-DD）> | <9.6> |

## 6. 待人工核对

<!-- 找不到权威记录的论文；有歧义的匹配（列出候选及其 URL）；字段看起来不对但仍照原样转录、
     没有静默修正的记录。每条写明要核什么、去哪核。干净时写"无"——绝不省略本节。这里是详细的
     一侧：reference.bib 末尾的 `%% Needs manual check` 块每篇一行，指到这里。 -->

## 7. 自查

<!-- 重抓并 diff 了哪些条目（≥5 条，随机；verify 模式下是全部）、结果如何、解析 / 括号 /
     唯一性检查的结果、从登记子指标复算的 3 条影响力分，以及因此改正了哪些条目。 -->

## 8. 下一步

<!-- 值得再跑一轮补的缺口（某个类别偏薄、某个子话题没覆盖）。转交：磨定位 → /skill:star-plan-coach
     §2 相关工作与定位；以后单加一篇 → /skill:star-refs-reviewer <arxiv-id>；重查 bib →
     /skill:star-refs-reviewer verify；引用与星标漂了 → /skill:star-refs-reviewer score。 -->
