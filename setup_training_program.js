// 培养方案数据库设置脚本
// 用于创建培养方案相关的数据库表和函数

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 加载环境变量
import dotenv from 'dotenv';
dotenv.config();

// Supabase配置
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 请确保在.env文件中设置了VITE_SUPABASE_URL和VITE_SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// 读取SQL文件
function readSQLFile(filename) {
  try {
    const filePath = path.join(__dirname, filename);
    if (!fs.existsSync(filePath)) {
      throw new Error(`文件不存在: ${filename}`);
    }
    return fs.readFileSync(filePath, 'utf8');
  } catch (error) {
    console.error(`❌ 读取SQL文件失败 ${filename}:`, error.message);
    throw error;
  }
}

// 执行SQL
async function executeSQL(sql, description) {
  try {
    console.log(`\n🔄 ${description}...`);
    
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });
    
    if (error) {
      // 如果exec_sql不存在，尝试直接执行
      console.log(`⚠️  exec_sql函数不可用，尝试直接执行SQL...`);
      
      // 这里可以添加其他执行方式
      console.log(`⚠️  跳过执行，请手动运行SQL文件: ${description}`);
      return { success: false, error: error.message };
    }
    
    console.log(`✅ ${description} - 完成`);
    return { success: true, data };
    
  } catch (error) {
    console.error(`❌ ${description} - 失败:`, error.message);
    return { success: false, error: error.message };
  }
}

// 主设置函数
async function setupTrainingProgramDatabase() {
  console.log('🚀 开始设置培养方案数据库...\n');
  
  try {
    // 1. 创建数据库表
    const tableSQL = readSQLFile('create_training_program_tables.sql');
    await executeSQL(tableSQL, '创建培养方案数据库表');
    
    // 2. 创建API函数
    const functionSQL = readSQLFile('training_program_api_functions.sql');
    await executeSQL(functionSQL, '创建培养方案API函数');
    
    // 3. 验证创建结果
    console.log('\n🔍 验证数据库表...');
    
    const tables = ['training_programs', 'training_program_courses', 'training_program_import_batches', 'student_training_programs', 'student_course_progress'];
    
    for (const tableName of tables) {
      try {
        const { data, error } = await supabase
          .from(tableName)
          .select('count', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ 表 ${tableName}: ${error.message}`);
        } else {
          console.log(`✅ 表 ${tableName}: ${data.count} 条记录`);
        }
      } catch (err) {
        console.log(`❌ 表 ${tableName}: 检查失败`);
      }
    }
    
    console.log('\n📋 设置说明:');
    console.log('1. 如果上述表创建失败，请手动执行以下SQL文件:');
    console.log('   - create_training_program_tables.sql');
    console.log('   - training_program_api_functions.sql');
    console.log('');
    console.log('2. 在Supabase控制台中，确保:');
    console.log('   - RLS (Row Level Security) 已禁用');
    console.log('   - 所有必要的权限已设置');
    console.log('');
    console.log('3. 启动API服务器:');
    console.log('   npm run api');
    console.log('');
    console.log('4. 启动前端开发服务器:');
    console.log('   npm run dev');
    console.log('');
    console.log('5. 或者同时启动两个服务器:');
    console.log('   npm run start:full');
    
    console.log('\n🎉 培养方案数据库设置完成!');
    
  } catch (error) {
    console.error('\n❌ 设置过程中发生错误:', error.message);
    console.log('\n请手动执行SQL文件来创建必要的表和函数');
  }
}

// 创建测试数据的函数
async function createTestData() {
  console.log('\n🧪 创建测试数据...');
  
  try {
    // 获取默认培养方案
    const { data: programs, error: programError } = await supabase
      .from('training_programs')
      .select('*')
      .eq('program_code', 'CS_2021')
      .single();
    
    if (programError || !programs) {
      console.log('❌ 未找到默认培养方案，请先运行设置脚本');
      return;
    }
    
    // 创建测试课程
    const testCourses = [
      {
        program_id: programs.id,
        course_number: 'CS101',
        course_name: '计算机基础',
        credits: 3,
        recommended_grade: '大一',
        semester: '第一学期',
        exam_method: '笔试',
        course_nature: '必修课',
        course_type: 'required',
        sequence_order: 1,
        status: 'active'
      },
      {
        program_id: programs.id,
        course_number: 'CS102',
        course_name: '程序设计基础',
        credits: 4,
        recommended_grade: '大一',
        semester: '第一学期',
        exam_method: '上机考试',
        course_nature: '必修课',
        course_type: 'required',
        sequence_order: 2,
        status: 'active'
      },
      {
        program_id: programs.id,
        course_number: 'MATH101',
        course_name: '高等数学',
        credits: 4,
        recommended_grade: '大一',
        semester: '第一学期',
        exam_method: '笔试',
        course_nature: '必修课',
        course_type: 'required',
        sequence_order: 3,
        status: 'active'
      }
    ];
    
    const { data, error } = await supabase
      .from('training_program_courses')
      .upsert(testCourses, { onConflict: 'program_id,course_number' })
      .select();
    
    if (error) {
      console.error('❌ 创建测试课程失败:', error.message);
    } else {
      console.log(`✅ 成功创建 ${testCourses.length} 门测试课程`);
      
      // 显示创建的课程
      data.forEach(course => {
        console.log(`   - ${course.course_number}: ${course.course_name} (${course.credits}学分)`);
      });
    }
    
  } catch (error) {
    console.error('❌ 创建测试数据失败:', error.message);
  }
}

// 运行设置
if (process.argv.includes('--test-data')) {
  await setupTrainingProgramDatabase();
  await createTestData();
} else {
  await setupTrainingProgramDatabase();
}