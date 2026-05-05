const test = require('brittle')
const Characteristic = require('../lib/characteristic')

test('default construction has no properties', (t) => {
  const char = new Characteristic('0000-0000-0000-0000')
  t.is(char.properties, 0)
  t.is(char.permissions, null)
  t.is(char.value, null)
  t.is(char.uuid, '0000-0000-0000-0000')
})

test('read option sets PROPERTY_READ bit', (t) => {
  const char = new Characteristic('0000', { read: true })
  t.ok(char.properties & Characteristic.PROPERTY_READ)
})

test('write option sets PROPERTY_WRITE bit', (t) => {
  const char = new Characteristic('0000', { write: true })
  t.ok(char.properties & Characteristic.PROPERTY_WRITE)
})

test('writeWithoutResponse option sets PROPERTY_WRITE_WITHOUT_RESPONSE bit', (t) => {
  const char = new Characteristic('0000', { writeWithoutResponse: true })
  t.ok(char.properties & Characteristic.PROPERTY_WRITE_WITHOUT_RESPONSE)
})

test('notify option sets PROPERTY_NOTIFY bit', (t) => {
  const char = new Characteristic('0000', { notify: true })
  t.ok(char.properties & Characteristic.PROPERTY_NOTIFY)
})

test('indicate option sets PROPERTY_INDICATE bit', (t) => {
  const char = new Characteristic('0000', { indicate: true })
  t.ok(char.properties & Characteristic.PROPERTY_INDICATE)
})

test('multiple options compose into bitmask', (t) => {
  const char = new Characteristic('0000', { read: true, write: true, notify: true })
  const expected =
    Characteristic.PROPERTY_READ | Characteristic.PROPERTY_WRITE | Characteristic.PROPERTY_NOTIFY
  t.is(char.properties, expected)
})

test('explicit permissions override inference', (t) => {
  const char = new Characteristic('0000', { permissions: 0x04 })
  t.is(char.permissions, 0x04)
})

test('value is stored', (t) => {
  const data = new Uint8Array([0x01, 0x02])
  const char = new Characteristic('0000', { value: data })
  t.alike(char.value, data)
})

test('value is mutable', (t) => {
  const data = new Uint8Array([0x01, 0x02])
  const char = new Characteristic('0000', { value: data })
  const newData = new Uint8Array([0x03])

  char.value = newData

  t.alike(char.value, newData)
})

test('property constants are correct', (t) => {
  t.is(Characteristic.PROPERTY_READ, 0x02)
  t.is(Characteristic.PROPERTY_WRITE_WITHOUT_RESPONSE, 0x04)
  t.is(Characteristic.PROPERTY_WRITE, 0x08)
  t.is(Characteristic.PROPERTY_NOTIFY, 0x10)
  t.is(Characteristic.PROPERTY_INDICATE, 0x20)
})
