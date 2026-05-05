const test = require('brittle')

const PeripheralManager = require('../lib/peripheral-manager')
const Service = require('../lib/service')
const Characteristic = require('../lib/characteristic')
const { isCI } = require('./helpers')

const SERVICE_UUID = '12345678-1234-1234-1234-123456789ABC'
const CHAR_UUID = '87654321-4321-4321-4321-CBA987654321'

test('initial state is unknown', { skip: isCI }, (t) => {
  using manager = new PeripheralManager()
  t.is(manager.state, 'unknown')
})

test('emits stateChange on init', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  t.ok(
    ['poweredOn', 'poweredOff', 'resetting', 'unauthorized', 'unsupported', 'unknown'].includes(
      state
    )
  )
})

test('state property tracks emitted state', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  t.is(manager.state, state)
})

test('addService registers and confirms service', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(new Service(SERVICE_UUID))

  const [uuid, error] = await new Promise((resolve) => {
    manager.on('serviceAdd', (uuid, error) => resolve([uuid, error]))
  })
  t.absent(error)
  t.is(uuid, SERVICE_UUID)
})

test('addService works with dynamic characteristic', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  const service = new Service(SERVICE_UUID)
  manager.addService(service)

  const [uuid, error] = await new Promise((resolve) => {
    manager.on('serviceAdd', (uuid, error) => resolve([uuid, error]))
  })
  t.absent(error)
  t.is(uuid, service.uuid)
})

test('addService with multiple characteristics', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  const service = new Service(SERVICE_UUID, [
    new Characteristic(CHAR_UUID, {
      read: true,
      value: new Uint8Array([0x01])
    }),
    new Characteristic(CHAR_UUID, {
      read: true,
      write: true,
      notify: true
    })
  ])
  manager.addService(service)

  const [uuid, error] = await new Promise((resolve) => {
    manager.on('serviceAdd', (uuid, error) => resolve([uuid, error]))
  })
  t.absent(error)
  t.is(uuid, service.uuid)
})

test('startAdvertising and stopAdvertising do not throw', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(createSimpleService())
  await waitForServiceAdd(manager)

  t.execution(() => {
    manager.startAdvertising({ name: 'BareTest', serviceUUIDs: [SERVICE_UUID] })
  })

  t.execution(() => {
    manager.stopAdvertising()
  })
})

test('destroy cleans up gracefully', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(createSimpleService())
  await waitForServiceAdd(manager)

  manager.startAdvertising({ name: 'BareTest', serviceUUIDs: [SERVICE_UUID] })

  t.execution(() => manager.destroy())
})

test('exports state constants', (t) => {
  t.is(PeripheralManager.STATE_UNKNOWN, 0)
  t.is(PeripheralManager.STATE_RESETTING, 1)
  t.is(PeripheralManager.STATE_UNSUPPORTED, 2)
  t.is(PeripheralManager.STATE_UNAUTHORIZED, 3)
  t.is(PeripheralManager.STATE_POWERED_OFF, 4)
  t.is(PeripheralManager.STATE_POWERED_ON, 5)
})

test('exports permission constants', (t) => {
  t.is(PeripheralManager.PERMISSION_READABLE, 0x01)
  t.is(PeripheralManager.PERMISSION_WRITEABLE, 0x02)
  t.is(PeripheralManager.PERMISSION_READ_ENCRYPTED, 0x04)
  t.is(PeripheralManager.PERMISSION_WRITE_ENCRYPTED, 0x08)
})

test('exports ATT result constants', (t) => {
  t.is(PeripheralManager.ATT_SUCCESS, 0)
  t.ok(typeof PeripheralManager.ATT_INVALID_HANDLE === 'number')
  t.ok(typeof PeripheralManager.ATT_READ_NOT_PERMITTED === 'number')
  t.ok(typeof PeripheralManager.ATT_WRITE_NOT_PERMITTED === 'number')
})

// Helpers

async function waitForPoweredOn(manager) {
  await new Promise((resolve) => {
    manager.on('stateChange', (state) => {
      if (state === 'poweredOn') resolve()
    })
  })
}

async function waitForServiceAdd(manager) {
  await new Promise((resolve) => {
    manager.on('serviceAdd', () => resolve())
  })
}

function createSimpleService() {
  const characteristic = new Characteristic(CHAR_UUID, {
    read: true,
    value: new Uint8Array([0x01])
  })
  return new Service(SERVICE_UUID, [characteristic])
}
