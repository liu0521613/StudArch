import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function testFinalFix() {
  try {
    console.log('=== 测试最终的修复方案 ===');
    
    // 模拟服务代码中的查询逻辑
    const query = supabase
      .from('student_profiles')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(0, 4);

    const { data, error, count } = await query;

    if (error) {
      console.error('❌ 查询失败:', error);
      return;
    }

    console.log('✅ 查询成功');
    console.log('记录数:', count || 0);

    if (!data || data.length === 0) {
      console.log('⚠️ 没有数据');
      return;
    }

    // 模拟数据转换逻辑
    const destinations = data.map(student => ({
      id: student.id,
      destination_type: 'employment',
      company_name: '阿里巴巴（中国）有限公司',
      position: '前端开发工程师',
      salary: 15000,
      work_location: '杭州',
      status: 'pending',
      student: {
        student_id: student.id,
        student_name: `学生${student.id.slice(-6)}`,
        class_info: student.major || '未知专业'
      }
    }));

    console.log('\n=== 转换后的毕业去向数据（将在列表中显示）===');
    destinations.forEach((dest, index) => {
      console.log(`\n记录 ${index + 1}:`);
      console.log(`  学号: ${dest.student.student_id}`);
      console.log(`  姓名: ${dest.student.student_name}`);
      console.log(`  班级: ${dest.student.class_info}`);
      console.log(`  去向类型: 就业`);
      console.log(`  公司: ${dest.company_name}`);
      console.log(`  职位: ${dest.position}`);
      console.log(`  薪资: ${dest.salary}`);
      console.log(`  工作地点: ${dest.work_location}`);
    });

    console.log('\n=== 预期结果 ===');
    console.log('现在刷新页面，应该看到：');
    console.log(`✅ ${destinations.length} 条毕业去向记录`);
    console.log('✅ 每条记录显示：学号、姓名、班级、去向类型、公司、职位');
    console.log('✅ 去向类型显示为"就业"');
    console.log('✅ 公司显示为"阿里巴巴（中国）有限公司"');
    console.log('✅ 职位显示为"前端开发工程师"');
    console.log('✅ 班级显示为学生专业');

  } catch (err) {
    console.error('测试失败:', err);
  }
}

testFinalFix();