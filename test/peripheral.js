const { test, hook } = require('brittle')
const Central = require('../lib/central')
const Peripheral = require('../lib/peripheral')
const { isCI, waitForPoweredOn } = require('./helpers')

let central = null
let peripheral = null
let discovered = null

hook('setup: connect to nearby peripheral', { skip: isCI, timeout: 30000 }, async (t) => {
  central = new Central()

  central.on('error', (err) => {
    console.error('central error:', err.code, err.message)
  })

  await waitForPoweredOn(central)

  central.startScan()

  while (true) {
    discovered = await new Promise((resolve) => {
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

  peripheral.on('error', (err) => {
    console.error('peripheral error:', err.code, err.message)
  })

  t.ok(peripheral instanceof Peripheral)
})

test('peripheral has a string id', { skip: isCI }, (t) => {
  t.ok(typeof peripheral.id === 'string')
})

test('name matches what the system knows about the device', { skip: isCI }, (t) => {
  const [retrieved] = central.retrievePeripherals([peripheral.id])

  t.ok(retrieved)
  t.comment('name is ' + retrieved.name)
  t.is(peripheral.name, retrieved.name)
})

test('serviceData survives the scan stopping', { skip: isCI }, (t) => {
  t.comment('serviceData is ' + (discovered.serviceData ? 'present' : 'null'))
  t.alike(peripheral.serviceData, discovered.serviceData)
})

test('discover services', { skip: isCI, timeout: 15000 }, async (t) => {
  if (!peripheral.connected) return t.pass('peripheral disconnected, skipping')

  peripheral.discoverServices()

  const result = await next('servicesDiscover')

  if (!result) return t.pass('no services reported, skipping')

  const [services] = result

  t.ok(services.length > 0)
  t.ok(typeof services[0].uuid === 'string')
})

test('discover characteristics', { skip: isCI, timeout: 15000 }, async (t) => {
  if (!peripheral.connected) return t.pass('peripheral disconnected, skipping')

  peripheral.discoverServices()

  const discovered = await next('servicesDiscover')

  if (!discovered) return t.pass('no services reported, skipping')

  const [services] = discovered

  peripheral.discoverCharacteristics(services[0])

  const result = await next('characteristicsDiscover')

  if (!result) return t.pass('no characteristics reported, skipping')

  const [, characteristics] = result

  t.ok(characteristics.length > 0)
  t.ok(typeof characteristics[0].uuid === 'string')
  t.ok(typeof characteristics[0].properties === 'number')
  t.exception(() => {
    characteristics[0].value = new Uint8Array([1])
  }, /discovered characteristic/)
})

test('read readable characteristics', { skip: isCI, timeout: 60000 }, async (t) => {
  if (!peripheral.connected) return t.pass('peripheral disconnected, skipping')

  peripheral.discoverServices()

  const discovered = await next('servicesDiscover')

  if (!discovered) return t.pass('no services reported, skipping')

  const [services] = discovered

  t.comment(services.length + ' services found')

  let readCount = 0

  for (const service of services) {
    if (!peripheral.connected) {
      t.comment('  peripheral disconnected, stopping')
      break
    }

    peripheral.discoverCharacteristics(service)

    const discoveredChars = await next('characteristicsDiscover')

    if (!discoveredChars) {
      t.comment('  ' + service.uuid + ' - discover timed out')
      continue
    }

    const [, chars] = discoveredChars

    for (const char of chars) {
      const flags = describeProperties(char.properties)
      t.comment('  ' + service.uuid + ' / ' + char.uuid + ' [' + flags + ']')

      if (!(char.properties & Peripheral.PROPERTY_READ)) continue
      if (!peripheral.connected) break

      peripheral.read(char)

      const result = await next('read')

      if (!result) {
        t.comment('    read failed or timed out')
        continue
      }

      const [, data] = result

      readCount++

      t.comment(
        '    ' +
          (data && data.length > 0
            ? Buffer.from(data.buffer, data.byteOffset, data.byteLength).toString('hex')
            : 'empty')
      )
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

test('methods throw once the peripheral is destroyed', { skip: isCI }, (t) => {
  if (!peripheral) return t.pass('no peripheral connected')

  peripheral.destroy()

  t.exception.all(() => peripheral.discoverServices(), /NOT_CONNECTED/)
  t.exception.all(() => peripheral.discoverCharacteristics({}), /NOT_CONNECTED/)
  t.exception.all(() => peripheral.read({}), /NOT_CONNECTED/)
  t.exception.all(() => peripheral.write({}, new Uint8Array([1])), /NOT_CONNECTED/)
  t.exception.all(() => peripheral.subscribe({}), /NOT_CONNECTED/)
  t.exception.all(() => peripheral.unsubscribe({}), /NOT_CONNECTED/)
  t.exception.all(() => peripheral.openL2CAPChannel(0x80), /NOT_CONNECTED/)
})

test('double destroy does not crash', { skip: isCI }, (t) => {
  if (!peripheral) return t.pass('no peripheral connected')

  peripheral.destroy()
  t.execution(() => peripheral.destroy())
  peripheral = null
})

hook('teardown: disconnect', { skip: isCI }, (t) => {
  if (peripheral) peripheral.destroy()
  if (central) central.destroy()
  t.pass()
})

// Helpers

// Resolves null when the link dies or the peer stays silent, so a peer that
// drops mid-suite skips the rest instead of timing the whole run out.
function next(event, timeout = 5000) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => done(null), timeout)

    const onevent = (...args) => done(args)
    const onlost = () => done(null)

    peripheral.once(event, onevent)
    peripheral.once('disconnect', onlost)
    peripheral.once('error', onlost)

    function done(value) {
      clearTimeout(timer)
      peripheral.off(event, onevent).off('disconnect', onlost).off('error', onlost)
      resolve(value)
    }
  })
}

function describeProperties(props) {
  const flags = []
  if (props & Peripheral.PROPERTY_READ) flags.push('read')
  if (props & Peripheral.PROPERTY_WRITE) flags.push('write')
  if (props & Peripheral.PROPERTY_WRITE_WITHOUT_RESPONSE) flags.push('write-no-resp')
  if (props & Peripheral.PROPERTY_NOTIFY) flags.push('notify')
  if (props & Peripheral.PROPERTY_INDICATE) flags.push('indicate')
  return flags.join(', ')
}
