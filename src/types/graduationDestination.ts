export interface GraduationDestination {
  id: string;
  student_id: string;
  teacher_id?: string;
  destination_type: 'employment' | 'furtherstudy' | 'abroad' | 'entrepreneurship' | 'unemployed' | 'other';
  company_name?: string;
  position?: string;
  salary?: number;
  work_location?: string;
  school_name?: string;
  major?: string;
  degree?: string;
  abroad_country?: string;
  startup_name?: string;
  startup_role?: string;
  other_description?: string;
  status: 'pending' | 'approved' | 'rejected';
  review_comment?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  proof_files: string[];
  submit_time: string;
  batch_import_id?: string;
  created_at: string;
  updated_at: string;
  // 关联的学生信息
  student?: {
    student_number: string;
    full_name: string;
    class_name: string;
  };
}