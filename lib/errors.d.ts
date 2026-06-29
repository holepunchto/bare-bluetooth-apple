declare class BluetoothError extends Error {
  readonly code: string

  static ADVERTISE_FAILED(msg: string): BluetoothError
}

export default BluetoothError
