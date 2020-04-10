import { Data } from '../utils'

export type PostDto = Readonly<{
  id: number,
  title: string,
  content: string,
  userId: number,
  createdAt: string, // Date string
}>

export class Post {
  static create({ id, title, content, userId, createdAt }: PostDto | Post): Post {
    return new Post(id, title, content, userId, new Date(createdAt))
  }

  private constructor (
    public readonly id: number,
    public readonly title: string,
    public readonly content: string,
    public readonly userId: number,
    public readonly createdAt: Date,
  ) {}
}

export type CreatePostData = Data<Post>
export type CreatePostDto = Pick<PostDto, 'title' | 'content'>
export type UpdatePostDto = CreatePostDto
