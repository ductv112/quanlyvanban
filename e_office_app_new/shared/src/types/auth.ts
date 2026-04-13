export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  user: UserInfo;
}

export interface UserInfo {
  staffId: number;
  unitId: number;
  departmentId: number;
  username: string;
  fullName: string;
  email: string;
  phone: string;
  image: string;
  positionName: string;
  departmentName: string;
  unitName: string;
  roles: string[];
}
