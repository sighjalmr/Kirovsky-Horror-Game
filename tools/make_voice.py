"""Draft voice-over for every line in voice/script.json.

Speaks each line with Silero (ru v5, a male speaker; free for non-commercial
use only) or an open Piper neural voice, then runs it through ffmpeg: aged into an old man (lower, slower, a
slight tremor, duller top), low cut, compression and a small dry room for
the inner voice, loudness to -17 LUFS.
Writes voice/<id>.ogg and voice/index.json (subtitle text -> file and length),
which scripts/voice.gd reads in the game.

These are scratch takes. When the actors' recordings come in, drop them in as
voice/<id>.ogg (same ids) and run this with --index-only.

    pip install torch
    curl -O https://models.silero.ai/models/tts/ru/v5_5_ru.pt
    python tools/make_voice.py --silero v5_5_ru.pt
    python tools/make_voice.py --silero v5_5_ru.pt --only p_kovpak_ask m_vasya

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
    # A voice down the line of the post telephone: narrow band, a little crackle.
    "phone": "highpass=f=380,lowpass=f=3200,acompressor=threshold=-22dB:ratio=4:attack=3:release=80,"
             "aecho=0.6:0.2:8:0.1",
    # Shouted through the plate glass of the front door from the street.
    "glass": "highpass=f=180,lowpass=f=2800,acompressor=threshold=-18dB:ratio=3:attack=5:release=150,"
             "aecho=0.8:0.3:30|70:0.15|0.08",
}


def spoken(line: dict) -> str:
    text = line.get("say", line["text"])
    text = text.replace("«", "").replace("»", "").replace("—", "").strip()
    for word, ph in STRESS.items():
        text = re.sub(rf"(?<![\w-]){word}(?![\w-])", f"[[{ph}]]", text, flags=re.IGNORECASE)
    return text


LOUDNESS = -17.0  # LUFS: clear over the hall without shouting


def loudness(path: Path) -> float:
    out = subprocess.run(["ffmpeg", "-nostats", "-i", str(path), "-af", "ebur128", "-f", "null", "-"],
                         capture_output=True, text=True, check=True).stderr
    return float(re.findall(r"I:\s+(-?[\d.]+) LUFS", out)[-1])


def duration(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True)
    return round(float(out.stdout), 2)


def silero_text(line: dict) -> str:
    # Silero reads Cyrillic with its own stresses; "+" before a vowel forces one.
    text = line.get("say", line["text"])
    return text.replace("«", "").replace("»", "").replace("—", "").replace("№", "номер").strip()


def synth_piper(voice, line: dict, raw: Path, pace: float) -> int:
    from piper import SynthesisConfig
    cfg = SynthesisConfig(length_scale=pace, noise_scale=0.6, noise_w_scale=0.7)
    with wave.open(str(raw), "wb") as w:
        voice.synthesize_wav(spoken(line), w, syn_config=cfg)
    return 22050


def synth_silero(voice, line: dict, raw: Path, pace: float) -> int:
    import torch
    model, speaker = voice
    rate = 48000
    audio = model.apply_tts(text=silero_text(line), speaker=speaker, sample_rate=rate)
    with wave.open(str(raw), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((audio.clamp(-1, 1) * 32767).to(torch.int16).numpy().tobytes())
    return rate


def render(voice, line: dict, out: Path, pitch: float, pace: float, age: bool = True) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        if isinstance(voice, tuple):
            rate = synth_silero(voice, line, raw, pace)
            slow = f"atempo={1 / (pitch * pace):.4f}"
        else:
            rate = synth_piper(voice, line, raw, pace)
            slow = f"atempo={1 / pitch:.4f}"
        chain = (f"asetrate={rate * pitch:.0f},aresample={rate},{slow},"
                 f"{AGE if age else ''}{FX[line.get('fx', 'inner')]},"
                 "adelay=120,apad=pad_dur=0.25,aresample=44100")
        dry = Path(tmp) / "dry.wav"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", chain, "-ac", "1", str(dry)],
                       check=True)
        # One-pass loudnorm leaves short lines quiet, so measure and set the gain.
        gain = LOUDNESS - loudness(dry)
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(dry),
                        "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                        "-c:a", "libvorbis", "-q:a", "6", str(out)], check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", help="Piper .onnx voice for Гордеев")
    ap.add_argument("--silero", help="Silero ru v5 .pt model instead of Piper")
    ap.add_argument("--speaker", help="Silero speaker for every line (default: each character's own, "
                    "see characters.*.tts in script.json)")
    ap.add_argument("--pitch", type=float, help="below 1 is lower and older (default: per character)")
    ap.add_argument("--pace", type=float, help="above 1 is slower (default: per character)")
    ap.add_argument("--only", nargs="*", help="line ids to redo")
    ap.add_argument("--out", help="write the takes here instead of voice/ (auditions)")
    ap.add_argument("--index-only", action="store_true", help="just rebuild index.json from the .ogg files")
    args = ap.parse_args()

    script = json.loads((VOICE / "script.json").read_text(encoding="utf-8"))
    if not args.index_only:
        if args.silero:
            import torch
            model = torch.package.PackageImporter(args.silero).load_pickle("tts_models", "model")
            torch.set_num_threads(4)
        else:
            from piper import PiperVoice
            piper = PiperVoice.load(args.model)
        for line in script["lines"]:
            if args.only and line["id"] not in args.only:
                continue
            # Гордеев is the default; Ковпак, Тамара Ивановна, Вася have their own voices.
            tts = script["characters"].get(line.get("who", "gordeev"), {}).get("tts", {})
            speaker = args.speaker or tts.get("speaker", "eugene")
            pitch = args.pitch or tts.get("pitch", 0.86)
            pace = args.pace or tts.get("pace", 1.12)
            voice = (model, speaker) if args.silero else piper
            out = Path(args.out) if args.out else VOICE
            out.mkdir(parents=True, exist_ok=True)
            render(voice, line, out / f"{line['id']}.ogg", pitch, pace, tts.get("age", True))
            print(line["id"], speaker)

    index = {}
    for line in script["lines"]:
        path = VOICE / f"{line['id']}.ogg"
        if path.exists():
            index[line["text"]] = {"file": f"res://voice/{path.name}", "length": duration(path)}
    (VOICE / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(index)} of {len(script['lines'])} lines voiced")


if __name__ == "__main__":
    main()
