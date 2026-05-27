import { UserModel } from "../models/user.models";

export interface IUserRepository {
  getUserById(id: string): Promise<UserModel | null>;
  getUserByEmail(email: string): Promise<UserModel | null>;
  createUser(user: UserModel): Promise<void>;
  updateUser(id: string, user: Partial<UserModel>): Promise<void>;
}
