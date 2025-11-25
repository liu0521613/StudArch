import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTM0NDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function testBatchImport() {
  try {
    console.log('🔧 测试批量导入功能...');

    const teacherId = '00000000-0000-0000-0000-000000000001';

    // 1. 测试获取可导入学生
    console.log('\n1. 测试获取可导入学生列表...');
    const { data: availableData, error: availableError } = await supabase
      .rpc('get_available_students_for_import', {
        p_teacher_id: teacherId,
        p_keyword: '',
        p_grade: '',
        p_department: '',
        p_page: 1,
        p_limit: 20
      });

    if (availableError) {
      console.error('❌ 获取可导入学生失败:', availableError);
      console.log('\n尝试创建必要的函数...');
      
      // 显示需要手动执行的SQL
      console.log('\n请在Supabase控制台SQL编辑器中执行以下SQL:');
      console.log('https://mddpbyibesqewcktlqle.supabase.co/project/sql');
      console.log('\nSQL内容:');
      console.log(`
-- 创建teacher_students表
CREATE TABLE IF NOT EXISTS teacher_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE(teacher_id, student_id)
);

-- 创建简化版函数
CREATE OR REPLACE FUNCTION get_available_students_for_import(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_grade TEXT DEFAULT '',
    p_department TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    students JSONB,
    total_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jsonb_build_array(
            jsonb_build_object(
                'id', u.id,
                'username', u.username,
                'email', u.email,
                'user_number', u.user_number,
                'full_name', u.full_name,
                'phone', u.phone,
                'department', u.department,
                'grade', u.grade,
                'class_name', u.class_name,
                'status', u.status,
                'created_at', u.created_at,
                'updated_at', u.updated_at,
                'role', jsonb_build_object(
                    'id', r.id,
                    'role_name', r.role_name,
                    'role_description', r.role_description,
                    'is_system_default', r.is_system_default,
                    'created_at', r.created_at,
                    'updated_at', r.updated_at
                )
            )
        ) as students,
        0 as total_count
    FROM users u
    LEFT JOIN roles r ON u.role_id = r.id
    WHERE u.role_id = '3'
      AND u.status = 'active'
      AND NOT EXISTS (
          SELECT 1 FROM teacher_students ts 
          WHERE ts.teacher_id = p_teacher_id 
            AND ts.student_id = u.id
      )
    LIMIT 1;
END;
$$;

-- 授权权限
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;
GRANT SELECT ON teacher_students TO authenticated;
      `);
      
      return;
    }

    console.log('✅ 获取可导入学生成功');
    const result = availableData?.[0];
    if (result?.students) {
      const students = result.students;
      console.log(`找到 ${students.length} 个可导入学生`);
      
      if (students.length > 0) {
        console.log('示例学生:', students[0]?.full_name);
        
        // 2. 测试批量导入
        console.log('\n2. 测试批量导入功能...');
        const studentIds = students.slice(0, 2).map(s => s.id); // 导入前2个学生
        
        const { data: importData, error: importError } = await supabase
          .rpc('batch_add_students_to_teacher', {
            p_teacher_id: teacherId,
            p_student_ids: studentIds
          });

        if (importError) {
          console.error('❌ 批量导入失败:', importError);
          console.log('\n可能需要创建batch_add_students_to_teacher函数:');
          console.log(`
CREATE OR REPLACE FUNCTION batch_add_students_to_teacher(
    p_teacher_id UUID,
    p_student_ids UUID[]
)
RETURNS JSONB AS $$
DECLARE
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_student_id UUID;
BEGIN
    FOREACH v_student_id IN ARRAY p_student_ids LOOP
        BEGIN
            INSERT INTO teacher_students (teacher_id, student_id, created_by)
            VALUES (p_teacher_id, v_student_id, p_teacher_id)
            ON CONFLICT (teacher_id, student_id) DO NOTHING;
            
            GET DIAGNOSTICS v_success_count = ROW_COUNT;
        EXCEPTION
            WHEN OTHERS THEN
                v_failed_count := v_failed_count + 1;
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'success', v_success_count,
        'failed', v_failed_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION batch_add_students_to_teacher TO authenticated;
GRANT INSERT ON teacher_students TO authenticated;
          `);
        } else {
          console.log('✅ 批量导入成功');
          console.log('导入结果:', importData);
        }
      }
    }

  } catch (error) {
    console.error('测试失败:', error);
  }
}

testBatchImport();