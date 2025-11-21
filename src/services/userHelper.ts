// 用户帮助函数，解决 "user is not defined" 问题

/**
 * 安全获取用户信息
 * 在开发环境下提供默认值，避免 "user is not defined" 错误
 */
export async function safeGetUser() {
  try {
    // 检查是否在浏览器环境
    if (typeof window === 'undefined') {
      return { user: null, error: '不在浏览器环境' };
    }

    // 模拟模式检测
    const isMockMode = !import.meta.env.VITE_SUPABASE_URL || 
                      import.meta.env.VITE_SUPABASE_URL.includes('your-project-ref') ||
                      import.meta.env.VITE_SUPABASE_URL.includes('demo.supabase.co');

    if (isMockMode) {
      console.log('检测到模拟模式，返回模拟用户');
      return { 
        user: {
          id: '550e8400-e29b-41d4-a716-446655440001',
          email: 'mock@example.com',
          role: 'teacher'
        }, 
        error: null 
      };
    }

    // 真实 Supabase 环境
    const { supabase } = await import('../lib/supabase');
    const { data, error } = await supabase.auth.getUser();
    
    if (error) {
      console.warn('获取用户信息失败，使用默认值:', error.message);
      return { user: null, error: error.message };
    }
    
    return { user: data?.user || null, error: null };
  } catch (error) {
    console.error('获取用户信息时出错:', error);
    return { 
      user: null, 
      error: error instanceof Error ? error.message : '未知错误' 
    };
  }
}

/**
 * 安全获取用户ID
 * 返回字符串或null，确保不会出现 undefined
 */
export async function safeGetUserId(): Promise<string | null> {
  const { user, error } = await safeGetUser();
  
  if (error || !user) {
    console.warn('无法获取用户ID，返回null:', error);
    return null;
  }
  
  return user.id || null;
}

/**
 * 获取用户信息的工具函数
 * 提供多种回退机制
 */
export function getUserInfoFromStorage() {
  try {
    // 尝试从 localStorage 获取
    if (typeof window !== 'undefined') {
      const userInfo = localStorage.getItem('user_info');
      if (userInfo) {
        const user = JSON.parse(userInfo);
        return user;
      }
    }
  } catch (error) {
    console.warn('从 localStorage 获取用户信息失败:', error);
  }
  
  // 返回默认用户信息
  return {
    id: '550e8400-e29b-41d4-a716-446655440001',
    email: 'fallback@example.com',
    role: 'teacher'
  };
}

/**
 * 确保用户变量总是有值
 */
export function ensureUserDefined() {
  // 检查是否在浏览器环境
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    // 尝试从全局获取
    if (typeof window !== 'undefined' && (window as any).user) {
      return (window as any).user;
    }
    
    // 从 localStorage 获取
    return getUserInfoFromStorage();
  } catch (error) {
    console.warn('确保用户定义时出错:', error);
    return null;
  }
}

// 默认导出
export default {
  safeGetUser,
  safeGetUserId,
  getUserInfoFromStorage,
  ensureUserDefined
};