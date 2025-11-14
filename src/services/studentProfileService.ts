import { supabase } from '../lib/supabase'
import {
  StudentProfile,
  ClassInfo,
  SystemSetting,
  StudentCompleteInfo,
  StudentProfileFormData,
  StudentSearchParams,
  StudentListResponse
} from '../types/user'

export class StudentProfileService {
  // 获取学生个人信息
  static async getStudentProfile(userId: string): Promise<StudentProfile | null> {
    const { data, error } = await supabase
      .from('student_profiles')
      .select('*')
      .eq('user_id', userId)
      .single()
    
    if (error) {
      if (error.code === 'PGRST116') {
        // 记录不存在，返回null
        return null
      }
      throw error
    }
    
    return data
  }

  // 获取学生完整信息
  static async getStudentCompleteInfo(userId: string): Promise<StudentCompleteInfo | null> {
    const { data, error } = await supabase
      .from('student_complete_info')
      .select('*')
      .eq('user_id', userId)
      .single()
    
    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      throw error
    }
    
    return data
  }

  // 初始化学生个人信息
  static async initializeStudentProfile(userId: string): Promise<StudentProfile> {
    const { data, error } = await supabase
      .rpc('initialize_student_profile', { p_user_id: userId })
    
    if (error) throw error
    
    // 返回新创建的profile
    return this.getStudentProfile(userId) as Promise<StudentProfile>
  }

  // 提交学生个人信息
  static async submitStudentProfile(
    profileId: string,
    profileData: StudentProfileFormData
  ): Promise<boolean> {
    const { error } = await supabase
      .rpc('submit_student_profile', {
        p_profile_id: profileId,
        p_profile_data: profileData,
        p_edit_reason: profileData.edit_reason
      })
    
    if (error) throw error
    
    return true
  }

  // 更新学生个人信息（直接更新，不经过审核）
  static async updateStudentProfile(
    profileId: string,
    profileData: Partial<StudentProfile>
  ): Promise<StudentProfile> {
    const { data, error } = await supabase
      .from('student_profiles')
      .update({
        ...profileData,
        updated_at: new Date().toISOString(),
        edit_count: supabase.rpc('coalesce', { expr1: supabase.sql`edit_count + 1`, expr2: 1 })
      })
      .eq('id', profileId)
      .select()
      .single()
    
    if (error) throw error
    
    return data
  }

  // 创建或更新学生个人信息
  static async createOrUpdateStudentProfile(
    userId: string,
    profileData: StudentProfileFormData
  ): Promise<StudentProfile> {
    // 检查是否已有个人信息
    let existingProfile = await this.getStudentProfile(userId)
    
    if (!existingProfile) {
      // 如果没有个人信息，先初始化
      const profileId = await this.initializeStudentProfile(userId)
      existingProfile = await this.getStudentProfile(userId) as StudentProfile
    }
    
    // 直接更新个人信息（用于直接可修改的字段）
    const updatedProfile = await this.updateStudentProfile(existingProfile.id, {
      gender: profileData.gender,
      birth_date: profileData.birth_date,
      id_card: profileData.id_card,
      nationality: profileData.nationality,
      political_status: profileData.political_status,
      phone: profileData.phone,
      emergency_contact: profileData.emergency_contact,
      emergency_phone: profileData.emergency_phone,
      home_address: profileData.home_address,
      admission_date: profileData.admission_date,
      graduation_date: profileData.graduation_date,
      student_type: profileData.student_type,
      profile_status: 'pending'
    })
    
    return updatedProfile
  }

  // 审核学生个人信息
  static async reviewStudentProfile(
    profileId: string,
    reviewResult: 'approved' | 'rejected',
    reviewNotes?: string,
    reviewedBy?: string // 添加可选参数，允许传入审核人ID
  ): Promise<boolean> {
    let reviewerId = reviewedBy
    
    // 如果没有传入审核人ID，尝试从本地存储获取
    if (!reviewerId) {
      const userInfo = localStorage.getItem('user_info')
      if (userInfo) {
        try {
          const user = JSON.parse(userInfo)
          reviewerId = user.id
        } catch (error) {
          console.error('解析用户信息失败:', error)
        }
      }
    }
    
    if (!reviewerId) {
      throw new Error('无法获取审核人信息，请重新登录')
    }
    
    const { error } = await supabase
      .rpc('review_student_profile', {
        p_profile_id: profileId,
        p_review_result: reviewResult,
        p_review_notes: reviewNotes,
        p_reviewed_by: reviewerId
      })
    
    if (error) throw error
    
    return true
  }

  // 获取所有班级列表
  static async getClasses(): Promise<ClassInfo[]> {
    const { data, error } = await supabase
      .from('classes')
      .select('*')
      .order('grade')
      .order('class_name')
    
    if (error) throw error
    
    return data || []
  }

  // 获取系统设置
  static async getSystemSettings(): Promise<SystemSetting[]> {
    const { data, error } = await supabase
      .from('system_settings')
      .select('*')
    
    if (error) throw error
    
    return data || []
  }

  // 获取个人信息维护功能开关状态
  static async isProfileEditEnabled(): Promise<boolean> {
    const { data, error } = await supabase
      .from('system_settings')
      .select('setting_value')
      .eq('setting_key', 'student_profile_edit_enabled')
      .single()
    
    if (error) {
      console.error('获取系统设置失败:', error)
      return false
    }
    
    return data?.setting_value === 'true'
  }

  // 更新系统设置
  static async updateSystemSetting(
    settingKey: string,
    settingValue: string
  ): Promise<boolean> {
    const { error } = await supabase
      .from('system_settings')
      .update({ setting_value: settingValue, updated_at: new Date().toISOString() })
      .eq('setting_key', settingKey)
    
    if (error) throw error
    
    return true
  }

  // 搜索学生列表（教师和管理员使用）
  static async searchStudents(params: StudentSearchParams): Promise<StudentListResponse> {
    let query = supabase
      .from('student_complete_info')
      .select('*', { count: 'exact' })
    
    // 添加搜索条件
    if (params.keyword) {
      query = query.or(`full_name.ilike.%${params.keyword}%,user_number.ilike.%${params.keyword}%,username.ilike.%${params.keyword}%`)
    }
    
    if (params.class_id) {
      query = query.eq('class_id', params.class_id)
    }
    
    if (params.grade) {
      query = query.eq('grade', params.grade)
    }
    
    if (params.department) {
      query = query.eq('department', params.department)
    }
    
    if (params.profile_status) {
      query = query.eq('profile_status', params.profile_status)
    }
    
    // 分页
    const page = params.page || 1
    const limit = params.limit || 20
    const from = (page - 1) * limit
    const to = from + limit - 1
    
    query = query.range(from, to).order('created_at', { ascending: false })
    
    const { data, error, count } = await query
    
    if (error) throw error
    
    return {
      students: data || [],
      total: count || 0,
      page,
      limit,
      total_pages: Math.ceil((count || 0) / limit)
    }
  }

  // 批量审核学生信息
  static async batchReviewProfiles(
    profileIds: string[],
    reviewResult: 'approved' | 'rejected',
    reviewNotes?: string,
    reviewedBy?: string // 添加可选参数，允许传入审核人ID
  ): Promise<boolean> {
    let reviewerId = reviewedBy
    
    // 如果没有传入审核人ID，尝试从本地存储获取
    if (!reviewerId) {
      const userInfo = localStorage.getItem('user_info')
      if (userInfo) {
        try {
          const user = JSON.parse(userInfo)
          reviewerId = user.id
        } catch (error) {
          console.error('解析用户信息失败:', error)
        }
      }
    }
    
    if (!reviewerId) {
      throw new Error('无法获取审核人信息，请重新登录')
    }
    
    // 逐个审核
    for (const profileId of profileIds) {
      try {
        await this.reviewStudentProfile(profileId, reviewResult, reviewNotes, reviewerId)
      } catch (error) {
        console.error(`审核学生信息失败 (${profileId}):`, error)
        throw error
      }
    }
    
    return true
  }

  // 获取学生个人信息修改记录
  static async getProfileEditLogs(profileId: string): Promise<any[]> {
    const { data, error } = await supabase
      .from('profile_edit_logs')
      .select('*')
      .eq('student_profile_id', profileId)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    
    return data || []
  }

  // 检查新登录学生是否需要完善个人信息
  static async checkProfileCompletion(userId: string): Promise<{
    needsCompletion: boolean
    profile?: StudentProfile
    isEditEnabled: boolean
  }> {
    const [profile, isEditEnabled] = await Promise.all([
      this.getStudentProfile(userId),
      this.isProfileEditEnabled()
    ])
    
    const needsCompletion = !profile || 
                           profile.profile_status === 'incomplete' || 
                           profile.profile_status === 'rejected'
    
    return {
      needsCompletion,
      profile: profile || undefined,
      isEditEnabled
    }
  }
}

export default StudentProfileService