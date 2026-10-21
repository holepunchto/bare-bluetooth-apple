const path = require('path')

module.exports = function build({ device }) {
  let signing = {}

  try {
    signing = require('./signing.json')
  } catch {}

  const { identity, provisioningProfile } = signing

  const options = {
    identifier: 'to.holepunch.bare.bluetooth.test',
    infoPlist: path.join(__dirname, 'Info.plist'),
    sign: identity !== undefined,
    identity
  }

  if (device.platform === 'ios') {
    return { ...options, sign: provisioningProfile !== undefined, provisioningProfile }
  }

  return options
}
