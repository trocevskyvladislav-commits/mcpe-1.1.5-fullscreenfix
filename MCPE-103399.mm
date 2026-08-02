#import <Foundation/Foundation.h>
#import <substrate.h>

// Указатели на оригинальные функции C++ из 1.1.5
bool (*orig_SignItem_useOn)(void* self, void* itemStack, void* player, int x, int y, int z, signed char face, float clickX, float clickY, float clickZ);
bool (*orig_Block_canBeReplaced)(void* block, void* region, int x, int y, int z);
int  (*orig_Block_getId)(void* block);

static bool g_IsPlacingSign = false;

// ID Бедрока в MCPE 1.1.5 равен 7
#define BEDROCK_ID 7

// 1. Хукаем проверку "можно ли заменить блок"
bool hook_Block_canBeReplaced(void* block, void* region, int x, int y, int z) {
    if (g_IsPlacingSign) {
        // Проверяем, не пытается ли табличка затереть бедрок
        if (block != NULL) {
            int blockId = orig_Block_getId(block);
            if (blockId == BEDROCK_ID) {
                return false; // Бедрок НЕ заменяем (как и в 1.16.100)
            }
        }
        // Все остальные блоки (камень, обсидиан, сундуки и т.д.) разрешаем перезаписывать!
        return true; 
    }
    return orig_Block_canBeReplaced(block, region, x, y, z);
}

// 2. Хукаем установку таблички
bool hook_SignItem_useOn(void* self, void* itemStack, void* player, int x, int y, int z, signed char face, float clickX, float clickY, float clickZ) {
    // Включаем контекст "Идет установка таблички"
    g_IsPlacingSign = true;
    
    // Вызываем родной метод установки 1.1.5
    bool result = orig_SignItem_useOn(self, itemStack, player, x, y, z, face, clickX, clickY, clickZ);
    
    // Выключаем контекст
    g_IsPlacingSign = false;
    
    return result;
}

__attribute__((constructor))
static void init_mcpe103399_patch() {
    // Поиск мангированных символов в бинарнике minecraftpe 1.1.5:
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
