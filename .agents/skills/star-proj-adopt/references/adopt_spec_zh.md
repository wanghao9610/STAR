# 接入规范——勘察配方、清单格式约定与写入规则

`star-proj-adopt` 背后的确切规则。`SKILL.md` 给出形状，本文件给出判定标准。

## 1. 勘察（只读）

六个勘察项，每项带一个置信度：`certain`（唯一且无歧义的匹配）、`likely`（唯一匹配但信号弱）、`unknown`（没有或有多个）。只有 `likely` 与 `unknown` 的行会进入确认点 1；`certain` 的行只作报告，不去问。这个标签决定了要问什么，因此必须由主 agent 来标：交给子代理勘察的那一项，只返回发现与证据路径，置信度一列留空，子代理不决定用户会被问到什么。

| 勘察项 | 看什么 | 何时算 `certain` |
|---|---|---|
| 源码 | 含 `__init__.py` 的顶层目录；入口脚本导入的是哪个；`pyproject.toml` / `setup.py` 的 `name` 与 `packages` | 顶层可导入包恰好一个，且入口脚本导入的就是它 |
| 运行时 | `conda env list`、`.venv/`、`which python`、已有脚本里的环境名、`environment.yml` / `requirements*.txt` | 恰好一个环境，其名字与项目吻合，或其 python 能导入源码包 |
| 数据 | 名为 `data*` / `dataset*` 的目录、配置与 dataloader 默认值里的路径、体量大的非代码目录树 | 唯一路径，且被不止一个配置或脚本引用 |
| 权重 | 名为 `ckpt*` / `checkpoint*` / `weights` / `pretrained` / `models` 的目录、`.pt` / `.pth` / `.safetensors` / `.bin` 的聚集处 | 唯一路径，且入口脚本加载的正是其中的 checkpoint |
| 输出 | 名为 `out*` / `runs` / `logs` / `exp*` / `work_dir*` 的目录、TensorBoard event 文件、按 run 分子目录的模式 | 唯一路径，且其子目录看起来就是一次次 run（时间戳、配置名） |
| 入口 | 可执行脚本、`if __name__ == "__main__"`、`console_scripts`、`Makefile` / `*.sh` 目标、README 里的命令 | ——始终作为一个列表报告，绝不压成单一答案 |

同时为工作清单记录：首次提交日期、提交总数、最近改动的 20 条路径，以及 README 里任何描述状态或结果的段落。

**整个勘察过程不写任何东西。** 不运行项目代码，不导入它的包，不创建环境。

## 2. 映射块

确认点 1 之前把勘察结果报成一整块，每个勘察项一行：

```
source     CODE_NAME=<dir>            certain   （唯一可导入包；被 train.py 导入）
runtime    PYTHON_HOME=<path>         likely    （conda env "ovd"；与 scripts/train.sh 里的环境名一致）
data       datas/ -> <path>           certain   （被 4 个配置引用）
weights    inits/ -> <path>           unknown   （未找到 checkpoint 目录）
outputs    <path>（逐 run 链接）      likely    （12 个带时间戳的子目录）
entry      3 个启动入口                —         （scripts/train.sh、scripts/eval.sh、tools/infer.py）
```

## 3. 软链规则

对 `datas/`、`inits/` 逐一按此顺序判定：

1. 路径不存在 → 建软链指向已确认的目标。
2. 路径是空目录（或只有 `.gitkeep`）→ 移除占位，建软链。
3. 路径已是指向同一目标的软链 → 保持不动，报告 `already linked`。
4. 路径是指向**其他目标**的软链，或是**非空的真实目录** → 什么都不做，报告冲突并询问。绝不替换，绝不合并进去。
5. 已确认的目标就在仓库内且位置正确 → 不需要软链，报告 `already in place`。

目标在仓库之外是可接受的；把它的绝对路径记入 `metds/adopt.md`。目标位于网络盘或可移动挂载点时，记录中注明这一点。

`wkdrs/` 绝不建成软链：git 拒绝暂存软链之后的任何路径，而它下面的 run 记录——执行日志、评审、分析、digest、结果汇总表——必须能进版本库（规约 §1.6）。不存在 → 建成真实目录。已经是软链 → 报告冲突并询问；用户同意后把链接换成真实目录，这不会删除它指向的任何内容。用户不同意 → 链接保留，§6 不在它下面写任何东西：选中的 run 报告出来并留在清单里，不放进提交提议。已有输出树从它内部接入，每个选中的 run 一个链接（§6）。之后某个 run 的大文件要放到别的盘时，链接 `wkdrs/<run>/` 里面的产物子目录，绝不链接 `wkdrs/` 或 `wkdrs/<run>/` 本身。

## 4. 包装脚本规则

用户保留的每个入口对应一个 `execs/scpts/<name>.sh`。包装脚本**调用已有命令，且对它不作任何改动**：

```bash
#!/usr/bin/env bash
set -euo pipefail

# 接入生成的包装脚本：原样调用项目已有的启动器。
# 来源：scripts/train.sh（接入于 <YYYY-MM-DD>）

cd "${ROOT_DIR}"
bash scripts/train.sh "$@"
```

规则：绝不编辑被包装的脚本；绝不把它内联进来；绝不"优化"它的参数。已有命令写死了某条路径、而软链现在也能接通同一位置时，那条路径保持原样——两者都能解析，改写它属于代码改动，超出边界。`<name>` 要能区分任务（规约 §9）；`execs/scpts/` 里已被占用的名字是需要询问的冲突，不能自己加后缀了事。

## 5. 工作清单格式约定

每一行是一个可辨认的已完成或进行中的工作单元。行少而证据扎实，胜过行多而多为臆测：两个 commit 加一个输出目录说的是同一件事，就是一行。

| 字段 | 内容 |
|---|---|
| `id` | `W1`、`W2`……——稳定不变，回填记录会引用它 |
| `what` | 一行描述。建了什么或跑了什么，用仓库自己的术语 |
| `state` | `built`（代码在，未找到 run）/ `run`（有 run 产出了输出）/ `concluded`（某处写下了结论）/ `abandoned`（被取代或明确放弃） |
| `evidence` | 路径、commit SHA、脚本名、日志行。没有证据的行不成立 |
| `run_dir` | `state` 为 `run` 或 `concluded` 时填既往 run 目录；否则留空 |
| `metric` | 日志、README 或结果文件里可见的任何数字，连同出处逐字引用。绝不计算，绝不四舍五入 |

**绝不进入某一行的东西：** 这项工作为什么做、支撑哪条主张、是否成功、接下来该做什么。那些归 coach 去问、归分析师去判（`SKILL.md` 原则 5）。

## 6. 入账规则（确认点 2）

对用户选中的每个 run：

1. 新建真实目录 `wkdrs/<run>/`，把已有 run 目录以绝对路径链接进去，成为 `wkdrs/<run>/output`（`star-plan-reviser` 的丢弃把 run 移到 `wkdrs/dropped/<run>/` 后，链接仍能解析）；`<run>` 在原名已足够区分、且在 `wkdrs/` 下尚未被占用时沿用原名，否则（`output/`、`run1/`）用 `<原名>_<run 日期>`。
2. 按 `assets/exec_log_reconstructed_zh.md` 写 `wkdrs/<run>/EXEC_LOG.md`，与 `output` 链接并列：那里的真实文件，阶段末的提交提议才能暂存。
3. 重建日志包含：带接入日期的 `reconstructed:` 头部、`source_plan: (none — 该 run 早于计划树)`、命令（仅当脚本或存档配置里有逐字记录）、现存产物，以及按 §5 引用的任何指标。**不含步骤表**——当时没有步骤可记，而编造步骤正是这条规则要防的失效模式。
4. 绝不往被软链的目录里面写。`EXEC_LOG.md` 放在 `wkdrs/<run>/` 里，与链接并列。

被选中的 run 目录里若已有 `EXEC_LOG.md`，原样不动，也不为它新建 `wkdrs/<run>/`，该 run 报告为 `already recorded`。

## 7. 回填对账（`backfill` 阶段）

对账规则与这个阶段放在一起，在 `backfill_zh.md`，阶段解析为 `backfill` 时才读，之前不读。走 `survey` 的运行一条都用不上。
