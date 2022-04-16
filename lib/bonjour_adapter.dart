import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:mdns_responder_ffi/bonjour_events.dart';
import 'ffi/bonjour_bindings.dart' as ffi;

class BonjourAdapter {
  final ffi.BonjourAdapterBindings bindings;
  final Pointer<ffi.BonjourAdapter> adapter;

  BonjourAdapter(this.bindings) : adapter = bindings.get_new_instance();

  Stream<BonjourBroadcastEvent> startBroadcast(
      String serviceName, String serviceType, int port, String txt) {
    final receivePort = ReceivePort();
    final controller = StreamController<BonjourBroadcastEvent>();
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


}
