// 测试localStorage持久化功能
console.log('=== 测试导入学生localStorage持久化功能 ===');

// 1. 清除之前的测试数据
localStorage.removeItem('importedStudentIds');
console.log('✓ 清除旧的localStorage数据');

// 2. 模拟选择学生并导入
const selectedStudents = ['00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000102'];
localStorage.setItem('importedStudentIds', JSON.stringify(selectedStudents));
console.log('✓ 模拟导入学生:', selectedStudents);

// 3. 验证数据是否正确保存
const savedData = localStorage.getItem('importedStudentIds');
if (savedData) {
  try {
    const parsedData = JSON.parse(savedData);
    console.log('✓ localStorage数据读取成功:', parsedData);
    console.log('✓ 数据格式验证:', Array.isArray(parsedData));
  } catch (e) {
    console.error('✗ localStorage数据解析失败:', e);
  }
} else {
  console.error('✗ localStorage中没有找到导入数据');
}

// 4. 模拟页面刷新后的数据恢复
const restoredData = localStorage.getItem('importedStudentIds');
if (restoredData) {
  const importedStudentIds = new Set(JSON.parse(restoredData));
  console.log('✓ 页面刷新后数据恢复成功，导入学生数量:', importedStudentIds.size);
  console.log('✓ 恢复的学生ID:', Array.from(importedStudentIds));
} else {
  console.error('✗ 页面刷新后数据恢复失败');
}

console.log('\n=== 测试完成 ===');
console.log('现在可以测试以下功能:');
console.log('1. 打开批量导入弹窗');
console.log('2. 选择一些学生');
console.log('3. 点击确认导入');
console.log('4. 刷新页面 (F5)');
console.log('5. 检查学生列表是否包含之前导入的学生');