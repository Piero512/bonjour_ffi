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
#include <dns_sd.h>
struct BonjourNativeBinding;
struct ServiceBrowseContext;
struct ServiceBroadcastContext;
typedef struct BonjourNativeBinding BonjourNativeBinding;
typedef struct ServiceBrowseContext ResolveContext;
typedef struct ServiceBroadcastContext BroadcastContext;

#ifdef __cplusplus

struct HandleRefs {
    HandleRefs(DNSServiceRef pService, uv_poll_s* pS) : ref(pService), handle(pS) {}

    DNSServiceRef ref;
    uv_poll_t* handle;
};

struct ServiceBrowseContext {
    explicit ServiceBrowseContext() : search_ref(nullptr, nullptr) {};

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

struct ServiceResolveContext {
    std::string service_name;
    std::string txt;
    int networkPort;
    ServiceBrowseContext* ref;
};

#endif

#ifdef __cplusplus
extern "C" {
#endif
LIBFFI_TEST_EXPORT BonjourNativeBinding* get_new_instance();

LIBFFI_TEST_EXPORT void delete_instance(BonjourNativeBinding* instance);


LIBFFI_TEST_EXPORT intptr_t initializeDartAPIDL(void* data);

LIBFFI_TEST_EXPORT ResolveContext*
search_for_service(BonjourNativeBinding* adapter, const char* service_type, Dart_Port_DL port, const char** err_str);

LIBFFI_TEST_EXPORT BroadcastContext*
broadcast_service(BonjourNativeBinding* adapter, const char* service_name, const char* service_type, int port,
                  const char* txt, int txtLength,
                  Dart_Port_DL sendport, const char** err_code);

LIBFFI_TEST_EXPORT void stop_broadcast(BonjourNativeBinding* adapter, BroadcastContext* ctx);

LIBFFI_TEST_EXPORT void stop_search(BonjourNativeBinding* adapter, ResolveContext* ctx);

#ifdef __cplusplus
}
#endif