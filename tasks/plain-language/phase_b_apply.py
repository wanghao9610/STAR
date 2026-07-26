#!/usr/bin/env python3
"""Phase B of the plain-language rewrite: the judgement-call terms, applied to
star-plan-decomposer / star-plan-executor / star-plan-reviser in all four trees.

Each rule names the file (relative to <tree>/skills/), the exact old text, the new
text, and the trees where it is expected to match at least once. Anything that
matches zero times where it was expected is reported so it can be handled by hand.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ALL = ("claude", "agents", "cursor", "kimi")
TREES = {
    "claude": ROOT / ".claude/skills",
    "agents": ROOT / ".agents/skills",
    "cursor": ROOT / ".cursor/skills",
    "kimi": ROOT / ".kimi-code/skills",
}
COPIES = ("claude", "cursor", "kimi")  # the three that stay heading-identical

RULES = []


def R(f, old, new, trees=ALL, regex=False, strict=True):
    RULES.append((f, old, new, tuple(trees), regex, strict))


DEC = "star-plan-decomposer/"
EXE = "star-plan-executor/"
REV = "star-plan-reviser/"

# ---------------------------------------------------------------- decomposer
f = DEC + "SKILL.md"
R(f, "under a hierarchical numeric prefix",
     "under a numeric prefix that shows its place in the tree")
R(f, "Supports arbitrary decomposition depth.",
     "A sub-plan can be decomposed again, to any depth.")
R(f, "the `involve` dial for this run", "the `involve` level for this run")
R(f, "the one signal that a strategy plan is ready to consume",
     "the one signal that a top-level plan is ready to consume")
R(f, "The check's verdict and evidence land in the run's",
     "The check's verdict and evidence are written into the run's")
R(f, "a still-coarse unit can be refined with",
     "a unit that is still too big to run can be refined with")
R(f, "for any unit that is still coarse.",
     "for any unit that is still too big to run.")
R(f, "(user-confirmed execution sync-back)",
     "(the user-confirmed write-back of what execution changed)")
R(f, "Dial-immune here:", "Always asked here:")
R(f, "Dialed at `low`:", "Set to `low`:")

f = DEC + "SKILL_zh.md"
R(f, "按分层数字前缀写入 metds/plans/", "按能体现其在树中位置的数字前缀写入 metds/plans/")
R(f, "支持任意深度的拆解。", "子计划还能继续再拆，深度不限。")
R(f, "`involve=low|medium|high` 记号", "`involve=low|medium|high` 这个写法")
R(f, "点名哪些章节仍为", "指明哪些章节仍为")
R(f, "根 §4 点名、而", "根 §4 写明、而")
R(f, "`references/subplan_评分表_zh.md`", "`references/subplan_rubric_zh.md`")
R(f, "`references/subplan_评分表.md`", "`references/subplan_rubric.md`")

f = DEC + "references/naming_convention.md"
R(f, "(decompose into ≤10 coarse units now, then recurse into the heavy ones)",
     "(decompose into ≤10 units now, each still too big to run, then recurse into the heavy ones)")

# ------------------------------------------------------------------ executor
f = EXE + "SKILL.md"
R(f, r"checkpoints(\s+)durable execution", r"records\1durable execution",
  trees=COPIES, regex=True)
R(f, "checkpoint progress under a run-specific wkdrs directory",
     "record progress under a run-specific wkdrs directory", trees=("agents",))
R(f, "gates it through ExitPlanMode", "waits for approval through ExitPlanMode",
  trees=("claude",))
R(f, "gates it on user approval,", "waits for the user's approval,", trees=("cursor",))
R(f, "gates it for approval", "waits for the user's approval", trees=("kimi",))
R(f, r"Syncs(\s+)user-confirmed(\s+)deviations", r"Writes\1user-confirmed\2deviations", regex=True)
R(f, "execution-settled values", "values settled by execution")
R(f, r"with a Revision History(\s+)trail", r"and adds a Revision History\1entry", regex=True)
R(f, "the `involve` dial for this run", "the `involve` level for this run")
R(f, "**Use the project runtime and run surface.**",
     "**Use the project runtime and launch entry point.**", trees=COPIES)
R(f, "the actual run surface before planning",
     "the actual launch entry point before planning", trees=("agents",))
R(f, "a **user-confirmed sync-back** of the affected §2–§5 content",
     "a **user-confirmed write-back** of the affected §2–§5 content")
R(f, "/ bound check}`", "/ the step's own check}`", trees=COPIES)
R(f, "how to run via conda, the bound check, and",
     "how to run via conda, the step's own check, and", trees=COPIES)
R(f, "**the main agent re-runs the bound check**",
     "**the main agent re-runs the step's own check**", trees=COPIES)
R(f, "Keep the main-loop reply concise", "Keep the main agent's reply concise", trees=COPIES)
R(f, "is a strategy signal — route it through feedback reflux below, never sync it.",
     "is a plan-level finding — route it back to the plan as described below, never sync it.",
  trees=COPIES)
R(f, "**Feedback reflux (strategy signal).**",
     "**Route it back to the plan (plan-level finding).**", trees=COPIES)
R(f, "**surface it explicitly**", "**point it out explicitly**", trees=COPIES)
R(f, "Sync-back is idempotent:", "The write-back is idempotent:")
R(f, "If Step 6 surfaced a strategy signal", "If Step 6 reported a plan-level finding",
  trees=COPIES)
R(f, "**only** through the user-confirmed sync-back protocol",
     "**only** through the user-confirmed write-back procedure")
R(f, "(feedback reflux).", "(route it back to the plan).", trees=COPIES)
R(f, "Dial-immune here:", "Always asked here:")
R(f, "Dialed at `low`:", "Set to `low`:")
R(f, "`code/` may be empty codebase", "`code/` may be an empty codebase", trees=COPIES)
# .agents-only executor wording
R(f, "artifacts, and a bound check.", "artifacts, and the action's own check.", trees=("agents",))
R(f, "Update the log after each bound check.", "Update the log after each action's check.",
  trees=("agents",))
R(f, "run its narrow bound check through the project environment",
     "run its own narrow check through the project environment", trees=("agents",))
R(f, "Re-run or independently inspect the bound check in the main agent.",
     "Re-run or independently inspect the action's own check in the main agent.",
  trees=("agents",))
R(f, "record a **Strategy signal** in the log", "record a **Plan-level finding** in the log",
  trees=("agents",))
R(f, "routes through the strategy signal in point 5, never through sync-back.",
     "routes through the plan-level finding in point 5, never by writing it back into the plan.",
  trees=("agents",))

f = EXE + "SKILL_zh.md"
R(f, "并留下 Revision History 记录", "并追加一条 Revision History 条目", trees=COPIES)
R(f, "并留下 Revision History，使计划文件", "并追加一条 Revision History 条目，使计划文件",
  trees=("agents",))
R(f, "`involve=low|medium|high` 记号", "`involve=low|medium|high` 这个写法")
R(f, "`exec_status` + `exec_runs` 指针", "`exec_status` + `exec_runs` 索引", trees=COPIES)
R(f, "点名本该负责它的数据就绪叶子", "指明本该负责它的数据就绪叶子", trees=COPIES)
R(f, "或路由到 `star-plan-decomposer", "或转交给 `star-plan-decomposer", trees=COPIES)
R(f, "以 delta 形式(ADDED", "以变更项形式(ADDED", trees=COPIES)
R(f, "并点名该章节", "并写明该章节")
R(f, "并点名任何已带未提交改动的路径", "并列出任何已带未提交改动的路径", trees=COPIES)
R(f, "的契约派一个", "的格式约定派一个", trees=("claude", "kimi"))
R(f, "的契约用 `Task` 派一个", "的格式约定用 `Task` 派一个", trees=("cursor",))
R(f, "并把失败喂回", "并把失败信息回传", trees=COPIES)
R(f, "记一行 delta 后继续", "记一行变更项后继续", trees=COPIES)
R(f, "只有用户自己点名才删", "只有用户自己指明才删")
R(f, "`references/exec_评分表_zh.md`", "`references/exec_rubric_zh.md`")
R(f, "在确认点上点名(规约 §1)", "在确认点上列出(规约 §1)", trees=COPIES)
# .agents-only
R(f, "检查 `.env`、点名输入、", "检查 `.env`、写明的输入、", trees=("agents",))
R(f, "每个 action 都点名文件、命令、工件和范围受限检查",
     "每个 action 都写明文件、命令、工件和范围受限检查", trees=("agents",))
R(f, "中的窄契约", "中那份范围很窄的格式约定", trees=("agents",))
R(f, "验证点名的数据集", "验证写明的数据集", trees=("agents",))
R(f, "点名应负责它的 data-readiness leaf", "指明应负责它的 data-readiness leaf",
  trees=("agents",))
R(f, "以 delta 形式（ADDED", "以变更项形式（ADDED", trees=("agents",))
R(f, "同时点名任何已有未提交修改的路径", "同时列出任何已有未提交修改的路径", trees=("agents",))
R(f, "记录 delta 行并继续", "记录变更项行并继续", trees=("agents",))
R(f, "在日志中记录 **Strategy signal**", "在日志中记录 **方向性信号**", trees=("agents",))

f = EXE + "references/agent_dispatch_spec.md"
R(f, "plus its bound check", "plus the step's own check", trees=COPIES, strict=False)
R(f, "plus its bound check", "plus the action's own check", trees=("agents",), strict=False)
R(f, "the bound check's result", "the result of the step's own check", trees=COPIES)
R(f, "re-runs the bound check**", "re-runs the step's own check**", trees=COPIES)
R(f, "re-runs or independently inspects the bound check before checkpointing",
     "re-runs or independently inspects the action's own check before checkpointing",
  trees=("agents",))

f = EXE + "references/agent_dispatch_spec_zh.md"
R(f, "# Agent 派发契约", "# Agent 派发格式约定", trees=COPIES)
R(f, "# 选择性委派契约", "# 选择性委派格式约定", trees=("agents",))
R(f, "把失败喂回下一次派发", "把失败信息回传给下一次派发", trees=COPIES)

f = EXE + "references/orient_checklist.md"
R(f, "**Find the run surface.**", "**Find the launch entry point.**")
R(f, "plus the identified run surface", "plus the launch entry point you identified")

f = EXE + "references/orient_checklist_zh.md"
R(f, "就是喂给 EXEC_PLAN", "就是输入给 EXEC_PLAN")
R(f, "它直接喂给 Step 3", "它直接输入给 Step 3")

f = EXE + "references/stop_line_rules.md"
R(f, "via the project's run surface (`execs/run.sh`)",
     "via the project's launch entry point (`execs/run.sh`)")

f = EXE + "references/plan_sync_rules.md"
R(f, "# Plan Sync-back Rules —", "# Plan Write-back Rules —")
R(f, "the boundary where sync-back must **not** be used",
     "the boundary where the write-back must **not** be used")
R(f, "surface the conflict", "report the conflict")
R(f, "Sync-back is idempotent:", "The write-back is idempotent:")
R(f, "(`star-plan-decomposer`), not sync-back.", "(`star-plan-decomposer`), not a write-back.")
R(f, "(feedback reflux).", "(route it back to the plan).")
R(f, "that is a strategy signal: record it, surface it, route it through feedback reflux.",
     "that is a plan-level finding: record it, report it, route it back to the plan.")
R(f, "sync-back only keeps §2–§5 current", "the write-back only keeps §2–§5 current")
R(f, "A §5 sync-back must always quote", "A §5 write-back must always quote")

f = EXE + "references/plan_sync_rules_zh.md"
R(f, "什么算偏差、delta 形式、写回流程", "什么算偏差、变更项形式、写回流程")
R(f, "## Delta 形式", "## 变更项形式")
R(f, "类型仿 OpenSpec delta", "类型仿 OpenSpec 的变更项")
R(f, "且该行必须点名那个章节", "且该行必须写明那个章节")

f = EXE + "assets/exec_plan_template.md"
R(f, "artifacts land under wkdrs/<run>/", "artifacts are written under wkdrs/<run>/")

f = EXE + "assets/exec_plan_template_zh.md"
R(f, "实质性 delta(references/plan_sync_rules_zh.md)",
     "实质性变更项(references/plan_sync_rules_zh.md)")
R(f, "栏点名该章节", "栏写明该章节")

f = EXE + "assets/exec_log_template.md"
R(f, r"filled by the MAIN LOOP re-running the bound(\s+)check",
     r"filled by the main agent re-running the step's own\1check", trees=COPIES, regex=True)
R(f, "filled by the MAIN LOOP re-running or", "filled by the main agent re-running or",
  trees=("agents",))
R(f, "independently inspecting the bound check",
     "independently inspecting the action's own check", trees=("agents",))
R(f, "**Strategy signal** and note", "**Plan-level finding** and note")

f = EXE + "assets/exec_log_template_zh.md"
R(f, "delta 形式与 EXEC_PLAN", "变更项形式与 EXEC_PLAN")

# ------------------------------------------------------------------- reviser
f = REV + "SKILL.md"
R(f, r"\(children(\s+)rollups for internal nodes\)",
     r"(a summary of the children\1for internal nodes)", regex=True)
R(f, "walks revision candidates one question at a time",
     "goes through revision candidates one question at a time", trees=COPIES)
R(f, "walk revision candidates one question at a time",
     "go through revision candidates one question at a time", trees=("agents",))
R(f, "Surface reverse `depends_on` edges", "Point out reverse `depends_on` edges")
R(f, "let the bumped `updated` surface staleness", "let the bumped `updated` show staleness",
  trees=COPIES)
R(f, "lets `$star-flow-status` surface staleness", "lets `$star-flow-status` show staleness",
  trees=("agents",))
R(f, "+ children rollup)", "+ a summary of the children)")
R(f, "(notably **Strategy signal** notes", "(notably **Plan-level finding** notes")
R(f, "commands, strategy signals)", "commands, plan-level findings)")
R(f, "Keep the running ledger as you go", "Keep the running record as you go")
R(f, "without the ledger the user approves edit 9", "without that record the user approves edit 9")
R(f, "candidates skipped, ripple warnings.", "candidates skipped, knock-on effects to watch.")

f = REV + "SKILL_zh.md"
R(f, "每条审查结论都带证据指针", "每条审查结论都带证据出处")
R(f, "的收集器契约", "的收集器格式约定", trees=COPIES)
R(f, "collector 契约", "collector 格式约定", trees=("agents",))
R(f, "§2 点名的输入", "§2 写明的输入")
R(f, "**Strategy signal**", "**方向性信号**")
R(f, "命令、strategy signal）", "命令、方向性信号）")
R(f, "点名受影响的 children", "指明受影响的 children")
R(f, "在 §2–§3 点名代码时", "在 §2–§3 写明代码时", trees=("agents",))

f = REV + "references/review_spec.md"
R(f, "step statuses, bound-check results", "step statuses, the step's own check results")
R(f, "incl. **Strategy signal** entries", "incl. **Plan-level finding** entries")
R(f, "kill-criteria hits and strategy signals that bear on",
     "kill-criteria hits and plan-level findings that bear on")
R(f, "— Strategy-signal or kill-criterion notes", "— plan-level finding or kill-criterion notes")
R(f, "## Verification ladder", "## Verification levels")
R(f, "by the highest rung that actually holds", "by the highest level that actually holds")
R(f, "every rung applicable to the item holds", "every level applicable to the item holds")
R(f, "can be met at rungs 1+3", "can be met at levels 1+3")
R(f, "**Cheap-check boundary**:", "**What counts as a cheap check**:")
R(f, "the full ladder over its own run", "all three levels over its own run")
R(f, "a child's strategy signal is evidence", "a child's plan-level finding is evidence")
R(f, "children rollup for root/internal targets",
     "a summary of the children for root/internal targets")
R(f, "kill-criteria hits and quoted strategy signals",
     "kill-criteria hits and quoted plan-level findings")
R(f, "and a blast radius grade", "and a grade for how far the change reaches")
R(f, "**Blast radius**:", "**How far the change reaches**:")

f = REV + "references/review_spec_zh.md"
R(f, "**Strategy signal**", "**方向性信号**")
R(f, "| §2/§3 点名的", "| §2/§3 写明的")
R(f, "kill-criteria 命中与 strategy signal |", "kill-criteria 命中与方向性信号 |")
R(f, "## 收集器契约", "## 收集器格式约定")
R(f, "——Strategy signal 或 kill-criterion 记录", "——方向性信号或 kill-criterion 记录")
R(f, "针对点名的每个模块/入口", "针对写明的每个模块/入口")
R(f, "## 核实阶梯", "## 核实分级")
R(f, "适用于该项的所有梯级全部成立", "适用于该项的所有级别全部成立")
R(f, "**低开销检查边界**：", "**什么算低开销检查**：")
R(f, "对它自己的 run 走完整阶梯", "对它自己的 run 走完整三级")
R(f, "（子计划的 strategy signal 就是质疑父假设的证据）",
     "（子计划的方向性信号就是质疑父假设的证据）")
R(f, "结论 + 证据指针", "结论 + 证据出处")
R(f, "kill-criteria 命中与原文引用的 strategy signal",
     "kill-criteria 命中与原文引用的方向性信号")
R(f, "**证据指针**必须具体", "**证据出处**必须具体")

f = REV + "references/revision_rules.md"
R(f, "# Revision Rules — authority, trail, and ripple",
     "# Revision Rules — authority, trail, and knock-on effects")
R(f, "## Ripple duties", "## Knock-on effect duties")

f = REV + "references/revision_rules_zh.md"
R(f, "只点名最近一次写入者", "只写明最近一次写入者")
R(f, "在最终汇报里点名受影响的 children", "在最终汇报里指明受影响的 children")

f = REV + "assets/review_report_template.md"
R(f, r"children rollup(\s+)\(per child", r"a summary of the children\1(per child", regex=True)
R(f, "kill-criteria hits and Strategy signals quoted from the log.",
     "kill-criteria hits and plan-level findings quoted from the log.")
R(f, "## 6. Ripple Map", "## 6. Knock-on Effects")
R(f, "Numbered. Blast radius: local (this file)",
     "Numbered. How far the change reaches: local (this file)")
R(f, "adopted changes land in the plan file", "adopted changes are written into the plan file")

f = REV + "assets/review_report_template_zh.md"
R(f, "原文引用的 Strategy signal。", "原文引用的方向性信号。")


def main():
    dry = "--apply" not in sys.argv
    problems = []
    total = 0
    for relpath, old, new, want, is_re, strict in RULES:
        for tree in ALL:
            path = TREES[tree] / relpath
            if not path.exists():
                problems.append(f"MISSING FILE {tree}: {relpath}")
                continue
            text = path.read_text(encoding="utf-8")
            if is_re:
                out, n = re.subn(old, new, text)
            else:
                n = text.count(old)
                out = text.replace(old, new)
            if tree not in want:
                if n and strict:
                    problems.append(f"UNEXPECTED HIT {tree:7s} {relpath}\n          {old!r}")
                continue
            if n == 0:
                problems.append(f"NO MATCH  {tree:7s} {relpath}\n          {old!r}")
                continue
            if not dry:
                path.write_text(out, encoding="utf-8")
            total += n
    print(f"{len(RULES)} rules, {total} substitutions{' (dry run)' if dry else ''}")
    for p in problems:
        print(p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
