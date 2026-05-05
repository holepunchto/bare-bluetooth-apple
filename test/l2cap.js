const test = require('brittle')
const PeripheralManager = require('../lib/peripheral-manager')
const { isCI } = require('./helpers')

test('manager publish L2CAP channel returns PSM', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  manager.publishChannel()

  const [psm, error] = await new Promise((resolve) => {
    manager.on('channelPublish', (psm, error) => {
      resolve([psm, error])
    })
  })

  t.absent(error, 'no error publishing channel')
  t.ok(typeof psm === 'number', 'psm is a number')
  t.ok(psm > 0, 'psm is positive: ' + psm)

  manager.unpublishChannel(psm)
})

test('manager publish multiple L2CAP channels', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  manager.publishChannel()

  const [psm1, error1] = await new Promise((resolve) => {
    manager.on('channelPublish', (psm, error) => {
      resolve([psm, error])
    })
  })

  t.absent(error1, 'no error publishing first channel')
  t.ok(psm1 > 0, 'first psm is positive: ' + psm1)

  manager.publishChannel()

  const [psm2, error2] = await new Promise((resolve) => {
    manager.once('channelPublish', (psm, error) => {
      resolve([psm, error])
    })
  })

  t.absent(error2, 'no error publishing second channel')
  t.ok(psm2 > 0, 'second psm is positive: ' + psm2)
  t.not(psm1, psm2, 'psms are different')

  manager.unpublishChannel(psm1)
  manager.unpublishChannel(psm2)
})

test('manager publish encrypted L2CAP channel', { skip: isCI }, async (t) => {
  const manager = new PeripheralManager()
  t.teardown(() => manager.destroy())

  const state = await new Promise((resolve) => {
    manager.on('stateChange', resolve)
  })

  if (state !== 'poweredOn') {
    t.comment('bluetooth not powered on: ' + state + ', skipping')
    return
  }

  manager.publishChannel({ encrypted: true })

  const [psm, error] = await new Promise((resolve) => {
    manager.on('channelPublish', (psm, error) => {
      resolve([psm, error])
    })
  })

  t.absent(error, 'no error publishing encrypted channel')
  t.ok(psm > 0, 'encrypted channel psm is positive: ' + psm)

  manager.unpublishChannel(psm)
})
