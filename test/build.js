const path = require('path')

let signing = {}

try {
  signing = require('./signing.json')
} catch {}

module.exports = {
  sign: 'provisioningProfile' in signing,
  ...signing,
  infoPlist: path.join(__dirname, 'Info.plist')
}
