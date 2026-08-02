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

// Принудительное назначение корректного Scale Factor для Viewport OpenGL
- (void)fake_didMoveToWindow {
    [self fake_didMoveToWindow];
    if ([self isKindOfClass:NSClassFromString(@"EAGLView")]) {
        self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

@end

@implementation CALayer (EAGLFixLayer)

// Фикс слоя CAEAGLLayer для предотвращения нулевых Framebuffer
- (void)fake_setBounds:(CGRect)bounds {
    if ([self isKindOfClass:[CAEAGLLayer class]]) {
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
        // Swizzle UIView (EAGLView)
        swizzleMethod([UIView class], @selector(didMoveToWindow), @selector(fake_didMoveToWindow));
        
        // Swizzle CALayer (CAEAGLLayer)
        swizzleMethod([CALayer class], @selector(setBounds:), @selector(fake_setBounds:));
    }
}
