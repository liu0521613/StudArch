import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function addCorrectStudentData() {
  try {
    console.log('=== 检查 student_profiles 表的实际可写字段 ===');
    
    // 先获取现有学生的一条记录看看哪些字段存在
    const { data: students, error } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(1);

    if (error) {
      console.error('获取学生失败:', error);
      return;
    }

    if (!students || students.length === 0) {
      console.log('没有找到学生数据');
      return;
    }

    console.log('学生表字段:', Object.keys(students[0]));

    // 使用实际存在的字段来添加示例数据
    // 根据之前的检查，我们看到的字段包括：id, user_id, gender, birth_date, major 等
    // 让我们尝试更新一些可以写入的字段
    
    const studentUpdates = [
      {
        // 学生1
        major: '计算机科学与技术',
        academic_status: '在读',
        notes: '示例学生1 - 张三'
      },
      {
        // 学生2  
        major: '软件工程',
        academic_status: '在读',
        notes: '示例学生2 - 李四'
      },
      {
        // 学生3
        major: '人工智能',
        academic_status: '在读', 
        notes: '示例学生3 - 王五'
      },
      {
        // 学生4
        major: '数据科学',
        academic_status: '在读',
        notes: '示例学生4 - 赵六'
      }
    ];

    // 获取所有学生的ID
    const { data: allStudents } = await supabase
      .from('student_profiles')
      .select('id')
      .limit(4);

    if (!allStudents || allStudents.length === 0) {
      console.log('没有获取到学生ID');
      return;
    }

    console.log('\n=== 尝试更新学生信息 ===');
    
    for (let i = 0; i < allStudents.length && i < studentUpdates.length; i++) {
      const student = allStudents[i];
      const updateData = studentUpdates[i];
      
      console.log(`\n更新学生 ${i + 1} (ID: ${student.id}):`);
      
      const { data: updatedData, error: updateError } = await supabase
        .from('student_profiles')
        .update({
          ...updateData,
          updated_at: new Date().toISOString()
        })
        .eq('id', student.id)
        .select('id, major, academic_status, notes');

      if (updateError) {
        console.error('❌ 更新失败:', updateError.message);
        
        // 尝试逐个字段更新，找出能写的字段
        console.log('尝试逐个字段更新...');
        for (const [field, value] of Object.entries(updateData)) {
          const { data: fieldData, error: fieldError } = await supabase
            .from('student_profiles')
            .update({ [field]: value })
            .eq('id', student.id)
            .select(field);
          
          if (fieldError) {
            console.log(`  ❌ 字段 ${field}: ${fieldError.message}`);
          } else {
            console.log(`  ✅ 字段 ${field}: 更新成功`);
          }
        }
      } else {
        console.log('✅ 更新成功:', updatedData[0]);
      }
    }

    // 最终验证
    console.log('\n=== 最终验证 ===');
    const { data: finalStudents, error: finalError } = await supabase
      .from('student_profiles')
      .select('id, major, academic_status, notes, created_at')
      .limit(4);

    if (finalError) {
      console.error('最终验证失败:', finalError);
    } else {
      console.log('最终学生数据:');
      finalStudents?.forEach((student, index) => {
        console.log(`${index + 1}. 专业: ${student.major || '无'}, 状态: ${student.academic_status || '无'}, 备注: ${student.notes || '无'}`);
      });
    }

  } catch (err) {
    console.error('操作失败:', err);
  }
}

addCorrectStudentData();