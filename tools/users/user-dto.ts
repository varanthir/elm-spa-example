import { Data } from '../utils'

export type UserDto = Readonly<{
  id: number,
  username: string,
  password: string,
  createdAt: string, // Date string
}>

export class User {
  static create({ id, username, password, createdAt }: UserDto | User): User {
    return new User(id, username, password, new Date(createdAt))
  }

  private constructor (
    public readonly id: number,
    public readonly username: string,
    public readonly password: string,
    public readonly createdAt: Date,
  ) {}
}

export class SafeUser {
  static create({ id, username, createdAt }: SafeUser): SafeUser {
    return new SafeUser(id, username, new Date(createdAt))
  }

  private constructor (
    public readonly id: number,
    public readonly username: string,
    public readonly createdAt: Date,
  ) {}
}

export class UpdatePasswordData {
  static create({ password, newPassword }: UpdatePasswordData): UpdatePasswordData {
    return new UpdatePasswordData(password, newPassword)
  }

  private constructor (
    public readonly password: string,
    public readonly newPassword: string,
  ) {}
}

export type CreateUser = Pick<User, 'username' | 'password'>
export type UserCredentials = Pick<User, 'username' | 'password'>
export type UserData = Data<User>
