#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static CGRect (*orig_bounds)(id, SEL);

static CGRect custom_bounds(id self, SEL _cmd) {
    // Если запрос идет к главному экрану, отдаем корректные 16:9
    if (self == [UIScreen mainScreen]) {
        return CGRectMake(0, 0, 667, 375); // Landscape 16:9
    }
    return orig_bounds(self, _cmd);
}

__attribute__((constructor))
static void init_screen_fix(void) {
    @autoreleasepool {
        Class screenClass = [UIScreen class];
        SEL sel = @selector(bounds);
        Method m = class_getInstanceMethod(screenClass, sel);
        if (m) {
            orig_bounds = (CGRect (*)(id, SEL))method_getImplementation(m);
            method_setImplementation(m, (IMP)custom_bounds);
        }
    }
}
