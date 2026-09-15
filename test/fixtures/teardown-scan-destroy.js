const Central = require('../../lib/central')

Bare.on('exit', () => {
  const central = new Central()
  central.startScan()
  central.destroy()
})
