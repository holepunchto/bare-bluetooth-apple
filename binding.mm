#include <cstdint>
#include <atomic>

#import <bare.h>
#import <js.h>
#import <jstl.h>

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

static void
bare_bluetooth_apple__on_bridged_release(js_env_t *env, void *data, void *finalize_hint) {
  CFBridgingRelease(data);
}

static js_external_t<void>
bare_bluetooth_apple_create_cbuuid(
  js_env_t *env,
  js_receiver_t,
  std::string str
) {
  int err;

  @autoreleasepool {
    CBUUID *uuid = [CBUUID UUIDWithString:[NSString stringWithUTF8String:str.c_str()]];
    void *retained_uuid = const_cast<void *>(CFBridgingRetain(uuid));

    js_external_t<void> result;
    err = js_create_external(env, retained_uuid, result);
    assert(err == 0);

    return result;
  }
}

typedef struct {
  CFTypeRef ref;
  char *uuid;
} bare_bluetooth_apple_external_t;

typedef struct {
  uint32_t count;
  char *error;
} bare_bluetooth_apple_peripheral_services_discover_t;

typedef struct {
  CFTypeRef service;
  uint32_t count;
  char *error;
} bare_bluetooth_apple_peripheral_characteristics_discover_t;

typedef struct {
  CFTypeRef characteristic;
  char *uuid;
  void *data;
  size_t data_len;
  char *error;
} bare_bluetooth_apple_peripheral_read_t;

typedef struct {
  CFTypeRef characteristic;
  char *uuid;
  char *error;
} bare_bluetooth_apple_peripheral_write_t;

typedef struct {
  CFTypeRef characteristic;
  char *uuid;
  void *data;
  size_t data_len;
  char *error;
} bare_bluetooth_apple_peripheral_notify_t;

typedef struct {
  CFTypeRef characteristic;
  char *uuid;
  bool is_notifying;
  char *error;
} bare_bluetooth_apple_peripheral_notify_state_t;

typedef struct {
  CFTypeRef channel;
  char *error;
} bare_bluetooth_apple_peripheral_channel_open_t;

typedef struct {
  int32_t state;
} bare_bluetooth_apple_server_state_change_t;

typedef struct {
  CFTypeRef service;
  char *uuid;
  char *error;
} bare_bluetooth_apple_server_add_service_t;

typedef struct {
  CFTypeRef request;
} bare_bluetooth_apple_server_read_request_t;

typedef struct {
  uint32_t count;
  CFTypeRef *requests;
} bare_bluetooth_apple_server_write_requests_t;

typedef struct {
  CFTypeRef central;
  char *characteristic_uuid;
} bare_bluetooth_apple_server_subscribe_t;

typedef struct {
  CFTypeRef central;
  char *characteristic_uuid;
} bare_bluetooth_apple_server_unsubscribe_t;

typedef struct {
  uint16_t psm;
  char *error;
} bare_bluetooth_apple_server_channel_publish_t;

typedef struct {
  CFTypeRef channel;
  char *error;
} bare_bluetooth_apple_server_channel_open_t;

typedef struct {
  int32_t state;
} bare_bluetooth_apple_central_state_change_t;

typedef struct {
  CFTypeRef peripheral;
  char *id;
  char *name;
  int32_t rssi;
} bare_bluetooth_apple_central_discover_t;

typedef struct {
  CFTypeRef peripheral;
  char *id;
} bare_bluetooth_apple_central_connect_t;

typedef struct {
  char *id;
  char *error;
} bare_bluetooth_apple_central_disconnect_t;

typedef struct {
  char *id;
  char *error;
} bare_bluetooth_apple_central_connect_fail_t;

typedef struct {
  void *bytes;
  size_t len;
} bare_bluetooth_apple_l2cap_data_t;

typedef struct {
  char *message;
} bare_bluetooth_apple_l2cap_error_t;

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
  bare_bluetooth_apple_peripheral_services_discover_t *event = static_cast<bare_bluetooth_apple_peripheral_services_discover_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_services_discover_t)));
  if (!event) abort();
  event->count = error ? 0 : (uint32_t) p.services.count;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_services_discover, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didDiscoverCharacteristicsForService:(CBService *)service
                                 error:(NSError *)error {
  bare_bluetooth_apple_peripheral_characteristics_discover_t *event = static_cast<bare_bluetooth_apple_peripheral_characteristics_discover_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_characteristics_discover_t)));
  if (!event) abort();

  event->service = CFBridgingRetain(service);
  event->count = error ? 0 : (uint32_t) service.characteristics.count;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_characteristics_discover, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                            error:(NSError *)error {
  if (characteristic.isNotifying) {
    bare_bluetooth_apple_peripheral_notify_t *event = static_cast<bare_bluetooth_apple_peripheral_notify_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_notify_t)));
    if (!event) abort();

    event->characteristic = CFBridgingRetain(characteristic);
    event->uuid = strdup(characteristic.UUID.UUIDString.UTF8String);
    event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

    NSData *value = characteristic.value;

    if (!error && value && value.length > 0) {
      event->data_len = value.length;
      event->data = static_cast<void *>(malloc(value.length));
      if (!event->data) abort();
      memcpy(event->data, value.bytes, value.length);
    } else {
      event->data = NULL;
      event->data_len = 0;
    }

    js_call_threadsafe_function(tsfn_notify, event, js_threadsafe_function_nonblocking);
  } else {
    bare_bluetooth_apple_peripheral_read_t *event = static_cast<bare_bluetooth_apple_peripheral_read_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_read_t)));
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
        event->data = static_cast<void *>(malloc(value.length));
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
  bare_bluetooth_apple_peripheral_write_t *event = static_cast<bare_bluetooth_apple_peripheral_write_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_write_t)));
  if (!event) abort();

  event->characteristic = CFBridgingRetain(characteristic);
  event->uuid = strdup(characteristic.UUID.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_write, event, js_threadsafe_function_nonblocking);
}

- (void)peripheral:(CBPeripheral *)p
  didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                        error:(NSError *)error {
  bare_bluetooth_apple_peripheral_notify_state_t *event = static_cast<bare_bluetooth_apple_peripheral_notify_state_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_notify_state_t)));
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
  bare_bluetooth_apple_peripheral_channel_open_t *event = static_cast<bare_bluetooth_apple_peripheral_channel_open_t *>(malloc(sizeof(bare_bluetooth_apple_peripheral_channel_open_t)));
  if (!event) abort();

  event->channel = l2capChannel ? CFBridgingRetain(l2capChannel) : NULL;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_channel_open, event, js_threadsafe_function_nonblocking);
}

@end

static void
bare_bluetooth_apple_peripheral__on_services_discover(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_services_discover_t *event = (bare_bluetooth_apple_peripheral_services_discover_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_uint32(env, event->count, &argv[0]);
  assert(err == 0);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[1]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[1]);
    assert(err == 0);
  }

  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_characteristics_discover(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_characteristics_discover_t *event = (bare_bluetooth_apple_peripheral_characteristics_discover_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[3];

  err = js_create_external(env, (void *) event->service, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_uint32(env, event->count, &argv[1]);
  assert(err == 0);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[2]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[2]);
    assert(err == 0);
  }

  free(event);

  js_call_function(env, receiver, function, 3, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_read(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_read_t *event = (bare_bluetooth_apple_peripheral_read_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[4];

  err = js_create_external(env, (void *) event->characteristic, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->uuid, -1, &argv[1]);
  assert(err == 0);

  if (event->data && event->data_len > 0) {
    void *buf;
    js_value_t *arraybuffer;
    err = js_create_arraybuffer(env, event->data_len, &buf, &arraybuffer);
    assert(err == 0);

    memcpy(buf, event->data, event->data_len);

    err = js_create_typedarray(env, js_uint8array, event->data_len, arraybuffer, 0, &argv[2]);
    assert(err == 0);

    free(event->data);
  } else {
    err = js_get_null(env, &argv[2]);
    assert(err == 0);
  }

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[3]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[3]);
    assert(err == 0);
  }

  free(event->uuid);
  free(event);

  js_call_function(env, receiver, function, 4, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_write(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_write_t *event = (bare_bluetooth_apple_peripheral_write_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[3];

  err = js_create_external(env, (void *) event->characteristic, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->uuid, -1, &argv[1]);
  assert(err == 0);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[2]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[2]);
    assert(err == 0);
  }

  free(event->uuid);
  free(event);

  js_call_function(env, receiver, function, 3, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_notify(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_notify_t *event = (bare_bluetooth_apple_peripheral_notify_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[4];

  err = js_create_external(env, (void *) event->characteristic, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->uuid, -1, &argv[1]);
  assert(err == 0);

  if (event->data && event->data_len > 0) {
    void *buf;
    js_value_t *arraybuffer;
    err = js_create_arraybuffer(env, event->data_len, &buf, &arraybuffer);
    assert(err == 0);

    memcpy(buf, event->data, event->data_len);

    err = js_create_typedarray(env, js_uint8array, event->data_len, arraybuffer, 0, &argv[2]);
    assert(err == 0);

    free(event->data);
  } else {
    err = js_get_null(env, &argv[2]);
    assert(err == 0);
  }

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[3]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[3]);
    assert(err == 0);
  }

  free(event->uuid);
  free(event);

  js_call_function(env, receiver, function, 4, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_notify_state(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_notify_state_t *event = (bare_bluetooth_apple_peripheral_notify_state_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[4];

  err = js_create_external(env, (void *) event->characteristic, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->uuid, -1, &argv[1]);
  assert(err == 0);

  err = js_get_boolean(env, event->is_notifying, &argv[2]);
  assert(err == 0);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[3]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[3]);
    assert(err == 0);
  }

  free(event->uuid);
  free(event);

  js_call_function(env, receiver, function, 4, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_peripheral__on_channel_open(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_peripheral_channel_open_t *event = (bare_bluetooth_apple_peripheral_channel_open_t *) data;
  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, wrapper->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  if (event->channel) {
    err = js_create_external(env, (void *) event->channel, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
    assert(err == 0);
  } else {
    err = js_get_null(env, &argv[0]);
    assert(err == 0);
  }

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[1]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[1]);
    assert(err == 0);
  }

  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_value_t *
bare_bluetooth_apple_peripheral_init(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 9;
  js_value_t *argv[9];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 9);

  void *peripheral_handle;
  err = js_get_value_external(env, argv[0], &peripheral_handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothApplePeripheral *handle = [[BareBluetoothApplePeripheral alloc] init];

    handle->env = env;
    handle->destroyed = false;
    handle->peripheral = (__bridge CBPeripheral *) peripheral_handle;

    err = js_create_reference(env, argv[1], 1, &handle->ctx);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[2], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_services_discover, &handle->tsfn_services_discover);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[3], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_characteristics_discover, &handle->tsfn_characteristics_discover);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[4], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_read, &handle->tsfn_read);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[5], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_write, &handle->tsfn_write);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[6], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_notify, &handle->tsfn_notify);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[7], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_notify_state, &handle->tsfn_notify_state);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[8], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_peripheral__on_channel_open, &handle->tsfn_channel_open);
    assert(err == 0);

    handle->peripheral.delegate = handle;

    err = js_create_external(env, (void *) CFBridgingRetain(handle), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_peripheral_id(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    NSString *uuid = wrapper->peripheral.identifier.UUIDString;

    err = js_create_string_utf8(env, (const utf8_t *) uuid.UTF8String, -1, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_peripheral_name(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    NSString *name = wrapper->peripheral.name;

    if (name) {
      err = js_create_string_utf8(env, (const utf8_t *) name.UTF8String, -1, &result);
      assert(err == 0);
    } else {
      err = js_get_null(env, &result);
      assert(err == 0);
    }
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_peripheral_discover_services(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1 || argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;

    NSArray<CBUUID *> *serviceUUIDs = nil;

    if (argc == 2) {
      bool is_null;
      err = js_is_null(env, argv[1], &is_null);
      assert(err == 0);

      if (!is_null) {
        uint32_t len;
        err = js_get_array_length(env, argv[1], &len);
        assert(err == 0);

        NSMutableArray<CBUUID *> *uuids = [NSMutableArray arrayWithCapacity:len];

        for (uint32_t i = 0; i < len; i++) {
          js_value_t *element;
          err = js_get_element(env, argv[1], i, &element);
          assert(err == 0);

          void *uuid_handle;
          err = js_get_value_external(env, element, &uuid_handle);
          assert(err == 0);

          [uuids addObject:(__bridge CBUUID *) uuid_handle];
        }

        serviceUUIDs = uuids;
      }
    }

    [wrapper->peripheral discoverServices:serviceUUIDs];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_peripheral_discover_characteristics(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 3;
  js_value_t *argv[3];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2 || argc == 3);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *service_handle;
  err = js_get_value_external(env, argv[1], &service_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    CBService *service = (__bridge CBService *) service_handle;

    NSArray<CBUUID *> *characteristicUUIDs = nil;

    if (argc == 3) {
      bool is_null;
      err = js_is_null(env, argv[2], &is_null);
      assert(err == 0);

      if (!is_null) {
        uint32_t len;
        err = js_get_array_length(env, argv[2], &len);
        assert(err == 0);

        NSMutableArray<CBUUID *> *uuids = [NSMutableArray arrayWithCapacity:len];

        for (uint32_t i = 0; i < len; i++) {
          js_value_t *element;
          err = js_get_element(env, argv[2], i, &element);
          assert(err == 0);

          void *uuid_handle;
          err = js_get_value_external(env, element, &uuid_handle);
          assert(err == 0);

          [uuids addObject:(__bridge CBUUID *) uuid_handle];
        }

        characteristicUUIDs = uuids;
      }
    }

    [wrapper->peripheral discoverCharacteristics:characteristicUUIDs forService:service];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_peripheral_read(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *char_handle;
  err = js_get_value_external(env, argv[1], &char_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    CBCharacteristic *characteristic = (__bridge CBCharacteristic *) char_handle;

    [wrapper->peripheral readValueForCharacteristic:characteristic];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_peripheral_write(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 4;
  js_value_t *argv[4];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 4);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *char_handle;
  err = js_get_value_external(env, argv[1], &char_handle);
  assert(err == 0);

  uint8_t *data;
  size_t data_len;
  err = js_get_typedarray_info(env, argv[2], NULL, (void **) &data, &data_len, NULL, NULL);
  assert(err == 0);

  bool with_response;
  err = js_get_value_bool(env, argv[3], &with_response);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    CBCharacteristic *characteristic = (__bridge CBCharacteristic *) char_handle;

    NSData *nsdata = [NSData dataWithBytes:data length:data_len];

    CBCharacteristicWriteType type = with_response
                                       ? CBCharacteristicWriteWithResponse
                                       : CBCharacteristicWriteWithoutResponse;

    [wrapper->peripheral writeValue:nsdata forCharacteristic:characteristic type:type];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_peripheral_subscribe(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *char_handle;
  err = js_get_value_external(env, argv[1], &char_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    CBCharacteristic *characteristic = (__bridge CBCharacteristic *) char_handle;

    [wrapper->peripheral setNotifyValue:YES forCharacteristic:characteristic];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_peripheral_unsubscribe(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *char_handle;
  err = js_get_value_external(env, argv[1], &char_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;
    CBCharacteristic *characteristic = (__bridge CBCharacteristic *) char_handle;

    [wrapper->peripheral setNotifyValue:NO forCharacteristic:characteristic];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_service_key(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  char key[32];
  int len = snprintf(key, sizeof(key), "%p", handle);
  assert(len > 0);

  err = js_create_string_utf8(env, (const utf8_t *) key, len, &result);
  assert(err == 0);

  return result;
}

static js_value_t *
bare_bluetooth_apple_service_uuid(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBService *service = (__bridge CBService *) handle;

    err = js_create_string_utf8(env, (const utf8_t *) service.UUID.UUIDString.UTF8String, -1, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_characteristic_key(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  char key[32];
  int len = snprintf(key, sizeof(key), "%p", handle);
  assert(len > 0);

  err = js_create_string_utf8(env, (const utf8_t *) key, len, &result);
  assert(err == 0);

  return result;
}

static js_value_t *
bare_bluetooth_apple_characteristic_uuid(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBCharacteristic *characteristic = (__bridge CBCharacteristic *) handle;

    err = js_create_string_utf8(env, (const utf8_t *) characteristic.UUID.UUIDString.UTF8String, -1, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_characteristic_properties(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBCharacteristic *characteristic = (__bridge CBCharacteristic *) handle;

    err = js_create_int32(env, (int32_t) characteristic.properties, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_peripheral_service_count(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;

    err = js_create_uint32(env, (uint32_t) wrapper->peripheral.services.count, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_peripheral_service_at_index(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  uint32_t index;
  err = js_get_value_uint32(env, argv[1], &index);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;

    CBService *service = wrapper->peripheral.services[index];

    err = js_create_external(env, (void *) CFBridgingRetain(service), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_service_characteristic_count(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBService *service = (__bridge CBService *) handle;

    err = js_create_uint32(env, (uint32_t) service.characteristics.count, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_service_characteristic_at_index(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  uint32_t index;
  err = js_get_value_uint32(env, argv[1], &index);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBService *service = (__bridge CBService *) handle;

    CBCharacteristic *characteristic = service.characteristics[index];

    err = js_create_external(env, (void *) CFBridgingRetain(characteristic), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_peripheral_open_l2cap_channel(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  uint32_t psm;
  err = js_get_value_uint32(env, argv[1], &psm);
  assert(err == 0);
  assert(psm <= UINT16_MAX);

  @autoreleasepool {
    BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;

    [wrapper->peripheral openL2CAPChannel:(CBL2CAPPSM) psm];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_peripheral_destroy(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  BareBluetoothApplePeripheral *wrapper = (__bridge BareBluetoothApplePeripheral *) handle;

  if (wrapper->destroyed) return NULL;

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

  return NULL;
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
  bare_bluetooth_apple_server_state_change_t *event = static_cast<bare_bluetooth_apple_server_state_change_t *>(malloc(sizeof(bare_bluetooth_apple_server_state_change_t)));
  if (!event) abort();
  event->state = (int32_t) peripheral.state;

  js_call_threadsafe_function(tsfn_state_change, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
  bare_bluetooth_apple_server_add_service_t *event = static_cast<bare_bluetooth_apple_server_add_service_t *>(malloc(sizeof(bare_bluetooth_apple_server_add_service_t)));
  if (!event) abort();

  event->service = CFBridgingRetain(service);
  event->uuid = strdup(service.UUID.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_add_service, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request {
  bare_bluetooth_apple_server_read_request_t *event = static_cast<bare_bluetooth_apple_server_read_request_t *>(malloc(sizeof(bare_bluetooth_apple_server_read_request_t)));
  if (!event) abort();

  event->request = CFBridgingRetain(request);

  js_call_threadsafe_function(tsfn_read_request, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
  bare_bluetooth_apple_server_write_requests_t *event = static_cast<bare_bluetooth_apple_server_write_requests_t *>(malloc(sizeof(bare_bluetooth_apple_server_write_requests_t)));
  if (!event) abort();

  uint32_t count = (uint32_t) requests.count;
  event->count = count;
  event->requests = static_cast<CFTypeRef *>(malloc(sizeof(CFTypeRef) * count));
  if (!event->requests) abort();

  for (uint32_t i = 0; i < count; i++) {
    event->requests[i] = CFBridgingRetain(requests[i]);
  }

  js_call_threadsafe_function(tsfn_write_requests, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                       central:(CBCentral *)central
  didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  bare_bluetooth_apple_server_subscribe_t *event = static_cast<bare_bluetooth_apple_server_subscribe_t *>(malloc(sizeof(bare_bluetooth_apple_server_subscribe_t)));
  if (!event) abort();

  event->central = CFBridgingRetain(central);
  event->characteristic_uuid = strdup(characteristic.UUID.UUIDString.UTF8String);

  js_call_threadsafe_function(tsfn_subscribe, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                           central:(CBCentral *)central
  didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
  bare_bluetooth_apple_server_unsubscribe_t *event = static_cast<bare_bluetooth_apple_server_unsubscribe_t *>(malloc(sizeof(bare_bluetooth_apple_server_unsubscribe_t)));
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
  bare_bluetooth_apple_server_channel_publish_t *event = static_cast<bare_bluetooth_apple_server_channel_publish_t *>(malloc(sizeof(bare_bluetooth_apple_server_channel_publish_t)));
  if (!event) abort();

  event->psm = (uint16_t) PSM;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_channel_publish, event, js_threadsafe_function_nonblocking);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
      didOpenL2CAPChannel:(CBL2CAPChannel *)l2capChannel
                    error:(NSError *)error {
  bare_bluetooth_apple_server_channel_open_t *event = static_cast<bare_bluetooth_apple_server_channel_open_t *>(malloc(sizeof(bare_bluetooth_apple_server_channel_open_t)));
  if (!event) abort();

  event->channel = l2capChannel ? CFBridgingRetain(l2capChannel) : NULL;
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_channel_open, event, js_threadsafe_function_nonblocking);
}

@end

static void
bare_bluetooth_apple_server__on_state_change(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_state_change_t *event = (bare_bluetooth_apple_server_state_change_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[1];
  err = js_create_int32(env, event->state, &argv[0]);
  assert(err == 0);

  free(event);

  js_call_function(env, receiver, function, 1, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_add_service(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_add_service_t *event = (bare_bluetooth_apple_server_add_service_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[3];

  err = js_create_external(env, (void *) event->service, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->uuid, -1, &argv[1]);
  assert(err == 0);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[2]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[2]);
    assert(err == 0);
  }

  free(event->uuid);
  free(event);

  js_call_function(env, receiver, function, 3, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_read_request(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_read_request_t *event = (bare_bluetooth_apple_server_read_request_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[1];

  err = js_create_external(env, (void *) event->request, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  free(event);

  js_call_function(env, receiver, function, 1, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_write_requests(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_write_requests_t *event = (bare_bluetooth_apple_server_write_requests_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  uint32_t count = event->count;

  js_value_t *argv[1];
  err = js_create_array_with_length(env, count, &argv[0]);
  assert(err == 0);

  for (uint32_t i = 0; i < count; i++) {
    js_value_t *request_external;
    err = js_create_external(env, (void *) event->requests[i], bare_bluetooth_apple__on_bridged_release, NULL, &request_external);
    assert(err == 0);

    err = js_set_element(env, argv[0], i, request_external);
    assert(err == 0);
  }

  free(event->requests);
  free(event);

  js_call_function(env, receiver, function, 1, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_subscribe(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_subscribe_t *event = (bare_bluetooth_apple_server_subscribe_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_external(env, (void *) event->central, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->characteristic_uuid, -1, &argv[1]);
  assert(err == 0);

  free(event->characteristic_uuid);
  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_unsubscribe(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_unsubscribe_t *event = (bare_bluetooth_apple_server_unsubscribe_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_external(env, (void *) event->central, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->characteristic_uuid, -1, &argv[1]);
  assert(err == 0);

  free(event->characteristic_uuid);
  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_ready_to_update(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, receiver, function, 0, NULL, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_channel_publish(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_channel_publish_t *event = (bare_bluetooth_apple_server_channel_publish_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_uint32(env, event->psm, &argv[0]);
  assert(err == 0);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[1]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[1]);
    assert(err == 0);
  }

  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_server__on_channel_open(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_server_channel_open_t *event = (bare_bluetooth_apple_server_channel_open_t *) data;
  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, server->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  if (event->channel) {
    err = js_create_external(env, (void *) event->channel, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
    assert(err == 0);
  } else {
    err = js_get_null(env, &argv[0]);
    assert(err == 0);
  }

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[1]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[1]);
    assert(err == 0);
  }

  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_value_t *
bare_bluetooth_apple_server_init(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 10;
  js_value_t *argv[10];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 10);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothAppleServer *handle = [[BareBluetoothAppleServer alloc] init];

    handle->env = env;

    err = js_create_reference(env, argv[0], 1, &handle->ctx);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[1], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_state_change, &handle->tsfn_state_change);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[2], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_add_service, &handle->tsfn_add_service);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[3], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_read_request, &handle->tsfn_read_request);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[4], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_write_requests, &handle->tsfn_write_requests);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[5], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_subscribe, &handle->tsfn_subscribe);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[6], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_unsubscribe, &handle->tsfn_unsubscribe);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[7], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_ready_to_update, &handle->tsfn_ready_to_update);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[8], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_channel_publish, &handle->tsfn_channel_publish);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[9], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_server__on_channel_open, &handle->tsfn_channel_open);
    assert(err == 0);

    handle->queue = dispatch_queue_create("bare.bluetooth.server", DISPATCH_QUEUE_SERIAL);
    handle->manager = [[CBPeripheralManager alloc] initWithDelegate:handle queue:handle->queue];

    err = js_create_external(env, (void *) CFBridgingRetain(handle), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_create_mutable_characteristic(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 4;
  js_value_t *argv[4];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 4);

  void *uuid_handle;
  err = js_get_value_external(env, argv[0], &uuid_handle);
  assert(err == 0);

  int32_t properties;
  err = js_get_value_int32(env, argv[1], &properties);
  assert(err == 0);

  int32_t permissions;
  err = js_get_value_int32(env, argv[2], &permissions);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBUUID *uuid = (__bridge CBUUID *) uuid_handle;

    NSData *initial_value = nil;
    bool is_null;
    err = js_is_null(env, argv[3], &is_null);
    assert(err == 0);

    if (!is_null) {
      uint8_t *data;
      size_t data_len;
      err = js_get_typedarray_info(env, argv[3], NULL, (void **) &data, &data_len, NULL, NULL);
      assert(err == 0);

      initial_value = [NSData dataWithBytes:data length:data_len];
    }

    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]
      initWithType:uuid
        properties:(CBCharacteristicProperties) properties
             value:initial_value
       permissions:(CBAttributePermissions) permissions];

    err = js_create_external(env, (void *) CFBridgingRetain(characteristic), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_create_mutable_service(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *uuid_handle;
  err = js_get_value_external(env, argv[0], &uuid_handle);
  assert(err == 0);

  bool is_primary;
  err = js_get_value_bool(env, argv[1], &is_primary);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBUUID *uuid = (__bridge CBUUID *) uuid_handle;

    CBMutableService *service = [[CBMutableService alloc] initWithType:uuid primary:is_primary];

    err = js_create_external(env, (void *) CFBridgingRetain(service), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_service_set_characteristics(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *service_handle;
  err = js_get_value_external(env, argv[0], &service_handle);
  assert(err == 0);

  @autoreleasepool {
    CBMutableService *service = (__bridge CBMutableService *) service_handle;

    uint32_t len;
    err = js_get_array_length(env, argv[1], &len);
    assert(err == 0);

    NSMutableArray<CBMutableCharacteristic *> *characteristics = [NSMutableArray arrayWithCapacity:len];

    for (uint32_t i = 0; i < len; i++) {
      js_value_t *element;
      err = js_get_element(env, argv[1], i, &element);
      assert(err == 0);

      void *char_handle;
      err = js_get_value_external(env, element, &char_handle);
      assert(err == 0);

      [characteristics addObject:(__bridge CBMutableCharacteristic *) char_handle];
    }

    service.characteristics = characteristics;
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_server_add_service(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *service_handle;
  err = js_get_value_external(env, argv[1], &service_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;
    CBMutableService *service = (__bridge CBMutableService *) service_handle;

    [server->manager addService:service];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_server_start_advertising(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 3;
  js_value_t *argv[3];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 3);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;

    NSMutableDictionary *advertisementData = [NSMutableDictionary dictionary];

    bool name_null;
    err = js_is_null(env, argv[1], &name_null);
    assert(err == 0);

    if (!name_null) {
      size_t name_len;
      err = js_get_value_string_utf8(env, argv[1], NULL, 0, &name_len);
      assert(err == 0);

      char *name_str = static_cast<char *>(malloc(name_len + 1));
      err = js_get_value_string_utf8(env, argv[1], (utf8_t *) name_str, name_len + 1, NULL);
      assert(err == 0);

      advertisementData[CBAdvertisementDataLocalNameKey] = [NSString stringWithUTF8String:name_str];

      free(name_str);
    }

    bool uuids_null;
    err = js_is_null(env, argv[2], &uuids_null);
    assert(err == 0);

    if (!uuids_null) {
      uint32_t len;
      err = js_get_array_length(env, argv[2], &len);
      assert(err == 0);

      NSMutableArray<CBUUID *> *serviceUUIDs = [NSMutableArray arrayWithCapacity:len];

      for (uint32_t i = 0; i < len; i++) {
        js_value_t *element;
        err = js_get_element(env, argv[2], i, &element);
        assert(err == 0);

        void *uuid_handle;
        err = js_get_value_external(env, element, &uuid_handle);
        assert(err == 0);

        [serviceUUIDs addObject:(__bridge CBUUID *) uuid_handle];
      }

      advertisementData[CBAdvertisementDataServiceUUIDsKey] = serviceUUIDs;
    }

    [server->manager startAdvertising:advertisementData];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_server_stop_advertising(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;

    [server->manager stopAdvertising];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_request_characteristic_uuid(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBATTRequest *request = (__bridge CBATTRequest *) handle;

    err = js_create_string_utf8(env, (const utf8_t *) request.characteristic.UUID.UUIDString.UTF8String, -1, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_request_offset(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBATTRequest *request = (__bridge CBATTRequest *) handle;

    err = js_create_int32(env, (int32_t) request.offset, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_request_data(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    CBATTRequest *request = (__bridge CBATTRequest *) handle;
    NSData *value = request.value;

    if (value && value.length > 0) {
      void *buf;
      js_value_t *arraybuffer;
      err = js_create_arraybuffer(env, value.length, &buf, &arraybuffer);
      assert(err == 0);

      memcpy(buf, value.bytes, value.length);

      err = js_create_typedarray(env, js_uint8array, value.length, arraybuffer, 0, &result);
      assert(err == 0);
    } else {
      err = js_get_null(env, &result);
      assert(err == 0);
    }
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_server_respond_to_request(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 4;
  js_value_t *argv[4];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 4);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *request_handle;
  err = js_get_value_external(env, argv[1], &request_handle);
  assert(err == 0);

  int32_t result_code;
  err = js_get_value_int32(env, argv[2], &result_code);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;
    CBATTRequest *request = (__bridge CBATTRequest *) request_handle;

    bool data_null;
    err = js_is_null(env, argv[3], &data_null);
    assert(err == 0);

    if (!data_null) {
      uint8_t *data;
      size_t data_len;
      err = js_get_typedarray_info(env, argv[3], NULL, (void **) &data, &data_len, NULL, NULL);
      assert(err == 0);

      request.value = [NSData dataWithBytes:data length:data_len];
    }

    [server->manager respondToRequest:request withResult:(CBATTError) result_code];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_server_update_value(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 3;
  js_value_t *argv[3];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 3);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  void *char_handle;
  err = js_get_value_external(env, argv[1], &char_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;
    CBMutableCharacteristic *characteristic = (__bridge CBMutableCharacteristic *) char_handle;

    uint8_t *data;
    size_t data_len;
    err = js_get_typedarray_info(env, argv[2], NULL, (void **) &data, &data_len, NULL, NULL);
    assert(err == 0);

    NSData *nsdata = [NSData dataWithBytes:data length:data_len];

    BOOL success = [server->manager updateValue:nsdata forCharacteristic:characteristic onSubscribedCentrals:nil];

    js_value_t *result;
    err = js_get_boolean(env, success, &result);
    assert(err == 0);

    return result;
  }
}

static js_value_t *
bare_bluetooth_apple_server_publish_channel(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  bool encrypted;
  err = js_get_value_bool(env, argv[1], &encrypted);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;

    [server->manager publishL2CAPChannelWithEncryption:encrypted];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_server_unpublish_channel(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  uint32_t psm;
  err = js_get_value_uint32(env, argv[1], &psm);
  assert(err == 0);
  assert(psm <= UINT16_MAX);

  @autoreleasepool {
    BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;

    [server->manager unpublishL2CAPChannel:(CBL2CAPPSM) psm];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_server_destroy(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  BareBluetoothAppleServer *server = (__bridge BareBluetoothAppleServer *) handle;

  [server->manager stopAdvertising];
  [server->manager removeAllServices];
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

  return NULL;
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
  bare_bluetooth_apple_central_state_change_t *event = static_cast<bare_bluetooth_apple_central_state_change_t *>(malloc(sizeof(bare_bluetooth_apple_central_state_change_t)));
  if (!event) abort();
  event->state = (int32_t) central.state;

  js_call_threadsafe_function(tsfn_state_change, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                   RSSI:(NSNumber *)RSSI {
  bare_bluetooth_apple_central_discover_t *event = static_cast<bare_bluetooth_apple_central_discover_t *>(malloc(sizeof(bare_bluetooth_apple_central_discover_t)));
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
  bare_bluetooth_apple_central_connect_t *event = static_cast<bare_bluetooth_apple_central_connect_t *>(malloc(sizeof(bare_bluetooth_apple_central_connect_t)));
  if (!event) abort();

  event->peripheral = CFBridgingRetain(peripheral);
  event->id = strdup(peripheral.identifier.UUIDString.UTF8String);

  js_call_threadsafe_function(tsfn_connect, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didDisconnectPeripheral:(CBPeripheral *)peripheral
                    error:(NSError *)error {
  bare_bluetooth_apple_central_disconnect_t *event = static_cast<bare_bluetooth_apple_central_disconnect_t *>(malloc(sizeof(bare_bluetooth_apple_central_disconnect_t)));
  if (!event) abort();

  event->id = strdup(peripheral.identifier.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : NULL;

  js_call_threadsafe_function(tsfn_disconnect, event, js_threadsafe_function_nonblocking);
}

- (void)centralManager:(CBCentralManager *)central
  didFailToConnectPeripheral:(CBPeripheral *)peripheral
                       error:(NSError *)error {
  bare_bluetooth_apple_central_connect_fail_t *event = static_cast<bare_bluetooth_apple_central_connect_fail_t *>(malloc(sizeof(bare_bluetooth_apple_central_connect_fail_t)));
  if (!event) abort();

  event->id = strdup(peripheral.identifier.UUIDString.UTF8String);
  event->error = error ? strdup(error.localizedDescription.UTF8String) : strdup("Unknown connection failure");

  js_call_threadsafe_function(tsfn_connect_fail, event, js_threadsafe_function_nonblocking);
}

@end

static void
bare_bluetooth_apple_central__on_state_change(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_central_state_change_t *event = (bare_bluetooth_apple_central_state_change_t *) data;
  BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[1];
  err = js_create_int32(env, event->state, &argv[0]);
  assert(err == 0);

  free(event);

  js_call_function(env, receiver, function, 1, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_discover(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_central_discover_t *event = (bare_bluetooth_apple_central_discover_t *) data;
  BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) context;

  if (!central->manager.isScanning) return;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[4];

  err = js_create_external(env, (void *) event->peripheral, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->id, -1, &argv[1]);
  assert(err == 0);

  if (event->name) {
    err = js_create_string_utf8(env, (const utf8_t *) event->name, -1, &argv[2]);
    assert(err == 0);
  } else {
    err = js_get_null(env, &argv[2]);
    assert(err == 0);
  }

  err = js_create_int32(env, event->rssi, &argv[3]);
  assert(err == 0);

  free(event->id);
  if (event->name) free(event->name);
  free(event);

  js_call_function(env, receiver, function, 4, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_connect(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_central_connect_t *event = (bare_bluetooth_apple_central_connect_t *) data;
  BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_external(env, (void *) event->peripheral, bare_bluetooth_apple__on_bridged_release, NULL, &argv[0]);
  assert(err == 0);

  err = js_create_string_utf8(env, (const utf8_t *) event->id, -1, &argv[1]);
  assert(err == 0);

  free(event->id);
  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_disconnect(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_central_disconnect_t *event = (bare_bluetooth_apple_central_disconnect_t *) data;
  BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_string_utf8(env, (const utf8_t *) event->id, -1, &argv[0]);
  assert(err == 0);

  free(event->id);

  if (event->error) {
    err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[1]);
    assert(err == 0);
    free(event->error);
  } else {
    err = js_get_null(env, &argv[1]);
    assert(err == 0);
  }

  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_central__on_connect_fail(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_central_connect_fail_t *event = (bare_bluetooth_apple_central_connect_fail_t *) data;
  BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, central->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[2];

  err = js_create_string_utf8(env, (const utf8_t *) event->id, -1, &argv[0]);
  assert(err == 0);

  free(event->id);

  err = js_create_string_utf8(env, (const utf8_t *) event->error, -1, &argv[1]);
  assert(err == 0);

  free(event->error);
  free(event);

  js_call_function(env, receiver, function, 2, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_value_t *
bare_bluetooth_apple_central_init(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 6;
  js_value_t *argv[6];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 6);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothAppleCentral *handle = [[BareBluetoothAppleCentral alloc] init];

    handle->env = env;

    err = js_create_reference(env, argv[0], 1, &handle->ctx);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[1], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_central__on_state_change, &handle->tsfn_state_change);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[2], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_central__on_discover, &handle->tsfn_discover);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[3], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_central__on_connect, &handle->tsfn_connect);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[4], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_central__on_disconnect, &handle->tsfn_disconnect);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[5], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_central__on_connect_fail, &handle->tsfn_connect_fail);
    assert(err == 0);

    handle->queue = dispatch_queue_create("bare.bluetooth.central", DISPATCH_QUEUE_SERIAL);
    handle->manager = [[CBCentralManager alloc] initWithDelegate:handle queue:handle->queue];

    err = js_create_external(env, (void *) CFBridgingRetain(handle), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_central_start_scan(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1 || argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) handle;

    NSArray<CBUUID *> *serviceUUIDs = nil;

    if (argc == 2) {
      bool is_null;
      err = js_is_null(env, argv[1], &is_null);
      assert(err == 0);

      if (!is_null) {
        uint32_t len;
        err = js_get_array_length(env, argv[1], &len);
        assert(err == 0);

        NSMutableArray<CBUUID *> *uuids = [NSMutableArray arrayWithCapacity:len];

        for (uint32_t i = 0; i < len; i++) {
          js_value_t *element;
          err = js_get_element(env, argv[1], i, &element);
          assert(err == 0);

          void *uuid_handle;
          err = js_get_value_external(env, element, &uuid_handle);
          assert(err == 0);

          [uuids addObject:(__bridge CBUUID *) uuid_handle];
        }

        serviceUUIDs = uuids;
      }
    }

    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey : @NO};

    [central->manager scanForPeripheralsWithServices:serviceUUIDs options:options];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_central_stop_scan(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) handle;

    [central->manager stopScan];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_central_connect(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *central_handle;
  err = js_get_value_external(env, argv[0], &central_handle);
  assert(err == 0);

  void *peripheral_handle;
  err = js_get_value_external(env, argv[1], &peripheral_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) central_handle;
    CBPeripheral *peripheral = (__bridge CBPeripheral *) peripheral_handle;

    [central->manager connectPeripheral:peripheral options:nil];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_central_disconnect(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *central_handle;
  err = js_get_value_external(env, argv[0], &central_handle);
  assert(err == 0);

  void *peripheral_handle;
  err = js_get_value_external(env, argv[1], &peripheral_handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) central_handle;
    CBPeripheral *peripheral = (__bridge CBPeripheral *) peripheral_handle;

    [central->manager cancelPeripheralConnection:peripheral];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_central_destroy(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  BareBluetoothAppleCentral *central = (__bridge BareBluetoothAppleCentral *) handle;

  [central->manager stopScan];
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

  return NULL;
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
      if ((NSUInteger) written < data.length) {
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

    size_t capacity = 4096;
    size_t total = 0;
    uint8_t *buf = static_cast<uint8_t *>(malloc(capacity));
    if (!buf) abort();

    do {
      if (total == capacity) {
        capacity *= 2;
        buf = static_cast<uint8_t *>(realloc(buf, capacity));
        if (!buf) abort();
      }

      NSInteger bytesRead = [inputStream read:buf + total maxLength:capacity - total];

      if (bytesRead <= 0) break;

      total += (size_t) bytesRead;
    } while (inputStream.hasBytesAvailable);

    if (total > 0) {
      bare_bluetooth_apple_l2cap_data_t *event = static_cast<bare_bluetooth_apple_l2cap_data_t *>(malloc(sizeof(bare_bluetooth_apple_l2cap_data_t)));
      if (!event) abort();
      event->len = total;
      event->bytes = buf;

      js_call_threadsafe_function(tsfn_data, event, js_threadsafe_function_nonblocking);
    } else {
      free(buf);
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

    bare_bluetooth_apple_l2cap_error_t *event = static_cast<bare_bluetooth_apple_l2cap_error_t *>(malloc(sizeof(bare_bluetooth_apple_l2cap_error_t)));
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

static void
bare_bluetooth_apple_l2cap__on_data(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_l2cap_data_t *event = (bare_bluetooth_apple_l2cap_data_t *) data;
  BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, l2cap->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[1];

  void *buf;
  js_value_t *arraybuffer;
  err = js_create_arraybuffer(env, event->len, &buf, &arraybuffer);
  assert(err == 0);

  memcpy(buf, event->bytes, event->len);

  err = js_create_typedarray(env, js_uint8array, event->len, arraybuffer, 0, &argv[0]);
  assert(err == 0);

  free(event->bytes);
  free(event);

  js_call_function(env, receiver, function, 1, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_drain(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, l2cap->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, receiver, function, 0, NULL, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_end(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, l2cap->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, receiver, function, 0, NULL, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_error(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  bare_bluetooth_apple_l2cap_error_t *event = (bare_bluetooth_apple_l2cap_error_t *) data;
  BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, l2cap->ctx, &receiver);
  assert(err == 0);

  js_value_t *argv[1];
  err = js_create_string_utf8(env, (const utf8_t *) event->message, -1, &argv[0]);
  assert(err == 0);

  free(event->message);
  free(event);

  js_call_function(env, receiver, function, 1, argv, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_close(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, l2cap->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, receiver, function, 0, NULL, NULL);

  if (!l2cap->finalized.exchange(true)) {
    err = js_delete_reference(env, l2cap->ctx);
    assert(err == 0);

    err = js_release_threadsafe_function(l2cap->tsfn_open, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(l2cap->tsfn_close, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(l2cap->tsfn_error, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(l2cap->tsfn_end, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(l2cap->tsfn_drain, js_threadsafe_function_release);
    assert(err == 0);

    err = js_release_threadsafe_function(l2cap->tsfn_data, js_threadsafe_function_release);
    assert(err == 0);
  }

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static void
bare_bluetooth_apple_l2cap__on_open(js_env_t *env, js_value_t *function, void *context, void *data) {
  int err;

  BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) context;

  js_handle_scope_t *scope;
  err = js_open_handle_scope(env, &scope);
  assert(err == 0);

  js_value_t *receiver;
  err = js_get_reference_value(env, l2cap->ctx, &receiver);
  assert(err == 0);

  js_call_function(env, receiver, function, 0, NULL, NULL);

  err = js_close_handle_scope(env, scope);
  assert(err == 0);
}

static js_value_t *
bare_bluetooth_apple_l2cap_init(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 8;
  js_value_t *argv[8];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 8);

  void *channel_handle;
  err = js_get_value_external(env, argv[0], &channel_handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *handle = [[BareBluetoothAppleL2CAPChannel alloc] init];

    handle->env = env;
    handle->channel = (__bridge CBL2CAPChannel *) channel_handle;
    handle->opened.store(false);
    handle->closing.store(false);
    handle->closed.store(false);
    handle->destroyed.store(false);
    handle->finalized.store(false);

    err = js_create_reference(env, argv[1], 1, &handle->ctx);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[2], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_l2cap__on_data, &handle->tsfn_data);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[3], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_l2cap__on_drain, &handle->tsfn_drain);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[4], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_l2cap__on_end, &handle->tsfn_end);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[5], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_l2cap__on_error, &handle->tsfn_error);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[6], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_l2cap__on_close, &handle->tsfn_close);
    assert(err == 0);

    err = js_create_threadsafe_function(env, argv[7], 0, 1, bare_bluetooth_apple__on_bridged_release, NULL, (void *) CFBridgingRetain(handle), bare_bluetooth_apple_l2cap__on_open, &handle->tsfn_open);
    assert(err == 0);

    err = js_create_external(env, (void *) CFBridgingRetain(handle), bare_bluetooth_apple__on_bridged_release, NULL, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_l2cap_open(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) handle;

    [l2cap open];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_l2cap_write(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 2;
  js_value_t *argv[2];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 2);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  uint8_t *data;
  size_t data_len;
  err = js_get_typedarray_info(env, argv[1], NULL, (void **) &data, &data_len, NULL, NULL);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) handle;

    if (atomic_load(&l2cap->destroyed) || !atomic_load(&l2cap->opened)) {
      js_value_t *result;
      err = js_create_int32(env, 0, &result);
      assert(err == 0);
      return result;
    }

    NSData *nsdata = [NSData dataWithBytes:data length:data_len];
    [l2cap performSelector:@selector(enqueueWrite:) onThread:l2cap->streamThread withObject:nsdata waitUntilDone:NO];

    js_value_t *result;
    err = js_create_int32(env, (int32_t) data_len, &result);
    assert(err == 0);

    return result;
  }
}

static js_value_t *
bare_bluetooth_apple_l2cap_end(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) handle;

    [l2cap destroy];
  }

  return NULL;
}

static js_value_t *
bare_bluetooth_apple_l2cap_psm(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) handle;

    err = js_create_uint32(env, (uint32_t) l2cap->channel.PSM, &result);
    assert(err == 0);
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_l2cap_peer(js_env_t *env, js_callback_info_t *info) {
  int err;

  size_t argc = 1;
  js_value_t *argv[1];

  err = js_get_callback_info(env, info, &argc, argv, NULL, NULL);
  assert(err == 0);

  assert(argc == 1);

  void *handle;
  err = js_get_value_external(env, argv[0], &handle);
  assert(err == 0);

  js_value_t *result;

  @autoreleasepool {
    BareBluetoothAppleL2CAPChannel *l2cap = (__bridge BareBluetoothAppleL2CAPChannel *) handle;
    CBPeer *peer = l2cap->channel.peer;

    if (peer) {
      NSString *uuid = peer.identifier.UUIDString;
      err = js_create_string_utf8(env, (const utf8_t *) uuid.UTF8String, -1, &result);
      assert(err == 0);
    } else {
      err = js_get_null(env, &result);
      assert(err == 0);
    }
  }

  return result;
}

static js_value_t *
bare_bluetooth_apple_exports(js_env_t *env, js_value_t *exports) {
  int err;

#define V(name, fn) \
  { \
    js_value_t *val; \
    err = js_create_function(env, name, -1, fn, NULL, &val); \
    assert(err == 0); \
    err = js_set_named_property(env, exports, name, val); \
    assert(err == 0); \
  }

  V("centralInit", bare_bluetooth_apple_central_init)
  V("centralStartScan", bare_bluetooth_apple_central_start_scan)
  V("centralStopScan", bare_bluetooth_apple_central_stop_scan)
  V("centralConnect", bare_bluetooth_apple_central_connect)
  V("centralDisconnect", bare_bluetooth_apple_central_disconnect)
  V("centralDestroy", bare_bluetooth_apple_central_destroy)

  V("peripheralInit", bare_bluetooth_apple_peripheral_init)
  V("peripheralId", bare_bluetooth_apple_peripheral_id)
  V("peripheralName", bare_bluetooth_apple_peripheral_name)
  V("peripheralDiscoverServices", bare_bluetooth_apple_peripheral_discover_services)
  V("peripheralDiscoverCharacteristics", bare_bluetooth_apple_peripheral_discover_characteristics)
  V("peripheralRead", bare_bluetooth_apple_peripheral_read)
  V("peripheralWrite", bare_bluetooth_apple_peripheral_write)
  V("peripheralSubscribe", bare_bluetooth_apple_peripheral_subscribe)
  V("peripheralUnsubscribe", bare_bluetooth_apple_peripheral_unsubscribe)
  V("peripheralDestroy", bare_bluetooth_apple_peripheral_destroy)
  V("peripheralOpenL2CAPChannel", bare_bluetooth_apple_peripheral_open_l2cap_channel)

  V("peripheralServiceCount", bare_bluetooth_apple_peripheral_service_count)
  V("peripheralServiceAtIndex", bare_bluetooth_apple_peripheral_service_at_index)
  V("serviceKey", bare_bluetooth_apple_service_key)
  V("serviceUuid", bare_bluetooth_apple_service_uuid)
  V("serviceCharacteristicCount", bare_bluetooth_apple_service_characteristic_count)
  V("serviceCharacteristicAtIndex", bare_bluetooth_apple_service_characteristic_at_index)
  V("characteristicKey", bare_bluetooth_apple_characteristic_key)
  V("characteristicUuid", bare_bluetooth_apple_characteristic_uuid)
  V("characteristicProperties", bare_bluetooth_apple_characteristic_properties)

  V("createMutableCharacteristic", bare_bluetooth_apple_create_mutable_characteristic)
  V("createMutableService", bare_bluetooth_apple_create_mutable_service)
  V("serviceSetCharacteristics", bare_bluetooth_apple_service_set_characteristics)

  V("serverInit", bare_bluetooth_apple_server_init)
  V("serverAddService", bare_bluetooth_apple_server_add_service)
  V("serverStartAdvertising", bare_bluetooth_apple_server_start_advertising)
  V("serverStopAdvertising", bare_bluetooth_apple_server_stop_advertising)
  V("requestCharacteristicUuid", bare_bluetooth_apple_request_characteristic_uuid)
  V("requestOffset", bare_bluetooth_apple_request_offset)
  V("requestData", bare_bluetooth_apple_request_data)
  V("serverRespondToRequest", bare_bluetooth_apple_server_respond_to_request)
  V("serverUpdateValue", bare_bluetooth_apple_server_update_value)
  V("serverDestroy", bare_bluetooth_apple_server_destroy)
  V("serverPublishChannel", bare_bluetooth_apple_server_publish_channel)
  V("serverUnpublishChannel", bare_bluetooth_apple_server_unpublish_channel)

  V("l2capInit", bare_bluetooth_apple_l2cap_init)
  V("l2capOpen", bare_bluetooth_apple_l2cap_open)
  V("l2capWrite", bare_bluetooth_apple_l2cap_write)
  V("l2capEnd", bare_bluetooth_apple_l2cap_end)
  V("l2capPsm", bare_bluetooth_apple_l2cap_psm)
  V("l2capPeer", bare_bluetooth_apple_l2cap_peer)

#undef V

  err = js_set_property<bare_bluetooth_apple_create_cbuuid>(env, exports, "createCBUUID");
  assert(err == 0);

  /* #define V(name, fn) \ */
  /*   err = js_set_property<fn>(env, exports, name); \ */
  /*   assert(err == 0); */
  /**/
  /*   V("createCBUUID", bare_bluetooth_apple_create_cbuuid) */
  /**/
  /* #undef V */

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
