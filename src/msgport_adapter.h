#pragma once
#if WIN32
#define LIBFFI_TEST_EXPORT __declspec(dllexport)
#else
#ifdef __cplusplus
#define LIBFFI_TEST_EXPORT extern "C"
#else
#define LIBFFI_TEST_EXPORT
#endif
#endif

#include <uv.h>
#include "dart_headers/dart_api_dl.h"

struct BonjourNativeBinding;
struct ServiceResolveContext;
struct ServiceBroadcastContext;
typedef struct BonjourNativeBinding BonjourNativeBinding;
typedef struct ServiceResolveContext ResolveContext;
typedef struct ServiceBroadcastContext BroadcastContext;

#ifdef __cplusplus

struct HandleRefs {
    HandleRefs(DNSServiceRef pService, uv_poll_s* pS) : ref(pService), handle(pS) {}

    DNSServiceRef ref;
    uv_poll_t* handle;
};

struct ServiceResolveContext {
    explicit ServiceResolveContext() : search_ref(nullptr, nullptr) {};

    Dart_Port_DL port{};
    HandleRefs search_ref;
    std::vector<HandleRefs> resolve_refs;
    std::vector<HandleRefs> ip_refs;
    uv_loop_t* loop_ptr{};
    std::string service_type;
};

struct ServiceBroadcastContext {
    explicit ServiceBroadcastContext() : broadcast_ref(nullptr, nullptr) {};
    Dart_Port_DL port{};
    HandleRefs broadcast_ref;
};

#endif

#ifdef __cplusplus
extern "C" {
#endif
LIBFFI_TEST_EXPORT BonjourNativeBinding* get_new_instance();

LIBFFI_TEST_EXPORT void delete_instance(BonjourNativeBinding* instance);


LIBFFI_TEST_EXPORT intptr_t initializeDartAPIDL(void* data);

LIBFFI_TEST_EXPORT ResolveContext*
search_for_service(BonjourNativeBinding* adapter, const char* service_type, Dart_Port_DL port);

LIBFFI_TEST_EXPORT BroadcastContext*
broadcast_service(BonjourNativeBinding* adapter, const char* service_name, const char* service_type, int port,
                  const char* txt,
                  Dart_Port_DL sendport);

LIBFFI_TEST_EXPORT void stop_broadcast(BonjourNativeBinding* adapter, BroadcastContext* ctx);

LIBFFI_TEST_EXPORT void stop_search(BonjourNativeBinding* adapter, ResolveContext* ctx);

#ifdef __cplusplus
}
#endif