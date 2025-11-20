// 直接测试导入功能的debug脚本
console.log('=== 直接测试导入功能 ===');

// 1. 清除所有localStorage数据
localStorage.clear();
console.log('✓ 清除所有localStorage数据');

// 2. 模拟导入学生到教师管理列表
const testStudentId = '00000000-0000-0000-0000-000000000101';
const testStudentId2 = 'demo-3';

// 保存到localStorage
const importedIds = [testStudentId, testStudentId2];
localStorage.setItem('importedStudentIds', JSON.stringify(importedIds));
console.log('✓ 模拟导入学生ID:', importedIds);

// 3. 验证localStorage中的数据
const savedData = localStorage.getItem('importedStudentIds');
console.log('localStorage中的数据:', savedData);

// 4. 检查是否可以在控制台直接操作组件状态
// 尝试触发页面重新渲染
console.log('\n=== 手动触发组件更新测试 ===');

// 如果页面已经加载，尝试查找React组件并强制更新
if (typeof window !== 'undefined' && window.document) {
  // 查找教师学生列表页面
  const currentUrl = window.location.pathname;
  console.log('当前页面路径:', currentUrl);
  
  // 如果在教师学生列表页面，尝试刷新数据
  if (currentUrl.includes('teacher-student-list')) {
    console.log('✓ 在教师学生列表页面');
    
    // 模拟点击搜索按钮来触发数据刷新
    const searchButton = document.querySelector('button[type="button"]');
    if (searchButton && searchButton.textContent?.includes('搜索')) {
      console.log('✓ 找到搜索按钮，尝试触发点击');
      searchButton.click();
    } else {
      console.log('✗ 未找到搜索按钮，尝试其他方式');
      
      // 尝试触发页面刷新
      setTimeout(() => {
        window.location.reload();
      }, 1000);
    }
  } else {
    console.log('✗ 不在教师学生列表页面，请导航到该页面测试');
  }
}

// 5. 验证导入状态是否正确保存
setTimeout(() => {
  const checkData = localStorage.getItem('importedStudentIds');
  console.log('延迟检查localStorage数据:', checkData);
  
  if (checkData) {
    try {
      const parsed = JSON.parse(checkData);
      console.log('✓ 数据解析成功，包含', parsed.length, '个学生ID');
      console.log('✓ 学生ID列表:', parsed);
    } catch (e) {
      console.error('✗ 数据解析失败:', e);
    }
  } else {
    console.error('✗ localStorage中没有找到导入数据');
  }
}, 2000);

console.log('\n=== 测试完成 ===');
console.log('请检查:');
console.log('1. localStorage中是否保存了导入的学生ID');
console.log('2. 页面刷新后这些学生是否显示在列表中');
console.log('3. 导入功能是否正常工作');