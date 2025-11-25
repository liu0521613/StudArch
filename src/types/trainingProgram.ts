export interface TrainingProgramCourse {
  id: string;
  course_number: string;      // 课程号
  course_name: string;        // 课程名称
  credits: number;           // 学分
  recommended_grade: string;  // 建议修读年级
  semester: string;          // 学期
  exam_method: string;       // 考试方式
  course_nature: string;     // 课程性质
  created_at?: string;
  updated_at?: string;
}

export interface TrainingProgramImportResult {
  success: number;
  failed: number;
  total: number;
  errors?: Array<{
    row: number;
    error: string;
    data?: any;
  }>;
}