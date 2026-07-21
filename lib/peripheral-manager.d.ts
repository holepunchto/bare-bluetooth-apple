import { EventEmitter, EventMap } from 'bare-events'
import Service from './service'
import Characteristic from './characteristic'
import L2CAPChannel from './channel'
import BluetoothError from './errors'

export type BluetoothState =
  | 'unknown'
  | 'resetting'
  | 'unsupported'
  | 'unauthorized'
  | 'poweredOff'
  | 'poweredOn'

export interface AdvertisingOptions {
  /** The name of the peripheral, if available. */
  name?: string
  serviceUUIDs?: string[]
  /** A snapshot of the `serviceData` from the most recent advertisement seen for this peripheral before connect or `null`. Service data is only in advertisement packets, so this value never updates after connect. */
  serviceData?: { [uuid: string]: Uint8Array }
}

export interface ChannelOptions {
  encrypted?: boolean
}

export interface ReadRequest {
  characteristicUuid: string
  offset: number
}

export interface WriteRequest {
  characteristicUuid: string
  data: Uint8Array
  offset: number
}

export interface PeripheralManagerEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  error: [error: BluetoothError]
  serviceAdd: [uuid: string]
  channelPublish: [psm: number]
  channelOpen: [channel: L2CAPChannel]
  readRequest: [request: ReadRequest]
  writeRequest: [requests: WriteRequest[]]
  /**
   * Subscribe to notifications for a `characteristic`.
   * @param characteristic - The characteristic to start receiving notifications for.
   */
  subscribe: [centralHandle: ArrayBuffer, characteristicUuid: string]
  /**
   * Unsubscribe from notifications for a `characteristic`.
   * @param characteristic - The characteristic to stop receiving notifications for.
   */
  unsubscribe: [centralHandle: ArrayBuffer, characteristicUuid: string]
  readyToUpdate: []
}

/**
 * Bluetooth PeripheralManager - peripheral server for GATT services and L2CAP channels
 */
declare class PeripheralManager extends EventEmitter<PeripheralManagerEventMap> {
  constructor()

  /** The current Bluetooth adapter state */
  readonly state: BluetoothState

  /**
   * @param service - The `Service` to register with the system, along with its characteristics.
   */
  addService(service: Service): void
  /**
   * @param opts - Advertising options such as the local `name` and the `serviceUUIDs` to advertise.
   */
  startAdvertising(opts?: AdvertisingOptions): void
  /** Stop advertising. */
  stopAdvertising(): void
  /**
   * @param request - The read or write request to respond to, as delivered by the `'readRequest'`/`'writeRequest'` event.
   * @param result - The ATT result code, e.g. `PeripheralManager.ATT_SUCCESS`.
   * @param data - The value to return for a read request; omit for write responses.
   */
  respondToRequest(request: ReadRequest, result: number, data?: Uint8Array | null): void
  /**
   * @param characteristic - The characteristic whose value changed.
   * @param data - The new value to send to subscribed centrals.
   * @returns Whether the notification was sent to subscribed centrals successfully.
   */
  updateValue(characteristic: Characteristic, data: Uint8Array): boolean
  /**
   * @param opts - Options for the L2CAP channel to publish.
   */
  publishChannel(opts?: ChannelOptions): void
  /**
   * @param psm - The PSM of the channel to unpublish, as assigned when it was published.
   */
  unpublishChannel(psm: number): void
  /** Destroy the instance and release all resources. */
  destroy(): void

  // State constants
  static readonly STATE_UNKNOWN: number
  static readonly STATE_POWERED_ON: number
  static readonly STATE_POWERED_OFF: number
  static readonly STATE_RESETTING: number
  static readonly STATE_UNAUTHORIZED: number
  /** Bluetooth state constants. */
  static readonly STATE_UNSUPPORTED: number

  // Property constants
  static readonly PROPERTY_READ: number
  static readonly PROPERTY_WRITE_WITHOUT_RESPONSE: number
  static readonly PROPERTY_WRITE: number
  static readonly PROPERTY_NOTIFY: number
  /** Characteristic property flags. */
  static readonly PROPERTY_INDICATE: number

  // Permission constants
  static readonly PERMISSION_READABLE: number
  static readonly PERMISSION_WRITEABLE: number
  static readonly PERMISSION_READ_ENCRYPTED: number
  /** Characteristic permission flags. */
  static readonly PERMISSION_WRITE_ENCRYPTED: number

  // ATT result constants
  static readonly ATT_SUCCESS: number
  static readonly ATT_INVALID_HANDLE: number
  static readonly ATT_READ_NOT_PERMITTED: number
  static readonly ATT_WRITE_NOT_PERMITTED: number
  static readonly ATT_INSUFFICIENT_RESOURCES: number
  /** ATT result codes for use with `manager.respondToRequest()`. */
  static readonly ATT_UNLIKELY_ERROR: number
}

export default PeripheralManager
