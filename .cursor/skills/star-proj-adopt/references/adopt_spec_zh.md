# 接入规范——勘察配方、清单契约与写入规则

`star-proj-adopt` 背后的确切规则。`SKILL_zh.md` 给出形状，本文件给出判定标准。

## 1. 勘察（只读）

六条探测线。每条返回发现结果加一个置信度：`certain`（唯一且无歧义的匹配）、`likely`（唯一匹配但信号弱）、`unknown`（没有或有多个）。只有 `likely` 与 `unknown` 的行会进入门 1——`certain` 的行只作报告，不去问。

| 探测线 | 看什么 | 何时算 `certain` |
|---|---|---|
| 源码 | 含 `__init__.py` 的顶层目录；入口脚本导入的是哪个；`pyproject.toml` / `setup.py` 的 `name` 与 `packages` | 顶层可导入包恰好一个，且入口脚本导入的就是它 |
| 运行时 | `conda env list`、`.venv/`、`which python`、已有脚本里的环境名、`environment.yml` / `requirements*.txt` | 恰好一个环境，其名字与项目吻合，或其 python 能导入源码包 |
| 数据 | 名为 `data*` / `dataset*` 的目录、配置与 dataloader 默认值里的路径、体量大的非代码目录树 | 唯一路径，且被一个以上的配置或脚本引用 |
| 权重 | 名为 `ckpt*` / `checkpoint*` / `weights` / `pretrained` / `models` 的目录、`.pt` / `.pth` / `.safetensors` / `.bin` 的聚集处 | 唯一路径，且入口脚本加载的正是其中的 checkpoint |
| 输出 | 名为 `out*` / `runs` / `logs` / `exp*` / `work_dir*` 的目录、TensorBoard event 文件、按 run 分子目录的模式 | 唯一路径，且其子目录看起来就是一次次 run（时间戳、配置名） |
| 入口 | 可执行脚本、`if __name__ == "__main__"`、`console_scripts`、`Makefile` / `*.sh` 目标、README 里的命令 | ——始终作为一个列表报告，绝不收敛成单一答案 |

同时为工作清单记录：首次提交日期、提交总数、最近改动的 20 条路径，以及 README 里任何描述状态或结果的段落。

**这条线上不写任何东西。** 不运行项目代码，不导入它的包，不创建环境。

## 2. 映射块

门 1 之前把勘察结果报成一整块，每条探测线一行：

```
source     CODE_NAME=<dir>            certain   （唯一可导入包；被 train.py 导入）
runtime    PYTHON_HOME=<path>         likely    （conda env "ovd"；与 scripts/train.sh 里的环境名一致）
data       datas/ -> <path>           certain   （被 4 个配置引用）
weights    inits/ -> <path>           unknown   （未找到 checkpoint 目录）
outputs    wkdrs/ -> <path>           likely    （12 个带时间戳的子目录）
entry      3 个启动入口                —         （scripts/train.sh、scripts/eval.sh、tools/infer.py）
```

## 3. 软链规则

对 `datas/`、`inits/`、`wkdrs/` 逐一按此顺序判定：

1. 路径不存在 → 建软链指向已确认的目标。
2. 路径是空目录（或只有 `.gitkeep`）→ 移除占位，建软链。
3. 路径已是指向同一目标的软链 → 保持不动，报告 `already linked`。
4. 路径是指向**其他目标**的软链，或是**非空的真实目录** → 什么都不做，报告冲突并询问。绝不替换，绝不合并进去。
5. 已确认的目标就在仓库内且位置正确 → 不需要软链，报告 `already in place`。

目标在仓库之外是正常且可接受的；把它的绝对路径记入 `metds/adopt.md`。目标位于网络盘或可移动挂载点时，连同该注意事项一并记录。

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

规则：绝不编辑被包装的脚本；绝不把它的内容内联进来；绝不"优化"它的参数。当已有命令写死了某条路径、而现在软链也能触达同一位置时，让那条写死的路径保持原样——两者都能解析，改写它属于代码改动，超出边界。`<name>` 要能区分任务（规约 §9）；`execs/scpts/` 里已被占用的名字是需要询问的冲突，不是可以自行加后缀了事的事项。

## 5. 工作清单契约

每一行是一个可辨认的已完成或进行中的工作单元。行少而证据扎实，胜过行多而多为臆测——若两个 commit 加一个输出目录说的是同一件事，那就是一行。

| 字段 | 内容 |
|---|---|
| `id` | `W1`、`W2`……——稳定不变，回填记录会引用它 |
| `what` | 一行描述。建了什么或跑了什么，用仓库自己的术语 |
| `state` | `built`（代码在，未找到 run）/ `run`（有 run 产出了输出）/ `concluded`（某处写下了结论）/ `abandoned`（被取代或明确放弃） |
| `evidence` | 路径、commit SHA、脚本名、日志行。至少一条。没有证据的行不成立 |
| `run_dir` | `state` 为 `run` 或 `concluded` 时填既往 run 目录；否则留空 |
| `metric` | 日志、README 或结果文件里可见的任何数字，连同出处逐字引用。绝不计算，绝不四舍五入 |

**绝不进入某一行的东西：** 这项工作为什么做、支撑哪条声明、是否成功、接下来该做什么。那些归 coach 去问、归分析师去判（`SKILL_zh.md` 原则 5）。

## 6. 入账规则（门 2）

对用户选中的每个 run：

1. 把已有 run 目录软链到 `wkdrs/<run>/`；`<run>` 在原名本身已足够区分时沿用原名，原名不足以区分时（`output/`、`run1/`）用 `<原名>_<run 日期>`。
2. 按 `assets/exec_log_reconstructed_zh.md` 写 `wkdrs/<run>/EXEC_LOG.md`。若软链指向只读或外部位置，改写到 `wkdrs/<run>_adopted/EXEC_LOG.md` 并在报告中说明。
3. 重建日志包含：带接入日期的 `reconstructed:` 头部、`source_plan:（无——接入时计划树尚不存在）`、能从脚本或存档配置里逐字复原时的命令、现存产物，以及按 §5 引用的任何指标。**不含步骤表**——当时并没有步骤可记，而编造步骤正是这整条规则要防的失效模式。
4. 绝不往被软链的目录里面写。`EXEC_LOG.md` 放在 `wkdrs/` 这一层。

被选中的 run 目录里若已有 `EXEC_LOG.md`，原样不动，该 run 报告为 `already ledgered`。

## 7. 回填对账（`backfill` 阶段）

leaf 与清单行只在**证据重叠**时才算匹配：leaf 的 §4 交付路径或 §3 步骤中出现了某条路径、脚本或模块，而它也出现在该行的 `evidence` 或 `run_dir` 里。仅凭名字相似不算匹配——把它作为 `weak` 提出来，交给用户定夺。

每个匹配上的 leaf 提议的状态：

| 清单 `state` | 提议的 leaf `exec_status` |
|---|---|
| `concluded` | `done` |
| `run` | 证据显示 leaf 的 §5 done-criterion 明显已达成时 `done`；否则 `in_progress` |
| `built` | `in_progress` |
| `abandoned` | 不提议——报告出来交给用户决定 |

`exec_runs` 只在该行的 run 已于门 2 入账时才写；`done` 但没有入账 run 的 leaf 只写 `exec_status`，并在报告中标出——`/star-flow-status` 会把它列在 done-with-no-run 之下。对获确认且 run 已入账的匹配，同一趟里把重建日志的 `source_plan:` 更新为该 leaf 的文件名——用户确认的正是这层对应关系。

绝不提议 `blocked`，绝不写 `depends_on`，绝不重排任何东西。当一条清单行匹配到多个 leaf、或多条清单行匹配到同一个 leaf 时，如实呈现并询问——多对多的匹配通常意味着拆解与历史彼此对不上，那是信息，不是需要抹平的错误。
