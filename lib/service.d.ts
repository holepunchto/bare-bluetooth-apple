import Characteristic from './characteristic'

/** Bluetooth Service - represents a GATT service */
export default class Service {
  /**
   * @param uuid - The service's UUID.
   * @param characteristics - The characteristics belonging to the service.
   * @param opts - Options; services are primary unless `primary: false` is set.
   */
  constructor(uuid: string, characteristics?: Characteristic[], opts?: ServiceOptions)

  /** The service UUID */
  readonly uuid: string

  /** The characteristics belonging to this service */
  readonly characteristics: Characteristic[]

  /** Whether this is a primary service */
  readonly primary: boolean
}

export interface ServiceOptions {
  /** Whether the service is a primary service. */
  primary?: boolean
}
