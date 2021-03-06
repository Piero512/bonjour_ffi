import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';

typedef CInitializeDLAPI = Int64 Function(Pointer<Void>);
typedef DartInitializeDLAPI = int Function(Pointer<Void>);

typedef GetNewInstance = Pointer<Void> Function();
typedef DeleteInstance = Void Function(Pointer<Void>);
typedef DartDeleteInstance = void Function(Pointer<Void>);
typedef BroadcastService = Pointer<Void> Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Int64, Pointer<Utf8>, Int64);
typedef DartBroadcastService = Pointer<Void> Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>, int);

typedef SearchForService = Pointer<Void> Function(
    Pointer<Void>, Pointer<Utf8>, Int64);
typedef DartSearchForService = Pointer<Void> Function(
    Pointer<Void>, Pointer<Utf8>, int);

class FFITest {
  late final initializeDLAPI =
  library.lookupFunction<CInitializeDLAPI, DartInitializeDLAPI>(
      'initializeDartAPIDL');

  late final _getNewInstance = library
      .lookupFunction<GetNewInstance, GetNewInstance>('get_new_instance');

  late final _deleteInstance = library
      .lookupFunction<DeleteInstance, DartDeleteInstance>('delete_instance');

  late final _broadcastService =
  library.lookupFunction<BroadcastService, DartBroadcastService>(
      'broadcast_service');

  late final _stopBroadcast = library.lookupFunction<
      Void Function(Pointer<Void>, Pointer<Void>),
      void Function(Pointer<Void>, Pointer<Void>)>('stop_broadcast');

  late final _searchForService =
  library.lookupFunction<SearchForService, DartSearchForService>(
      'search_for_service');

  late final _stopSearch = library.lookupFunction<
      Void Function(Pointer<Void>, Pointer<Void>),
      void Function(Pointer<Void>, Pointer<Void>)>('stop_search');

  Pointer<Void> getNewInstance() {
    return _getNewInstance();
  }

  final DynamicLibrary library;

  FFITest(this.library);

  void deleteInstance(Pointer<Void> instance) {
    return _deleteInstance(instance);
  }

  Pointer<Void> broadcastService(Pointer<Void> adapter, String serviceName,
      String serviceType, int port, String txt, int sendport) {
    return using((Arena arena) {
      final svcname = serviceName.toNativeUtf8(allocator: arena);
      final svctype = serviceType.toNativeUtf8(allocator: arena);
      final txtPtr = txt.toNativeUtf8(allocator: arena);
      return _broadcastService(
          adapter, svcname, svctype, port, txtPtr, sendport);
    });
  }

  Future<void> stopBroadcast(Pointer<Void> dnsAdapter, Pointer<Void> context) {
    return Future.delayed(Duration.zero, () {
      _stopBroadcast(dnsAdapter, context);
    });
  }

  Pointer<Void> searchForService(Pointer<Void> dnsAdapter, String serviceType,
      int sendport) {
    return using((Arena arena) {
      final svcType = serviceType.toNativeUtf8(allocator: arena);
      return _searchForService(dnsAdapter, svcType, sendport);
    });
  }

  void stopSearch(Pointer<Void> dnsAdapter, Pointer<Void> context) {
    return _stopSearch(dnsAdapter, context);
  }
}

String getDynamicLibraryPath() {
  if (Platform.isWindows) {
    return "cmake-build-debug/bonjour_ffi.dll";
  } else if (Platform.isMacOS) {
    return 'cmake-build-debug/bonjour_ffi.dylib';
  } else {
    return 'build/libbonjour_ffi.so';
  }
}

Future<void> main(List<String> args) async {
  final test = FFITest(DynamicLibrary.open(getDynamicLibraryPath()));
  final output = test.initializeDLAPI(NativeApi.initializeApiDLData);
  print('Output of native initialization: $output');
  final dnssdapi = test.getNewInstance();
  final rp = ReceivePort('');
  final sub = rp.listen(print);
  final broadcastContext = test.broadcastService(dnssdapi, "AsyncTests",
      '_custom_type._tcp', 3000, "", rp.sendPort.nativePort);
  final linequeue = StreamQueue(
      stdin.transform(utf8.decoder).transform(const LineSplitter()));
  print("Broadcast started! Press enter to stop it.");
  await linequeue.next;
  await test.stopBroadcast(dnssdapi, broadcastContext);
  final resolveContext = test.searchForService(
      dnssdapi, "_rfb._tcp.", rp.sendPort.nativePort);
  print("Resolve context started! Press enter to stop it.");
  await linequeue.next;
  test.stopSearch(dnssdapi, resolveContext);
  linequeue.cancel();
  test.deleteInstance(dnssdapi);
  await sub.cancel();
  print("Initialized and finalized!");
}
