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

StreamQueue queueInput(){
  return StreamQueue(stdin);
}

Future<void> main() async {
  // You should change the place where the library is being loaded.
  final dl = DynamicLibrary.open('cmake-build-debug/'+ getDynamicLibrarySuffix());
  final bindings = BonjourAdapterBindings(dl);
  bindings.initializeDartAPIDL(NativeApi.initializeApiDLData);
  final adapter = BonjourBinding(bindings);
  final encoder = JsonEncoder.withIndent("  ");
  final sub = adapter.searchForService('_rfb._tcp').listen((event) => print(encoder.convert(event)));
  print("Subscribed to search for service");
  final sub2 = adapter.startBroadcast('Bonjour Test service', '_custom_service._tcp', 8081, 'txt').listen((event) => print(encoder.convert(event)));
  print("Subscribed to start broadcast");
  final inputQueue = queueInput();
  print("Press enter to exit");
  await inputQueue.next;
  print("Exiting...");
  inputQueue.cancel();
  await sub.cancel();
  await sub2.cancel();
  adapter.destroy();
  print("Ended");
}
