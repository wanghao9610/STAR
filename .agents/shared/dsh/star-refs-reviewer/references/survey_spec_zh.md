# Step 10：综述一个领域（仅 survey 模式）

写 `metds/refs/<slug>_survey.md`——一份独立的领域地图，分层阅读、按分类体系组织。它不需要已有笔记、不需要 bib、甚至不需要计划，也不写 `reference.bib` 和 `refs_index.md`：想把它翻出的某篇收进核验过的 bib，事后跑一次 `/skill:star-refs-reviewer <arxiv-id>` 即可——整份补读清单则一次 `/skill:star-refs-reviewer add …` 收下。`<slug>` 在来源是计划时取计划 slug，否则把话题压成 kebab-case（≤5 词）。

1. **来源与画像。** Step 0 原样适用——检索前报画像、读增量基线、定语言。另找 1–3 篇该话题已有的综述：它们的分类体系就是分类轴的起点，按本轮实际收到的东西改造，绝不整套照搬。
2. **放宽检索。** Step 1 的机器原样跑——同样的画像出检索式、同样的分派上限与返回格式、同样按 `references/source_policy_zh.md` 的预算与缓存——但池子留着，不砍到 15 条：综述靠广度立足。池子每动一步就记一笔账：found → deduplicated → screened → tiered，写进综述的 Scope 一节。
3. **筛选分层。** 三个阅读层，按各自能支撑什么命名。**精读层（deep）**——8–12 篇，读到 `method-and-results` 或更深；只有它们能进对比表、能被转引数字。**泛读层（abstract）**——15–25 篇，读到 `abstract-and-intro`，够把一篇放上某支并用一句话刻画；检索记录里没有摘要时才抓页面。**记录层（record）**——其余，只凭记录的事实（标题、会议、年份）用于广度与趋势，绝不刻画、绝不进表。分层同时权衡相关性与影响力分；与完整流程不同，这里分数决定遴选：一支的最高分工作应落在精读层或泛读层，不该留在记录层。清单给出各篇分数，读到论文页之前是残缺分。然后是本模式唯一的判断型问题，一次问完：画像、分类轴（连同被舍弃的轴）、分层清单（精读层为推荐）。`involve=low` 按推荐项直接采纳并记入决策记录（规约 §7.8）；完整流程的核心集确认仍然必答。
4. **阅读。** 精读层与泛读层可按 Step 3 的方式分派——一篇一个收集器、host 预算按 `references/source_policy_zh.md` 拆成具体数字、一篇一个 `raw/` 前缀——各自按 `references/refs_rubric_zh.md` 的 survey 收集器返回格式返回。待读不足 6 篇就不分派，主会话自己读。抓回的论文页挂出官方仓库的，照 Step 3 的规矩由主 agent 补一次 GitHub 调用、把分数补齐——精读层照例都补，泛读层只在本就抓了页面时顺手补；绝不为找仓库专门抓页面。本模式不带图：配图是 Step 3 的事，属于一篇本模式并不写的笔记。
5. **只从池子里成文。** 每一节只用本轮抓回并缓存的材料起草（模板：`assets/survey_template_zh.md`，英文：`assets/survey_template.md`；评分：`references/refs_rubric_zh.md` 的综述一节）。正文点名的每篇论文都出现在带注引用表里，附记录 URL 与抓取日期；每条非显然论断带行内 `[@key]`——与 bib citekey 同为 `Year_Method_FirstAuthor` 形制、只在本文件内解析，日后该篇进 bib 时键保持不变；没有缓存来源的论断删掉或标注为本综述自己的推断；数字必须连同数据集与指标一起出现。对比表只收精读层的论文作行；缓存来源填不上的格写 `—`。
6. **自查。** 随机重开 5 组"论断↔引用来源"对着缓存核对；来源在该范围内撑不住的论断改写或删除——改的是正文，绝不改引用。确认带注引用表的每条链接都指向本轮抓过的页面或记录。
7. **Frontmatter 与覆写保护。** Frontmatter：`type: survey`、`topic`、`language`（按 Step 0.4 的规则）、`generated`（真实日期）、`sources`（读过方法来源时记它和它的 `updated`）、`papers`（各层计数）、以及 `model_id` / `model_trail`（规约 §8）。重跑撞上已有的 `<slug>_survey.md` 时逐字沿用 Step 9.4 的规则。
8. **摘要。** ≤500 字：来源与画像、计数账、写了哪些支、自查结果，以及转交——补读清单逐篇 `/skill:star-refs-reviewer <arxiv-id>`、或整单一次 `/skill:star-refs-reviewer add …`；定位交 `/skill:star-plan-coach` §2（相关工作与定位）；地图显示计划想做的那个缺口已经被填上的交 §1（问题定义与动机），计划尚不存在、无处可重开的交 `/skill:star-idea-storm`；项目需要笔记和核验 bib 时走完整流程。
