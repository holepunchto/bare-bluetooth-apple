const os = require('bare-os')

exports.isCI = !!os.getEnv('CI')

exports.waitForPoweredOn = async function waitForPoweredOn(emitter) {
  await new Promise((resolve) => {
    emitter.on('stateChange', (state) => {
      if (state === 'poweredOn') resolve()
    })
  })
}

exports.hexdump = function hexdump(data) {
  const hex = Array.from(data)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join(' ')
  const ascii = Array.from(data)
    .map((b) => (b >= 0x20 && b < 0x7f ? String.fromCharCode(b) : '.'))
    .join('')
  return data.length + ' bytes: [' + hex + '] "' + ascii + '"'
}
