#!/usr/bin/env bash
# 学术笔记创建脚本 - 专门为学术笔记系统设计

set -e

# 解析命令行参数
SUBJECT=""
TOPIC=""
JSON_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            cat << 'EOF'
用法: create-note.sh <学科> <主题> [--json]

创建新的学术笔记，包含完整的目录结构和模板文件。

参数:
  学科        笔记所属学科 (如: 数学, 物理, 计算机)
  主题        笔记主题 (如: 线性代数, 电磁学, 数据结构)
  --json      以JSON格式输出结果
  --help      显示此帮助信息

示例:
  ./create-note.sh 数学 线性代数
  ./create-note.sh 物理 电磁学 --json

输出:
  创建笔记文件: notes/数学/线性代数详解.md
  创建规格目录: specs/数学-线性代数/
EOF
            exit 0
            ;;
        *)
            if [[ -z "$SUBJECT" ]]; then
                SUBJECT="$arg"
            elif [[ -z "$TOPIC" ]]; then
                TOPIC="$arg"
            else
                echo "错误: 未知参数 '$arg'" >&2
                echo "使用 --help 查看用法" >&2
                exit 1
            fi
            ;;
    esac
done

# 验证必需参数
if [[ -z "$SUBJECT" || -z "$TOPIC" ]]; then
    echo "错误: 必须提供学科和主题参数" >&2
    echo "用法: $0 <学科> <主题> [--json]" >&2
    echo "示例: $0 数学 线性代数" >&2
    exit 1
fi

# 获取脚本目录和通用函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 获取仓库根目录
REPO_ROOT=$(get_repo_root)

# 定义目录和文件路径
NOTE_DIR="$REPO_ROOT/notes/$SUBJECT"
NOTE_FILE="$NOTE_DIR/${TOPIC}详解.md"
SPEC_DIR="$REPO_ROOT/specs/$SUBJECT-$TOPIC"

# 创建目录结构
mkdir -p "$NOTE_DIR"
mkdir -p "$SPEC_DIR/contracts"
mkdir -p "$REPO_ROOT/图片资源/错题图片"
mkdir -p "$REPO_ROOT/图片资源/解答图片"

# 检查笔记模板
NOTE_TEMPLATE="$REPO_ROOT/.specify/templates/note-template.md"
if [[ ! -f "$NOTE_TEMPLATE" ]]; then
    echo "警告: 笔记模板不存在，创建基础模板..." >&2
    cat > "$NOTE_TEMPLATE" << 'EOF'
# [主题名称]详解

**课程来源**: [课程名称]  
**授课教师**: [教师姓名]  
**学校**: [学校名称]

## 📊 知识体系思维导图

```mermaid
mindmap
  root(([主题名称]))
    基本概念
      定义
      特征
      条件
    核心内容
      理论1
      理论2
      应用
    实际应用
      应用1
      应用2
      案例
```

---

## 第一部分：基本概念

### 1.1 定义

### 1.2 基本性质

## 第二部分：核心理论

### 2.1 理论基础

### 2.2 重要公式

## 第三部分：实际应用

### 3.1 应用领域

### 3.2 典型案例

---

## 📖 考试宝典

### 🔥 高频考点总结

### ⚡ 快速解题技巧

### 🎯 标准答题模板

---

## ⚠️ 易错点数据库

### 🚨 概念类易错点

### 🚨 计算类易错点

---

## 📋 速查手册

### 🔧 核心公式速查表

### 🔢 常用数值速查表

---

## 💪 分层次例题体系

### 🟢 第一层：基础理解题

### 🟡 第二层：应用计算题

### 🔴 第三层：综合分析题

---

## 🏆 考试冲刺要点

### 必背公式

### 关键概念

### 解题技巧

---

## 总结

[知识点总结和学习建议]
EOF
fi

# 从模板创建笔记文件
cp "$NOTE_TEMPLATE" "$NOTE_FILE"
sed -i "s/\[主题名称\]/$TOPIC/g" "$NOTE_FILE"
sed -i "s/\[课程名称\]/$SUBJECT/g" "$NOTE_FILE"

# 创建规格说明文件
SPEC_TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
PLAN_TEMPLATE="$REPO_ROOT/.specify/templates/plan-template.md"

if [[ -f "$SPEC_TEMPLATE" ]]; then
    cp "$SPEC_TEMPLATE" "$SPEC_DIR/spec.md"
    sed -i "s/\[FEATURE NAME\]/$SUBJECT-$TOPIC 学术笔记/g" "$SPEC_DIR/spec.md"
    sed -i "s/\[###-feature-name\]/$SUBJECT-$TOPIC/g" "$SPEC_DIR/spec.md"
fi

if [[ -f "$PLAN_TEMPLATE" ]]; then
    cp "$PLAN_TEMPLATE" "$SPEC_DIR/plan.md"
    sed -i "s/\[FEATURE\]/$SUBJECT-$TOPIC 学术笔记/g" "$SPEC_DIR/plan.md"
    sed -i "s/\[###-feature-name\]/$SUBJECT-$TOPIC/g" "$SPEC_DIR/plan.md"
fi

# 创建学术笔记专用的数据模型文件
cat > "$SPEC_DIR/data-model.md" << EOF
# 数据模型: $SUBJECT-$TOPIC 学术笔记

## 笔记结构模型

### 核心实体

#### Note (笔记)
- **标题**: $TOPIC详解
- **学科**: $SUBJECT
- **创建日期**: $(date +%Y-%m-%d)
- **状态**: 草稿/完成/需要更新

#### Section (章节)
- **章节编号**: 1.1, 1.2, 2.1, etc.
- **章节标题**: 具体章节名称
- **内容类型**: 概念/理论/应用/例题

#### ErrorRecord (错题记录)
- **错题编号**: YYYYMMDD_学科_序号
- **错误类型**: 概念性/计算性/方法性/应用性
- **关联知识点**: 相关章节和概念
- **整合状态**: 待处理/已整合/需要复查

#### Formula (公式)
- **公式编号**: 按章节编号
- **公式内容**: LaTeX格式
- **适用条件**: 使用前提和限制
- **相关例题**: 关联的例题编号

### 关系模型

- Note 1:N Section (一个笔记包含多个章节)
- Section 1:N Formula (一个章节包含多个公式)
- Section 1:N ErrorRecord (一个章节关联多个错题)
- ErrorRecord M:N Formula (错题可能涉及多个公式)

### 质量指标

- **完整性**: 必备章节是否齐全
- **准确性**: 公式和概念是否正确
- **实用性**: 考试宝典和速查手册是否有效
- **更新频率**: 错题整合和内容更新频率
EOF

# 输出结果
if $JSON_MODE; then
    printf '{"note_file":"%s","spec_dir":"%s","subject":"%s","topic":"%s","status":"created"}\n' \
        "$NOTE_FILE" "$SPEC_DIR" "$SUBJECT" "$TOPIC"
else
    echo "✅ 学术笔记创建成功!"
    echo "📝 笔记文件: $NOTE_FILE"
    echo "📋 规格目录: $SPEC_DIR"
    echo "🎯 学科: $SUBJECT"
    echo "📚 主题: $TOPIC"
    echo ""
    echo "📖 下一步操作:"
    echo "1. 编辑笔记内容: $NOTE_FILE"
    echo "2. 使用 /speckit.plan 命令规划笔记内容"
    echo "3. 使用 /speckit.tasks 命令分解任务"
    echo "4. 使用 /speckit.implement 命令自动化实施"
fi
