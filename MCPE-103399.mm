#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Объявляем функции Substrate/Dobby вручную, чтобы не запрашивать substrate.h
extern "C" {
    void MSHookFunction(void *symbol, void *replace, void **result);
    void *MSFindSymbol(void *image, const char *name);
}

// Указатели на оригинальные C++ функции MCPE 1.1.5
bool (*orig_SignItem_useOn)(void* self, void* itemStack, void* player, int x, int y, int z, signed char face, float clickX, float clickY, float clickZ);
bool (*orig_Block_canBeReplaced)(void* block, void* region, int x, int y, int z);
int  (*orig_Block_getId)(void* block);

static bool g_IsPlacingSign = false;

#define BEDROCK_ID 7

bool hook_Block_canBeReplaced(void* block, void* region, int x, int y, int z) {
    if (g_IsPlacingSign) {
        if (block != NULL && orig_Block_getId != NULL) {
            int blockId = orig_Block_getId(block);
            if (blockId == BEDROCK_ID) {
                return false;
            }
        }
        return true;
    }
    return orig_Block_canBeReplaced(block, region, x, y, z);
}

bool hook_SignItem_useOn(void* self, void* itemStack, void* player, int x, int y, int z, signed char face, float clickX, float clickY, float clickZ) {
    g_IsPlacingSign = true;
    bool result = orig_SignItem_useOn(self, itemStack, player, x, y, z, face, clickX, clickY, clickZ);
    g_IsPlacingSign = false;
    return result;
}

__attribute__((constructor))
static void init_mcpe103399_patch() {
    void* signUseOnSym     = (void*)MSFindSymbol(NULL, "__NK8SignItem5useOnER9ItemStackR6PlayeriiiEfff");
    void* canBeReplacedSym = (void*)MSFindSymbol(NULL, "__NK5Block14canBeReplacedER11BlockSourceiii");
    void* getIdSym         = (void*)MSFindSymbol(NULL, "__NK5Block5getIdEv");

    if (getIdSym) {
        orig_Block_getId = (int (*)(void*))getIdSym;
    }

    if (signUseOnSym && canBeReplacedSym) {
        MSHookFunction(signUseOnSym, (void*)&hook_SignItem_useOn, (void**)&orig_SignItem_useOn);
        MSHookFunction(canBeReplacedSym, (void*)&hook_Block_canBeReplaced, (void**)&orig_Block_canBeReplaced);
    }
}
