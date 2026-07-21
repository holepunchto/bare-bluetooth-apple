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

<!-- bare-refgen:api start -->

## API

### L2CAPChannel

#### `new L2CAPChannel(channelHandle: ArrayBuffer)`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/channel.d.ts#L7)

An L2CAP channel, obtained through the `'channelOpen'` event on `PeripheralManager` or `Peripheral`. Extends `Duplex` from `bare-stream` and supports standard readable and writable stream operations.

**Parameters**

| Parameter       | Type          | Default | Description                                                                                                          |
| --------------- | ------------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| `channelHandle` | `ArrayBuffer` | —       | The native channel handle backing the stream; supplied internally when a channel opens, not usually passed directly. |

#### `peer: string | null`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/channel.d.ts#L13)

The UUID of the remote peer if available

#### `psm: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/channel.d.ts#L10)

The L2CAP PSM (Protocol/Service Multiplexer) for this channel

### Service

#### `new Service(uuid: string, characteristics?: Characteristic[], opts?: ServiceOptions)`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/service.d.ts#L7)

Create a GATT service definition.

**Parameters**

| Parameter          | Type               | Default | Description                                                  |
| ------------------ | ------------------ | ------- | ------------------------------------------------------------ |
| `uuid`             | `string`           | —       | The service's UUID.                                          |
| `characteristics?` | `Characteristic[]` | —       | The characteristics belonging to the service.                |
| `opts?`            | `ServiceOptions`   | —       | Options; set `primary: true` to mark this a primary service. |

#### `characteristics: Characteristic[]`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/service.d.ts#L13)

The characteristics belonging to this service

#### `primary: boolean`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/service.d.ts#L16)

Whether this is a primary service

#### `Service.uuid: string`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/service.d.ts#L10)

The service UUID

### Characteristic

#### `new Characteristic(uuid: string, opts?: CharacteristicOptions)`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L5)

Create a GATT characteristic definition.

**Parameters**

| Parameter | Type                    | Default | Description                                                                                                                                                           |
| --------- | ----------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `uuid`    | `string`                | —       | The characteristic's UUID.                                                                                                                                            |
| `opts?`   | `CharacteristicOptions` | —       | Options selecting the characteristic `properties` (`read`, `write`, `writeWithoutResponse`, `notify`, `indicate`) and its optional `permissions` and initial `value`. |

#### `Characteristic.PROPERTY_INDICATE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L24)

#### `Characteristic.PROPERTY_NOTIFY: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L23)

#### `Characteristic.PROPERTY_READ: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L20)

#### `Characteristic.PROPERTY_WRITE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L22)

#### `Characteristic.PROPERTY_WRITE_WITHOUT_RESPONSE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L21)

#### `permissions: number | null`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L14)

Bitmask of characteristic permissions, if set explicitly

#### `properties: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L11)

Bitmask of characteristic properties

#### `Characteristic.uuid: string`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L8)

The characteristic UUID

#### `value: Uint8Array | null`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L17)

The current value, if set

### PeripheralManager

#### `new PeripheralManager()`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L48)

Create a new BLE peripheral manager. Advertises services and handles read/write requests from centrals.

#### `addService(service: Service): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L53)

Add a `service` to the manager. The service and its characteristics will be registered with the system.

**Parameters**

| Parameter | Type      | Default | Description                                                                |
| --------- | --------- | ------- | -------------------------------------------------------------------------- |
| `service` | `Service` | —       | The `Service` to register with the system, along with its characteristics. |

#### `PeripheralManager.destroy(): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L60)

Destroy the instance and release all resources.

#### `PeripheralManager.ATT_INSUFFICIENT_RESOURCES: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L88)

#### `PeripheralManager.ATT_INVALID_HANDLE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L85)

#### `PeripheralManager.ATT_READ_NOT_PERMITTED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L86)

#### `PeripheralManager.ATT_SUCCESS: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L84)

#### `PeripheralManager.ATT_UNLIKELY_ERROR: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L89)

ATT result codes for use with `manager.respondToRequest()`.

#### `PeripheralManager.ATT_WRITE_NOT_PERMITTED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L87)

#### `PeripheralManager.PERMISSION_READ_ENCRYPTED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L80)

#### `PeripheralManager.PERMISSION_READABLE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L78)

#### `PeripheralManager.PERMISSION_WRITE_ENCRYPTED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L81)

Characteristic permission flags.

#### `PeripheralManager.PERMISSION_WRITEABLE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L79)

#### `PeripheralManager.PROPERTY_INDICATE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L75)

Characteristic property flags.

#### `PeripheralManager.PROPERTY_NOTIFY: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L74)

#### `PeripheralManager.PROPERTY_READ: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L71)

#### `PeripheralManager.PROPERTY_WRITE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L73)

#### `PeripheralManager.PROPERTY_WRITE_WITHOUT_RESPONSE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L72)

#### `PeripheralManager.STATE_POWERED_OFF: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L65)

#### `PeripheralManager.STATE_POWERED_ON: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L64)

#### `PeripheralManager.STATE_RESETTING: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L66)

#### `PeripheralManager.STATE_UNAUTHORIZED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L67)

#### `PeripheralManager.STATE_UNKNOWN: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L63)

#### `PeripheralManager.STATE_UNSUPPORTED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L68)

Bluetooth state constants.

#### `publishChannel(opts?: ChannelOptions): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L58)

Publish an L2CAP channel.

**Parameters**

| Parameter | Type             | Default | Description                               |
| --------- | ---------------- | ------- | ----------------------------------------- |
| `opts?`   | `ChannelOptions` | —       | Options for the L2CAP channel to publish. |

#### `respondToRequest(request: ReadRequest, result: number, data?: Uint8Array | null): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L56)

Respond to a read or write `request` with the given ATT `result` code. Optionally include `data` for read responses.

**Parameters**

| Parameter | Type                 | Default | Description                                                                                          |
| --------- | -------------------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `request` | `ReadRequest`        | —       | The read or write request to respond to, as delivered by the `'readRequest'`/`'writeRequest'` event. |
| `result`  | `number`             | —       | The ATT result code, e.g. `PeripheralManager.ATT_SUCCESS`.                                           |
| `data?`   | `Uint8Array \| null` | —       | The value to return for a read request; omit for write responses.                                    |

#### `startAdvertising(opts?: AdvertisingOptions): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L54)

Start advertising.

**Parameters**

| Parameter | Type                 | Default | Description                                                                       |
| --------- | -------------------- | ------- | --------------------------------------------------------------------------------- |
| `opts?`   | `AdvertisingOptions` | —       | Advertising options such as the local `name` and the `serviceUUIDs` to advertise. |

#### `PeripheralManager.state: BluetoothState`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L51)

The current Bluetooth adapter state

#### `stopAdvertising(): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L55)

Stop advertising.

#### `unpublishChannel(psm: number): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L59)

Unpublish a previously published L2CAP channel identified by `psm`.

**Parameters**

| Parameter | Type     | Default | Description                                                             |
| --------- | -------- | ------- | ----------------------------------------------------------------------- |
| `psm`     | `number` | —       | The PSM of the channel to unpublish, as assigned when it was published. |

#### `updateValue(characteristic: Characteristic, data: Uint8Array): boolean`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L57)

Update the value of a `characteristic` and notify subscribed centrals.

**Parameters**

| Parameter        | Type             | Default | Description                                   |
| ---------------- | ---------------- | ------- | --------------------------------------------- |
| `characteristic` | `Characteristic` | —       | The characteristic whose value changed.       |
| `data`           | `Uint8Array`     | —       | The new value to send to subscribed centrals. |

**Returns** `boolean` — Whether the notification was sent to subscribed centrals successfully.

### Central

#### `new Central()`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L27)

Create a new BLE central manager. The central scans for and connects to peripherals.

#### `Central.STATE_POWERED_OFF: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L41)

#### `Central.STATE_POWERED_ON: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L40)

#### `Central.STATE_RESETTING: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L42)

#### `Central.STATE_UNAUTHORIZED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L43)

#### `Central.STATE_UNKNOWN: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L39)

#### `Central.STATE_UNSUPPORTED: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L44)

#### `connect(peripheral: DiscoveredPeripheral): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L34)

Connect to a discovered `peripheral`.

**Parameters**

| Parameter    | Type                   | Default | Description                            |
| ------------ | ---------------------- | ------- | -------------------------------------- |
| `peripheral` | `DiscoveredPeripheral` | —       | A discovered peripheral to connect to. |

#### `Central.destroy(): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L36)

Destroy the instance and release all resources.

#### `disconnect(peripheral: Peripheral): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L35)

Disconnect from a connected `peripheral`.

**Parameters**

| Parameter    | Type         | Default | Description                                  |
| ------------ | ------------ | ------- | -------------------------------------------- |
| `peripheral` | `Peripheral` | —       | The connected peripheral to disconnect from. |

#### `startScan(serviceUUIDs?: string[]): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L32)

Start scanning for peripherals. If `serviceUUIDs` is provided, only peripherals advertising those services will be discovered.

**Parameters**

| Parameter       | Type       | Default | Description                                                                      |
| --------------- | ---------- | ------- | -------------------------------------------------------------------------------- |
| `serviceUUIDs?` | `string[]` | —       | The service UUIDs to filter advertisements by; omit to discover all peripherals. |

#### `Central.state: BluetoothState`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L30)

The current Bluetooth adapter state

#### `stopScan(): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L33)

Stop scanning for peripherals.

### Peripheral

#### `new Peripheral(peripheralHandle: ArrayBuffer, opts?: PeripheralOptions)`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L30)

Represents a connected BLE peripheral. Obtained through the `'connect'` event on `Central` — not typically constructed directly.

**Parameters**

| Parameter          | Type                | Default | Description                                                                                                    |
| ------------------ | ------------------- | ------- | -------------------------------------------------------------------------------------------------------------- |
| `peripheralHandle` | `ArrayBuffer`       | —       | The native peripheral handle; supplied internally when Central emits `'connect'`, not usually passed directly. |
| `opts?`            | `PeripheralOptions` | —       | Options carrying the peripheral's advertised metadata.                                                         |

#### `Peripheral.destroy(): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L48)

Destroy the instance and release all resources.

#### `discoverCharacteristics(service: Service, characteristicUUIDs?: string[]): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L42)

Discover characteristics for a `service`. If `characteristicUUIDs` is provided, only those characteristics will be discovered.

**Parameters**

| Parameter              | Type       | Default | Description                                                                                |
| ---------------------- | ---------- | ------- | ------------------------------------------------------------------------------------------ |
| `service`              | `Service`  | —       | The service to discover characteristics on.                                                |
| `characteristicUUIDs?` | `string[]` | —       | The characteristic UUIDs to discover; omit to discover all characteristics of the service. |

#### `discoverServices(serviceUUIDs?: string[]): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L41)

Discover services on the peripheral. If `serviceUUIDs` is provided, only those services will be discovered.

**Parameters**

| Parameter       | Type       | Default | Description                                                   |
| --------------- | ---------- | ------- | ------------------------------------------------------------- |
| `serviceUUIDs?` | `string[]` | —       | The service UUIDs to discover; omit to discover all services. |

#### `id: string`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L33)

The peripheral UUID identifier

#### `name: string | null`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L36)

The peripheral name, if available

#### `openL2CAPChannel(psm: number): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L47)

Open an L2CAP channel to the peripheral using the given `psm`.

**Parameters**

| Parameter | Type     | Default | Description                                                    |
| --------- | -------- | ------- | -------------------------------------------------------------- |
| `psm`     | `number` | —       | The PSM (Protocol/Service Multiplexer) of the channel to open. |

#### `Peripheral.PROPERTY_INDICATE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L55)

#### `Peripheral.PROPERTY_NOTIFY: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L54)

#### `Peripheral.PROPERTY_READ: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L51)

#### `Peripheral.PROPERTY_WRITE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L53)

#### `Peripheral.PROPERTY_WRITE_WITHOUT_RESPONSE: number`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L52)

#### `read(characteristic: Characteristic): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L43)

Read the value of a `characteristic`.

**Parameters**

| Parameter        | Type             | Default | Description                 |
| ---------------- | ---------------- | ------- | --------------------------- |
| `characteristic` | `Characteristic` | —       | The characteristic to read. |

#### `serviceData: { [uuid: string]: Uint8Array } | null`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L39)

Service data captured from the most recent advertisement seen before connect, or null

#### `subscribe(characteristic: Characteristic): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L45)

Subscribe to notifications for a `characteristic`.

**Parameters**

| Parameter        | Type             | Default | Description                                              |
| ---------------- | ---------------- | ------- | -------------------------------------------------------- |
| `characteristic` | `Characteristic` | —       | The characteristic to start receiving notifications for. |

#### `unsubscribe(characteristic: Characteristic): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L46)

Unsubscribe from notifications for a `characteristic`.

**Parameters**

| Parameter        | Type             | Default | Description                                             |
| ---------------- | ---------------- | ------- | ------------------------------------------------------- |
| `characteristic` | `Characteristic` | —       | The characteristic to stop receiving notifications for. |

#### `write(characteristic: Characteristic, data: Uint8Array, withResponse?: boolean): void`

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L44)

Write `data` to a `characteristic`. If `withResponse` is `true` (the default), the write will be confirmed by the peripheral.

**Parameters**

| Parameter        | Type             | Default | Description                                                 |
| ---------------- | ---------------- | ------- | ----------------------------------------------------------- |
| `characteristic` | `Characteristic` | —       | The characteristic to write to.                             |
| `data`           | `Uint8Array`     | —       | The bytes to write.                                         |
| `withResponse?`  | `boolean`        | —       | Whether the peripheral confirms the write (default `true`). |

### Types

#### `ServiceOptions`

```ts
interface ServiceOptions {
  primary?: boolean
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/service.d.ts#L19)

#### `CharacteristicOptions`

```ts
interface CharacteristicOptions {
  read?: boolean
  write?: boolean
  writeWithoutResponse?: boolean
  notify?: boolean
  indicate?: boolean
  permissions?: number
  value?: Uint8Array | null
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/characteristic.d.ts#L27)

#### `BluetoothState`

```ts
type BluetoothState =
  | 'unknown'
  | 'resetting'
  | 'unsupported'
  | 'unauthorized'
  | 'poweredOff'
  | 'poweredOn'
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L7)

#### `AdvertisingOptions`

```ts
interface AdvertisingOptions {
  name?: string
  serviceUUIDs?: string[]
  serviceData?: { [uuid: string]: Uint8Array }
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L10)

#### `ChannelOptions`

```ts
interface ChannelOptions {
  encrypted?: boolean
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L16)

#### `ReadRequest`

```ts
interface ReadRequest {
  characteristicUuid: string
  offset: number
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L20)

#### `WriteRequest`

```ts
interface WriteRequest {
  characteristicUuid: string
  data: Uint8Array
  offset: number
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L25)

#### `PeripheralManagerEventMap`

```ts
interface PeripheralManagerEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  error: [error: BluetoothError]
  serviceAdd: [uuid: string]
  channelPublish: [psm: number]
  channelOpen: [channel: L2CAPChannel]
  readRequest: [request: ReadRequest]
  writeRequest: [requests: WriteRequest[]]
  subscribe: [centralHandle: ArrayBuffer, characteristicUuid: string]
  unsubscribe: [centralHandle: ArrayBuffer, characteristicUuid: string]
  readyToUpdate: []
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral-manager.d.ts#L31)

#### `DiscoveredPeripheral`

```ts
interface DiscoveredPeripheral {
  id: string
  name: string | null
  rssi: number
  serviceData: { [uuid: string]: Uint8Array } | null
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L8)

#### `CentralEventMap`

```ts
interface CentralEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  error: [error: BluetoothError]
  discover: [peripheral: DiscoveredPeripheral]
  connect: [peripheral: Peripheral]
  disconnect: [peripheral: Peripheral | null]
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/central.d.ts#L15)

#### `PeripheralOptions`

```ts
interface PeripheralOptions {
  central?: Central
  id?: string
  name?: string
  serviceData?: { [uuid: string]: Uint8Array } | null
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L8)

#### `PeripheralEventMap`

```ts
interface PeripheralEventMap extends EventMap {
  error: [error: BluetoothError]
  servicesDiscover: [services: Service[]]
  characteristicsDiscover: [service: Service | null, characteristics: Characteristic[]]
  read: [characteristic: Characteristic | null, data: Uint8Array | null]
  write: [characteristic: Characteristic | null]
  notify: [characteristic: Characteristic | null, data: Uint8Array | null]
  notifyState: [characteristic: Characteristic | null, isNotifying: boolean]
  channelOpen: [channel: L2CAPChannel]
}
```

[source](https://github.com/holepunchto/bare-bluetooth-apple/blob/v0.3.4/lib/peripheral.d.ts#L15)

<!-- bare-refgen:api end -->

## License

Apache-2.0
