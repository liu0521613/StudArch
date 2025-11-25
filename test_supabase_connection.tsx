import React, { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';

interface TestResult {
  status: 'success' | 'error' | 'loading';
  message: string;
  data?: any;
}

const TestSupabaseConnection: React.FC = () => {
  const [envStatus, setEnvStatus] = useState<TestResult>({ status: 'loading', message: '检查环境变量...' });
  const [connectionStatus, setConnectionStatus] = useState<TestResult>({ status: 'loading', message: '测试数据库连接...' });
  const [saveStatus, setSaveStatus] = useState<TestResult>({ status: 'idle', message: '' });

  useEffect(() => {
    testEnvironment();
  }, []);

  const testEnvironment = () => {
    console.log('Testing environment variables...');
    
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
    
    console.log('Environment variables:', {
      supabaseUrl: supabaseUrl ? 'set' : 'not set',
      supabaseKey: supabaseKey ? 'set' : 'not set'
    });

    if (supabaseUrl && supabaseKey) {
      setEnvStatus({
        status: 'success',
        message: `环境变量配置正确`,
        data: {
          url: supabaseUrl.substring(0, 30) + '...',
          keySet: !!supabaseKey
        }
      });
      testConnection(supabaseUrl, supabaseKey);
    } else {
      setEnvStatus({
        status: 'error',
        message: '环境变量缺失，请检查 .env 文件'
      });
    }
  };

  const testConnection = async (url: string, key: string) => {
    try {
      const supabase = createClient(url, key);
      
      const { data, error } = await supabase
        .from('reward_punishments')
        .select('count')
        .limit(1);

      if (error) {
        setConnectionStatus({
          status: 'error',
          message: `数据库连接失败: ${error.message}`,
          data: error
        });
      } else {
        setConnectionStatus({
          status: 'success',
          message: '数据库连接成功',
          data: { count: data?.length || 0 }
        });
      }
    } catch (err: any) {
      setConnectionStatus({
        status: 'error',
        message: `连接异常: ${err.message}`,
        data: err
      });
    }
  };

  const testSave = async () => {
    setSaveStatus({ status: 'loading', message: '正在测试保存功能...' });

    try {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL!;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      // 获取学生ID
      const { data: students, error: studentError } = await supabase
        .from('student_profiles')
        .select('id')
        .limit(1);

      if (studentError || !students || students.length === 0) {
        setSaveStatus({
          status: 'error',
          message: '获取学生ID失败'
        });
        return;
      }

      const studentId = students[0].id;
      
      // 测试保存
      const testData = {
        student_id: studentId,
        type: 'reward' as const,
        name: '前端测试保存',
        level: 'school' as const,
        category: '测试',
        description: '这是通过测试页面创建的奖惩记录',
        date: '2024-01-15',
        created_by: 'test-user',
        status: 'pending' as const
      };

      const { data, error } = await supabase
        .from('reward_punishments')
        .insert(testData)
        .select()
        .single();

      if (error) {
        setSaveStatus({
          status: 'error',
          message: `保存失败: ${error.message}`,
          data: error
        });
      } else {
        setSaveStatus({
          status: 'success',
          message: '保存成功！',
          data: data
        });

        // 5秒后自动清理
        setTimeout(() => {
          cleanupTest(data.id);
        }, 5000);
      }
    } catch (err: any) {
      setSaveStatus({
        status: 'error',
        message: `保存异常: ${err.message}`,
        data: err
      });
    }
  };

  const cleanupTest = async (id: string) => {
    try {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL!;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      await supabase
        .from('reward_punishments')
        .delete()
        .eq('id', id);

      setSaveStatus({
        status: 'success',
        message: '保存成功，测试数据已自动清理'
      });
    } catch (err: any) {
      console.error('Cleanup failed:', err);
    }
  };

  const getStatusColor = (status: TestResult['status']) => {
    switch (status) {
      case 'success': return '#d4edda';
      case 'error': return '#f8d7da';
      case 'loading': return '#d1ecf1';
      default: return '#f8f9fa';
    }
  };

  const getStatusTextColor = (status: TestResult['status']) => {
    switch (status) {
      case 'success': return '#155724';
      case 'error': return '#721c24';
      case 'loading': return '#0c5460';
      default: return '#383d41';
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '50px auto', padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>🔧 奖惩系统连接测试</h1>
      
      <div style={{ margin: '20px 0' }}>
        <h2>1. 环境变量检查</h2>
        <div style={{
          padding: '15px',
          borderRadius: '5px',
          backgroundColor: getStatusColor(envStatus.status),
          color: getStatusTextColor(envStatus.status)
        }}>
          <strong>{envStatus.status === 'loading' ? '⏳' : envStatus.status === 'success' ? '✅' : '❌'} {envStatus.message}</strong>
          {envStatus.data && (
            <pre style={{ marginTop: '10px', fontSize: '12px' }}>
              {JSON.stringify(envStatus.data, null, 2)}
            </pre>
          )}
        </div>
      </div>

      <div style={{ margin: '20px 0' }}>
        <h2>2. 数据库连接测试</h2>
        <div style={{
          padding: '15px',
          borderRadius: '5px',
          backgroundColor: getStatusColor(connectionStatus.status),
          color: getStatusTextColor(connectionStatus.status)
        }}>
          <strong>{connectionStatus.status === 'loading' ? '⏳' : connectionStatus.status === 'success' ? '✅' : '❌'} {connectionStatus.message}</strong>
          {connectionStatus.data && (
            <pre style={{ marginTop: '10px', fontSize: '12px' }}>
              {JSON.stringify(connectionStatus.data, null, 2)}
            </pre>
          )}
        </div>
      </div>

      <div style={{ margin: '20px 0' }}>
        <h2>3. 保存功能测试</h2>
        <button 
          onClick={testSave}
          disabled={saveStatus.status === 'loading'}
          style={{
            padding: '10px 20px',
            backgroundColor: '#007bff',
            color: 'white',
            border: 'none',
            borderRadius: '5px',
            cursor: saveStatus.status === 'loading' ? 'not-allowed' : 'pointer',
            marginBottom: '10px'
          }}
        >
          {saveStatus.status === 'loading' ? '测试中...' : '测试保存奖惩记录'}
        </button>
        
        {saveStatus.message && (
          <div style={{
            padding: '15px',
            borderRadius: '5px',
            backgroundColor: getStatusColor(saveStatus.status),
            color: getStatusTextColor(saveStatus.status)
          }}>
            <strong>{saveStatus.status === 'loading' ? '⏳' : saveStatus.status === 'success' ? '✅' : '❌'} {saveStatus.message}</strong>
            {saveStatus.data && (
              <pre style={{ marginTop: '10px', fontSize: '12px' }}>
                {JSON.stringify(saveStatus.data, null, 2)}
              </pre>
            )}
          </div>
        )}
      </div>

      <div style={{ margin: '40px 0', padding: '20px', backgroundColor: '#f8f9fa', borderRadius: '5px' }}>
        <h3>🔍 调试说明</h3>
        <ol>
          <li>检查环境变量是否正确配置（以 VITE_ 开头）</li>
          <li>确认数据库连接是否正常</li>
          <li>测试实际的保存功能是否工作</li>
          <li>打开浏览器控制台查看详细日志</li>
        </ol>
        <p><strong>如果保存成功，说明环境问题已解决。</strong></p>
        <p><strong>如果仍然失败，请查看控制台的错误信息。</strong></p>
      </div>
    </div>
  );
};

export default TestSupabaseConnection;