---
env_name: <ENV_NAME>
backend: conda            # conda / venv
created: <YYYY-MM-DD>     # 运行时真实日期（date +%Y%m%d），绝不编造
status: verified          # verified / partial / blocked
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
---

# 环境报告——<ENV_NAME>

一个全新的 session 应当仅凭这份文件就能使用——或重建——这个环境。

## 身份

- 解释器（`ENV_PY`）：`<绝对路径>`   ← 一切命令走这个路径；从不 `source activate`
- 后端：conda（`$CONDA_HOME/envs/<ENV_NAME>`）/ venv（`<项目根>/.venv`）
- Python：`<版本>`
- 上一个环境已备份为：`<名称>_<YYYYMMDD>` / 无
  <!-- 改名后的 venv 脚本里仍是旧绝对路径：仅作冻结备份，不能直接激活。 -->

## 机器探测

- OS / 架构：<…>
- GPU / 驱动：<nvidia-smi 一行摘要，或"无">
- 驱动 CUDA 上限：<X.Y> · 本机 toolkit（nvcc）：<X.Y / 缺失>
- 选定的框架 wheel 源：`<url / 默认 PyPI>`——<依据：上限、锁定、平台>

## 依赖来源

- 采用的来源：已有 requirements / 打包元数据（<文件>）/ import 扫描
- 本次写入的文件：<清单，或"无——布局已存在">
- 提交：`star-env-builder: add requirements layout`（<sha>）/ 无

## 安装结果

<!-- 实际处理过的类别每类一行。Failed 填数量，细节写在"失败与受阻"。 -->

| 类别 | 文件 | 应装 | 已装 | 失败 | 路由 |
|---|---|---|---|---|---|
| conda | requirements/conda.txt | | | | conda |
| framework | requirements/framework.txt | | | | uv |
| runtime | requirements/runtime.txt | | | | uv |
| optional | requirements/optional.txt | | | | skipped |
| project | `-e ${CODE_NAME}`（`--no-deps`） | | | | uv |

## 冒烟矩阵

<!-- 由主循环亲自运行后填写。结果：pass / blocked / skipped（写明原因）。
     证据是真实输出尾部——pass 的证据栏不允许为空。 -->

| 层 | 检查 | 命令 | 结果 | 证据 |
|---|---|---|---|---|
| L1 | | | | |
| L2 | | | | |
| L3 | | | | |

## 失败与受阻

<!-- 错误尾部、诊断、尝试过什么（每层 ≤2 轮）、当前状态。 -->

## 待用户执行（STOP 线）

<!-- 源码编译、sudo/系统级安装、>10 GB 下载。确切命令 + 越线原因 + 完成后怎么做。 -->

- [ ] `<确切命令>`——<原因：源码编译 / sudo / 体量>。完成后：重新运行 `/star-env-builder <ENV_NAME>` 并选择*原地验证修复*。

## 快照

精确版本清单：[`freeze.txt`](freeze.txt)——`uv pip freeze --python $ENV_PY`（或 `$ENV_PY -m pip freeze`）。
