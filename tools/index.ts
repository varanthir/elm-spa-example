import { Api } from './api'

const refreshTokenExp = 10 * 60 // seconds = 10 minutes
const accessTokenExp = 10 // seconds
const port = 3000

console.log(`\nThis is just example BE, DON'T USE IT ON PRODUCTION!\n`)

const api = new Api({
  refreshTokenExp,
  accessTokenExp,
})

function exit(signals: NodeJS.Signals) {
  console.log(`\nEXIT: ${signals}`)

  api.close(() => {
    console.log('Server stopped.')
  })

  process.exit()
}

process.on('SIGINT', exit)
process.on('SIGTERM', exit)

api.open(port, () => {
  console.log('START')
  console.log(`Server is listening on port ${port}...`)
})
