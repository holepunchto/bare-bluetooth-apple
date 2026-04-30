#import <atomic>
#import <optional>

#import <bare.h>
#import <js.h>
#import <jstl.h>

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

struct bare_bluetooth_apple_external_t {
  CFTypeRef ref;
  char *uuid;
};

struct bare_bluetooth_apple_peripheral_services_discover_t {
  uint32_t count;
  char *error;
};

struct bare_bluetooth_apple_peripheral_characteristics_discover_t {
  CFTypeRef service;
  uint32_t count;
  char *error;
};

struct bare_bluetooth_apple_peripheral_read_t {
  CFTypeRef characteristic;
  char *uuid;
  void *data;
  size_t data_len;
  char *error;
};

struct bare_bluetooth_apple_peripheral_write_t {
  CFTypeRef characteristic;
  char *uuid;
  char *error;
};

struct bare_bluetooth_apple_peripheral_notify_t {
  CFTypeRef characteristic;
  char *uuid;
  void *data;
  size_t data_len;
  char *error;
};

struct bare_bluetooth_apple_peripheral_notify_state_t {
  CFTypeRef characteristic;
  char *uuid;
  bool is_notifying;
  char *error;
};

struct bare_bluetooth_apple_peripheral_channel_open_t {
  CFTypeRef channel;
  char *error;
};

struct bare_bluetooth_apple_server_state_change_t {
  int32_t state;
};

struct bare_bluetooth_apple_server_add_service_t {
  CFTypeRef service;
  char *uuid;
  char *error;
};

struct bare_bluetooth_apple_server_read_request_t {
  CFTypeRef request;
};

struct bare_bluetooth_apple_server_write_requests_t {
  uint32_t count;
  CFTypeRef *requests;
};

struct bare_bluetooth_apple_server_subscribe_t {
  CFTypeRef central;
  char *characteristic_uuid;
};

struct bare_bluetooth_apple_server_unsubscribe_t {
  CFTypeRef central;
  char *characteristic_uuid;
};

struct bare_bluetooth_apple_server_channel_publish_t {
  uint16_t psm;
  char *error;
};

struct bare_bluetooth_apple_server_channel_open_t {
  CFTypeRef channel;
  char *error;
};

struct bare_bluetooth_apple_central_state_change_t {
  int32_t state;
};

struct bare_bluetooth_apple_central_discover_t {
  CFTypeRef peripheral;
  char *id;
  char *name;
  int32_t rssi;
};

struct bare_bluetooth_apple_central_connect_t {
  CFTypeRef peripheral;
  char *id;
};

struct bare_bluetooth_apple_central_disconnect_t {
  char *id;
  char *error;
};

struct bare_bluetooth_apple_central_connect_fail_t {
  char *id;
  char *error;
};

struct bare_bluetooth_apple_l2cap_data_t {
  void *bytes;
  size_t len;
};

struct bare_bluetooth_apple_l2cap_error_t {
  char *message;
};

@interface BareBluetoothApplePeripheral : NSObject <CBPeripheralDelegate> {
@public
  js_env_t *env;
  bool destroyed;
  js_ref_t *ctx;
  js_threadsafe_function_t *tsfn_services_discover;
  js_threadsafe_function_t *tsfn_characteristics_discover;
  js_threadsafe_function_t *tsfn_read;
  js_threadsafe_function_t *tsfn_write;
  js_threadsafe_function_t *tsfn_notify;
  js_threadsafe_function_t *tsfn_notify_state;
  js_threadsafe_function_t *tsfn_channel_open;

  CBPeripheral *peripheral;
}

@end

@implementation BareBluetoothApplePeripheral

- (void)dealloc {
  [super dealloc];
}

- (void)peripheral:(CBPeripheral *)p didDiscoverServices:(NSError *)error {
  auto event = new bare_bluetooth_apple_peripheral_services_discover_t;
  if (!event) abort();
  event->count = error ? 0 : static_cast<uint32_t>(p.services.count);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_services_discover, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didDiscoverCharacteristicsForService:(CBService *)service
                                 error:(NSError *)error {
  auto event = new bare_bluetooth_apple_peripheral_characteristics_discover_t;
  if (!event) abort();

  event->service = CFBridgingRetain(service);
  event->count = error ? 0 : static_cast<uint32_t>(service.characteristics.count);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_characteristics_discover, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                            error:(NSError *)error {
  if (characteristic.isNotifying) {
    auto event = new bare_bluetooth_apple_peripheral_notify_t;
    if (!event) abort();

    event->characteristic = CFBridgingRetain(characteristic);
    event->uuid = strdup(characteristic.UUID.UUIDString.UTF8String);
    event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

    NSData *value = characteristic.value;

    if (!error && value && value.length > 0) {
      event->data_len = value.length;
      event->data = new uint8_t[value.length];
      if (!event->data) abort();
      memcpy(event->data, value.bytes, value.length);
    } else {
      event->data = NULL;
      event->data_len = 0;
    }

    js_call_threadsafe_function(tsfn_notify, event, js_threadsafe_function_nonblocking);
  } else {
    auto event = new bare_bluetooth_apple_peripheral_read_t;
    if (!event) abort();

    event->characteristic = CFBridgingRetain(characteristic);
    event->uuid = strdup(characteristic.UUID.UUIDString.UTF8String);

    if (error) {
      event->data = NULL;
      event->data_len = 0;
      event->error = strdup(error.localizedDescription.UTF8String);
    } else {
      NSData *value = characteristic.value;

      if (value && value.length > 0) {
        event->data_len = value.length;
        event->data = new uint8_t[value.length];
        if (!event->data) abort();
        memcpy(event->data, value.bytes, value.length);
      } else {
        event->data = NULL;
        event->data_len = 0;
      }

      event->error = NULL;
    }

    js_call_threadsafe_function(tsfn_read, event, js_threadsafe_function_nonblocking);
  }
}

- (void)peripheral:(CBPeripheral *)p
  didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                           error:(NSError *)error {
  auto event = new bare_bluetooth_apple_peripheral_write_t;
  if (!event) abort();

  event->characteristic = CFBridgingRetain(characteristic);
  event->uuid = strdup(characteristic.UUID.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_write, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                        error:(NSError *)error {
  auto event = new bare_bluetooth_apple_peripheral_notify_state_t;
  if (!event) abort();

  event->characteristic = CFBridgingRetain(characteristic);
  event->uuid = strdup(characteristic.UUID.UUIDString.UTF8String);
  event->is_notifying = characteristic.isNotifying;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_notify_state, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didOpenL2CAPChannel:(CBL2CAPChannel *)l2capChannel
                error:(NSError *)error {
  auto event = new bare_bluetooth_apple_peripheral_channel_open_t;
  if (!event) abort();

  event->channel = l2capChannel ? CFBridgingRetain(l2capChannel) : NULL;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_channel_open, event, js_threadsafe_function_nonblocking);
}

@end

static void
bare_bluetooth_apple__on_bridged_release(js_env_t *env, void *data, void *finalize_hint) {
  CFBridgingRelease(data);
}

template <typename T>
static void
bare_bluetooth_apple__release_bridged(js_env_t *, T *data) {
  CFBridgingRelease(data);
}

static js_external_t<CBUUID>
bare_bluetooth_apple_create_cbuuid(
  js_env_t *env,
  js_receiver_t,
  std::string str
) {
  @autoreleasepool {
    int err;
    CBUUID *uuid = [CBUUID UUIDWithString:[NSString stringWithUTF8String:str.c_str()]];

    js_external_t<CBUUID> result;
    err = js_create_external(env, static_cast<CBUUID *>(CFBridgingRetain(uuid)), result);
    assert(err == 0);

    return result;
  }
}

struct bare_bluetooth_apple_peripheral_t {
  BareBluetoothApplePeripheral *handle;
};

static void
bare_bluetooth_apple_peripheral__on_finalize(js_env_t *env, bare_bluetooth_apple_peripheral_t *peripheral) {
  CFBridgingRelease((__bridge CFTypeRef) peripheral->handle);
  delete peripheral;
}

using bare_bluetooth_apple_peripheral__on_services_discover_fn = js_function_t<void, js_receiver_t, uint32_t, js_object_t>;
using bare_bluetooth_apple_peripheral__on_characteristics_discover_fn = js_function_t<void, js_receiver_t, js_object_t, uint32_t, js_object_t>;
using bare_bluetooth_apple_peripheral__on_read_fn = js_function_t<void, js_receiver_t, js_object_t, std::string, js_object_t, js_object_t>;
using bare_bluetooth_apple_peripheral__on_write_fn = js_function_t<void, js_receiver_t, js_object_t, std::string, js_object_t>;
using bare_bluetooth_apple_peripheral__on_notify_fn = js_function_t<void, js_receiver_t, js_object_t, std::string, js_object_t, js_object_t>;
using bare_bluetooth_apple_peripheral__on_notify_state_fn = js_function_t<void, js_receiver_t, js_object_t, std::string, bool, js_object_t>;
using bare_bluetooth_apple_peripheral__on_channel_open_fn = js_function_t<void, js_receiver_t, js_object_t, js_object_t>;

static void
bare_bluetooth_apple_peripheral__on_services_discover(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_services_discover_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_services_discover_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  uint32_t count = event->count;

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), count, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_characteristics_discover(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_characteristics_discover_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_characteristics_discover_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *service;
  err = js_create_external(env, const_cast<void *>(event->service), bare_bluetooth_apple__on_bridged_release, NULL, &service);
  assert(err == 0);

  uint32_t count = event->count;

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(service), count, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_read(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_read_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_read_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *characteristic;
  err = js_create_external(env, const_cast<void *>(event->characteristic), bare_bluetooth_apple__on_bridged_release, NULL, &characteristic);
  assert(err == 0);

  std::string uuid(event->uuid);

  js_value_t *data;
  if (event->data && event->data_len > 0) {
    void *buf;
    js_value_t *arraybuffer;
    err = js_create_arraybuffer(env, event->data_len, &buf, &arraybuffer);
    assert(err == 0);

    memcpy(buf, event->data, event->data_len);

    err = js_create_typedarray(env, js_uint8array, event->data_len, arraybuffer, 0, &data);
    assert(err == 0);

    delete[] reinterpret_cast<uint8_t *>(event->data);
  } else {
    err = js_get_null(env, &data);
    assert(err == 0);
  }

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  free(event->uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(characteristic), uuid, js_object_t(data), js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_write(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_write_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_write_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *characteristic;
  err = js_create_external(env, const_cast<void *>(event->characteristic), bare_bluetooth_apple__on_bridged_release, NULL, &characteristic);
  assert(err == 0);

  std::string uuid(event->uuid);

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  free(event->uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(characteristic), uuid, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_notify(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_notify_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_notify_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *characteristic;
  err = js_create_external(env, const_cast<void *>(event->characteristic), bare_bluetooth_apple__on_bridged_release, NULL, &characteristic);
  assert(err == 0);

  std::string uuid(event->uuid);

  js_value_t *data;
  if (event->data && event->data_len > 0) {
    void *buf;
    js_value_t *arraybuffer;
    err = js_create_arraybuffer(env, event->data_len, &buf, &arraybuffer);
    assert(err == 0);

    memcpy(buf, event->data, event->data_len);

    err = js_create_typedarray(env, js_uint8array, event->data_len, arraybuffer, 0, &data);
    assert(err == 0);

    delete[] reinterpret_cast<uint8_t *>(event->data);
  } else {
    err = js_get_null(env, &data);
    assert(err == 0);
  }

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  free(event->uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(characteristic), uuid, js_object_t(data), js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_notify_state(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_notify_state_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_notify_state_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *characteristic;
  err = js_create_external(env, const_cast<void *>(event->characteristic), bare_bluetooth_apple__on_bridged_release, NULL, &characteristic);
  assert(err == 0);

  std::string uuid(event->uuid);
  bool is_notifying = event->is_notifying;

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  free(event->uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(characteristic), uuid, is_notifying, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_channel_open(
  js_env_t *env,
  bare_bluetooth_apple_peripheral__on_channel_open_fn function,
  bare_bluetooth_apple_peripheral_t *peripheral,
  bare_bluetooth_apple_peripheral_channel_open_t *event
) {
  auto wrapper = peripheral->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *channel;
  if (event->channel) {
    err = js_create_external(env, const_cast<void *>(event->channel), bare_bluetooth_apple__on_bridged_release, NULL, &channel);
    assert(err == 0);
  } else {
    err = js_get_null(env, &channel);
    assert(err == 0);
  }

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(channel), js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_external_t<BareBluetoothApplePeripheral>
bare_bluetooth_apple_peripheral_init(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBPeripheral> peripheral_handle,
  js_object_t context,
  bare_bluetooth_apple_peripheral__on_services_discover_fn onServicesDiscover,
  bare_bluetooth_apple_peripheral__on_characteristics_discover_fn onCharacteristicsDiscover,
  bare_bluetooth_apple_peripheral__on_read_fn onRead,
  bare_bluetooth_apple_peripheral__on_write_fn onWrite,
  bare_bluetooth_apple_peripheral__on_notify_fn onNotify,
  bare_bluetooth_apple_peripheral__on_notify_state_fn onNotifyState,
  bare_bluetooth_apple_peripheral__on_channel_open_fn onChannelOpen
) {
  @autoreleasepool {
    int err;

    BareBluetoothApplePeripheral *handle = [[BareBluetoothApplePeripheral alloc] init];
    CBPeripheral *peripheral;
    err = js_get_value(env, peripheral_handle, peripheral);
    assert(err == 0);

    handle->env = env;
    handle->destroyed = false;
    handle->peripheral = peripheral;

    err = js_create_reference(env, static_cast<js_value_t *>(context), 1, &handle->ctx);
    assert(err == 0);

    auto *services_discover_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_services_discover,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_services_discover_t>(env, onServicesDiscover, 0, 1, services_discover_ctx, handle->tsfn_services_discover);
    assert(err == 0);

    auto *characteristics_discover_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_characteristics_discover,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_characteristics_discover_t>(env, onCharacteristicsDiscover, 0, 1, characteristics_discover_ctx, handle->tsfn_characteristics_discover);
    assert(err == 0);

    auto *read_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_read,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_read_t>(env, onRead, 0, 1, read_ctx, handle->tsfn_read);
    assert(err == 0);

    auto *write_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_write,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_write_t>(env, onWrite, 0, 1, write_ctx, handle->tsfn_write);
    assert(err == 0);

    auto *notify_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_notify,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_notify_t>(env, onNotify, 0, 1, notify_ctx, handle->tsfn_notify);
    assert(err == 0);

    auto *notify_state_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_notify_state,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_notify_state_t>(env, onNotifyState, 0, 1, notify_state_ctx, handle->tsfn_notify_state);
    assert(err == 0);

    auto *channel_open_ctx = new bare_bluetooth_apple_peripheral_t{(__bridge BareBluetoothApplePeripheral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_peripheral__on_channel_open,
      bare_bluetooth_apple_peripheral__on_finalize,
      bare_bluetooth_apple_peripheral_t,
      bare_bluetooth_apple_peripheral_channel_open_t>(env, onChannelOpen, 0, 1, channel_open_ctx, handle->tsfn_channel_open);
    assert(err == 0);

    handle->peripheral.delegate = handle;

    js_external_t<BareBluetoothApplePeripheral> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<BareBluetoothApplePeripheral>>(
      env,
      static_cast<BareBluetoothApplePeripheral *>(CFBridgingRetain(handle)),
      result
    );
    assert(err == 0);

    return result;
  }
}

static void
bare_bluetooth_apple_peripheral_destroy(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle
) {
  int err;

  BareBluetoothApplePeripheral *wrapper;
  err = js_get_value(env, handle, wrapper);
  assert(err == 0);

  if (wrapper->destroyed) return;

  wrapper->destroyed = true;
  wrapper->peripheral.delegate = nil;

  err = js_delete_reference(env, wrapper->ctx);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_channel_open, js_threadsafe_function_release);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_notify_state, js_threadsafe_function_release);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_notify, js_threadsafe_function_release);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_write, js_threadsafe_function_release);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_read, js_threadsafe_function_release);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_characteristics_discover, js_threadsafe_function_release);
  assert(err == 0);

  err = js_release_threadsafe_function(wrapper->tsfn_services_discover, js_threadsafe_function_release);
  assert(err == 0);
}

static std::string
bare_bluetooth_apple_peripheral_id(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle
) {
  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper;
    int err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    NSString *uuid = wrapper->peripheral.identifier.UUIDString;

    return uuid.UTF8String;
  }
}

static std::optional<std::string>
bare_bluetooth_apple_peripheral_name(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle
) {
  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper;
    int err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    NSString *name = wrapper->peripheral.name;

    if (name) {
      return name.UTF8String;
    } else {
      return std::nullopt;
    }
  }
}

static void
bare_bluetooth_apple_peripheral_discover_services(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  std::optional<std::vector<js_external_t<CBUUID>>> uuids
) {
  @autoreleasepool {
    int err;
    BareBluetoothApplePeripheral *wrapper;
    err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    NSMutableArray<CBUUID *> *serviceUUIDs = nil;

    if (uuids.has_value()) {
      serviceUUIDs = [NSMutableArray arrayWithCapacity:uuids.value().size()];
      for (auto uuid : *uuids) {
        CBUUID *cbuuid;
        err = js_get_value(env, uuid, cbuuid);
        assert(err == 0);
        [serviceUUIDs addObject:cbuuid];
      }
    }

    [wrapper->peripheral discoverServices:serviceUUIDs];
  }
}

static void
bare_bluetooth_apple_peripheral_discover_characteristics(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  js_external_t<CBService> service_handle,
  std::optional<std::vector<js_external_t<CBUUID>>> uuids
) {
  @autoreleasepool {
    int err;

    BareBluetoothApplePeripheral *wrapper;
    err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    CBService *service;
    err = js_get_value(env, service_handle, service);
    assert(err == 0);

    NSMutableArray<CBUUID *> *characteristicUUIDs = nil;

    if (uuids.has_value()) {
      characteristicUUIDs = [NSMutableArray arrayWithCapacity:uuids.value().size()];

      for (auto uuid : uuids.value()) {
        CBUUID *cbuuid;
        err = js_get_value(env, uuid, cbuuid);
        assert(err == 0);
        [characteristicUUIDs addObject:cbuuid];
      }
    }

    [wrapper->peripheral discoverCharacteristics:characteristicUUIDs forService:service];
  }
}

static void
bare_bluetooth_apple_peripheral_read(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  js_external_t<CBCharacteristic> char_handle
) {
  @autoreleasepool {
    int err;

    BareBluetoothApplePeripheral *wrapper;
    err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    CBCharacteristic *characteristic;
    err = js_get_value(env, char_handle, characteristic);
    assert(err == 0);

    [wrapper->peripheral readValueForCharacteristic:characteristic];
  }
}

static void
bare_bluetooth_apple_peripheral_write(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  js_external_t<CBCharacteristic> char_handle,
  js_arraybuffer_span_t data,
  uint64_t size,
  uint64_t offset,
  bool with_response
) {
  @autoreleasepool {
    int err;

    BareBluetoothApplePeripheral *wrapper;
    err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    CBCharacteristic *characteristic;
    err = js_get_value(env, char_handle, characteristic);
    assert(err == 0);

    NSData *nsdata = [NSData dataWithBytes:&data[offset] length:size];

    CBCharacteristicWriteType type = with_response
                                       ? CBCharacteristicWriteWithResponse
                                       : CBCharacteristicWriteWithoutResponse;

    [wrapper->peripheral writeValue:nsdata forCharacteristic:characteristic type:type];
  }
}

static void
bare_bluetooth_apple_peripheral_subscribe(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  js_external_t<CBCharacteristic> char_handle
) {

  @autoreleasepool {
    int err;

    BareBluetoothApplePeripheral *wrapper;
    err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    CBCharacteristic *characteristic;
    err = js_get_value(env, char_handle, characteristic);
    assert(err == 0);

    [wrapper->peripheral setNotifyValue:YES forCharacteristic:characteristic];
  }
}

static void
bare_bluetooth_apple_peripheral_unsubscribe(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  js_external_t<CBCharacteristic> char_handle
) {
  @autoreleasepool {
    int err;

    BareBluetoothApplePeripheral *wrapper;
    err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    CBCharacteristic *characteristic;
    err = js_get_value(env, char_handle, characteristic);
    assert(err == 0);

    // TODO: pass notify as parameter ?
    [wrapper->peripheral setNotifyValue:NO forCharacteristic:characteristic];
  }
}

static void
bare_bluetooth_apple_peripheral_open_l2cap_channel(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  uint32_t psm
) {
  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper;
    int err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    [wrapper->peripheral openL2CAPChannel:static_cast<CBL2CAPPSM>(psm)];
  }
}

static uint32_t
bare_bluetooth_apple_peripheral_service_count(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle
) {
  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper;
    int err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    return wrapper->peripheral.services.count;
  }
}

static js_external_t<CBService>
bare_bluetooth_apple_peripheral_service_at_index(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothApplePeripheral> handle,
  uint32_t index
) {

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper;
    int err = js_get_value(env, handle, wrapper);
    assert(err == 0);

    CBService *service = wrapper->peripheral.services[index];

    js_external_t<CBService> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<CBService>>(
      env,
      static_cast<CBService *>(CFBridgingRetain(service)),
      result
    );

    assert(err == 0);

    return result;
  }
}

static std::string
bare_bluetooth_apple_service_key(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBService> handle
) {
  @autoreleasepool {
    CBService *service;
    int err = js_get_value(env, handle, service);
    assert(err == 0);

    char key[32];
    int len = snprintf(key, sizeof(key), "%p", service);
    assert(len > 0);

    return std::string(key, len);
  }
}

static std::string
bare_bluetooth_apple_service_uuid(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBService> handle
) {
  @autoreleasepool {
    CBService *service;
    int err = js_get_value(env, handle, service);
    assert(err == 0);

    return service.UUID.UUIDString.UTF8String;
  }
}

static std::string
bare_bluetooth_apple_characteristic_key(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBCharacteristic> handle
) {
  @autoreleasepool {
    CBCharacteristic *characteristic;
    int err = js_get_value(env, handle, characteristic);
    assert(err == 0);

    char key[32];
    int len = snprintf(key, sizeof(key), "%p", characteristic);
    assert(len > 0);

    return std::string(key, len);
  }
}

static std::string
bare_bluetooth_apple_characteristic_uuid(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBCharacteristic> handle
) {
  @autoreleasepool {
    CBCharacteristic *characteristic;
    int err = js_get_value(env, handle, characteristic);
    assert(err == 0);

    return characteristic.UUID.UUIDString.UTF8String;
  }
}

static int32_t
bare_bluetooth_apple_characteristic_properties(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBCharacteristic> handle
) {
  @autoreleasepool {
    CBCharacteristic *characteristic;
    int err = js_get_value(env, handle, characteristic);
    assert(err == 0);

    return static_cast<int32_t>(characteristic.properties);
  }
}

static uint32_t
bare_bluetooth_apple_service_characteristic_count(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBService> handle
) {
  @autoreleasepool {
    CBService *service;
    int err = js_get_value(env, handle, service);
    assert(err == 0);

    return service.characteristics.count;
  }
}

static js_external_t<CBCharacteristic>
bare_bluetooth_apple_service_characteristic_at_index(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBService> handle,
  uint32_t index
) {
  @autoreleasepool {
    CBService *service;
    int err = js_get_value(env, handle, service);
    assert(err == 0);

    CBCharacteristic *characteristic = service.characteristics[index];

    js_external_t<CBCharacteristic> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<CBCharacteristic>>(
      env,
      static_cast<CBCharacteristic *>(CFBridgingRetain(characteristic)),
      result
    );

    assert(err == 0);

    return result;
  }
}

@interface BareBluetoothAppleServer : NSObject <CBPeripheralManagerDelegate> {
@public
  js_env_t *env;
  js_ref_t *ctx;
  js_threadsafe_function_t *tsfn_state_change;
  js_threadsafe_function_t *tsfn_add_service;
  js_threadsafe_function_t *tsfn_read_request;
  js_threadsafe_function_t *tsfn_write_requests;
  js_threadsafe_function_t *tsfn_subscribe;
  js_threadsafe_function_t *tsfn_unsubscribe;
  js_threadsafe_function_t *tsfn_ready_to_update;
  js_threadsafe_function_t *tsfn_channel_publish;
  js_threadsafe_function_t *tsfn_channel_open;

  CBPeripheralManager *manager;
  dispatch_queue_t queue;
}

@end

@implementation BareBluetoothAppleServer

- (void)dealloc {
  [super dealloc];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  auto event = new bare_bluetooth_apple_server_state_change_t;
  if (!event) abort();
  event->state = static_cast<int32_t>(peripheral.state);

  js_call_threadsafe_function(tsfn_state_change, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
  auto event = new bare_bluetooth_apple_server_add_service_t;
  if (!event) abort();

  event->service = CFBridgingRetain(service);
  event->uuid = strdup(service.UUID.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_add_service, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request {
  auto event = new bare_bluetooth_apple_server_read_request_t;
  if (!event) abort();

  event->request = CFBridgingRetain(request);

  js_call_threadsafe_function(tsfn_read_request, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
  auto event = new bare_bluetooth_apple_server_write_requests_t;
  if (!event) abort();

  uint32_t count = static_cast<uint32_t>(requests.count);
  event->count = count;
  event->requests = new CFTypeRef[count];
  if (!event->requests) abort();

  for (uint32_t i = 0; i < count; i++) {
    event->requests[i] = CFBridgingRetain(requests[i]);
  }

  js_call_threadsafe_function(tsfn_write_requests, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                       central:(CBCentral *)central
  didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  auto event = new bare_bluetooth_apple_server_subscribe_t;
  if (!event) abort();

  event->central = CFBridgingRetain(central);
  event->characteristic_uuid = strdup(characteristic.UUID.UUIDString.UTF8String);

  js_call_threadsafe_function(tsfn_subscribe, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                           central:(CBCentral *)central
  didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
  auto event = new bare_bluetooth_apple_server_unsubscribe_t;
  if (!event) abort();

  event->central = CFBridgingRetain(central);
  event->characteristic_uuid = strdup(characteristic.UUID.UUIDString.UTF8String);

  js_call_threadsafe_function(tsfn_unsubscribe, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
  js_call_threadsafe_function(tsfn_ready_to_update, NULL, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
   didPublishL2CAPChannel:(CBL2CAPPSM)PSM
                    error:(NSError *)error {
  auto event = new bare_bluetooth_apple_server_channel_publish_t;
  if (!event) abort();

  event->psm = static_cast<uint16_t>(PSM);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_channel_publish, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
      didOpenL2CAPChannel:(CBL2CAPChannel *)l2capChannel
                    error:(NSError *)error {
  auto event = new bare_bluetooth_apple_server_channel_open_t;
  if (!event) abort();

  event->channel = l2capChannel ? CFBridgingRetain(l2capChannel) : NULL;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_channel_open, event, js_threadsafe_function_nonblocking);
}

@end

struct bare_bluetooth_apple_server_t {
  BareBluetoothAppleServer *handle;
};

static void
bare_bluetooth_apple_server__on_finalize(js_env_t *env, bare_bluetooth_apple_server_t *srv) {
  CFBridgingRelease((__bridge CFTypeRef) srv->handle);
  delete srv;
}

using bare_bluetooth_apple_server__on_state_change_fn = js_function_t<void, js_receiver_t, int32_t>;
using bare_bluetooth_apple_server__on_add_service_fn = js_function_t<void, js_receiver_t, js_object_t, std::string, js_object_t>;
using bare_bluetooth_apple_server__on_read_request_fn = js_function_t<void, js_receiver_t, js_object_t>;
using bare_bluetooth_apple_server__on_write_requests_fn = js_function_t<void, js_receiver_t, js_array_t>;
using bare_bluetooth_apple_server__on_subscribe_fn = js_function_t<void, js_receiver_t, js_object_t, std::string>;
using bare_bluetooth_apple_server__on_unsubscribe_fn = js_function_t<void, js_receiver_t, js_object_t, std::string>;
using bare_bluetooth_apple_server__on_ready_to_update_fn = js_function_t<void, js_receiver_t>;
using bare_bluetooth_apple_server__on_channel_publish_fn = js_function_t<void, js_receiver_t, uint32_t, js_object_t>;
using bare_bluetooth_apple_server__on_channel_open_fn = js_function_t<void, js_receiver_t, js_object_t, js_object_t>;

static void
bare_bluetooth_apple_server__on_state_change(
  js_env_t *env,
  bare_bluetooth_apple_server__on_state_change_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_state_change_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  int32_t state = event->state;
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), state);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_add_service(
  js_env_t *env,
  bare_bluetooth_apple_server__on_add_service_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_add_service_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *service;
  err = js_create_external(env, const_cast<void *>(event->service), bare_bluetooth_apple__on_bridged_release, NULL, &service);
  assert(err == 0);

  std::string uuid(event->uuid);

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  free(event->uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(service), uuid, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_read_request(
  js_env_t *env,
  bare_bluetooth_apple_server__on_read_request_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_read_request_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *request;
  err = js_create_external(env, const_cast<void *>(event->request), bare_bluetooth_apple__on_bridged_release, NULL, &request);
  assert(err == 0);

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(request));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_write_requests(
  js_env_t *env,
  bare_bluetooth_apple_server__on_write_requests_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_write_requests_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  uint32_t count = event->count;

  js_value_t *array;
  err = js_create_array_with_length(env, count, &array);
  assert(err == 0);

  for (uint32_t i = 0; i < count; i++) {
    js_value_t *request_external;
    err = js_create_external(env, const_cast<void *>(event->requests[i]), bare_bluetooth_apple__on_bridged_release, NULL, &request_external);
    assert(err == 0);

    err = js_set_element(env, array, i, request_external);
    assert(err == 0);
  }

  delete[] event->requests;
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_array_t(array));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_subscribe(
  js_env_t *env,
  bare_bluetooth_apple_server__on_subscribe_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_subscribe_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *central;
  err = js_create_external(env, const_cast<void *>(event->central), bare_bluetooth_apple__on_bridged_release, NULL, &central);
  assert(err == 0);

  std::string characteristic_uuid(event->characteristic_uuid);

  free(event->characteristic_uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(central), characteristic_uuid);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_unsubscribe(
  js_env_t *env,
  bare_bluetooth_apple_server__on_unsubscribe_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_unsubscribe_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *central;
  err = js_create_external(env, const_cast<void *>(event->central), bare_bluetooth_apple__on_bridged_release, NULL, &central);
  assert(err == 0);

  std::string characteristic_uuid(event->characteristic_uuid);

  free(event->characteristic_uuid);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(central), characteristic_uuid);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_ready_to_update(
  js_env_t *env,
  bare_bluetooth_apple_server__on_ready_to_update_fn function,
  bare_bluetooth_apple_server_t *srv,
  void *data
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, function, js_receiver_t(receiver));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_channel_publish(
  js_env_t *env,
  bare_bluetooth_apple_server__on_channel_publish_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_channel_publish_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  uint32_t psm = event->psm;

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), psm, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_channel_open(
  js_env_t *env,
  bare_bluetooth_apple_server__on_channel_open_fn function,
  bare_bluetooth_apple_server_t *srv,
  bare_bluetooth_apple_server_channel_open_t *event
) {
  auto server = srv->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *channel;
  if (event->channel) {
    err = js_create_external(env, const_cast<void *>(event->channel), bare_bluetooth_apple__on_bridged_release, NULL, &channel);
    assert(err == 0);
  } else {
    err = js_get_null(env, &channel);
    assert(err == 0);
  }

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(channel), js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_external_t<BareBluetoothAppleServer>
bare_bluetooth_apple_server_init(
  js_env_t *env,
  js_receiver_t,
  js_object_t context,
  bare_bluetooth_apple_server__on_state_change_fn on_state_change,
  bare_bluetooth_apple_server__on_add_service_fn on_add_service,
  bare_bluetooth_apple_server__on_read_request_fn on_read_request,
  bare_bluetooth_apple_server__on_write_requests_fn on_write_requests,
  bare_bluetooth_apple_server__on_subscribe_fn on_subscribe,
  bare_bluetooth_apple_server__on_unsubscribe_fn on_unsubscribe,
  bare_bluetooth_apple_server__on_ready_to_update_fn on_ready_to_update,
  bare_bluetooth_apple_server__on_channel_publish_fn on_channel_publish,
  bare_bluetooth_apple_server__on_channel_open_fn on_channel_open
) {
  @autoreleasepool {
    BareBluetoothAppleServer *handle = [[BareBluetoothAppleServer alloc] init];

    handle->env = env;

    int err = js_create_reference(env, static_cast<js_value_t *>(context), 1, &handle->ctx);
    assert(err == 0);

    auto *state_change_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_state_change,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_state_change_t>(env, on_state_change, 0, 1, state_change_ctx, handle->tsfn_state_change);
    assert(err == 0);

    auto *add_service_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_add_service,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_add_service_t>(env, on_add_service, 0, 1, add_service_ctx, handle->tsfn_add_service);
    assert(err == 0);

    auto *read_request_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_read_request,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_read_request_t>(env, on_read_request, 0, 1, read_request_ctx, handle->tsfn_read_request);
    assert(err == 0);

    auto *write_requests_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_write_requests,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_write_requests_t>(env, on_write_requests, 0, 1, write_requests_ctx, handle->tsfn_write_requests);
    assert(err == 0);

    auto *subscribe_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_subscribe,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_subscribe_t>(env, on_subscribe, 0, 1, subscribe_ctx, handle->tsfn_subscribe);
    assert(err == 0);

    auto *unsubscribe_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_unsubscribe,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_unsubscribe_t>(env, on_unsubscribe, 0, 1, unsubscribe_ctx, handle->tsfn_unsubscribe);
    assert(err == 0);

    auto *ready_to_update_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_ready_to_update,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      void>(env, on_ready_to_update, 0, 1, ready_to_update_ctx, handle->tsfn_ready_to_update);
    assert(err == 0);

    auto *channel_publish_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_channel_publish,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_channel_publish_t>(env, on_channel_publish, 0, 1, channel_publish_ctx, handle->tsfn_channel_publish);
    assert(err == 0);

    auto *channel_open_ctx = new bare_bluetooth_apple_server_t{(__bridge BareBluetoothAppleServer *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_server__on_channel_open,
      bare_bluetooth_apple_server__on_finalize,
      bare_bluetooth_apple_server_t,
      bare_bluetooth_apple_server_channel_open_t>(env, on_channel_open, 0, 1, channel_open_ctx, handle->tsfn_channel_open);
    assert(err == 0);

    handle->queue = dispatch_queue_create("bare.bluetooth.server", DISPATCH_QUEUE_SERIAL);
    handle->manager = [[CBPeripheralManager alloc] initWithDelegate:handle queue:handle->queue];

    js_external_t<BareBluetoothAppleServer> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<BareBluetoothAppleServer>>(env, static_cast<BareBluetoothAppleServer *>(CFBridgingRetain(handle)), result);
    assert(err == 0);

    return result;
  }
}

static js_external_t<CBMutableCharacteristic>
bare_bluetooth_apple_create_mutable_characteristic(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBUUID> uuid_handle,
  int32_t properties,
  int32_t permissions,
  std::optional<js_uint8array_t> initial_value
) {
  @autoreleasepool {
    CBUUID *uuid;
    int err = js_get_value(env, uuid_handle, uuid);
    assert(err == 0);

    NSData *value_data = nil;

    if (initial_value) {
      uint8_t *data;
      size_t len;
      err = js_get_typedarray_info(env, *initial_value, data, len);
      assert(err == 0);

      value_data = [NSData dataWithBytes:data length:len];
    }

    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]
      initWithType:uuid
        properties:static_cast<CBCharacteristicProperties>(properties)
             value:value_data
       permissions:static_cast<CBAttributePermissions>(permissions)];

    js_external_t<CBMutableCharacteristic> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<CBMutableCharacteristic>>(
      env,
      static_cast<CBMutableCharacteristic *>(CFBridgingRetain(characteristic)),
      result
    );
    assert(err == 0);

    return result;
  }
}

static js_external_t<CBMutableService>
bare_bluetooth_apple_create_mutable_service(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBUUID> uuid_handle,
  bool is_primary
) {
  @autoreleasepool {
    CBUUID *uuid;
    int err = js_get_value(env, uuid_handle, uuid);
    assert(err == 0);

    CBMutableService *service = [[CBMutableService alloc] initWithType:uuid primary:is_primary];

    js_external_t<CBMutableService> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<CBMutableService>>(
      env,
      static_cast<CBMutableService *>(CFBridgingRetain(service)),
      result
    );

    assert(err == 0);

    return result;
  }
}

static void
bare_bluetooth_apple_service_set_characteristics(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBMutableService> service_handle,
  js_array_t char_array
) {
  @autoreleasepool {
    CBMutableService *service;
    int err = js_get_value(env, service_handle, service);
    assert(err == 0);

    uint32_t len;
    err = js_get_array_length(env, static_cast<js_value_t *>(char_array), &len);
    assert(err == 0);

    NSMutableArray<CBMutableCharacteristic *> *characteristics = [NSMutableArray arrayWithCapacity:len];

    for (uint32_t i = 0; i < len; i++) {
      js_external_t<CBMutableCharacteristic> ext;
      err = js_get_element(env, char_array, i, ext);
      assert(err == 0);

      CBMutableCharacteristic *characteristic;
      err = js_get_value(env, ext, characteristic);
      assert(err == 0);

      [characteristics addObject:characteristic];
    }

    service.characteristics = characteristics;
  }
}

static void
bare_bluetooth_apple_server_add_service(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle,
  js_external_t<CBMutableService> service_handle
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    CBMutableService *service;
    err = js_get_value(env, service_handle, service);
    assert(err == 0);

    [server->manager addService:service];
  }
}

static void
bare_bluetooth_apple_server_start_advertising(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle,
  std::optional<std::string> name,
  std::optional<js_array_t> service_uuids
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    NSMutableDictionary *advertisementData = [NSMutableDictionary dictionary];

    if (name) {
      advertisementData[CBAdvertisementDataLocalNameKey] = [NSString stringWithUTF8String:name->c_str()];
    }

    if (service_uuids) {
      uint32_t len;
      err = js_get_array_length(env, static_cast<js_value_t *>(*service_uuids), &len);
      assert(err == 0);

      NSMutableArray<CBUUID *> *uuids = [NSMutableArray arrayWithCapacity:len];

      for (uint32_t i = 0; i < len; i++) {
        js_external_t<CBUUID> ext;
        err = js_get_element(env, *service_uuids, i, ext);
        assert(err == 0);

        CBUUID *uuid;
        err = js_get_value(env, ext, uuid);
        assert(err == 0);

        [uuids addObject:uuid];
      }

      advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids;
    }

    [server->manager startAdvertising:advertisementData];
  }
}

static void
bare_bluetooth_apple_server_stop_advertising(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    [server->manager stopAdvertising];
  }
}

static std::string
bare_bluetooth_apple_request_characteristic_uuid(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBATTRequest> handle
) {
  @autoreleasepool {
    CBATTRequest *request;
    int err = js_get_value(env, handle, request);
    assert(err == 0);

    return request.characteristic.UUID.UUIDString.UTF8String;
  }
}

static int32_t
bare_bluetooth_apple_request_offset(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBATTRequest> handle
) {
  @autoreleasepool {
    CBATTRequest *request;
    int err = js_get_value(env, handle, request);
    assert(err == 0);

    return static_cast<int32_t>(request.offset);
  }
}

static std::optional<js_uint8array_t>
bare_bluetooth_apple_request_data(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBATTRequest> handle
) {
  @autoreleasepool {
    CBATTRequest *request;
    int err = js_get_value(env, handle, request);
    assert(err == 0);

    NSData *value = request.value;

    if (value && value.length > 0) {
      js_uint8array_t result;
      err = js_create_typedarray(env, static_cast<const uint8_t *>(value.bytes), value.length, result);
      assert(err == 0);

      return result;
    }

    return std::nullopt;
  }
}

static void
bare_bluetooth_apple_server_respond_to_request(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle,
  js_external_t<CBATTRequest> request_handle,
  int32_t result_code,
  std::optional<js_uint8array_t> data
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    CBATTRequest *request;
    err = js_get_value(env, request_handle, request);
    assert(err == 0);

    if (data) {
      uint8_t *buf;
      size_t len;
      err = js_get_typedarray_info(env, *data, buf, len);
      assert(err == 0);

      request.value = [NSData dataWithBytes:buf length:len];
    }

    [server->manager respondToRequest:request withResult:static_cast<CBATTError>(result_code)];
  }
}

static bool
bare_bluetooth_apple_server_update_value(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle,
  js_external_t<CBMutableCharacteristic> char_handle,
  js_uint8array_t data
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    CBMutableCharacteristic *characteristic;
    err = js_get_value(env, char_handle, characteristic);
    assert(err == 0);

    uint8_t *buf;
    size_t len;
    err = js_get_typedarray_info(env, data, buf, len);
    assert(err == 0);

    NSData *nsdata = [NSData dataWithBytes:buf length:len];

    return [server->manager updateValue:nsdata forCharacteristic:characteristic onSubscribedCentrals:nil];
  }
}

static void
bare_bluetooth_apple_server_publish_channel(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle,
  bool encrypted
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    [server->manager publishL2CAPChannelWithEncryption:encrypted];
  }
}

static void
bare_bluetooth_apple_server_unpublish_channel(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle,
  uint32_t psm
) {
  assert(psm <= UINT16_MAX);

  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    [server->manager unpublishL2CAPChannel:static_cast<CBL2CAPPSM>(psm)];
  }
}

static void
bare_bluetooth_apple_server_remove_all_services(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    [server->manager removeAllServices];
  }
}

static void
bare_bluetooth_apple_server_destroy(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleServer> handle
) {
  @autoreleasepool {
    BareBluetoothAppleServer *server;
    int err = js_get_value(env, handle, server);
    assert(err == 0);

    server->manager.delegate = nil;

    err = js_delete_reference(env, server->ctx);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_channel_open, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_channel_publish, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_ready_to_update, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_unsubscribe, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_subscribe, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_write_requests, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_read_request, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_add_service, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(server->tsfn_state_change, js_threadsafe_function_release);
    assert(err == 0);
  }
}

@interface BareBluetoothAppleCentral : NSObject <CBCentralManagerDelegate> {
@public
  js_env_t *env;
  js_ref_t *ctx;
  js_threadsafe_function_t *tsfn_state_change;
  js_threadsafe_function_t *tsfn_discover;
  js_threadsafe_function_t *tsfn_connect;
  js_threadsafe_function_t *tsfn_disconnect;
  js_threadsafe_function_t *tsfn_connect_fail;

  CBCentralManager *manager;
  dispatch_queue_t queue;
}

@end

@implementation BareBluetoothAppleCentral

- (void)dealloc {
  [super dealloc];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  auto event = new bare_bluetooth_apple_central_state_change_t;
  if (!event) abort();
  event->state = static_cast<int32_t>(central.state);

  js_call_threadsafe_function(tsfn_state_change, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                   RSSI:(NSNumber *)RSSI {
  auto event = new bare_bluetooth_apple_central_discover_t;
  if (!event) abort();

  event->peripheral = CFBridgingRetain(peripheral);

  NSString *idString = peripheral.identifier.UUIDString;
  event->id = strdup(idString.UTF8String);

  NSString *peripheralName = peripheral.name;
  event->name = peripheralName ? strdup(peripheralName.UTF8String) : NULL;

  event->rssi = RSSI.intValue;

  js_call_threadsafe_function(tsfn_discover, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
  auto event = new bare_bluetooth_apple_central_connect_t;
  if (!event) abort();

  event->peripheral = CFBridgingRetain(peripheral);
  event->id = strdup(peripheral.identifier.UUIDString.UTF8String);

  js_call_threadsafe_function(tsfn_connect, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didDisconnectPeripheral:(CBPeripheral *)peripheral
                    error:(NSError *)error {
  auto event = new bare_bluetooth_apple_central_disconnect_t;
  if (!event) abort();

  event->id = strdup(peripheral.identifier.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_disconnect, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didFailToConnectPeripheral:(CBPeripheral *)peripheral
                       error:(NSError *)error {
  auto event = new bare_bluetooth_apple_central_connect_fail_t;
  if (!event) abort();

  event->id = strdup(peripheral.identifier.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : strdup("Unknown connection failure");

  js_call_threadsafe_function(tsfn_connect_fail, event, js_threadsafe_function_nonblocking);
}

@end

struct bare_bluetooth_apple_central_t {
  BareBluetoothAppleCentral *handle;
};

static void
bare_bluetooth_apple_central__on_finalize(js_env_t *env, bare_bluetooth_apple_central_t *cen) {
  CFBridgingRelease((__bridge CFTypeRef) cen->handle);
  delete cen;
}

using bare_bluetooth_apple_central__on_state_change_fn = js_function_t<void, js_receiver_t, int32_t>;
using bare_bluetooth_apple_central__on_discover_fn = js_function_t<void, js_receiver_t, js_object_t, std::string, js_object_t, int32_t>;
using bare_bluetooth_apple_central__on_connect_fn = js_function_t<void, js_receiver_t, js_object_t, std::string>;
using bare_bluetooth_apple_central__on_disconnect_fn = js_function_t<void, js_receiver_t, std::string, js_object_t>;
using bare_bluetooth_apple_central__on_connect_fail_fn = js_function_t<void, js_receiver_t, std::string, std::string>;

static void
bare_bluetooth_apple_central__on_state_change(
  js_env_t *env,
  bare_bluetooth_apple_central__on_state_change_fn function,
  bare_bluetooth_apple_central_t *cen,
  bare_bluetooth_apple_central_state_change_t *event
) {
  auto central = cen->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  int32_t state = event->state;
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), state);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_discover(
  js_env_t *env,
  bare_bluetooth_apple_central__on_discover_fn function,
  bare_bluetooth_apple_central_t *cen,
  bare_bluetooth_apple_central_discover_t *event
) {
  auto central = cen->handle;
  int err;

  if (!central->manager.isScanning) {
    CFBridgingRelease(event->peripheral);
    free(event->id);
    if (event->name) free(event->name);
    delete event;
    return;
  }

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *peripheral_ext;
  err = js_create_external(env, const_cast<void *>(event->peripheral), bare_bluetooth_apple__on_bridged_release, NULL, &peripheral_ext);
  assert(err == 0);

  std::string id(event->id);

  js_value_t *name;
  if (event->name) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->name), -1, &name);
    assert(err == 0);
  } else {
    err = js_get_null(env, &name);
    assert(err == 0);
  }

  int32_t rssi = event->rssi;

  free(event->id);
  if (event->name) free(event->name);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(peripheral_ext), id, js_object_t(name), rssi);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_connect(
  js_env_t *env,
  bare_bluetooth_apple_central__on_connect_fn function,
  bare_bluetooth_apple_central_t *cen,
  bare_bluetooth_apple_central_connect_t *event
) {
  auto central = cen->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *peripheral_ext;
  err = js_create_external(env, const_cast<void *>(event->peripheral), bare_bluetooth_apple__on_bridged_release, NULL, &peripheral_ext);
  assert(err == 0);

  std::string id(event->id);

  free(event->id);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_object_t(peripheral_ext), id);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_disconnect(
  js_env_t *env,
  bare_bluetooth_apple_central__on_disconnect_fn function,
  bare_bluetooth_apple_central_t *cen,
  bare_bluetooth_apple_central_disconnect_t *event
) {
  auto central = cen->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  std::string id(event->id);
  free(event->id);

  js_value_t *error;
  if (event->error) {
    err = js_create_string_utf8(env, reinterpret_cast<const utf8_t *>(event->error), -1, &error);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &error);
    assert(err == 0);
  }

  delete event;

  js_call_function(env, function, js_receiver_t(receiver), id, js_object_t(error));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_connect_fail(
  js_env_t *env,
  bare_bluetooth_apple_central__on_connect_fail_fn function,
  bare_bluetooth_apple_central_t *cen,
  bare_bluetooth_apple_central_connect_fail_t *event
) {
  auto central = cen->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  std::string id(event->id);
  std::string error(event->error);

  free(event->id);
  free(event->error);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), id, error);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_external_t<BareBluetoothAppleCentral>
bare_bluetooth_apple_central_init(
  js_env_t *env,
  js_receiver_t,
  js_object_t context,
  bare_bluetooth_apple_central__on_state_change_fn on_state_change,
  bare_bluetooth_apple_central__on_discover_fn on_discover,
  bare_bluetooth_apple_central__on_connect_fn on_connect,
  bare_bluetooth_apple_central__on_disconnect_fn on_disconnect,
  bare_bluetooth_apple_central__on_connect_fail_fn on_connect_fail
) {
  @autoreleasepool {
    BareBluetoothAppleCentral *handle = [[BareBluetoothAppleCentral alloc] init];

    handle->env = env;

    int err = js_create_reference(env, static_cast<js_value_t *>(context), 1, &handle->ctx);
    assert(err == 0);

    auto *state_ctx = new bare_bluetooth_apple_central_t{(__bridge BareBluetoothAppleCentral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_central__on_state_change,
      bare_bluetooth_apple_central__on_finalize,
      bare_bluetooth_apple_central_t,
      bare_bluetooth_apple_central_state_change_t>(env, on_state_change, 0, 1, state_ctx, handle->tsfn_state_change);
    assert(err == 0);

    auto *discover_ctx = new bare_bluetooth_apple_central_t{(__bridge BareBluetoothAppleCentral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_central__on_discover,
      bare_bluetooth_apple_central__on_finalize,
      bare_bluetooth_apple_central_t,
      bare_bluetooth_apple_central_discover_t>(env, on_discover, 0, 1, discover_ctx, handle->tsfn_discover);
    assert(err == 0);

    auto *connect_ctx = new bare_bluetooth_apple_central_t{(__bridge BareBluetoothAppleCentral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_central__on_connect,
      bare_bluetooth_apple_central__on_finalize,
      bare_bluetooth_apple_central_t,
      bare_bluetooth_apple_central_connect_t>(env, on_connect, 0, 1, connect_ctx, handle->tsfn_connect);
    assert(err == 0);

    auto *disconnect_ctx = new bare_bluetooth_apple_central_t{(__bridge BareBluetoothAppleCentral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_central__on_disconnect,
      bare_bluetooth_apple_central__on_finalize,
      bare_bluetooth_apple_central_t,
      bare_bluetooth_apple_central_disconnect_t>(env, on_disconnect, 0, 1, disconnect_ctx, handle->tsfn_disconnect);
    assert(err == 0);

    auto *connect_fail_ctx = new bare_bluetooth_apple_central_t{(__bridge BareBluetoothAppleCentral *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_central__on_connect_fail,
      bare_bluetooth_apple_central__on_finalize,
      bare_bluetooth_apple_central_t,
      bare_bluetooth_apple_central_connect_fail_t>(env, on_connect_fail, 0, 1, connect_fail_ctx, handle->tsfn_connect_fail);
    assert(err == 0);

    handle->queue = dispatch_queue_create("bare.bluetooth.central", DISPATCH_QUEUE_SERIAL);
    handle->manager = [[CBCentralManager alloc] initWithDelegate:handle queue:handle->queue];

    js_external_t<BareBluetoothAppleCentral> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<BareBluetoothAppleCentral>>(env, static_cast<BareBluetoothAppleCentral *>(CFBridgingRetain(handle)), result);
    assert(err == 0);

    return result;
  }
}

static void
bare_bluetooth_apple_central_start_scan(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleCentral> handle,
  std::optional<js_array_t> uuids_array
) {
  @autoreleasepool {
    BareBluetoothAppleCentral *central;
    int err = js_get_value(env, handle, central);
    assert(err == 0);

    NSArray<CBUUID *> *serviceUUIDs = nil;

    if (uuids_array) {
      uint32_t len;
      err = js_get_array_length(env, static_cast<js_value_t *>(*uuids_array), &len);
      assert(err == 0);

      NSMutableArray<CBUUID *> *uuids = [NSMutableArray arrayWithCapacity:len];

      for (uint32_t i = 0; i < len; i++) {
        js_external_t<CBUUID> ext;
        err = js_get_element(env, *uuids_array, i, ext);
        assert(err == 0);

        CBUUID *uuid;
        err = js_get_value(env, ext, uuid);
        assert(err == 0);

        [uuids addObject:uuid];
      }

      serviceUUIDs = uuids;
    }

    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey : @NO};

    [central->manager scanForPeripheralsWithServices:serviceUUIDs options:options];
  }
}

static void
bare_bluetooth_apple_central_stop_scan(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleCentral> handle
) {
  @autoreleasepool {
    BareBluetoothAppleCentral *central;
    int err = js_get_value(env, handle, central);
    assert(err == 0);

    [central->manager stopScan];
  }
}

static void
bare_bluetooth_apple_central_connect(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleCentral> handle,
  js_external_t<CBPeripheral> peripheral_handle
) {
  @autoreleasepool {
    BareBluetoothAppleCentral *central;
    int err = js_get_value(env, handle, central);
    assert(err == 0);

    CBPeripheral *peripheral;
    err = js_get_value(env, peripheral_handle, peripheral);
    assert(err == 0);

    [central->manager connectPeripheral:peripheral options:nil];
  }
}

static void
bare_bluetooth_apple_central_disconnect(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleCentral> handle,
  js_external_t<CBPeripheral> peripheral_handle
) {
  @autoreleasepool {
    BareBluetoothAppleCentral *central;
    int err = js_get_value(env, handle, central);
    assert(err == 0);

    CBPeripheral *peripheral;
    err = js_get_value(env, peripheral_handle, peripheral);
    assert(err == 0);

    [central->manager cancelPeripheralConnection:peripheral];
  }
}

static void
bare_bluetooth_apple_central_destroy(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleCentral> handle
) {
  @autoreleasepool {
    BareBluetoothAppleCentral *central;
    int err = js_get_value(env, handle, central);
    assert(err == 0);

    central->manager.delegate = nil;

    err = js_delete_reference(env, central->ctx);
    assert(err == 0);

    err = js_release_threadsafe_function(central->tsfn_connect_fail, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(central->tsfn_disconnect, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(central->tsfn_connect, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(central->tsfn_discover, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(central->tsfn_state_change, js_threadsafe_function_release);
    assert(err == 0);
  }
}

@interface BareBluetoothAppleL2CAPChannel : NSObject <NSStreamDelegate> {
@public
  js_env_t *env;
  js_ref_t *ctx;
  js_threadsafe_function_t *tsfn_data;
  js_threadsafe_function_t *tsfn_drain;
  js_threadsafe_function_t *tsfn_end;
  js_threadsafe_function_t *tsfn_error;
  js_threadsafe_function_t *tsfn_close;
  js_threadsafe_function_t *tsfn_open;

  CBL2CAPChannel *channel;
  NSInputStream *inputStream;
  NSOutputStream *outputStream;

  NSThread *streamThread;
  std::atomic<bool> opened;
  std::atomic<bool> closing;
  std::atomic<bool> closed;
  std::atomic<bool> destroyed;
  std::atomic<bool> finalized;
  NSMutableArray *writeQueue;
}

- (void)open;
- (void)destroy;
- (void)enqueueWrite:(NSData *)data;
- (void)processWriteQueue;

@end

@implementation BareBluetoothAppleL2CAPChannel

- (void)dealloc {
  [super dealloc];
}

- (void)open {
  if (opened.load()) return;
  opened.store(true);

  inputStream = channel.inputStream;
  outputStream = channel.outputStream;
  writeQueue = [[NSMutableArray alloc] init];

  streamThread = [[NSThread alloc] initWithTarget:self selector:@selector(streamThreadEntry) object:nil];
  streamThread.name = @"bare.bluetooth.l2cap";
  [streamThread start];
}

- (void)streamThreadEntry {
  @autoreleasepool {
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

    inputStream.delegate = self;
    outputStream.delegate = self;

    [inputStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];

    [inputStream open];
    [outputStream open];

    while (!destroyed.load() && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
    }
  }
}

- (void)destroy {
  if (destroyed.load() || closing.load()) return;
  closing.store(true);
  destroyed.store(true);

  if (!opened.load()) {
    js_call_threadsafe_function(tsfn_close, NULL, js_threadsafe_function_nonblocking);
    return;
  }

  [self performSelector:@selector(closeOnStreamThread) onThread:streamThread withObject:nil waitUntilDone:NO];
}

- (void)enqueueWrite:(NSData *)data {
  [writeQueue addObject:data];
  [self processWriteQueue];
}

- (void)processWriteQueue {
  while (writeQueue.count > 0 && outputStream.hasSpaceAvailable) {
    NSData *data = writeQueue[0];
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    NSInteger written = [outputStream write:bytes maxLength:data.length];

    if (written > 0) {
      if (static_cast<NSUInteger>(written) < data.length) {
        writeQueue[0] = [data subdataWithRange:NSMakeRange(written, data.length - written)];
      } else {
        [writeQueue removeObjectAtIndex:0];
      }
    } else {
      break;
    }
  }
}

- (void)closeOnStreamThread {
  if (closed.load()) return;

  [inputStream close];
  [outputStream close];

  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  [inputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
  [outputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];

  inputStream.delegate = nil;
  outputStream.delegate = nil;

  [writeQueue removeAllObjects];

  closed.store(true);

  js_call_threadsafe_function(tsfn_close, NULL, js_threadsafe_function_nonblocking);
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  if (closing.load()) return;

  switch (eventCode) {
  case NSStreamEventHasBytesAvailable: {
    if (stream != inputStream) break;

    std::vector<uint8_t> buffer;
    buffer.reserve(4096);
    size_t total = 0;

    do {
      if (total == buffer.size()) {
        buffer.resize(buffer.size() == 0 ? 4096 : buffer.size() * 2);
      }

      NSInteger bytesRead = [inputStream read:buffer.data() + total maxLength:buffer.size() - total];

      if (bytesRead <= 0) break;

      total += static_cast<size_t>(bytesRead);
    } while (inputStream.hasBytesAvailable);

    if (total > 0) {
      auto event = new bare_bluetooth_apple_l2cap_data_t;
      if (!event) abort();
      event->len = total;
      event->bytes = new uint8_t[total];
      std::memcpy(event->bytes, buffer.data(), total);

      js_call_threadsafe_function(tsfn_data, event, js_threadsafe_function_nonblocking);
    }

    break;
  }

  case NSStreamEventHasSpaceAvailable: {
    if (stream != outputStream) break;

    [self processWriteQueue];

    js_call_threadsafe_function(tsfn_drain, NULL, js_threadsafe_function_nonblocking);

    break;
  }

  case NSStreamEventEndEncountered: {
    js_call_threadsafe_function(tsfn_end, NULL, js_threadsafe_function_nonblocking);

    break;
  }

  case NSStreamEventErrorOccurred: {
    NSError *error = stream.streamError;

    auto event = new bare_bluetooth_apple_l2cap_error_t;
    if (!event) abort();
    event->message = error ? strdup(error.localizedDescription.UTF8String) : strdup("Unknown stream error");

    js_call_threadsafe_function(tsfn_error, event, js_threadsafe_function_nonblocking);

    break;
  }

  case NSStreamEventOpenCompleted: {
    if (stream != outputStream) break;

    js_call_threadsafe_function(tsfn_open, NULL, js_threadsafe_function_nonblocking);

    break;
  }

  default:
    break;
  }
}

@end

struct bare_bluetooth_apple_l2cap_t {
  BareBluetoothAppleL2CAPChannel *handle;
};

static void
bare_bluetooth_apple_l2cap__on_finalize(js_env_t *env, bare_bluetooth_apple_l2cap_t *l2cap) {
  CFBridgingRelease((__bridge CFTypeRef) l2cap->handle);
  delete l2cap;
}

using bare_bluetooth_apple_l2cap__on_data_fn = js_function_t<void, js_receiver_t, js_uint8array_t>;
using bare_bluetooth_apple_l2cap__on_drain_fn = js_function_t<void, js_receiver_t>;
using bare_bluetooth_apple_l2cap__on_end_fn = js_function_t<void, js_receiver_t>;
using bare_bluetooth_apple_l2cap__on_error_fn = js_function_t<void, js_receiver_t, std::string>;
using bare_bluetooth_apple_l2cap__on_close_fn = js_function_t<void, js_receiver_t>;
using bare_bluetooth_apple_l2cap__on_open_fn = js_function_t<void, js_receiver_t>;

static void
bare_bluetooth_apple_l2cap__on_data(
  js_env_t *env,
  bare_bluetooth_apple_l2cap__on_data_fn function,
  bare_bluetooth_apple_l2cap_t *l2cap,
  bare_bluetooth_apple_l2cap_data_t *event
) {
  auto channel = l2cap->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, channel->ctx, &receiver);
  assert(err == 0);

  void *buf;
  js_value_t *arraybuffer;
  err = js_create_arraybuffer(env, event->len, &buf, &arraybuffer);
  assert(err == 0);

  memcpy(buf, event->bytes, event->len);

  js_value_t *typedarray;
  err = js_create_typedarray(env, js_uint8array, event->len, arraybuffer, 0, &typedarray);
  assert(err == 0);

  delete[] reinterpret_cast<uint8_t *>(event->bytes);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), js_uint8array_t(typedarray));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_drain(
  js_env_t *env,
  bare_bluetooth_apple_l2cap__on_drain_fn function,
  bare_bluetooth_apple_l2cap_t *l2cap,
  void *data
) {
  auto channel = l2cap->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, channel->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, function, js_receiver_t(receiver));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_end(
  js_env_t *env,
  bare_bluetooth_apple_l2cap__on_end_fn function,
  bare_bluetooth_apple_l2cap_t *l2cap,
  void *data
) {
  auto channel = l2cap->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, channel->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, function, js_receiver_t(receiver));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_error(
  js_env_t *env,
  bare_bluetooth_apple_l2cap__on_error_fn function,
  bare_bluetooth_apple_l2cap_t *l2cap,
  bare_bluetooth_apple_l2cap_error_t *event
) {
  auto channel = l2cap->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, channel->ctx, &receiver);
  assert(err == 0);

  std::string message(event->message);

  free(event->message);
  delete event;

  js_call_function(env, function, js_receiver_t(receiver), message);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_close(
  js_env_t *env,
  bare_bluetooth_apple_l2cap__on_close_fn function,
  bare_bluetooth_apple_l2cap_t *l2cap,
  void *data
) {
  auto channel = l2cap->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, channel->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, function, js_receiver_t(receiver));

  if (!channel->finalized.exchange(true)) {
    err = js_delete_reference(env, channel->ctx);
    assert(err == 0);

    err = js_release_threadsafe_function(channel->tsfn_open, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(channel->tsfn_close, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(channel->tsfn_error, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(channel->tsfn_end, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(channel->tsfn_drain, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(channel->tsfn_data, js_threadsafe_function_release);
    assert(err == 0);
  }

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_open(
  js_env_t *env,
  bare_bluetooth_apple_l2cap__on_open_fn function,
  bare_bluetooth_apple_l2cap_t *l2cap,
  void *data
) {
  auto channel = l2cap->handle;
  int err;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, channel->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, function, js_receiver_t(receiver));

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_external_t<BareBluetoothAppleL2CAPChannel>
bare_bluetooth_apple_l2cap_init(
  js_env_t *env,
  js_receiver_t,
  js_external_t<CBL2CAPChannel> channel_handle,
  js_object_t context,
  bare_bluetooth_apple_l2cap__on_data_fn on_data,
  bare_bluetooth_apple_l2cap__on_drain_fn on_drain,
  bare_bluetooth_apple_l2cap__on_end_fn on_end,
  bare_bluetooth_apple_l2cap__on_error_fn on_error,
  bare_bluetooth_apple_l2cap__on_close_fn on_close,
  bare_bluetooth_apple_l2cap__on_open_fn on_open
) {
  @autoreleasepool {
    CBL2CAPChannel *channel;
    int err = js_get_value(env, channel_handle, channel);
    assert(err == 0);

    BareBluetoothAppleL2CAPChannel *handle = [[BareBluetoothAppleL2CAPChannel alloc] init];

    handle->env = env;
    handle->channel = channel;
    handle->opened.store(false);
    handle->closing.store(false);
    handle->closed.store(false);
    handle->destroyed.store(false);
    handle->finalized.store(false);

    err = js_create_reference(env, static_cast<js_value_t *>(context), 1, &handle->ctx);
    assert(err == 0);

    auto *data_ctx = new bare_bluetooth_apple_l2cap_t{(__bridge BareBluetoothAppleL2CAPChannel *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_l2cap__on_data,
      bare_bluetooth_apple_l2cap__on_finalize,
      bare_bluetooth_apple_l2cap_t,
      bare_bluetooth_apple_l2cap_data_t>(env, on_data, 0, 1, data_ctx, handle->tsfn_data);
    assert(err == 0);

    auto *drain_ctx = new bare_bluetooth_apple_l2cap_t{(__bridge BareBluetoothAppleL2CAPChannel *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_l2cap__on_drain,
      bare_bluetooth_apple_l2cap__on_finalize,
      bare_bluetooth_apple_l2cap_t,
      void>(env, on_drain, 0, 1, drain_ctx, handle->tsfn_drain);
    assert(err == 0);

    auto *end_ctx = new bare_bluetooth_apple_l2cap_t{(__bridge BareBluetoothAppleL2CAPChannel *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_l2cap__on_end,
      bare_bluetooth_apple_l2cap__on_finalize,
      bare_bluetooth_apple_l2cap_t,
      void>(env, on_end, 0, 1, end_ctx, handle->tsfn_end);
    assert(err == 0);

    auto *error_ctx = new bare_bluetooth_apple_l2cap_t{(__bridge BareBluetoothAppleL2CAPChannel *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_l2cap__on_error,
      bare_bluetooth_apple_l2cap__on_finalize,
      bare_bluetooth_apple_l2cap_t,
      bare_bluetooth_apple_l2cap_error_t>(env, on_error, 0, 1, error_ctx, handle->tsfn_error);
    assert(err == 0);

    auto *close_ctx = new bare_bluetooth_apple_l2cap_t{(__bridge BareBluetoothAppleL2CAPChannel *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_l2cap__on_close,
      bare_bluetooth_apple_l2cap__on_finalize,
      bare_bluetooth_apple_l2cap_t,
      void>(env, on_close, 0, 1, close_ctx, handle->tsfn_close);
    assert(err == 0);

    auto *open_ctx = new bare_bluetooth_apple_l2cap_t{(__bridge BareBluetoothAppleL2CAPChannel *) CFBridgingRetain(handle)};
    err = js_create_threadsafe_function<
      bare_bluetooth_apple_l2cap__on_open,
      bare_bluetooth_apple_l2cap__on_finalize,
      bare_bluetooth_apple_l2cap_t,
      void>(env, on_open, 0, 1, open_ctx, handle->tsfn_open);
    assert(err == 0);

    js_external_t<BareBluetoothAppleL2CAPChannel> result;
    err = js_create_external<bare_bluetooth_apple__release_bridged<BareBluetoothAppleL2CAPChannel>>(env, static_cast<BareBluetoothAppleL2CAPChannel *>(CFBridgingRetain(handle)), result);
    assert(err == 0);

    return result;
  }
}

static void
bare_bluetooth_apple_l2cap_open(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleL2CAPChannel> handle
) {
  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap;
    int err = js_get_value(env, handle, l2cap);
    assert(err == 0);

    [l2cap open];
  }
}

static int32_t
bare_bluetooth_apple_l2cap_write(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleL2CAPChannel> handle,
  js_uint8array_t buf
) {
  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap;
    int err = js_get_value(env, handle, l2cap);
    assert(err == 0);

    if (atomic_load(&l2cap->destroyed) || !atomic_load(&l2cap->opened)) {
      return 0;
    }

    uint8_t *data;
    size_t data_len;
    err = js_get_typedarray_info(env, buf, data, data_len);
    assert(err == 0);

    NSData *nsdata = [NSData dataWithBytes:data length:data_len];
    [l2cap performSelector:@selector(enqueueWrite:) onThread:l2cap->streamThread withObject:nsdata waitUntilDone:NO];

    return static_cast<int32_t>(data_len);
  }
}

static void
bare_bluetooth_apple_l2cap_end(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleL2CAPChannel> handle
) {
  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap;
    int err = js_get_value(env, handle, l2cap);
    assert(err == 0);

    [l2cap destroy];
  }
}

static uint32_t
bare_bluetooth_apple_l2cap_psm(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleL2CAPChannel> handle
) {
  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap;
    int err = js_get_value(env, handle, l2cap);
    assert(err == 0);

    return static_cast<uint32_t>(l2cap->channel.PSM);
  }
}

static std::optional<std::string>
bare_bluetooth_apple_l2cap_peer(
  js_env_t *env,
  js_receiver_t,
  js_external_t<BareBluetoothAppleL2CAPChannel> handle
) {
  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap;
    int err = js_get_value(env, handle, l2cap);
    assert(err == 0);

    CBPeer *peer = l2cap->channel.peer;

    if (peer) {
      return std::string(peer.identifier.UUIDString.UTF8String);
    }

    return std::nullopt;
  }
}

static js_value_t *
bare_bluetooth_apple_exports(js_env_t *env, js_value_t *exports) {
  int err;

#define V(name, fn) \
  err = js_set_property<fn>(env, exports, name); \
  assert(err == 0);

  // CBUUID
  V("createCBUUID", bare_bluetooth_apple_create_cbuuid)

  // Peripheral
  V("peripheralInit", bare_bluetooth_apple_peripheral_init)
  V("peripheralDestroy", bare_bluetooth_apple_peripheral_destroy)
  V("peripheralId", bare_bluetooth_apple_peripheral_id)
  V("peripheralName", bare_bluetooth_apple_peripheral_name)
  V("peripheralDiscoverServices", bare_bluetooth_apple_peripheral_discover_services)
  V("peripheralDiscoverCharacteristics", bare_bluetooth_apple_peripheral_discover_characteristics)
  V("peripheralRead", bare_bluetooth_apple_peripheral_read)
  V("peripheralWrite", bare_bluetooth_apple_peripheral_write)
  V("peripheralSubscribe", bare_bluetooth_apple_peripheral_subscribe)
  V("peripheralUnsubscribe", bare_bluetooth_apple_peripheral_unsubscribe)
  V("peripheralOpenL2CAPChannel", bare_bluetooth_apple_peripheral_open_l2cap_channel)
  V("peripheralServiceCount", bare_bluetooth_apple_peripheral_service_count)
  V("peripheralServiceAtIndex", bare_bluetooth_apple_peripheral_service_at_index)

  // Service/Characteristic
  V("serviceKey", bare_bluetooth_apple_service_key)
  V("serviceUuid", bare_bluetooth_apple_service_uuid)
  V("characteristicKey", bare_bluetooth_apple_characteristic_key)
  V("characteristicUuid", bare_bluetooth_apple_characteristic_uuid)
  V("characteristicProperties", bare_bluetooth_apple_characteristic_properties)
  V("serviceCharacteristicCount", bare_bluetooth_apple_service_characteristic_count)
  V("serviceCharacteristicAtIndex", bare_bluetooth_apple_service_characteristic_at_index)

  // Request
  V("requestCharacteristicUuid", bare_bluetooth_apple_request_characteristic_uuid)
  V("requestOffset", bare_bluetooth_apple_request_offset)
  V("requestData", bare_bluetooth_apple_request_data)

  // Mutable Service/Characteristic
  V("createMutableCharacteristic", bare_bluetooth_apple_create_mutable_characteristic)
  V("createMutableService", bare_bluetooth_apple_create_mutable_service)
  V("serviceSetCharacteristics", bare_bluetooth_apple_service_set_characteristics)

  // Central
  V("centralInit", bare_bluetooth_apple_central_init)
  V("centralStartScan", bare_bluetooth_apple_central_start_scan)
  V("centralStopScan", bare_bluetooth_apple_central_stop_scan)
  V("centralConnect", bare_bluetooth_apple_central_connect)
  V("centralDisconnect", bare_bluetooth_apple_central_disconnect)
  V("centralDestroy", bare_bluetooth_apple_central_destroy)

  // Server
  V("serverInit", bare_bluetooth_apple_server_init)
  V("serverAddService", bare_bluetooth_apple_server_add_service)
  V("serverStartAdvertising", bare_bluetooth_apple_server_start_advertising)
  V("serverStopAdvertising", bare_bluetooth_apple_server_stop_advertising)
  V("serverRespondToRequest", bare_bluetooth_apple_server_respond_to_request)
  V("serverUpdateValue", bare_bluetooth_apple_server_update_value)
  V("serverRemoveAllServices", bare_bluetooth_apple_server_remove_all_services)
  V("serverDestroy", bare_bluetooth_apple_server_destroy)
  V("serverPublishChannel", bare_bluetooth_apple_server_publish_channel)
  V("serverUnpublishChannel", bare_bluetooth_apple_server_unpublish_channel)

  // L2CAP
  V("l2capInit", bare_bluetooth_apple_l2cap_init)
  V("l2capOpen", bare_bluetooth_apple_l2cap_open)
  V("l2capWrite", bare_bluetooth_apple_l2cap_write)
  V("l2capEnd", bare_bluetooth_apple_l2cap_end)
  V("l2capPsm", bare_bluetooth_apple_l2cap_psm)
  V("l2capPeer", bare_bluetooth_apple_l2cap_peer)

#undef V

#define V(name, n) \
  { \
    js_value_t *val; \
    err = js_create_int32(env, n, &val); \
    assert(err == 0); \
    err = js_set_named_property(env, exports, name, val); \
    assert(err == 0); \
  }

  V("STATE_UNKNOWN", CBManagerStateUnknown)
  V("STATE_POWERED_ON", CBManagerStatePoweredOn)
  V("STATE_POWERED_OFF", CBManagerStatePoweredOff)
  V("STATE_RESETTING", CBManagerStateResetting)
  V("STATE_UNAUTHORIZED", CBManagerStateUnauthorized)
  V("STATE_UNSUPPORTED", CBManagerStateUnsupported)

  V("PROPERTY_READ", CBCharacteristicPropertyRead)
  V("PROPERTY_WRITE_WITHOUT_RESPONSE", CBCharacteristicPropertyWriteWithoutResponse)
  V("PROPERTY_WRITE", CBCharacteristicPropertyWrite)
  V("PROPERTY_NOTIFY", CBCharacteristicPropertyNotify)
  V("PROPERTY_INDICATE", CBCharacteristicPropertyIndicate)

  V("PERMISSION_READABLE", CBAttributePermissionsReadable)
  V("PERMISSION_WRITEABLE", CBAttributePermissionsWriteable)
  V("PERMISSION_READ_ENCRYPTED", CBAttributePermissionsReadEncryptionRequired)
  V("PERMISSION_WRITE_ENCRYPTED", CBAttributePermissionsWriteEncryptionRequired)

  V("ATT_SUCCESS", CBATTErrorSuccess)
  V("ATT_INVALID_HANDLE", CBATTErrorInvalidHandle)
  V("ATT_READ_NOT_PERMITTED", CBATTErrorReadNotPermitted)
  V("ATT_WRITE_NOT_PERMITTED", CBATTErrorWriteNotPermitted)
  V("ATT_INSUFFICIENT_RESOURCES", CBATTErrorInsufficientResources)
  V("ATT_UNLIKELY_ERROR", CBATTErrorUnlikelyError)
#undef V

  return exports;
}

BARE_MODULE(bare_bluetooth_apple, bare_bluetooth_apple_exports)
