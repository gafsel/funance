export enum CategoryType {
  income = "income",
  expense = "expense",
  both = "both",
}

export interface CategoryModel {
  id: string;
  name: string;
  icon: string;
  color: string;
  type: CategoryType;
  isDeleted: boolean;
}
