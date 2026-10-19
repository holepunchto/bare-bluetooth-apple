const path = require('path')

const { IDENTITY, PROVISIONING_PROFILE } = process.env

module.exports = {
  sign: !!PROVISIONING_PROFILE,
  identity: IDENTITY,
  provisioningProfile: PROVISIONING_PROFILE,
  infoPlist: path.join(__dirname, 'Info.plist')
}
