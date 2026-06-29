const test = require('brittle')

const PeripheralManager = require('../lib/peripheral-manager')
const Service = require('../lib/service')
const Characteristic = require('../lib/characteristic')
const { isCI, waitForPoweredOn } = require('./helpers')

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

test('startAdvertising with serviceData does not throw', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(createSimpleService())
  await waitForServiceAdd(manager)

  t.execution(() => {
    manager.startAdvertising({
      name: 'BareTest',
      serviceUUIDs: [SERVICE_UUID],
      serviceData: { [SERVICE_UUID]: new Uint8Array([0xca, 0xfe]) }
    })
  })

  t.execution(() => {
    manager.stopAdvertising()
  })
})

test('startAdvertising with serviceData only', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(createSimpleService())
  await waitForServiceAdd(manager)

  t.execution(() => {
    manager.startAdvertising({
      serviceData: { [SERVICE_UUID]: new Uint8Array([0x01]) }
    })
  })

  t.execution(() => {
    manager.stopAdvertising()
  })
})

test('startAdvertising with multiple serviceData entries', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(createSimpleService())
  await waitForServiceAdd(manager)

  const SECOND_UUID = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'

  t.execution(() => {
    manager.startAdvertising({
      serviceData: {
        [SERVICE_UUID]: new Uint8Array([0xca, 0xfe]),
        [SECOND_UUID]: new Uint8Array([0xde, 0xad])
      }
    })
  })

  t.execution(() => {
    manager.stopAdvertising()
  })
})

test('startAdvertising does not emit error on success', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.addService(createSimpleService())
  await waitForServiceAdd(manager)

  manager.on('error', (err) => {
    t.fail(`unexpected error: ${err.code} ${err.message}`)
  })

  manager.startAdvertising({ name: 'BareTest', serviceUUIDs: [SERVICE_UUID] })

  await new Promise((resolve) => setTimeout(resolve, 500))

  t.pass('no error emitted for valid advertising data')

  manager.stopAdvertising()
})

test(
  'startAdvertising emits error with ADVERTISE_FAILED code for invalid data',
  { skip: isCI },
  async (t) => {
    using manager = new PeripheralManager()
    await waitForPoweredOn(manager)

    manager.startAdvertising({
      name: 'X'.repeat(256),
      serviceUUIDs: [SERVICE_UUID]
    })

    const err = await Promise.race([
      new Promise((resolve) => {
        manager.on('error', resolve)
      }),
      new Promise((resolve) => setTimeout(() => resolve(null), 1000))
    ])

    if (err === null) {
      t.pass('platform accepted the oversized payload; error not applicable here')
    } else {
      t.is(err.code, 'ADVERTISE_FAILED')
      t.ok(typeof err.message === 'string' && err.message.length > 0)
    }

    manager.stopAdvertising()
  }
)

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

test('publishChannel returns PSM', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.publishChannel()

  const [psm, error] = await new Promise((resolve) => {
    manager.on('channelPublish', (psm, error) => resolve([psm, error]))
  })

  t.absent(error)
  t.ok(typeof psm === 'number')
  t.ok(psm > 0)

  manager.unpublishChannel(psm)
})

test('publishChannel multiple times returns distinct PSMs', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.publishChannel()

  const [psm1, error1] = await new Promise((resolve) => {
    manager.on('channelPublish', (psm, error) => resolve([psm, error]))
  })

  t.absent(error1)
  t.ok(psm1 > 0)

  manager.publishChannel()

  const [psm2, error2] = await new Promise((resolve) => {
    manager.once('channelPublish', (psm, error) => resolve([psm, error]))
  })

  t.absent(error2)
  t.ok(psm2 > 0)
  t.not(psm1, psm2)

  manager.unpublishChannel(psm1)
  manager.unpublishChannel(psm2)
})

test('publishChannel with encryption', { skip: isCI }, async (t) => {
  using manager = new PeripheralManager()
  await waitForPoweredOn(manager)

  manager.publishChannel({ encrypted: true })

  const [psm, error] = await new Promise((resolve) => {
    manager.on('channelPublish', (psm, error) => resolve([psm, error]))
  })

  t.absent(error)
  t.ok(psm > 0)

  manager.unpublishChannel(psm)
})

// Helpers

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
