const { TextEncoder, TextDecoder } = require('bare-encoding')
const bluetooth = require('../../')

const SERVICE_UUID = '01230000-0000-1000-8000-00805F9B34FB'
const CHAR_READ_UUID = '01230000-0001-1000-8000-00805F9B34FB'
const CHAR_WRITE_UUID = '01230000-0002-1000-8000-00805F9B34FB'
const CHAR_NOTIFY_UUID = '01230000-0003-1000-8000-00805F9B34FB'
const CHAR_PSM_UUID = '01230000-0004-1000-8000-00805F9B34FB'

const server = new bluetooth.Server()

let notifyCounter = 0
let notifyInterval = null
let l2capPsm = null
let psmCharacteristic = null
const subscribedCentrals = new Set()

server.on('stateChange', (state) => {
  console.log('state:', state)

  if (state !== 'poweredOn') {
    console.log('waiting for poweredOn...')
    return
  }

  const readChar = new bluetooth.Characteristic(CHAR_READ_UUID, {
    read: true,
    value: new Uint8Array([0x48, 0x65, 0x6c, 0x6c, 0x6f])
  })

  const writeChar = new bluetooth.Characteristic(CHAR_WRITE_UUID, {
    write: true,
    writeWithoutResponse: true
  })

  const notifyChar = new bluetooth.Characteristic(CHAR_NOTIFY_UUID, {
    read: true,
    notify: true
  })

  psmCharacteristic = new bluetooth.Characteristic(CHAR_PSM_UUID, {
    read: true
  })

  const service = new bluetooth.Service(SERVICE_UUID, [
    readChar,
    writeChar,
    notifyChar,
    psmCharacteristic
  ])

  server.addService(service)

  server.on('serviceAdd', (uuid, error) => {
    if (error) {
      console.log('failed to add service:', error)
      return
    }

    console.log('service added:', uuid)

    server.publishChannel()
  })

  server.on('channelPublish', (psm, error) => {
    if (error) {
      console.log('failed to publish L2CAP channel:', error)
      return
    }

    l2capPsm = psm
    console.log('L2CAP channel published, PSM:', psm)

    server.startAdvertising({
      name: 'BareTest',
      serviceUUIDs: [SERVICE_UUID]
    })

    console.log('service UUID:', SERVICE_UUID)
    console.log('on the client run `bare examples/full-test/client.js`')
  })

  server.on('readRequest', (request) => {
    console.log('read request for:', request.characteristicUuid, 'offset:', request.offset)

    let value = null

    if (request.characteristicUuid === CHAR_NOTIFY_UUID) {
      value = new Uint8Array([notifyCounter & 0xff])
    } else if (request.characteristicUuid === CHAR_PSM_UUID) {
      if (l2capPsm !== null) {
        value = new Uint8Array([l2capPsm & 0xff, (l2capPsm >> 8) & 0xff])
      } else {
        value = new Uint8Array([0, 0])
      }
    }

    if (value && request.offset > 0) {
      value = value.slice(request.offset)
    }

    server.respondToRequest(request, bluetooth.Server.ATT_SUCCESS, value)
  })

  server.on('writeRequest', (requests) => {
    for (const request of requests) {
      console.log('write request for:', request.characteristicUuid)
      console.log('data:', request.data)
      console.log('as string:', new TextDecoder().decode(request.data))
    }

    server.respondToRequest(requests[0], bluetooth.Server.ATT_SUCCESS, null)
  })

  server.on('subscribe', (centralHandle, characteristicUuid) => {
    console.log('central subscribed to:', characteristicUuid)
    subscribedCentrals.add(centralHandle)

    if (!notifyInterval && characteristicUuid === CHAR_NOTIFY_UUID) {
      notifyInterval = setInterval(() => {
        notifyCounter = (notifyCounter + 1) % 256
        const value = new Uint8Array([notifyCounter])

        const sent = server.updateValue(notifyChar, value)
        if (sent) {
          console.log('notification sent:', notifyCounter)
        } else {
          console.log('notification queued (backpressure)')
        }
      }, 1000)
    }
  })

  server.on('unsubscribe', (centralHandle, characteristicUuid) => {
    console.log('central unsubscribed from:', characteristicUuid)
    subscribedCentrals.delete(centralHandle)

    if (subscribedCentrals.size === 0 && notifyInterval) {
      clearInterval(notifyInterval)
      notifyInterval = null
      console.log('stopped notifications (no subscribers)')
    }
  })

  server.on('readyToUpdate', () => {
    console.log('ready to send more notifications')
  })

  server.on('channelOpen', (channel, error) => {
    if (error) {
      console.log('L2CAP channel error:', error)
      return
    }

    console.log('L2CAP channel opened, peer:', channel.peer)

    channel.on('open', () => {
      console.log('L2CAP stream ready')

      const msg = new TextEncoder().encode('Welcome to L2CAP!\n')
      channel.write(msg)
    })

    channel.on('data', (data) => {
      console.log('L2CAP received:', new TextDecoder().decode(data))

      channel.write(data)
    })

    channel.on('drain', () => {
      console.log('L2CAP drain')
    })

    channel.on('end', () => {
      console.log('L2CAP remote closed')
    })

    channel.on('error', (err) => {
      console.log('L2CAP error:', err.message)
    })

    channel.on('close', () => {
      console.log('L2CAP channel closed')
    })
  })
})

Bare.on('exit', () => {
  console.log('shutting down...')

  if (notifyInterval) {
    clearInterval(notifyInterval)
  }

  server.stopAdvertising()

  if (l2capPsm !== null) {
    server.unpublishChannel(l2capPsm)
  }

  server.destroy()
})
