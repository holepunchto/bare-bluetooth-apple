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

Emitted when a peripheral is discovered during scanning. The listener receives a `peripheral` object.

The `peripheral` object has `id`, `name`, `rssi`, and `serviceData` properties. `rssi` is the signal strength reported with the most recent advertisement packet. `serviceData` is an object mapping service UUIDs to `Uint8Array` data, or `null` if no service data was advertised in this packet.

The same `peripheral` reference is reused across discover events for a given `id`; its `rssi` and `serviceData` are updated in place to reflect the latest packet.

#### `event: 'connect'`

Emitted with `peripheral` when a connection to a peripheral is established. The `peripheral` is a `Peripheral` instance.

#### `event: 'disconnect'`

Emitted with `peripheral` and `error` when a peripheral disconnects.

#### `event: 'connectFail'`

Emitted with `id` and `error` when a connection attempt fails.

#### `const manager = new PeripheralManager()`

Create a new BLE peripheral manager. Advertises services and handles read/write requests from centrals.

#### `manager.state`

The current Bluetooth state. One of `'unknown'`, `'resetting'`, `'unsupported'`, `'unauthorized'`, `'poweredOff'`, or `'poweredOn'`.

#### `manager.addService(service)`

Add a `service` to the manager. The service and its characteristics will be registered with the system.

#### `manager.startAdvertising([options])`

Start advertising.

Options include:

```js
options = {
  name: null,
  serviceUUIDs: null,
  serviceData: null
}
```

`serviceData` is an object mapping service UUID strings to `Uint8Array` values. When set, the advertised data will include the given service data, which can be read by scanning centrals without connecting.

#### `manager.stopAdvertising()`

Stop advertising.

#### `manager.respondToRequest(request, result[, data])`

Respond to a read or write `request` with the given ATT `result` code. Optionally include `data` for read responses.

#### `manager.updateValue(characteristic, data)`

Update the value of a `characteristic` and notify subscribed centrals. Returns `true` if the update was sent successfully.

#### `manager.publishChannel([options])`

Publish an L2CAP channel.

Options include:

```js
options = {
  encrypted: false
}
```

#### `manager.unpublishChannel(psm)`

Unpublish a previously published L2CAP channel identified by `psm`.

#### `manager.destroy()`

Destroy the manager and release all resources.

#### `event: 'stateChange'`

Emitted with `state` when the Bluetooth state changes.

#### `event: 'serviceAdd'`

Emitted with `uuid` and `error` when a service has been added.

#### `event: 'error'`

Emitted with an `Error` when an operation fails asynchronously, such as advertising failing to start after `startAdvertising()`. Use `err.code` to distinguish the kind of error, e.g. `'ADVERTISE_FAILED'`.

#### `event: 'readRequest'`

Emitted with `request` when a central reads a characteristic. The `request` object has `characteristicUuid` and `offset` properties.

#### `event: 'writeRequest'`

Emitted with `requests` when a central writes to a characteristic. Each request has `characteristicUuid`, `data`, and `offset` properties.

#### `event: 'subscribe'`

Emitted with `centralHandle` and `characteristicUuid` when a central subscribes to notifications.

#### `event: 'unsubscribe'`

Emitted with `centralHandle` and `characteristicUuid` when a central unsubscribes from notifications.

#### `event: 'readyToUpdate'`

Emitted when the manager is ready to send another update after a previous `updateValue()` returned `false`.

#### `event: 'channelPublish'`

Emitted with `psm` and `error` when an L2CAP channel is published.

#### `event: 'channelOpen'`

Emitted with `channel` and `error` when an L2CAP channel is opened. The `channel` is an `L2CAPChannel` instance.

#### `const peripheral = new Peripheral(peripheralHandle[, options])`

Represents a connected BLE peripheral. Obtained through the `'connect'` event on `Central` — not typically constructed directly.

#### `peripheral.id`

The unique identifier of the peripheral.

#### `peripheral.name`

The advertised name of the peripheral.

#### `peripheral.serviceData`

A snapshot of the `serviceData` from the most recent advertisement seen for this peripheral before connect or `null`. Service data is only in advertisement packets, so this value never updates after connect.

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

An L2CAP channel, obtained through the `'channelOpen'` event on `PeripheralManager` or `Peripheral`. Extends `Duplex` from `bare-stream` and supports standard readable and writable stream operations.

#### `channel.psm`

The Protocol/Service Multiplexer number of the channel.

#### `channel.peer`

The peer identifier of the channel.

### Constants

#### `PeripheralManager.STATE_UNKNOWN`

#### `PeripheralManager.STATE_POWERED_ON`

#### `PeripheralManager.STATE_POWERED_OFF`

#### `PeripheralManager.STATE_RESETTING`

#### `PeripheralManager.STATE_UNAUTHORIZED`

#### `PeripheralManager.STATE_UNSUPPORTED`

Bluetooth state constants.

#### `PeripheralManager.PROPERTY_READ`

#### `PeripheralManager.PROPERTY_WRITE_WITHOUT_RESPONSE`

#### `PeripheralManager.PROPERTY_WRITE`

#### `PeripheralManager.PROPERTY_NOTIFY`

#### `PeripheralManager.PROPERTY_INDICATE`

Characteristic property flags.

#### `PeripheralManager.PERMISSION_READABLE`

#### `PeripheralManager.PERMISSION_WRITEABLE`

#### `PeripheralManager.PERMISSION_READ_ENCRYPTED`

#### `PeripheralManager.PERMISSION_WRITE_ENCRYPTED`

Characteristic permission flags.

#### `PeripheralManager.ATT_SUCCESS`

#### `PeripheralManager.ATT_INVALID_HANDLE`

#### `PeripheralManager.ATT_READ_NOT_PERMITTED`

#### `PeripheralManager.ATT_WRITE_NOT_PERMITTED`

#### `PeripheralManager.ATT_INSUFFICIENT_RESOURCES`

#### `PeripheralManager.ATT_UNLIKELY_ERROR`

ATT result codes for use with `manager.respondToRequest()`.

## License

Apache-2.0
