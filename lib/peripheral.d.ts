import { EventEmitter, EventMap } from 'bare-events'
import Central from './central'
import Service from './service'
import Characteristic from './characteristic'
import L2CAPChannel from './channel'
import BluetoothError from './errors'

export interface PeripheralOptions {
  central?: Central
  id?: string
  name?: string
  serviceData?: { [uuid: string]: Uint8Array } | null
}

export interface PeripheralEventMap extends EventMap {
  error: [error: BluetoothError]
  servicesDiscover: [services: Service[]]
  characteristicsDiscover: [service: Service | null, characteristics: Characteristic[]]
  read: [characteristic: Characteristic | null, data: Uint8Array | null]
  write: [characteristic: Characteristic | null]
  notify: [characteristic: Characteristic | null, data: Uint8Array | null]
  notifyState: [characteristic: Characteristic | null, isNotifying: boolean]
  channelOpen: [channel: L2CAPChannel]
}

/**
 * Bluetooth Peripheral - represents a connected or discovered peripheral device
 */
export default class Peripheral extends EventEmitter<PeripheralEventMap> {
  constructor(peripheralHandle: ArrayBuffer, opts?: PeripheralOptions)

  /** The peripheral UUID identifier */
  readonly id: string

  /** The peripheral name, if available */
  readonly name: string | null

  /** Service data captured from the most recent advertisement seen before connect, or null */
  readonly serviceData: { [uuid: string]: Uint8Array } | null

  discoverServices(serviceUUIDs?: string[]): void
  discoverCharacteristics(service: Service, characteristicUUIDs?: string[]): void
  read(characteristic: Characteristic): void
  write(characteristic: Characteristic, data: Uint8Array, withResponse?: boolean): void
  subscribe(characteristic: Characteristic): void
  unsubscribe(characteristic: Characteristic): void
  openL2CAPChannel(psm: number): void
  destroy(): void

  // Property constants
  static readonly PROPERTY_READ: number
  static readonly PROPERTY_WRITE_WITHOUT_RESPONSE: number
  static readonly PROPERTY_WRITE: number
  static readonly PROPERTY_NOTIFY: number
  static readonly PROPERTY_INDICATE: number
}
