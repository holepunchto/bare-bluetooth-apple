import { EventEmitter, EventMap } from 'bare-events'
import Peripheral from './peripheral'
import BluetoothError from './errors'

export type BluetoothState =
  'unknown' | 'resetting' | 'unsupported' | 'unauthorized' | 'poweredOff' | 'poweredOn'

export interface DiscoveredPeripheral {
  id: string
  name: string | null
  rssi: number
  serviceData: { [uuid: string]: Uint8Array } | null
}

export interface CentralEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  error: [error: BluetoothError]
  discover: [peripheral: DiscoveredPeripheral]
  connect: [peripheral: Peripheral]
  disconnect: [peripheral: Peripheral | null]
}

/**
 * Bluetooth Central - central manager for scanning and connecting to peripherals
 */
export default class Central extends EventEmitter<CentralEventMap> {
  constructor()

  /** The current Bluetooth adapter state */
  readonly state: BluetoothState

  startScan(serviceUUIDs?: string[]): void
  stopScan(): void
  connect(peripheral: DiscoveredPeripheral): void
  disconnect(peripheral: Peripheral): void
  destroy(): void

  // State constants
  static readonly STATE_UNKNOWN: number
  static readonly STATE_POWERED_ON: number
  static readonly STATE_POWERED_OFF: number
  static readonly STATE_RESETTING: number
  static readonly STATE_UNAUTHORIZED: number
  static readonly STATE_UNSUPPORTED: number
}
