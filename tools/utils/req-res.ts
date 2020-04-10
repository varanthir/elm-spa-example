
import { ParamsDictionary, Request, Response }  from 'express-serve-static-core'

export type Req<T = never> = Request<ParamsDictionary, never, T>
export type Res<T = never> = Response<T>
