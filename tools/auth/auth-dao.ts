import * as Jwt from 'jsonwebtoken'
import * as uuid4 from 'uuid/v4'
import { Session } from './session'

const SECRET = '50m3-s3cr5t-p455w0rd'

export class AuthDao  {

  private _revokedTokens = new Set<string>()
  private _accessToRefreshMap = new Map<string, string>() // < accesToken, refreshToken >

  constructor(
    private readonly refreshTokenExpirationTime: number, // seconds
    private readonly accessTokenExpirationTime: number, // seconds
  ) {}

  getUserId(accessToken: string): number | null {
    if (this._revokedTokens.has(accessToken)) {
      return null
    }

    try {
      return (Jwt.verify(accessToken, SECRET) as { data: { userId: number } }).data.userId
    } catch (error) {
      return null
    }
  }

  create(userId: number): Session {
    const issuedAt = Math.floor(Date.now() / 1000) // Seconds Since the Epoch

    const access_token = Jwt.sign(
      {
        iat: issuedAt,
        exp: issuedAt + this.accessTokenExpirationTime,
        data: { userId, uuid: uuid4() }
      },
      SECRET
    )

    const refresh_token = Jwt.sign(
      {
        iat: issuedAt,
        exp: issuedAt + this.refreshTokenExpirationTime,
        data: { userId, uuid: uuid4() }
      },
      SECRET
    )

    this._accessToRefreshMap.set(access_token, refresh_token)

    return Session.create({
      access_token,
      refresh_token,
      expires: this.accessTokenExpirationTime,
    })
  }

  refresh(refresh_token: string): Session | null {
    if (this._revokedTokens.has(refresh_token)) {
      return null
    }

    try {
      const { userId } = (Jwt.verify(refresh_token, SECRET) as { data: { userId: number } }).data
      const issuedAt = Math.floor(Date.now() / 1000) // Seconds Since the Epoch
      const expires = issuedAt + this.accessTokenExpirationTime

      const access_token = Jwt.sign(
        {
          iat: issuedAt,
          exp: expires,
          data: { userId, uuid: uuid4() }
        },
        SECRET
      )

      this._accessToRefreshMap.set(access_token, refresh_token)

      return Session.create({
        access_token,
        refresh_token,
        expires,
      })
    } catch (error) {
      return null
    }
  }

  revoke(accessToken: string): void {
    const refreshToken = this._accessToRefreshMap.get(accessToken)

    if (refreshToken) {
      this._accessToRefreshMap.forEach((refreshToken_, accessToken_) => {
        if (refreshToken_ === refreshToken) {
          this._revokedTokens.add(accessToken_)
        }
      })

      this._revokedTokens.add(refreshToken)
    }

    this._revokedTokens.add(accessToken)
    this.removeExpired()
  }

  private removeExpired(): void {
    this._revokedTokens.forEach(revokedToken => {
      try {
        Jwt.verify(revokedToken, SECRET)
      } catch (error) {
        if (error === Jwt.TokenExpiredError) {
          this._revokedTokens.delete(revokedToken)
        }
      }
    })
  }
}
