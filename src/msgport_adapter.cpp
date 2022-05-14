#include "dart_headers/dart_api_dl.h"
#include "uv.h"
#include "dns_sd.h"
#include <functional>
#include <vector>
#include "msgport_adapter.h"
#include "nlohmann/json.hpp"


struct BonjourNativeBinding {
public:
    uv_loop_t loop{};
    uv_thread_t event_loop_thread{};
    uv_async_t stop_handle{};
    uv_async_t run_on_uv_loop_handle{};

    static Dart_CObject getStringObject(const char* data) {
        Dart_CObject toReturn{};
        toReturn.type = Dart_CObject_kString;
        toReturn.value.as_string = const_cast<char*>(data);
        return toReturn;
    }

    static std::string getAddress(const struct sockaddr* address) {
        std::string toReturn(INET6_ADDRSTRLEN,'\0');
        uv_ip_name(address, toReturn.data(), INET6_ADDRSTRLEN);
        toReturn.resize(strlen(toReturn.data()));
        return toReturn;
    }

    BonjourNativeBinding() {
        uv_loop_init(&loop);
        uv_async_init(&loop, &stop_handle, [](uv_async_t* async_handle) {
            printf("Received stop async callback! Closing...\n");
            uv_close(reinterpret_cast<uv_handle_t*>(async_handle), nullptr);
        });
        uv_async_init(&loop, &run_on_uv_loop_handle, [](uv_async_t* handle) {
            if (handle->data != nullptr) {
                auto fn = reinterpret_cast<std::function<void()>*>(handle->data);
                (*fn)();
                delete fn;
            }
            handle->data = nullptr;
        });
        uv_thread_create(&event_loop_thread, [](void* l) {
            printf("Starting event loop in different thread...\n");
            uv_run((uv_loop_t*) l, UV_RUN_DEFAULT);
            printf("uv_run returned...\n");
        }, &loop);
    }

    ~BonjourNativeBinding() {
        uv_async_send(&stop_handle);
        uv_close(reinterpret_cast<uv_handle_t*>(&run_on_uv_loop_handle), nullptr);
        uv_loop_close(&loop);
        uv_thread_join(&event_loop_thread);
    }

    static void process_readable_socket(uv_poll_t* self, int status, int events) {
        if (status >= 0) {
            if (events & UV_READABLE) {
                auto ref = reinterpret_cast<DNSServiceRef>(self->data);
                DNSServiceProcessResult(ref);
            }
            // Probably not an error, but unexpected wakeup.
        } else {
            fprintf(stderr, "Received error while polling socket: %s\n", uv_err_name(status));
            uv_poll_stop(self);
            uv_close(reinterpret_cast<uv_handle_t*>(self), [](uv_handle_t* closing_handle) {
                delete closing_handle;
            });
        }
    }

    static void resolve_ip_address_dns_sd(
            DNSServiceRef sdRef,
            DNSServiceFlags flags,
            uint32_t interfaceIndex,
            DNSServiceErrorType errorCode,
            const char* hostname,
            const struct sockaddr* address,
            uint32_t ttl,
            void* context
    ) {
        auto ctx = reinterpret_cast<ServiceResolveContext*>(context);
        if (errorCode == kDNSServiceErr_NoError) {
            // Send the found IP to Dart.
            auto ip = getAddress(address);
            auto json = nlohmann::json::object({
                   {"type", "resolved"},
                   {"address", ip},
                   {"serviceName", hostname},
                   {"serviceType", ctx->service_type}
                }
            );
            auto serialized = to_string(json);
            auto dart_obj = getStringObject(serialized.c_str());
            Dart_PostCObject_DL(ctx->port, &dart_obj);
            // Dispose of the poll handle and close IP ref.
            auto ip_resolver_refs_iter = std::find_if(ctx->ip_refs.begin(), ctx->ip_refs.end(),
                                                      [&sdRef](const HandleRefs& val) {
                                                          return val.ref == sdRef;
                                                      });
            if (ip_resolver_refs_iter != ctx->ip_refs.end()) {
                auto& resolved_ref = *ip_resolver_refs_iter;
                uv_poll_stop(resolved_ref.handle);
                uv_close(reinterpret_cast<uv_handle_t*>(resolved_ref.handle), [](uv_handle_t* closed_handle) {
                    delete closed_handle;
                });
                DNSServiceRefDeallocate(sdRef);
                ctx->ip_refs.erase(ip_resolver_refs_iter);
            }
        }
    }

    static void _resolve_service_dns_sd_call(
            DNSServiceRef sdRef,
            DNSServiceFlags flags,
            uint32_t interfaceIndex,
            DNSServiceErrorType errorCode,
            const char* fullname,
            const char* hosttarget,
            uint16_t port,                                   /* In network byte order */
            uint16_t txtLen,
            const unsigned char* txtRecord,
            void* context
    ) {
        auto ctx = reinterpret_cast<ServiceResolveContext*>(context);
        if (errorCode == kDNSServiceErr_NoError) {
            auto json = nlohmann::json::object({
                   {"type", "found"},
                   {"serviceName", fullname},
                   {"serviceType", ctx->service_type}
                }
            );
            auto serialized = to_string(json);
            auto dart_obj = getStringObject(serialized.c_str());
            Dart_PostCObject_DL(ctx->port, &dart_obj);
            DNSServiceRef ip_ref;
            auto poll_handle = new uv_poll_t{};
            DNSServiceGetAddrInfo(&ip_ref, 0, interfaceIndex, kDNSServiceProtocol_IPv4 | kDNSServiceProtocol_IPv6,
                                  hosttarget, &BonjourNativeBinding::resolve_ip_address_dns_sd, context);
            poll_handle->data = ip_ref;
            uv_poll_init_socket(ctx->loop_ptr, poll_handle, DNSServiceRefSockFD(ip_ref));
            uv_poll_start(poll_handle, UV_READABLE, &BonjourNativeBinding::process_readable_socket);
            ctx->ip_refs.emplace_back(ip_ref, poll_handle);
        }
    }

    static void _search_service_dns_sd_call(
            DNSServiceRef sdRef,
            DNSServiceFlags flags,
            uint32_t interfaceIndex,
            DNSServiceErrorType errorCode,
            const char* serviceName,
            const char* regtype,
            const char* replyDomain,
            void* context) {
        auto ctx = reinterpret_cast<ServiceResolveContext*>(context);
        if (errorCode == kDNSServiceErr_NoError) {
            if (flags & kDNSServiceFlagsAdd) {
                // Added
                auto json = nlohmann::json::object({
                       {"type", "added"},
                       {"serviceName", serviceName},
                       {"serviceType", ctx->service_type}
                    }
                );
                auto serialized = to_string(json);
                auto dart_obj = getStringObject(serialized.c_str());
                Dart_PostCObject_DL(ctx->port, &dart_obj);
                DNSServiceRef resolvedRef;
                DNSServiceResolve(&resolvedRef, flags, interfaceIndex, serviceName, regtype, replyDomain,
                                  &BonjourNativeBinding::_resolve_service_dns_sd_call, context);

                auto resolve_handle = new uv_poll_t{};
                resolve_handle->data = resolvedRef;
                uv_poll_init_socket(ctx->loop_ptr, resolve_handle, DNSServiceRefSockFD(resolvedRef));
                uv_poll_start(resolve_handle, UV_READABLE, &BonjourNativeBinding::process_readable_socket);
                ctx->resolve_refs.emplace_back(resolvedRef, resolve_handle);
            } else {
                // Removed
                auto json = nlohmann::json::object({
                       {"type", "removed"},
                       {"serviceName", serviceName},
                       {"serviceType", ctx->service_type},
                    }
                );
                auto serialized = to_string(json);
                auto dart_obj = getStringObject(serialized.c_str());
                Dart_PostCObject_DL(ctx->port, &dart_obj);
            }
        }
    }

    static void broadcast_service_dns_sd_cb(
            DNSServiceRef sdRef,
            DNSServiceFlags flags,
            DNSServiceErrorType errorCode,
            const char* name,
            const char* regtype,
            const char* domain,
            void* context
    ) {
        auto ctx = reinterpret_cast<BroadcastContext*>(context);
        if (errorCode == kDNSServiceErr_NoError) {
            nlohmann::json json;
            if (flags & kDNSServiceFlagsAdd) {
                json = nlohmann::json::object({{"type","added"}, {"serviceName", std::string(name) + regtype + domain }});
            } else {
                json = nlohmann::json::object({{"type","removed"}, {"serviceName", std::string(name) + regtype + domain }});
            }
            auto serialized = to_string(json);
            auto obj = getStringObject(serialized.c_str());
            Dart_PostCObject_DL(ctx->port, &obj);
        }
    }

    ResolveContext* search_for_service(const std::string& type, Dart_Port_DL sendport) {
        // Add new request through dns_sd.h and add the respective socket into the event loop.
        auto* context = new ResolveContext{};
        context->loop_ptr = &loop;
        context->service_type = type;
        context->port = sendport;
        DNSServiceRef ref;
        auto err = DNSServiceBrowse(&ref, 0, 0, type.c_str(), nullptr,
                                    &BonjourNativeBinding::_search_service_dns_sd_call,
                                    (void*) context);
        if (err == kDNSServiceErr_NoError) {
            auto poll_handle = new uv_poll_t{};
            poll_handle->data = ref;
            context->search_ref.ref = ref;
            context->search_ref.handle = poll_handle;
            auto* fn = new std::function([=]() {
                uv_poll_init_socket(&this->loop, poll_handle, DNSServiceRefSockFD(ref));
                uv_poll_start(poll_handle, UV_READABLE, &BonjourNativeBinding::process_readable_socket);
            });
            this->run_on_uv_loop_handle.data = fn;
            uv_async_send(&run_on_uv_loop_handle);
        }
        return context;
    }

    BroadcastContext* broadcast_service(const std::string& service_name, const std::string& service_type, int port,
                                        const std::string& txt, Dart_Port_DL sendport) {
        auto* ctx = new BroadcastContext{};
        DNSServiceRef broadcast_ref;
        auto err = DNSServiceRegister(&broadcast_ref, 0, 0, service_name.c_str(), service_type.c_str(), nullptr,
                                      nullptr,
                                      htons(port), 0,
                                      nullptr, &BonjourNativeBinding::broadcast_service_dns_sd_cb, ctx);
        if (err == kDNSServiceErr_NoError) {
            auto* poll_handle = new uv_poll_t{};
            ctx->port = sendport;
            ctx->broadcast_ref.ref = broadcast_ref;
            ctx->broadcast_ref.handle = poll_handle;
            poll_handle->data = broadcast_ref;
            auto* fn = new std::function([=]() {
                uv_poll_init_socket(&loop, poll_handle, DNSServiceRefSockFD(broadcast_ref));
                uv_poll_start(poll_handle, UV_READABLE, &BonjourNativeBinding::process_readable_socket);
            });
            this->run_on_uv_loop_handle.data = fn;
            uv_async_send(&run_on_uv_loop_handle);
        }
        return ctx;
    }

    void stop_broadcast(BroadcastContext* ctx) {
        auto* fn = new std::function([ctx]() {
            auto broadcast_handle = ctx->broadcast_ref.handle;
            delete_handle(broadcast_handle);
            delete ctx;
        });
        this->run_on_uv_loop_handle.data = fn;
        uv_async_send(&run_on_uv_loop_handle);
    }

    static void delete_handle(uv_poll_t* poll_handle) {
        uv_poll_stop(poll_handle);
        uv_close(reinterpret_cast<uv_handle_t*>(poll_handle), [](uv_handle_t* handle) {
            DNSServiceRefDeallocate(reinterpret_cast<DNSServiceRef>(handle->data));
            delete handle;
        });
    }

    void stop_search(ResolveContext* ctx) {
        auto* fn = new std::function<void()>([ctx]() {
            auto search_handle = ctx->search_ref.handle;
            delete_handle(search_handle);
            ctx->search_ref.handle = nullptr;
            for (const auto& item: ctx->resolve_refs) {
                delete_handle(item.handle);
            }
            for (const auto& item: ctx->ip_refs) {
                delete_handle(item.handle);
            }
            delete ctx;
        });
        this->run_on_uv_loop_handle.data = fn;
        uv_async_send(&run_on_uv_loop_handle);
    }
};

BonjourNativeBinding* get_new_instance() {
    return new BonjourNativeBinding();
}


void delete_instance(BonjourNativeBinding* instance) {
    delete instance;
}

intptr_t initializeDartAPIDL(void* data) {
    return Dart_InitializeApiDL(data);
}

ResolveContext* search_for_service(BonjourNativeBinding* adapter, const char* service_type, Dart_Port_DL port) {
    return adapter->search_for_service(service_type, port);
}

void stop_search(BonjourNativeBinding* adapter, ResolveContext* ctx) {
    adapter->stop_search(ctx);
}

BroadcastContext*
broadcast_service(BonjourNativeBinding* adapter, const char* service_name, const char* service_type, int port,
                  const char* txt,
                  Dart_Port_DL sendport) {
    return adapter->broadcast_service(service_name, service_type, port, txt, sendport);
}

void stop_broadcast(BonjourNativeBinding* adapter, BroadcastContext* ctx) {
    adapter->stop_broadcast(ctx);
}
