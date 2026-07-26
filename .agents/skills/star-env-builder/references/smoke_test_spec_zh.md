# 冒烟测试规范——三层递进，必须留证据

安装完成后运行，全程走绝对路径 `$ENV_PY`。预算：分钟级、CPU 轻量、不碰数据、不碰权重、不做网络下载。每项检查都把确切命令和输出尾部作为证据记入 ENV_REPORT 的冒烟测试结果表。

## L1——import

范围：`framework.txt` + `runtime.txt` 中的每个发行包，若装了 `optional.txt` 也包含在内。

把发行名映射回 import 名（解析映射表反过来用），然后**一次**把整层跑完——每个发行包一行制表符分隔：发行名、import 名、`ok` 或 `FAIL`、版本号或错误尾巴、以及实际用的那条命令。

```bash
$ENV_PY - <<'EOF'
import importlib, importlib.metadata as md
for dist, mod in PAIRS:                    # 映射好的清单，按 framework.txt + runtime.txt 的顺序
    try:
        m = importlib.import_module(mod)
        v = getattr(m, "__version__", None) or md.version(dist)
        print(f"{dist}\t{mod}\tok\t{v}\timport {mod}")
    except Exception as e:
        print(f"{dist}\t{mod}\tFAIL\t{type(e).__name__}: {e}\timport {mod}")
EOF
```

通过 = import 成功；记下版本号。矩阵是从这一份输出照抄下来的，而不是从三四十次单独调用里拼回来的——后者正是"证据栏空着、检查却被记成跑过了"最可能的来路。这个循环由主 agent 自己跑；原则 6 不变，把命令合成一批并不等于把它们委派出去。每一行都带着它实际用的命令，失败的行带着错误尾巴，否则这个循环就成了藏住失败的那个东西。

## L2——框架深检

以 torch 为例（jax / tensorflow 按同样形态改写）：

- 报出 `torch.__version__` 与 `torch.version.cuda`。
- 预期有 GPU（预检时 `nvidia-smi` 成功）：`torch.cuda.is_available()` 必须为 `True`；记录 `device_count()`；跑一次小运算——`(torch.randn(64,64,device='cuda') @ torch.randn(64,64,device='cuda')).sum()`。
- macOS：检查 `torch.backends.mps.is_available()`；小运算跑在 `mps` 上。
- 纯 CPU 机器：小运算跑在 CPU 上，报告*CPU-only（符合预期）*——这是事实陈述，不算失败。
- GPU 机器上 `is_available()` 为 `False` **就是失败**。常见原因按序排查：装成了 CPU wheel（`torch.version.cuda` 为 `None`——用错了源）、驱动比 wheel 的 CUDA 运行时旧（回安装器策略重新匹配源）。

## L3——项目

1. `$ENV_PY -m compileall -q ${CODE_NAME}`——语法层，不需要装依赖。
2. 已做可编辑安装 → `$ENV_PY -c "import <包名>"`——能抓到 compileall 看不见的 import 期依赖缺口。
3. 最便宜的入口，按存在顺序取第一个：console 入口跑 `--help`；`$ENV_PY ${CODE_NAME}/<train|main|demo>.py --help`（优先用 README 提到的那个）；有测试 → `$ENV_PY -m pytest --collect-only -q`（收集阶段会 import 测试模块但不运行）。

没有任何入口 → 如实说明；L3 就是 compileall + 包 import。

## 失败协议

某层失败 → 按 traceback 诊断：

- 缺传递依赖 → 装上它，**并**补进对应的生成 requirements 文件（只修环境不修布局，下次重建还会坏）。已有布局（优先级 1）不改——把缺口写进报告。
- wheel 装错（GPU 机器上装了 CPU torch、ABI 不匹配）→ 回安装器策略的 wheel 选择重来。

每层 ≤2 轮修复；仍失败 → 在结果表中标 `blocked` 并附错误尾部，相互独立的后续层继续跑，最终报告里明确列出。

## 证据格式（冒烟测试结果表的行）

| 层 | 检查 | 命令 | 结果 | 证据 |
|---|---|---|---|---|
| L1 | torch 可导入 | `$ENV_PY -c "import torch; …"` | pass | `2.4.1` |
| L2 | CUDA 可用 | `$ENV_PY -c "…is_available()…"` | pass | `True / 2 devices / sum=-11.98` |
| L3 | 入口 | `$ENV_PY code/train.py --help` | blocked | `ModuleNotFoundError: pycocotools`（尾部） |

结果取值：`pass` / `blocked` / `skipped（写明原因）`。`pass` 的证据栏不允许为空。
