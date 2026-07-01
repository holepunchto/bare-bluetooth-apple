declare class BluetoothError extends Error {
  readonly code: string

  static ADVERTISE_FAILED(msg: string): BluetoothError
  static CONNECTION_FAILED(msg: string): BluetoothError
  static DISCONNECT(msg: string): BluetoothError
  static DISCOVER_FAILED(msg: string): BluetoothError
  static READ_FAILED(msg: string): BluetoothError
  static WRITE_FAILED(msg: string): BluetoothError
  static NOTIFY_FAILED(msg: string): BluetoothError
  static NOTIFY_STATE_FAILED(msg: string): BluetoothError
  static CHANNEL_FAILED(msg: string): BluetoothError
  static SERVICE_ADD_FAILED(msg: string): BluetoothError
  static CHANNEL_PUBLISH_FAILED(msg: string): BluetoothError
}

export default BluetoothError
