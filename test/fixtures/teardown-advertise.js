const PeripheralManager = require('../../lib/peripheral-manager')

Bare.on('exit', () => {
  const server = new PeripheralManager()
  server.startAdvertising()
})
