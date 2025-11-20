import { supabase } from '../lib/supabase'
import { User, UserWithRole, UserSearchParams, UserListResponse, BatchImport, ImportFailure } from '../types/user'

export class UserService {
  // 获取用户列表（带搜索和分页）
  static async getUsers(params: UserSearchParams): Promise<UserListResponse> {
    const {
      keyword = '',
      role_id,
      status,
      page = 1,
      limit = 10,
      sort_by = 'created_at',
      sort_order = 'desc'
    } = params

    let query = supabase
      .from('users')
      .select(`
        *,
        role:roles(*)
      `, { count: 'exact' })

    // 搜索条件
    if (keyword) {
      query = query.or(`username.ilike.%${keyword}%,email.ilike.%${keyword}%,full_name.ilike.%${keyword}%`)
    }

    if (role_id) {
      query = query.eq('role_id', role_id)
    }

    if (status) {
      query = query.eq('status', status)
    }

    // 排序和分页
    query = query
      .order(sort_by, { ascending: sort_order === 'asc' })
      .range((page - 1) * limit, page * limit - 1)

    const { data, error, count } = await query

    if (error) {
      throw new Error(`获取用户列表失败: ${error.message}`)
    }

    return {
      users: data as UserWithRole[],
      total: count || 0,
      page,
      limit,
      total_pages: Math.ceil((count || 0) / limit)
    }
  }

  // 获取单个用户详情
  static async getUserById(id: string): Promise<UserWithRole> {
    const { data, error } = await supabase
      .from('users')
      .select(`
        *,
        role:roles(*)
      `)
      .eq('id', id)
      .single()

    if (error) {
      throw new Error(`获取用户详情失败: ${error.message}`)
    }

    return data as UserWithRole
  }

  // 创建用户
  static async createUser(userData: Partial<User>): Promise<User> {
    // 简化处理：直接使用密码作为哈希值（仅用于测试，生产环境需要加密）
    const userToCreate = { 
      ...userData,
      password_hash: userData.password || '123456' // 为测试简化
    };
    
    // 移除前端发送的明文密码字段
    delete (userToCreate as any).password;

    const { data, error } = await supabase
      .from('users')
      .insert([userToCreate])
      .select()
      .single()

    if (error) {
      console.error('创建用户详细错误:', error);
      throw new Error(`创建用户失败: ${error.message}`)
    }

    return data
  }

  // 更新用户
  static async updateUser(id: string, userData: Partial<User>): Promise<User> {
    const { data, error } = await supabase
      .from('users')
      .update(userData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      throw new Error(`更新用户失败: ${error.message}`)
    }

    return data
  }

  // 删除用户
  static async deleteUser(id: string): Promise<void> {
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id)

    if (error) {
      throw new Error(`删除用户失败: ${error.message}`)
    }
  }

  // 批量重置密码
  static async batchResetPassword(userIds: string[]): Promise<void> {
    const { error } = await supabase.rpc('batch_reset_password', {
      user_ids: userIds
    })

    if (error) {
      throw new Error(`批量重置密码失败: ${error.message}`)
    }
  }

  // 获取角色列表
  static async getRoles() {
    const { data, error } = await supabase
      .from('roles')
      .select('*')
      .order('name')

    if (error) {
      throw new Error(`获取角色列表失败: ${error.message}`)
    }

    return data
  }

  // 获取导入记录列表
  static async getImportRecords(page: number = 1, limit: number = 10): Promise<{ imports: BatchImport[], total: number }> {
    const { data, error, count } = await supabase
      .from('batch_imports')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    if (error) {
      throw new Error(`获取导入记录失败: ${error.message}`)
    }

    return {
      imports: data || [],
      total: count || 0
    }
  }

  // 获取导入失败详情
  static async getImportFailures(importId: string): Promise<ImportFailure[]> {
    const { data, error } = await supabase
      .from('import_failures')
      .select('*')
      .eq('import_id', importId)
      .order('row_number')

    if (error) {
      throw new Error(`获取导入失败详情失败: ${error.message}`)
    }

    return data || []
  }

  // 开始批量导入
  static async startBatchImport(filename: string, data: any[]): Promise<BatchImport> {
    const { data: result, error } = await supabase.rpc('batch_import_users', {
      p_filename: filename,
      p_data: data
    })

    if (error) {
      throw new Error(`开始批量导入失败: ${error.message}`)
    }

    return result
  }

  // 获取系统统计数据
  static async getDashboardStats() {
    const { data, error } = await supabase.rpc('get_dashboard_stats')

    if (error) {
      throw new Error(`获取统计数据失败: ${error.message}`)
    }

    return data
  }

  // 获取所有已授权的学生（用于教师批量导入）
  static async getAuthorizedStudents(params?: {
    keyword?: string
    grade?: string
    department?: string
    page?: number
    limit?: number
  }): Promise<{ students: UserWithRole[], total: number }> {
    const {
      keyword = '',
      grade,
      department,
      page = 1,
      limit = 50
    } = params || {}

    // 尝试多个函数版本
    // 1. 尝试修正后的函数
    const result1 = await supabase
      .rpc('get_all_available_students_v2', {
        p_keyword: keyword,
        p_grade: grade || '',
        p_department: department || '',
        p_page: page,
        p_limit: limit
      });
    
    if (!result1.error) {
      const result = result1.data?.[0];
      return {
        students: (result?.students || []) as UserWithRole[],
        total: result?.total_count || 0
      };
    }

    // 2. 尝试原函数
    const result2 = await supabase
      .rpc('get_authorized_students', {
        p_keyword: keyword,
        p_grade: grade || '',
        p_department: department || '',
        p_page: page,
        p_limit: limit
      });

    if (!result2.error) {
      if (!result2.data || result2.data.length === 0) {
        return { students: [], total: 0 }
      }
      const result = result2.data[0]
      return {
        students: (result.students || []) as UserWithRole[],
        total: result.total_count || 0
      }
    }

    console.warn('所有RPC函数都失败，使用直接查询作为fallback');
    
    // Fallback: 直接查询users表，确保只返回学生角色
    let query = supabase
      .from('users')
      .select(`
        *,
        role:roles(*)
      `, { count: 'exact' })
      .eq('role_id', '3') // 明确指定学生角色ID
      .eq('status', 'active')

    // 搜索条件
    if (keyword) {
      query = query.or(`full_name.ilike.%${keyword}%,user_number.ilike.%${keyword}%,email.ilike.%${keyword}%`)
    }

    if (grade) {
      query = query.eq('grade', grade)
    }

    if (department) {
      query = query.eq('department', department)
    }

    // 排序和分页
    query = query
      .order('created_at', { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    const { data, error: fallbackError, count } = await query

    if (fallbackError) {
      throw new Error(`获取已授权学生列表失败: ${fallbackError.message}`)
    }

    return {
      students: data as UserWithRole[] || [],
      total: count || 0
    }
  }

  // 教师批量添加学生到自己的管理列表
  static async teacherAddStudents(studentIds: string[], teacherId: string): Promise<{ success: number, failed: number }> {
    try {
      // 首先尝试使用灵活的函数（支持字符串ID）
      const { data, error } = await supabase
        .rpc('add_students_flexible', {
          p_teacher_id: teacherId,
          p_student_ids: studentIds
        })

      if (error) {
        console.error('超安全函数调用失败，尝试简化函数:', error);
        
        // 如果超安全函数失败，尝试简化函数
        const { data: simpleData, error: simpleError } = await supabase
          .rpc('add_students_to_teacher_simple', {
            p_teacher_id: teacherId,
            p_student_ids: studentIds
          })
        
        if (simpleError) {
          console.error('简化函数也失败，尝试原函数:', simpleError);
          
          // 如果简化函数失败，尝试原函数
          const { data: oldData, error: oldError } = await supabase
            .rpc('batch_add_students_to_teacher', {
              p_teacher_id: teacherId,
              p_student_ids: studentIds
            })
          
          if (oldError) {
            console.error('原函数也失败:', oldError);
            throw new Error(`批量添加学生失败: ${oldError.message}`)
          }
          
          console.log('原函数返回数据:', oldData);
          return {
            success: oldData?.success || 0,
            failed: oldData?.failed || 0
          }
        }
        
        console.log('简化函数返回数据:', simpleData);
        return {
          success: simpleData?.success || 0,
          failed: simpleData?.failed || 0
        }
      }

      console.log('超安全函数返回数据:', data);

      return {
        success: data?.success || 0,
        failed: data?.failed || 0
      }
    } catch (error) {
      console.error('批量添加学生详细错误:', error);
      
      // 最后的Fallback: 使用直接的数据库插入
      try {
        let successCount = 0;
        let failedCount = 0;
        
        for (const studentId of studentIds) {
          try {
            const { error: insertError } = await supabase
              .from('teacher_students')
              .insert({
                teacher_id: teacherId,
                student_id: studentId,
                created_by: teacherId
              });
            
            if (insertError) {
              console.error(`学生 ${studentId} 插入失败:`, insertError);
              failedCount++;
            } else {
              successCount++;
            }
          } catch (e) {
            console.error(`学生 ${studentId} 处理异常:`, e);
            failedCount++;
          }
        }
        
        return {
          success: successCount,
          failed: failedCount
        };
      } catch (fallbackError) {
        console.error('Fallback也失败了:', fallbackError);
        throw new Error(`批量添加学生失败: ${error instanceof Error ? error.message : '未知错误'}`);
      }
    }
  }

  // 获取教师当前管理的学生列表
  static async getTeacherStudents(teacherId: string, params?: {
    keyword?: string
    page?: number
    limit?: number
  }): Promise<{ students: UserWithRole[], total: number }> {
    const {
      keyword = '',
      page = 1,
      limit = 20
    } = params || {}

    // 尝试多个函数版本
    let data, error;

    // 1. 尝试修正后的函数
    const result1 = await supabase
      .rpc('get_teacher_students_v2', {
        p_teacher_id: teacherId,
        p_keyword: keyword,
        p_page: page,
        p_limit: limit
      });
    
    if (!result1.error) {
      const result = result1.data?.[0];
      return {
        students: (result?.students || []) as UserWithRole[],
        total: result?.total_count || 0
      };
    }

    // 2. 尝试原函数
    const result2 = await supabase
      .rpc('get_teacher_students', {
        p_teacher_id: teacherId,
        p_keyword: keyword,
        p_page: page,
        p_limit: limit
      });

    if (!result2.error) {
      if (!result2.data || result2.data.length === 0) {
        return { students: [], total: 0 }
      }
      const result = result2.data[0]
      const students = (result.students || []) as UserWithRole[]

      // 获取总数（需要额外查询）
      const { count, error: countError } = await supabase
        .from('teacher_students')
        .select('*', { count: 'exact', head: true })
        .eq('teacher_id', teacherId)

      if (countError) {
        console.warn('获取总数失败:', countError.message)
      }

      return {
        students,
        total: count || 0
      }
    }

    throw new Error(`获取教师学生列表失败: ${result2.error?.message || '未知错误'}`)
  }

  // 移除教师的学生
  static async removeStudentFromTeacher(teacherId: string, studentId: string): Promise<boolean> {
    const { data, error } = await supabase
      .rpc('remove_student_from_teacher', {
        p_teacher_id: teacherId,
        p_student_id: studentId
      })

    if (error) {
      throw new Error(`移除学生失败: ${error.message}`)
    }

    return data || false
  }

  // 获取教师学生统计信息
  static async getTeacherStudentStats(teacherId: string) {
    const { data, error } = await supabase
      .from('teacher_student_stats')
      .select('*')
      .eq('teacher_id', teacherId)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        // 没有找到记录，返回默认值
        return {
          teacher_id: teacherId,
          student_count: 0,
          last_add_date: null
        }
      }
      throw new Error(`获取教师学生统计失败: ${error.message}`)
    }

    return data
  }
}

export default UserService