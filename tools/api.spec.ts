import * as axios from 'axios'
import { Api } from './api'
import { sleep } from './utils'

const getHeaders = (accessToken: string) => ({
  headers: { Authorization: `Bearer ${accessToken}` }
})

const mapErrorToStatus = (error: { response: { status: number }}) => Promise.reject(error.response.status)

describe('Api', () => {
  const refreshTokenExp = 2 // seconds
  const accessTokenExp = 1 // second
  const port = 9876
  const api = new Api({
    refreshTokenExp,
    accessTokenExp,
    simulateDelay: false,
    inMemory: true,
    log: () => {},
  })

  const get = (url: string, config?: axios.AxiosRequestConfig) =>
    axios.default.get(`http://localhost:${port}${url}`, config)

  const post = (url: string, data?: any, config?: axios.AxiosRequestConfig) =>
    axios.default.post(`http://localhost:${port}${url}`, data, config)

  beforeAll(() => api.open(port))
  afterAll(() => api.close())

  it('should return hello message', async () => {
    const response = await get('/')
    expect(typeof response.data.message).toBe('string')
  })

  it('should return auth token', async () => {
    const token = 's0m5-53cr3t-t0k3n'
    const headers = { Authorization: `Bearer ${token}` }
    const response = await get('/auth-header', { headers })
    expect(response.data).toBe(token)
  })

  describe('/refresh', () => {
    const userCredentials = {
      username: 'Testuser1',
      password: 'Testpass1',
    }

    it('should return new access token when previous is expired', async () => {
      await post('/users', userCredentials)
      const session = await post('/login', userCredentials)
      await sleep(accessTokenExp * 1000 + 1)
      await expectAsync(
        post('/refresh', { refresh_token: session.data.refresh_token })
      ).toBeResolved()
    })
  })

  describe('/logout', () => {
    const userCredentials = {
      username: 'Testuser2',
      password: 'Testpass2',
    }

    it('should revoke refresh token and all access tokens', async () => {
      await post('/users', userCredentials)
      const session1 = await post('/login', userCredentials)
      const session2 = await post('/refresh', {
        refresh_token: session1.data.refresh_token
      })

      await post('/logout', null, getHeaders(session1.data.access_token))

      await expectAsync(
        get('/me', getHeaders(session1.data.access_token)).catch(mapErrorToStatus)
      ).toBeRejectedWith(401)

      await expectAsync(
        get('/me', getHeaders(session2.data.access_token)).catch(mapErrorToStatus)
      ).toBeRejectedWith(401)

      await expectAsync(
        post('/refresh', { refresh_token: session1.data.refresh_token }).catch(mapErrorToStatus)
      ).toBeRejectedWith(401)
    })
  })
})
