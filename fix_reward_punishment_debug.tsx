import React from 'react';
import { RewardPunishmentService } from '../services/rewardPunishmentService';

// 调试奖惩保存功能的组件
const RewardPunishmentDebug: React.FC = () => {
  const debugSave = async () => {
    try {
      console.log('🔍 开始调试奖惩保存...');
      
      // 模拟表单数据
      const formData = {
        type: 'reward' as const,
        name: '测试奖励',
        level: 'school' as const,
        category: '奖学金',
        description: '这是一个测试奖励记录',
        date: '2024-01-01'
      };
      
      console.log('📝 表单数据:', formData);
      
      // 检查环境变量
      console.log('🔍 检查环境变量...');
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      console.log('Supabase URL:', supabaseUrl ? '已配置' : '未配置');
      console.log('Supabase Key:', supabaseKey ? '已配置' : '未配置');
      
      if (!supabaseUrl || !supabaseKey) {
        alert('❌ 环境变量未配置');
        return;
      }
      
      // 测试数据库连接
      console.log('🔍 测试数据库连接...');
      const isConnected = await RewardPunishmentService.checkConnection();
      console.log('数据库连接:', isConnected ? '正常' : '异常');
      
      if (!isConnected) {
        alert('❌ 数据库连接失败');
        return;
      }
      
      // 尝试保存
      console.log('💾 尝试保存奖惩记录...');
      
      // 获取一个测试学生ID
      const testData = await getTestStudentId();
      if (!testData) {
        alert('❌ 无法获取测试学生ID');
        return;
      }
      
      const rewardData = {
        student_id: testData.studentId,
        type: formData.type,
        name: formData.name,
        level: formData.level,
        category: formData.category,
        description: formData.description,
        date: formData.date,
        created_by: 'debug_teacher'
      };
      
      console.log('📦 准备保存的数据:', rewardData);
      
      const result = await RewardPunishmentService.createRewardPunishment(rewardData);
      console.log('✅ 保存成功:', result);
      
      // 清理测试数据
      if (result?.id) {
        await RewardPunishmentService.deleteRewardPunishment(result.id);
        console.log('🧹 测试数据已清理');
      }
      
      alert('✅ 奖惩保存功能正常');
      
    } catch (error) {
      console.error('❌ 调试过程中发现错误:', error);
      alert(`❌ 保存失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  };
  
  // 获取测试学生ID
  const getTestStudentId = async () => {
    try {
      // 这里需要导入实际的API来获取学生
      const response = await fetch('/api/students?limit=1');
      if (response.ok) {
        const students = await response.json();
        return students.length > 0 ? { studentId: students[0].id } : null;
      }
      return null;
    } catch (error) {
      console.error('获取学生ID失败:', error);
      return null;
    }
  };
  
  return (
    <div style={{ padding: '20px' }}>
      <h2>奖惩保存功能调试</h2>
      <button 
        onClick={debugSave}
        style={{
          padding: '10px 20px',
          backgroundColor: '#007bff',
          color: 'white',
          border: 'none',
          borderRadius: '5px',
          cursor: 'pointer'
        }}
      >
        开始调试
      </button>
      <p style={{ marginTop: '10px', fontSize: '14px', color: '#666' }}>
        点击按钮开始调试奖惩保存功能，请查看浏览器控制台的详细日志。
      </p>
    </div>
  );
};

export default RewardPunishmentDebug;