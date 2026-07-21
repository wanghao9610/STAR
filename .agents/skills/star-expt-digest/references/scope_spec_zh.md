# Scope Spec — 四种选择器、run 定日期与水位线

一份 digest 的诚实度不超过它的周期定义。本文件规定参数如何变成 run 集合、run 如何定日期，以及序列如何续接而不漏算、不重复。

## 四种选择器

解释参数，**先匹配先生效**：

| 参数 | 模式 | 范围 |
|---|---|---|
| *(无)* | `incremental` | 日期落在 `(水位线, 今天]` 的全部 run，全森林 |
| `<N>d`（`7d`、`30d`）或 `<YYYY-MM-DD>` | `window` | 日期落在 `[起点, 今天]` 的全部 run，全森林 |
| slug / 数字前缀 / 文件名 | `plan` | 该节点的**家族**，不设时间界 |
| `all` | `all` | 项目里的全部 run，全森林 |

`<N>d` 从今天往前 `N` 天起算，含端点。裸的 `<YYYY-MM-DD>` 表示"自该日期起"，含端点。既解析不成窗口也解析不成计划名的参数不是可以猜的：列出最接近的计划候选并提问（规约 §5.2）。

**plan 模式取的是家族，不是子树。** 给定一个节点，run 集合是其**全部后代叶子**的全部 run——那才是证据。它**上溯到根的祖先**也要读，但只作语境：根的 §4 claim 映射与 §5 kill-criteria 才是让一个叶子的数字有意义的东西，digest 的头条要对着它们写。祖先自身不贡献 run；内部节点不可执行（规约 §5.4）。这就是"包含父计划与子计划的结果"在实操上的含义：父提供问题，后代提供答案。

## 给 run 定日期

一个 run 的日期决定它是否落在窗内。取**第一个可得的**：

1. 其最新 `wkdrs/<run>/EXPT_ANALYSIS_<YYYY-MM-DD>.md` 文件名里的日期；
2. 否则取其 `wkdrs/<run>/EXEC_LOG.md` 里最后一条带日期的条目；
3. 否则该 run **无法定日期**——连同原因列进 digest 的缺口段，并且只在 `plan` 与 `all` 模式里纳入，因为那两种模式无需满足任何窗口。

**绝不用文件 mtime。** 它会因为一次 checkout、一次格式化、一次 `cp -r`、一次备份而改变——一份以 mtime 为键的 digest 会悄悄打乱历史。这与规约 §4 对写入日期的要求、以及 `status_spec.md` 对过期判断的要求是同一条纪律：比对记录下来的值，绝不比对文件系统时间戳。

一个 run **只定一次日期**，按上面的规则，即便它的两个候选日期不一致。四月跑完、七月才分析的 run，在窗口判定上算七月的 run，因为 digest 报告的是**证据**落地的时间，不是 GPU 转动的时间。当两个日期相差超过窗口自身长度时，在该 run 的行里说明这一点。

## 水位线

水位线是最新一份 digest 的 `covers.through`——从 frontmatter 读取，绝不推断。它就是"不带参数的 `$star-expt-digest`"之所以等于"自上次以来"的原因。

**解析增量窗：**

- 已有 digest → 窗为 `(covers.through, 今天]`，起点开区间，这样上一份 digest 的最后一天不会被报两次。
- 根本没有 `wkdrs/digests/`，或里面没有 digest → 这是第一份 digest。窗为全部历史，文件记 `mode: incremental`，`covers.from: —`，`previous: —`。

**推进它。** 只有覆盖区间**截止到今天**的 digest 才推进序列。具体说：

- `incremental` 与 `<N>d` / `<YYYY-MM-DD>` 窗口都截止到今天 → 推进它。
- `plan` 模式不设时间界，而且回溯性阅读不算进展 → 它把 `covers.through` 写成范围内最新的 run 日期，并且**不**成为下一次增量运行的续接点。
- `all` 截止到今天并重建序列 → 推进它。

这条规则保护的是：**一次向后看的 digest 绝不能导致下一次增量运行漏掉工作。** 由于水位线取的是"最新一份 digest 的 `covers.through`"，一份 `covers.through` 是旧日期的 `plan` 模式 digest 天然会被 max 忽略掉——但如果某个家族的 run 全部在今天跑完，而今天又写了一份 `plan` 模式 digest，它就会污染水位线。所以下一次增量运行取的是 **`mode` 为 `incremental`、`window` 或 `all` 的那些 digest 中**最新的 `covers.through`，完全忽略 `plan` 模式的文件。

## 重叠与幂等

- 两份 digest **可以**覆盖重叠的周期。那不是错误：为周五汇报写的 `7d` digest 并不会让周一那份增量 digest 失效。重叠是可见的，因为每份 digest 都写明了自己的窗口。
- 同一天用同一个选择器再跑一次会**覆盖当天的文件**（规约 §4.3）。它不追加，也不生成 `_v2`。
- 一个 run 出现在两份 digest 里是预期之内的，无需对账。绝不能发生的是一个 run **一份都没出现在**——而这恰恰由上面的半开增量窗与 `plan` 模式豁免共同防住。

## Frontmatter 契约

```yaml
---
type: digest
language: <en|zh>
generated: <YYYY-MM-DD>          # 系统时钟取的真实日期；绝不编造
mode: <incremental|window|plan|all>
scope: <whole forest | family of <prefix>_<slug>>
covers:
  from: <YYYY-MM-DD 或 "—">      # 仅当周期起点无界时写 "—"
  through: <YYYY-MM-DD>
previous: <EXPT_DIGEST_<YYYY-MM-DD>.md 或 "—">
sources:                          # 本 digest 报告过的每个 run，两层都算
  - run: <prefix>_<slug>
    report: <EXPT_ANALYSIS_<YYYY-MM-DD>.md 或 "none">
    tier: <report-backed|provisional>
    verdict: <met|partially met|not met|inconclusive|invalid|—>
---
```

`sources:` 承担两重职责：它是**下一份** digest 用来推导"发生了什么变化"的比对基线（`digest_rubric_zh.md`），也是"本 digest 写就时哪些 run 还处在临时层"的记录。临时层的行写 `verdict: —` 才是对的——临时 run 没有判定，往里填一个，就是在编造本 skill 无权做出的判断。
