import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function addSampleStudentData() {
  try {
    console.log('=== 为现有学生添加基础信息 ===');
    
    // 先获取现有学生
    const { data: students, error } = await supabase
      .from('student_profiles')
      .select('id, user_id')
      .limit(5);

    if (error) {
      console.error('获取学生失败:', error);
      return;
    }

    if (!students || students.length === 0) {
      console.log('没有找到学生数据');
      return;
    }

    // 示例学生数据
    const sampleData = [
      {
        student_id: '2021001',
        student_name: '张三',
        class_info: '计算机科学与技术1班',
        major: '计算机科学与技术'
      },
      {
        student_id: '2021002',
        student_name: '李四',
        class_info: '计算机科学与技术2班',
        major: '软件工程'
      },
      {
        student_id: '2021003',
        student_name: '王五',
        class_info: '计算机科学与技术3班',
        major: '人工智能'
      },
      {
        student_id: '2021004',
        student_name: '赵六',
        class_info: '软件工程1班',
        major: '软件工程'
      }
    ];

    // 更新每个学生的信息
    for (let i = 0; i < students.length && i < sampleData.length; i++) {
      const student = students[i];
      const data = sampleData[i];
      
      console.log(`\n更新学生 ${i + 1}:`);
      
      const { data: updatedData, error: updateError } = await supabase
        .from('student_profiles')
        .update({
          ...data,
          updated_at: new Date().toISOString()
        })
        .eq('id', student.id)
        .select('id, student_id, student_name, class_info, major');

      if (updateError) {
        console.error('❌ 更新失败:', updateError);
      } else {
        console.log('✅ 更新成功:', updatedData[0]);
      }
    }

    // 验证更新结果
    console.log('\n=== 验证更新结果 ===');
    const { data: updatedStudents, error: verifyError } = await supabase
      .from('student_profiles')
      .select('id, student_id, student_name, class_info, major')
      .limit(5);

    if (verifyError) {
      console.error('验证失败:', verifyError);
    } else {
      console.log('更新后的学生数据:');
      updatedStudents?.forEach((student, index) => {
        if (student.student_id) {
          console.log(`${index + 1}. ${student.student_name} (${student.student_id}) - ${student.class_info}`);
        }
      });
    }

  } catch (err) {
    console.error('操作失败:', err);
  }
}

addSampleStudentData();