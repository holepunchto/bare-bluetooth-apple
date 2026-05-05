const { TextEncoder, TextDecoder } = require('bare-encoding')
const bluetooth = require('../../')

const SERVICE_UUID = '01230000-0000-1000-8000-00805F9B34FB'
const CHAR_UUID = '01230001-0000-1000-8000-00805F9B34FB'

const manager = new bluetooth.PeripheralManager()

let pingChar = null

manager.on('stateChange', (state) => {
  console.log('state:', state)

  if (state !== 'poweredOn') {
    return
  }

  pingChar = new bluetooth.Characteristic(CHAR_UUID, {
    write: true,
    notify: true
  })

  const service = new bluetooth.Service(SERVICE_UUID, [pingChar])
  manager.addService(service)
})

manager.on('serviceAdd', (uuid, error) => {
  if (error) {
    console.log('service add error:', error)
    return
  }

  console.log('service added')
  manager.startAdvertising({ name: 'Ping', serviceUUIDs: [SERVICE_UUID] })
  console.log('on client mac run `bare examples/ping-pong/client.js`')
})

manager.on('writeRequest', (requests) => {
  const data = requests[0].data
  console.log('received:', new TextDecoder().decode(data))

  manager.respondToRequest(requests[0], bluetooth.PeripheralManager.ATT_SUCCESS, null)

  const response = new TextEncoder().encode('pong: ' + new TextDecoder().decode(data))
  manager.updateValue(pingChar, response)
})

manager.on('subscribe', () => {
  console.log('client subscribed')
})

manager.on('unsubscribe', () => {
  console.log('client unsubscribed')
})

Bare.on('exit', () => {
  manager.stopAdvertising()
  manager.destroy()
})
