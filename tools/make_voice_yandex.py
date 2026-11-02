"""Voice lines from voice/script.json with Yandex SpeechKit (REST API v1).

SpeechKit follows a "+" before the stressed vowel exactly, so each line's
"stress" field is sent as is (abbreviations already spelled out, e.g.
«эмжэк+а»). The subtitles ("text") are never changed.

After synthesis the take goes through the same chain as make_voice.py:
Гордеев is lowered a little and aged (AGE), placed by fx (inner voice /
aloud), and set to -17 LUFS.

Needs the environment variable YANDEX_API_KEY (a service account API key with
the role ai.speechkit-tts.user) and tts.api.cloud.yandex.net reachable.

    python tools/make_voice_yandex.py --only cs_n1_city cs_n1_go
    python tools/make_voice_yandex.py --prefix cs_n1_ --voice ermil
    python tools/make_voice_yandex.py --only cs_n1_nina --voice zahar --out /tmp/aud
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_voice as mv  # noqa: E402

VOICE = mv.VOICE
URL = "https://tts.api.cloud.yandex.net/speech/v1/tts:synthesize"
RATE = 48000


def tts_text(line: dict) -> str:
    text = line.get("stress") or mv.silero_text(line)
    return text.replace("«", "").replace("»", "").replace("—", ",").strip()


def synth(text: str, voice: str, speed: float, emotion: str, raw: Path) -> None:
    body = {"text": text, "lang": "ru-RU", "voice": voice, "speed": f"{speed:.2f}",
            "format": "lpcm", "sampleRateHertz": str(RATE)}
    if emotion:
        body["emotion"] = emotion
    # curl, not urllib: through the proxy the chunked answer is sometimes cut short.
    cmd = ["curl", "-sS", "--fail", "--retry", "4", "--retry-all-errors", "-H",
           f"Authorization: Api-Key {os.environ['YANDEX_API_KEY']}", URL]
    for k, v in body.items():
        cmd += ["--data-urlencode", f"{k}={v}"]
    pcm = subprocess.run(cmd, capture_output=True, check=True).stdout
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", str(RATE), "-ac", "1",
                    "-i", "-", str(raw)], input=pcm, check=True)


def render(line: dict, out: Path, voice: str, speed: float, pitch: float, emotion: str, age: bool) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        synth(tts_text(line), voice, speed, emotion, raw)
        chain = (f"asetrate={RATE * pitch:.0f},aresample={RATE},atempo={1 / pitch:.4f},"
                 f"{mv.AGE if age else ''}{mv.FX[line.get('fx', 'inner')]},"
                 "adelay=120,apad=pad_dur=0.25,aresample=44100")
        dry = Path(tmp) / "dry.wav"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", chain, "-ac", "1", str(dry)],
                       check=True)
        gain = mv.LOUDNESS - mv.loudness(dry)
        args = {".mp3": ["-c:a", "libmp3lame", "-q:a", "2"], ".wav": []}.get(out.suffix, ["-c:a", "libvorbis", "-q:a", "6"])
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(dry),
                        "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false", *args, str(out)],
                       check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", help="line ids")
    ap.add_argument("--prefix", help="every line whose id starts with this")
    ap.add_argument("--voice", help="SpeechKit voice (default: characters.*.yandex.voice)")
    ap.add_argument("--speed", type=float, help="1.0 is normal, below is slower")
    ap.add_argument("--pitch", type=float, help="below 1 is lower and older")
    ap.add_argument("--emotion", help="neutral / good (voice permitting)")
    ap.add_argument("--out", help="write here instead of voice/ (auditions)")
    ap.add_argument("--ext", default="ogg", help="ogg for the game, mp3 for listening")
    args = ap.parse_args()

    script = json.loads((VOICE / "script.json").read_text(encoding="utf-8"))
    out = Path(args.out) if args.out else VOICE
    out.mkdir(parents=True, exist_ok=True)
    done = []
    for line in script["lines"]:
        if args.only and line["id"] not in args.only:
            continue
        if args.prefix and not line["id"].startswith(args.prefix):
            continue
        cfg = script["characters"].get(line.get("who", "gordeev"), {})
        ya = cfg.get("yandex", {})
        voice = args.voice or ya.get("voice", "filipp")
        speed = args.speed or ya.get("speed", 0.9)
        pitch = args.pitch or ya.get("pitch", 0.94)
        emotion = args.emotion if args.emotion is not None else ya.get("emotion", "")
        path = out / f"{line['id']}.{args.ext}"
        render(line, path, voice, speed, pitch, emotion, cfg.get("tts", {}).get("age", True))
        done.append(line)
        print(line["id"], voice, mv.duration(path))

    if not args.out and args.ext == "ogg":
        # Update only the lines voiced here; every other take keeps its entry.
        index_path = VOICE / "index.json"
        index = json.loads(index_path.read_text(encoding="utf-8")) if index_path.exists() else {}
        for line in done:
            path = VOICE / f"{line['id']}.ogg"
            index[line["text"]] = {"file": f"res://voice/{path.name}", "length": mv.duration(path)}
        index_path.write_text(json.dumps(index, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
