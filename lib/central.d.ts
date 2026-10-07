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
  /**
   * A snapshot of the `serviceData` from the most recent advertisement seen for this peripheral
   * before connect or `null`. Service data is only in advertisement packets, so this value never
   * updates after connect.
   */
  serviceData: { [uuid: string]: Uint8Array } | null
}

export type PeripheralState = 'disconnected' | 'connecting' | 'connected' | 'disconnecting'

export interface CentralOptions {
  /**
   * Let the system show its own Bluetooth power alert when Bluetooth is off. Defaults to `false`.
   */
  showPowerAlert?: boolean
}

/**
 * A peripheral resolved without scanning. It carries no advertisement data, so it has no `rssi`
 * or `serviceData`.
 */
export interface RetrievedPeripheral {
  /** The unique identifier of the peripheral. */
  id: string
  /** The name of the peripheral, if available. */
  name: string | null
  /** The connection state, which may reflect a connection made by another application. */
  state: PeripheralState
}

export interface CentralEventMap extends EventMap {
  stateChange: [state: BluetoothState]
  error: [error: BluetoothError]
  discover: [peripheral: DiscoveredPeripheral]
  /** Emitted when a connection is established, with the connected `Peripheral`. */
  connect: [peripheral: Peripheral]
  /**
   * Emitted when a peripheral disconnects, with the now-destroyed `Peripheral`, or `null` if it
   * was not tracked as connected. If the disconnect carried an error, `error` is emitted instead.
   */
  disconnect: [peripheral: Peripheral | null]
}

/** Bluetooth Central - central manager for scanning and connecting to peripherals */
export default class Central extends EventEmitter<CentralEventMap> {
  /**
   * Create a new BLE central manager. The central scans for and connects to peripherals.
   * @param opts - Manager options such as `showPowerAlert`.
   */
  constructor(opts?: CentralOptions)

  /** The current Bluetooth adapter state */
  readonly state: BluetoothState

  /**
   * @param serviceUUIDs - The service UUIDs to filter advertisements by; omit to discover all
   * peripherals.
   */
  startScan(serviceUUIDs?: string[], opts?: { allowDuplicates?: boolean }): void
  /** Stop scanning for peripherals. */
  stopScan(): void
  /**
   * Resolve peripherals from identifiers persisted after an earlier scan, without scanning again.
   * @param ids - The per host UUIDs reported as `peripheral.id`, not MAC addresses.
   * @throws if an id is not a UUID, or if Bluetooth is not powered on.
   */
  retrievePeripherals(ids: string[]): RetrievedPeripheral[]
  /**
   * Peripherals already connected to the system that implement any of `services`. Those connected
   * by another application still need `connect()` before this central can use them.
   *
   * @throws if Bluetooth is not powered on.
   */
  retrieveConnectedPeripherals(services: string[]): RetrievedPeripheral[]
  /**
   * Connect to a discovered or retrieved `peripheral`.
   * @param peripheral - The peripheral to connect to.
   */
  connect(peripheral: DiscoveredPeripheral | RetrievedPeripheral): void
  /**
   * Disconnect from a connected `peripheral`, or cancel a pending connection to a discovered one.
   * @param peripheral - The connected peripheral to disconnect from, or a discovered peripheral
   * with a pending connection.
   */
  disconnect(peripheral: Peripheral | DiscoveredPeripheral | RetrievedPeripheral): void
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
