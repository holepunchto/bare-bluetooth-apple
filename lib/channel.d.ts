import { Duplex } from 'bare-stream'

/**
 * L2CAP Channel - Bluetooth Low Energy L2CAP channel as a Duplex stream
 */
export default class L2CAPChannel extends Duplex {
  constructor(channelHandle: ArrayBuffer)

  /** The L2CAP PSM (Protocol/Service Multiplexer) for this channel */
  readonly psm: number

  /** The UUID of the remote peer if available */
  readonly peer: string | null
}
