import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'bonjour_events.dart';
import 'ffi/bonjour_bindings.dart' as ffi;

class BonjourBinding {
  final ffi.BonjourAdapterBindings bindings;
  Pointer<ffi.BonjourNativeBinding> adapter;

  BonjourBinding(this.bindings) : adapter = bindings.get_new_instance();

  Stream<BonjourBroadcastEvent> startBroadcast(
      String serviceName, String serviceType, int port, String txt) {
    final receivePort = ReceivePort('Broadcast $serviceName');
    final controller = StreamController<BonjourBroadcastEvent>(sync: true);
    final context = using((Arena arena) {
      final svcName = serviceName.toNativeUtf8(allocator: arena).cast<Int8>();
      final svcType = serviceType.toNativeUtf8(allocator: arena).cast<Int8>();
      final txtPtr = txt.toNativeUtf8(allocator: arena).cast<Int8>();
      return bindings.broadcast_service(adapter, svcName, svcType, port, txtPtr,
          receivePort.sendPort.nativePort);
    });
    controller.onCancel = () {
      bindings.stop_broadcast(adapter, context);
      receivePort.close();
    };
    receivePort
        .map((event) =>
            BonjourBroadcastEvent.fromJson(json.decode(event as String)))
        .pipe(controller);
    return controller.stream;
  }

  Stream<BonjourSearchEvent> searchForService(String serviceType) {
    final receivePort = ReceivePort('Browse $serviceType');
    final controller = StreamController<BonjourSearchEvent>(sync: true);
    final context = using((Arena arena) {
      final svcType = serviceType.toNativeUtf8(allocator: arena).cast<Int8>();
      return bindings.search_for_service(
          adapter, svcType, receivePort.sendPort.nativePort);
    });
    controller.onCancel = () {
      bindings.stop_search(adapter, context);
      receivePort.close();
    };
    receivePort
        .map((event) {
          var decoded = json.decode(event as String);
          return BonjourSearchEvent.fromJson(decoded);
        })
        .pipe(controller);
    return controller.stream;
  }

  void destroy(){
    bindings.delete_instance(adapter);
    adapter = nullptr;
  }
}
