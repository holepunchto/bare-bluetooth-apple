import { Duplex } from 'bare-stream'

/**
 * L2CAP Channel - Bluetooth Low Energy L2CAP channel as a Duplex stream
 */
export default class L2CAPChannel extends Duplex {
  /**
   * @param channelHandle - The native channel handle backing the stream; supplied internally when a channel opens, not usually passed directly.
   */
  constructor(channelHandle: ArrayBuffer)

  /** The L2CAP PSM (Protocol/Service Multiplexer) for this channel */
  readonly psm: number

  /** The UUID of the remote peer if available */
  readonly peer: string | null
}
