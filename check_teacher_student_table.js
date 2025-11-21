const { createClient } = require('@supabase/supabase-js');

// 替换为你的Supabase配置
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseKey = 'your-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTeacherStudentTable() {
  try {
    console.log('=== 检查 teacher_students 表 ===');
    
    // 1. 检查表是否存在
    const { data: tables, error: tableError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .eq('table_name', 'teacher_students');
    
    if (tableError) {
      console.error('检查表是否存在失败:', tableError);
      return;
    }
    
    if (!tables || tables.length === 0) {
      console.log('❌ teacher_students 表不存在');
      return;
    }
    
    console.log('✅ teacher_students 表存在');
    
    // 2. 检查表结构
    const { data: columns, error: columnError } = await supabase
      .from('information_schema.columns')
      .select('column_name, data_type')
      .eq('table_schema', 'public')
      .eq('table_name', 'teacher_students')
      .order('ordinal_position');
    
    if (columnError) {
      console.error('检查表结构失败:', columnError);
      return;
    }
    
    console.log('\n📋 表结构:');
    columns.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type}`);
    });
    
    // 3. 检查数据
    const { data: records, error: dataError } = await supabase
      .from('teacher_students')
      .select('*');
    
    if (dataError) {
      console.error('查询数据失败:', dataError);
      return;
    }
    
    console.log(`\n📊 数据记录数: ${records.length}`);
    if (records.length > 0) {
      console.log('数据示例:');
      records.slice(0, 3).forEach(record => {
        console.log(`  教师ID: ${record.teacher_id}, 学生ID: ${record.student_id}, 创建时间: ${record.created_at}`);
      });
    }
    
    // 4. 检查RLS策略
    const { data: policies, error: policyError } = await supabase
      .from('pg_policies')
      .select('policyname, permissive, roles, cmd, qual')
      .eq('tablename', 'teacher_students');
    
    if (policyError) {
      console.log('\n⚠️  无法检查RLS策略 (可能是权限问题)');
    } else {
      console.log('\n🔐 RLS策略:');
      if (policies && policies.length > 0) {
        policies.forEach(policy => {
          console.log(`  - ${policy.policyname}: ${policy.cmd}`);
        });
      } else {
        console.log('  未找到RLS策略');
      }
    }
    
    // 5. 测试函数调用
    console.log('\n🧪 测试相关函数:');
    
    const testTeacherId = '00000000-0000-0000-0000-000000000001';
    
    try {
      const { data: funcResult, error: funcError } = await supabase
        .rpc('get_teacher_students', {
          p_teacher_id: testTeacherId,
          p_keyword: '',
          p_page: 1,
          p_limit: 10
        });
      
      if (funcError) {
        console.log(`  ❌ get_teacher_students 失败: ${funcError.message}`);
      } else {
        console.log(`  ✅ get_teacher_students 成功，返回 ${funcResult.length} 条记录`);
      }
    } catch (e) {
      console.log(`  ❌ get_teacher_students 异常: ${e.message}`);
    }
    
    try {
      const { data: authResult, error: authError } = await supabase
        .rpc('get_authorized_students', {
          p_keyword: '',
          p_grade: '',
          p_department: '',
          p_page: 1,
          p_limit: 10
        });
      
      if (authError) {
        console.log(`  ❌ get_authorized_students 失败: ${authError.message}`);
      } else {
        console.log(`  ✅ get_authorized_students 成功，返回 ${authResult.length} 条记录`);
      }
    } catch (e) {
      console.log(`  ❌ get_authorized_students 异常: ${e.message}`);
    }
    
  } catch (error) {
    console.error('检查过程出错:', error);
  }
}

// 检查用户表中的学生数据
async function checkUsersTable() {
  try {
    console.log('\n=== 检查 users 表中的学生数据 ===');
    
    const { data: students, error: studentsError } = await supabase
      .from('users')
      .select('id, username, user_number, full_name, role_id, status')
      .eq('role_id', '3')
      .eq('status', 'active')
      .limit(5);
    
    if (studentsError) {
      console.error('查询学生数据失败:', studentsError);
      return;
    }
    
    console.log(`✅ 找到 ${students.length} 个活跃学生:`);
    students.forEach(student => {
      console.log(`  - ID: ${student.id}, 学号: ${student.user_number}, 姓名: ${student.full_name}`);
    });
    
  } catch (error) {
    console.error('检查用户表失败:', error);
  }
}

// 主函数
async function main() {
  console.log('🔍 开始检查数据库结构和数据...\n');
  
  await checkTeacherStudentTable();
  await checkUsersTable();
  
  console.log('\n✨ 检查完成');
}

// 运行检查
main().catch(console.error);