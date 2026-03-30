const { Duplex } = require('bare-stream')

const binding = require('../binding')

module.exports = exports = class L2CAPChannel extends Duplex {
  constructor(channelHandle) {
    super({
      objectMode: false,
      allowHalfOpen: false
    })

    this._channelHandle = channelHandle

    this._handle = binding.l2capInit(
      channelHandle,
      this,
      this._ondata,
      this._ondrain,
      this._onend,
      this._onerror,
      this._onclose,
      this._onopen
    )
  }

  /** @returns {number} The L2CAP PSM (Protocol/Service Multiplexer) for this channel */
  get psm() {
    return binding.l2capPsm(this._handle)
  }

  /** @returns {string|null} The UUID of the remote peer if available. */
  get peer() {
    return binding.l2capPeer(this._handle)
  }

  _open(callback) {
    binding.l2capOpen(this._handle)
    callback()
  }

  _write(chunk, _encoding, callback) {
    if (this.destroyed) {
      callback(new Error('Channel is destroyed'))
      return
    }

    try {
      const bytesWritten = binding.l2capWrite(this._handle, chunk)
      if (bytesWritten === 0) {
        callback(new Error('Channel not ready or destroyed'))
      } else {
        callback(null)
      }
    } catch (err) {
      callback(err)
    }
  }

  _final(callback) {
    callback()
  }

  _destroy(err, callback) {
    binding.l2capEnd(this._handle)
    callback(err)
  }

  [Symbol.for('bare.inspect')]() {
    return {
      __proto__: { constructor: L2CAPChannel },
      destroyed: this.destroyed
    }
  }

  _ondata(data) {
    this.push(data)
  }

  _ondrain() {
    this.emit('drain')
  }

  _onend() {
    this.push(null)
  }

  _onerror(message) {
    this.emit('error', new Error(message))
  }

  _onclose() {
    this.emit('close')
  }

  _onopen() {
    this.emit('open')
  }
}
