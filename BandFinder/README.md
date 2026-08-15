# Band Finder

A single-purpose iOS BLE scanner for hunting down one specific lost device — built for a
**Xiaomi Smart Band 10 “301A”** dropped at the beach, but it works for any BLE device
whose name you once saw on a pairing screen.

Generic scanners show you a hundred `N/A` rows and no way to tell them apart. This one
filters and ranks, then gives you a hot/cold meter with sound and vibration so you can hunt
with your eyes on the sand.

---

## Read this before you spend an afternoon on it

**Bluetooth does not work under water.** 2.4 GHz is absorbed by seawater at roughly
1000 dB per metre. A band lying on the seabed is undetectable at any distance by any phone
or any app — this is physics, not a limitation of this code.

This app is worth using if the band is:

- on dry or wet sand, buried shallowly,
- washed up at the tideline,
- in a few centimetres of water at low tide, or
- somewhere on shore you didn't expect (a bag, a car, the path back).

It is not worth using if the band is out in the water. Nothing will find it there.

Two more things that decide whether this can work at all:

- **Battery.** A Band 10 that is disconnected keeps advertising and will last days, not
  months. The sooner you search, the better the odds.
- **Advertising behaviour.** An unpaired or disconnected Xiaomi band advertises
  intermittently, and the interval can stretch to several seconds. Stand still for
  10–15 seconds in each spot rather than sweeping quickly.

---

## What it does that a generic scanner can't

### The `301A` trick

Your pairing screen showed `Xiaomi Smart Band 10 301A`. Those four hex characters are the
**last two bytes of the band's Bluetooth MAC address** (`…:30:1A`).

iOS never exposes MAC addresses to apps — that's why every third-party scanner shows a
random-looking UUID instead. But Xiaomi/Huami bands routinely embed their own MAC inside the
manufacturer-specific data of the advertising packet, which iOS *does* hand over. So the app
scans the raw payload bytes for `30 1A` (both byte orders) and scores a hit heavily.

That means it can pick the band out even when the name field is empty.

### Ranked, not listed

Every device gets a 0–100 score from:

| Evidence | Weight |
| --- | --- |
| Name still contains the MAC suffix (`301A`) | +100 |
| Name contains `xiaomi` / `mi band` / `smart band` / `amazfit` / `huami` | +60 |
| Advertising payload contains the MAC suffix bytes | +55 |
| Manufacturer ID `0x0157` (Anhui Huami) | +50 |
| Manufacturer ID `0x038F` / `0x02FF` (Xiaomi) | +45 |
| Advertises Xiaomi service UUID `FEE0` / `FEE1` / `FEE2` / `FE95` / `FDAB` | +45 |

Everything scoring 0 is hidden by default, which collapses a crowded beach down to a few rows.

### Hunting, not just listing

- **Smoothed RSSI.** Raw BLE readings swing ±10 dB packet to packet. An exponential moving
  average makes the meter readable while you walk.
- **Duplicate packets allowed.** The scan uses `CBCentralManagerScanOptionAllowDuplicatesKey`,
  without which iOS reports each device once and the signal strength never updates — the single
  most common reason a homebrew scanner feels dead.
- **Geiger sound + haptics.** Clicks speed up (0.7 Hz → 14 Hz) and rise in pitch as the signal
  strengthens. Phone at knee height, eyes on the ground.
- **Best-here peak hold**, resettable per spot, so you can compare two positions fairly.
- **GPS pins.** Drop a pin at every signal peak; the cluster is your dig site. Exports as CSV.
- **Buzz attempt.** If the device is connectable, the app connects and writes to the Immediate
  Alert service (`0x1802` / `0x2A06`). Many Xiaomi bands refuse this without authentication, so
  a failure proves nothing either way — but it costs one tap.

---

## Building and installing it

You need a Mac with Xcode. There is no way around this — Apple does not allow installing
self-built apps from a phone alone.

1. Copy the `BandFinder` folder to a Mac.
2. Open `BandFinder.xcodeproj`.
3. Select the `BandFinder` target → **Signing & Capabilities** → set **Team** to your own
   Apple ID (add it under Xcode → Settings → Accounts if needed).
4. Change the bundle identifier from `com.example.bandfinder` to something unique, e.g.
   `com.yourname.bandfinder`.
5. Plug in your iPhone, pick it as the run destination, press ⌘R.
6. On the phone: Settings → General → VPN & Device Management → trust your developer certificate.

A free Apple ID gives you a 7-day provisioning profile; the app stops launching after a week
and you rebuild it. A paid developer account gives you a year.

**It must run on a real iPhone.** The Simulator has no Bluetooth radio.

Deployment target is iOS 17.

---

## How to actually search

1. Go at **low tide** — it exposes ground that was under water when you lost it.
2. Open the app, leave the MAC suffix as `301A`, leave "Hide unlikely devices" on.
3. Walk the beach in a **grid**, roughly 5 m between passes. BLE range over open damp sand is
   maybe 10–30 m in the best case and much less if the band is buried or in a puddle.
4. Hold the phone **low**, near the sand. Your own body blocks 2.4 GHz badly — if a candidate
   appears, turn slowly on the spot and watch whether the number rises; your body shadowing the
   signal is a crude direction finder.
5. **Pause 10–15 seconds** anywhere you get a hit. Advertising is intermittent.
6. Tap a candidate, turn on the Geiger sound, and drop a pin at every peak.
7. If nothing scores above 0 after a full sweep, turn off "Hide unlikely devices" and look for
   anything connectable with no name that tracks with your movement.

Also try the obvious: the Mi Fitness / Zepp Life app on the Android phone that was paired to it
has a "last connected location" record, and the band may simply reconnect on its own if you get
within range with that phone.

---

## Files

| File | Purpose |
| --- | --- |
| `BandFinderApp.swift` | App entry point, keeps the screen awake |
| `Models.swift` | Discovery model, vendor identifiers, scoring heuristics |
| `BLEScanner.swift` | CoreBluetooth central, RSSI smoothing, buzz attempt |
| `Feedback.swift` | Geiger click generator (AVAudioEngine) and haptics |
| `SearchLog.swift` | GPS pin logging, persistence, CSV export |
| `ContentView.swift` | Candidate list and hunt settings |
| `TrackerView.swift` | Full-screen hot/cold tracker and pin list |
