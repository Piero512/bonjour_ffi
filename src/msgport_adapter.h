#pragma once

#include <uv.h>

class DNSSDAdapter;

struct HandleRefs {
    HandleRefs(DNSServiceRef pService, uv_poll_s *pS) : ref(pService), handle(pS) {}

    DNSServiceRef ref;
    uv_poll_t *handle;
};

struct ServiceResolveContext {
    explicit ServiceResolveContext() : search_ref(nullptr, nullptr) {};

    Dart_Port_DL port{};
    HandleRefs search_ref;
    std::vector<HandleRefs> resolve_refs;
    std::vector<HandleRefs> ip_refs;
    uv_loop_t *loop_ptr{};
};

typedef struct ServiceResolveContext ResolveContext;

struct ServiceBroadcastContext {
    explicit ServiceBroadcastContext() : broadcast_ref(nullptr, nullptr) {};
    Dart_Port_DL port{};
    HandleRefs broadcast_ref;
};

typedef struct ServiceBroadcastContext BroadcastContext;
#ifdef __cplusplus
extern "C" {
#endif

DNSSDAdapter *get_new_instance();

void delete_instance(DNSSDAdapter *instance);


intptr_t initializeDartAPIDL(void *data);

ResolveContext *search_for_service(DNSSDAdapter *adapter, const char *service_type, Dart_Port_DL port);

BroadcastContext *
broadcast_service(DNSSDAdapter *adapter, const char *service_name, const char *service_type, int port, const char *txt,
                  Dart_Port_DL sendport);

void stop_broadcast(DNSSDAdapter *adapter, BroadcastContext *ctx);

#ifdef __cplusplus
}
#endif