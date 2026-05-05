const test = require('brittle')
const PeripheralManager = require('../lib/peripheral-manager')
const Service = require('../lib/service')
const Characteristic = require('../lib/characteristic')
const { isCI } = require('./helpers')

const SERVICE_UUID = '12345678-1234-1234-1234-123456789ABC'
const CHAR_UUID = '87654321-4321-4321-4321-CBA987654321'

test('manager emits stateChange on init', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  t.ok(typeof state === 'string', 'state is a string')
  t.ok(
    ['poweredOn', 'poweredOff', 'resetting', 'unauthorized', 'unsupported', 'unknown'].includes(
      state
    ),
    'state is a valid value: ' + state
  )
})

test('manager tracks state property', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  t.is(manager.state, 'unknown', 'initial state is unknown')

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  t.is(manager.state, state, 'state property matches emitted state')
})

test('manager exports state constants', (t) => {
  t.is(PeripheralManager.STATE_UNKNOWN, 0)
  t.is(PeripheralManager.STATE_RESETTING, 1)
  t.is(PeripheralManager.STATE_UNSUPPORTED, 2)
  t.is(PeripheralManager.STATE_UNAUTHORIZED, 3)
  t.is(PeripheralManager.STATE_POWERED_OFF, 4)
  t.is(PeripheralManager.STATE_POWERED_ON, 5)
})

test('manager exports permission constants', (t) => {
  t.is(PeripheralManager.PERMISSION_READABLE, 0x01)
  t.is(PeripheralManager.PERMISSION_WRITEABLE, 0x02)
  t.is(PeripheralManager.PERMISSION_READ_ENCRYPTED, 0x04)
  t.is(PeripheralManager.PERMISSION_WRITE_ENCRYPTED, 0x08)
})

test('manager exports ATT result constants', (t) => {
  t.is(PeripheralManager.ATT_SUCCESS, 0)
  t.ok(typeof PeripheralManager.ATT_INVALID_HANDLE === 'number', 'ATT_INVALID_HANDLE is number')
  t.ok(
    typeof PeripheralManager.ATT_READ_NOT_PERMITTED === 'number',
    'ATT_READ_NOT_PERMITTED is number'
  )
  t.ok(
    typeof PeripheralManager.ATT_WRITE_NOT_PERMITTED === 'number',
    'ATT_WRITE_NOT_PERMITTED is number'
  )
})

test('manager add service with static value', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  const characteristic = new Characteristic(CHAR_UUID, {
    read: true,
    value: new Uint8Array([0x48, 0x65, 0x6c, 0x6c, 0x6f])
  })

  const service = new Service(SERVICE_UUID, [characteristic])

  manager.addService(service)

  const [uuid, error] = await new Promise((resolve) => {
    manager.on('serviceAdd', (uuid, error) => {
      resolve([uuid, error])
    })
  })

  t.absent(error, 'no error adding service')
  t.is(uuid, SERVICE_UUID, 'service uuid matches')
})

test('manager add service with dynamic characteristic', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  const dynamicUuid = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'

  const characteristic = new Characteristic(dynamicUuid, {
    read: true,
    write: true
  })

  const serviceUuid = 'BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF'
  const service = new Service(serviceUuid, [characteristic])

  manager.addService(service)

  const [uuid, error] = await new Promise((resolve) => {
    manager.on('serviceAdd', (uuid, error) => {
      resolve([uuid, error])
    })
  })

  t.absent(error, 'no error adding dynamic service')
  t.is(uuid, serviceUuid, 'dynamic service uuid matches')
})

test('manager start and stop advertising', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  const characteristic = new Characteristic(CHAR_UUID, {
    read: true,
    value: new Uint8Array([0x01])
  })

  const service = new Service(SERVICE_UUID, [characteristic])

  manager.addService(service)

  await new Promise((resolve) => {
    manager.on('serviceAdd', () => resolve())
  })

  t.execution(() => {
    manager.startAdvertising({
      name: 'BareTestAdv',
      serviceUUIDs: [SERVICE_UUID]
    })
  })

  t.execution(() => {
    manager.stopAdvertising()
  })
})

test('manager destroy cleans up gracefully', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  const characteristic = new Characteristic(CHAR_UUID, {
    read: true,
    value: new Uint8Array([0x01])
  })

  const service = new Service(SERVICE_UUID, [characteristic])

  manager.addService(service)

  await new Promise((resolve) => {
    manager.on('serviceAdd', () => resolve())
  })

  manager.startAdvertising({
    name: 'BareTestDestroy',
    serviceUUIDs: [SERVICE_UUID]
  })

  t.execution(() => manager.destroy())
})

test('manager multiple characteristics in one service', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  const charA = new Characteristic('11111111-1111-1111-1111-111111111111', {
    read: true,
    value: new Uint8Array([0x01])
  })

  const charB = new Characteristic('22222222-2222-2222-2222-222222222222', {
    read: true,
    write: true,
    notify: true
  })

  const serviceUuid = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC'
  const service = new Service(serviceUuid, [charA, charB])

  manager.addService(service)

  const [uuid, error] = await new Promise((resolve) => {
    manager.on('serviceAdd', (uuid, error) => {
      resolve([uuid, error])
    })
  })

  t.absent(error, 'no error adding multi-characteristic service')
  t.is(uuid, serviceUuid, 'multi-characteristic service uuid matches')
})
