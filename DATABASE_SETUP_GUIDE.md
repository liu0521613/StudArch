# 超级管理平台 - 数据库安装配置指南

## 📋 文档说明

本文档提供完整的数据库安装和配置指导，帮助您的队友在 Supabase 中成功部署和运行项目数据库。

---

## 🚀 快速开始

### 前置要求

1. **Supabase 账户** - 确保您有有效的 Supabase 账户
2. **项目访问权限** - 确保您有创建新项目的权限
3. **必要的扩展权限** - 确保可以启用数据库扩展

---

## 📝 安装步骤

### 第一步：创建 Supabase 项目

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 点击 **New Project**
3. 配置项目信息：
   - **Name**: `super-admin-platform` (或自定义名称)
   - **Database Password**: 设置安全的数据库密码
   - **Region**: 选择离您最近的区域
4. 点击 **Create new project**

### 第二步：准备数据库环境

1. 进入项目后，点击左侧菜单的 **SQL Editor**
2. 确保已启用以下数据库扩展：
   ```sql
   -- 检查扩展状态
   SELECT * FROM pg_available_extensions 
   WHERE name IN ('uuid-ossp', 'pgcrypto');
   
   -- 如果没有启用，启用它们
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   CREATE EXTENSION IF NOT EXISTS "pgcrypto";
   ```

### 第三步：执行数据库初始化脚本

1. 复制 `database_backup_complete.sql` 文件中的全部内容
2. 在 SQL Editor 中粘贴并执行整个脚本
3. 脚本执行时间：约 2-5 分钟

### 第四步：验证数据库初始化

脚本执行完成后，检查以下内容：

1. **查看验证结果**：脚本最后会显示数据统计信息
2. **检查表结构**：
   ```sql
   -- 查看所有表
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

3. **验证测试数据**：
   ```sql
   -- 查看用户数据
   SELECT * FROM user_details LIMIT 10;
   
   -- 查看学生信息
   SELECT * FROM student_complete_info;
   ```

---

## 🔧 配置说明

### 环境变量配置

在项目根目录创建或更新 `.env` 文件：

```env
# Supabase Configuration
VITE_SUPABASE_URL=您的项目URL
VITE_SUPABASE_ANON_KEY=您的匿名密钥
VITE_SUPABASE_SERVICE_ROLE_KEY=您的服务角色密钥
```

**如何获取配置信息：**

1. 在 Supabase 项目中，进入 **Settings** > **API**
2. 复制以下信息：
   - **Project URL**: 位于 `Configuration` 部分
   - **anon public**: 匿名密钥
   - **service_role secret**: 服务角色密钥

### 数据库连接测试

创建测试文件验证连接：

```javascript
// test_connection.js
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function testConnection() {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .limit(1);
    
    if (error) throw error;
    
    console.log('✅ 数据库连接成功！');
    console.log('测试数据：', data);
  } catch (error) {
    console.error('❌ 数据库连接失败：', error.message);
  }
}

testConnection();
```

---

## 🔐 安全配置

### 行级安全策略 (RLS)

数据库已配置以下安全策略：

1. **用户权限管理**
   - 超级管理员：完全访问权限
   - 教师：查看学生信息权限
   - 学生：仅查看和修改自己的信息

2. **数据访问控制**
   - 个人信息访问限制
   - 班级信息权限控制
   - 系统设置管理权限

### 密码安全

测试用户的默认密码为 `123456`，建议在生产环境中：

1. 修改默认密码
2. 启用强密码策略
3. 配置密码复杂度要求

---

## 📊 测试数据说明

### 默认测试账户

| 用户名 | 角色 | 密码 | 功能描述 |
|--------|------|------|----------|
| `admin` | 超级管理员 | 123456 | 完全系统管理权限 |
| `teacher_zhang` | 教师 | 123456 | 学生信息查看和管理 |
| `student_2021001` | 学生 | 123456 | 个人信息维护功能 |

### 测试功能验证

1. **学生信息维护**
   - 登录学生账户
   - 验证个人信息编辑功能
   - 测试信息提交和审核流程

2. **教师管理功能**
   - 登录教师账户
   - 验证学生信息查看权限
   - 测试信息审核功能

3. **管理员功能**
   - 系统设置管理
   - 用户权限管理
   - 数据统计查看

---

## 🛠️ 故障排除

### 常见问题

**Q: 脚本执行失败，提示扩展未启用**
A: 手动启用扩展：
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

**Q: 表已存在错误**
A: 脚本会自动删除现有表，如果仍有问题，手动删除：
```sql
DROP TABLE IF EXISTS users CASCADE;
-- 重复执行脚本
```

**Q: 权限策略不生效**
A: 检查 RLS 是否启用：
```sql
-- 检查表的安全策略
SELECT * FROM pg_policies WHERE tablename = 'users';
```

### 性能优化建议

1. **索引优化**
   - 已为常用查询字段创建索引
   - 根据实际使用情况调整索引策略

2. **查询优化**
   - 使用视图简化复杂查询
   - 避免全表扫描

---

## 📁 文件说明

### 关键文件

| 文件名 | 描述 | 用途 |
|--------|------|------|
| `database_backup_complete.sql` | 完整数据库备份 | 一次性执行所有数据库初始化 |
| `.env` | 环境配置文件 | 配置 Supabase 连接信息 |
| `package.json` | 项目依赖配置 | 查看项目依赖和脚本 |

### 备份和恢复

**备份数据库：**
```sql
-- 在 Supabase Dashboard 中使用备份功能
-- 或使用 pg_dump 工具
```

**恢复数据：**
- 重新执行 `database_backup_complete.sql` 脚本
- 或使用 Supabase 的导入功能

---

## 📞 技术支持

### 联系信息

- **项目负责人**: [您的姓名]
- **技术支持**: [团队联系方式]
- **文档维护**: [文档维护者]

### 问题反馈

遇到问题时，请提供以下信息：
1. 错误消息和堆栈跟踪
2. 操作步骤复现
3. 相关环境信息

---

## ✅ 完成检查清单

- [ ] Supabase 项目创建成功
- [ ] 数据库扩展已启用
- [ ] 数据库脚本执行完成
- [ ] 测试数据验证通过
- [ ] 环境变量配置正确
- [ ] 连接测试成功
- [ ] 安全策略生效
- [ ] 功能测试完成

---

**最后更新**: 2025-11-17  
**版本**: v1.0  
**维护者**: AI 助手