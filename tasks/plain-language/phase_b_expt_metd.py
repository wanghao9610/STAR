#!/usr/bin/env python3
"""Phase B terminology rewrite for star-expt-analyst / star-expt-digest / star-metd-summarize.

Applies the judgment-call terms from tasks/plain-language/glossary.md to the three
skills in all four trees. Ordered literal (and a few regex) rules; reports counts.
"""
import re
import sys
from pathlib import Path

ROOT = Path("/Users/haowang/Workdir/Projs/Gits/STAR")
TREES = [".claude", ".agents", ".cursor", ".kimi-code"]
SKILLS = ["star-expt-analyst", "star-expt-digest", "star-metd-summarize"]

L = "lit"
R = "rex"

RULES = [
    # ---------- Phase A collateral: filenames inside backticks were translated ----------
    (L, "analysis_评分表_zh.md", "analysis_rubric_zh.md"),
    (L, "analysis_评分表.md", "analysis_rubric.md"),
    (L, "digest_评分表_zh.md", "digest_rubric_zh.md"),
    (L, "digest_评分表.md", "digest_rubric.md"),
    (L, "判判判定日期", "判定日期"),

    # ================= ENGLISH =================
    # --- ledger (noun) -> results table / model record file ---
    (L, "cross-run ledger", "cross-run results table"),
    (L, "results ledger", "results table"),
    (L, "the verified ledger", "the verified results table"),
    (L, "The verified ledger", "The verified results table"),
    (L, "the project ledger", "the project results table"),
    (L, "The project ledger", "The project results table"),
    (L, "A scoped ledger", "A scoped results table"),
    (L, "a stale ledger", "a stale results table"),
    (L, "a ledger older than", "a results table older than"),
    (L, "the ledger cites it", "the results table cites it"),
    (L, "a ledger number", "a number in the results table"),
    (L, "Compile the ledger", "Compile the results table"),
    (L, "compile a ledger from nothing", "compile a results table from nothing"),
    (L, "into one ledger,", "into one results table,"),
    (L, "What the ledger never does", "What the results table never does"),
    (L, "the ledger shows what exists", "the results table shows what exists"),
    (L, "a ledger that silently replaces", "a results table that silently replaces"),
    (L, "means the ledger is stale", "means the results table is stale"),
    (L, "writes no ledger, and the ledger's own trust model",
        "writes no results table, and the results table's own trust model"),
    (L, "entered into the ledger", "entered into the results table"),
    (L, "contradict the ledger", "contradict the results table"),
    (L, "the ledger reports numbers", "the results table reports numbers"),
    (L, "the ledger is `", "the results table is `"),
    (L, "or the ledger was changed.", "or the results table was changed."),
    (L, "or the ledger.", "or the results table."),
    (L, "run that fed this ledger", "run that fed this results table"),
    (L, "narrative the ledger is forbidden", "narrative the results table is forbidden"),
    # ledger (noun), MODEL_LEDGER sense
    (L, "in the ledger; a reader", "in the model record file; a reader"),
    (L, "so this ledger inherits", "so this model record file inherits"),
    (L, "so the ledger inherits", "so the model record file inherits"),
    (L, "the ledger has no quality signal", "the model record file has no quality signal"),
    # rollup
    (L, "the cross-artifact model-provenance rollup at",
        "the combined table of which model wrote what at"),

    # --- surface / boundary ---
    (L, "What the analysis surfaces beyond your write boundary is routed:",
        "Anything the analysis finds beyond what it may write is routed:"),
    (L, "Route what the analysis surfaces beyond the write boundary:",
        "Route anything the analysis finds beyond what it may write:"),
    (L, "What the digest surfaces beyond your write boundary is routed:",
        "Anything the digest finds beyond what it may write is routed:"),
    (L, "Route what the digest surfaces beyond the write boundary:",
        "Route anything the digest finds beyond what it may write:"),
    (L, "What compiling surfaces beyond your write boundary is routed:",
        "Anything compiling finds beyond what it may write is routed:"),
    (L, "Route what compiling surfaces beyond the write boundary:",
        "Route anything compiling finds beyond what it may write:"),
    (L, "**Warnings worth surfacing**", "**Warnings worth reporting**"),
    (L, "surface it plainly and route it", "report it plainly and route it"),
    (L, "The whole evaluation surface in one table", "The whole evaluation setup in one table"),

    # --- ladder ---
    (L, "## Severity ladder", "## Severity levels"),
    (L, "## Run verdict ladder", "## Run verdict levels"),

    # --- strategy plan / strategy signal ---
    (L, "**strategy plans** (roots and internal nodes)", "**top-level plans** (roots and internal nodes)"),
    (L, "every strategy plan finalized", "every top-level plan finalized"),
    (L, "every strategy plan carries", "every top-level plan carries"),
    (L, "each strategy plan missing", "each top-level plan missing"),
    (L, "an unfinalized strategy plan", "an unfinalized top-level plan"),
    (L, "The **root** strategy plan at the top", "The **root** plan at the top"),
    (R, r"\bStrategy signals\b", "plan-level findings"),
    (R, r"\bStrategy signal\b", "plan-level finding"),
    (R, r"\bstrategy signals\b", "plan-level findings"),
    (R, r"\bstrategy signal\b", "plan-level finding"),

    # --- land / landed / lands ---
    (L, "lands in exactly one tier", "belongs to exactly one tier"),
    (L, "when the *evidence* landed", "when the *evidence* was in place"),
    (L, "where the artifact lands under", "where the artifact is written under"),
    (L, "outputs land under", "outputs are written under"),

    # --- owed / debt ---
    (L, "## 8. Gaps & Debts", "## 8. Gaps & Outstanding Follow-ups"),
    (L, "What the period leaves owing:", "What the period still leaves to do:"),
    (L, "- <what is owed> —", "- <the outstanding follow-up> —"),
    (L, "**Gaps and debts**", "**Gaps and outstanding follow-ups**"),

    # --- health read / leakage smells / re-seeds / time axis ---
    (L, "chat-only health read", "chat-only quick check"),
    (L, "A quick health read of a run", "A quick check of a run"),
    (L, "leakage smells", "signs of data leakage"),
    (L, "re-seeds the series", "restarts the series"),
    (L, "`all` re-seeds from the beginning", "`all` covers the whole history from the beginning"),
    (L, "lately, on the time axis", "lately, in date order"),

    # --- collector delegate ---
    (L, "Collectors return exactly these two lists", "Read-only subagents return exactly these two lists"),
    (L, "Collectors never write, never read outside their list",
        "These read-only subagents never write, never read outside their list"),
    (L, "Collectors extract and return;", "These read-only subagents extract and return;"),
    (L, "Collectors extract only.", "Read-only subagents extract only."),

    # ================= CHINESE =================
    # --- 点名 (specials first, then the general 写明) ---
    (L, "一个信号都不点名的叶子", "一个信号都没提到的叶子"),
    (L, "点名并路由未完成的工作", "列出未完成的工作并转交"),
    (L, "（点名要写的那些）", "（列出要写的那些）"),
    (L, "plan 模式下点名为取", "plan 模式下列出为取"),
    (L, "`traces_to` 点名了", "`traces_to` 指明了"),
    (L, "值得点名的缺口", "值得写出来的缺口"),
    (L, "点名", "写明"),

    # --- 路由 -> 转交 ---
    (L, "都走路由：", "都转交出去："),
    (L, "走路由：", "转交出去："),
    (L, "以及路由。", "以及转交去向。"),
    (L, "带上它的路由：", "带上它的转交去向："),
    (L, "路由到", "转交给"),
    (L, "路由给", "转交给"),
    (L, "路由出去", "转交出去"),
    (L, "并路由", "并转交"),
    (L, "路由", "转交"),

    # --- 契约 -> 格式约定 ---
    (L, "观察契约", "观察格式约定"),
    (L, "指标行契约", "指标行格式约定"),
    (L, "提取契约", "提取格式约定"),
    (L, "Frontmatter 契约", "Frontmatter 格式约定"),

    # --- 阶梯 -> 分级 ---
    (L, "## 严重度阶梯", "## 严重度分级"),
    (L, "## run 判定阶梯", "## run 判定分级"),

    # --- 喂 -> 输入给 / 供给 ---
    (L, "哪些叶子喂哪份文档", "哪些叶子供给哪份文档"),
    (L, "| 喂给 |", "| 供给 |"),
    (L, "同时喂 dataset 与 training", "同时输入给 dataset 与 training"),
    (L, "同时喂多份文档", "同时输入给多份文档"),
    (L, "可以喂多份文档", "可以输入给多份文档"),
    (L, "只喂 overview", "只输入给 overview"),
    (L, "逐节喂", "逐节输入"),
    (L, "喂过本文档", "输入给本文档"),
    (L, "喂给", "输入给"),
    (L, "它们喂给", "它们输入给"),

    # --- 头条 -> 关键指标 / 核心结论 ---
    (L, "头条指标", "关键指标"),
    (L, "头条数字", "关键指标数字"),
    (L, "头条表格", "关键指标表格"),
    (L, "写头条", "写核心结论"),
    (L, "## 2. 头条 —— 学到了什么", "## 2. 核心结论 —— 学到了什么"),
    (L, "报告的头条", "报告的核心结论"),
    (L, "作为报告头条", "作为报告的核心结论"),
    (L, "digest 的头条里", "digest 的核心结论里"),
    (L, "digest 的头条要对着它们写", "digest 的核心结论要对着它们写"),
    (L, "头条（学到了什么）", "核心结论（学到了什么）"),
    (L, "头条就恰如其分地说出这件事", "核心结论就恰如其分地说出这件事"),
    (L, "头条", "核心结论"),

    # --- 台账 / 总账 -> 结果汇总表 / 模型记录表 ---
    (L, "### Step 8：台账（仅 ledger 模式）", "### Step 8：模型记录表（仅 ledger 模式）"),
    (L, "本台账因此继承同一限制", "本模型记录表因此继承同一限制"),
    (L, "台账因此继承同一限制", "模型记录表因此继承同一限制"),
    (L, "本台账里没有任何质量信号", "本模型记录表里没有任何质量信号"),
    (L, "本台账的盲区", "本模型记录表的盲区"),
    (L, "结果台账", "结果汇总表"),
    (L, "结果总账", "结果汇总表"),
    (L, "过期台账", "过期的结果汇总表"),
    (L, "因为一份窄总账悄悄替换掉更宽的总账", "因为一份范围窄的结果汇总表悄悄替换掉更宽的那份"),
    (L, "台账", "结果汇总表"),
    (L, "总账", "结果汇总表"),

    # --- delta / gap ---
    (L, "绝不参与 delta", "绝不参与差值计算"),
    (L, "跨种子均值、delta、百分比", "跨种子均值、差值、百分比"),
    (L, "段里的任何 delta", "段里的任何差值"),
    (L, "指标 delta 归因", "指标差值归因"),
    (L, "绝不把 delta 归因", "绝不把差值归因"),
    (L, "任何 delta 都能被说成提升", "任何差值都能被说成提升"),
    (L, "真实提升的 delta", "真实提升的差值"),
    (L, "没人填的那个 gap", "没人填的那个缺口"),

    # --- misc single-point metaphors ---
    (L, "框架不问自答写出来的产物", "框架自动生成的产物"),
    (L, "沿**读者**需要的轴线重新切分", "沿**读者**需要的维度重新组织"),
    (L, "沿方法的轴线组织，而不是计划的轴线。", "沿方法本身的维度组织，而不是计划的结构。"),
    (L, "按方法本身的轴线而非计划的轴线合并",
        "按读者需要的维度（方法、数据、训练、评测）而非计划的结构合并"),
    (L, "按时间轴总结", "按时间顺序总结"),
    (L, "结果支持 / 推翻 / 悬置 `traces_to` 里的主张？",
        "结果支持 / 推翻 `traces_to` 里的主张，还是暂不下结论？"),
]


def main(apply: bool) -> int:
    files = []
    for tree in TREES:
        for skill in SKILLS:
            files.extend(sorted((ROOT / tree / "skills" / skill).rglob("*.md")))
    counts = {i: 0 for i in range(len(RULES))}
    changed = 0
    for path in files:
        text = original = path.read_text(encoding="utf-8")
        for i, (kind, pat, rep) in enumerate(RULES):
            if kind == L:
                n = text.count(pat)
                if n:
                    text = text.replace(pat, rep)
            else:
                text, n = re.subn(pat, rep, text)
            counts[i] += n
        if text != original:
            changed += 1
            if apply:
                path.write_text(text, encoding="utf-8")
    for i, (kind, pat, rep) in enumerate(RULES):
        flag = "   " if counts[i] else "!!!"
        print(f"{flag} {counts[i]:4d}  {pat[:60]!r} -> {rep[:50]!r}")
    print(f"\n{len(files)} files scanned, {changed} would change (apply={apply})")
    return 0


if __name__ == "__main__":
    sys.exit(main(apply="--apply" in sys.argv))
