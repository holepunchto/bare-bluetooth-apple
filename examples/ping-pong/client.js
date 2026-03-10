const { TextEncoder, TextDecoder } = require('bare-encoding')
const bluetooth = require('../../')

const SERVICE_UUID = '01230000-0000-1000-8000-00805F9B34FB'
const CHAR_UUID = '01230001-0000-1000-8000-00805F9B34FB'

const central = new bluetooth.Central()

let peripheral = null
let pingChar = null
let pingCount = 0

central.on('stateChange', (state) => {
  console.log('state:', state)

  if (state !== 'poweredOn') {
    return
  }

  central.startScan([SERVICE_UUID])
})

central.on('discover', (p) => {
  console.log('found:', p.name || p.id)
  central.stopScan()
  central.connect(p)
})

central.on('connectFail', (id, error) => {
  console.log('connect failed:', error)
  central.startScan([SERVICE_UUID])
})

central.on('connect', (p) => {
  console.log('connected')
  peripheral = p

  peripheral.on('servicesDiscover', (services, error) => {
    if (error) {
      console.log('servicesDiscover error:', error)
      return
    }

    for (const s of services) {
      if (s.uuid === SERVICE_UUID) {
        peripheral.discoverCharacteristics(s)
      }
    }
  })

  peripheral.on('characteristicsDiscover', (service, chars, error) => {
    if (error) {
      console.log('characteristicsDiscover error:', error)
      return
    }

    for (const c of chars) {
      if (c.uuid === CHAR_UUID) {
        pingChar = c
        console.log('subscribing...')
        peripheral.subscribe(c)
      }
    }
  })

  peripheral.on('notifyState', (char, isNotifying) => {
    console.log('subscribed:', isNotifying)
    if (isNotifying) {
      sendPing()
    }
  })

  peripheral.on('notify', (char, data) => {
    console.log('received:', new TextDecoder().decode(data))

    setTimeout(sendPing, 1000)
  })

  peripheral.on('write', (char, error) => {
    if (error) {
      console.log('write error:', error)
    }
  })

  peripheral.discoverServices([SERVICE_UUID])
})

central.on('disconnect', (p, error) => {
  console.log('disconnected', error || '')
  peripheral = null
  pingChar = null

  setTimeout(() => {
    console.log('reconnecting...')
    central.startScan([SERVICE_UUID])
  }, 2000)
})

function sendPing() {
  if (!peripheral || !pingChar) return

  pingCount++
  const msg = 'ping ' + pingCount
  console.log('sending:', msg)
  peripheral.write(pingChar, new TextEncoder().encode(msg))
}

Bare.on('exit', () => {
  if (peripheral) {
    central.disconnect(peripheral)
  }

  central.stopScan()
  central.destroy()
})
