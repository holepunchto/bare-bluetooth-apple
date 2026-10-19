const test = require('brittle')

require('./test/characteristic')
require('./test/central')
require('./test/peripheral')
require('./test/peripheral-manager')
require('./test/service')

test('exit', (t) => t.pass()).then(() => Bare.emit('beforeExit'))
