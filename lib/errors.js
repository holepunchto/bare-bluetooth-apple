module.exports = class BluetoothError extends Error {
  constructor(msg, code, fn = BluetoothError) {
    super(`${code}: ${msg}`)
    this.code = code

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, fn)
    }
  }

  get name() {
    return 'BluetoothError'
  }

  static ADVERTISE_FAILED(msg, fn = BluetoothError.ADVERTISE_FAILED) {
    return new BluetoothError(msg, 'ADVERTISE_FAILED', fn)
  }
}
