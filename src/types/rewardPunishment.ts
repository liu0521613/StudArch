export interface RewardPunishment {
  id: string;
  student_id: string;
  type: 'reward' | 'punishment';
  name: string;
  level: 'school' | 'province' | 'country' | 'department' | 'class';
  category?: string;
  description: string;
  date: string;
  created_by: string;
  created_at: string;
  updated_at?: string;
  reviewed_by?: string;
  reviewed_at?: string;
  status?: 'pending' | 'approved' | 'rejected';
}

export interface RewardPunishmentCreate {
  student_id: string;
  type: 'reward' | 'punishment';
  name: string;
  level: 'school' | 'province' | 'country' | 'department' | 'class';
  category?: string;
  description: string;
  date: string;
  created_by: string;
}

export interface RewardPunishmentUpdate {
  name?: string;
  level?: 'school' | 'province' | 'country' | 'department' | 'class';
  category?: string;
  description?: string;
  date?: string;
  status?: 'pending' | 'approved' | 'rejected';
}

export interface RewardPunishmentListResponse {
  items: RewardPunishment[];
  total: number;
  page: number;
  limit: number;
}

export interface RewardPunishmentFilters {
  type?: 'reward' | 'punishment';
  level?: 'school' | 'province' | 'country' | 'department' | 'class';
  category?: string;
  status?: 'pending' | 'approved' | 'rejected';
  date_from?: string;
  date_to?: string;
  page?: number;
  limit?: number;
}