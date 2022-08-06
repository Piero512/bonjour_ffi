import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:async/async.dart';
import 'package:bonjour_ffi/bonjour_ffi.dart';

String getDynamicLibrarySuffix() {
  if (Platform.isWindows) {
    return "ffi_test.dll";
  } else if (Platform.isMacOS) {
    return 'libffi_test.dylib';
  } else {
    return 'libffi_test.so';
  }
}

StreamQueue queueInput() {
  return StreamQueue(stdin);
}

Future<void> main() async {
  // You should change the place where the library is being loaded.
  final dl = DynamicLibrary.open('build/' + getDynamicLibrarySuffix());
  // Initialize the dynamically linked Dart API. This is very important as otherwise, the library will jump to null.
  final bindings = BonjourAdapterBindings(dl);
  bindings.initializeDartAPIDL(NativeApi.initializeApiDLData);
  // Initialize the bindings through the library.
  final adapter = BonjourBinding(bindings);
  final encoder = JsonEncoder.withIndent("  ");
  // Listen to adapter.searchForService to get updates on the services on the network.
  final sub = adapter
      .searchForService('_rfb._tcp')
      .listen((event) => print(encoder.convert(event)));
  print("Subscribed to search for service");
  // Listen to this Stream until you don't want to announce the service.
  final sub2 = adapter.startBroadcast(
      'Bonjour Test service',
      '_custom_service._tcp',
      8081,
      ['txt']).listen((event) => print(encoder.convert(event)));
  print("Subscribed to start broadcast");
  final inputQueue = queueInput();
  print("Press enter to exit");
  await inputQueue.next;
  print("Exiting...");
  inputQueue.cancel();
  await sub.cancel();
  await sub2.cancel();
  // Useful for cleaning the worker thread used to poll through libuv, use sparingly.
  adapter.destroy();
  print("Ended");
}
