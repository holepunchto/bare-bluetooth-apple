/** Bluetooth Characteristic - represents a GATT characteristic */
export default class Characteristic {
  /**
   * @param uuid - The characteristic's UUID.
   * @param opts - Options selecting the characteristic `properties` (`read`, `write`,
   * `writeWithoutResponse`, `notify`, `indicate`) and its optional `permissions` and initial
   * `value`.
   */
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
  /** Characteristic property flags. */
  static readonly PROPERTY_INDICATE: number
}

export interface CharacteristicOptions {
  /** Whether to set the `PROPERTY_READ` flag in the characteristic's `properties` bitmask. */
  read?: boolean
  /** Whether to set the `PROPERTY_WRITE` flag in the characteristic's `properties` bitmask. */
  write?: boolean
  writeWithoutResponse?: boolean
  notify?: boolean
  indicate?: boolean
  /** The bitmask of characteristic permissions to set. */
  permissions?: number
  /** The current value of the characteristic, or `null`. */
  value?: Uint8Array | null
}
