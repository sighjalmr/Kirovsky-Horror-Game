#!/usr/bin/env python3
"""Synthesises every sound of «Кировский: Закрытие» into sounds/*.wav
(44.1 kHz, 16 bit, mono) by physical-ish modelling: struck metal as decaying
modal partials, the fluorescent ballast as mains harmonics with buzz, the
horror stings as sawing violin sections. Footsteps and the blows are built from
real recordings by tools/make_foley.py, the dynamo torch by
tools/make_torch_sound.py. Loops are seamless. Each WAV is a plain
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
LOOPS = {"hum", "whirr", "phone", "compressor", "drone", "room", "engine", "crowd", "heartbeat", "killer_breath"}

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


def strings(t, notes, start, length, bend=0.0, trem=0.0, voices=3, seed=0):
    """A violin section sawing: detuned sawtooth voices with vibrato and bow
    noise, a hard bow attack, pitch bending by `bend` octaves over the note."""
    rng = np.random.default_rng(seed)
    out = np.zeros_like(t)
    on = (t >= start) & (t < start + length)
    tt = t[on] - start
    e = np.minimum(tt / 0.012, 1) * np.minimum((length - tt) / 0.05, 1)
    if trem:
        e *= 0.6 + 0.4 * np.sin(2 * np.pi * trem * tt) ** 2
    for f in notes:
        for v in range(voices):
            fr = f * 2 ** (bend * tt / length) * (1 + rng.uniform(-0.006, 0.006))
            fr *= 1 + 0.006 * np.sin(2 * np.pi * rng.uniform(5.0, 6.5) * tt + rng.uniform(0, 6))
            ph = 2 * np.pi * np.cumsum(fr) / SR
            saw = sum(np.sin(k * ph) / k for k in range(1, int(9000 / f) + 1))
            out[on] += saw * e / voices
    bow = band(rng.standard_normal(len(t)), 2000, 8000) * 0.15
    out += bow * np.where(on, 1.0, 0.0) * np.abs(out).max(initial=0) * 0.4
    return out


def stinger(name):
    """The killer has seen you: a sub hit and three shrieking violin stabs,
    sliding down a little like the shower scene, over a low brass cluster
    that swells and dies away."""
    g = Gen(name)
    t = g.t(4.0)
    x = modal(t, [(36, 1.2, 1.6), (52, 0.8, 0.8)])
    x += band(g.noise(4.0), 60, 3000) * env(t, 0.002, 0.08) * 0.8
    for k, at in enumerate((0.0, 0.32, 0.64)):
        x += strings(t, (1318.5, 1396.9, 1975.5), at, 0.28, bend=-0.12, seed=k) * 0.55
    swell = np.minimum(t / 0.3, 1) * np.exp(-t / 1.6)
    for f in (73.4, 77.8, 110.0, 116.5, 155.6):
        ph = 2 * np.pi * np.cumsum(f * (1 + 0.004 * np.sin(2 * np.pi * 5.3 * t + f))) / SR
        x += sum(np.sin(k * ph) / k for k in range(1, 14)) * swell * 0.22
    x = band(x, 25, 15000)
    save(name, x, 0.92)


def attack_sting(name):
    """He has you: a slam, then the strings climb screaming in tremolo over a
    scraping of bowed metal and a low cluster, for as long as the blows fall."""
    g = Gen(name)
    t = g.t(5.0)
    x = modal(t, [(32, 1.6, 2.0), (47, 1.0, 1.0), (71, 0.6, 0.4)])
    x += band(g.noise(5.0), 40, 6000) * env(t, 0.001, 0.15) * 1.2
    x += strings(t, (1046.5, 1108.7, 1568.0, 1661.2), 0.0, 3.6, bend=0.6, trem=11.0, voices=4, seed=7) * 0.5
    for f in (55.0, 58.3, 82.4, 87.3):
        ph = 2 * np.pi * np.cumsum(f * (1 + 0.005 * np.sin(2 * np.pi * 4.1 * t + f))) / SR
        x += sum(np.sin(k * ph) / k for k in range(1, 18)) * np.minimum(t / 0.2, 1) * np.exp(-t / 2.2) * 0.25
    scrape = band(g.noise(5.0), 2300, 2700, soft=0.08) + band(g.noise(5.0), 3700, 4300, soft=0.08)
    scrape *= 1 + 0.6 * np.sin(2 * np.pi * (3 + 2 * t) * t)
    x += norm(scrape, 0.35) * np.minimum(t / 0.4, 1) * np.exp(-t / 2.0)
    x *= np.minimum((5.0 - t) / 1.2, 1)
    x = band(x, 25, 15000)
    save(name, x, 0.95)


def swing(name):
    """The cleaver coming down through the air, rising to the blow."""
    g = Gen(name)
    d = 0.22
    tt = g.t(d)
    x = np.zeros_like(tt)
    for lo, hi, a in ((250, 900, 1.0), (900, 2600, 0.6), (2600, 6000, 0.25)):
        x += band(g.noise(d), lo, hi) * a
    shape = np.sin(np.pi * np.minimum(tt / 0.17, 1) * 0.5) ** 3 * np.minimum((d - tt) / 0.05, 1)
    save(name, x * shape, 0.7)


def heartbeat(name):
    """Your own pulse in your ears, 80 beats a minute (play faster for fear):
    the low lub and the softer dub, felt more than heard. Loops."""
    g = Gen(name)
    period = 0.75
    t = g.t(period * 3)
    x = np.zeros_like(t)
    for k in range(3):
        for off, f, a in ((0.0, 52, 1.0), (0.26, 64, 0.6)):
            beat = modal(g.t(0.3), [(f, 0.07, a), (f * 2.1, 0.03, a * 0.3)])
            beat *= np.minimum(g.t(0.3) / 0.012, 1)
            place(x, beat, k * period + off + 0.01)
    save(name, band(x, 25, 400), 0.9)


def ringing(name):
    """The ringing in the ears after the blow, slowly fading."""
    g = Gen(name)
    t = g.t(7.0)
    x = np.sin(2 * np.pi * 5100 * t) + 0.6 * np.sin(2 * np.pi * 5113 * t) + 0.25 * np.sin(2 * np.pi * 3170 * t)
    x += band(g.noise(7.0), 4500, 6000) * 0.15
    x *= np.minimum(t / 0.05, 1) * np.exp(-t / 2.5)
    save(name, x, 0.35)


def killer_breath(name):
    """Him, close: heavy breathing through an open mouth, a wet rasp in the
    throat on every breath out. Loops."""
    g = Gen(name)
    t = g.t(4.5)
    x = np.zeros_like(t)
    for k, at in enumerate((0.05, 1.55, 3.05)):
        di, de = g.rng.uniform(0.5, 0.6), g.rng.uniform(0.7, 0.8)
        ti = g.t(di)
        inh = band(g.noise(di), 900, 1500, soft=0.25) + band(g.noise(di), 2200, 3200, soft=0.25) * 0.6
        place(x, inh * np.sin(np.pi * ti / di) ** 1.5 * 0.45, at)
        te = g.t(de)
        ph = 2 * np.pi * np.cumsum(g.rng.uniform(88, 100) * (1 - 0.1 * te / de)) / SR
        voiced = sum(np.sin(j * ph) / j ** 1.2 for j in range(1, 30))
        exh = band(g.noise(de), 350, 700, soft=0.3) + band(g.noise(de), 1100, 1700, soft=0.3) * 0.6 + \
            band(voiced, 300, 2500) * 0.08
        exh *= 1 + 0.7 * np.sin(2 * np.pi * g.rng.uniform(35, 50) * te)  # the rasp
        place(x, exh * np.sin(np.pi * te / de) ** 1.2, at + di + 0.05)
    save(name, band(x, 120, 6000), 0.8)


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


def crowd(name):
    """A Saturday afternoon in the hall: a dozen voices too far off to make
    out (formant-shaped noise in syllables), till keys clattering and the
    drawer, baskets set down, a wire cart, a cough. Loops."""
    g = Gen(name)
    dur = 14.0
    t = g.t(dur)
    x = np.zeros_like(t)
    for _ in range(12):
        lo = g.rng.uniform(250, 600)
        voice = band(g.noise(dur), lo, lo * g.rng.uniform(2.5, 4.0), True)
        rate = g.rng.uniform(3.5, 5.5)
        syl = (0.5 + 0.5 * np.sin(2 * np.pi * rate * t + g.rng.uniform(0, 6) + 2 * np.sin(2 * np.pi * 0.7 * t))) ** 3
        # Each one talks in phrases with pauses between.
        k = int(g.rng.integers(2, 5))
        phrase = (0.5 + 0.5 * np.sin(2 * np.pi * k / dur * t + g.rng.uniform(0, 6))) ** 2
        x += voice * syl * phrase * g.rng.uniform(0.4, 1.0)
    x = norm(x, 1.0) * 0.6
    x += norm(band(g.noise(dur), 80, 400, True), 1.0) * 0.12
    for _ in range(9):  # till keys
        at = g.rng.uniform(0.2, dur - 1.5)
        for j in range(int(g.rng.integers(3, 7))):
            place(x, modal(g.t(0.1), [(2300, 0.012, 1.0), (4100, 0.008, 0.5)]) * 0.12, at + j * g.rng.uniform(0.11, 0.2))
    for at in (3.1, 9.4):  # the drawer: bell and the slide out
        place(x, modal(g.t(1.0), [(1870, 0.35, 1.0), (4670, 0.2, 0.4)]) * 0.1, at)
        place(x, band(g.noise(0.3), 300, 2500) * env(g.t(0.3), 0.02, 0.1) * 0.15, at + 0.05)
    for at in (1.7, 6.2, 11.8):  # baskets set down
        place(x, modal(g.t(0.4), [(520, 0.05, 1.0), (1210, 0.04, 0.6), (2650, 0.02, 0.3)]) * 0.12, at)
    tt = g.t(3.0)  # a wire cart rolling past
    place(x, band(g.noise(3.0), 900, 5000) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * tt)) * np.sin(np.pi * tt / 3.0) * 0.05, 7.0)
    place(x, band(g.noise(0.35), 200, 1800) * env(g.t(0.35), 0.01, 0.08) * 0.35, 12.6)  # a cough
    save(name, band(x, 60, 7000, True), 0.6)


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
    "engine": engine, "knock": knock, "cans": cans, "lock": lock, "crowd": crowd,
    "hum": hum, "click": click, "phone": phone, "compressor": compressor, "room": room,
    "cloth": cloth, "stinger": stinger, "drone": drone, "chime": chime, "breath": breath,
    "clank": clank, "keys": keys, "pickup": pickup, "attack_sting": attack_sting, "swing": swing,
    "heartbeat": heartbeat, "ringing": ringing, "killer_breath": killer_breath,
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for nm in sys.argv[1:] or list(ALL):
        ALL[nm](nm)
        print("made", nm)
