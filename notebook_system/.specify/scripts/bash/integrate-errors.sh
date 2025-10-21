#!/usr/bin/env bash
# 错题整合脚本 - 自动化处理错题并整合到笔记中

set -e

# 解析命令行参数
ERROR_TEMPLATE=""
TARGET_NOTE=""
JSON_MODE=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            cat << 'EOF'
用法: integrate-errors.sh <错题模板文件> <目标笔记文件> [选项]

自动化处理错题并整合到学术笔记的易错点数据库中。

参数:
  错题模板文件    填写好的错题记录模板(.md文件)
  目标笔记文件    要整合到的笔记文件(.md文件)
  --json          以JSON格式输出结果
  --dry-run       预览模式，不实际修改文件
  --help          显示此帮助信息

示例:
  ./integrate-errors.sh error_001.md notes/数学/线性代数详解.md
  ./integrate-errors.sh error_002.md notes/物理/电磁学详解.md --json --dry-run

输出:
  成功整合错题到目标笔记的易错点数据库
  更新错题复盘统计信息
EOF
            exit 0
            ;;
        *)
            if [[ -z "$ERROR_TEMPLATE" ]]; then
                ERROR_TEMPLATE="$arg"
            elif [[ -z "$TARGET_NOTE" ]]; then
                TARGET_NOTE="$arg"
            else
                echo "错误: 未知参数 '$arg'" >&2
                echo "使用 --help 查看用法" >&2
                exit 1
            fi
            ;;
    esac
done

# 验证必需参数
if [[ -z "$ERROR_TEMPLATE" || -z "$TARGET_NOTE" ]]; then
    echo "错误: 必须提供错题模板文件和目标笔记文件" >&2
    echo "用法: $0 <错题模板文件> <目标笔记文件> [选项]" >&2
    exit 1
fi

# 检查文件是否存在
if [[ ! -f "$ERROR_TEMPLATE" ]]; then
    echo "错误: 错题模板文件不存在: $ERROR_TEMPLATE" >&2
    exit 1
fi

if [[ ! -f "$TARGET_NOTE" ]]; then
    echo "错误: 目标笔记文件不存在: $TARGET_NOTE" >&2
    exit 1
fi

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 解析错题模板文件
parse_error_template() {
    local template_file="$1"
    
    # 提取基本信息
    ERROR_ID=$(grep "^## 错题记录" "$template_file" | sed 's/## 错题记录 #//' || echo "未知")
    SUBJECT=$(grep "- 目标笔记：" "$template_file" | sed 's/.*：\[*\([^]]*\)\]*.*/\1/' || echo "未知")
    KNOWLEDGE_TAGS=$(grep "- 知识点标签：" "$template_file" | sed 's/.*：\[*\([^]]*\)\]*.*/\1/' || echo "")
    DIFFICULTY=$(grep "- 难度等级：" "$template_file" | sed 's/.*：\[*\([^]]*\)\]*.*/\1/' || echo "🟡中等")
    ERROR_TYPE=$(grep "- 错误类型：" "$template_file" | sed 's/.*：\[*\([^]]*\)\]*.*/\1/' || echo "未分类")
    MAIN_REASON=$(grep "- 主要错误原因：" "$template_file" | sed 's/.*：\[*\([^]]*\)\]*.*/\1/' || echo "")
    
    # 提取多行内容
    WRONG_SOLUTION=$(sed -n '/\*\*我的错误解答\*\*：/,/\*\*错误分析\*\*：/p' "$template_file" | sed '1d;$d' | sed '/^$/d')
    CORRECT_SOLUTION=$(sed -n '/\*\*正确解答\*\*：/,/\*\*我需要加强的知识点\*\*：/p' "$template_file" | sed '1d;$d' | sed '/^$/d')
    PREVENTION_PLAN=$(sed -n '/\*\*我的防错计划\*\*：/,$p' "$template_file" | sed '1d' | sed '/^$/d')
}

# 生成易错点条目
generate_error_entry() {
    local error_name="$1"
    local entry_number="$2"
    
    cat << EOF

#### ${entry_number}. **${error_name}**（错题 #${ERROR_ID}）
- ❌ **错误**：${MAIN_REASON}
- ✅ **正确**：${CORRECT_SOLUTION}
- **易错原因**：基于实际错题分析，${ERROR_TYPE}错误
- **实际案例**：![错题图片](./图片资源/错题图片/${ERROR_ID}.jpg)
- **防范措施**：
$(echo "$PREVENTION_PLAN" | sed 's/^/  /')
- **强化练习**：
  - 针对${KNOWLEDGE_TAGS}的基础练习
  - 类似题型的变式训练
  - 定期复习和自测

EOF
}

# 更新错题复盘统计
update_error_stats() {
    local note_file="$1"
    local error_type="$2"
    
    # 检查是否已有错题复盘章节
    if ! grep -q "## 🔄 本章错题复盘" "$note_file"; then
        # 添加错题复盘章节
        cat >> "$note_file" << EOF

---

## 🔄 本章错题复盘

### 错题统计
- 总错题数：1道
- 概念类错误：0道
- 计算类错误：0道
- 方法类错误：0道
- 应用类错误：0道

### 高频错误Top1
1. **${error_type}错误**：出现1次
   - 主要问题：${MAIN_REASON}
   - 核心缺陷：需要加强相关知识点理解
   - 改进重点：${KNOWLEDGE_TAGS}

### 改进建议
基于错题分析，建议重点加强：

1. **基础概念理解**：
   - 复习${KNOWLEDGE_TAGS}相关理论
   - 加强概念辨析和应用训练
   - 建立知识点之间的联系

2. **解题方法训练**：
   - 掌握标准解题步骤
   - 练习类似题型的变式
   - 培养检查和验证的习惯

3. **错误预防机制**：
   - 建立个人易错点清单
   - 定期回顾和强化训练
   - 考试前重点复习易错内容

**下次学习重点**：${KNOWLEDGE_TAGS}、解题方法规范化、错误预防策略
EOF
    else
        # 更新现有统计
        # 这里可以添加更复杂的统计更新逻辑
        echo "更新现有错题统计..." >&2
    fi
}

# 主处理流程
main() {
    if ! $JSON_MODE; then
        echo "🔄 开始处理错题整合..."
        echo "📝 错题模板: $ERROR_TEMPLATE"
        echo "📚 目标笔记: $TARGET_NOTE"
        echo ""
    fi
    
    # 解析错题模板
    echo "📖 解析错题模板..." >&2
    parse_error_template "$ERROR_TEMPLATE"
    
    if ! $JSON_MODE; then
        echo "✅ 错题信息解析完成:"
        echo "  🆔 错题编号: $ERROR_ID"
        echo "  📚 学科: $SUBJECT"
        echo "  🏷️  知识点: $KNOWLEDGE_TAGS"
        echo "  📊 难度: $DIFFICULTY"
        echo "  🔍 错误类型: $ERROR_TYPE"
        echo ""
    fi
    
    # 检查目标笔记是否有易错点数据库章节
    if ! grep -q "## ⚠️ 易错点数据库" "$TARGET_NOTE"; then
        if $DRY_RUN; then
            echo "预览: 将添加易错点数据库章节" >&2
        else
            echo "⚠️  目标笔记缺少易错点数据库章节，正在添加..." >&2
            # 在考试宝典后添加易错点数据库章节
            sed -i '/## 📖 考试宝典/a\\n---\n\n## ⚠️ 易错点数据库\n\n### 🚨 概念类易错点\n\n### 🚨 计算类易错点\n\n### 🚨 方法类易错点\n\n### 🚨 应用类易错点' "$TARGET_NOTE"
        fi
    fi
    
    # 确定错误类型对应的章节
    case "$ERROR_TYPE" in
        *概念*)
            section="### 🚨 概念类易错点"
            ;;
        *计算*)
            section="### 🚨 计算类易错点"
            ;;
        *方法*)
            section="### 🚨 方法类易错点"
            ;;
        *应用*)
            section="### 🚨 应用类易错点"
            ;;
        *)
            section="### 🚨 计算类易错点"  # 默认分类
            ;;
    esac
    
    # 生成错误名称
    error_name=$(echo "$KNOWLEDGE_TAGS" | cut -d',' -f1)
    if [[ -z "$error_name" ]]; then
        error_name="学习错误"
    fi
    error_name="${error_name}理解错误"
    
    # 计算条目编号
    entry_count=$(grep -c "^#### [0-9]*\." "$TARGET_NOTE" || echo "0")
    entry_number=$((entry_count + 1))
    
    if $DRY_RUN; then
        echo "🔍 预览模式 - 将要进行的操作:"
        echo "  📍 插入位置: $section"
        echo "  🏷️  错误名称: $error_name"
        echo "  🔢 条目编号: $entry_number"
        echo "  📝 错题编号: $ERROR_ID"
        echo ""
        echo "📋 生成的易错点条目预览:"
        generate_error_entry "$error_name" "$entry_number"
    else
        # 实际整合错题
        echo "🔧 正在整合错题到易错点数据库..." >&2
        
        # 创建临时文件
        temp_file=$(mktemp)
        
        # 在指定章节后添加新的易错点条目
        awk -v section="$section" -v entry="$(generate_error_entry "$error_name" "$entry_number")" '
        $0 == section {
            print $0
            print entry
            next
        }
        {print}
        ' "$TARGET_NOTE" > "$temp_file"
        
        # 替换原文件
        mv "$temp_file" "$TARGET_NOTE"
        
        # 更新错题统计
        echo "📊 更新错题复盘统计..." >&2
        update_error_stats "$TARGET_NOTE" "$ERROR_TYPE"
        
        echo "✅ 错题整合完成!" >&2
    fi
    
    # 输出结果
    if $JSON_MODE; then
        printf '{"status":"success","error_id":"%s","target_note":"%s","error_type":"%s","knowledge_tags":"%s","dry_run":%s}\n' \
            "$ERROR_ID" "$TARGET_NOTE" "$ERROR_TYPE" "$KNOWLEDGE_TAGS" "$DRY_RUN"
    else
        echo ""
        echo "🎉 错题处理完成!"
        echo "📝 已整合错题: $ERROR_ID"
        echo "📚 目标笔记: $TARGET_NOTE"
        echo "🔍 错误类型: $ERROR_TYPE"
        echo "🏷️  知识点: $KNOWLEDGE_TAGS"
        
        if ! $DRY_RUN; then
            echo ""
            echo "📖 建议后续操作:"
            echo "1. 检查整合结果: $TARGET_NOTE"
            echo "2. 验证笔记规范: ./validate-note.sh \"$TARGET_NOTE\""
            echo "3. 添加错题图片到: 图片资源/错题图片/${ERROR_ID}.jpg"
            echo "4. 完善强化练习内容"
        fi
    fi
}

# 执行主流程
main
