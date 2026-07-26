#!/usr/bin/env bash
# Phase A of the plain-language rewrite: the unambiguous 1:1 term substitutions
# from tasks/plain-language/glossary.md.
#
# Only terms with a single sense across the whole corpus live here. Polysemous
# terms (点名 / 提升 / 阶梯 / 指针 / 记号 / surface / ladder / ledger / land …)
# are handled per-sentence in Phase B and are deliberately absent.
#
#   bash tasks/plain-language/rewrite.sh --dry-run   # per-pattern hit counts, no writes
#   bash tasks/plain-language/rewrite.sh             # apply
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "$ROOT"

DRY=false
[[ "${1:-}" == "--dry-run" ]] && DRY=true

# Latin-term guard: not part of a longer identifier and not inside a filename
# such as review_rubric_zh.md. Applied to every ASCII pattern below.
zh_files() {
    find .agents/skills .claude/skills .cursor/skills .kimi-code/skills \
         docs/mds/star-workflow -name '*_zh.md' -o -name '*.zh-CN.md' 2>/dev/null
    echo "README.zh-CN.md"
}

en_files() {
    find .agents/skills .claude/skills .cursor/skills .kimi-code/skills \
         docs/mds/star-workflow -name '*.md' ! -name '*_zh.md' ! -name '*.zh-CN.md' 2>/dev/null
    echo "README.md"
}

# --- Chinese: one sense only -------------------------------------------------
# Ordered: longer / more specific patterns before the general ones they contain.
ZH_RULES=(
    '大面积飘红=>大片是缺项'
    '已平台化=>已进入平台期'
    '化了妆的 Park=>变相搁置'
    'Park 掉=>搁置'
    '被 Park 的=>被搁置的'
    '全部 Park=>全部搁置'
    'Park=>搁置'
    '计划组件落位映射=>计划各组件对应的代码路径'
    '拥挤度注记=>竞争激烈程度说明'
    '"过好"检查=>结果好得反常的排查'
    '相关工作基座=>相关工作基础'
    '文献基座=>文献基础'
    '承重的公式=>关键公式'
    '同门契约=>对应的规范'
    '无损接入=>不改动原有内容地接入'
    '移动残渣=>搬移后的残留引用'
    '生成招式=>生成手法'
    '常驻指针=>常驻的指路说明'
    '薄指针=>一小段指路说明'
    '涟漪图=>影响范围图'
    '涟漪意识=>连带影响意识'
    '涟漪义务=>连带影响义务'
    '涟漪提醒=>连带影响提醒'
    '涟漪=>连带影响'
    '爆炸半径=>影响范围'
    '水位线=>上次覆盖到的日期'
    '报告支撑=>有报告依据的'
    '发布面=>对外发布的部分'
    '关注面=>关注点'
    '运行面=>启动方式'
    '测试面=>测试覆盖情况'
    '读取面=>读取范围'
    '抬头行=>文件首行'
    '抬头=>文件头'
    '自审线=>自审行'
    '字形=>状态符号'
    '活性=>存活情况'
    '词干=>共同前缀'
    '越阈=>越过阈值'
    '交接物=>交付物'
    '差距清单=>缺口清单'
    '回环=>循环'
    '数据通路=>数据流'
    '审计痕迹=>审计线索'
    '誊写=>原样转录'
    '修复 pass=>修复轮'
    '主循环=>主 agent'
    '生产者=>产出方'
    '归拢=>收集'
    '触达=>接通'
    '归宿=>去处'
    '赌注=>关键假设'
    '拥挤度=>竞争激烈程度'
    '真源=>唯一依据'
    '定日期=>判定日期'
    '保险丝=>兜底检查'
    '逃生选项=>兜底选项'
    '回灌=>写回'
    '挂回=>对应回'
    '报告形文件=>形似报告的文件'
    '产物注册表=>产物登记表'
    '用一个从句=>用半句话'
    '从句=>半句话'
    '消费=>使用'
    '扇出=>并行分派'
    '残渣=>残留'
    '在盘上=>在磁盘上'
    '在盘=>在磁盘上'
    '廉价=>低开销'
    '准绳=>评判依据'
    '原始载荷=>原始内容'
    '载荷=>原始内容'
    '分线=>分组'
    '本线=>本组'
    '跨线=>跨组'
    '落位=>确定去处'
    '裸写=>直接写出'
    '单测量级=>单元测试量级'
    '保持窄=>只管一小块'
    '基座=>基础'
    '招式=>手法'
    '承重=>关键'
    # 夹用英文（有现成中文词）
    'greenfield=>空代码库（从零起步）'
    'sanity 检查=>合理性检查'
    'scratch=>草稿文件'
    'drift=>失配'
    'tie-break=>打平时的取舍依据'
    'surgical=>精准克制'

    # --- 第二批：gate / STOP line，以及经语境核验的单义词 ---
    # 门槛 / 一门 / 专门 / 部门 是正常中文，靠"先长后短 + 不留裸门规则"保住。
    'STOP 线=>红线'
    '越线=>越过红线'
    '门与门之间=>确认点之间'
    '两门之间和之后=>两个确认点之间和之后'
    '门间自主=>确认点之间自主'
    '第三道门=>第三个确认点'
    '两道门=>两个确认点'
    '三道门=>三个确认点'
    '五道门=>五个确认点'
    '一道门=>一个确认点'
    '这道门=>这个确认点'
    '某个门=>某个确认点'
    '各道审批门=>各个审批确认点'
    '安装计划门=>安装计划确认点'
    '审批门=>审批确认点'
    '批准闸门=>审批确认点'
    '安全门=>安全确认点'
    '硬门=>必问确认点'
    '写入门=>写入确认点'
    'diff 门=>diff 确认点'
    '门 1=>确认点 1'
    '门 2=>确认点 2'
    '门 3=>确认点 3'
    '跨门=>跨确认点'
    '门关上之前=>这个确认点关闭之前'
    '门没覆盖=>确认点没覆盖'
    '门没有覆盖=>确认点没有覆盖'
    '门批准=>确认点批准'
    '门覆盖=>确认点覆盖'
    '门前=>确认点之前'
    '门上=>确认点上'
    '门下=>确认点下'
    '门口=>确认点'
    # 其余单义词
    '战略信号=>方向性信号'
    '策略信号=>方向性信号'
    '战略计划=>总体计划'
    '策略计划=>总体计划'
    '战略章节=>总体计划章节'
    '战略节点=>总体计划节点'
    '战略性=>总体性'
    '战略级=>总体计划级'
    '战略层面=>总体层面'
    '战略=>总体方向'
    '落笔=>写入'
    '奠基=>搭建'
    '机械=>例行'
    '有界重试=>有限次重试'
    '有界=>范围受限'
    '临时层=>未核实层'
    '临时数字=>未核实数字'
    '临时 run=>未核实 run'
    '正确性 smell=>正确性可疑写法'
    '反馈回流=>向上反馈'
    '收集者=>收集器'
    'checkpoint 到=>记入'
    'delegate=>子代理'
    'secret=>密钥凭据'
    'Findings=>问题项'
    'findings=>问题项'
    'finding=>问题项'
    'claims=>主张'
    'claim=>主张'
    'Rubric=>评分表'
    'rubric=>评分表'
)

# --- English: one sense only -------------------------------------------------
EN_RULES=(
    'self-audit line=>unrecognized-files line'
    'coverage band=>follow-up checks'
    'whole forest=>all plan trees'
    'on a cadence=>regularly'
    'main loop=>main agent'
    'artifact registry=>output table'
    'thin pointers=>short cross-references'
    'thin pointer=>short cross-reference'
    'revive-when line=>note on what would make it worth revisiting'
    'concern lane=>topic'
    'code home=>place for the code to live'
    'Ripple awareness=>Knock-on effects'
    'ripple map=>knock-on effects'
    'Ripple map=>Knock-on effects'
    'keep-set=>set of directions to keep'
    'carve-out=>exception'
    'clobbered=>overwritten'
    'clobber=>overwrite'
    'yardsticks=>review rules'
    'yardstick=>review rule'
    'watermark=>last covered date'
    'glyphs=>status symbols'
    'glyph=>status symbol'
    'greenfield=>empty codebase'
    'involve dial=>involve level'
    'dial-immune=>always asked'
    're-cut=>reorganize'
)

# bash 3.2 (macOS) has no namerefs — rules come in as newline-separated text.
apply_rules() {
    local rules_text="$1"
    local files="$2"
    local label="$3"
    printf '\n== %s ==\n' "$label"
    local rule pat rep re n
    while IFS= read -r rule; do
        [[ -z "$rule" ]] && continue
        pat="${rule%%=>*}"
        rep="${rule##*=>}"
        # Guard ASCII patterns so identifiers, filenames (review_rubric_zh.md)
        # and longer words (Parked) are never touched; CJK patterns need no
        # boundary. bash 3.2 has no [[:ascii:]] class — the test must be an
        # explicit printable-ASCII range, or it fails open and drops the guard.
        if [[ "$pat" != *[^\ -~]* ]]; then
            re="(?<![\\w-])\\Q${pat}\\E(?![\\w-])"
        else
            re="\\Q${pat}\\E"
        fi
        n=$(echo "$files" | tr ' ' '\n' | grep -v '^$' | \
            xargs perl -CSD -Mutf8 -ne "\$c += () = /$re/g; END { print \$c // 0 }" 2>/dev/null || echo 0)
        printf '%6s  %s -> %s\n' "${n:-0}" "$pat" "$rep"
        if ! $DRY && [[ "${n:-0}" != "0" ]]; then
            echo "$files" | tr ' ' '\n' | grep -v '^$' | \
                xargs perl -CSD -Mutf8 -i -pe "s/$re/${rep}/g"
        fi
    done <<< "$rules_text"
}

ZHF="$(zh_files | tr '\n' ' ')"
ENF="$(en_files | tr '\n' ' ')"

$DRY && echo "DRY RUN — no files written"
apply_rules "$(printf '%s\n' "${ZH_RULES[@]}")" "$ZHF" "中文（$(echo "$ZHF" | wc -w | tr -d ' ') 个文件）"
apply_rules "$(printf '%s\n' "${EN_RULES[@]}")" "$ENF" "English ($(echo "$ENF" | wc -w | tr -d ' ') files)"

# Final sweep: any 门 the phrase rules above did not reach is an approval gate.
# 门槛 (threshold) and 一门/专门/部门/入门 are ordinary Chinese — guard both sides.
if ! $DRY; then
    printf '\n== 收尾：裸「门」==\n'
    echo "$ZHF" | tr ' ' '\n' | grep -v '^$' | \
        xargs perl -CSD -Mutf8 -i -pe 's/(?<![一专部入])门(?!槛)/确认点/g'
    echo "done"
fi
printf '\n'
