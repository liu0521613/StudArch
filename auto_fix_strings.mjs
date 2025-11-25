import fs from 'fs';

const filePath = 'src/pages/p-teacher_student_list/index.tsx';
let content = fs.readFileSync(filePath, 'utf8');

console.log('开始修复字符串问题...');

// 找到并替换有问题的代码块
const brokenBlock = /if \(successCount > 0 && failedCount === 0\) \{[\s\S]*?alert\(message\);/g;
const fixedBlock = `if (successCount > 0 && failedCount === 0) {
        alert(\`✅ 成功删除 \${successCount} 个学生\`);
      } else if (successCount > 0 && failedCount > 0) {
        const errorDetails = errors.slice(0, 3).join('\\n');
        const moreErrors = errors.length > 3 ? \`\\n...还有 \${errors.length - 3} 个错误\` : '';
        let message = \`⚠️ 部分删除完成

✅ 成功删除: \${successCount} 个
❌ 删除失败: \${failedCount} 个

失败详情:
\${errorDetails}\${moreErrors}\`;
        alert(message);
      } else {
        let message = \`❌ 删除失败，共 \${failedCount} 个学生删除失败

\${errors.slice(0, 2).join('\\n')}\`;
        alert(message);
      }`;

content = content.replace(brokenBlock, fixedBlock);

fs.writeFileSync(filePath, content);
console.log('✅ 字符串修复完成！');