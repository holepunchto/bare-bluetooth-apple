import { EventEmitter } from 'bare-events'
import Peripheral from './peripheral'

export type BluetoothState =
  | 'unknown'
  | 'resetting'
  | 'unsupported'
  | 'unauthorized'
  | 'poweredOff'
  | 'poweredOn'

export interface CentralEventMap {
  stateChange: [state: BluetoothState]
  discover: [peripheral: Peripheral]
  connect: [peripheral: Peripheral, error?: string]
  disconnect: [peripheral: Peripheral | null, error?: string]
  connectFail: [id: string, error: string]
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
  connect(peripheral: Peripheral): void
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
