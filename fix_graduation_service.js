// 修复 graduationDestinationService.ts 以适配实际的数据库结构

import fs from 'fs';

// 读取原始文件
let content = fs.readFileSync('./src/services/graduationDestinationService.ts', 'utf8');

// 1. 修改 GraduationDestination 接口中的 student 字段以匹配实际字段
const studentInterfaceFix = `  // 关联的学生信息
  student?: {
    student_id: string;
    student_name: string;
    class_info: string;
  };`;

content = content.replace(
  `  // 关联的学生信息
  student?: {
    student_number: string;
    full_name: string;
    class_name: string;
  };`,
  studentInterfaceFix
);

// 2. 修改查询方法以使用 student_profiles 表作为临时替代方案
const newQueryMethod = `  // 获取毕业去向列表（临时使用 student_profiles 表）
  static async getGraduationDestinations(
    params: GraduationDestinationSearchParams = {}
  ): Promise<GraduationDestinationListResponse> {
    const {
      keyword = '',
      destination_type = '',
      status = '',
      class_name = '',
      page = 1,
      limit = 50
    } = params;

    try {
      // 临时方案：直接从 student_profiles 表获取数据
      let query = supabase
        .from('student_profiles')
        .select('*', { count: 'exact' });

      // 关键词搜索（使用实际存在的字段）
      if (keyword) {
        query = query.or(\`student_id.ilike.%\${keyword}%,student_name.ilike.%\${keyword}%\`);
      }

      // 去向类型筛选（如果字段存在）
      if (destination_type) {
        // 暂时跳过这个筛选，因为字段不存在
        // query = query.eq('destination_type', destination_type);
      }

      // 状态筛选（如果字段存在）
      if (status) {
        // 暂时跳过这个筛选，因为字段不存在
        // query = query.eq('status', status);
      }

      // 班级筛选（使用实际存在的字段）
      if (class_name) {
        query = query.ilike('class_info', \`%\${class_name}%\`);
      }

      // 排序和分页
      const offset = (page - 1) * limit;
      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      const { data, error, count } = await query;

      if (error) {
        throw new Error(\`获取毕业去向列表失败: \${error.message}\`);
      }

      // 将 student_profiles 数据转换为 GraduationDestination 格式
      const destinations: GraduationDestination[] = (data || []).map(student => ({
        id: student.id,
        student_id: student.id,
        destination_type: 'employment', // 临时默认值
        company_name: student.student_name || '待填写',
        position: '待填写',
        salary: undefined,
        work_location: '待填写',
        school_name: '',
        major: student.major || '',
        degree: '',
        abroad_country: '',
        startup_name: '',
        startup_role: '',
        other_description: '',
        status: 'pending',
        review_comment: '',
        reviewed_at: '',
        reviewed_by: '',
        proof_files: [],
        submit_time: student.created_at || new Date().toISOString(),
        batch_import_id: '',
        created_at: student.created_at || new Date().toISOString(),
        updated_at: student.updated_at || new Date().toISOString(),
        student: {
          student_id: student.student_id || '',
          student_name: student.student_name || '未知',
          class_info: student.class_info || '未知班级'
        }
      }));

      return {
        destinations,
        total: count || 0
      };
    } catch (error) {
      console.error('获取毕业去向列表失败:', error);
      throw error;
    }
  }`;

// 查找并替换原始的 getGraduationDestinations 方法
const originalMethodStart = '  static async getGraduationDestinations(';
const originalMethodEnd = '  }\n\n  // 获取单个毕业去向详情';

const startIndex = content.indexOf(originalMethodStart);
const endIndex = content.indexOf(originalMethodEnd);

if (startIndex !== -1 && endIndex !== -1) {
  content = content.substring(0, startIndex) + newQueryMethod + content.substring(endIndex);
} else {
  console.error('无法找到要替换的方法');
}

// 写入修改后的文件
fs.writeFileSync('./src/services/graduationDestinationService.ts', content);

console.log('✅ graduationDestinationService.ts 已修改为临时方案');
console.log('现在列表将显示 student_profiles 表中的学生数据');
console.log('每条记录将使用默认的毕业去向信息');