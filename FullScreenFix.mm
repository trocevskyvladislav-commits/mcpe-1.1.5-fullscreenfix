#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Резервный метод для подмены реализации (Method Swizzling)
static void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation UIScreen (FullscreenFix)

// 1. Возвращаем реальные физические границы матрицы
- (CGRect)fake_bounds {
    CGRect native = [self nativeBounds];
    CGFloat scale = [self nativeScale];
    if (scale <= 0) scale = [self scale];
    if (scale <= 0) scale = 1.0;

    // Переводим пиксели матрицы в точки UIKit
    return CGRectMake(0, 0, native.size.width / scale, native.size.height / scale);
}

// 2. Убираем устаревшие рамки StatusBar / Safe Area отступов
- (CGRect)fake_applicationFrame {
    return [self fake_bounds];
}

@end

@implementation UIView (FullscreenFixWindow)

// 3. Форсируем растягивание главного представления окна на весь экран
- (CGRect)fake_frame {
    if ([self isKindOfClass:[UIWindow class]]) {
        return [[UIScreen mainScreen] bounds];
    }
    return [self fake_frame]; // Вызов оригинального метода после swizzling
}

@end

// Точка входа: выполняем подмену методов при загрузке библиотеки в память
__attribute__((constructor))
static void init_fullscreen_fix(void) {
    @autoreleasepool {
        Class screenClass = [UIScreen class];
        
        // Подменяем bounds и applicationFrame
        swizzleMethod(screenClass, @selector(bounds), @selector(fake_bounds));
        swizzleMethod(screenClass, @selector(applicationFrame), @selector(fake_applicationFrame));
        
        // Подменяем frame для UIWindow
        Class viewClass = [UIView class];
        swizzleMethod(viewClass, @selector(frame), @selector(fake_frame));
    }
}

