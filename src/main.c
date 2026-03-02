#include <genesis.h>
#include "palette_anim_ext.h"
#include "resources.h"

#define TILE_VRAM_BG       1
#define TILE_VRAM_PLAYER   (TILE_VRAM_BG + BG_TILE_COUNT)
#define BG_PLANE_W         40
#define BG_PLANE_H         28

enum
{
    BG_TILE_SKY = 0,
    BG_TILE_CLOUD,
    BG_TILE_GROUND,
    BG_TILE_ROCK,
    BG_TILE_WATER_0,
    BG_TILE_WATER_1,
    BG_TILE_COUNT
};

static const u16 bgPalette[16] =
{
    0x0000, 0x0E86, 0x0EEE, 0x0A64,
    0x02A0, 0x0260, 0x0644, 0x0886,
    0x0200, 0x0400, 0x0640, 0x08A0,
    0x0000, 0x0000, 0x0000, 0x0EEE
};

static const u16 spritePalette[16] =
{
    0x0000, 0x0222, 0x024E, 0x0EEE,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000
};

static const u32 bgTiles[BG_TILE_COUNT * 8] =
{
    /* SKY */
    0x11111111, 0x11111111, 0x11111111, 0x11111111,
    0x11111111, 0x11111111, 0x11111111, 0x11111111,
    /* CLOUD */
    0x11111111, 0x11122111, 0x11222211, 0x12222221,
    0x11222211, 0x11122111, 0x11111111, 0x11111111,
    /* GROUND */
    0x44444444, 0x45444544, 0x44444444, 0x55555555,
    0x54555455, 0x55555555, 0x55455545, 0x55555555,
    /* ROCK */
    0x66666666, 0x66556656, 0x65666656, 0x66656566,
    0x56566665, 0x66665666, 0x65666656, 0x66666666,
    /* WATER 0 */
    0x8899AABB, 0x99AABB88, 0xAABB8899, 0xBB8899AA,
    0x8899AABB, 0x99AABB88, 0xAABB8899, 0xBB8899AA,
    /* WATER 1 */
    0x99AABB88, 0xAABB8899, 0xBB8899AA, 0x8899AABB,
    0x99AABB88, 0xAABB8899, 0xBB8899AA, 0x8899AABB
};

static const u32 playerTiles[4 * 8] =
{
    /* top-left */
    0x00011000, 0x00122100, 0x01222210, 0x01233210,
    0x01222210, 0x01222210, 0x00122100, 0x00011000,
    /* top-right */
    0x00011000, 0x00122100, 0x01222210, 0x01223310,
    0x01222210, 0x01222210, 0x00122100, 0x00011000,
    /* bottom-left */
    0x00011000, 0x00122100, 0x01222210, 0x01222210,
    0x01222210, 0x01223210, 0x00122100, 0x00011000,
    /* bottom-right */
    0x00011000, 0x00122100, 0x01222210, 0x01222210,
    0x01222210, 0x01232210, 0x00122100, 0x00011000
};

static s16 playerX = 120;
static s16 playerY = 130;
static u16 waterfallTick = 0;
static u16 waterfallFrame = 0;

static void drawBackground(void)
{
    const u16 attrSky = TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, TILE_VRAM_BG + BG_TILE_SKY);
    const u16 attrCloud = TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, TILE_VRAM_BG + BG_TILE_CLOUD);
    const u16 attrGround = TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, TILE_VRAM_BG + BG_TILE_GROUND);
    const u16 attrRock = TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, TILE_VRAM_BG + BG_TILE_ROCK);
    const u16 attrWater0 = TILE_ATTR_FULL(PAL0, TRUE, FALSE, FALSE, TILE_VRAM_BG + BG_TILE_WATER_0);
    const u16 attrWater1 = TILE_ATTR_FULL(PAL0, TRUE, FALSE, FALSE, TILE_VRAM_BG + BG_TILE_WATER_1);

    u16 x;
    u16 y;

    VDP_clearPlane(BG_A, TRUE);

    for (y = 0; y < BG_PLANE_H; y++)
    {
        for (x = 0; x < BG_PLANE_W; x++)
        {
            u16 tile = attrSky;

            if (y >= 24) tile = attrGround;
            if ((x >= 17) && (x <= 22) && (y >= 6) && (y < 24)) tile = attrRock;
            if ((x >= 19) && (x <= 20) && (y >= 7) && (y < 24))
                tile = ((x + y) & 1) ? attrWater0 : attrWater1;

            VDP_setTileMapXY(BG_A, tile, x, y);
        }
    }

    VDP_setTileMapXY(BG_A, attrCloud, 4, 3);
    VDP_setTileMapXY(BG_A, attrCloud, 5, 3);
    VDP_setTileMapXY(BG_A, attrCloud, 27, 5);
    VDP_setTileMapXY(BG_A, attrCloud, 28, 5);
    VDP_setTileMapXY(BG_A, attrCloud, 32, 2);
}

static void updatePlayer(void)
{
    const u16 joy = JOY_readJoypad(JOY_1);
    const u16 playerAttr = TILE_ATTR_FULL(PAL1, TRUE, FALSE, FALSE, TILE_VRAM_PLAYER);

    if (joy & BUTTON_LEFT) playerX -= 2;
    if (joy & BUTTON_RIGHT) playerX += 2;
    if (joy & BUTTON_UP) playerY -= 2;
    if (joy & BUTTON_DOWN) playerY += 2;

    if (playerX < 0) playerX = 0;
    if (playerY < 0) playerY = 0;
    if (playerX > (320 - 16)) playerX = 320 - 16;
    if (playerY > (224 - 16)) playerY = 224 - 16;

    VDP_setSprite(0, playerX, playerY, SPRITE_SIZE(2, 2), playerAttr);
}

static void applyPaletteAnimFrame(const PaletteAnim *anim, u16 frame)
{
    const u16 *colors = anim->frames + (frame * anim->colorCount);
    PAL_setColors((anim->palette * 16) + anim->firstColor, colors, anim->colorCount, CPU);
}

static void updatePaletteAnim(const PaletteAnim *anim)
{
    const u16 delay = (anim->frameDelay > 0) ? anim->frameDelay : 1;

    waterfallTick++;
    if (waterfallTick < delay)
        return;

    waterfallTick = 0;
    waterfallFrame++;

    if (waterfallFrame >= anim->frameCount)
        waterfallFrame = 0;

    applyPaletteAnimFrame(anim, waterfallFrame);
}

int main(bool hardReset)
{
    (void) hardReset;

    VDP_setScreenWidth320();
    VDP_setScreenHeight224();
    PAL_setPalette(PAL0, bgPalette, CPU);
    PAL_setPalette(PAL1, spritePalette, CPU);
    VDP_loadTileData(bgTiles, TILE_VRAM_BG, BG_TILE_COUNT, CPU);
    VDP_loadTileData(playerTiles, TILE_VRAM_PLAYER, 4, CPU);
    drawBackground();

    VDP_resetSprites();
    updatePlayer();
    VDP_updateSprites(1, CPU);
    applyPaletteAnimFrame(&waterfallAnim, 0);

    while (TRUE)
    {
        updatePlayer();
        updatePaletteAnim(&waterfallAnim);
        VDP_updateSprites(1, CPU);
        SYS_doVBlankProcess();
    }

    return 0;
}
