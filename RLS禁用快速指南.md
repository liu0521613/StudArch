# RLS策略禁用快速指南

## 🎯 目标
取消数据库中所有表行级安全策略，让所有用户可以无限制访问数据。

## 🚀 最快执行方式（推荐）

### 方法一：分步执行（推荐）

**步骤1：检查现有表**
1. 打开 [Supabase Dashboard](https://app.supabase.com)
2. 选择项目：`mddpbyibesqewcktlqle`
3. 进入 **SQL Editor**
4. 执行 `CHECK_TABLES_FIRST.sql` 查看实际存在的表

**步骤2：使用通用RLS禁用脚本**
5. 执行 `UNIVERSAL_RLS_DISABLE.sql` 禁用所有RLS策略

**方法二：使用最小化脚本**
如果上述脚本仍有问题，执行 `MINIMAL_RLS_DISABLE.sql`

### 方法二：使用完整SQL脚本
- 执行 `disable_all_rls_policies.sql` 文件内容（包含所有表和策略）

## 📋 执行内容概览

### 主要操作
- ✅ 禁用7个核心表的RLS功能
- ✅ 删除17个常见安全策略  
- ✅ 验证清理结果

### 涉及的核心表
1. `users` - 用户表
2. `user_profiles` - 用户档案
3. `students` - 学生表
4. `teachers` - 教师表
5. `student_profiles` - 学生档案
6. `teacher_profiles` - 教师档案
7. `teacher_student_relations` - 师生关系

## 🔍 验证结果

执行完成后，运行验证SQL应该显示：
```sql
-- 所有表的 rowsecurity 应该为 false
-- 剩余策略数量应该为 0
```

## ⚠️ 注意事项

1. **安全影响**: 禁用RLS后，所有用户都能访问所有数据
2. **恢复方法**: 需要重新执行RLS策略才能恢复安全控制
3. **建议**: 仅在开发/调试时使用，生产环境请谨慎操作

## 📁 生成的文件

| 文件名 | 用途 |
|--------|------|
| `CHECK_TABLES_FIRST.sql` | 检查现有表（首先执行） |
| `UNIVERSAL_RLS_DISABLE.sql` | 通用RLS禁用脚本（推荐） |
| `MINIMAL_RLS_DISABLE.sql` | 最小化RLS禁用脚本 |
| `SIMPLE_CLEAN_RLS.sql` | 简单RLS清理脚本 |
| `FINAL_SAFE_RLS_DISABLE.sql` | 完整安全RLS禁用脚本 |

## ✅ 执行完成标志

当看到以下输出时，表示RLS已成功禁用：
```
RLS Status After Disable: 所有表的 rowsecurity = false
Remaining Policies: policy_count = 0
All RLS policies have been disabled!
```

---

**执行时间**: 约1-2分钟  
**难度等级**: ⭐⭐☆☆☆ (简单)  
**风险等级**: ⚠️⚠️⚠️☆☆ (中等)