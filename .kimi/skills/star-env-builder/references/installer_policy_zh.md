# 安装器策略——uv > pip > conda 阶梯

什么工具装什么、按什么顺序、失败了怎么办。每条命令都走绝对路径的 `$ENV_PY` 或 `$CONDA_HOME/bin/conda`——从不 `source activate`，从不用系统 python。

## 阶梯

| 层级 | 何时用 | 命令形态 |
|---|---|---|
| uv（默认） | uv 在 PATH 上，或用户同意安装它 | `uv pip install --python $ENV_PY -r <文件>` |
| pip（降级） | uv 缺失且用户拒装，或某个包在 uv 下失败 | `$ENV_PY -m pip install <包>` |
| conda（仅白名单） | conda 后端**且**包在白名单上 | `$CONDA_HOME/bin/conda install -n <ENV_NAME> -c conda-forge <包> -y` |

- uv 缺失 → 问一次并带推荐：装 uv（如 `$PYTHON_HOME/bin/python -m pip install --user uv`，用户偏好官方独立安装器亦可）/ 本次改用 pip。拒装只损失速度，不损失正确性。
- 阶梯之外不混用管理器：uv/pip 装的由 uv/pip 升级。绝不用 conda 覆盖 pip 管理的包——conda 只拥有白名单，而白名单 pip 从不涉足。

## 安装顺序

1. `conda.txt`——仅 conda 后端；系统/工具链层先装，后面的构建才看得见它。
2. `framework.txt`——带上它的 `--extra-index-url`；最大的 wheel 先装，尽早失败。
3. `runtime.txt`
4. `optional.txt`——仅当获批的安装计划包含它。
5. 最后做项目可编辑安装（有打包元数据时）：`uv pip install --python $ENV_PY --no-deps -e ${CODE_NAME}`（`--no-deps` 因为各类别已覆盖依赖）。

## conda 白名单（conda 只装这些）

`cudatoolkit` / `cuda-toolkit`、`cudnn`、`nccl`、`gcc_linux-64` / `gxx_linux-64`（源码构建用的编译器）、`ffmpeg`、`openmpi` / `mpich`（连同 `mpi4py`）、`faiss-gpu`。

理由：这些包携带原生库，必须与系统隔离（或与系统协调）；它们的 pip wheel 要么不存在，要么会和系统副本打架。

venv 后端需要白名单项 → 不要即兴发挥（不 `sudo`、不 apt/brew）：停下来问，选项是——用户自行系统级安装 / 跳过 / 有 pip 替代品就用替代品（`faiss-cpu`、`imageio-ffmpeg`）。

## 框架 wheel 选择（CUDA 匹配）

1. **上限**：`nvidia-smi` 头部的 `CUDA Version` = 驱动支持的最高运行时版本。
2. **锁定**：依赖来源中的 torch 锁定版本，加上上游 README 点名的 CUDA 版本。
3. **选择**：不超过上限、又满足锁定的最高官方 `cuXXX` wheel 源——当前可用的源以 pytorch.org/get-started 为准（源会轮换；不要凭记忆）。例：`--extra-index-url https://download.pytorch.org/whl/cu121`。
4. macOS → 默认 PyPI wheel（CPU + MPS）。无 NVIDIA GPU 的 Linux → `/whl/cpu`。
5. **不匹配**（锁定版本比上限新；上游要求的 nvcc 机器上没有）→ 作为门上的问题给出具体选项：满足锁定的旧 wheel / 更新的 torch（说明 API 风险）/ CPU 构建。

`nvcc` 只在源码构建时才重要（那本来就在 STOP 线外）；装 wheel 只需要驱动。

## 失败处理

- 按包处理：uv → pip 重试，每包总计 ≤2 次；截取错误尾部。
- 单包失败不中止整轮：记录后继续装其余，最后把失败项一次性解决或移交。
- 源码构建特征——要求 `--no-build-isolation`、`setup.py` 探测 `CUDA_HOME`、"Building wheel …" 跑上几分钟（`flash-attn`、完整版 `mmcv`、从 git 装 `detectron2`）→ STOP 线：把准备好的确切命令写进 ENV_REPORT 的"待用户执行"；绝不擅自运行。
- 解析器冲突（uv/pip 回溯报错）→ 绝不用 `--no-deps` 强推（项目可编辑安装是唯一例外）；把冲突对摆到门上或写进报告。

## 镜像与源

- 尊重环境或 `.env` 中已有的 `PIP_INDEX_URL` / `UV_DEFAULT_INDEX` / `UV_INDEX_URL`——原样传递，绝不覆盖。
- torch 源与镜像可叠加：保留用户的主源，torch 源用 `--extra-index-url` 附加。
- 绝不写全局配置：不 `pip config set`、不改 `.condarc`、不写 `uv.toml`。
