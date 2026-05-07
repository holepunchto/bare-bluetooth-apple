export { default as L2CAPChannel } from './lib/channel'
export { default as Service, ServiceOptions } from './lib/service'
export { default as Characteristic, CharacteristicOptions } from './lib/characteristic'
export {
  default as PeripheralManager,
  BluetoothState,
  AdvertisingOptions,
  ChannelOptions,
  ReadRequest,
  WriteRequest,
  PeripheralManagerEventMap
} from './lib/peripheral-manager'
export { default as Central, DiscoveredPeripheral, CentralEventMap } from './lib/central'
export { default as Peripheral, PeripheralOptions, PeripheralEventMap } from './lib/peripheral'
