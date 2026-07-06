const os = require('bare-os')
const { spawnSync } = require('bare-subprocess')

exports.isCI = !!os.getEnv('CI')

const entry = require.resolve('../index.js')

exports.runTeardown = function runTeardown(setup) {
  const program = `
    const { Central, Peripheral, PeripheralManager } = require(${JSON.stringify(entry)})
    ${setup}
    Bare.exit(0)
  `

  return spawnSync(Bare.argv[0], ['-e', program], { encoding: 'utf8' })
}

exports.waitForPoweredOn = async function waitForPoweredOn(emitter) {
  await new Promise((resolve) => {
    emitter.on('stateChange', (state) => {
      if (state === 'poweredOn') resolve()
    })
  })
}
