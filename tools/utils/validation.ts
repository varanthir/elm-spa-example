import * as Joi from '@hapi/joi'

export const userCredentialsSchema = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required(),
})

export const postDataSchema = Joi.object({
  title: Joi.string().required(),
  content: Joi.string().required(),
})

export const updatePasswordDataSchema = Joi.object({
  password: Joi.string().required(),
  newPassword: Joi.string().required(),
})
