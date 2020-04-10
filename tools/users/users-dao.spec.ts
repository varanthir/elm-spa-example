import { UsersDao } from './users-dao'
import { User } from './user-dto'
import { noop } from '../utils'

describe('UsersDao', () => {
  let usersDao: UsersDao
  let createdUser: User

  beforeAll(() => {
    usersDao = new UsersDao(noop, true)
  })

  afterAll(() => {
    usersDao.onDestroy()
  })

  it('should create new user', () => {
    const userData = { username: 'Testjohn9876', password: 'Testpass9876' }
    createdUser = usersDao.create(userData)
    const { username, password } = createdUser
    expect({ username, password }).toEqual(userData)
  })

  it('should get created user', () => {
    expect(usersDao.get(createdUser.id)).toEqual(createdUser)
  })

  it('should get all users', () => {
    const users = usersDao.getAll()
    const user = users.find(u => createdUser.id === u.id)
    expect(users.length).toBeGreaterThanOrEqual(1)
    expect(user).toEqual(createdUser)
  })

  it('should find users by name', () => {
    const user = usersDao.findByName('john9876').find(u => createdUser.id === u.id)
    expect(user).toEqual(createdUser)
  })

  it('should update user', () => {
    const username = 'Testjohn9876a'
    const password = 'Testpass9876a'
    usersDao.update(createdUser.id, { username, password })
    const updatedUser = usersDao.get(createdUser.id)
    expect(updatedUser?.username).toBe(username)
    expect(updatedUser?.password).toBe(password)
  })

  it('should delete existing user', () => {
    const result = usersDao.delete(createdUser.id)
    const user = usersDao.getAll().find(u => createdUser.id === u.id)
    expect(result).toBeTrue()
    expect(user).toBeUndefined()
  })
})
