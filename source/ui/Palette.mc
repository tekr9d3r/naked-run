import Toybox.Graphics;
import Toybox.Lang;

// Dc.setColor() takes a raw 24-bit 0xRRGGBB integer, so these are exact hex
// values rather than approximations through the named Graphics.COLOR_* set.
//
// ONE adaptive dark theme, not two. Connect IQ does not expose panel
// technology, so there is no honest way to ask "am I on AMOLED or MIP?" at
// runtime. Rather than guess, the palette is built to the constraint that is
// harder to satisfy - a 64-colour transflective MIP panel in daylight - and
// then simply looks correct on AMOLED too:
//
//   * true black background, which an AMOLED renders as unlit pixels and a
//     MIP renders as its darkest state; either way it is the highest-contrast
//     ground available on both,
//   * flat fills only, no gradients or glow, since a MIP quantizes a gradient
//     into visible bands,
//   * every meaning carried by a shape or a brightness step, never by two
//     neighbouring hues.
//
// The two ambers from the design brief both survive, but as roles rather than
// as per-device variants: the brighter one is the accent, the duller one is
// the secondary tier under it. That reads as intentional hierarchy on a rich
// display and as two clearly distinct greys' worth of contrast on a flat one.
module Palette {

    const BLACK = 0x000000;       // the background, everywhere
    const CHARCOAL = 0x1C1D1F;    // the only non-black fill: grid rules, dot track

    const AMBER = 0xF2A93C;       // accent: the footprints, the wordmark, the dot
    const AMBER_DIM = 0xC9974A;   // secondary accent: stat labels, the tagline

    const BONE = 0xEFEAE1;        // the quote, and the hero stat
    const GREY = 0x76777A;        // hints, labels, unlit states

    // The recording light, and the only red anywhere in this app - so it
    // never stops meaning "this run is being recorded". Red rather than the
    // amber accent because every camera, every dashcam and every studio door
    // already agreed on what a blinking red light means, and a run screen
    // showing no numbers has nothing else to lean on.
    const RECORD = 0xE5392B;
    const RECORD_OFF = 0x4A1210;  // the dark half of the blink
}
