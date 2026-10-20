const test = require('brittle')

require('./test/characteristic')
require('./test/central')
require('./test/peripheral')
require('./test/peripheral-manager')
require('./test/service')

// brittle only prints its plan on beforeExit, which a GUI runtime never emits.
test('exit', (t) => t.pass()).then(() => Bare.emit('beforeExit'))
