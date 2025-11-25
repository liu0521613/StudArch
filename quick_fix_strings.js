import fs from 'fs';

// 读取文件
const filePath = 'src/pages/p-teacher_student_list/index.tsx';
let content = fs.readFileSync(filePath, 'utf8');

// 修复有问题的字符串 - 简单替换
const fixes = [
  // 修复删除部分的字符串错误
  {
    find: /let message = `⚠️ 部分删除完成\\\\n\\\\n✅ 成功删除: \${successCount} 个\\\\n❌ 删除失败: \${failedCount} 个\\\\n\\\\n失败详情:\\\\n\${errorDetails}\${moreErrors}`;/gs,
    replace: 'let message = `⚠️ 部分删除完成\\n\\n✅ 成功删除: ${successCount} 个\\n❌ 删除失败: ${failedCount} 个\\n\\n失败详情:\\n${errorDetails}${moreErrors}`;'
  },
  {
    find: /let message = `❌ 删除失败，共 \${failedCount} 个学生删除失败\\\\n\\\\n\${errors\.slice\(0, 2\)\.join\('\\\\n'\)}`;/gs,
    replace: 'let message = `❌ 删除失败，共 ${failedCount} 个学生删除失败\\n\\n${errors.slice(0, 2).join("\\n")}`;'
  }
];

// 应用修复
fixes.forEach(fix => {
  content = content.replace(fix.find, fix.replace);
});

// 写回文件
fs.writeFileSync(filePath, content);
console.log('✅ 字符串修复完成');