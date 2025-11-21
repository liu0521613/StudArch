// 诊断导入问题脚本
// 使用方法：在浏览器控制台运行，或修改supabase配置后用Node.js运行

console.log('🔍 开始诊断学生导入显示问题...\n');

// 1. 检查localStorage中的导入数据
function checkLocalStorage() {
  console.log('=== 检查 localStorage ===');
  
  const importedIds = localStorage.getItem('importedStudentIds');
  console.log('导入的学生ID:', importedIds);
  
  if (importedIds) {
    try {
      const parsedIds = JSON.parse(importedIds);
      console.log('解析后的ID数组:', parsedIds);
      console.log('导入数量:', parsedIds.length);
    } catch (e) {
      console.error('解析导入ID失败:', e);
    }
  } else {
    console.log('❌ localStorage中没有导入的学生的ID');
  }
}

// 2. 检查当前页面的学生数据
function checkCurrentStudents() {
  console.log('\n=== 检查当前页面学生数据 ===');
  
  // 查找React组件中的学生数据
  const reactRoot = document.getElementById('root');
  if (reactRoot) {
    const studentRows = document.querySelectorAll('table tbody tr');
    console.log('页面显示的学生行数:', studentRows.length);
    
    studentRows.forEach((row, index) => {
      const cells = row.querySelectorAll('td');
      if (cells.length >= 3) {
        const studentNumber = cells[1]?.textContent;
        const studentName = cells[2]?.textContent;
        console.log(`  ${index + 1}. 学号: ${studentNumber}, 姓名: ${studentName}`);
      }
    });
  }
}

// 3. 模拟API调用检查数据库
async function checkDatabaseData() {
  console.log('\n=== 检查数据库数据 ===');
  
  // 这里需要您配置正确的supabase URL和key
  const supabaseUrl = 'https://your-project.supabase.co'; // 替换为实际URL
  const supabaseKey = 'your-anon-key'; // 替换为实际key
  
  if (supabaseUrl === 'https://your-project.supabase.co') {
    console.log('⚠️  请先配置正确的 Supabase URL 和 Key');
    return;
  }
  
  try {
    // 动态加载supabase客户端
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
    document.head.appendChild(script);
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const { createClient } = window.supabase;
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // 检查teacher_students表数据
    const { data: teacherStudents, error: tsError } = await supabase
      .from('teacher_students')
      .select('*');
    
    if (tsError) {
      console.error('查询teacher_students失败:', tsError);
    } else {
      console.log('✅ teacher_students记录数:', teacherStudents.length);
      teacherStudents.slice(0, 3).forEach(record => {
        console.log(`  - 教师: ${record.teacher_id}, 学生: ${record.student_id}`);
      });
    }
    
    // 检查用户表中的学生
    const { data: students, error: studentsError } = await supabase
      .from('users')
      .select('id, user_number, full_name, role_id, status')
      .eq('role_id', '3')
      .eq('status', 'active')
      .limit(10);
    
    if (studentsError) {
      console.error('查询学生用户失败:', studentsError);
    } else {
      console.log('✅ 活跃学生数量:', students.length);
      students.forEach(student => {
        console.log(`  - ID: ${student.id}, 学号: ${student.user_number}, 姓名: ${student.full_name}`);
      });
    }
    
  } catch (error) {
    console.error('数据库检查失败:', error);
  }
}

// 4. 检查导入流程
function checkImportProcess() {
  console.log('\n=== 检查导入流程 ===');
  
  // 检查导入按钮
  const importButton = document.querySelector('button[onclick*="Import"]');
  console.log('导入按钮存在:', !!importButton);
  
  // 检查相关事件监听器
  console.log('建议检查以下方面:');
  console.log('1. 导入成功后是否正确调用了 fetchTeacherStudents()');
  console.log('2. 教师ID是否正确传递');
  console.log('3. 数据库插入操作是否成功');
  console.log('4. 查询过滤条件是否正确');
}

// 5. 生成修复建议
function generateFixSuggestions() {
  console.log('\n=== 修复建议 ===');
  
  console.log('1. 🔄 强制刷新学生列表:');
  console.log('   - 在导入成功后，确保调用 fetchTeacherStudents()');
  console.log('   - 添加 setTimeout 确保数据库操作完成');
  
  console.log('\n2. 🗄️  检查数据库函数:');
  console.log('   - 确认 get_teacher_students 函数存在');
  console.log('   - 检查 RLS 策略是否正确');
  
  console.log('\n3. 🔍 调试数据流:');
  console.log('   - 在 handleConfirmImport 中添加更多日志');
  console.log('   - 检查返回的数据格式');
  
  console.log('\n4. 🧪 测试数据库连接:');
  console.log('   - 使用开发者工具检查网络请求');
  console.log('   - 确认 Supabase 配置正确');
}

// 运行诊断
async function runDiagnosis() {
  checkLocalStorage();
  checkCurrentStudents();
  checkImportProcess();
  generateFixSuggestions();
  
  // 可选的数据库检查（需要配置）
  console.log('\n如需检查数据库，请先配置 supabaseUrl 和 supabaseKey');
  console.log('然后取消注释下面的行:');
  // await checkDatabaseData();
}

// 立即运行诊断
runDiagnosis();

// 导出函数供手动调用
window.diagnoseImportIssue = {
  checkLocalStorage,
  checkCurrentStudents,
  checkDatabaseData,
  checkImportProcess,
  runDiagnosis
};

console.log('\n✨ 诊断完成！如需手动调用特定检查，请使用 window.diagnoseImportIssue');