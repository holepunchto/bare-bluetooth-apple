const os = require('bare-os')

exports.isCI = !!os.getEnv('CI')

const FATAL = ['poweredOff', 'unauthorized', 'unsupported']

exports.waitForPoweredOn = async function waitForPoweredOn(emitter) {
  await new Promise((resolve, reject) => {
    emitter.on('stateChange', (state) => {
      if (state === 'poweredOn') resolve()
      else if (FATAL.includes(state)) reject(new Error('Bluetooth is ' + state))
    })
  })
}

exports.waitForEvent = function waitForEvent(emitter, name, timeout) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      emitter.off(name, onevent)
      resolve(null)
    }, timeout)

    emitter.once(name, onevent)

    function onevent(...args) {
      clearTimeout(timer)
      resolve(args)
    }
  })
}
