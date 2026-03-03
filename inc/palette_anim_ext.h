#ifndef _PALETTE_ANIM_EXT_H_
#define _PALETTE_ANIM_EXT_H_

#include <genesis.h>

typedef struct
{
    u16 palette;
    u16 firstColor;
    u16 colorCount;
    u16 frameCount;
    u16 frameDelay;
    u16 reserved;
    const u16 *frames;
} PaletteAnim;

#endif
