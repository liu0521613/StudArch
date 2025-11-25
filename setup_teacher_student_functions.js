const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('缺少 Supabase 配置');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function executeTeacherStudentFunctions() {
    try {
        console.log('开始执行教师学生管理函数...');

        // 1. 创建teacher_students表
        const createTableSQL = `
        CREATE TABLE IF NOT EXISTS teacher_students (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            created_by UUID REFERENCES users(id),
            UNIQUE(teacher_id, student_id)
        );`;

        console.log('创建teacher_students表...');
        const { error: tableError } = await supabase.rpc('exec_sql', { sql: createTableSQL });
        if (tableError) {
            console.log('表可能已存在，继续执行...');
        }

        // 2. 创建简化版get_available_students_for_import函数
        const createFunctionSQL = `
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
        DECLARE
            v_offset INTEGER := (p_page - 1) * p_limit;
        BEGIN
            RETURN QUERY
            SELECT 
                COALESCE(
                    jsonb_agg(
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
                    ),
                    '[]'::jsonb
                ) as students,
                (
                    SELECT COUNT(*)
                    FROM users u_count
                    WHERE u_count.role_id = '3'
                      AND u_count.status = 'active'
                      AND NOT EXISTS (
                          SELECT 1 FROM teacher_students ts_count 
                          WHERE ts_count.teacher_id = p_teacher_id 
                            AND ts_count.student_id = u_count.id
                      )
                      AND (
                          p_keyword = '' OR 
                          LOWER(u_count.full_name) LIKE LOWER('%' || p_keyword || '%') OR
                          LOWER(u_count.user_number) LIKE LOWER('%' || p_keyword || '%') OR
                          LOWER(u_count.email) LIKE LOWER('%' || p_keyword || '%')
                      )
                      AND (p_grade = '' OR u_count.grade = p_grade)
                      AND (p_department = '' OR u_count.department = p_department)
                ) as total_count
            FROM users u
            LEFT JOIN roles r ON u.role_id = r.id
            WHERE u.role_id = '3'
              AND u.status = 'active'
              AND NOT EXISTS (
                  SELECT 1 FROM teacher_students ts 
                  WHERE ts.teacher_id = p_teacher_id 
                    AND ts.student_id = u.id
              )
              AND (
                  p_keyword = '' OR 
                  LOWER(u.full_name) LIKE LOWER('%' || p_keyword || '%') OR
                  LOWER(u.user_number) LIKE LOWER('%' || p_keyword || '%') OR
                  LOWER(u.email) LIKE LOWER('%' || p_keyword || '%')
              )
              AND (p_grade = '' OR u.grade = p_grade)
              AND (p_department = '' OR u.department = p_department)
            ORDER BY u.created_at DESC
            LIMIT p_limit OFFSET v_offset;
        END;
        $$;`;

        console.log('创建get_available_students_for_import函数...');
        const { error: functionError } = await supabase.rpc('exec_sql', { sql: createFunctionSQL });
        if (functionError) {
            console.error('创建函数失败:', functionError);
        } else {
            console.log('✅ get_available_students_for_import函数创建成功');
        }

        // 3. 创建batch_add_students_to_teacher函数
        const batchImportSQL = `
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
            -- 验证教师权限
            IF NOT EXISTS (
                SELECT 1 FROM users 
                WHERE id = p_teacher_id 
                AND role_id = '2' -- 教师角色ID
            ) THEN
                RETURN jsonb_build_object(
                    'success', 0,
                    'failed', 0,
                    'error', '无效的教师ID或权限不足'
                );
            END IF;

            -- 批量插入学生关联
            FOREACH v_student_id IN ARRAY p_student_ids LOOP
                BEGIN
                    -- 验证学生是否存在且状态正常
                    IF EXISTS (
                        SELECT 1 FROM users u
                        WHERE u.id = v_student_id 
                        AND u.role_id = '3' -- 学生角色ID
                        AND u.status = 'active'
                    ) THEN
                        -- 插入关联记录（忽略重复）
                        INSERT INTO teacher_students (teacher_id, student_id, created_by)
                        VALUES (p_teacher_id, v_student_id, p_teacher_id)
                        ON CONFLICT (teacher_id, student_id) DO NOTHING;
                        
                        GET DIAGNOSTICS v_success_count = ROW_COUNT;
                    ELSE
                        v_failed_count := v_failed_count + 1;
                    END IF;
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
        $$ LANGUAGE plpgsql SECURITY DEFINER;`;

        console.log('创建batch_add_students_to_teacher函数...');
        const { error: batchError } = await supabase.rpc('exec_sql', { sql: batchImportSQL });
        if (batchError) {
            console.error('创建批量导入函数失败:', batchError);
        } else {
            console.log('✅ batch_add_students_to_teacher函数创建成功');
        }

        // 4. 授权权限
        const grantSQL = `
        GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;
        GRANT EXECUTE ON FUNCTION batch_add_students_to_teacher TO authenticated;
        `;

        const { error: grantError } = await supabase.rpc('exec_sql', { sql: grantSQL });
        if (grantError) {
            console.error('授权失败:', grantError);
        } else {
            console.log('✅ 权限授权成功');
        }

        console.log('\n✅ 所有函数执行完成！');

    } catch (error) {
        console.error('执行过程中出错:', error);
    }
}

executeTeacherStudentFunctions();