package dev.retro.template;

import sgdk.rescomp.Compiler;
import sgdk.rescomp.Processor;
import sgdk.rescomp.Resource;
import sgdk.tool.FileUtil;

public class PalAnimProcessor implements Processor
{
    @Override
    public String getId()
    {
        return "PALANIM";
    }

    @Override
    public Resource execute(String[] fields) throws Exception
    {
        if (fields.length < 6)
        {
            System.out.println("Wrong PALANIM definition");
            System.out.println("PALANIM name file palette firstColor colorCount [frameDelay]");
            System.out.println("  name       PaletteAnim variable name");
            System.out.println("  file       path to .panim data file");
            System.out.println("  palette    destination palette index (PAL0..PAL3 -> 0..3)");
            System.out.println("  firstColor first palette entry in palette (0..15)");
            System.out.println("  colorCount number of colors to animate per frame");
            System.out.println("  frameDelay number of frames to keep each animation frame (default 4)");
            return null;
        }

        final String id = fields[1];
        final String fileIn = FileUtil.adjustPath(Compiler.resDir, fields[2]);
        final int palette = decodeInt(fields[3]);
        final int firstColor = decodeInt(fields[4]);
        final int colorCount = decodeInt(fields[5]);
        final int frameDelay = (fields.length >= 7) ? decodeInt(fields[6]) : 4;

        Compiler.addResourceFile(fileIn);
        return new PalAnimResource(id, fileIn, palette, firstColor, colorCount, frameDelay);
    }

    private int decodeInt(String value)
    {
        final String text = value.trim();

        if (text.startsWith("0x") || text.startsWith("0X"))
            return Integer.decode(text).intValue();

        return Integer.parseInt(text);
    }
}
