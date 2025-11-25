// 清理后的批量删除处理函数
const cleanBatchDeleteHandler = `
  const handleBatchDelete = async () => {
    if (selectedStudents.size === 0) {
      alert('请选择要删除的学生');
      return;
    }

    const selectedCount = selectedStudents.size;
    const confirmMessage = \`确定要删除选中的 \${selectedCount} 个学生吗？\n\n此操作将从系统中完全删除这些学生的所有信息，包括：\n• 学生基本信息\n• 档案信息\n• 毕业去向信息\n• 关联数据\n\n此操作不可恢复！\`;

    if (!confirm(confirmMessage)) {
      return;
    }

    // 二次确认
    const finalConfirm = prompt('请输入 "DELETE" 来确认删除操作：');
    if (finalConfirm !== 'DELETE') {
      alert('确认输入不正确，操作已取消');
      return;
    }

    try {
      let successCount = 0;
      let failedCount = 0;
      const errors: string[] = [];

      for (const studentId of selectedStudents) {
        try {
          // 首先从教师管理列表中移除
          const currentTeacherId = '00000000-0000-0000-0000-000000000001';
          await UserService.removeStudentFromTeacher(currentTeacherId, studentId);
          
          // 然后完全删除学生数据
          await UserService.deleteUser(studentId);
          successCount++;
        } catch (error) {
          failedCount++;
          const errorMsg = error instanceof Error ? error.message : '未知错误';
          errors.push(\`学生ID \${studentId}: \${errorMsg}\`);
          console.error(\`删除学生 \${studentId} 失败:\`, error);
        }
      }

      setSelectedStudents(new Set());
      fetchTeacherStudents(); // 重新获取数据

      // 显示详细的结果 - 使用干净的字符串
      if (successCount > 0 && failedCount === 0) {
        alert(\`✅ 成功删除 \${successCount} 个学生\`);
      } else if (successCount > 0 && failedCount > 0) {
        const errorDetails = errors.slice(0, 3).join('\n');
        const moreErrors = errors.length > 3 ? \`\\n...还有 \${errors.length - 3} 个错误\` : '';
        let message = \`⚠️ 部分删除完成\\n\\n✅ 成功删除: \${successCount} 个\\n❌ 删除失败: \${failedCount} 个\\n\\n失败详情:\\n\${errorDetails}\${moreErrors}\`;
        alert(message);
      } else {
        let message = \`❌ 删除失败，共 \${failedCount} 个学生删除失败\\n\\n\${errors.slice(0, 2).join('\n')}\`;
        alert(message);
      }
    } catch (error) {
      console.error('批量删除学生失败:', error);
      alert('批量删除操作失败，请稍后重试');
    }
  };
`;

module.exports = { cleanBatchDeleteHandler };