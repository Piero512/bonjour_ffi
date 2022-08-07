import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'bonjour_events.dart';
import 'ffi/bonjour_bindings.dart' as ffi;

class BonjourBinding {
  final ffi.BonjourAdapterBindings bindings;
  Pointer<ffi.BonjourNativeBinding> adapter;

  BonjourBinding(this.bindings) : adapter = bindings.get_new_instance();

  Uint8List _encodeTxtRecords(List<String> records) {
    final builder = BytesBuilder(copy: false);
    for (final record in records) {
      final encoded = utf8.encode(record);
      final encodedLength = encoded.length;
      assert(encodedLength < 255, "TXT record can't be larger than 255 bytes");
      builder.addByte(encodedLength);
      builder.add(encoded);
    }
    return builder.takeBytes();
  }

  Stream<BonjourBroadcastEvent> startBroadcast(
      String serviceName, String serviceType, int port,
      [List<String> txtRecords = const []]) {
    final receivePort = ReceivePort('Broadcast $serviceName');
    final controller = StreamController<BonjourBroadcastEvent>(sync: true);
    final context = using((Arena arena) {
      final svcName = serviceName.toNativeUtf8(allocator: arena).cast<Char>();
      final svcType = serviceType.toNativeUtf8(allocator: arena).cast<Char>();
      final encodedTxtRecords = _encodeTxtRecords(txtRecords);
      final encodedSize = encodedTxtRecords.lengthInBytes;
      final encodedTxtPtr = arena.call<Uint8>(encodedTxtRecords.lengthInBytes);
      encodedTxtPtr
          .asTypedList(encodedTxtRecords.lengthInBytes)
          .setRange(0, encodedSize, encodedTxtRecords);
      final errPtr = arena.call<Pointer<Char>>();
      final ctx = bindings.broadcast_service(
        adapter,
        svcName,
        svcType,
        port,
        encodedTxtPtr.cast(),
        encodedTxtRecords.lengthInBytes,
        receivePort.sendPort.nativePort,
        errPtr,
      );
      if (ctx == nullptr) {
        throw Exception(
          "Error from the native side: ${errPtr.value.cast<Utf8>().toDartString()}",
        );
      } else {
        return ctx;
      }
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
      final svcType = serviceType.toNativeUtf8(allocator: arena).cast<Char>();
      final errPtr = arena.call<Pointer<Char>>();
      final ctx = bindings.search_for_service(
          adapter, svcType, receivePort.sendPort.nativePort, errPtr);
      if (ctx != nullptr) {
        return ctx;
      } else {
        throw Exception(
          "Error from the native side: ${errPtr.value.cast<Utf8>().toDartString()}",
        );
      }
    });
    controller.onCancel = () {
      bindings.stop_search(adapter, context);
      receivePort.close();
    };
    receivePort.map((event) {
      var decoded = json.decode(event as String);
      return BonjourSearchEvent.fromJson(decoded);
    }).pipe(controller);
    return controller.stream;
  }

  void destroy() {
    bindings.delete_instance(adapter);
    adapter = nullptr;
  }
}
