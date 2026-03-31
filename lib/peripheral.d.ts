import { EventEmitter } from 'bare-events'
import Service from './service'
import Characteristic from './characteristic'
import L2CAPChannel from './channel'

export interface PeripheralOptions {
  connectHandle?: ArrayBuffer
  id?: string
  name?: string
}

/**
 * Bluetooth Peripheral - represents a connected or discovered peripheral device
 */
export default class Peripheral extends EventEmitter {
  constructor(peripheralHandle: ArrayBuffer, opts?: PeripheralOptions)

  /** The peripheral UUID identifier */
  readonly id: string

  /** The peripheral name, if available */
  readonly name: string | null

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

  // Events
  on(
    event: 'servicesDiscover',
    listener: (services: Service[] | null, error?: string) => void
  ): this
  on(
    event: 'characteristicsDiscover',
    listener: (service: string, characteristics: Characteristic[] | null, error?: string) => void
  ): this
  on(
    event: 'read',
    listener: (characteristic: string, data: Uint8Array, error?: string) => void
  ): this
  on(event: 'write', listener: (characteristic: string, error?: string) => void): this
  on(
    event: 'notify',
    listener: (characteristic: string, data: Uint8Array, error?: string) => void
  ): this
  on(
    event: 'notifyState',
    listener: (characteristic: string, isNotifying: boolean, error?: string) => void
  ): this
  on(event: 'channelOpen', listener: (channel: L2CAPChannel | null, error?: string) => void): this
}
