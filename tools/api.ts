import { Server } from 'http'
import * as express from 'express'
import * as bodyParser from 'body-parser'

import { UsersDao, UserController } from './users'
import { PostsDao, PostController } from './posts'
import { AuthController, AuthDao } from './auth'
import { noop } from './utils'

export type ApiConfig = Readonly<{
  refreshTokenExp: number // seconds
  accessTokenExp: number // seconds
  simulateDelay: boolean
  inMemory: boolean
  log: (message?: any, ...optionalParams: any[]) => void
}>

const defaultConfig: ApiConfig = {
  refreshTokenExp: 24 * 60 * 60, // 1d
  accessTokenExp: 60 * 60, // 1h
  simulateDelay: true,
  inMemory: false,
  log: console.log
}

export class Api {
  private readonly postsDao: PostsDao
  private readonly usersDao: UsersDao
  private readonly authDao: AuthDao

  private readonly auth: AuthController
  private readonly postController: PostController
  private readonly userController: UserController

  private readonly app: express.Express
  private server: Server | null = null

  constructor(config: Partial<ApiConfig> = {}) {
    const {
      refreshTokenExp,
      accessTokenExp,
      simulateDelay,
      inMemory,
      log,
    } = { ...defaultConfig, ...config }

    this.postsDao = new PostsDao(log, inMemory)
    this.usersDao = new UsersDao(log, inMemory)
    this.authDao = new AuthDao(refreshTokenExp, accessTokenExp)

    this.auth = new AuthController(this.usersDao, this.authDao)
    this.postController = new PostController(this.postsDao)
    this.userController = new UserController(this.usersDao)

    this.app = express()

    // MIDDLEWARES
    this.app.use(bodyParser.json())

    if (simulateDelay) {
      this.app.use((req, res, next) => {
        setTimeout(() => {
          next()
          log(`${req.method} ${req.url} => ${res.statusCode} [${req.ip}, ${req.hostname}]`)
        }, this.random() + 100)
      })
    } else {
      this.app.use((req, res, next) => {
        next()
        log(`${req.method} ${req.url} => ${res.statusCode} [${req.ip}, ${req.hostname}]`)
      })
    }

    // ROUTES
    this.app.get('/', (req, res) => {
      res.send({ message: 'Hello world!' })
    })

    this.app.get('/auth-header', (req, res) => {
      const authToken = req.header('authorization')?.replace('Bearer ', '')
      res.send(authToken)
    })

    // Users
    this.app.get  ('/me',            this.auth.withAuth(this.userController.getMe))
    this.app.get  ('/users/:userId', this.auth.withAuth(this.userController.get))
    this.app.get  ('/users',         this.auth.withAuth(this.userController.getAll))
    this.app.post ('/users',         this.userController.create)
    this.app.patch('/users',         this.auth.withAuth(this.userController.update))

    // Posts
    this.app.get   ('/posts/:postId', this.auth.withAuth(this.postController.get))
    this.app.get   ('/posts',         this.auth.withAuth(this.postController.getAll))
    this.app.post  ('/posts',         this.auth.withAuth(this.postController.create))
    this.app.patch ('/posts/:postId', this.auth.withAuth(this.postController.update))
    this.app.delete('/posts/:postId', this.auth.withAuth(this.postController.delete))

    // Auth
    this.app.post('/refresh', this.auth.refresh)
    this.app.post('/login',   this.auth.login)
    this.app.post('/logout',  this.auth.withAuth(this.auth.logout))
  }

  open(port: number, cb = noop): void {
    this.server = this.app.listen(port, cb)
  }

  close(cb = noop): void {
    if (this.server && this.server.listening) {
      this.server.close()
      cb()
    }
  
    this.usersDao.onDestroy()
    this.postsDao.onDestroy()
  }

  private random(): number {
    return Math.round(Math.random() * 100) + 1
  }
}
