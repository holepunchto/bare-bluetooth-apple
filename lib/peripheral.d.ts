import { EventEmitter, EventMap } from 'bare-events'
import Central from './central'
import Service from './service'
import Characteristic from './characteristic'
import L2CAPChannel from './channel'

export interface PeripheralOptions {
  central?: Central
  id?: string
  name?: string
  serviceData?: { [uuid: string]: Uint8Array } | null
}

export interface PeripheralEventMap extends EventMap {
  servicesDiscover: [services: Service[] | null, error?: string]
  characteristicsDiscover: [
    service: string,
    characteristics: Characteristic[] | null,
    error?: string
  ]
  read: [characteristic: string, data: Uint8Array, error?: string]
  write: [characteristic: string, error?: string]
  notify: [characteristic: string, data: Uint8Array, error?: string]
  notifyState: [characteristic: string, isNotifying: boolean, error?: string]
  channelOpen: [channel: L2CAPChannel | null, error?: string]
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
  discoverCharacteristics(service: string, characteristicUUIDs?: string[]): void
  read(characteristic: string): void
  write(characteristic: string, data: Uint8Array, withResponse?: boolean): void
  subscribe(characteristic: string): void
  unsubscribe(characteristic: string): void
  openL2CAPChannel(psm: number): void
  destroy(): void

  // Property constants
  static readonly PROPERTY_READ: number
  static readonly PROPERTY_WRITE_WITHOUT_RESPONSE: number
  static readonly PROPERTY_WRITE: number
  static readonly PROPERTY_NOTIFY: number
  static readonly PROPERTY_INDICATE: number
}
