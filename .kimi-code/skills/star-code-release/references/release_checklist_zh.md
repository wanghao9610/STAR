# 发布体检清单

四族检查，对**被 git 跟踪**的仓库外加本次运行提升的路径执行。每条 finding 带 `file:line`、命中的检查项和具体修法。严重度由所属族固定，与本次运行其余部分跑得如何无关：只要有一条未清阻断项，本次结论就是 `blocked`，绝不是"就绪，只是有个小问题"。

范围说明：检查的是一个把仓库 clone 下来的陌生人会拿到什么。`git ls-files` 是这件事的权威，外加本次提升的路径。躺在被忽略的 `wkdrs/` 文件里的 secret 不是发布阻断项——但本次即将提升的文件里的 secret 是，这也正是体检安排在 gather 之后的原因。

## 1. Secret 与机器本地路径——**阻断**

这一族没有主观判断，也没有豁免。

| 检查 | 怎么查 | 修法 |
|---|---|---|
| `.env` 被提交 | `git ls-files .env` 有输出 | `git rm --cached .env`；确认 `.gitignore` 覆盖它。同时直白说明历史里仍有它，而重写历史是用户的决定 |
| API key 与 token | 在被跟踪的文件树里 grep `sk-`、`hf_`、`ghp_`、`AKIA`、`api[_-]?key`、`secret`、`token`、`password`、`WANDB_API_KEY`、`Bearer ` | 移到 `.env` / 环境变量，从那里读 |
| 机器本地绝对路径 | grep `/home/`、`/Users/`、`/mnt/`、`/data1/`、`C:\\`，以及用户本人的用户名 | 从 `.env` 读根路径（AGENTS.md §6）。永远是阻断项——它是研究仓库在别人机器上跑不起来的头号原因 |
| 内网主机与端点 | grep 像内网的主机名、私有 IP 段（`10.`、`192.168.`、`172.16–31.`）、集群节点名、非公开 URL | 删除，或换成公开等价物 |
| 个人数据 | 引用信息之外的作者邮箱、SSH 配置、`.netrc`、私有数据集 URL | 删除 |

在被跟踪文件列表里 grep，并且**每条命中都要读过再报**：一句写着"不要硬编码 `/home/...`"的 docstring 不是 finding，`tokenizer` 里的 `token` 也不是 secret。一条误报的阻断项就会让整份清单失去权威。

## 2. 许可证与署名

| 检查 | 严重度 | 修法 |
|---|---|---|
| 根目录存在 `LICENSE` | 阻断 | 由用户选择 license；点名下面 §5 记录的约束并询问。绝不替用户选 |
| 它与 `metds/codearc.md` §5 记录的上游许可证兼容 | 冲突时阻断 | 精确报出冲突——"上游是 GPL-3.0，根 LICENSE 是 MIT"——然后到此为止。解决许可证冲突是法律决定，不是 skill 的 |
| `${CODE_NAME}/` 下上游的 `LICENSE` / `CITATION*` 仍在原处 | 被删则阻断 | 从 git 历史恢复 |
| 代码库从某仓库奠基时存在 `${CODE_NAME}/UPSTREAM.md` | major | 由 `/skill:star-code-architect` 记录来源 |
| README 的 Acknowledgement 点名了上游仓库与核心论文 | major | 从 `UPSTREAM.md` 和 `metds/refs/refs_index.md` 编译 |
| 拷进来但没有署名的第三方代码 | major | 点名文件及其出处（若还能追溯）；否则标出来交给用户 |

## 3. 命令可运行性

README 打印的每条命令，按读者会遇到的顺序检查。这一族决定了这个仓库对作者以外的人是否成立。

1. **安装**——README 点名的 requirements 文件存在；它写的 python 版本与最新 `ENV_REPORT.md` 一致；它打印的安装阶梯就是当初实际用的那套。
2. **入口**——README 调用的每个模块能在 `.env` 解释器下导入（`python -c "import <module>"`）。导入失败是 major，并点名缺失的依赖或路径。
3. **脚本**——README 打印的每个 `execs/scpts/*.sh` 和工具脚本都存在、可执行，且其 `--help` 或前 20 行能印证 README 展示的参数。
4. **配置**——被打印命令点名的每个配置路径都在那个路径上存在。
5. **权重**——Model Zoo 链接的每个 checkpoint，要么在 `inits/` 下的盘上，要么已在给出的 URL 公开发布。两者皆非的链接是阻断项：为一个谁也下不到的文件留一行 Model Zoo，比没有这一行更糟。

除导入和 `--help` 外，什么都不执行。验证训练命令真能训练，正是 STOP 线要挡住的事。

## 4. 静态资源与链接

| 检查 | 严重度 |
|---|---|
| README 引用的每张图片都存在（`docs/srcs/…`、相对路径） | major |
| 每个相对链接都解析到仓库内的文件 | major |
| 每个锚点链接都对应文件里的某个标题 | minor |
| 没有链接指向 `wkdrs/`、`datas/`、`inits/` 或其他被 git 忽略的路径 | major——它在作者机器上能开，对别人是 404 |
| `.gitignore` 仍覆盖 `.env`、`datas/`、`inits/`、`wkdrs/` | 不覆盖则阻断 |
| 没有超过约 10 MB 的文件被跟踪 | major——点名它，并建议改用 release asset 或下载脚本 |

## 报告方式

按族分组，阻断项在前，每条写成 `<file>:<line> — <什么> · 修法：<怎么改>`。然后给结论行：

- **release-ready**——没有未清阻断项。说明还剩哪些 major，以及它们属于用户的判断。
- **blocked (n)**——n 条未清阻断项，逐条点名。即使其余全部通过，结论也是这个。

准备好的发布命令写进报告的*等待用户*一节，绝不在这里执行（`SKILL_zh.md` 核心原则 6）：加 remote、push、打 tag、发 release、上传权重。给出确切命令，并说明每条会让什么变得不可逆。
