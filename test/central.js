const test = require('brittle')
const Central = require('../lib/central')
const Thread = require('bare-thread')
const { isCI, waitForPoweredOn } = require('./helpers')

const UNKNOWN_ID = '00000000-0000-0000-0000-000000000001'

test('initial state is unknown', { skip: isCI }, (t) => {
  using central = new Central()
  t.is(central.state, 'unknown')
})

test('emits stateChange on init', { skip: isCI }, async (t) => {
  using central = new Central()

  const state = await new Promise((resolve) => {
    central.on('stateChange', resolve)
  })

  t.ok(
    ['poweredOn', 'poweredOff', 'resetting', 'unauthorized', 'unsupported', 'unknown'].includes(
      state
    )
  )
})

test('state property tracks emitted state', { skip: isCI }, async (t) => {
  using central = new Central()

  const state = await new Promise((resolve) => {
    central.on('stateChange', resolve)
  })

  t.is(central.state, state)
})

test('scan discovers peripherals with expected shape', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  central.startScan()

  const peripheral = await new Promise((resolve) => {
    central.on('discover', resolve)
  })

  central.stopScan()

  t.ok(typeof peripheral.id === 'string')
  t.ok(peripheral.id.length > 0)
  t.ok(typeof peripheral.rssi === 'number')
  t.ok(peripheral.rssi < 0)
  t.ok(peripheral.name === null || typeof peripheral.name === 'string')
  t.ok(peripheral.serviceData === null || typeof peripheral.serviceData === 'object')
})

test(
  'repeated discover for same id reuses the same object reference',
  { skip: isCI },
  async (t) => {
    using central = new Central()
    await waitForPoweredOn(central)

    central.startScan()

    const same = await new Promise((resolve) => {
      const seen = new Map()

      central.on('discover', (peripheral) => {
        if (seen.has(peripheral.id)) {
          resolve(peripheral === seen.get(peripheral.id))
          return
        }
        seen.set(peripheral.id, peripheral)
      })
    })

    central.stopScan()

    t.ok(same)
  }
)

test('allowDuplicates reports the same peripheral repeatedly', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  central.startScan(null, { allowDuplicates: true })

  const repeated = await new Promise((resolve) => {
    const seen = new Set()
    const timeout = setTimeout(() => resolve(false), 5000)

    central.on('discover', (peripheral) => {
      if (seen.has(peripheral.id)) {
        clearTimeout(timeout)
        resolve(true)
        return
      }
      seen.add(peripheral.id)
    })
  })

  central.stopScan()

  t.ok(repeated)
})

test('destroy cleans up gracefully', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  central.startScan()

  await new Promise((resolve) => {
    central.on('discover', resolve)
  })

  t.execution(() => central.destroy())
})

test('double destroy does not crash', { skip: isCI }, async (t) => {
  const central = new Central()
  await waitForPoweredOn(central)

  central.destroy()
  t.execution(() => central.destroy())
})

test('teardown on exit cleans up native resources', { skip: isCI }, (t) => {
  t.plan(1)

  const thread = new Thread(require.resolve('./fixtures/teardown-scan.js'))
  thread.join()

  t.pass('thread torn down without crashing')
})

test('destroy then exit does not double-free', { skip: isCI }, (t) => {
  t.plan(1)

  const thread = new Thread(require.resolve('./fixtures/teardown-scan-destroy.js'))
  thread.join()

  t.pass('thread torn down without crashing')
})

test('filtered scan with non-existent UUID finds nothing', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  central.startScan(['00000000-0000-0000-0000-000000000000'])

  let found = false
  central.on('discover', () => {
    found = true
  })

  await new Promise((resolve) => setTimeout(resolve, 3000))

  central.stopScan()
  t.absent(found)
})

test('retrievePeripherals with no ids finds nothing', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  t.alike(central.retrievePeripherals([]), [])
})

test('retrievePeripherals rejects a malformed id', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  t.exception(() => central.retrievePeripherals(['not-a-uuid']))
})

test('retrievePeripherals finds nothing for an unknown id', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  t.alike(central.retrievePeripherals([UNKNOWN_ID]), [])
})

test('retrievePeripherals resolves a peripheral seen while scanning', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  central.startScan()

  const discovered = await new Promise((resolve) => {
    central.on('discover', resolve)
  })

  central.stopScan()

  const [peripheral] = central.retrievePeripherals([discovered.id])

  t.ok(peripheral)
  t.is(peripheral.id, discovered.id)
  t.is(peripheral.state, 'disconnected')
  t.ok(peripheral.name === null || typeof peripheral.name === 'string')
  t.absent('rssi' in peripheral)
  t.absent('serviceData' in peripheral)
})

test('retrieveConnectedPeripherals with no services finds nothing', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  t.alike(central.retrieveConnectedPeripherals([]), [])
})

test('retrieveConnectedPeripherals reports connection state', { skip: isCI }, async (t) => {
  using central = new Central()
  await waitForPoweredOn(central)

  const found = central.retrieveConnectedPeripherals(['180D'])

  t.ok(Array.isArray(found))

  for (const peripheral of found) {
    t.ok(typeof peripheral.id === 'string')
    t.ok(['disconnected', 'connecting', 'connected', 'disconnecting'].includes(peripheral.state))
  }
})

test('exports state constants', (t) => {
  t.is(Central.STATE_UNKNOWN, 0)
  t.is(Central.STATE_RESETTING, 1)
  t.is(Central.STATE_UNSUPPORTED, 2)
  t.is(Central.STATE_UNAUTHORIZED, 3)
  t.is(Central.STATE_POWERED_OFF, 4)
  t.is(Central.STATE_POWERED_ON, 5)
})
