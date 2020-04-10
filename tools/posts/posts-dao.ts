import * as fs from 'fs'
import * as path from 'path'
import { AbstractDao } from '../utils'
import { Post, PostDto, CreatePostData, UpdatePostDto } from './post-dto'

export class PostsDao extends AbstractDao<Post> {
  private readonly _postsPath: string = path.resolve(__dirname, 'posts.json')
  private _posts = new Map<number, Post>()
  private _idCounter = 0

  constructor(
    private readonly log: (message?: any, ...optionalParams: any[]) => void,
    private readonly inMemory = false,
  ) {
    super()
    if (!inMemory) {
      this.loadPosts()
    }
  }

  private loadPosts() {
    try {
      const rawPosts: PostDto[] = JSON.parse(fs.readFileSync(this._postsPath, { encoding: 'utf8' }))
      const posts = rawPosts.map(Post.create)
      this._posts = posts.reduce((acc, curr) => {
        acc.set(curr.id, curr)
        return acc
      }, new Map<number, Post>())
      this._idCounter = Math.max(0, ...posts.map(({ id }) => id))

      this.log('Posts loaded.')
    } catch (error) {
      this.log(`Can't load posts.`, error.message)
    }
  }

  onDestroy(): void {
    if (!this.inMemory) {
      this.savePosts()
    }
  }

  private savePosts(): void {
    try {
      const postArray = Array.from(this._posts.values())
      fs.writeFileSync(this._postsPath, JSON.stringify(postArray, null, 2), { encoding: 'utf8' })
      this.log('Posts saved.')
    } catch (error) {
      this.log(`Can't save posts.`, error.message)
    }
  }

  get(postId: number): Post | null {
    return this._posts.get(postId) || null
  }

  getAll(userId?: number): Post[] {
    const posts = Array.from(this._posts.values())
    return userId === undefined
      ? posts
      : posts.filter(post => post.userId === userId)
  }

  create(postData: CreatePostData): Post {
    this._idCounter += 1

    const newPost = Post.create({
      ...postData,
      id: this._idCounter,
      createdAt: new Date()
    })

    this._posts.set(newPost.id, newPost)
    return newPost
  }

  update(postId: number, postData: Partial<UpdatePostDto>): Post | null {
    const post = this._posts.get(postId) || null

    if (post) {
      const updatedPost = Post.create({ ...post, ...postData })
      this._posts.set(postId, updatedPost)
      return updatedPost
    }

    return null
  }

  delete(postId: number): boolean {
    return this._posts.delete(postId)
  }
}
