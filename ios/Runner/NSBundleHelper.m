#import <Foundation/Foundation.h>
#import "NSBundleHelper.h"

const char* getMainBundlePath() {
    return [[NSBundle mainBundle].bundlePath UTF8String];
}
