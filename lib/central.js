const EventEmitter = require('bare-events')
const binding = require('../binding')
const Peripheral = require('./peripheral')
const errors = require('./errors')

const STATES = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn']

module.exports = exports = class Central extends EventEmitter {
  constructor() {
    super()

    this._handle = binding.centralInit(
      this,
      this._onstatechange,
      this._ondiscover,
      this._onconnect,
      this._ondisconnect,
      this._onconnectfail
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

  // Peripherals CoreBluetooth can resolve without scanning.
  //
  // Unlike the linux and android backends this cannot enumerate on its own:
  // CoreBluetooth identifiers are per host and per application, and there is no
  // API to list everything previously connected. Pass `ids` persisted from an
  // earlier scan, or `services` to find peripherals the system already has
  // connected, possibly via another application.
  knownPeripherals({ ids = null, services = null } = {}) {
    if (!ids && !services) {
      throw new Error(
        'knownPeripherals requires ids or services on this platform: ' +
          'CoreBluetooth cannot enumerate previously connected peripherals. ' +
          'Persist peripheral.id from a scan and pass it back as ids'
      )
    }

    const found = []

    const onperipheral = (handle, id, name) => {
      found.push(this._known(handle, id, name === undefined ? null : name))
    }

    if (ids) {
      binding.centralRetrievePeripherals(this._handle, ids, onperipheral)
    }

    if (services) {
      const uuids = services.map((s) => binding.createCBUUID(s))
      binding.centralRetrieveConnectedPeripherals(this._handle, uuids, onperipheral)
    }

    return found
  }

  connect(peripheral) {
    binding.centralConnect(this._handle, peripheral._handle)
  }

  // Connect by CoreBluetooth identifier, without scanning first.
  //
  // The id is the per host UUID string reported as peripheral.id, not a MAC
  // address; there is no such thing on this platform.
  connectById(id) {
    const [peripheral] = this.knownPeripherals({ ids: [id] })

    if (!peripheral) {
      throw new Error(
        'Unknown peripheral ' +
          id +
          ': CoreBluetooth has no record of it. Discover it with startScan() once and persist its id'
      )
    }

    this.connect(peripheral)

    return peripheral
  }

  _known(handle, id, name) {
    let peripheral = this._peripherals.get(id)

    if (peripheral) {
      peripheral._handle = handle
      if (name) peripheral.name = name
    } else {
      peripheral = { _handle: handle, id, name, rssi: 0, serviceData: null }
      this._peripherals.set(id, peripheral)
    }

    return peripheral
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
      serviceData: discovered ? discovered.serviceData : null,
      central: this
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

exports.STATE_UNKNOWN = binding.STATE_UNKNOWN
exports.STATE_POWERED_ON = binding.STATE_POWERED_ON
exports.STATE_POWERED_OFF = binding.STATE_POWERED_OFF
exports.STATE_RESETTING = binding.STATE_RESETTING
exports.STATE_UNAUTHORIZED = binding.STATE_UNAUTHORIZED
exports.STATE_UNSUPPORTED = binding.STATE_UNSUPPORTED
