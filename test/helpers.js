const os = require('bare-os')

exports.isCI = !!os.getEnv('CI')

exports.waitForPoweredOn = async function waitForPoweredOn(emitter) {
  await new Promise((resolve) => {
    emitter.on('stateChange', (state) => {
      if (state === 'poweredOn') resolve()
    })
  })
}
