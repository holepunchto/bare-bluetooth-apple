const EventEmitter = require('bare-events')
const binding = require('../binding')
const Peripheral = require('./peripheral')
const errors = require('./errors')

const STATES = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn']
const PERIPHERAL_STATES = ['disconnected', 'connecting', 'connected', 'disconnecting']

module.exports = exports = class Central extends EventEmitter {
  constructor(opts = {}) {
    super()

    const { showPowerAlert = false } = opts

    this._handle = binding.centralInit(
      this,
      this._onstatechange,
      this._ondiscover,
      this._onconnect,
      this._ondisconnect,
      this._onconnectfail,
      showPowerAlert
    )

    this._peripherals = new Map()
    this._connected = new Map()
    this._state = 'unknown'
    this._destroyed = false
  }

  get state() {
    return this._state
  }

  startScan(serviceUUIDs, opts = {}) {
    const uuids = serviceUUIDs ? serviceUUIDs.map((s) => binding.createCBUUID(s)) : undefined
    binding.centralStartScan(this._handle, uuids, opts.allowDuplicates)
  }

  stopScan() {
    binding.centralStopScan(this._handle)
    this._peripherals.clear()
  }

  retrievePeripherals(ids) {
    return binding.centralRetrievePeripherals(this._handle, ids).map(toPeripheral)
  }

  retrieveConnectedPeripherals(services) {
    const uuids = services.map((s) => binding.createCBUUID(s))
    return binding.centralRetrieveConnectedPeripherals(this._handle, uuids).map(toPeripheral)
  }

  connect(peripheral) {
    binding.centralConnect(this._handle, peripheral._handle)
  }

  disconnect(peripheral) {
    binding.centralDisconnect(this._handle, peripheral._handle)
  }

  destroy() {
    if (this._destroyed) return
    this._destroyed = true
    binding.centralStopScan(this._handle)
    binding.centralDestroy(this._handle)
  }

  [Symbol.dispose]() {
    this.destroy()
  }

  [Symbol.for('bare.inspect')]() {
    return {
      __proto__: { constructor: Central },
      state: this._state
    }
  }

  _onstatechange(state) {
    this._state = STATES[state] || 'unknown'
    this.emit('stateChange', this._state)
  }

  _ondiscover(handle, id, name, rssi, serviceData) {
    if (name === undefined) name = null

    let peripheral = this._peripherals.get(id)
    if (peripheral) {
      peripheral._handle = handle
      if (name) peripheral.name = name
      peripheral.rssi = rssi
      peripheral.serviceData = serviceData
    } else {
      peripheral = { _handle: handle, id, name, rssi, serviceData }
      this._peripherals.set(id, peripheral)
    }

    this.emit('discover', peripheral)
  }

  _onconnect(handle, id) {
    const discovered = this._peripherals.get(id)
    const peripheral = new Peripheral(handle, {
      id,
      name: discovered ? discovered.name : null,
      serviceData: discovered ? discovered.serviceData : null
    })
    this._connected.set(id, peripheral)

    this.emit('connect', peripheral)
  }

  _ondisconnect(id, error) {
    const peripheral = this._connected.get(id) || null

    if (peripheral) peripheral.destroy()

    this._connected.delete(id)

    if (error) {
      this.emit('error', errors.DISCONNECT(error, id))
      return
    }

    this.emit('disconnect', peripheral)
  }

  _onconnectfail(id, error) {
    this.emit('error', errors.CONNECTION_FAILED(error, id))
  }
}

function toPeripheral({ handle, id, name, state }) {
  return { _handle: handle, id, name, state: PERIPHERAL_STATES[state] }
}

exports.STATE_UNKNOWN = binding.STATE_UNKNOWN
exports.STATE_POWERED_ON = binding.STATE_POWERED_ON
exports.STATE_POWERED_OFF = binding.STATE_POWERED_OFF
exports.STATE_RESETTING = binding.STATE_RESETTING
exports.STATE_UNAUTHORIZED = binding.STATE_UNAUTHORIZED
exports.STATE_UNSUPPORTED = binding.STATE_UNSUPPORTED
