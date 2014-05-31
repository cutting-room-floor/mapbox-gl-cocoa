#import <UIKit/UIKit.h>

@interface UIColor (MVKAdditions)

+ (UIColor *)colorWithRGBAString:(NSString *)rgbaString;
- (NSString *)rgbaStringFromColor;

+ (UIColor *)colorWithHexString:(NSString *)hexString;
- (NSString *)hexStringFromColor;

@end
