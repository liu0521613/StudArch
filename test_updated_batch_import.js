import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTM0NDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function testUpdatedBatchImport() {
  try {
    console.log('🧪 测试更新后的批量导入功能...');

    const teacherId = '00000000-0000-0000-0000-000000000001';

    // 1. 测试获取所有激活学生
    console.log('\n1. 获取所有激活的学生...');
    const { data: allStudents, error: studentsError } = await supabase
      .from('users')
      .select(`
        *,
        role:roles(*)
      `)
      .eq('role_id', '3') // 学生角色
      .eq('status', 'active')
      .limit(5); // 限制数量以便测试

    if (studentsError) {
      console.error('❌ 获取学生失败:', studentsError);
      return;
    }

    console.log(`✅ 找到 ${allStudents?.length || 0} 个激活学生`);
    
    if (!allStudents || allStudents.length === 0) {
      console.log('⚠️  没有找到学生数据，请先创建一些测试学生');
      return;
    }

    // 显示找到的学生
    allStudents.forEach((student, index) => {
      console.log(`${index + 1}. ${student.full_name} (${student.user_number}) - ${student.email}`);
    });

    // 2. 获取教师已管理的学生
    console.log('\n2. 获取教师已管理的学生...');
    const { data: teacherStudents, error: teacherError } = await supabase
      .from('teacher_students')
      .select('student_id')
      .eq('teacher_id', teacherId);

    if (teacherError) {
      console.warn('获取教师学生关联失败:', teacherError);
    } else {
      console.log(`✅ 教师已管理 ${teacherStudents?.length || 0} 个学生`);
    }

    const managedStudentIds = new Set(teacherStudents?.map(ts => ts.student_id) || []);

    // 3. 筛选出可导入的学生
    const availableStudents = allStudents.filter(student => !managedStudentIds.has(student.id));
    console.log(`✅ 找到 ${availableStudents.length} 个可导入学生`);

    if (availableStudents.length === 0) {
      console.log('⚠️  没有可导入的学生（所有学生都已被管理）');
      return;
    }

    // 4. 测试批量导入（只导入第一个可导入的学生）
    const studentToImport = availableStudents[0];
    console.log(`\n3. 测试导入学生: ${studentToImport.full_name}...`);

    try {
      const { error: insertError } = await supabase
        .from('teacher_students')
        .insert({
          teacher_id: teacherId,
          student_id: studentToImport.id,
          created_by: teacherId
        });

      if (insertError) {
        console.error('❌ 导入失败:', insertError);
      } else {
        console.log('✅ 导入成功！');
        
        // 5. 验证导入结果
        console.log('\n4. 验证导入结果...');
        const { data: verifyData, error: verifyError } = await supabase
          .from('teacher_students')
          .select(`
            *,
            student:users(full_name, user_number, email)
          `)
          .eq('teacher_id', teacherId)
          .eq('student_id', studentToImport.id)
          .single();

        if (verifyError) {
          console.error('❌ 验证失败:', verifyError);
        } else {
          console.log('✅ 验证成功！');
          console.log(`导入的学生: ${verifyData.student?.full_name}`);
        }
      }
    } catch (err) {
      console.error('❌ 导入过程中出错:', err);
    }

    // 6. 测试获取教师学生列表
    console.log('\n5. 获取教师管理的学生列表...');
    const { data: finalTeacherStudents, error: finalError } = await supabase
      .from('teacher_students')
      .select(`
        student:users(id, full_name, user_number, email, department, grade, class_name, status),
        created_at
      `)
      .eq('teacher_id', teacherId)
      .order('created_at', { ascending: false });

    if (finalError) {
      console.error('❌ 获取最终列表失败:', finalError);
    } else {
      console.log(`✅ 教师当前管理的学生数量: ${finalTeacherStudents?.length || 0}`);
      finalTeacherStudents?.forEach((item, index) => {
        console.log(`${index + 1}. ${item.student?.full_name} - ${item.student?.user_number}`);
      });
    }

  } catch (error) {
    console.error('测试失败:', error);
  }
}

testUpdatedBatchImport();