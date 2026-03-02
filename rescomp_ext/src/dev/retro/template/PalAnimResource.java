package dev.retro.template;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import sgdk.rescomp.Resource;
import sgdk.rescomp.resource.Bin;
import sgdk.rescomp.tool.Util;
import sgdk.rescomp.type.Basics.Compression;

public class PalAnimResource extends Resource
{
    public final int palette;
    public final int firstColor;
    public final int colorCount;
    public final int frameCount;
    public final int frameDelay;
    public final Bin frameColors;

    private final int hc;

    public PalAnimResource(String id, String file, int palette, int firstColor, int colorCount, int frameDelay) throws Exception
    {
        super(id);

        if ((palette < 0) || (palette > 3))
            throw new IllegalArgumentException("PALANIM: palette must be in range [0..3]");
        if ((firstColor < 0) || (firstColor > 15))
            throw new IllegalArgumentException("PALANIM: firstColor must be in range [0..15]");
        if ((colorCount <= 0) || (colorCount > 16))
            throw new IllegalArgumentException("PALANIM: colorCount must be in range [1..16]");
        if ((firstColor + colorCount) > 16)
            throw new IllegalArgumentException("PALANIM: firstColor + colorCount must be <= 16");

        final short[] parsedFrames = parseFrameColors(file, colorCount);

        this.palette = palette;
        this.firstColor = firstColor;
        this.colorCount = colorCount;
        this.frameCount = parsedFrames.length / colorCount;
        this.frameDelay = Math.max(1, frameDelay);
        this.frameColors = (Bin) addInternalResource(new Bin(id + "_frames", parsedFrames, Compression.NONE, false));

        hc = Arrays.hashCode(parsedFrames) ^ (palette << 24) ^ (firstColor << 16) ^ (colorCount << 8) ^ this.frameDelay;
    }

    @Override
    public int internalHashCode()
    {
        return hc;
    }

    @Override
    public boolean internalEquals(Object obj)
    {
        if (obj instanceof PalAnimResource)
        {
            final PalAnimResource anim = (PalAnimResource) obj;

            return (palette == anim.palette) &&
                   (firstColor == anim.firstColor) &&
                   (colorCount == anim.colorCount) &&
                   (frameCount == anim.frameCount) &&
                   (frameDelay == anim.frameDelay) &&
                   frameColors.equals(anim.frameColors);
        }

        return false;
    }

    @Override
    public List<Bin> getInternalBinResources()
    {
        return Arrays.asList(frameColors);
    }

    @Override
    public int shallowSize()
    {
        return (2 * 6) + 4;
    }

    @Override
    public int totalSize()
    {
        return shallowSize() + frameColors.totalSize();
    }

    @Override
    public void out(ByteArrayOutputStream outB, StringBuilder outS, StringBuilder outH) throws IOException
    {
        outB.reset();

        Util.decl(outS, outH, "PaletteAnim", id, 2, global);
        outS.append("    dc.w    " + palette + "\n");
        outS.append("    dc.w    " + firstColor + "\n");
        outS.append("    dc.w    " + colorCount + "\n");
        outS.append("    dc.w    " + frameCount + "\n");
        outS.append("    dc.w    " + frameDelay + "\n");
        outS.append("    dc.w    0\n");
        outS.append("    dc.l    " + frameColors.id + "\n");
        outS.append("\n");
    }

    private short[] parseFrameColors(String file, int colorCount) throws IOException
    {
        final List<String> lines = Files.readAllLines(Path.of(file), StandardCharsets.UTF_8);
        final List<Short> colors = new ArrayList<>();

        for (String line : lines)
        {
            String cleanLine = line;

            final int commentPos = cleanLine.indexOf('#');
            if (commentPos >= 0)
                cleanLine = cleanLine.substring(0, commentPos);

            cleanLine = cleanLine.trim();
            if (cleanLine.isEmpty())
                continue;

            final String[] fields = cleanLine.split("[\\s,]+");
            if (fields.length != colorCount)
                throw new IllegalArgumentException("PALANIM: each frame line must contain exactly " + colorCount + " colors");

            for (String field : fields)
                colors.add((short) (decodeColor(field) & 0x0FFF));
        }

        if (colors.isEmpty())
            throw new IllegalArgumentException("PALANIM: no frame data found in " + file);

        final short[] result = new short[colors.size()];

        for (int i = 0; i < colors.size(); i++)
            result[i] = colors.get(i).shortValue();

        return result;
    }

    private int decodeColor(String value)
    {
        final String text = value.trim();

        if (text.startsWith("0x") || text.startsWith("0X"))
            return Integer.decode(text).intValue();

        return Integer.parseInt(text, 16);
    }
}
