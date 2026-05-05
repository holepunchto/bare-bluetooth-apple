const test = require('brittle')
const Central = require('../lib/central')
const { isCI } = require('./helpers')

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
  if (!(await waitForPoweredOn(central))) return t.comment('bluetooth not powered on, skipping')

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
})

test(
  'repeated discover for same id reuses the same object reference',
  { skip: isCI },
  async (t) => {
    using central = new Central()
    if (!(await waitForPoweredOn(central))) return t.comment('bluetooth not powered on, skipping')

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

test('destroy cleans up gracefully', { skip: isCI }, async (t) => {
  using central = new Central()
  if (!(await waitForPoweredOn(central))) return t.comment('bluetooth not powered on, skipping')

  central.startScan()

  await new Promise((resolve) => {
    central.on('discover', resolve)
  })

  t.execution(() => central.destroy())
})

test('filtered scan with non-existent UUID finds nothing', { skip: isCI }, async (t) => {
  using central = new Central()
  if (!(await waitForPoweredOn(central))) return t.comment('bluetooth not powered on, skipping')

  central.startScan(['00000000-0000-0000-0000-000000000000'])

  let found = false
  central.on('discover', () => {
    found = true
  })

  await new Promise((resolve) => setTimeout(resolve, 3000))

  central.stopScan()
  t.absent(found)
})

test('exports state constants', (t) => {
  t.is(Central.STATE_UNKNOWN, 0)
  t.is(Central.STATE_RESETTING, 1)
  t.is(Central.STATE_UNSUPPORTED, 2)
  t.is(Central.STATE_UNAUTHORIZED, 3)
  t.is(Central.STATE_POWERED_OFF, 4)
  t.is(Central.STATE_POWERED_ON, 5)
})

// Helpers

async function waitForPoweredOn(central) {
  const state = await new Promise((resolve) => {
    central.on('stateChange', resolve)
  })
  return state === 'poweredOn'
}
