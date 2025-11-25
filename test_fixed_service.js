import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function testFixedService() {
  try {
    console.log('=== 测试修改后的查询逻辑 ===');
    
    // 测试新的查询方法
    const query = supabase
      .from('student_profiles')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(0, 4);

    const { data, error, count } = await query;

    if (error) {
      console.error('❌ 查询失败:', error);
    } else {
      console.log('✅ 查询成功');
      console.log('记录数:', count || 0);
      
      if (data && data.length > 0) {
        console.log('\n=== 学生数据（将显示在列表中）===');
        data.forEach((student, index) => {
          console.log(`\n学生 ${index + 1}:`);
          console.log(`  学号: ${student.student_id || '无'}`);
          console.log(`  姓名: ${student.student_name || '无'}`);
          console.log(`  班级: ${student.class_info || '无'}`);
          console.log(`  专业: ${student.major || '无'}`);
          console.log(`  创建时间: ${student.created_at || '无'}`);
          
          // 模拟转换后的毕业去向数据
          const mockDestination = {
            id: student.id,
            destination_type: 'employment',
            company_name: '阿里巴巴（中国）有限公司',
            position: '前端开发工程师',
            salary: 15000,
            work_location: '杭州',
            status: 'pending',
            student: {
              student_id: student.student_id || '',
              student_name: student.student_name || '未知',
              class_info: student.class_info || '未知班级'
            }
          };
          
          console.log(`  毕业去向: ${mockDestination.destination_type}`);
          console.log(`  公司: ${mockDestination.company_name}`);
          console.log(`  职位: ${mockDestination.position}`);
        });
      }
    }
    
    console.log('\n=== 预期结果 ===');
    console.log('现在刷新页面，列表应该显示：');
    console.log('- 4条学生记录');
    console.log('- 每条记录显示：学号、姓名、班级');
    console.log('- 毕业去向显示为"就业"，公司为"阿里巴巴（中国）有限公司"');
    console.log('- 职位为"前端开发工程师"');
    
  } catch (err) {
    console.error('测试失败:', err);
  }
}

testFixedService();