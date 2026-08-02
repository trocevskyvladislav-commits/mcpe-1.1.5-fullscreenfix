#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 1. Указатель на оригинальный метод [UIScreen bounds]
static CGRect (*orig_UIScreen_bounds)(id self, SEL _cmd);

// Наша подмена: принудительно отдаем реальные физические размеры экрана
CGRect hk_UIScreen_bounds(id self, SEL _cmd) {
    UIScreen *screen = [UIScreen mainScreen];
    CGRect nativeBounds = [screen nativeBounds];
    CGFloat scale = [screen nativeScale];
    if (scale <= 0) scale = 2.0;

    CGFloat w = nativeBounds.size.width / scale;
    CGFloat h = nativeBounds.size.height / scale;

    // Гарантируем Landscape режим (ширина больше высоты)
    CGFloat realWidth = fmax(w, h);
    CGFloat realHeight = fmin(w, h);

    return CGRectMake(0, 0, realWidth, realHeight);
}

// 2. Функция, которая растягивает все View игры на весь экран
void forceFullScreenLayout() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        CGRect screenRect = [UIScreen mainScreen].bounds;
        window.frame = screenRect;

        for (UIView *view in window.subviews) {
            view.frame = screenRect;
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [view setNeedsLayout];
            [view layoutIfNeeded];
        }
    });
}

// 3. Точка входа при загрузке dylib в процесс MCPE
__attribute__((constructor))
static void init_fullscreen_fix() {
    @autoreleasepool {
        // Подменяем метод [UIScreen bounds]
        Class screenClass = [UIScreen class];
        Method boundsMethod = class_getInstanceMethod(screenClass, @selector(bounds));
        if (boundsMethod) {
            orig_UIScreen_bounds = (CGRect (*)(id, SEL))method_getImplementation(boundsMethod);
            method_setImplementation(boundsMethod, (IMP)hk_UIScreen_bounds);
        }

        // Подписываемся на события загрузки, чтобы применить размеры
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            forceFullScreenLayout();
            
            // Дополнительный запуск через 0.5 сек (когда C++ движок закончит инициализацию OpenGL)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                forceFullScreenLayout();
            });
        }];
    }
}
