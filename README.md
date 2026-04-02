# bare-bluetooth-apple

CoreBluetooth bindings for Bare. Provides BLE central and peripheral roles, GATT services and characteristics, and L2CAP channels on Apple platforms.

```
npm i bare-bluetooth-apple
```

## Usage

```js
const bluetooth = require('bare-bluetooth-apple')

const server = new bluetooth.Server()

server.on('stateChange', (state) => {
  if (state !== 'poweredOn') return

  const char = new bluetooth.Characteristic('01230001-0000-1000-8000-00805F9B34FB', {
    write: true,
    notify: true
  })

  const service = new bluetooth.Service('01230000-0000-1000-8000-00805F9B34FB', [char])
  server.addService(service)
})

server.on('serviceAdd', (uuid, error) => {
  if (error) return

  server.startAdvertising({
    name: 'MyDevice',
    serviceUUIDs: ['01230000-0000-1000-8000-00805F9B34FB']
  })
})

server.on('writeRequest', (requests) => {
  // Handle incoming write requests
  server.respondToRequest(requests[0], bluetooth.Server.ATT_SUCCESS, null)
})
```

## API

#### `const central = new Central()`

Create a new BLE central manager. The central scans for and connects to peripherals.

#### `central.state`

The current Bluetooth state. One of `'unknown'`, `'resetting'`, `'unsupported'`, `'unauthorized'`, `'poweredOff'`, or `'poweredOn'`.

#### `central.startScan([serviceUUIDs])`

Start scanning for peripherals. If `serviceUUIDs` is provided, only peripherals advertising those services will be discovered.

#### `central.stopScan()`

Stop scanning for peripherals.

#### `central.connect(peripheral)`

Connect to a discovered `peripheral`.

#### `central.disconnect(peripheral)`

Disconnect from a connected `peripheral`.

#### `central.destroy()`

Destroy the central manager and release all resources.

#### `event: 'stateChange'`

Emitted with `state` when the Bluetooth state changes.

#### `event: 'discover'`

Emitted with `peripheral` when a peripheral is discovered during scanning. The `peripheral` object has `handle`, `id`, `name`, and `rssi` properties.

#### `event: 'connect'`

Emitted with `peripheral` when a connection to a peripheral is established. The `peripheral` is a `Peripheral` instance.

#### `event: 'disconnect'`

Emitted with `peripheral` and `error` when a peripheral disconnects.

#### `event: 'connectFail'`

Emitted with `id` and `error` when a connection attempt fails.

#### `const server = new Server()`

Create a new BLE peripheral manager (server). The server advertises services and handles read/write requests from centrals.

#### `server.state`

The current Bluetooth state. One of `'unknown'`, `'resetting'`, `'unsupported'`, `'unauthorized'`, `'poweredOff'`, or `'poweredOn'`.

#### `server.addService(service)`

Add a `service` to the server. The service and its characteristics will be registered with the system.

#### `server.startAdvertising([options])`

Start advertising the server.

Options include:

```js
options = {
  name: null,
  serviceUUIDs: null
}
```

#### `server.stopAdvertising()`

Stop advertising.

#### `server.respondToRequest(request, result[, data])`

Respond to a read or write `request` with the given ATT `result` code. Optionally include `data` for read responses.

#### `server.updateValue(characteristic, data)`

Update the value of a `characteristic` and notify subscribed centrals. Returns `true` if the update was sent successfully.

#### `server.publishChannel([options])`

Publish an L2CAP channel.

Options include:

```js
options = {
  encrypted: false
}
```

#### `server.unpublishChannel(psm)`

Unpublish a previously published L2CAP channel identified by `psm`.

#### `server.destroy()`

Destroy the server and release all resources.

#### `event: 'stateChange'`

Emitted with `state` when the Bluetooth state changes.

#### `event: 'serviceAdd'`

Emitted with `uuid` and `error` when a service has been added.

#### `event: 'readRequest'`

Emitted with `request` when a central reads a characteristic. The `request` object has `handle`, `characteristicUuid`, and `offset` properties.

#### `event: 'writeRequest'`

Emitted with `requests` when a central writes to a characteristic. Each request has `handle`, `characteristicUuid`, `data`, and `offset` properties.

#### `event: 'subscribe'`

Emitted with `centralHandle` and `characteristicUuid` when a central subscribes to notifications.

#### `event: 'unsubscribe'`

Emitted with `centralHandle` and `characteristicUuid` when a central unsubscribes from notifications.

#### `event: 'readyToUpdate'`

Emitted when the server is ready to send another update after a previous `updateValue()` returned `false`.

#### `event: 'channelPublish'`

Emitted with `psm` and `error` when an L2CAP channel is published.

#### `event: 'channelOpen'`

Emitted with `channel` and `error` when an L2CAP channel is opened. The `channel` is an `L2CAPChannel` instance.

#### `const peripheral = new Peripheral(peripheralHandle[, options])`

Represents a connected BLE peripheral. Obtained through the `'connect'` event on `Central`.

Options include:

```js
options = {
  id: null,
  name: null,
  connectHandle: null
}
```

#### `peripheral.id`

The unique identifier of the peripheral.

#### `peripheral.name`

The advertised name of the peripheral.

#### `peripheral.discoverServices([serviceUUIDs])`

Discover services on the peripheral. If `serviceUUIDs` is provided, only those services will be discovered.

#### `peripheral.discoverCharacteristics(service[, characteristicUUIDs])`

Discover characteristics for a `service`. If `characteristicUUIDs` is provided, only those characteristics will be discovered.

#### `peripheral.read(characteristic)`

Read the value of a `characteristic`.

#### `peripheral.write(characteristic, data[, withResponse])`

Write `data` to a `characteristic`. If `withResponse` is `true` (the default), the write will be confirmed by the peripheral.

#### `peripheral.subscribe(characteristic)`

Subscribe to notifications for a `characteristic`.

#### `peripheral.unsubscribe(characteristic)`

Unsubscribe from notifications for a `characteristic`.

#### `peripheral.openL2CAPChannel(psm)`

Open an L2CAP channel to the peripheral using the given `psm`.

#### `peripheral.destroy()`

Destroy the peripheral instance and release resources.

#### `event: 'servicesDiscover'`

Emitted with `services` and `error` when services are discovered.

#### `event: 'characteristicsDiscover'`

Emitted with `service`, `characteristics`, and `error` when characteristics are discovered.

#### `event: 'read'`

Emitted with `characteristic`, `data`, and `error` when a characteristic value is read.

#### `event: 'write'`

Emitted with `characteristic` and `error` when a characteristic write completes.

#### `event: 'notify'`

Emitted with `characteristic`, `data`, and `error` when a notification is received.

#### `event: 'notifyState'`

Emitted with `characteristic`, `isNotifying`, and `error` when the notification state changes.

#### `event: 'channelOpen'`

Emitted with `channel` and `error` when an L2CAP channel is opened.

#### `const service = new Service(uuid[, characteristics][, options])`

Create a GATT service definition.

Options include:

```js
options = {
  primary: true
}
```

#### `service.uuid`

The UUID of the service.

#### `service.characteristics`

The list of characteristics belonging to the service.

#### `service.primary`

Whether the service is a primary service.

#### `const characteristic = new Characteristic(uuid[, options])`

Create a GATT characteristic definition.

Options include:

```js
options = {
  read: false,
  write: false,
  writeWithoutResponse: false,
  notify: false,
  indicate: false,
  permissions: null,
  value: null
}
```

Setting `read`, `write`, `writeWithoutResponse`, `notify`, or `indicate` to `true` enables the corresponding characteristic property.

#### `characteristic.uuid`

The UUID of the characteristic.

#### `characteristic.properties`

The bitmask of characteristic properties.

#### `characteristic.permissions`

The bitmask of characteristic permissions, or `null` if permissions are inferred from properties.

#### `characteristic.value`

The static value of the characteristic, or `null`.

#### `const channel = new L2CAPChannel(channelHandle)`

An L2CAP channel, obtained through the `'channelOpen'` event on `Server` or `Peripheral`. Extends `Duplex` from `bare-stream` and supports standard readable and writable stream operations.

#### `channel.psm`

The Protocol/Service Multiplexer number of the channel.

#### `channel.peer`

The peer identifier of the channel.

### Constants

#### `Server.STATE_UNKNOWN`

#### `Server.STATE_POWERED_ON`

#### `Server.STATE_POWERED_OFF`

#### `Server.STATE_RESETTING`

#### `Server.STATE_UNAUTHORIZED`

#### `Server.STATE_UNSUPPORTED`

Bluetooth state constants.

#### `Server.PROPERTY_READ`

#### `Server.PROPERTY_WRITE_WITHOUT_RESPONSE`

#### `Server.PROPERTY_WRITE`

#### `Server.PROPERTY_NOTIFY`

#### `Server.PROPERTY_INDICATE`

Characteristic property flags.

#### `Server.PERMISSION_READABLE`

#### `Server.PERMISSION_WRITEABLE`

#### `Server.PERMISSION_READ_ENCRYPTED`

#### `Server.PERMISSION_WRITE_ENCRYPTED`

Characteristic permission flags.

#### `Server.ATT_SUCCESS`

#### `Server.ATT_INVALID_HANDLE`

#### `Server.ATT_READ_NOT_PERMITTED`

#### `Server.ATT_WRITE_NOT_PERMITTED`

#### `Server.ATT_INSUFFICIENT_RESOURCES`

#### `Server.ATT_UNLIKELY_ERROR`

ATT result codes for use with `server.respondToRequest()`.

## License

Apache-2.0
