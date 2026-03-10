const { TextEncoder, TextDecoder } = require('bare-encoding')
const bluetooth = require('../../')

const SERVICE_UUID = '01230000-0000-1000-8000-00805F9B34FB'
const CHAR_READ_UUID = '01230000-0001-1000-8000-00805F9B34FB'
const CHAR_WRITE_UUID = '01230000-0002-1000-8000-00805F9B34FB'
const CHAR_NOTIFY_UUID = '01230000-0003-1000-8000-00805F9B34FB'
const CHAR_PSM_UUID = '01230000-0004-1000-8000-00805F9B34FB'

const central = new bluetooth.Central()

let connectedPeripheral = null
let characteristics = {}

function scan() {
  console.log('scanning for service:', SERVICE_UUID)

  central.startScan([SERVICE_UUID])

  central.on('discover', (peripheral) => {
    console.log(
      'discovered:',
      peripheral.name || '(unnamed)',
      'id:',
      peripheral.id,
      'rssi:',
      peripheral.rssi
    )

    central.stopScan()
    console.log('connecting...')
    central.connect(peripheral)
  })
}

central.on('stateChange', (state) => {
  console.log('state:', state)
  scan()
})

central.on('connect', (peripheral) => {
  console.log('connected to:', peripheral.name || '(unnamed)', 'id:', peripheral.id)
  connectedPeripheral = peripheral

  peripheral.on('servicesDiscover', (services, error) => {
    if (error) {
      console.log('service discovery error:', error)
      return
    }

    console.log('discovered', services.length, 'services')

    for (const service of services) {
      console.log('  service:', service.uuid)

      if (service.uuid === SERVICE_UUID) {
        peripheral.discoverCharacteristics(service)
      }
    }
  })

  peripheral.on('characteristicsDiscover', (service, chars, error) => {
    if (error) {
      console.log('characteristic discovery error:', error)
      return
    }

    console.log('discovered', chars.length, 'characteristics for service:', service.uuid)

    for (const char of chars) {
      console.log('  characteristic:', char.uuid, 'properties:', char.properties)
      characteristics[char.uuid] = char
    }

    const readChar = characteristics[CHAR_READ_UUID]

    if (readChar) {
      console.log('reading static characteristic...')
      peripheral.read(readChar)
    }

    const writeChar = characteristics[CHAR_WRITE_UUID]

    if (writeChar) {
      setTimeout(() => {
        console.log('writing to characteristic...')
        const message = new TextEncoder().encode('Hello from client!')
        peripheral.write(writeChar, message)
      }, 500)
    }

    const notifyChar = characteristics[CHAR_NOTIFY_UUID]

    if (notifyChar) {
      setTimeout(() => {
        console.log('subscribing to notifications...')
        peripheral.subscribe(notifyChar)
      }, 1000)
    }

    const psmChar = characteristics[CHAR_PSM_UUID]

    if (psmChar) {
      setTimeout(() => {
        console.log('reading PSM characteristic...')
        peripheral.read(psmChar)
      }, 1500)
    }
  })

  peripheral.on('read', (characteristic, data, error) => {
    if (error) {
      console.log('read error:', error)
      return
    }

    console.log('read from', characteristic.uuid, ':', data)

    if (characteristic.uuid === CHAR_READ_UUID) {
      console.log('read value as string:', new TextDecoder().decode(data))
    }

    if (characteristic.uuid === CHAR_PSM_UUID && data && data.length >= 2) {
      const psm = data[0] | (data[1] << 8)
      console.log('L2CAP PSM:', psm)

      if (psm > 0) {
        console.log('opening L2CAP channel...')
        peripheral.openL2CAPChannel(psm)
      }
    }
  })

  peripheral.on('write', (characteristic, error) => {
    if (error) {
      console.log('write error:', error)
      return
    }

    console.log('write completed for:', characteristic.uuid)
  })

  peripheral.on('notifyState', (characteristic, isNotifying, error) => {
    if (error) {
      console.log('notify state error:', error)
      return
    }

    console.log(
      'notify state for',
      characteristic.uuid,
      ':',
      isNotifying ? 'subscribed' : 'unsubscribed'
    )
  })

  peripheral.on('notify', (characteristic, data, error) => {
    if (error) {
      console.log('notification error:', error)
      return
    }

    console.log('notification from', characteristic.uuid, ':', data[0])
  })

  peripheral.on('channelOpen', (channel, error) => {
    if (error) {
      console.log('L2CAP channel error:', error)
      return
    }

    console.log('L2CAP channel opened, PSM:', channel.psm)

    channel.on('open', () => {
      console.log('L2CAP stream ready')

      setTimeout(() => {
        console.log('sending L2CAP message...')
        channel.write(new TextEncoder().encode('Hello from client!'))
      }, 500)

      setTimeout(() => {
        console.log('sending another L2CAP message...')
        channel.write(new TextEncoder().encode('Testing L2CAP streaming'))
      }, 1500)
    })

    channel.on('data', (data) => {
      console.log('L2CAP received:', new TextDecoder().decode(data))
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

  console.log('discovering services...')
  peripheral.discoverServices([SERVICE_UUID])
})

central.on('disconnect', (peripheral, error) => {
  console.log(
    'disconnected:',
    peripheral ? peripheral.id : '(unknown)',
    error ? 'error: ' + error : ''
  )
  connectedPeripheral = null
  characteristics = {}

  console.log('restarting scan in 2 seconds...')
  setTimeout(scan, 2000)
})

Bare.on('exit', () => {
  if (connectedPeripheral) {
    central.disconnect(connectedPeripheral)
  }

  central.stopScan()
  central.destroy()
})
