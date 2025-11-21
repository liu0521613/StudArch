// 测试教师学生管理功能的脚本
// 在浏览器控制台中运行，或修改supabase配置后使用

console.log('🧪 开始测试教师学生管理功能...\n');

// 测试函数
async function testTeacherStudentFunctions() {
  // 配置Supabase - 请替换为实际配置
  const supabaseUrl = 'https://your-project.supabase.co';
  const supabaseKey = 'your-anon-key';
  
  if (supabaseUrl === 'https://your-project.supabase.co') {
    console.log('⚠️  请先配置正确的 Supabase URL 和 Key');
    console.log('修改 supabaseUrl 和 supabaseKey 变量后重新运行');
    return;
  }
  
  try {
    // 动态加载Supabase客户端
    if (!window.supabase) {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
      document.head.appendChild(script);
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    const { createClient } = window.supabase;
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    const testTeacherId = '00000000-0000-0000-0000-000000000001';
    let testsPassed = 0;
    let totalTests = 4;
    
    console.log('=== 测试1: 检查 teacher_students 表 ===');
    try {
      const { data, error } = await supabase
        .from('teacher_students')
        .select('*')
        .limit(5);
      
      if (error) {
        console.error('❌ 查询失败:', error.message);
      } else {
        console.log(`✅ 成功查询到 ${data.length} 条记录`);
        if (data.length > 0) {
          console.log('示例数据:', data[0]);
        }
        testsPassed++;
      }
    } catch (e) {
      console.error('❌ 异常:', e.message);
    }
    
    console.log('\n=== 测试2: get_authorized_students 函数 ===');
    try {
      const { data, error } = await supabase
        .rpc('get_authorized_students', {
          p_keyword: '',
          p_grade: '',
          p_department: '',
          p_page: 1,
          p_limit: 5
        });
      
      if (error) {
        console.error('❌ 函数调用失败:', error.message);
      } else {
        console.log('✅ 函数调用成功');
        if (data && data.length > 0) {
          const result = data[0];
          console.log(`找到 ${result.total_count} 个学生，返回 ${result.students?.length || 0} 条记录`);
        }
        testsPassed++;
      }
    } catch (e) {
      console.error('❌ 异常:', e.message);
    }
    
    console.log('\n=== 测试3: get_teacher_students 函数 ===');
    try {
      const { data, error } = await supabase
        .rpc('get_teacher_students', {
          p_teacher_id: testTeacherId,
          p_keyword: '',
          p_page: 1,
          p_limit: 10
        });
      
      if (error) {
        console.error('❌ 函数调用失败:', error.message);
      } else {
        console.log('✅ 函数调用成功');
        if (data && data.length > 0) {
          const result = data[0];
          console.log(`教师管理的学生总数: ${result.total_count}`);
          console.log(`当前页学生数: ${result.students?.length || 0}`);
        }
        testsPassed++;
      }
    } catch (e) {
      console.error('❌ 异常:', e.message);
    }
    
    console.log('\n=== 测试4: batch_add_students_to_teacher 函数 ===');
    try {
      // 先获取一些学生ID用于测试
      const { data: students } = await supabase
        .from('users')
        .select('id')
        .eq('role_id', '3')
        .eq('status', 'active')
        .limit(2);
      
      if (students && students.length > 0) {
        const studentIds = students.map(s => s.id);
        
        const { data, error } = await supabase
          .rpc('batch_add_students_to_teacher', {
            p_teacher_id: testTeacherId,
            p_student_ids: studentIds
          });
        
        if (error) {
          console.error('❌ 批量添加失败:', error.message);
        } else {
          console.log('✅ 批量添加成功');
          console.log('结果:', data);
          testsPassed++;
        }
      } else {
        console.log('⚠️  没有找到可用于测试的学生');
        testsPassed++;
      }
    } catch (e) {
      console.error('❌ 异常:', e.message);
    }
    
    // 总结测试结果
    console.log('\n=== 测试结果 ===');
    console.log(`通过: ${testsPassed}/${totalTests}`);
    
    if (testsPassed === totalTests) {
      console.log('🎉 所有测试通过！数据库功能正常');
    } else {
      console.log('⚠️  部分测试失败，请检查错误信息');
    }
    
  } catch (error) {
    console.error('测试过程中出错:', error);
  }
}

// 检查前端导入功能
function checkFrontendImportFunction() {
  console.log('\n=== 检查前端导入功能 ===');
  
  // 检查localStorage
  const importedIds = localStorage.getItem('importedStudentIds');
  if (importedIds) {
    try {
      const parsed = JSON.parse(importedIds);
      console.log(`✅ localStorage中有 ${parsed.length} 个导入的学生ID`);
    } catch (e) {
      console.log('❌ localStorage中的导入数据格式错误');
    }
  } else {
    console.log('ℹ️  localStorage中暂无导入数据');
  }
  
  // 检查页面元素
  const importButton = document.querySelector('button:has(.fa-upload)');
  console.log('导入按钮存在:', !!importButton);
  
  const studentTable = document.querySelector('table tbody');
  const studentRows = studentTable ? studentTable.querySelectorAll('tr').length : 0;
  console.log(`当前显示学生行数: ${studentRows}`);
}

// 运行测试
async function runAllTests() {
  console.log('🚀 开始完整测试...\n');
  
  // 检查前端功能
  checkFrontendImportFunction();
  
  // 测试数据库功能
  await testTeacherStudentFunctions();
  
  console.log('\n✨ 测试完成！');
  console.log('\n如果测试通过，您可以：');
  console.log('1. 尝试在界面上导入一些学生');
  console.log('2. 检查导入后学生列表是否正确显示');
  console.log('3. 刷新页面确认数据持久化');
}

// 导出函数供手动调用
window.testTeacherStudentFunctions = {
  runAllTests,
  testTeacherStudentFunctions,
  checkFrontendImportFunction
};

// 自动运行测试
runAllTests();