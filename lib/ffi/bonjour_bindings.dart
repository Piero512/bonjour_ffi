// ignore_for_file: camel_case_types, non_constant_identifier_names
// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

/// Bindings to a C++ lightweight binding to dns_sd.h
class BonjourAdapterBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  BonjourAdapterBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  BonjourAdapterBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ffi.Pointer<BonjourNativeBinding> get_new_instance() {
    return _get_new_instance();
  }

  late final _get_new_instancePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<BonjourNativeBinding> Function()>>(
          'get_new_instance');
  late final _get_new_instance = _get_new_instancePtr
      .asFunction<ffi.Pointer<BonjourNativeBinding> Function()>();

  void delete_instance(
    ffi.Pointer<BonjourNativeBinding> instance,
  ) {
    return _delete_instance(
      instance,
    );
  }

  late final _delete_instancePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<BonjourNativeBinding>)>>('delete_instance');
  late final _delete_instance = _delete_instancePtr
      .asFunction<void Function(ffi.Pointer<BonjourNativeBinding>)>();

  int initializeDartAPIDL(
    ffi.Pointer<ffi.Void> data,
  ) {
    return _initializeDartAPIDL(
      data,
    );
  }

  late final _initializeDartAPIDLPtr =
      _lookup<ffi.NativeFunction<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>>(
          'initializeDartAPIDL');
  late final _initializeDartAPIDL =
      _initializeDartAPIDLPtr.asFunction<int Function(ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<ResolveContext> search_for_service(
    ffi.Pointer<BonjourNativeBinding> adapter,
    ffi.Pointer<ffi.Char> service_type,
    int port,
  ) {
    return _search_for_service(
      adapter,
      service_type,
      port,
    );
  }

  late final _search_for_servicePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ResolveContext> Function(
              ffi.Pointer<BonjourNativeBinding>,
              ffi.Pointer<ffi.Char>,
              Dart_Port_DL)>>('search_for_service');
  late final _search_for_service = _search_for_servicePtr.asFunction<
      ffi.Pointer<ResolveContext> Function(
          ffi.Pointer<BonjourNativeBinding>, ffi.Pointer<ffi.Char>, int)>();

  ffi.Pointer<BroadcastContext> broadcast_service(
    ffi.Pointer<BonjourNativeBinding> adapter,
    ffi.Pointer<ffi.Char> service_name,
    ffi.Pointer<ffi.Char> service_type,
    int port,
    ffi.Pointer<ffi.Char> txt,
    int txtLength,
    int sendport,
    ffi.Pointer<ffi.Pointer<ffi.Char>> err_code,
  ) {
    return _broadcast_service(
      adapter,
      service_name,
      service_type,
      port,
      txt,
      txtLength,
      sendport,
      err_code,
    );
  }

  late final _broadcast_servicePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<BroadcastContext> Function(
              ffi.Pointer<BonjourNativeBinding>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              Dart_Port_DL,
              ffi.Pointer<ffi.Pointer<ffi.Char>>)>>('broadcast_service');
  late final _broadcast_service = _broadcast_servicePtr.asFunction<
      ffi.Pointer<BroadcastContext> Function(
          ffi.Pointer<BonjourNativeBinding>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Char>>)>();

  void stop_broadcast(
    ffi.Pointer<BonjourNativeBinding> adapter,
    ffi.Pointer<BroadcastContext> ctx,
  ) {
    return _stop_broadcast(
      adapter,
      ctx,
    );
  }

  late final _stop_broadcastPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<BonjourNativeBinding>,
              ffi.Pointer<BroadcastContext>)>>('stop_broadcast');
  late final _stop_broadcast = _stop_broadcastPtr.asFunction<
      void Function(
          ffi.Pointer<BonjourNativeBinding>, ffi.Pointer<BroadcastContext>)>();

  void stop_search(
    ffi.Pointer<BonjourNativeBinding> adapter,
    ffi.Pointer<ResolveContext> ctx,
  ) {
    return _stop_search(
      adapter,
      ctx,
    );
  }

  late final _stop_searchPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<BonjourNativeBinding>,
              ffi.Pointer<ResolveContext>)>>('stop_search');
  late final _stop_search = _stop_searchPtr.asFunction<
      void Function(
          ffi.Pointer<BonjourNativeBinding>, ffi.Pointer<ResolveContext>)>();
}

class BonjourNativeBinding extends ffi.Opaque {}

class ServiceBrowseContext extends ffi.Opaque {}

class ServiceBroadcastContext extends ffi.Opaque {}

typedef ResolveContext = ServiceBrowseContext;
typedef Dart_Port_DL = ffi.Int64;
typedef BroadcastContext = ServiceBroadcastContext;
