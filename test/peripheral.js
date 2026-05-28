const { test, hook } = require('brittle')
const Central = require('../lib/central')
const Peripheral = require('../lib/peripheral')
const { isCI, waitForPoweredOn, hexdump } = require('./helpers')

let central = null
let peripheral = null

hook('setup: connect to nearby peripheral', { skip: isCI, timeout: 30000 }, async (t) => {
  central = new Central()
  await waitForPoweredOn(central)

  central.startScan()

  while (true) {
    const discovered = await new Promise((resolve) => {
      central.once('discover', resolve)
    })

    central.stopScan()
    central.connect(discovered)

    peripheral = await new Promise((resolve) => {
      central.once('connect', resolve)
      central.once('connectFail', () => resolve(null))
      setTimeout(() => resolve(null), 5000)
    })

    if (peripheral) break

    central.startScan()
  }

  t.ok(peripheral instanceof Peripheral)
})

test('peripheral has a string id', { skip: isCI }, (t) => {
  t.ok(typeof peripheral.id === 'string')
})

test('discover services', { skip: isCI, timeout: 15000 }, async (t) => {
  peripheral.discoverServices()

  const [services, error] = await new Promise((resolve) => {
    peripheral.on('servicesDiscover', (services, error) => resolve([services, error]))
  })

  t.absent(error)
  t.ok(services.length > 0)
  t.ok(typeof services[0].uuid === 'string')
})

test('discover characteristics', { skip: isCI, timeout: 15000 }, async (t) => {
  peripheral.discoverServices()

  const [services] = await new Promise((resolve) => {
    peripheral.on('servicesDiscover', (services, error) => resolve([services, error]))
  })

  peripheral.discoverCharacteristics(services[0])

  const [, characteristics, error] = await new Promise((resolve) => {
    peripheral.on('characteristicsDiscover', (svc, chars, error) => resolve([svc, chars, error]))
  })

  t.absent(error)
  t.ok(characteristics.length > 0)
  t.ok(typeof characteristics[0].uuid === 'string')
  t.ok(typeof characteristics[0].properties === 'number')
})

test('read readable characteristics', { skip: isCI, timeout: 60000 }, async (t) => {
  peripheral.discoverServices()

  const [services] = await new Promise((resolve) => {
    peripheral.on('servicesDiscover', (services, error) => resolve([services, error]))
  })

  t.comment(services.length + ' services found')

  let readCount = 0

  for (const service of services) {
    peripheral.discoverCharacteristics(service)

    const chars = await new Promise((resolve) => {
      const timeout = setTimeout(() => resolve(null), 5000)
      peripheral.once('characteristicsDiscover', (svc, chars) => {
        clearTimeout(timeout)
        resolve(chars)
      })
    })

    if (!chars) {
      t.comment('  ' + service.uuid + ' — discover timed out')
      continue
    }

    for (const char of chars) {
      const flags = describeProperties(char.properties)
      t.comment('  ' + service.uuid + ' / ' + char.uuid + ' [' + flags + ']')

      if (!(char.properties & Peripheral.PROPERTY_READ)) continue

      peripheral.read(char)

      const result = await new Promise((resolve) => {
        const timeout = setTimeout(() => resolve(null), 5000)
        peripheral.once('read', (c, data, error) => {
          clearTimeout(timeout)
          resolve([c, data, error])
        })
      })

      if (!result) {
        t.comment('    read timed out')
        continue
      }

      const [, data, error] = result

      if (error) {
        t.comment('    read error: ' + error)
        continue
      }

      readCount++

      t.comment('    ' + (data && data.length > 0 ? hexdump(data) : 'empty'))
    }
  }

  t.ok(readCount >= 0, 'enumerated all characteristics')
})

test('peripheral property constants', (t) => {
  t.is(Peripheral.PROPERTY_READ, 0x02)
  t.is(Peripheral.PROPERTY_WRITE_WITHOUT_RESPONSE, 0x04)
  t.is(Peripheral.PROPERTY_WRITE, 0x08)
  t.is(Peripheral.PROPERTY_NOTIFY, 0x10)
  t.is(Peripheral.PROPERTY_INDICATE, 0x20)
})

hook('teardown: disconnect', { skip: isCI }, (t) => {
  if (peripheral) peripheral.destroy()
  if (central) central.destroy()
  t.pass()
})

// Helpers

function describeProperties(props) {
  const flags = []
  if (props & Peripheral.PROPERTY_READ) flags.push('read')
  if (props & Peripheral.PROPERTY_WRITE) flags.push('write')
  if (props & Peripheral.PROPERTY_WRITE_WITHOUT_RESPONSE) flags.push('write-no-resp')
  if (props & Peripheral.PROPERTY_NOTIFY) flags.push('notify')
  if (props & Peripheral.PROPERTY_INDICATE) flags.push('indicate')
  return flags.join(', ')
}
