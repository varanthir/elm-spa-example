import { ValidationError } from '@hapi/joi'
import { Req, Res, Status, userCredentialsSchema } from '../utils'
import { UsersDao, UserCredentials } from '../users'
import { Session } from './session'
import { AuthDao } from './auth-dao'

type Handler<ReqBody, ResBody> = (req: Req<ReqBody>, res: Res<ResBody>, userId: number) => void

export class AuthController {

  constructor(
    private readonly usersDao: UsersDao,
    private readonly authDao: AuthDao,
  ) {}

  readonly refresh = (req: Req<{ refresh_token: string }>, res: Res<Session>): void => {
    const { refresh_token } = req.body
    const session = this.authDao.refresh(refresh_token)

    if (!session) {
      res.sendStatus(Status.UNAUTHORIZED)
      return
    }

    res.send(session)
  }

  readonly login = (req: Req, res: Res<Session | ValidationError | string>): void => {
    const { value, error, errors, warning } = userCredentialsSchema.validate(req.body)
    if (error || errors || warning) {
      res
        .status(Status.BAD_REQUEST)
        .send(error || errors || warning || 'Something went wrong')
      return
    }

    const userCredentials = value as UserCredentials
    const user = this.usersDao.findByName(userCredentials.username)[0] || null
    if (
      user
        && user.username === userCredentials.username
        && user.password === userCredentials.password
    ) {  
      const session = this.authDao.create(user.id)
      res.send(session)
      return
    }

    res
      .status(Status.UNAUTHORIZED)
      .send(`Username and password don't match`)
  }

  readonly logout = (req: Req, res: Res): void => {
    const accessToken = req.header('authorization')?.replace('Bearer ', '') || ''
    const userId = this.authDao.getUserId(accessToken)
  
    if (userId === null) {
      res.sendStatus(Status.UNAUTHORIZED)
      return
    }

    this.authDao.revoke(accessToken)
    res.sendStatus(Status.NO_CONTENT)
  }

  readonly withAuth = <ReqBody, ResBody>(handler: Handler<ReqBody, ResBody>) =>
    (req: Req<ReqBody>, res: Res<ResBody>): void => {
      const accessToken = req.header('authorization')?.replace('Bearer ', '') || ''
      const userId = this.authDao.getUserId(accessToken)
    
      if (userId === null) {
        res.sendStatus(Status.UNAUTHORIZED)
        return
      }

      handler(req, res, userId)
    }
}
