#include "callbacks.h"

#include <stdint.h>
#include <gdk/gdk.h>
#include <assert.h>
#include <stdlib.h>

#include "dart_native_api.h"

static Dart_PostCObject dart_PostCObject = 0;

typedef struct _Context {
    Dart_Port port;
} Context;

HELPER_API void* create_context(int64_t port) {
    Context* context = malloc(sizeof(Context));
    context->port = port;
    return context;
}

HELPER_API void set_post_object_ptr(void *ptr) {
    dart_PostCObject = ptr;
}

HELPER_API void notification_handler(void *context, void *details) {
    char *output = 0;
    int result = GA_convert_json_to_string(details, &output);
    assert(result == 0);

    Dart_CObject obj;
    obj.type = Dart_CObject_kString;
    obj.value.as_string = output;
    bool postResult = dart_PostCObject(((Context*)context)->port, &obj);
    assert(postResult != 0);

    GA_destroy_string(output);
}
