/**
 * Bluetooth Characteristic - represents a GATT characteristic
 */
export default class Characteristic {
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
