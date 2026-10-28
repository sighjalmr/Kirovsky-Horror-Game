#!/usr/bin/env python3
"""Synthesises every sound of «Кировский: Закрытие» into sounds/*.wav
(44.1 kHz, 16 bit, mono) by physical-ish modelling: struck metal as decaying
modal partials, footsteps as heel and toe impacts on tile, the fluorescent
ballast as mains harmonics with buzz. Loops are seamless. Each WAV is a plain
file: replace it with a field recording of the same name and the game uses it.

    python3 tools/make_sounds.py            # all sounds
    python3 tools/make_sounds.py phone hum  # some of them

Needs Python 3 and numpy.
"""

import os
import sys
import wave
import zlib

import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "sounds")
LOOPS = {"hum", "whirr", "phone", "compressor", "drone", "room", "engine"}

IMPORT = """[remap]

importer="wav"
type="AudioStreamWAV"

[deps]

source_file="res://sounds/{name}.wav"

[params]

force/8_bit=false
force/mono=true
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode={loop}
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
"""


class Gen:
    def __init__(self, name):
        self.rng = np.random.default_rng(zlib.crc32(name.encode()))

    def t(self, seconds):
        return np.arange(int(seconds * SR)) / SR

    def noise(self, seconds):
        return self.rng.standard_normal(int(seconds * SR))


def band(x, lo, hi, loop=False, soft=0.3):
    """Band-pass by FFT with soft skirts. Circular when `loop`, so loops stay seamless."""
    n = len(x)
    pad = 0 if loop else int(0.25 * SR)
    X = np.fft.rfft(np.concatenate([x, np.zeros(pad)]))
    f = np.fft.rfftfreq(n + pad, 1 / SR)
    m = np.ones_like(f)
    if lo > 0:
        m *= 1 / (1 + (lo / np.maximum(f, 1e-3)) ** (2 / soft))
    if hi < SR / 2:
        m *= 1 / (1 + (f / hi) ** (2 / soft))
    return np.fft.irfft(X * m, n + pad)[:n]


def env(t, attack, decay):
    return np.minimum(t / max(attack, 1e-5), 1) * np.exp(-np.maximum(t - attack, 0) / decay)


def modal(t, partials, t0=0.0, amp=1.0):
    """Struck object: partials = [(freq, decay s, gain)]."""
    out = np.zeros_like(t)
    tt = t - t0
    on = tt >= 0
    for f, d, g in partials:
        out[on] += g * np.sin(2 * np.pi * f * tt[on]) * np.exp(-tt[on] / d)
    return out * amp


def place(buf, clip, at):
    i = int(at * SR)
    j = min(len(buf), i + len(clip))
    if i < len(buf):
        buf[i:j] += clip[:j - i]
    return buf


def norm(x, peak=0.9):
    return x / max(np.max(np.abs(x)), 1e-9) * peak


def fade(x, seconds=0.01):
    n = int(seconds * SR)
    x = x.copy()
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(name, x, peak=0.9):
    x = norm(x, peak)
    if name not in LOOPS:
        x = fade(x)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    if not os.path.exists(path + ".import"):  # Godot fills in the rest itself; keep its version
        with open(path + ".import", "w") as f:
            f.write(IMPORT.format(name=name, loop=1 if name in LOOPS else 0))


# --- the store -------------------------------------------------------------------

def hum(name):
    """Fluorescent tubes on a choke ballast: 100 Hz with odd buzz harmonics,
    a thin high whine and the occasional tick of a tired starter."""
    g = Gen(name)
    t = g.t(4.0)
    x = np.zeros_like(t)
    for k, a in ((1, 1.0), (2, 0.5), (3, 0.35), (4, 0.12), (5, 0.18), (7, 0.08), (9, 0.05)):
        x += a * np.sin(2 * np.pi * 100 * k * t + k)
    x += 0.15 * np.sin(2 * np.pi * 50 * t)
    buzz = band(g.noise(4.0), 2500, 7000, True) * (0.5 + 0.5 * np.sin(2 * np.pi * 100 * t)) ** 4
    x += norm(buzz, 0.25)
    x += 0.03 * np.sin(2 * np.pi * 15000 * t)
    save(name, x, 0.6)


def click(name):
    """A contactor relay in the panel: hard clack, a bounce, metal ring, thump."""
    g = Gen(name)
    t = g.t(0.6)
    x = np.zeros_like(t)
    for at, a in ((0.0, 1.0), (0.012, 0.4), (0.031, 0.2)):
        burst = band(g.noise(0.004), 1500, 9000)
        place(x, burst * a, at)
    x += modal(t, [(1830, 0.03, 0.4), (3120, 0.02, 0.3), (4730, 0.015, 0.2)])
    x += modal(t, [(120, 0.05, 0.8)])
    x = band(x, 60, 12000)
    # The panel cabinet rings on a little.
    x += band(g.noise(0.6), 300, 1200) * env(t, 0.001, 0.08) * 0.15
    save(name, x)


def whirr(name):
    """The dynamo torch: six squeezes a second spin a flywheel through plastic
    gears, a whine that rises and sags with each squeeze, ratchet clicks, and
    the lever knocking on the case."""
    g = Gen(name)
    t = g.t(1.0)
    phase_sq = (t * 6.0) % 1.0
    speed = 0.55 + 0.45 * np.sin(np.pi * phase_sq) ** 0.7
    f = 210 * speed
    ph = 2 * np.pi * np.cumsum(f) / SR
    tone = sum(a * np.sin(k * ph) for k, a in ((1, 1.0), (2, 0.6), (3, 0.45), (4, 0.25), (6, 0.15), (8, 0.1)))
    # Gear mesh: 12 teeth per turn.
    mesh = np.sin(12 * ph) * 0.35
    x = tone * 0.5 + mesh
    x *= 0.6 + 0.4 * speed
    # Ratchet clicks at the gear rate.
    rate_ph = np.cumsum(f * 0.25) / SR
    ticks = np.diff(np.floor(rate_ph), prepend=0) > 0
    clicks = np.zeros_like(t)
    clicks[ticks] = 1.0
    clicks = band(np.convolve(clicks, g.rng.standard_normal(60) * np.exp(-np.arange(60) / 12), "same"), 2000, 9000, True)
    x += norm(clicks, 0.12)
    # Lever knock at each squeeze.
    for k in range(6):
        place(x, band(g.noise(0.01), 600, 4000) * env(g.t(0.01), 0.0005, 0.003) * 0.3, k / 6 + 0.002)
    x = band(x, 80, 5000, True)
    x[-200:] = x[-200:] * np.linspace(1, 0, 200) + x[:200] * np.linspace(0, 1, 200)
    save(name, x, 0.45)


def step(name, heavy=False):
    """A shoe on ceramic tile: heel strike, body thump, toe roll, a little grit.
    Rubber boots: duller strike, more weight, a soft squeak."""
    g = Gen(name)
    t = g.t(0.45)
    x = np.zeros_like(t)
    heel = band(g.noise(0.03), 700 if heavy else 1200, 5000 if heavy else 9000) * env(g.t(0.03), 0.0005, 0.006 if heavy else 0.004)
    place(x, heel * (0.7 if heavy else 1.0), 0.0)
    thump_f = g.rng.uniform(60, 80) if heavy else g.rng.uniform(95, 130)
    x += modal(t, [(thump_f, 0.05 if heavy else 0.03, 1.2 if heavy else 0.6)])
    # Tile resonance.
    x += modal(t, [(g.rng.uniform(1700, 2300), 0.012, 0.15), (g.rng.uniform(3200, 3900), 0.008, 0.1)])
    toe_at = g.rng.uniform(0.06, 0.09) if not heavy else g.rng.uniform(0.09, 0.12)
    toe = band(g.noise(0.04), 900, 7000) * env(g.t(0.04), 0.002, 0.01)
    place(x, toe * 0.45, toe_at)
    grit = band(g.noise(0.08), 4000, 12000) * env(g.t(0.08), 0.01, 0.025)
    place(x, grit * 0.2, toe_at - 0.01)
    if heavy:
        sq = np.sin(2 * np.pi * np.cumsum(np.linspace(900, 1300, int(0.06 * SR))) / SR) * env(g.t(0.06), 0.01, 0.02)
        place(x, sq * 0.08, toe_at + 0.02)
    save(name, x, 0.85)


def phone(name):
    """Soviet desk phone: an electromechanical bell, the hammer beating two
    gongs at 25 Hz for 0.8 s, then 3.2 s of silence (the Russian cadence)."""
    g = Gen(name)
    t = g.t(4.0)
    x = np.zeros_like(t)
    gongs = [[(1180, 0.5, 1.0), (2740, 0.25, 0.5), (5020, 0.12, 0.3), (7810, 0.06, 0.15)],
             [(1310, 0.5, 1.0), (3050, 0.25, 0.5), (5580, 0.12, 0.3), (8690, 0.06, 0.15)]]
    tt = g.t(1.2)
    strike = [modal(tt, p) for p in gongs]
    for k in range(20):
        at = k / 25
        place(x, strike[k % 2] * (0.8 + 0.2 * g.rng.random()) * (1 - k / 40), at)
        place(x, band(g.noise(0.003), 2000, 9000) * 0.3, at)
    x = band(x, 300, 12000, True)
    save(name, x, 0.8)


def compressor(name):
    """Freezer chest compressor: 50 Hz motor with harmonics, a loose panel
    rattling at 25 Hz and the condenser fan."""
    g = Gen(name)
    t = g.t(4.0)
    x = sum(a * np.sin(2 * np.pi * 50 * k * t + k) for k, a in ((1, 1.0), (2, 0.7), (3, 0.3), (4, 0.2), (6, 0.1)))
    rattle = band(g.noise(4.0), 400, 2500, True) * (np.maximum(np.sin(2 * np.pi * 25 * t), 0) ** 8)
    x += norm(rattle, 0.3)
    x += norm(band(g.noise(4.0), 80, 600, True), 0.35)
    save(name, x, 0.6)


def room(name):
    """Room tone of the empty hall at night: ventilation, the far city, the
    building settling."""
    g = Gen(name)
    t = g.t(12.0)
    x = norm(band(g.noise(12.0), 20, 180, True), 1.0) * 0.8
    x += norm(band(g.noise(12.0), 200, 1500, True), 1.0) * 0.25
    for _ in range(3):  # creaks
        at = g.rng.uniform(0.5, 10.5)
        f0 = g.rng.uniform(250, 500)
        tt = g.t(0.5)
        cr = np.sin(2 * np.pi * np.cumsum(f0 + 60 * np.sin(tt * 30)) / SR) * env(tt, 0.1, 0.12)
        cr *= band(g.noise(0.5), 100, 3000) * 0.5 + 0.5
        place(x, cr * 0.15, at)
    save(name, x, 0.5)


# --- people and things ---------------------------------------------------------

def cloth(name):
    """Lifting a heavy linen cover: three swishes and the fabric crackle."""
    g = Gen(name)
    t = g.t(1.2)
    x = np.zeros_like(t)
    for at, d, a in ((0.0, 0.35, 1.0), (0.3, 0.4, 0.8), (0.7, 0.3, 0.5)):
        tt = g.t(d)
        sw = band(g.noise(d), 400, 5000) * np.sin(np.pi * tt / d) ** 2
        place(x, sw * a, at)
    crack = np.zeros_like(t)
    idx = g.rng.integers(0, len(t), 260)
    crack[idx] = g.rng.standard_normal(260)
    x += band(crack, 2000, 10000) * 2.0 * (1 - t / 1.2)
    save(name, x, 0.8)


def stinger(name):
    """Horror sting: a sub hit, a cluster of low brass that swells, a bowed
    metal screech over it, all decaying into a long tail."""
    g = Gen(name)
    t = g.t(4.0)
    x = modal(t, [(38, 1.2, 1.5), (55, 0.8, 0.8)])
    swell = np.minimum(t / 0.25, 1) * np.exp(-t / 1.6)
    for f in (73.4, 77.8, 110.0, 116.5, 155.6):
        ph = 2 * np.pi * np.cumsum(f * (1 + 0.004 * np.sin(2 * np.pi * 5.3 * t + f))) / SR
        saw = sum(np.sin(k * ph) / k for k in range(1, 14))
        x += saw * swell * 0.25
    bowed = band(g.noise(4.0), 1100, 1400, soft=0.08) + band(g.noise(4.0), 2600, 2900, soft=0.08)
    x += norm(bowed, 0.6) * np.minimum(t / 0.6, 1) * np.exp(-t / 1.2)
    x = band(x, 25, 14000)
    save(name, x, 0.9)


def stab(name):
    """A cleaver blow: the whoosh, a wet heavy thud, bone crunch, a squelch."""
    g = Gen(name)
    t = g.t(0.7)
    x = np.zeros_like(t)
    tw = g.t(0.12)
    whoosh = band(g.noise(0.12), 300, 3000) * np.sin(np.pi * tw / 0.12) ** 3
    place(x, whoosh * 0.4, 0.0)
    hit = 0.11
    x += modal(t, [(62, 0.07, 1.4), (95, 0.05, 0.7)], hit)
    crunch = np.zeros(int(0.12 * SR))
    idx = g.rng.integers(0, len(crunch), 90)
    crunch[idx] = g.rng.standard_normal(90)
    crunch = band(crunch, 300, 3500) * env(g.t(0.12), 0.002, 0.04) * 6
    place(x, crunch, hit)
    tq = g.t(0.35)
    sq = band(g.noise(0.35), 150, 900) * env(tq, 0.01, 0.1)
    sq *= 1 + 0.8 * np.sin(2 * np.pi * (14 + 30 * tq) * tq)
    place(x, sq * 0.8, hit + 0.02)
    save(name, x, 0.95)


def drone(name):
    """Chase music: a low beating drone, wind through a vent, distant metal."""
    g = Gen(name)
    t = g.t(8.0)
    x = np.zeros_like(t)
    for f, a in ((55.0, 1.0), (55.375, 0.9), (82.5, 0.5), (110.125, 0.35), (164.875, 0.2)):
        x += a * np.sin(2 * np.pi * f * t)
    x *= 0.7 + 0.3 * np.sin(2 * np.pi * t / 8.0)
    wind = band(g.noise(8.0), 200, 900, True, 0.2)
    x += norm(wind, 0.4) * (0.6 + 0.4 * np.sin(2 * np.pi * 2 * t / 8.0 + 1))
    for at in (1.5, 5.25):
        place(x, modal(g.t(2.0), [(311, 0.9, 0.3), (743, 0.6, 0.2), (1301, 0.4, 0.15)]), at)
    save(name, x, 0.7)


def chime(name):
    g = Gen(name)
    t = g.t(2.0)
    x = modal(t, [(1568, 1.0, 1.0), (3921, 0.5, 0.3)]) + modal(t, [(1318, 1.0, 1.0), (3295, 0.5, 0.3)], 0.35)
    save(name, x, 0.6)


def breath(name):
    """Somebody breathing on the line: two slow breaths through a telephone
    earpiece (300–3400 Hz), line hiss and mains hum."""
    g = Gen(name)
    t = g.t(4.0)
    x = np.zeros_like(t)
    for at, d, a in ((0.2, 1.1, 1.0), (1.6, 1.3, 0.8), (3.0, 0.9, 0.9)):
        tt = g.t(d)
        b = band(g.noise(d), 400, 700, soft=0.3) * 1.2 + band(g.noise(d), 1200, 1800, soft=0.3) * 0.6 + \
            band(g.noise(d), 2400, 3000, soft=0.3) * 0.3
        place(x, b * np.sin(np.pi * tt / d) ** 1.5 * a, at)
    x += band(g.noise(4.0), 300, 3400) * 0.04
    x += 0.03 * np.sin(2 * np.pi * 50 * t)
    x = band(x, 300, 3400, soft=0.15)
    save(name, x, 0.7)


def clank(name):
    """A steel door or latch: heavy modal metal ringing on."""
    g = Gen(name)
    t = g.t(2.2)
    x = band(g.noise(0.02), 200, 6000) * 2
    x = np.concatenate([x, np.zeros(len(t) - len(x))])
    x += modal(t, [(176, 0.9, 1.0), (413, 0.6, 0.7), (957, 0.4, 0.5), (1733, 0.25, 0.35), (2851, 0.15, 0.2),
                   (4120, 0.08, 0.1)])
    x += modal(t, [(176 * 1.01, 0.9, 0.5)])  # beating
    save(name, x, 0.9)


def keys(name):
    """A bunch of keys on a ring jingling in a coat pocket."""
    g = Gen(name)
    t = g.t(0.9)
    x = np.zeros_like(t)
    for _ in range(26):
        at = g.rng.uniform(0, 0.6) ** 1.3
        f = g.rng.uniform(2400, 6800)
        p = [(f, 0.05, 1.0), (f * 2.76, 0.03, 0.5), (f * 5.4, 0.015, 0.25)]
        place(x, modal(g.t(0.2), p) * g.rng.uniform(0.3, 1.0), at)
    x += band(g.noise(0.9), 2000, 8000) * env(t, 0.05, 0.2) * 0.1
    save(name, x, 0.8)


def pickup(name):
    """Handling something: a soft tap and a short rustle of paper."""
    g = Gen(name)
    t = g.t(0.5)
    x = modal(t, [(240, 0.03, 0.8), (980, 0.015, 0.3)])
    place(x, band(g.noise(0.25), 1500, 8000) * env(g.t(0.25), 0.02, 0.06) * 0.6, 0.05)
    save(name, x, 0.8)


def engine(name):
    """A ГАЗ-24 «Волга» idling in the rain: a four-cylinder at ~800 rpm
    (firing at 27 Hz) with its harmonics, the exhaust burble, the fan belt,
    rain on the bonnet. Loops."""
    g = Gen(name)
    t = g.t(4.0)
    f = 27.0
    wob = 1 + 0.01 * np.sin(2 * np.pi * 0.5 * t)
    ph = 2 * np.pi * f * np.cumsum(wob) / SR
    x = np.zeros_like(t)
    for k, a in ((1, 1.0), (2, 0.6), (3, 0.3), (4, 0.25), (6, 0.1), (8, 0.06)):
        x += a * np.sin(k * ph + k)
    pulses = (0.5 + 0.5 * np.sin(ph)) ** 6
    x += band(g.noise(4.0), 60, 400, True) * pulses * 1.2
    x += band(g.noise(4.0), 1800, 3200, True) * 0.05
    x += band(g.noise(4.0), 3000, 12000, True) * 0.12  # rain
    x = band(x, 25, 6000, True)
    save(name, x, 0.7)


def knock(name):
    """Knuckles on the plate glass of the front door: a dull thud with the
    pane ringing faintly."""
    g = Gen(name)
    t = g.t(0.5)
    x = band(g.noise(0.01), 150, 2500) * env(g.t(0.01), 0.001, 0.003) * 2
    x = np.concatenate([x, np.zeros(len(t) - len(x))])
    x += modal(t, [(180, 0.05, 1.0), (420, 0.04, 0.5), (1320, 0.08, 0.15), (2710, 0.06, 0.08)])
    save(name, x, 0.85)


def cans(name):
    """A pyramid of tins comes down: a dozen tinplate cans hitting the tile and
    each other, then two rolling away and a last one wobbling to rest."""
    g = Gen(name)
    t = g.t(3.5)
    x = np.zeros_like(t)
    for i in range(14):
        at = 0.05 + g.rng.uniform(0, 0.7) ** 1.4
        f = g.rng.uniform(650, 1100)
        p = [(f, 0.06, 1.0), (f * 2.3, 0.04, 0.6), (f * 3.9, 0.025, 0.4), (f * 5.6, 0.015, 0.2)]
        hit = modal(g.t(0.3), p) + band(g.noise(0.3), 1500, 7000) * env(g.t(0.3), 0.0005, 0.01)
        place(x, hit * g.rng.uniform(0.4, 1.0), at)
    for start, dur in ((0.8, 2.0), (1.0, 2.4)):
        tt = g.t(dur)
        roll = band(g.noise(dur), 300, 2500) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * tt) ** 2) * np.exp(-tt / (dur * 0.5))
        place(x, roll * 0.25, start)
    tt = g.t(0.6)
    wob = modal(tt, [(900, 0.05, 1.0), (2100, 0.03, 0.5)])
    for k in range(5):
        place(x, wob * 0.3 * 0.7 ** k, 2.6 + 0.06 * k * (1 - 0.1 * k))
    save(name, x, 0.85)


def lock(name):
    """A key going into a mortise lock, the turn, the bolt shooting home."""
    g = Gen(name)
    t = g.t(0.9)
    x = np.zeros_like(t)
    scrape = band(g.noise(0.18), 2000, 9000) * np.linspace(0.2, 1, int(0.18 * SR)) * 0.25
    place(x, scrape, 0.0)
    place(x, modal(g.t(0.2), [(3100, 0.02, 0.6), (5200, 0.01, 0.3)]), 0.2)
    place(x, band(g.noise(0.25), 800, 4000) * env(g.t(0.25), 0.05, 0.08) * 0.2, 0.3)
    place(x, modal(g.t(0.4), [(640, 0.06, 1.0), (1730, 0.04, 0.6), (3900, 0.02, 0.3)]) +
          band(g.noise(0.4), 500, 6000) * env(g.t(0.4), 0.0005, 0.006), 0.55)
    save(name, x, 0.85)


ALL = {
    "engine": engine, "knock": knock, "cans": cans, "lock": lock,
    "hum": hum, "click": click, "whirr": whirr, "phone": phone, "compressor": compressor, "room": room,
    "cloth": cloth, "stinger": stinger, "stab": stab, "drone": drone, "chime": chime, "breath": breath,
    "clank": clank, "keys": keys, "pickup": pickup,
}
for _i in range(1, 5):
    ALL["step_%d" % _i] = lambda n: step(n)
    ALL["heavy_step_%d" % _i] = lambda n: step(n, True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for nm in sys.argv[1:] or list(ALL):
        ALL[nm](nm)
        print("made", nm)
