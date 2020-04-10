type SessionObject = Readonly<{
  access_token: string
  refresh_token: string
  expires: number
}>

export class Session {
  static create({ access_token, refresh_token, expires }: SessionObject): Session {
    return new Session(access_token, refresh_token, expires);
  }

  public readonly token_type = 'bearer'

  private constructor(
    public readonly access_token: string,
    public readonly refresh_token: string,
    public readonly expires: number,
  ) {}
}
