# bare-bluetooth-apple

CoreBluetooth bindings for Bare. Provides BLE central and peripheral roles, GATT services and characteristics, and L2CAP channels on Apple platforms.

```
npm i bare-bluetooth-apple
```

## Usage

```js
const bluetooth = require('bare-bluetooth-apple')

const manager = new bluetooth.PeripheralManager()

manager.on('stateChange', (state) => {
  if (state !== 'poweredOn') return

  const char = new bluetooth.Characteristic('01230001-0000-1000-8000-00805F9B34FB', {
    write: true,
    notify: true
  })

  const service = new bluetooth.Service('01230000-0000-1000-8000-00805F9B34FB', [char])
  manager.addService(service)
})

manager.on('serviceAdd', (uuid, error) => {
  if (error) return

  manager.startAdvertising({
    name: 'MyDevice',
    serviceUUIDs: ['01230000-0000-1000-8000-00805F9B34FB']
  })
})

manager.on('error', (err) => {
  console.error('manager error:', err.code, err.message)
})

manager.on('writeRequest', (requests) => {
  // Handle incoming write requests
  manager.respondToRequest(requests[0], bluetooth.PeripheralManager.ATT_SUCCESS, null)
})
```

## API

See the [`bare-bluetooth-apple` reference](https://docs.pears.com/reference/bare/modules/bare-bluetooth-apple).

## Running the tests under ASan

`./run-test-asan` rebuilds the addon with AddressSanitizer and runs `test.js` (or the file you pass) under an ASan-instrumented `bare`. It refuses to run if that `bare` is missing or not instrumented.

```
./run-test-asan                       # whole suite
./run-test-asan test/peripheral.js    # one file
BARE=/path/to/bare ./run-test-asan    # another bare
```

## License

Apache-2.0
