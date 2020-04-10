import { ValidationError } from '@hapi/joi'
import { Req, Res, userCredentialsSchema, Status, updatePasswordDataSchema } from '../utils'
import { UsersDao } from './users-dao'
import { SafeUser, CreateUser, UpdatePasswordData } from './user-dto'


export class UserController {

  constructor(private readonly usersDao: UsersDao) {}

  readonly get = (req: Req, res: Res<SafeUser | string>) => {
    const userId = Number(req.params['userId'])
    this.getUser(userId, res)
  }

  readonly getMe = (req: Req, res: Res<SafeUser | string>, userId: number) => {
    this.getUser(userId, res)
  }

  readonly getAll = (req: Req, res: Res<SafeUser[]>) => {
    const users = this.usersDao.getAll().map(SafeUser.create)
    res.send(users)
  }

  readonly create = (req: Req<CreateUser>, res: Res<SafeUser | ValidationError | string>) => {
    const { value, error, errors, warning } = userCredentialsSchema.validate(req.body)

    if (error || errors || warning) {
      res
        .status(Status.BAD_REQUEST)
        .send(error || errors || warning || 'Something went wrong')
      return
    }
  
    const userData = (value as CreateUser)

    if (this.usersDao.findByName(userData.username).length > 0) {
      res
        .status(Status.BAD_REQUEST)
        .send(`User with name: ${userData.username} already exists`)
      return
    }

    const createdUser = this.usersDao.create(userData)
    const safeCreatedUser = SafeUser.create(createdUser)
    res.send(safeCreatedUser)
  }

  readonly update = (req: Req<UpdatePasswordData>, res: Res<ValidationError | string>, userId: number) => {
    const user = this.usersDao.get(userId)

    if (!user) {
      res.sendStatus(Status.NOT_FOUND)
      return
    }

    const { value, error, errors, warning } = updatePasswordDataSchema.validate(req.body)
  
    if (error || errors || warning) {
      res
        .status(Status.BAD_REQUEST)
        .send(error || errors || warning || 'Something went wrong')
      return 
    }

    const updatePasswordData = UpdatePasswordData.create(value)

    if (user.password !== updatePasswordData.password) {
      res.sendStatus(Status.BAD_REQUEST)
      return 
    }

    const updatedUser = this.usersDao.update(user.id, { password: updatePasswordData.newPassword })

    if (!updatedUser) {
      res.sendStatus(Status.NOT_FOUND)
      return
    }

    res.sendStatus(Status.NO_CONTENT)
  }

  private getUser(userId: number, res: Res<SafeUser | string>): void {
    const user = this.usersDao.get(userId)

    if (!user) {
      res
        .status(Status.NOT_FOUND)
        .send(`Can't find user with id: ${userId}`)
      return
    }

    const safeUser = SafeUser.create(user)
    res.send(safeUser)
  }
}
