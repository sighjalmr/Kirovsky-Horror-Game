"""Draft voice-over for every line in voice/script.json.

Speaks each line with an open Piper neural voice, fixes stresses espeak gets
wrong, then runs it through ffmpeg: aged into an old man (lower, slower, a
slight tremor, duller top), low cut, compression and a small dry room for
the inner voice, loudness to -13 LUFS.
Writes voice/<id>.ogg and voice/index.json (subtitle text -> file and length),
which scripts/voice.gd reads in the game.

These are scratch takes. When the actors' recordings come in, drop them in as
voice/<id>.ogg (same ids) and run this with --index-only.

    pip install piper-tts
    python tools/make_voice.py --model path/to/ru_RU-dmitri-medium.onnx
"""

import argparse
import json
import re
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOICE = ROOT / "voice"

# espeak-ng puts these stresses in the wrong place.
STRESS = {
    "сорок": "sˈorʌk",
    "лукина": "ɭukʲˈinʌ",
    "полосы": "pˈoɭʌsy",
    "что-то": "ʃtˈotʌ",
}

# An old man's voice: a shaky tremor in loudness, a fuller chest and the top
# end gone dull. Pitch vibrato and a 3 kHz cut made the words mushy.
AGE = "tremolo=f=5:d=0.2,lowpass=f=7000,equalizer=f=250:t=q:w=1:g=2,"

FX = {
    # Inside his head: close, dry, a touch of room.
    "inner": "highpass=f=90,lowpass=f=9000,acompressor=threshold=-20dB:ratio=3:attack=5:release=120,"
             "aecho=0.8:0.25:18|31:0.12|0.07",
    # Said aloud into the phone at the post: more of the hall around him.
    "aloud": "highpass=f=110,acompressor=threshold=-18dB:ratio=3:attack=5:release=150,"
             "aecho=0.8:0.4:45|90|140:0.18|0.12|0.07",
}


def spoken(line: dict) -> str:
    text = line.get("say", line["text"])
    text = text.replace("«", "").replace("»", "").replace("—", "").strip()
    for word, ph in STRESS.items():
        text = re.sub(rf"(?<![\w-]){word}(?![\w-])", f"[[{ph}]]", text, flags=re.IGNORECASE)
    return text


def duration(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True)
    return round(float(out.stdout), 2)


def render(voice, line: dict, out: Path, pitch: float, pace: float) -> None:
    from piper import SynthesisConfig
    cfg = SynthesisConfig(length_scale=pace, noise_scale=0.6, noise_w_scale=0.7)
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        with wave.open(str(raw), "wb") as w:
            voice.synthesize_wav(spoken(line), w, syn_config=cfg)
        rate = 22050
        chain = (f"asetrate={rate * pitch:.0f},aresample={rate},atempo={1 / pitch:.4f},"
                 f"{AGE}{FX[line.get('fx', 'inner')]},"
                 "adelay=120,apad=pad_dur=0.25,loudnorm=I=-13:TP=-1:LRA=7,aresample=44100")
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", chain,
                        "-ac", "1", "-c:a", "libvorbis", "-q:a", "6", str(out)], check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", help="Piper .onnx voice for Гордеев")
    ap.add_argument("--pitch", type=float, default=0.86, help="below 1 is lower and older")
    ap.add_argument("--pace", type=float, default=1.22, help="above 1 is slower")
    ap.add_argument("--only", nargs="*", help="line ids to redo")
    ap.add_argument("--index-only", action="store_true", help="just rebuild index.json from the .ogg files")
    args = ap.parse_args()

    script = json.loads((VOICE / "script.json").read_text(encoding="utf-8"))
    if not args.index_only:
        from piper import PiperVoice
        voice = PiperVoice.load(args.model)
        for line in script["lines"]:
            if args.only and line["id"] not in args.only:
                continue
            render(voice, line, VOICE / f"{line['id']}.ogg", args.pitch, args.pace)
            print(line["id"])

    index = {}
    for line in script["lines"]:
        path = VOICE / f"{line['id']}.ogg"
        if path.exists():
            index[line["text"]] = {"file": f"res://voice/{path.name}", "length": duration(path)}
    (VOICE / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(index)} of {len(script['lines'])} lines voiced")


if __name__ == "__main__":
    main()
