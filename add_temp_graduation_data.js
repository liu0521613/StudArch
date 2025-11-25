import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function addTempGraduationData() {
  try {
    console.log('=== 在 student_profiles 表中添加临时毕业去向数据 ===');
    
    // 先获取现有的学生数据
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(5);
    
    if (studentError) {
      console.error('获取学生数据失败:', studentError);
      return;
    }
    
    if (!students || students.length === 0) {
      console.log('没有找到学生数据');
      return;
    }
    
    console.log('找到学生:', students.length, '个');
    
    // 为每个学生添加临时毕业去向数据
    const tempGraduationData = [
      {
        destination_type: 'employment',
        company_name: '阿里巴巴（中国）有限公司',
        position: '前端开发工程师',
        salary: '15000',
        work_location: '杭州',
        graduation_status: 'pending'
      },
      {
        destination_type: 'furtherstudy',
        school_name: '清华大学',
        major: '计算机应用技术',
        degree: '硕士研究生',
        graduation_status: 'pending'
      },
      {
        destination_type: 'abroad',
        school_name: '美国斯坦福大学',
        major: '人工智能',
        degree: '博士研究生',
        abroad_country: '美国',
        graduation_status: 'pending'
      },
      {
        destination_type: 'entrepreneurship',
        startup_name: '北京创新科技有限公司',
        startup_role: '创始人兼CEO',
        graduation_status: 'pending'
      },
      {
        destination_type: 'other',
        other_description: '自由职业',
        graduation_status: 'pending'
      }
    ];
    
    // 更新每个学生的毕业去向数据
    for (let i = 0; i < students.length && i < tempGraduationData.length; i++) {
      const student = students[i];
      const graduationData = tempGraduationData[i];
      
      console.log(`\n更新学生 ${student.student_id || student.id}:`);
      console.log('毕业去向:', graduationData.destination_type);
      
      const { data: updatedData, error: updateError } = await supabase
        .from('student_profiles')
        .update({
          ...graduationData,
          updated_at: new Date().toISOString()
        })
        .eq('id', student.id)
        .select();
      
      if (updateError) {
        console.error('更新失败:', updateError);
      } else {
        console.log('✅ 更新成功:', updatedData?.[0]?.student_id);
      }
    }
    
    // 验证更新结果
    console.log('\n=== 验证更新结果 ===');
    const { data: updatedStudents, error: verifyError } = await supabase
      .from('student_profiles')
      .select('student_id, student_name, destination_type, company_name, school_name, graduation_status')
      .limit(5);
    
    if (verifyError) {
      console.error('验证失败:', verifyError);
    } else {
      console.log('更新后的学生毕业去向数据:');
      updatedStudents?.forEach((student, index) => {
        if (student.destination_type) {
          console.log(`${index + 1}. ${student.student_name} (${student.student_id}): ${student.destination_type}`);
          if (student.company_name) console.log(`   公司: ${student.company_name}`);
          if (student.school_name) console.log(`   学校: ${student.school_name}`);
        }
      });
    }
    
  } catch (err) {
    console.error('操作失败:', err);
  }
}

addTempGraduationData();