const EventEmitter = require('bare-events')
const binding = require('../binding')
const Service = require('./service')
const Characteristic = require('./characteristic')
const L2CAPChannel = require('./channel')

module.exports = exports = class Peripheral extends EventEmitter {
  constructor(peripheralHandle, opts = {}) {
    super()

    this._peripheralHandle = peripheralHandle
    this._connectHandle = opts.connectHandle || null
    this._id = opts.id || null
    this._name = opts.name === undefined ? null : opts.name
    this._destroyed = false
    this._services = new Map()
    this._characteristics = new Map()
    this._characteristicsByHandle = new Map()

    this._handle = binding.peripheralInit(
      peripheralHandle,
      this,
      this._onservicesdiscover,
      this._oncharacteristicsdiscover,
      this._onread,
      this._onwrite,
      this._onnotify,
      this._onnotifystate,
      this._onchannelopen
    )

    if (this._id === null) this._id = binding.peripheralId(this._handle)
    if (opts.name === undefined) this._name = binding.peripheralName(this._handle)
  }

  /** @returns {string} The peripheral UUID identifier. */
  get id() {
    return this._id
  }

  /** @returns {string|null} The peripheral name, if advertised. */
  get name() {
    return this._name
  }

  /**
   * @param {string[]} [serviceUUIDs]
   */
  discoverServices(serviceUUIDs) {
    const uuids = serviceUUIDs ? serviceUUIDs.map((s) => binding.createCBUUID(s)) : null
    binding.peripheralDiscoverServices(this._handle, uuids)
  }

  /**
   * @param {Service} service
   * @param {string[]} [characteristicUUIDs]
   */
  discoverCharacteristics(service, characteristicUUIDs) {
    const uuids = characteristicUUIDs
      ? characteristicUUIDs.map((s) => binding.createCBUUID(s))
      : null
    binding.peripheralDiscoverCharacteristics(this._handle, service._handle, uuids)
  }

  /**
   * @param {Characteristic} characteristic
   */
  read(characteristic) {
    binding.peripheralRead(this._handle, characteristic._handle)
  }

  /**
   * @param {Characteristic} characteristic - The target characteristic.
   * @param {Uint8Array} data - The data to write.
   * @param {boolean} [withResponse=true]
   */
  write(characteristic, data, withResponse) {
    if (withResponse === undefined) withResponse = true
    binding.peripheralWrite(this._handle, characteristic._handle, data, withResponse)
  }

  /**
   * Subscribe to notifications for a characteristic.
   *
   * @param {Characteristic} characteristic - A characteristic with the
   *   notify or indicate property.
   */
  subscribe(characteristic) {
    binding.peripheralSubscribe(this._handle, characteristic._handle)
  }

  /**
   * Unsubscribe from notifications for a characteristic.
   *
   * @param {Characteristic} characteristic - A currently subscribed characteristic.
   */
  unsubscribe(characteristic) {
    binding.peripheralUnsubscribe(this._handle, characteristic._handle)
  }

  /**
   * @param {number} psm - The PSM to connect to from the server's `channelPublish` event
   */
  openL2CAPChannel(psm) {
    binding.peripheralOpenL2CAPChannel(this._handle, psm)
  }

  destroy() {
    if (this._destroyed) return
    this._destroyed = true
    this._connectHandle = null
    binding.peripheralDestroy(this._handle)
  }

  [Symbol.for('bare.inspect')]() {
    return {
      __proto__: { constructor: Peripheral },
      id: this.id,
      name: this.name
    }
  }

  _onservicesdiscover(count, error) {
    if (error) {
      this.emit('servicesDiscover', null, error)
      return
    }

    const services = []

    for (let i = 0; i < count; i++) {
      const handle = binding.peripheralServiceAtIndex(this._handle, i)
      const serviceKey = binding.serviceKey(handle)
      const uuid = binding.serviceUuid(handle)
      let service = this._services.get(serviceKey)

      if (!service) {
        service = new Service(uuid)
        service._handle = handle
        service._key = serviceKey
        this._services.set(serviceKey, service)
      } else {
        service._handle = handle
      }

      services.push(service)
    }

    this.emit('servicesDiscover', services, null)
  }

  _oncharacteristicsdiscover(serviceHandle, count, error) {
    const serviceKey = binding.serviceKey(serviceHandle)
    const service = this._services.get(serviceKey) || null

    if (error) {
      this.emit('characteristicsDiscover', service, null, error)
      return
    }

    const characteristics = []

    for (let i = 0; i < count; i++) {
      const handle = binding.serviceCharacteristicAtIndex(serviceHandle, i)
      const handleKey = binding.characteristicKey(handle)
      const characteristicKey = serviceKey + ':' + handleKey
      const uuid = binding.characteristicUuid(handle)
      const properties = binding.characteristicProperties(handle)
      let characteristic = this._characteristics.get(characteristicKey)

      if (!characteristic) {
        characteristic = new Characteristic(uuid)
        characteristic._handle = handle
        characteristic._properties = properties
        characteristic._key = characteristicKey
        characteristic._serviceKey = serviceKey
        characteristic._handleKey = handleKey
        this._characteristics.set(characteristicKey, characteristic)
      } else {
        characteristic._handle = handle
        characteristic._properties = properties
      }

      this._characteristicsByHandle.set(handleKey, characteristic)

      characteristics.push(characteristic)
    }

    if (service) {
      service._characteristics = characteristics
    }

    this.emit('characteristicsDiscover', service, characteristics, null)
  }

  _onread(charHandle, uuid, data, error) {
    const characteristic =
      this._characteristicsByHandle.get(binding.characteristicKey(charHandle)) || null

    this.emit('read', characteristic, data, error)
  }

  _onwrite(charHandle, uuid, error) {
    const characteristic =
      this._characteristicsByHandle.get(binding.characteristicKey(charHandle)) || null

    this.emit('write', characteristic, error)
  }

  _onnotify(charHandle, uuid, data, error) {
    const characteristic =
      this._characteristicsByHandle.get(binding.characteristicKey(charHandle)) || null

    this.emit('notify', characteristic, data, error)
  }

  _onnotifystate(charHandle, uuid, isNotifying, error) {
    const characteristic =
      this._characteristicsByHandle.get(binding.characteristicKey(charHandle)) || null

    this.emit('notifyState', characteristic, isNotifying, error)
  }

  _ondisconnect() {
    this._connectHandle = null
  }

  _onchannelopen(channelHandle, error) {
    if (error || !channelHandle) {
      this.emit('channelOpen', null, error)
      return
    }

    const channel = new L2CAPChannel(channelHandle)
    channel.open()
    this.emit('channelOpen', channel, null)
  }
}

exports.PROPERTY_READ = binding.PROPERTY_READ
exports.PROPERTY_WRITE_WITHOUT_RESPONSE = binding.PROPERTY_WRITE_WITHOUT_RESPONSE
exports.PROPERTY_WRITE = binding.PROPERTY_WRITE
exports.PROPERTY_NOTIFY = binding.PROPERTY_NOTIFY
exports.PROPERTY_INDICATE = binding.PROPERTY_INDICATE
