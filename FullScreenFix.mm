#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static void swizzleMethod(Class targetClass, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(targetClass, swizzledSelector);
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation UIView (EAGLFix)

- (void)fake_didMoveToWindow {
    [self fake_didMoveToWindow];
    if ([self isKindOfClass:NSClassFromString(@"EAGLView")]) {
        self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

@end

@implementation CALayer (EAGLFixLayer)

- (void)fake_setBounds:(CGRect)bounds {
    // Безопасная динамическая проверка класса без жестких ссылок на OpenGLES
    Class eaglLayerClass = NSClassFromString(@"CAEAGLLayer");
    if (eaglLayerClass && [self isKindOfClass:eaglLayerClass]) {
        CGRect screenBounds = [UIScreen mainScreen].nativeBounds;
        CGFloat scale = [UIScreen mainScreen].nativeScale;
        if (scale > 0) {
            bounds = CGRectMake(0, 0, screenBounds.size.width / scale, screenBounds.size.height / scale);
        }
    }
    [self fake_setBounds:bounds];
}

@end

__attribute__((constructor))
static void init_fullscreen_fix(void) {
    @autoreleasepool {
        swizzleMethod([UIView class], @selector(didMoveToWindow), @selector(fake_didMoveToWindow));
        
        Class calayerClass = NSClassFromString(@"CALayer");
        if (calayerClass) {
            swizzleMethod(calayerClass, @selector(setBounds:), @selector(fake_setBounds:));
        }
    }
}
