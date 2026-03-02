#include <genesis.h>

int main(bool hardReset)
{
    (void) hardReset;

    VDP_setScreenWidth320();
    PAL_setPalette(PAL0, palette_black, CPU);
    VDP_clearPlane(BG_A, TRUE);

    VDP_drawText("SGDK is running", 11, 11);
    VDP_drawText("Build: make", 13, 13);
    VDP_drawText("Test: make test", 11, 14);

    while (TRUE)
    {
        SYS_doVBlankProcess();
    }

    return 0;
}
