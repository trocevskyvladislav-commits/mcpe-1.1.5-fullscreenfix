#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

// Объявление типа функции glViewport
typedef void (*glViewportFunc)(int x, int y, int width, int height);
static glViewportFunc orig_glViewport = NULL;

// Перехваченный glViewport
void my_glViewport(int x, int y, int width, int height) {
    // Если игра пытается выставить нулевой или кривой Viewport после логотипа
    if (width <= 0 || height <= 0) {
        CGRect mainBounds = [UIScreen mainScreen].nativeBounds;
        width = (int)mainBounds.size.width;
        height = (int)mainBounds.size.height;
    }
    
    // Вызываем оригинальный glViewport с правильными размерами
    if (orig_glViewport) {
        orig_glViewport(x, y, width, height);
    }
}

__attribute__((constructor))
static void init_opengl_hook(void) {
    @autoreleasepool {
        // Подгружаем символ glViewport из системного OpenGLES фреймворка
        void* libgles = dlopen("/System/Library/Frameworks/OpenGLES.framework/OpenGLES", RTLD_LAZY);
        if (libgles) {
            orig_glViewport = (glViewportFunc)dlsym(libgles, "glViewport");
        }
    }
}
