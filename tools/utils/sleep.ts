export const sleep = (ms: number): Promise<void> => {
  const seconds = ms / 1000
  console.log(`\n# sleep for ${seconds} seconds...`)
  return new Promise(resolve => setTimeout(resolve, ms))
}
