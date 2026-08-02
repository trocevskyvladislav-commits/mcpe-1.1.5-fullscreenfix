#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Оригинальные функции
static void (*orig_didMoveToWindow)(id, SEL);
static void (*orig_setBounds)(id, SEL, CGRect);

// ПерехватdidMoveToWindow для UIView (EAGLView)
static void custom_didMoveToWindow(id self, SEL _cmd) {
    orig_didMoveToWindow(self, _cmd);
    
    Class eaglViewClass = NSClassFromString(@"EAGLView");
    if (eaglViewClass && [self isKindOfClass:eaglViewClass]) {
        UIView *view = (UIView *)self;
        view.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

// Перехват setBounds для CALayer (CAEAGLLayer)
static void custom_setBounds(id self, SEL _cmd, CGRect bounds) {
    Class eaglLayerClass = NSClassFromString(@"CAEAGLLayer");
    if (eaglLayerClass && [self isKindOfClass:eaglLayerClass]) {
        CGRect screenBounds = [UIScreen mainScreen].nativeBounds;
        CGFloat scale = [UIScreen mainScreen].nativeScale;
        if (scale > 0) {
            bounds = CGRectMake(0, 0, screenBounds.size.width / scale, screenBounds.size.height / scale);
        }
    }
    orig_setBounds(self, _cmd, bounds);
}

__attribute__((constructor))
static void init_fullscreen_fix(void) {
    @autoreleasepool {
        // Swizzle UIView - didMoveToWindow
        Class uiViewClass = NSClassFromString(@"UIView");
        if (uiViewClass) {
            SEL sel = @selector(didMoveToWindow);
            Method m = class_getInstanceMethod(uiViewClass, sel);
            if (m) {
                orig_didMoveToWindow = (void (*)(id, SEL))method_getImplementation(m);
                method_setImplementation(m, (IMP)custom_didMoveToWindow);
            }
        }
        
        // Swizzle CALayer - setBounds:
        Class caLayerClass = NSClassFromString(@"CALayer");
        if (caLayerClass) {
            SEL sel = @selector(setBounds:);
            Method m = class_getInstanceMethod(caLayerClass, sel);
            if (m) {
                orig_setBounds = (void (*)(id, SEL, CGRect))method_getImplementation(m);
                method_setImplementation(m, (IMP)custom_setBounds);
            }
        }
    }
}
