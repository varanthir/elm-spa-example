import Jasmine = require('jasmine')

const jasmine = new Jasmine({})

jasmine.loadConfig({
  random: false,
  failFast: true,
  spec_dir: '.',
  spec_files: [
    '**/*.spec.ts',
  ],
})

jasmine.execute()
