import Toybox.Lang;
import Toybox.Math;

// The whole content of the run screen.
//
// These live as plain literals in one array rather than in strings.xml
// because editing the list is the single most likely change anyone will make
// to this app, and a Monkey C array is one file to open and one line to add.
// The cost is that they are not localisable; when a second language shows up
// this becomes Rez.Strings.Quote01..NN and a list of resource ids here.
//
// Tone rules, so additions stay in key: lowercase, no exclamation marks, no
// second person imperative that sounds like a coach shouting, under about 40
// characters so it still sets big on a 176 px screen. Calm, not cheesy.
module Quotes {

    const LINES = [
        "run like no one's counting.",
        "one foot. then the other.",
        "the numbers can wait.",
        "you already started.",
        "breathe. that's the whole plan.",
        "nowhere to be but here.",
        "easy is a pace too.",
        "let the watch do the math.",
        "this is the good part.",
        "keep it boring.",
        "nothing to chase today.",
        "you'll be glad you went."
    ] as Array<String>;

    function count() as Number {
        return LINES.size();
    }

    function at(index as Number) as String {
        var n = LINES.size();
        var i = index % n;
        if (i < 0) {
            i += n;
        }
        return LINES[i];
    }

    // Runs start on a random line rather than always the first, so the app
    // doesn't open with the same sentence every morning.
    function randomStartIndex() as Number {
        return (Math.rand() % LINES.size()).abs();
    }
}
