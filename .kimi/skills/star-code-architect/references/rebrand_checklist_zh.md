# 保守改名清单

把引入的代码库重命名为 `${CODE_NAME}`，同时不把它悄悄改坏。经验法则：**Python 解析的标识符可以改；框架在运行时按字符串解析的名称绝不改。**

## 前置条件

- `${CODE_NAME}/UPSTREAM.md` 已写好，import 提交已落地（回滚锚点）。
- 弄清上游 Python 包名：顶层可 import 的目录（可能与仓库名不同；可能在 `src/` 下）。

## 步骤按序执行——每步验证

每步结束时：`grep -rn '<旧名>' ${CODE_NAME} | wc -l`（计数必须按预期下降），再跑 `python -m compileall -q ${CODE_NAME}`（语法级检查，无需安装依赖）。

1. **包目录**：`<上游包名>/` → `<code_name>/`（在 `${CODE_NAME}/` 内，或在 `src/` 下）。两者本就一致则跳过。
2. **import**：改写所有 `.py` 中的 `import <上游包名>` / `from <上游包名> …`，以及 `__init__.py` 的再导出。
3. **打包元数据**：`pyproject.toml` 的 `[project].name`（及 `[tool.setuptools]` packages），或 `setup.py`/`setup.cfg` 的 `name=`、`packages=`、`package_dir`。
4. **命令行入口**：`[project.scripts]` / `entry_points={'console_scripts': …}` 指向的目标。
5. **README**：标题、安装命令（`pip install <名称>`）、用法示例里的 import 片段。
6. **文档配置**（仅当改动 trivial）：`docs/conf.py` 的项目名。

然后提交：`star-code-architect: rebrand to <CODE_NAME>`（只暂存 `${CODE_NAME}/`）。

## 禁改清单 → 残留表

下面这些看着像包名，实则由框架、checkpoint 或外部服务在**运行时按字符串**解析。现在改掉它们，坏的时候不会有任何 traceback 指回改名这一步：

| 类别 | 例子 | 为什么现在不能动 |
|---|---|---|
| 注册表字符串 | `@MODELS.register_module('XDet')`、detectron2 的 `META_ARCH` 键 | 配置按字面字符串引用它们 |
| 配置 `type:` 键 | YAML/py 配置里的 `type: XDetHead` | 通过注册表查找解析 |
| checkpoint 耦合 | `state_dict` 前缀、pickle 进 ckpt 的类名 | 预训练权重会加载失败 |
| 服务名称 | wandb 项目名、logger 名、HF hub id | 外部记录引用它们 |
| 类名前缀 | `XDetBackbone` 等一族 | 与上面所有条目耦合 |

每一类出现位置在残留表（`codearc.md` §7）加一行：位置模式、类别、风险、建议的后续处理。未来改名的命名风格只做**建议**（如 `code` → `Code` 前缀），绝不自动执行。后续改名走 `star-plan-executor` 的步骤，每条自带检查。

## import 冒烟（环境就绪后）

`.env` 指向的 conda 环境装好依赖后：通过该环境跑 `python -c "import <code_name>"`。写进最终汇报；环境尚不存在时，说明该检查待办，并把准备好的安装命令移交用户。
