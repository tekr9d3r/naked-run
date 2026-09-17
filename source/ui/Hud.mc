import Toybox.Graphics;
import Toybox.Lang;

// Shared text helpers. Nearly all of this is about *measuring before
// drawing*: Garmin's fonts are a fixed enum whose members are wildly
// different sizes across the device range, so a string that sits comfortably
// on a 454 px Venu runs off a 176 px Instinct at the same tier. Every
// headline, quote and stat in this app is fitted at draw time rather than
// assumed to fit.
module Hud {

    // Steps the font tier down until the string fits maxWidth, then draws it
    // centred with its top at y.
    function drawFitCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String, maxWidth as Number) as Void {
        dc.drawText(metrics.centerX, y, fitTier(dc, metrics, tier, text, maxWidth), text,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function fitTier(dc as Graphics.Dc, metrics as ScreenMetrics, tier as Number, text as String, maxWidth as Number) as Graphics.FontType {
        var t = tier;
        while (t > 0 && dc.getTextWidthInPixels(text, metrics.fontFor(t)) > maxWidth) {
            t -= 1;
        }
        return metrics.fontFor(t);
    }

    // Greedy word-wrap - Dc.drawText has none of its own.
    function wrapLines(dc as Graphics.Dc, font as Graphics.FontType, text as String, maxWidth as Number) as Array<String> {
        var lines = [] as Array<String>;
        var words = splitWords(text);
        var line = "";
        for (var i = 0; i < words.size(); i += 1) {
            var candidate = (line.length() == 0) ? (words[i] as String) : (line + " " + words[i]);
            if (line.length() > 0 && dc.getTextWidthInPixels(candidate, font) > maxWidth) {
                lines.add(line);
                line = words[i] as String;
            } else {
                line = candidate;
            }
        }
        if (line.length() > 0) {
            lines.add(line);
        }
        return lines;
    }

    function splitWords(text as String) as Array<String> {
        var words = [] as Array<String>;
        var rest = text;
        var idx = rest.find(" ");
        while (idx != null) {
            if (idx > 0) {
                words.add(rest.substring(0, idx) as String);
            }
            rest = rest.substring(idx + 1, rest.length()) as String;
            idx = rest.find(" ");
        }
        if (rest.length() > 0) {
            words.add(rest);
        }
        return words;
    }

    // The quote. The one piece of type this app exists to show, so it is
    // fitted properly rather than by a fixed width percentage.
    //
    // For each tier from the largest down: wrap at the width available in the
    // middle of the band, see how tall the resulting block is, centre it in
    // the band, then re-wrap at the width available across the block's real
    // top and bottom - which on a round screen is narrower, because the block
    // now reaches away from the centre line. Accept the tier only if the
    // block fits the band vertically *and* every individual line fits the
    // circle at its own height. Otherwise drop a tier and try again.
    //
    // The two-pass wrap matters: on a 416 px round screen "breathe. that's
    // the whole plan." wraps to two lines at the centre width and to three at
    // the width its own top line actually gets, and only the second answer is
    // the one that stays inside the bezel.
    function drawQuoteBlock(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, text as String, bandTop as Number, bandBottom as Number) as Void {
        var bandHeight = bandBottom - bandTop;
        var bandCenter = (bandTop + bandBottom) / 2;

        for (var tier = 4; tier >= 0; tier -= 1) {
            var font = metrics.fontFor(tier);
            var lineH = dc.getFontHeight(font);

            var centerWidth = 2 * layout.safeHalfWidth(metrics, bandCenter, bandCenter);
            var lines = wrapLines(dc, font, text, centerWidth);

            var blockH = lines.size() * lineH;
            var top = bandCenter - blockH / 2;
            lines = wrapLines(dc, font, text, 2 * layout.safeHalfWidth(metrics, top, top + blockH));

            blockH = lines.size() * lineH;
            top = bandCenter - blockH / 2;

            if (tier > 0 && (blockH > bandHeight || !linesFit(dc, metrics, layout, lines, font, top, lineH))) {
                continue;
            }
            drawLines(dc, metrics, lines, font, top, lineH);
            return;
        }
    }

    function linesFit(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, lines as Array<String>, font as Graphics.FontType, top as Number, lineH as Number) as Boolean {
        for (var i = 0; i < lines.size(); i += 1) {
            var lineTop = top + i * lineH;
            if (dc.getTextWidthInPixels(lines[i], font) > layout.safeWidthForLine(metrics, lineTop, lineH)) {
                return false;
            }
        }
        return true;
    }

    function drawLines(dc as Graphics.Dc, metrics as ScreenMetrics, lines as Array<String>, font as Graphics.FontType, top as Number, lineH as Number) as Void {
        for (var i = 0; i < lines.size(); i += 1) {
            dc.drawText(metrics.centerX, top + i * lineH, font, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Largest of Garmin's number fonts that fits the given box. Used for the
    // one hero number in the app, the total time on the summary screen.
    function fitNumberFont(dc as Graphics.Dc, metrics as ScreenMetrics, text as String, maxWidth as Number, maxHeight as Number) as Graphics.FontType {
        var font = biggestNumberFont(metrics);
        while ((dc.getFontHeight(font) > maxHeight || dc.getTextWidthInPixels(text, font) > maxWidth)
                && font != smallerNumberFont(font)) {
            font = smallerNumberFont(font);
        }
        return font;
    }

    function smallerNumberFont(font as Graphics.FontType) as Graphics.FontType {
        if (font == Graphics.FONT_SYSTEM_NUMBER_THAI_HOT) {
            return Graphics.FONT_SYSTEM_NUMBER_HOT;
        } else if (font == Graphics.FONT_SYSTEM_NUMBER_HOT) {
            return Graphics.FONT_SYSTEM_NUMBER_MEDIUM;
        } else if (font == Graphics.FONT_SYSTEM_NUMBER_MEDIUM) {
            return Graphics.FONT_SYSTEM_NUMBER_MILD;
        }
        return font;
    }

    function biggestNumberFont(metrics as ScreenMetrics) as Graphics.FontType {
        if (metrics.scale >= 0.85) {
            return Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
        } else if (metrics.scale >= 0.55) {
            return Graphics.FONT_SYSTEM_NUMBER_HOT;
        }
        return Graphics.FONT_SYSTEM_NUMBER_MEDIUM;
    }
}
