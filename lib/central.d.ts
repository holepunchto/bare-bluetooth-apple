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

  startScan(serviceUUIDs?: string[], opts?: { allowDuplicates?: boolean }): void
  stopScan(): void
  /**
   * Peripherals CoreBluetooth can resolve without scanning. Requires `ids`
   * (persisted from an earlier scan) or `services`; unlike the linux and
   * android backends this platform cannot enumerate on its own.
   *
   * @throws if neither `ids` nor `services` is given
   */
  knownPeripherals(opts: { ids?: string[]; services?: string[] }): DiscoveredPeripheral[]
  connect(peripheral: DiscoveredPeripheral): void
  /**
   * Connect by CoreBluetooth identifier, without scanning first. The id is the
   * per host UUID reported as `peripheral.id`, not a MAC address.
   *
   * @throws if CoreBluetooth has no record of the id
   */
  connectById(id: string): DiscoveredPeripheral
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
