# 超级管理平台用户管理系统 API 接口规范

## 概述
本文档定义了用户管理系统的后端API接口规范，包含用户管理、权限控制、批量导入等功能。

## 基础配置

### 认证方式
- **认证类型**: JWT (JSON Web Token)
- **请求头**: `Authorization: Bearer {token}`
- **Token获取**: 通过登录接口获取

### 响应格式
```json
{
    "success": true,
    "code": 200,
    "message": "操作成功",
    "data": {},
    "timestamp": "2024-01-12T10:00:00Z"
}
```

### 错误码说明
- `200`: 成功
- `400`: 请求参数错误
- `401`: 未授权
- `403`: 权限不足
- `404`: 资源不存在
- `500`: 服务器内部错误

## API 接口详情

### 1. 用户认证接口

#### 1.1 用户登录
```http
POST /api/auth/login
```
**请求参数:**
```json
{
    "username": "string",
    "password": "string"
}
```

**响应:**
```json
{
    "success": true,
    "code": 200,
    "data": {
        "token": "jwt_token_string",
        "user": {
            "id": "uuid",
            "username": "string",
            "email": "string",
            "full_name": "string",
            "role": "string",
            "permissions": ["string"]
        }
    }
}
```

#### 1.2 刷新Token
```http
POST /api/auth/refresh
```
**请求头:** `Authorization: Bearer {refresh_token}`

**响应:** 与登录接口相同

### 2. 用户管理接口

#### 2.1 获取用户列表
```http
GET /api/users
```
**查询参数:**
- `page`: 页码 (默认: 1)
- `pageSize`: 每页数量 (默认: 10)
- `search`: 搜索关键词 (用户名/学号/姓名)
- `role`: 角色筛选
- `status`: 状态筛选
- `sortBy`: 排序字段
- `sortOrder`: 排序方式 (asc/desc)

**响应:**
```json
{
    "success": true,
    "data": {
        "users": [
            {
                "id": "uuid",
                "username": "string",
                "user_number": "string",
                "full_name": "string",
                "role": "string",
                "status": "string",
                "department": "string",
                "created_at": "timestamp"
            }
        ],
        "total": 100,
        "page": 1,
        "pageSize": 10
    }
}
```

#### 2.2 创建用户
```http
POST /api/users
```
**请求参数:**
```json
{
    "username": "string",
    "email": "string",
    "user_number": "string",
    "full_name": "string",
    "password": "string",
    "role": "teacher|student",
    "department": "string",
    "grade": "string",
    "class_name": "string",
    "phone": "string"
}
```

#### 2.3 更新用户信息
```http
PUT /api/users/{userId}
```
**请求参数:** (可部分更新)
```json
{
    "email": "string",
    "full_name": "string",
    "department": "string",
    "grade": "string",
    "class_name": "string",
    "phone": "string",
    "status": "active|inactive"
}
```

#### 2.4 删除用户
```http
DELETE /api/users/{userId}
```

#### 2.5 批量删除用户
```http
POST /api/users/batch-delete
```
**请求参数:**
```json
{
    "user_ids": ["uuid1", "uuid2"]
}
```

### 3. 密码管理接口

#### 3.1 重置用户密码
```http
POST /api/users/{userId}/reset-password
```
**响应:**
```json
{
    "success": true,
    "data": {
        "new_password": "随机生成的密码"
    }
}
```

#### 3.2 批量重置密码
```http
POST /api/users/batch-reset-password
```
**请求参数:**
```json
{
    "user_ids": ["uuid1", "uuid2"]
}
```

### 4. 批量导入接口

#### 4.1 下载导入模板
```http
GET /api/import/template
```
**查询参数:**
- `type`: `teachers` 或 `students`

**响应:** Excel文件下载

#### 4.2 上传导入文件
```http
POST /api/import/upload
Content-Type: multipart/form-data
```
**请求参数:**
- `file`: Excel文件
- `import_type`: `teachers` 或 `students`

**响应:**
```json
{
    "success": true,
    "data": {
        "batch_id": "uuid",
        "total_records": 100,
        "valid_records": 95,
        "invalid_records": 5,
        "preview_data": [
            {
                "username": "string",
                "user_number": "string",
                "full_name": "string",
                "valid": true,
                "errors": []
            }
        ]
    }
}
```

#### 4.3 确认导入
```http
POST /api/import/confirm
```
**请求参数:**
```json
{
    "batch_id": "uuid",
    "user_data": [
        {
            "username": "string",
            "user_number": "string",
            "full_name": "string",
            "department": "string",
            "grade": "string",
            "class_name": "string"
        }
    ]
}
```

**响应:**
```json
{
    "success": true,
    "data": {
        "import_id": "uuid",
        "success_count": 95,
        "failed_count": 5,
        "failed_records": [
            {
                "row_data": {},
                "error_message": "错误信息"
            }
        ]
    }
}
```

#### 4.4 获取导入历史
```http
GET /api/import/history
```
**查询参数:**
- `page`: 页码
- `pageSize`: 每页数量
- `import_type`: 导入类型
- `status`: 导入状态

**响应:**
```json
{
    "success": true,
    "data": {
        "imports": [
            {
                "id": "uuid",
                "filename": "string",
                "import_type": "string",
                "total_records": 100,
                "success_count": 95,
                "failed_count": 5,
                "status": "completed",
                "created_at": "timestamp",
                "imported_by": "用户名"
            }
        ],
        "total": 10
    }
}
```

### 5. 系统管理接口

#### 5.1 获取系统角色
```http
GET /api/system/roles
```
**响应:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "role_name": "super_admin",
            "role_description": "超级管理员",
            "permissions": ["string"]
        }
    ]
}
```

#### 5.2 获取系统统计
```http
GET /api/system/statistics
```
**响应:**
```json
{
    "success": true,
    "data": {
        "total_users": 1000,
        "active_users": 950,
        "teachers_count": 50,
        "students_count": 900,
        "today_logins": 50,
        "week_logins": 300
    }
}
```

### 6. 日志管理接口

#### 6.1 获取登录日志
```http
GET /api/logs/login
```
**查询参数:**
- `userId`: 用户ID
- `startDate`: 开始日期
- `endDate`: 结束日期
- `page`: 页码

#### 6.2 获取操作日志
```http
GET /api/logs/operation
```
**查询参数:**
- `userId`: 操作人ID
- `action`: 操作类型
- `startDate`: 开始日期

## 权限控制

### 角色权限矩阵

| 权限功能 | 超级管理员 | 教师 | 学生 |
|---------|-----------|------|------|
| 用户管理 | ✅ 全部权限 | ❌ 无权限 | ❌ 无权限 |
| 查看学生 | ✅ 全部学生 | ✅ 自己学生 | ✅ 仅自己 |
| 导入用户 | ✅ 允许 | ❌ 不允许 | ❌ 不允许 |
| 重置密码 | ✅ 允许 | ❌ 不允许 | ❌ 不允许 |

### 接口权限要求

- **用户管理相关接口**: 需要 `super_admin` 角色
- **批量导入接口**: 需要 `super_admin` 角色  
- **密码重置接口**: 需要 `super_admin` 角色
- **系统统计接口**: 需要 `super_admin` 或 `teacher` 角色
- **日志查看接口**: 需要 `super_admin` 角色

## 数据验证规则

### 用户数据验证
- **用户名**: 3-50字符，字母数字下划线
- **学号/工号**: 唯一，非空
- **邮箱**: 有效邮箱格式，可选
- **密码**: 最小6位，可选
- **姓名**: 非空，2-50字符

### 导入数据验证
- 检查用户名唯一性
- 检查学号/工号唯一性
- 验证必填字段
- 验证数据格式
- 验证角色有效性

## 错误处理

### 常见错误响应

```json
// 400 - 参数错误
{
    "success": false,
    "code": 400,
    "message": "请求参数错误",
    "errors": [
        {
            "field": "username",
            "message": "用户名已存在"
        }
    ]
}

// 401 - 未授权
{
    "success": false,
    "code": 401,
    "message": "未授权访问"
}

// 403 - 权限不足
{
    "success": false,
    "code": 403,
    "message": "权限不足"
}

// 500 - 服务器错误
{
    "success": false,
    "code": 500,
    "message": "服务器内部错误"
}
```

## 安全考虑

1. **密码安全**: 使用bcrypt加密存储
2. **SQL注入防护**: 使用参数化查询
3. **XSS防护**: 输入数据转义
4. **CSRF防护**: 使用JWT Token
5. **速率限制**: 接口调用频率限制
6. **数据加密**: 敏感数据传输加密

## 性能优化

1. **数据库索引**: 关键字段建立索引
2. **分页查询**: 大数据量使用分页
3. **缓存策略**: 频繁查询数据缓存
4. **异步处理**: 批量导入使用异步任务
5. **连接池**: 数据库连接复用

---

**文档版本**: v1.0  
**最后更新**: 2024-01-12  
**维护者**: 超级管理平台开发团队