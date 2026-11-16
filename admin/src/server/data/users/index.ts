import type { Page, QueryOf, Result, Schemas, StaffContext } from "../types";

export type UserRow = Schemas["AdminUserRow"];
export type UserDetail = Schemas["AdminUserDetail"];
export type UserHealth = Schemas["AdminUserHealth"];
export type UserActionInput = Schemas["AdminUserActionInput"];
export type UsersQuery = QueryOf<"adminListUsers">;

export interface UsersRepository {
  list(query: UsersQuery, ctx: StaffContext): Promise<Result<Page<UserRow>>>;
  get(id: string, ctx: StaffContext): Promise<Result<UserDetail>>;
  /** Données de santé : step-up, motif obligatoire, consultation journalisée par l'API. */
  revealHealth(id: string, reason: string, ctx: StaffContext): Promise<Result<UserHealth>>;
  action(id: string, input: UserActionInput, ctx: StaffContext): Promise<Result<UserDetail>>;
}
