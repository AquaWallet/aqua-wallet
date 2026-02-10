
#ifndef GDK_API_H
#define GDK_API_H

#ifdef GDK_STATIC_DEFINE
#  define GDK_API
#  define GDK_NO_EXPORT
#else
#  ifndef GDK_API
#    ifdef greenaddress_objects_EXPORTS
        /* We are building this library */
#      define GDK_API __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define GDK_API __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef GDK_NO_EXPORT
#    define GDK_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef GDK_DEPRECATED
#  define GDK_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef GDK_DEPRECATED_EXPORT
#  define GDK_DEPRECATED_EXPORT GDK_API GDK_DEPRECATED
#endif

#ifndef GDK_DEPRECATED_NO_EXPORT
#  define GDK_DEPRECATED_NO_EXPORT GDK_NO_EXPORT GDK_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef GDK_NO_DEPRECATED
#    define GDK_NO_DEPRECATED
#  endif
#endif

#endif /* GDK_API_H */
