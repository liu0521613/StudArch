import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkDataAfterPolicy() {
  try {
    console.log('=== 检查 RLS 策略后的表访问和数据 ===');
    
    // 检查 graduation_destinations 表
    console.log('\n--- 检查 graduation_destinations 表 ---');
    const { data: destinations, error: destError, count } = await supabase
      .from('graduation_destinations')
      .select('*', { count: 'exact' });
    
    if (destError) {
      console.error('❌ 访问 graduation_destinations 失败:', destError);
    } else {
      console.log('✅ graduation_destinations 可访问');
      console.log('记录数:', count || 0);
      
      if (destinations && destinations.length > 0) {
        console.log('数据示例:');
        destinations.slice(0, 3).forEach((record, index) => {
          console.log(`记录 ${index + 1}:`, {
            id: record.id,
            student_id: record.student_id,
            destination_type: record.destination_type,
            status: record.status,
            company_name: record.company_name,
            school_name: record.school_name
          });
        });
      } else {
        console.log('⚠️ 表中没有数据');
      }
    }
    
    // 检查导入批次表
    console.log('\n--- 检查 graduation_import_batches 表 ---');
    const { data: batches, error: batchError } = await supabase
      .from('graduation_import_batches')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);
    
    if (batchError) {
      console.error('❌ 访问 graduation_import_batches 失败:', batchError);
    } else {
      console.log('✅ graduation_import_batches 可访问');
      console.log('批次记录数:', batches?.length || 0);
      
      if (batches && batches.length > 0) {
        batches.forEach((batch, index) => {
          console.log(`批次 ${index + 1}:`, {
            id: batch.id,
            batch_name: batch.batch_name,
            total_records: batch.total_records,
            success_count: batch.success_count,
            failure_count: batch.failure_count,
            status: batch.status
          });
        });
      } else {
        console.log('⚠️ 没有导入批次记录');
      }
    }
    
    // 检查学生表
    console.log('\n--- 检查 student_profiles 表 ---');
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('id, student_number, full_name, class_name')
      .limit(5);
    
    if (studentError) {
      console.error('❌ 访问 student_profiles 失败:', studentError);
    } else {
      console.log('✅ student_profiles 可访问');
      console.log('学生记录数:', students?.length || 0);
      
      if (students && students.length > 0) {
        console.log('学生数据:');
        students.forEach((student, index) => {
          console.log(`学生 ${index + 1}:`, student);
        });
      }
    }
    
    // 如果没有数据，手动插入一些测试数据
    if (!destinations || destinations.length === 0) {
      console.log('\n=== 尝试插入测试数据 ===');
      
      // 先获取学生ID
      const { data: studentIds, error: studentIdError } = await supabase
        .from('student_profiles')
        .select('id, student_number, full_name')
        .limit(5);
      
      if (studentIdError) {
        console.error('获取学生ID失败:', studentIdError);
      } else if (studentIds && studentIds.length > 0) {
        console.log('找到学生:', studentIds);
        
        // 插入测试数据
        const testData = [
          {
            student_id: studentIds[0]?.id,
            destination_type: 'employment',
            company_name: '阿里巴巴（中国）有限公司',
            position: '前端开发工程师',
            salary: 15000,
            work_location: '杭州',
            status: 'pending'
          },
          {
            student_id: studentIds[1]?.id,
            destination_type: 'furtherstudy',
            school_name: '清华大学',
            major: '计算机应用技术',
            degree: '硕士研究生',
            status: 'pending'
          }
        ];
        
        for (const data of testData) {
          if (!data.student_id) continue;
          
          const { data: insertedData, error: insertError } = await supabase
            .from('graduation_destinations')
            .insert([data])
            .select();
          
          if (insertError) {
            console.error('插入失败:', insertError);
          } else {
            console.log('✅ 插入成功:', insertedData);
          }
        }
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkDataAfterPolicy();