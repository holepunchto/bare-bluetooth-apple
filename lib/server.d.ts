import { EventEmitter, EventMap } from 'bare-events'
import Service from './service'
import Characteristic from './characteristic'
import L2CAPChannel from './channel'

export type BluetoothState =
  | 'unknown'
  | 'resetting'
  | 'unsupported'
  | 'unauthorized'
  | 'poweredOff'
  | 'poweredOn'

export interface AdvertisingOptions {
  name?: string
  serviceUUIDs?: string[]
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
}

export interface ServerEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  addService: [uuid: string, error?: string]
  channelPublish: [psm: number, error?: string]
  channelOpen: [channel: L2CAPChannel | null, error?: string]
  readRequest: [request: ReadRequest]
  writeRequests: [requests: WriteRequest[]]
  subscribe: [centralHandle: ArrayBuffer, characteristicUuid: string]
  unsubscribe: [centralHandle: ArrayBuffer, characteristicUuid: string]
  readyToUpdate: []
}

/**
 * Bluetooth Server - peripheral server for GATT services and L2CAP channels
 */
declare class Server extends EventEmitter<ServerEventMap> {
  constructor()

  /** The current Bluetooth adapter state */
  readonly state: BluetoothState

  addService(service: Service): void
  startAdvertising(opts?: AdvertisingOptions): void
  stopAdvertising(): void
  respondToRequest(request: ReadRequest, result: number, data?: Uint8Array | null): void
  updateValue(characteristic: Characteristic, data: Uint8Array): boolean
  publishChannel(opts?: ChannelOptions): void
  unpublishChannel(psm: number): void
  destroy(): void

  // State constants
  static readonly STATE_UNKNOWN: number
  static readonly STATE_POWERED_ON: number
  static readonly STATE_POWERED_OFF: number
  static readonly STATE_RESETTING: number
  static readonly STATE_UNAUTHORIZED: number
  static readonly STATE_UNSUPPORTED: number

  // Property constants
  static readonly PROPERTY_READ: number
  static readonly PROPERTY_WRITE_WITHOUT_RESPONSE: number
  static readonly PROPERTY_WRITE: number
  static readonly PROPERTY_NOTIFY: number
  static readonly PROPERTY_INDICATE: number

  // Permission constants
  static readonly PERMISSION_READABLE: number
  static readonly PERMISSION_WRITEABLE: number
  static readonly PERMISSION_READ_ENCRYPTED: number
  static readonly PERMISSION_WRITE_ENCRYPTED: number

  // ATT result constants
  static readonly ATT_SUCCESS: number
  static readonly ATT_INVALID_HANDLE: number
  static readonly ATT_READ_NOT_PERMITTED: number
  static readonly ATT_WRITE_NOT_PERMITTED: number
  static readonly ATT_INSUFFICIENT_RESOURCES: number
  static readonly ATT_UNLIKELY_ERROR: number
}

export default Server
