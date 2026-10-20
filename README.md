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

See <https://github.com/holepunchto/bare#sanitizers> for building that `bare`.

```
./run-test-asan                       # whole suite
./run-test-asan test/peripheral.js    # one file
BARE=/path/to/bare ./run-test-asan    # another bare
```

## Running the tests

The tests drive a real radio. `npm test` packs them into an app and launches it on this Mac and streams the TAP output.

To run them on an iPhone instead, build the addon for it:

```console
bare-make generate --platform ios --arch arm64
bare-make build
bare-make install
```

Then put the signing options in `test/signing.json`: a provisioning profile that covers the phone, and the identity to sign with if the keychain holds several.

```json
{
  "identity": "Apple Development: Jane Doe (TEAMID)",
  "provisioningProfile": "/Users/jane/Library/Developer/Xcode/UserData/Provisioning Profiles/<id>.mobileprovision"
}
```

Plug the phone in and run:

```console
npm test -- --platform ios
```

The first run waits on the Bluetooth prompt on the phone, which iOS then remembers.

## License

Apache-2.0
