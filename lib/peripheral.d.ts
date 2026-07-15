import { EventEmitter, EventMap } from 'bare-events'
import Central from './central'
import Service from './service'
import Characteristic from './characteristic'
import L2CAPChannel from './channel'
import BluetoothError from './errors'

export interface PeripheralOptions {
  central?: Central
  /** The unique identifier of the peripheral. */
  id?: string
  /** The name of the peripheral, if available. */
  name?: string
  /** A snapshot of the `serviceData` from the most recent advertisement seen for this peripheral before connect or `null`. Service data is only in advertisement packets, so this value never updates after connect. */
  serviceData?: { [uuid: string]: Uint8Array } | null
}

export interface PeripheralEventMap extends EventMap {
  error: [error: BluetoothError]
  servicesDiscover: [services: Service[]]
  characteristicsDiscover: [service: Service | null, characteristics: Characteristic[]]
  /**
   * Read the value of a `characteristic`.
   * @param characteristic - The characteristic to read.
   */
  read: [characteristic: Characteristic | null, data: Uint8Array | null]
  /**
   * Write `data` to a `characteristic`. If `withResponse` is `true` (the default), the write will be confirmed by the peripheral.
   * @param characteristic - The characteristic to write to.
   * @param data - The bytes to write.
   * @param withResponse - Whether the peripheral confirms the write (default `true`).
   */
  write: [characteristic: Characteristic | null]
  notify: [characteristic: Characteristic | null, data: Uint8Array | null]
  notifyState: [characteristic: Characteristic | null, isNotifying: boolean]
  channelOpen: [channel: L2CAPChannel]
}

/**
 * Bluetooth Peripheral - represents a connected or discovered peripheral device
 */
export default class Peripheral extends EventEmitter<PeripheralEventMap> {
  /**
   * @param peripheralHandle - The native peripheral handle; supplied internally when Central emits `'connect'`, not usually passed directly.
   * @param opts - Options carrying the peripheral's advertised metadata.
   */
  constructor(peripheralHandle: ArrayBuffer, opts?: PeripheralOptions)

  /** The peripheral UUID identifier */
  readonly id: string

  /** The peripheral name, if available */
  readonly name: string | null

  /** Service data captured from the most recent advertisement seen before connect, or null */
  readonly serviceData: { [uuid: string]: Uint8Array } | null

  /**
   * @param serviceUUIDs - The service UUIDs to discover; omit to discover all services.
   */
  discoverServices(serviceUUIDs?: string[]): void
  /**
   * @param service - The service to discover characteristics on.
   * @param characteristicUUIDs - The characteristic UUIDs to discover; omit to discover all characteristics of the service.
   */
  discoverCharacteristics(service: Service, characteristicUUIDs?: string[]): void
  /**
   * @param characteristic - The characteristic to read.
   */
  read(characteristic: Characteristic): void
  /**
   * @param characteristic - The characteristic to write to.
   * @param data - The bytes to write.
   * @param withResponse - Whether the peripheral confirms the write (default `true`).
   */
  write(characteristic: Characteristic, data: Uint8Array, withResponse?: boolean): void
  /**
   * @param characteristic - The characteristic to start receiving notifications for.
   */
  subscribe(characteristic: Characteristic): void
  /**
   * @param characteristic - The characteristic to stop receiving notifications for.
   */
  unsubscribe(characteristic: Characteristic): void
  /**
   * @param psm - The PSM (Protocol/Service Multiplexer) of the channel to open.
   */
  openL2CAPChannel(psm: number): void
  /** Destroy the instance and release all resources. */
  destroy(): void

  // Property constants
  static readonly PROPERTY_READ: number
  static readonly PROPERTY_WRITE_WITHOUT_RESPONSE: number
  static readonly PROPERTY_WRITE: number
  static readonly PROPERTY_NOTIFY: number
  /** Characteristic property flags. */
  static readonly PROPERTY_INDICATE: number
}
