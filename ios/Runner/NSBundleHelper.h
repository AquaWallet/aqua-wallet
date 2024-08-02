#ifndef NSBundleHelper_h
#define NSBundleHelper_h

// BundleHelper.h

#import <Foundation/Foundation.h>

// Declares the C function for external use.
__attribute__((visibility("default")))
const char* getMainBundlePath(void);

#endif /* NSBundleHelper_h */

