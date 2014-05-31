#import "NSArray+MVKAdditions.h"

@implementation NSArray (MVKAdditions)

- (NSMutableArray *)deepMutableCopy
{
    return (NSMutableArray *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFArrayRef)self, kCFPropertyListMutableContainersAndLeaves));
}

@end
