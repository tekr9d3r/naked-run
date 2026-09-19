# Naked Run

A running app for Garmin watches that records everything and shows you
nothing. Outdoor running only — it will not start without a GPS fix.

It starts an ordinary FIT-recorded run — GPS, pace, heart rate, distance,
cadence — so the activity lands in Garmin Connect exactly like one started
from the watch's own Run app. What's different is the screen during the run:
no pace, no distance, no time, no heart rate. Just a short line of text that
changes every few minutes, and a blinking red light telling you it's
recording.

The numbers all arrive at once, on the summary screen, after you stop.

**We track it. You just run.**

## The loop

1. **Start screen** — the footprint mark, the wordmark, the tagline. While
   there's no fix, `WAIT FOR GPS` and three sweeping dots sit at the top; once
   there is one they vanish, since "GPS is fine" isn't news worth a line of
   type. A short arc on the bezel at two o'clock marks the physical START
   button — grey while waiting, amber once a press will start a run.
2. **GPS gate** — only if you press SELECT before a fix has landed. Holds until
   it does, then starts the run by itself. BACK cancels.
3. **Run screen** — one quote, centred and set as large as the glass allows,
   plus `( ) REC` near the bottom, the light blinking once a second. Nothing
   else. The quote changes every 7 minutes.
4. **Stop** — MENU or BACK opens the standard in-activity menu: Resume, End
   Run, Discard Run. Ending pauses nothing and loses nothing; discarding asks
   for confirmation first.
5. **Summary screen** — RUN COMPLETE, total time as the hero, then distance,
   avg pace, avg HR and max HR in a 2x2 grid.

SELECT mid-run pauses. The paused screen keeps the quote where it was, dimmed,
and swaps the recording row for the word PAUSED — still no numbers, because a
pause is not a moment to sneak a split in.

**The recording light is the one red in the app**, so it never stops meaning
"this run is being recorded". It blinks rather than fades: a recording light
is a binary thing, a MIP panel would band a fade anyway, and the hard step is
what proves the clock behind it is still running — a frozen app and a
motionless indicator look identical. The earlier version was an amber dot
shading through three brightness steps, which asked the runner to decode a
colour and couldn't say what it was the status *of*. On pause the light does
not merely stop, it disappears; a light that has stopped moving is ambiguous,
and that is the one distinction on this screen that has to be unmistakable.

## Why the run screen is empty in the strong sense

`RunScreen.mc` never calls `Activity.getActivityInfo()`. The live data isn't
fetched and hidden, or drawn small, or guarded behind a flag — it is simply
not read. That is the only version of this promise that a later edge-case edit
can't quietly erode by adding "just one" field.

The only number the run screen has access to is the controller's tick count,
and it uses it for two things: deciding when to change the quote, and blinking
the recording light.

## The GPS gate

A run cannot be started without a usable fix.

This matters more here than in a normal run app. Everywhere else a missing fix
announces itself — distance sits at zero and you notice within a minute. On a
screen with no numbers the two cases look identical, so the run would look
perfectly healthy right up until the summary showed nothing. There is no
*during* in which to catch it, so the check happens before.

- The receiver is switched on when the **app opens**, not when the run starts,
  so it acquires while you're reading the wordmark. Most of the time the fix is
  already there and the gate never appears.
- `GpsQuality.isReady()` opens at `QUALITY_USABLE` or better. `QUALITY_GOOD`
  would leave someone waiting under tree cover for a bar that may never come.
- Press SELECT early and you land on the gate, which **starts the run by itself
  the moment the fix lands** — the intent was already given, so you shouldn't
  have to press again while standing in the cold.
- There is no override. Starting anyway is the exact outcome the gate exists to
  prevent.

The gate shows no accuracy value and no satellite count on purpose. Those would
be the first data fields in the app, and they'd teach the habit of looking at
the watch that everything else here is trying to break. A sweep of dots says
"working on it", which is all that's actionable — wait, or walk into clearer
sky.

**This app is for outdoor running only, by design.** Treadmill and indoor runs
will never get a fix and so can never start, and that is a deliberate scope
decision rather than a gap to be filled later. The whole premise is that you
run without looking at numbers because the watch is capturing them — and
without GPS there is no route, no distance and no pace to capture. An indoor
mode would be a different app wearing this one's name.

Say so in the store description: someone who installs this for treadmill use
has been mis-sold, and that is the one complaint the gate cannot answer for
itself.

## Design decisions worth knowing

**One theme, not two.** Connect IQ doesn't expose panel technology, so there's
no honest runtime answer to "am I on AMOLED or MIP?". Rather than guess, the
palette is built to the harder constraint — a 64-colour transflective panel in
daylight — and looks correct on AMOLED as a consequence: true black ground,
flat fills only, no gradients or glow, and every meaning carried by shape or
brightness rather than by two neighbouring hues. Both ambers from the design
brief survive as *roles* rather than as per-device variants: `#F2A93C` is the
accent, `#C9974A` the secondary tier under it.

**The circular safe area is solved, not guessed.** A round watch is a circle,
not a rectangle with rounded corners, and a line of text at 80% of screen
width will hang out of it near the top and bottom while looking fine through
the middle. Since the largest thing in this app is a centred quote that may
wrap to three lines, `Layout.safeHalfWidth()` computes the actual half-chord
of the safe circle at the block's own height, and `Hud.drawQuoteBlock()` wraps
twice — once at the width available at the centre, then again at the narrower
width the block gets once it's been centred and reaches away from the centre
line. Only the second answer stays inside the bezel.

**Everything is fitted at draw time.** Garmin's fonts are a fixed enum whose
members are very different sizes across the device range, so nothing assumes
it fits. Each headline, quote, stat and label steps down font tiers until it
does. That's what lets one composition run from a 176 px Instinct to a 454 px
Venu with no per-device layouts.

**The logo is bare footprints, and it's drawn, not bundled.**
`FootprintMark.mc` builds one right foot in a normalised 44x100 box out of
three rounded slabs (forefoot pad, arch, heel) and five toe dots; a left foot
is the same numbers mirrored, which is why `FootprintPen` carries a mirror
flag rather than there being a second set of coordinates to keep in sync.

Two placements: `drawPair()` staggers a left and a right into a stride for the
start screen and the app icon, and `drawSingle()` draws one print for the
small mark on the summary, where a pair at that size would shrink each toe to
a single pixel.

The proportions are what make it read as a footprint rather than a blob: the
heel is narrower than the forefoot, and the arch slab sits flush with the
*outer* edge while cutting well in on the inner, big-toe side — which is where
a real print's arch is missing. An arch centred between the two leaves a notch
on both sides and the whole thing reads as a keyhole.

`resources/drawables/launcher_icon.svg` is generated from those same numbers
so the store icon can't drift from the in-app mark.

**The summary snapshot is taken before the save, not after.** Once
`Session.save()` runs, `Activity.getActivityInfo()` no longer reports on the
activity that just ended. `RunSummary` freezes the numbers first; the
controller saves second. Missing values (no wrist HR, no paired strap) render
as `--`, never as `0` — a dash is honest, a zero is a claim.

**Time is the hero, not distance.** Total time is the number a runner actually
chose — they decided to go out for forty minutes. Distance, pace and the two
heart rates are the consequences, so they sit underneath at a quarter of the
size.

## Editing the quotes

`source/Quotes.mc`, one array of string literals. Add a line, rebuild, done.

They live there rather than in `strings.xml` because editing the list is the
most likely change anyone will ever make to this app and one file beats two.
The cost is that they aren't localisable; when a second language shows up this
becomes `Rez.Strings.Quote01..NN` and a list of resource ids.

Tone rules so additions stay in key: lowercase, no exclamation marks, no
coach-shouting imperatives, under 40 characters so it still sets large on a
176 px screen. Calm, not cheesy. `Tests.quotesAreShort` enforces the length.

The rotation interval is `RunConstants.QUOTE_INTERVAL_SEC` (420 s). Drop it to
10 while testing in the simulator, or you'll be waiting seven minutes to watch
a line change.

## Project layout

```
source/
  NakedRunApp.mc          app entry; saves an abandoned run on teardown
  RunController.mc        state machine, 1 Hz clock, quote rotation, GPS gate
  RunConstants.mc         states, timings, the rotation interval
  RunView.mc              one persistent view, routed per state
  RunDelegate.mc          SELECT / MENU / BACK
  ActivityMenuDelegate.mc Resume / End Run / Discard Run
  ActivityRecorder.mc     the FIT session, and nothing else
  GpsStatus.mc            fix quality, and the gate's threshold
  RunSummary.mc           frozen stats, captured before the save
  Quotes.mc               the quote list
  Utils.mc                summary formatters (unit-aware)
  Tests.mc                unit tests, compiled in only by -t
  ui/
    ScreenMetrics.mc      screen shape/scale; px() and font tiers
    Layout.mc             per-screen anchors + the circular safe area
    Palette.mc            the single dark theme
    Hud.mc                text measuring, wrapping and fitting
    FootprintMark.mc      the procedural bare-footprint logo
    StartScreen.mc
    AcquiringScreen.mc    the GPS gate
    RunScreen.mc          the quote and the dot (and drawPaused)
    SummaryScreen.mc      hero time + 2x2 grid
```

## Build, test, run

```sh
./build.sh                      # the representative device spread
./build.sh fenix7 venu3         # named devices
./test.sh                       # unit tests, in the simulator
```

`build.sh` defaults to `instinct3amoled50mm fenix7 venu3 venusq2 fr55
fenix7s` — the test watch, a MIP round, a large AMOLED round, the rectangle,
and the smallest screen in the target list. The manifest targets 80 devices.

To run it:

```sh
"$CIQ_SDK/bin/connectiq" &                                   # simulator, once
"$CIQ_SDK/bin/monkeydo" dist/NakedRun-fenix7.prg fenix7
```

`test.sh` needs the simulator already running. Both scripts read `CIQ_SDK`,
`CIQ_KEY` and `JAVA_HOME` from the environment and fall back to the Homebrew
JDK and the SDK 9.2.0 install path.

The signing key in `keys/` is gitignored on purpose. Back it up separately —
losing it means never being able to re-sign an update to the same app identity.

## Permissions

| Permission | Why |
|---|---|
| `Fit` | `ActivityRecording.createSession` — the whole point of the app |
| `Positioning` | GPS for distance, pace and the route track, and the gate |
| `Sensor` | heart rate, including from a paired chest strap |

`FitContributor` is deliberately **not** requested. It's only needed to write
custom FIT fields, and this app writes none — the recording is meant to be
indistinguishable from a native run, so it adds nothing to it.

## v1.1 follow-ups

Scoped out of v1 on purpose, to get the start → run → stop → summary → save
loop solid first:

- **Settings** — rotation interval and quote pack, via `Application.Properties`
  and a `settings.xml`. `QUOTE_INTERVAL_SEC` is already a single constant so
  this is a small change.
- **Quote packs** — themed sets (calm / dry / stoic), selectable on the start
  screen.
- **Per-device theme tuning** — if a reliable AMOLED-vs-MIP signal turns up,
  split the palette rather than shipping one adaptive theme. Not worth
  blocking on.
- **Custom embedded font** — a genuine bold condensed face instead of
  `FONT_SYSTEM_*`, which would make the wordmark and quotes noticeably better
  and costs a `.fnt` per screen size.
- **Long-press for one glance** — an explicit, deliberate peek at elapsed
  time, for the runner who needs to make a train. Arguably against the point
  of the app; worth an argument before building.
