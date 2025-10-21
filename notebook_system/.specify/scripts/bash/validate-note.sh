#!/usr/bin/env bash
# 学术笔记验证脚本 - 检查笔记是否符合规范

set -e

# 解析命令行参数
NOTE_FILE=""
JSON_MODE=false
STRICT_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --strict)
            STRICT_MODE=true
            ;;
        --help|-h)
            cat << 'EOF'
用法: validate-note.sh <笔记文件> [选项]

验证学术笔记是否符合Markdown规范v2.0和宪法要求。

参数:
  笔记文件      要验证的.md文件路径
  --json        以JSON格式输出验证结果
  --strict      严格模式，任何警告都视为错误
  --help        显示此帮助信息

示例:
  ./validate-note.sh notes/数学/线性代数详解.md
  ./validate-note.sh notes/物理/电磁学详解.md --json --strict

输出:
  文本模式: 显示详细的验证结果和建议
  JSON模式: 返回结构化的验证数据
EOF
            exit 0
            ;;
        *)
            if [[ -z "$NOTE_FILE" ]]; then
                NOTE_FILE="$arg"
            else
                echo "错误: 未知参数 '$arg'" >&2
                echo "使用 --help 查看用法" >&2
                exit 1
            fi
            ;;
    esac
done

# 验证必需参数
if [[ -z "$NOTE_FILE" ]]; then
    echo "错误: 必须提供笔记文件路径" >&2
    echo "用法: $0 <笔记文件> [选项]" >&2
    exit 1
fi

# 检查文件是否存在
if [[ ! -f "$NOTE_FILE" ]]; then
    if $JSON_MODE; then
        printf '{"status":"error","message":"文件不存在: %s"}\n' "$NOTE_FILE"
    else
        echo "❌ 错误: 文件不存在: $NOTE_FILE" >&2
    fi
    exit 1
fi

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 初始化验证结果
ERRORS=()
WARNINGS=()
PASSED_CHECKS=()

# 验证函数
add_error() { ERRORS+=("$1"); }
add_warning() { WARNINGS+=("$1"); }
add_passed() { PASSED_CHECKS+=("$1"); }

# 1. 检查文件基本信息
if $JSON_MODE; then
    echo "🔍 开始验证: $(basename "$NOTE_FILE")" >&2
else
    echo "🔍 验证学术笔记规范: $NOTE_FILE"
    echo "📋 基于学术笔记系统宪法v1.0进行检查"
    echo ""
fi

# 2. 检查必备章节
echo "📖 检查必备章节结构..." >&2

REQUIRED_SECTIONS=(
    "知识体系思维导图"
    "考试宝典"
    "易错点数据库"
    "速查手册"
    "分层次例题体系"
    "总结"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "$section" "$NOTE_FILE"; then
        add_passed "包含必备章节: $section"
    else
        add_error "缺少必备章节: $section"
    fi
done

# 3. 检查标题层级规范
echo "📝 检查标题层级规范..." >&2

# 检查是否有且仅有一个一级标题
h1_count=$(grep -c "^# " "$NOTE_FILE" || true)
if [[ $h1_count -eq 1 ]]; then
    add_passed "标题层级: 有且仅有一个一级标题"
elif [[ $h1_count -eq 0 ]]; then
    add_error "标题层级: 缺少一级标题"
else
    add_error "标题层级: 存在多个一级标题($h1_count个)"
fi

# 检查标题层级是否合理(不跳级)
if grep -q "^##### " "$NOTE_FILE"; then
    add_warning "标题层级: 使用了五级标题，建议避免过深的层级"
fi

# 4. 检查Mermaid思维导图
echo "🗺️ 检查Mermaid思维导图..." >&2

if grep -q "```mermaid" "$NOTE_FILE"; then
    add_passed "包含Mermaid思维导图"
    
    # 提取mermaid代码块并检查是否包含数学公式
    mermaid_content=$(sed -n '/```mermaid/,/```/p' "$NOTE_FILE")
    
    # 检查是否包含禁止的数学符号
    forbidden_symbols=('$' '=' '+' '-' '*' '/' '^' '_' '≥' '≤' '≠' '∞' 'α' 'β' 'γ' 'π' 'Ω')
    for symbol in "${forbidden_symbols[@]}"; do
        if echo "$mermaid_content" | grep -q "$symbol"; then
            add_error "Mermaid思维导图: 包含禁止的数学符号 '$symbol'"
        fi
    done
    
    # 检查是否包含括号组合
    if echo "$mermaid_content" | grep -q "P("; then
        add_error "Mermaid思维导图: 包含概率表达式 'P('"
    fi
    
    if ! echo "$mermaid_content" | grep -q "ERROR"; then
        add_passed "Mermaid语法: 未发现明显语法错误"
    fi
else
    add_error "缺少Mermaid思维导图"
fi

# 5. 检查数学公式格式
echo "🔢 检查数学公式格式..." >&2

# 统计数学公式数量
inline_formulas=$(grep -o '\$[^$]*\$' "$NOTE_FILE" | wc -l || true)
block_formulas=$(grep -c '^\$\$' "$NOTE_FILE" || true)

if [[ $inline_formulas -gt 0 || $block_formulas -gt 0 ]]; then
    add_passed "数学公式: 发现 $inline_formulas 个行内公式, $block_formulas 个独立公式"
    
    # 检查是否有未闭合的公式
    if grep -q '\$[^$]*$' "$NOTE_FILE"; then
        add_warning "数学公式: 可能存在未闭合的公式标记"
    fi
else
    add_warning "数学公式: 未发现数学公式，如果是数理科目请检查是否遗漏"
fi

# 6. 检查Emoji使用规范
echo "😊 检查Emoji使用规范..." >&2

# 检查是否使用了规范的Emoji
standard_emojis=('📊' '📖' '⚠️' '📋' '💪' '🔥' '⚡' '🎯' '🚨' '🔧' '🔢' '🟢' '🟡' '🔴' '🏆')
emoji_found=false

for emoji in "${standard_emojis[@]}"; do
    if grep -q "$emoji" "$NOTE_FILE"; then
        emoji_found=true
        break
    fi
done

if $emoji_found; then
    add_passed "Emoji使用: 使用了规范的Emoji标记"
else
    add_warning "Emoji使用: 建议使用规范的Emoji来增强视觉效果"
fi

# 7. 检查内容质量
echo "✅ 检查内容质量..." >&2

# 检查文件大小
file_size=$(wc -c < "$NOTE_FILE")
if [[ $file_size -gt 5242880 ]]; then  # 5MB
    add_error "文件大小: 超过5MB限制，需要拆分"
elif [[ $file_size -lt 1000 ]]; then
    add_warning "文件大小: 内容较少，可能需要补充"
else
    add_passed "文件大小: 符合要求"
fi

# 检查是否有TODO或待完成标记
if grep -qi "TODO\|待完成\|FIXME\|待修正" "$NOTE_FILE"; then
    add_warning "内容完整性: 发现待完成标记，请及时完善"
fi

# 8. 检查错题复盘章节
echo "🔄 检查错题复盘..." >&2

if grep -q "错题复盘" "$NOTE_FILE"; then
    add_passed "包含错题复盘章节"
    
    # 检查是否有错题统计
    if grep -q "总错题数" "$NOTE_FILE"; then
        add_passed "错题复盘: 包含错题统计信息"
    else
        add_warning "错题复盘: 缺少错题统计信息"
    fi
else
    add_warning "建议添加错题复盘章节"
fi

# 9. 生成验证报告
total_errors=${#ERRORS[@]}
total_warnings=${#WARNINGS[@]}
total_passed=${#PASSED_CHECKS[@]}

if $JSON_MODE; then
    # JSON输出
    errors_json=$(printf '"%s",' "${ERRORS[@]}")
    warnings_json=$(printf '"%s",' "${WARNINGS[@]}")
    passed_json=$(printf '"%s",' "${PASSED_CHECKS[@]}")
    
    errors_json="[${errors_json%,}]"
    warnings_json="[${warnings_json%,}]"
    passed_json="[${passed_json%,}]"
    
    if [[ $total_errors -eq 0 && ($total_warnings -eq 0 || ! $STRICT_MODE) ]]; then
        status="passed"
    else
        status="failed"
    fi
    
    printf '{"status":"%s","file":"%s","errors":%s,"warnings":%s,"passed":%s,"summary":{"errors":%d,"warnings":%d,"passed":%d}}\n' \
        "$status" "$NOTE_FILE" "$errors_json" "$warnings_json" "$passed_json" \
        "$total_errors" "$total_warnings" "$total_passed"
else
    # 文本输出
    echo ""
    echo "📊 验证结果汇总:"
    echo "✅ 通过检查: $total_passed 项"
    echo "⚠️  警告: $total_warnings 项"
    echo "❌ 错误: $total_errors 项"
    echo ""
    
    if [[ $total_passed -gt 0 ]]; then
        echo "✅ 通过的检查:"
        for check in "${PASSED_CHECKS[@]}"; do
            echo "  ✓ $check"
        done
        echo ""
    fi
    
    if [[ $total_warnings -gt 0 ]]; then
        echo "⚠️  警告信息:"
        for warning in "${WARNINGS[@]}"; do
            echo "  ⚠ $warning"
        done
        echo ""
    fi
    
    if [[ $total_errors -gt 0 ]]; then
        echo "❌ 错误信息:"
        for error in "${ERRORS[@]}"; do
            echo "  ✗ $error"
        done
        echo ""
    fi
    
    # 最终结论
    if [[ $total_errors -eq 0 && ($total_warnings -eq 0 || ! $STRICT_MODE) ]]; then
        echo "🎉 验证通过! 笔记符合学术笔记系统规范。"
        exit 0
    else
        if [[ $total_errors -gt 0 ]]; then
            echo "💥 验证失败! 请修正上述错误后重新验证。"
        elif $STRICT_MODE; then
            echo "💥 严格模式验证失败! 请处理所有警告。"
        fi
        exit 1
    fi
fi
