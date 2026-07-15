import { EventEmitter, EventMap } from 'bare-events'
import Peripheral from './peripheral'
import BluetoothError from './errors'

export type BluetoothState =
  'unknown' | 'resetting' | 'unsupported' | 'unauthorized' | 'poweredOff' | 'poweredOn'

export interface DiscoveredPeripheral {
  /** The unique identifier of the peripheral. */
  id: string
  /** The name of the peripheral, if available. */
  name: string | null
  rssi: number
  /** A snapshot of the `serviceData` from the most recent advertisement seen for this peripheral before connect or `null`. Service data is only in advertisement packets, so this value never updates after connect. */
  serviceData: { [uuid: string]: Uint8Array } | null
}

export interface CentralEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  error: [error: BluetoothError]
  discover: [peripheral: DiscoveredPeripheral]
  /**
   * Connect to a discovered `peripheral`.
   * @param peripheral - A discovered peripheral to connect to.
   */
  connect: [peripheral: Peripheral]
  /**
   * Disconnect from a connected `peripheral`.
   * @param peripheral - The connected peripheral to disconnect from.
   */
  disconnect: [peripheral: Peripheral | null]
}

/**
 * Bluetooth Central - central manager for scanning and connecting to peripherals
 */
export default class Central extends EventEmitter<CentralEventMap> {
  constructor()

  /** The current Bluetooth adapter state */
  readonly state: BluetoothState

  /**
   * @param serviceUUIDs - The service UUIDs to filter advertisements by; omit to discover all peripherals.
   */
  startScan(serviceUUIDs?: string[]): void
  /** Stop scanning for peripherals. */
  stopScan(): void
  /**
   * @param peripheral - A discovered peripheral to connect to.
   */
  connect(peripheral: DiscoveredPeripheral): void
  /**
   * @param peripheral - The connected peripheral to disconnect from.
   */
  disconnect(peripheral: Peripheral): void
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
}
