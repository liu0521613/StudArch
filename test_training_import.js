// 测试培养方案导入API
import fetch from 'node-fetch';

const testData = {
  courses: [
    {
      course_number: 'CS101',
      course_name: '计算机基础',
      credits: 3,
      recommended_grade: '大一',
      semester: '第一学期',
      exam_method: '笔试',
      course_nature: '必修课'
    },
    {
      course_number: 'CS102', 
      course_name: '程序设计基础',
      credits: 4,
      recommended_grade: '大一',
      semester: '第一学期',
      exam_method: '上机考试',
      course_nature: '必修课'
    }
  ],
  programCode: 'CS_2021',
  batchName: '测试导入批次',
  importedBy: '00000000-0000-0000-0000-000000000001'
};

async function testImport() {
  try {
    console.log('🔄 测试培养方案导入API...');
    
    const response = await fetch('http://localhost:3001/api/training-program/import', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testData)
    });
    
    const result = await response.json();
    
    if (response.ok) {
      console.log('✅ 导入成功!');
      console.log('结果:', JSON.stringify(result, null, 2));
    } else {
      console.log('❌ 导入失败!');
      console.log('错误:', result);
    }
    
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
  }
}

testImport();