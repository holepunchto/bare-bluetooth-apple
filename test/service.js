const test = require('brittle')
const Service = require('../lib/service')
const Characteristic = require('../lib/characteristic')

test('construction with uuid only', (t) => {
  const svc = new Service('1234')
  t.is(svc.uuid, '1234')
  t.alike(svc.characteristics, [])
  t.is(svc.primary, true)
})

test('construction with characteristics', (t) => {
  const charA = new Characteristic('AAAA', { read: true })
  const charB = new Characteristic('BBBB', { write: true })
  const svc = new Service('1234', [charA, charB])

  t.is(svc.characteristics.length, 2)
  t.is(svc.characteristics[0], charA)
  t.is(svc.characteristics[1], charB)
})

test('primary defaults to true', (t) => {
  const svc = new Service('1234')
  t.is(svc.primary, true)
})

test('primary can be set to false', (t) => {
  const svc = new Service('1234', [], { primary: false })
  t.is(svc.primary, false)
})

test('null characteristics defaults to empty array', (t) => {
  const svc = new Service('1234', null)
  t.alike(svc.characteristics, [])
})
