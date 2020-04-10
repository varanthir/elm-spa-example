import * as fs from 'fs'
import * as path from 'path'

import { AbstractDao } from '../utils'
import { User, UserDto, UserData } from './user-dto'


export class UsersDao extends AbstractDao<User> {
  private readonly _usersPath: string = path.resolve(__dirname, 'users.json')

  private _users = new Map<number, User>()
  private _idCounter = 0

  constructor(
    private readonly log: (message?: any, ...optionalParams: any[]) => void,
    private readonly inMemory = false,
  ) {
    super()
    if (!inMemory) {
      this.loadUsers()
    }
  }

  private loadUsers() {
    try {
      const rawUsers: UserDto[] = JSON.parse(fs.readFileSync(this._usersPath, { encoding: 'utf8' }))
      const users = rawUsers.map(User.create)
      this._users = users.reduce((acc, curr) => {
        acc.set(curr.id, curr)
        return acc
      }, new Map<number, User>())
      this._idCounter = Math.max(0, ...users.map(({ id }) => id))

      this.log('Users loaded.')
    } catch (error) {
      this.log(`Can't load users.`, error.message)
    }
  }

  onDestroy(): void {
    if (!this.inMemory) {
      this.saveUsers()
    }
  }

  private saveUsers(): void {
    try {
      const userArray = Array.from(this._users.values())
      fs.writeFileSync(this._usersPath, JSON.stringify(userArray, null, 2), { encoding: 'utf8' })
      this.log('Users saved.')
    } catch (error) {
      this.log(`Can't save users.`, error.message)
    }
  }

  get(userId: number): User | null {
    return this._users.get(userId) || null
  }

  getAll(): User[] {
    return Array.from(this._users.values())
  }

  findByName(name: string): User[] {
    return Array.from(this._users.values())
      .filter(user => user.username.toLowerCase().includes(name.toLowerCase()))
  }

  create(userData: UserData): User {
    this._idCounter += 1

    const newUser = User.create({
      ...userData,
      id: this._idCounter,
      createdAt: new Date()
    })

    this._users.set(newUser.id, newUser)

    return newUser
  }

  update(userId: number, userData: Partial<UserData>): User | null {
    const user = this._users.get(userId) || null

    if (user) {
      const updatedUser = User.create({ ...user, ...userData })
      this._users.set(userId, updatedUser)

      return updatedUser
    }

    return null
  }

  delete(userId: number): boolean {
    return this._users.delete(userId)
  }
}
