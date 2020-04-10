import * as Status from 'http-status-codes'
import { ValidationError } from '@hapi/joi'
import { postDataSchema, Req, Res } from '../utils'
import { PostsDao } from './posts-dao'
import { Post, CreatePostDto, UpdatePostDto } from './post-dto'

export class PostController {

  constructor(private readonly postsDao: PostsDao) {}

  readonly get = (req: Req, res: Res<Post | string>, userId: number) => {
    const postId = Number(req.params['postId'])
    const post = this.postsDao.get(postId)

    if (!post || post.userId !== userId) {
      res
        .status(Status.NOT_FOUND)
        .send(`Can't find post with id: ${postId}`)
      return
    }

    res.send(post)
  }

  readonly getAll = (req: Req, res: Res<Post[]>, userId: number): void => {
    const posts = this.postsDao.getAll(userId)
    res.send(posts)
  }

  readonly create = (req: Req<CreatePostDto>, res: Res<Post | ValidationError | string>, userId: number): void => {
    const { value, error, errors, warning } = postDataSchema.validate(req.body)

    if (error || errors || warning) {
      res
        .status(Status.BAD_REQUEST)
        .send(error || errors || warning || 'Something went wrong')
      return 
    }
  
    const postData: CreatePostDto = value
    const createdPost = this.postsDao.create({ ...postData, userId })
    res.send(createdPost)
  }

  readonly update = (req: Req<UpdatePostDto>, res: Res<Post | ValidationError | string>, userId: number) => {
    const postId = Number(req.params['postId'])
    const post = this.postsDao.get(postId)

    if (!post || post.userId !== userId) {
      res
        .status(Status.NOT_FOUND)
        .send(`Can't find post with id: ${postId}`)
      return
    }

    const { value, error, errors, warning } = postDataSchema.validate(req.body)

    if (error || errors || warning) {
      res
        .status(Status.BAD_REQUEST)
        .send(error || errors || warning || 'Something went wrong')
      return 
    }

    const postData: UpdatePostDto = value
    const updatedPost = this.postsDao.update(postId, postData)
  
    if (!updatedPost) {
      res.sendStatus(Status.NOT_FOUND)
      return
    }
  
    res.send(updatedPost)
  }

  readonly delete = (req: Req, res: Res<string>, userId: number) => {
    const postId = Number(req.params['postId'])
    const post = this.postsDao.get(postId)

    if (!post || post.userId !== userId) {
      res
        .status(Status.NOT_FOUND)
        .send(`Can't find post with id: ${postId}`)
      return
    }

    const deleted = this.postsDao.delete(postId)

    if (!deleted) {
      res
        .status(Status.NOT_FOUND)
        .send(`Can't find post with id: ${postId}`)
      return
    }

    res.sendStatus(Status.NO_CONTENT)
  }
}
