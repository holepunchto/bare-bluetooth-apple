const os = require('bare-os')
const { spawnSync } = require('bare-subprocess')

exports.isCI = !!os.getEnv('CI')

// Threads no longer inherit the module protocol, so teardown-on-exit
// scenarios need a real child process.
exports.runFixture = function runFixture(file) {
  return spawnSync(os.execPath(), [file]).status
}

exports.waitForPoweredOn = async function waitForPoweredOn(emitter) {
  await new Promise((resolve) => {
    emitter.on('stateChange', (state) => {
      if (state === 'poweredOn') resolve()
    })
  })
}
