// 简化的测试脚本 - 只测试核心功能
console.log('🧪 开始简单测试...\n');

// 修改这里配置您的Supabase信息
const supabaseUrl = 'https://your-project.supabase.co'; // 替换为实际URL
const supabaseKey = 'your-anon-key'; // 替换为实际key

async function quickTest() {
  if (supabaseUrl === 'https://your-project.supabase.co') {
    console.log('⚠️  请先修改 supabaseUrl 和 supabaseKey');
    return;
  }

  try {
    // 加载Supabase
    if (!window.supabase) {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
      document.head.appendChild(script);
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    const { createClient } = window.supabase;
    const supabase = createClient(supabaseUrl, supabaseKey);

    console.log('1. 测试获取授权学生...');
    const { data: students, error: studentsError } = await supabase
      .rpc('get_authorized_students', {
        p_keyword: '',
        p_grade: '',
        p_department: '',
        p_page: 1,
        p_limit: 3
      });

    if (studentsError) {
      console.error('❌ 获取授权学生失败:', studentsError.message);
    } else {
      console.log('✅ 获取授权学生成功');
      const result = students?.[0];
      if (result) {
        console.log(`   找到 ${result.total_count} 个学生，显示前 ${result.students?.length || 0} 个`);
      }
    }

    console.log('\n2. 测试获取教师学生...');
    const testTeacherId = '00000000-0000-0000-0000-000000000001';
    const { data: teacherStudents, error: teacherError } = await supabase
      .rpc('get_teacher_students', {
        p_teacher_id: testTeacherId,
        p_keyword: '',
        p_page: 1,
        p_limit: 10
      });

    if (teacherError) {
      console.error('❌ 获取教师学生失败:', teacherError.message);
    } else {
      console.log('✅ 获取教师学生成功');
      const result = teacherStudents?.[0];
      if (result) {
        console.log(`   教师管理 ${result.total_count} 个学生，当前显示 ${result.students?.length || 0} 个`);
      }
    }

    console.log('\n✨ 测试完成！');
    console.log('\n如果两个测试都显示 ✅，说明数据库函数工作正常');
    console.log('您现在可以测试前端的批量导入功能了');

  } catch (error) {
    console.error('测试出错:', error);
  }
}

// 运行测试
quickTest();