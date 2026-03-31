import { Duplex } from 'bare-stream'

/**
 * L2CAP Channel - Bluetooth Low Energy L2CAP channel as a Duplex stream
 */
export declare class L2CAPChannel extends Duplex {
  constructor(channelHandle: ArrayBuffer)

  /** The L2CAP PSM (Protocol/Service Multiplexer) for this channel */
  readonly psm: number

  /** The UUID of the remote peer if available */
  readonly peer: string | null
}

/**
 * Bluetooth Service - represents a GATT service
 */
export declare class Service {
  constructor(uuid: string, characteristics?: Characteristic[], opts?: ServiceOptions)

  /** The service UUID */
  readonly uuid: string

  /** The characteristics belonging to this service */
  readonly characteristics: Characteristic[]

  /** Whether this is a primary service */
  readonly primary: boolean
}

export interface ServiceOptions {
  primary?: boolean
}

/**
 * Bluetooth Characteristic - represents a GATT characteristic
 */
export declare class Characteristic {
  constructor(uuid: string, opts?: CharacteristicOptions)

  /** The characteristic UUID */
  readonly uuid: string

  /** Bitmask of characteristic properties */
  readonly properties: number

  /** Bitmask of characteristic permissions, if set explicitly */
  readonly permissions: number | null

  /** The current value, if set */
  value: Uint8Array | null

  // Property constants
  static readonly PROPERTY_READ: number
  static readonly PROPERTY_WRITE_WITHOUT_RESPONSE: number
  static readonly PROPERTY_WRITE: number
  static readonly PROPERTY_NOTIFY: number
  static readonly PROPERTY_INDICATE: number
}

export interface CharacteristicOptions {
  read?: boolean
  write?: boolean
  writeWithoutResponse?: boolean
  notify?: boolean
  indicate?: boolean
  permissions?: number
  value?: Uint8Array | null
}
