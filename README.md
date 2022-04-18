### bonjour_ffi

This package is a Dart-only abstraction over the Bonjour system libraries 
that are generally present on macOS. It needs to be run with a companion C++ module
that wraps dns_sd requirement of listening to the sockets to the daemon by using libuv
in a safe and clean manner.

## Features

This package is able to search for services and to broadcast your own by using simple APIs

Make sure to close the subscriptions of the two high level functions. 

## Getting started

To develop a solution using this package you need to follow the next steps.

You need to:

* Make sure that the Bonjour libraries are available for linking (this is not needed in macOS provided you have Xcode installed.)
* Have an internet connection to download libuv.
* Build the companion C++ CMake project that this library binds to.
* Bundle the library on release, or compile it statically.



## Usage

The API for this package is very easy to use, as it only consists of two methods,
broadcast and search for service.

```dart
Future<void> main() async {
  // You should change the place where the library is being loaded.
  final dl = DynamicLibrary.open('build/'+ getDynamicLibrarySuffix());
  // Initialize the dynamically linked Dart API. This is very important as otherwise, the library will jump to null.
  final bindings = BonjourAdapterBindings(dl);
  bindings.initializeDartAPIDL(NativeApi.initializeApiDLData);
  // Initialize the bindings through the library.
  final adapter = BonjourBinding(bindings);
  // Listen to adapter.searchForService to get updates on the services on the network.
  final sub = adapter.searchForService('_rfb._tcp').listen((event) => print(encoder.convert(event)));
  print("Subscribed to search for service");
  // Listen to this Stream until you don't want to announce the service.
  final sub2 = adapter.startBroadcast('Bonjour Test service', '_custom_service._tcp', 8081, 'txt').listen((event) => print(encoder.convert(event)));
  print("Subscribed to start broadcast");
  await Future.delayed(Duration(seconds: 5));
  // Don't forget to unsubscribe, or your isolate will never finish, as the library uses [ReceivePort] internally. 
  await sub.cancel();
  await sub2.cancel();
  // Useful for cleaning the worker thread used to poll through libuv, use sparingly.
  adapter.destroy();
  print("Ended");
}
```

## Additional information

This package welcomes contributions, and if more APIs from dns_sd.h are needed, 
PRs are welcome.


