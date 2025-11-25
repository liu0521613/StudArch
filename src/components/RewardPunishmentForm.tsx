import React, { useState } from 'react';
import styles from '../pages/p-teacher_student_detail/styles.module.css';
import { RewardPunishment, RewardPunishmentCreate } from '../types/rewardPunishment';

interface RewardPunishmentFormProps {
  reward?: RewardPunishment | null;
  onSave: (data: Partial<RewardPunishmentCreate>) => void;
  onCancel: () => void;
}

const RewardPunishmentForm: React.FC<RewardPunishmentFormProps> = ({ 
  reward, 
  onSave, 
  onCancel 
}) => {
  const [formData, setFormData] = useState({
    type: reward?.type || 'reward' as 'reward' | 'punishment',
    name: reward?.name || '',
    category: reward?.category || '',
    description: reward?.description || '',
    date: reward?.date || new Date().toISOString().split('T')[0]
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };



  // 根据奖惩类型获取常见分类
  const getCategoryOptions = () => {
    if (formData.type === 'reward') {
      return [
        { value: '', label: '请选择分类' },
        { value: '奖学金', label: '奖学金' },
        { value: '荣誉', label: '荣誉称号' },
        { value: '竞赛', label: '竞赛获奖' },
        { value: '论文', label: '论文发表' },
        { value: '专利', label: '专利申请' },
        { value: '社会实践', label: '社会实践' },
        { value: '其他', label: '其他奖励' }
      ];
    } else {
      return [
        { value: '', label: '请选择分类' },
        { value: '纪律处分', label: '纪律处分' },
        { value: '警告', label: '警告处分' },
        { value: '严重警告', label: '严重警告' },
        { value: '记过', label: '记过处分' },
        { value: '留校察看', label: '留校察看' },
        { value: '其他', label: '其他处分' }
      ];
    }
  };

  return (
    <div className="fixed inset-0 z-50">
      <div 
        className={styles.modalBackdrop}
        onClick={onCancel}
      ></div>
      <div className="relative flex items-center justify-center min-h-screen p-4">
        <div className={`${styles.modalEnter} bg-white rounded-xl shadow-lg w-full max-w-md max-h-[90vh] overflow-y-auto`}>
          <div className="flex items-center justify-between p-6 border-b border-border-light">
            <h3 className="text-lg font-semibold text-text-primary">
              {reward ? '编辑奖惩' : '新增奖惩'}
            </h3>
            <button 
              onClick={onCancel}
              className="text-text-secondary hover:text-text-primary transition-colors"
            >
              <i className="fas fa-times text-xl"></i>
            </button>
          </div>
          
          <form onSubmit={handleSubmit} className="p-6">
            <div className="space-y-4">
              {/* 奖惩类型 */}
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  奖惩类型 <span className="text-red-500">*</span>
                </label>
                <select 
                  value={formData.type}
                  onChange={(e) => handleInputChange('type', e.target.value)}
                  className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent"
                  required
                >
                  <option value="reward">奖励</option>
                  <option value="punishment">惩罚</option>
                </select>
              </div>

              {/* 奖惩名称 */}
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  奖惩名称 <span className="text-red-500">*</span>
                </label>
                <input 
                  type="text" 
                  value={formData.name}
                  onChange={(e) => handleInputChange('name', e.target.value)}
                  className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent" 
                  placeholder={formData.type === 'reward' ? '例如：校级一等奖学金' : '例如：迟到警告'}
                  required
                />
              </div>



              {/* 分类 */}
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  分类
                </label>
                <select 
                  value={formData.category}
                  onChange={(e) => handleInputChange('category', e.target.value)}
                  className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent"
                >
                  {getCategoryOptions().map(option => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* 描述 */}
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  详细描述 <span className="text-red-500">*</span>
                </label>
                <textarea 
                  value={formData.description}
                  onChange={(e) => handleInputChange('description', e.target.value)}
                  className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent" 
                  rows={3} 
                  placeholder="请详细描述奖惩的原因、经过等信息"
                  required
                />
              </div>

              {/* 日期 */}
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  发生日期 <span className="text-red-500">*</span>
                </label>
                <input 
                  type="date" 
                  value={formData.date}
                  onChange={(e) => handleInputChange('date', e.target.value)}
                  className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent"
                  max={new Date().toISOString().split('T')[0]}
                  required
                />
              </div>

              {/* 提示信息 */}
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                <p className="text-sm text-blue-700">
                  <i className="fas fa-info-circle mr-1"></i>
                  请确保填写的奖惩信息真实准确，奖励和惩罚记录将纳入学生的综合素质评价。
                </p>
              </div>
            </div>

            <div className="flex items-center justify-end space-x-3 mt-6 pt-6 border-t border-border-light">
              <button 
                type="button"
                onClick={onCancel}
                className="px-4 py-2 border border-border-light text-text-primary rounded-lg hover:bg-gray-50 transition-colors"
              >
                取消
              </button>
              <button 
                type="submit"
                className="px-4 py-2 bg-secondary text-white rounded-lg hover:bg-accent transition-colors"
              >
                {reward ? '更新' : '保存'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default RewardPunishmentForm;