const PeripheralManager = require('../../lib/peripheral-manager')

Bare.on('exit', () => {
  const server = new PeripheralManager()

  server.on('error', (err) => {
    console.error('advertise error:', err.code, err.message)
  })

  server.startAdvertising()
})
