# 学术笔记规格说明: [FEATURE NAME]

**笔记分支**: `[学科-主题]`  
**创建时间**: [DATE]  
**状态**: 草稿  
**输入**: 用户需求: "$ARGUMENTS"

## 学习场景与测试 *(必填)*

<!--
  重要说明: 学习场景应该按重要性排序，每个学习目标必须是独立可测试的。
  这意味着如果您只完成其中一个目标，仍然应该有一个可行的最小学习成果。
  
  为每个场景分配优先级 (P1, P2, P3等)，其中P1是最关键的。
  将每个场景视为独立的学习切片，可以：
  - 独立学习
  - 独立测试
  - 独立掌握
  - 独立应用
-->

### 学习目标 1 - [简要标题] (优先级: P1)

[用简单语言描述这个学习目标]

**优先级原因**: [解释价值和为什么是这个优先级]

**独立测试**: [描述如何独立测试这个学习成果 - 例如："可以通过[具体行动]完全测试并获得[具体价值]"]

**验收场景**:

1. **给定** [初始状态], **当** [学习行动], **那么** [预期学习成果]
2. **给定** [初始状态], **当** [应用行动], **那么** [预期应用效果]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  
- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
- **FR-005**: System MUST [behavior, e.g., "log all security events"]

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]
- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]
- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]

