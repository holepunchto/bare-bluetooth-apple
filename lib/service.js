module.exports = class Service {
  constructor(uuid, characteristics, opts = {}) {
    this._uuid = uuid
    this._characteristics = characteristics || []
    this._primary = opts.primary !== false
    this._handle = null
  }

  /** @returns {string} The service UUID. */
  get uuid() {
    return this._uuid
  }

  /** @returns {Characteristic[]} The characteristics belonging to this service. */
  get characteristics() {
    return this._characteristics
  }

  /** @returns {boolean} Whether this is a primary service. */
  get primary() {
    return this._primary
  }

  [Symbol.for('bare.inspect')]() {
    return {
      __proto__: { constructor: Service },
      uuid: this._uuid
    }
  }
}
