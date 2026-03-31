import Characteristic from './characteristic'

/**
 * Bluetooth Service - represents a GATT service
 */
export default class Service {
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
