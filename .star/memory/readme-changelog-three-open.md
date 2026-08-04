---
type: pref
scope: global
language: zh
verified: 2026-08-04
model_id: claude-opus-5
source: conversation
---

两份 README 的更新日志只展开最新的三条发布，更早的条目全部折进 `<details>` 块（英文页 `<summary>Earlier releases</summary>`，中文页「更早的版本」）。

**Why:** 每条发布条目都是一整段长文，可见列表一超过三条，读者在读到当前版本之前就先滑过了几屏历史；折叠保留全部历史，又让页面停在当前版本上。
**How to apply:** 新增一条版本时是两个动作，不是一个——新条目插在可见列表最前面，原来的第三条移进折叠块的最前面（折叠块内同样新的在前）；两份 README 一起改。提交信息里按惯例写明哪一条折走了，例如「the change log's v0.1.14 entry covers the skill roster, and v0.1.11 folds away」。
