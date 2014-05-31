#import "NSDictionary+MVKAdditions.h"

@implementation NSDictionary (MVKAdditions)

- (NSMutableDictionary *)deepMutableCopy
{
    return (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)self, kCFPropertyListMutableContainersAndLeaves));
}

@end
