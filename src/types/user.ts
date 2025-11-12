export interface User {
  id: string
  username: string
  email: string
  user_number: string
  full_name: string
  password?: string // 明文密码（仅用于创建时）
  password_hash?: string // 加密后的密码
  role_id: string
  status: 'active' | 'inactive' | 'pending'
  created_at: string
  updated_at: string
  last_login_at?: string
}

export interface Role {
  id: string
  role_name: 'super_admin' | 'teacher' | 'student'
  role_description: string
  permissions: any
  is_system_default: boolean
  created_at: string
  updated_at: string
}

export interface UserWithRole extends User {
  role: Role
}

export interface UserSearchParams {
  keyword?: string
  role_id?: string
  status?: string
  page?: number
  limit?: number
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

export interface UserListResponse {
  users: UserWithRole[]
  total: number
  page: number
  limit: number
  total_pages: number
}

export interface BatchImport {
  id: string
  filename: string
  total_rows: number
  success_rows: number
  failed_rows: number
  status: 'pending' | 'processing' | 'completed' | 'failed'
  created_by: string
  created_at: string
  completed_at?: string
}

export interface ImportFailure {
  id: string
  import_id: string
  row_number: number
  error_message: string
  raw_data: string
  created_at: string
}