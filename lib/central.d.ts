import { EventEmitter } from 'bare-events'
import Peripheral from './peripheral'

export type BluetoothState =
  | 'unknown'
  | 'resetting'
  | 'unsupported'
  | 'unauthorized'
  | 'poweredOff'
  | 'poweredOn'

/**
 * Bluetooth Central - central manager for scanning and connecting to peripherals
 */
export default class Central extends EventEmitter {
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

  // Events
  on(event: 'stateChange', listener: (state: BluetoothState) => void): this
  on(event: 'discover', listener: (peripheral: Peripheral) => void): this
  on(event: 'connect', listener: (peripheral: Peripheral, error?: string) => void): this
  on(event: 'disconnect', listener: (peripheral: Peripheral | null, error?: string) => void): this
  on(event: 'connectFail', listener: (id: string, error: string) => void): this
}
