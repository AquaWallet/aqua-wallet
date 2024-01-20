#pragma once

#define HELPER_API __attribute__((visibility("default"))) __attribute__((used))

#include <stdint.h>

HELPER_API void* create_context(int64_t port);

HELPER_API void set_post_object_ptr(void *ptr);

HELPER_API void notification_handler(void *context, void *details);
