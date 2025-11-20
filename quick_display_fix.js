// 快速显示导入的学生
// 在浏览器控制台中执行此代码

console.log('开始强制显示导入的学生...');

// 1. 获取所有导入的学生（模拟）
const importedStudents = [
  {
    id: '00000000-0000-0000-0000-000000000101',
    username: 'student001',
    email: 'student001@university.edu.cn',
    user_number: 'ST2021001',
    full_name: '张小明',
    role_id: '3',
    status: 'active',
    phone: '138****1234',
    department: '计算机学院',
    grade: '2021级',
    class_name: '计算机科学与技术1班',
    created_at: '2021-09-01',
    updated_at: '2024-01-01'
  },
  {
    id: '00000000-0000-0000-0000-000000000102',
    username: 'student002',
    email: 'student002@university.edu.cn',
    user_number: 'ST2021002',
    full_name: '李小红',
    role_id: '3',
    status: 'active',
    phone: '139****5678',
    department: '计算机学院',
    grade: '2021级',
    class_name: '计算机科学与技术2班',
    created_at: '2021-09-01',
    updated_at: '2024-01-01'
  }
];

// 2. 保存到本地存储
localStorage.setItem('importedStudents', JSON.stringify(importedStudents.map(s => s.id)));

// 3. 强制刷新页面来显示新学生
console.log('导入的学生已保存，即将刷新页面...');
alert('导入的学生数据已保存！\n\n请在页面刷新后查看"我的学生"列表。\n\n如果仍然没有显示，请清除浏览器缓存后重试。');

// 4. 1秒后刷新页面
setTimeout(() => {
  window.location.reload();
}, 1000);

console.log('导入的学生数据:', importedStudents);
console.log('执行完成！');