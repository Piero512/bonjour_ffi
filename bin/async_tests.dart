import 'dart:ffi';
import 'dart:io';
import 'package:bonjour_ffi/bonjour_ffi.dart';
import 'dart:convert';

String getDynamicLibraryPath() {
  if (Platform.isWindows) {
    return "build/Debug/bonjour_ffi.dll";
  } else if (Platform.isMacOS) {
    return 'build/bonjour_ffi.dylib';
  } else {
    return 'build/libbonjour_ffi.so';
  }
}

Future<void> main(List<String> args) async {
  // You should change the place where the library is being loaded.
  final dl = DynamicLibrary.open(getDynamicLibraryPath());
  // Initialize the dynamically linked Dart API. This is very important as otherwise, the library will jump to null.
  final bindings = BonjourAdapterBindings(dl);
  bindings.initializeDartAPIDL(NativeApi.initializeApiDLData);
  final encoder = JsonEncoder();
  // Initialize the bindings through the library.
  final adapter = BonjourBinding(bindings);
  // Listen to adapter.searchForService to get updates on the services on the network.
  final sub = adapter.searchForService('_custom_service._tcp').listen(
        (event) => print("Search service: ${encoder.convert(event)}"),
      );
  print("Subscribed to search for service");
  // Listen to this Stream until you don't want to announce the service.
  final sub2 = adapter.startBroadcast(
    'Bonjour Test service',
    '_custom_service._tcp',
    8081,
    ['first_record=1234', 'second_record=4321'],
  ).listen(
    (event) => print("Broadcast event: ${encoder.convert(event)}"),
  );
  print("Subscribed to start broadcast");
  await Future.delayed(Duration(seconds: 5));
  // Don't forget to unsubscribe, or your isolate will never finish, as the library uses [ReceivePort] internally.
  sub.cancel();
  sub2.cancel();
  // Useful for cleaning the worker thread used to poll through libuv, use sparingly.
  adapter.destroy();
  print("Ended");
}
