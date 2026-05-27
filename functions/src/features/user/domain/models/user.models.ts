export interface UserModel {
  id: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  createdAt: Date;
  lastLogin?: Date;
}
