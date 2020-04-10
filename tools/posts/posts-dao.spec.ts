import { PostsDao } from './posts-dao'
import { Post } from './post-dto'
import { noop } from '../utils'

describe('PostsDao', () => {
  const userId = 9876
  let postsDao: PostsDao
  let createdPost: Post

  beforeAll(() => {
    postsDao = new PostsDao(noop, true)
  })

  afterAll(() => {
    postsDao.onDestroy()
  })

  it('should create new post', () => {
    const postData = { title: 'Post 1', content: 'Content 1', userId }
    createdPost = postsDao.create(postData)
    const { title, content } = createdPost
    expect({ title, content, userId: createdPost.userId }).toEqual(postData)
  })

  it('should get created post', () => {
    expect(postsDao.get(createdPost.id)).toEqual(createdPost)
  })

  it('should get all posts', () => {
    const posts = postsDao.getAll()
    const post = posts.find(p => createdPost.id === p.id)
    expect(posts.length).toBeGreaterThanOrEqual(1)
    expect(post).toEqual(createdPost)
  })

  it('should get all posts for specified user', () => {
    const allPosts = postsDao.getAll()
    const userPosts = postsDao.getAll(userId)
    expect(allPosts.filter(post => post.userId === userId)).toEqual(userPosts)
  })

  it('should update post', () => {
    const title = 'Title 1a'
    const content = 'Content 1a'
    postsDao.update(createdPost.id, { title, content })
    const updatedPost = postsDao.get(createdPost.id)
    expect(updatedPost?.title).toBe(title)
    expect(updatedPost?.content).toBe(content)
  })

  it('should delete existing post', () => {
    const result = postsDao.delete(createdPost.id)
    const post = postsDao.getAll().find(p => createdPost.id === p.id)
    expect(result).toBeTrue()
    expect(post).toBeUndefined()
  })
})
