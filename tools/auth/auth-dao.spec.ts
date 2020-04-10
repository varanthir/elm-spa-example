import { AuthDao } from './auth-dao'
import { sleep } from '../utils'

describe('AuthDao', () => {
  const refreshExpTime = 2 // seconds
  const accessExpTime = 1 // seconds
  const userId = 1
  let authDao: AuthDao

  beforeEach(() => {
    authDao = new AuthDao(refreshExpTime, accessExpTime)
  })

  it('should verify created token', () => {
    const session = authDao.create(userId)
    expect(authDao.getUserId(session.access_token)).toBe(userId)
  })

  it('should revoke created token', () => {
    const session = authDao.create(userId)
    authDao.revoke(session.access_token)
    expect(authDao.getUserId(session.access_token)).toBe(null)
  })

  it(`should revoke access token after ${accessExpTime} seconds`, async () => {
    const session = authDao.create(userId)
    await sleep(accessExpTime * 1000 + 1)
    expect(authDao.getUserId(session.access_token)).toBe(null)
  })

  it(`should refresh access token after revoked`, async () => {
    const session = authDao.create(userId)
    await sleep(accessExpTime * 1000 + 1)
    const refreshedSession = authDao.refresh(session.refresh_token)
    expect(refreshedSession).toBeTruthy()
    expect(authDao.getUserId(refreshedSession!.access_token)).toBe(userId)
  })

  it(`should revoke refresh token after ${refreshExpTime} seconds`, async () => {
    const session = authDao.create(userId)
    await sleep(refreshExpTime * 1000 + 1)
    expect(authDao.getUserId(session.access_token)).toBe(null)
  })
})
