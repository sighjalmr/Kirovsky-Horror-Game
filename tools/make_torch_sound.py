#!/usr/bin/env python3
"""The «жучок» dynamo torch, modelled as the machine it is.

Each squeeze of the lever turns a toothed sector that drives, through a one-way
pawl, a small pinion on the dynamo rotor. The rotor carries a flywheel, so
between squeezes it coasts and slows, and the whine of the plastic gears sags
and rises again with the next squeeze. The script simulates the rotor speed
sample by sample and builds every sound from it:

  * the gear whine: the rotor pinion meshing (10 teeth a turn), with the wobble
    of a cheap, slightly eccentric moulded gear;
  * the magnet poles of the dynamo and its load, a low hum under the whine;
  * the coarse buzz of the lever sector, only while it is driving;
  * gritty plastic tooth noise and air, growing with speed;
  * the lever bottoming out on the bakelite case, the pawl ticking over the
    ratchet as the spring pulls the lever back, the lever stopping open, and
    the faint ring of the return spring;
  * all of it through the hollow bakelite shell (its resonances) and the fist
    round it (high end damped).

Writes sounds/whirr.wav (the seamless loop of steady pumping, two squeezes a
second, each a little different), sounds/torch_on.wav (the first squeeze from
rest, to play before the loop), sounds/torch_off.wav (the lever let go and the
flywheel running down), and scripts/dynamo_curve.gd: how bright the bulb is
through the loop and the first squeeze, so the beam pulses with the sound.

    python3 tools/make_torch_sound.py

Needs Python 3 and numpy.
"""

import os

import numpy as np

from make_sounds import ROOT, SR, Gen, band, modal, save

PERIOD = 0.5         # one squeeze and release, s
SQUEEZE = 0.19       # lever travel closed, s
RELEASE = 0.12       # the spring opening it again, s
GAP = 0.025          # fingers ease off before the spring wins, s
CYCLES = 6           # cycles in the loop: 3 s, so the variation does not repeat soon
PEAK = 70.0          # rotor speed at the end of a full squeeze, rev/s
TAU_ENGAGE = 0.03    # how stiffly the pawl drags the flywheel up, s
TAU_COAST = 0.9      # flywheel spin-down, s
FRICTION = 9.0       # bearing and bulb load, rev/s^2
TEETH = 10           # rotor pinion
SECTOR_RATIO = 9 / 40  # lever sector teeth per rotor pinion tooth
PAWL_TEETH = 14      # ratchet teeth passed while the lever opens
CURVE_RATE = 100     # bulb brightness samples a second in dynamo_curve.gd
SHELL = [(470, 0.016, 0.55), (1240, 0.012, 0.8), (2380, 0.008, 0.5), (3650, 0.006, 0.3), (5100, 0.004, 0.15)]


def lever_speed(t, cyc):
    """Rotor speed the lever would drive at each instant (0 outside squeezes),
    and the times of the clack, the pawl ticks and the open stop."""
    drive = np.zeros_like(t)
    events = []
    for start, k, sq in cyc:
        tt = t - start
        on = (tt >= 0) & (tt < sq)
        # Lever angle 0.5 - 0.5 cos: the speed is a half sine.
        drive[on] = np.maximum(drive[on], PEAK * k * np.sin(np.pi * tt[on] / sq) * 1.06)
        events.append(("clack", start + sq, k))
        r0 = start + sq + GAP
        for j in range(1, PAWL_TEETH + 1):
            # angle runs 1 -> 0 as 0.5 + 0.5 cos(pi u); tooth j passes at angle 1 - j/N
            u = np.arccos(1 - 2 * (j / PAWL_TEETH)) / np.pi
            events.append(("pawl", r0 + u * RELEASE, k))
        events.append(("stop", r0 + RELEASE, k))
    return drive, events


def rotor(drive, w0=0.0):
    """Flywheel speed: dragged up by the pawl while the lever outruns it,
    otherwise coasting down against friction."""
    w = np.empty_like(drive)
    dt = 1.0 / SR
    a_e = dt / TAU_ENGAGE
    for i, d in enumerate(drive):
        if d > w0:
            w0 += (d - w0) * a_e
        else:
            w0 -= (w0 / TAU_COAST + FRICTION) * dt
            if w0 < 0.0:
                w0 = 0.0
        w[i] = w0
    return w


def tones(g, w, drive, loop):
    n = len(w)
    theta = 2 * np.pi * np.cumsum(w) / SR
    s = w / PEAK
    # Pinion mesh whine with harmonics; the moulded gear is a touch eccentric,
    # so the whine wobbles once a turn and once a turn of the big gear.
    wobble = 1 + 0.22 * np.sin(theta + 0.4) + 0.12 * np.sin(theta / 4 + 1.3)
    whine = sum(a * np.sin(k * TEETH * theta + k * 0.7) for k, a in ((1, 1.0), (2, 0.55), (3, 0.32), (4, 0.16), (5, 0.08)))
    x = whine * wobble * s ** 1.3 * 0.3
    # Magnet poles and the load: a duller hum an octave and more below.
    x += (np.sin(4 * theta) + 0.4 * np.sin(8 * theta + 1) + 0.2 * np.sin(12 * theta + 2)) * s ** 1.6 * 0.12
    # The lever's toothed sector, coarse and buzzy, only while it drives.
    engaged = np.clip((drive - w + 6.0) / 6.0, 0, 1)
    engaged = np.convolve(engaged, np.ones(220) / 220, "same")
    ph = (TEETH * SECTOR_RATIO * theta / (2 * np.pi)) % 1.0
    saw = (2 * ph - 1) + 0.5 * np.sign(np.sin(2 * np.pi * ph))
    x += band(saw, 90, 2500, loop) * engaged * s * 0.13
    # Tooth grit: noise ticking at the mesh rate, and air from the fan blades of the rotor.
    grit = band(g.noise(n / SR), 1800, 7500, loop) * np.abs(np.sin(TEETH * theta / 2)) ** 10
    x += grit * s ** 1.5 * 0.5
    x += band(g.noise(n / SR), 900, 6000, loop) * s ** 2.2 * 0.05
    # Something loose inside rattles now and then at speed.
    rattle = (g.rng.random(n) < 4.0 * s / SR) * g.rng.uniform(0.3, 1.0, n)
    x += np.convolve(rattle, modal(g.t(0.006), [(3300, 0.0012, 1.0), (5900, 0.0008, 0.5)]), "same") * 0.05
    return x


def knocks(g, x, events, t0=0.0):
    """Lever hitting the case, pawl ticks, the open stop and the spring."""
    for kind, at, k in events:
        at -= t0
        i = int(at * SR)
        if i < 0 or i >= len(x):
            continue
        j = g.rng.uniform(0.94, 1.06)
        if kind == "clack":
            c = modal(g.t(0.08), [(340 * j, 0.018, 0.5), (1150 * j, 0.012, 1.0), (2630 * j, 0.008, 0.6), (4100 * j, 0.005, 0.35)])
            c += band(g.noise(0.08), 1000, 6500) * np.exp(-g.t(0.08) / 0.0025) * 0.8
            c *= 1.2 * k * g.rng.uniform(0.85, 1.1)
        elif kind == "pawl":
            c = modal(g.t(0.02), [(3200 * j, 0.0025, 1.0), (5200 * j, 0.0016, 0.5), (1900 * j, 0.003, 0.3)])
            c *= 0.075 * g.rng.uniform(0.6, 1.3)
        else:  # the lever at its stop, and the coil spring singing faintly
            c = modal(g.t(0.15), [(1500 * j, 0.008, 1.0), (3400 * j, 0.006, 0.6), (620 * j, 0.012, 0.3)]) * 0.42
            c += modal(g.t(0.15), [(2870 * j, 0.06, 1.0), (4410 * j, 0.04, 0.6), (7020 * j, 0.025, 0.3)]) * 0.03
            c *= g.rng.uniform(0.8, 1.1)
        m = min(len(c), len(x) - i)
        x[i:i + m] += c[:m]
    return x


def shell(x, loop):
    """Hollow bakelite case and the fist around it."""
    ir = np.zeros(int(0.05 * SR))
    ir[0] = 1.0
    ir += modal(np.arange(len(ir)) / SR, SHELL) * 0.035
    if loop:
        y = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, len(x)), len(x))
    else:
        y = np.convolve(x, ir)[:len(x)]
    return band(y, 70, 8500, loop)


def bulb(w, b0=0.0):
    """Filament glow: power goes with the square of the speed, the hot
    tungsten smooths it over a few hundredths of a second."""
    p = (w / PEAK) ** 2
    b = np.empty_like(p)
    a = 1.0 / (SR * 0.06)
    for i, v in enumerate(p):
        b0 += (v - b0) * a
        b[i] = b0
    return b


def cycles(g, n, t0=0.0):
    """Squeeze plan: start time, strength, squeeze length. A man pumping a
    torch is not a metronome, but each loop starts where the last ended."""
    out = []
    for c in range(n):
        out.append((t0 + c * PERIOD + g.rng.uniform(-0.012, 0.012) * (c > 0),
                    g.rng.uniform(0.86, 1.0), SQUEEZE * g.rng.uniform(0.93, 1.07)))
    return out


def make():
    g = Gen("whirr")
    plan = cycles(g, CYCLES)
    # Spin the flywheel up on the last two squeezes first, so the loop starts
    # in the state it ends in.
    warm = [(c * PERIOD, k, q) for c, (_, k, q) in enumerate(plan[-2:])]
    tw = np.arange(int(2 * PERIOD * SR)) / SR
    dw, _ = lever_speed(tw, warm)
    ww = rotor(dw)
    bw = bulb(ww)

    t = np.arange(int(CYCLES * PERIOD * SR)) / SR
    drive, events = lever_speed(t, plan)
    w = rotor(drive, ww[-1])
    # Whole turns of every gear over the loop (a multiple of 4 rotor turns),
    # so no tone jumps at the seam.
    revs = w.sum() / SR
    w *= max(4, round(revs / 4) * 4) / revs
    x = tones(g, w, drive, True)
    # Pawl ticks and stops past the end wrap round to the start.
    events += [(k, a - CYCLES * PERIOD, s) for k, a, s in events if a >= CYCLES * PERIOD]
    x = knocks(g, x, events)
    x = shell(x, True)
    loop_b = bulb(w, bw[-1])
    # One gain for all three files, so they play at the same loudness.
    gain = 0.55 / np.max(np.abs(x))
    save("whirr", x, 0.55)

    # First squeeze from rest, running 40 ms into the loop's first squeeze to
    # cross-fade under it.
    g2 = Gen("torch_on")
    tail = 0.04
    t = np.arange(int((PERIOD + tail) * SR)) / SR
    first = [(0.03, plan[-1][1], plan[-1][2] * 1.05), (PERIOD, plan[0][1], plan[0][2])]
    drive, events = lever_speed(t, first)
    w = rotor(drive)
    x = tones(g2, w, drive, False)
    x = knocks(g2, x, events)
    # The fingers taking up the slack before the lever starts to move.
    x[:int(0.03 * SR)] += band(g2.noise(0.03), 800, 5000) * np.linspace(0, 1, int(0.03 * SR)) * 0.02
    x = shell(x, False)
    n = int(tail * SR)
    x[-n:] *= np.linspace(1, 0, n)
    on_b = bulb(w)
    save("torch_on", x, np.max(np.abs(x)) * gain)

    # Let go: the lever springs open, the flywheel runs down to a stop.
    g3 = Gen("torch_off")
    t = np.arange(int(1.9 * SR)) / SR
    events = [("pawl", 0.01 + np.arccos(1 - 2 * j / PAWL_TEETH) / np.pi * RELEASE * 0.8, 0.9) for j in range(1, PAWL_TEETH + 1)]
    events.append(("stop", 0.01 + RELEASE * 0.8, 0.9))
    w = rotor(np.zeros_like(t), 0.85 * PEAK)
    x = tones(g3, w, np.zeros_like(t), False)
    x = knocks(g3, x, events)
    stop = int(np.argmax(w <= 0.0)) / SR
    x = knocks(g3, x, [("pawl", stop, 1.4)])  # the rotor rocking back on the last tooth
    x = shell(x, False)
    n = int(0.015 * SR)
    x[:n] *= np.linspace(0, 1, n)  # comes in under the loop's fade-out
    save("torch_off", x, np.max(np.abs(x)) * gain)

    return loop_b, on_b


def write_curve(loop_b, on_b):
    step = SR // CURVE_RATE
    top = float(np.max(loop_b))

    def fmt(b):
        return ", ".join("%.3f" % (v / top) for v in b[::step])

    with open(os.path.join(ROOT, "scripts", "dynamo_curve.gd"), "w") as f:
        f.write('''class_name DynamoCurve
## Bulb brightness of the «жучок» (1 = brightest), sampled %d times a second.
## Written by tools/make_torch_sound.py together with sounds/whirr.wav and
## sounds/torch_on.wav, so the beam pulses with the squeezes heard.

const RATE := %d.0
## The first squeeze from rest (sounds/torch_on.wav); the loop starts after it.
const START_LEN := %.3f
const START := [%s]
## Steady pumping, the length of sounds/whirr.wav.
const LOOP := [%s]


static func at(curve: Array, t: float) -> float:
	var i := clampi(int(t * RATE), 0, curve.size() - 1)
	return curve[i]
''' % (CURVE_RATE, CURVE_RATE, PERIOD, fmt(on_b[:int(PERIOD * SR)]), fmt(loop_b)))


if __name__ == "__main__":
    lb, ob = make()
    write_curve(lb, ob)
    print("made whirr, torch_on, torch_off, scripts/dynamo_curve.gd")
