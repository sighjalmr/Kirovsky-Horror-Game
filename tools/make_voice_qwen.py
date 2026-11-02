"""Voice every line in voice/script.json with Qwen3-TTS (Apache-2.0).

Each character has a reference take in voice/qwen_refs/<who>_ref.wav, made once
by the VoiceDesign model from the English description in characters.*.qwen.instruct.
Every line is then spoken by the Base model cloning that reference, so a voice
stays the same from line to line.

Stress: Qwen3 reads "+" and the combining acute aloud, but it follows a capital
stressed vowel ("потОм"). Each line's "stress" field marks stresses with "+"
before the vowel ("пот+ом"); here that becomes a capital. Words of one syllable
carry no mark. The subtitles ("text") are never changed.

After synthesis the take goes through the same chain as make_voice.py:
Гордеев is aged (AGE) and placed by fx (inner voice / aloud); the phone and the
door glass get their filters; everyone ends at -17 LUFS.

    pip install qwen-tts soundfile
    python tools/make_voice_qwen.py                      # all lines
    python tools/make_voice_qwen.py --only n1_2245 m_vasya
    python tools/make_voice_qwen.py --design shopper     # (re)make a reference voice
"""

import argparse
import gc
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_voice as mv  # noqa: E402

VOICE = mv.VOICE
BASE = "Qwen/Qwen3-TTS-12Hz-1.7B-Base"
DESIGN = "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign"

# Everyone but Гордеев: a little low cut and gentle compression, no ageing.
PLAIN = "highpass=f=80,acompressor=threshold=-20dB:ratio=2.5:attack=5:release=120"


def qwen_text(line: dict) -> str:
    text = line.get("stress") or line.get("say", line["text"])
    text = re.sub(r"\+(\w)", lambda m: m.group(1).upper(), text)
    text = text.replace("+", "")
    return text.replace("«", "").replace("»", "").replace("—", "").replace("№", "номер").strip()


def finish(who: str, line: dict, wav, rate: int, out: Path) -> None:
    import soundfile as sf
    fx = line.get("fx", "inner")
    if who == "gordeev":
        chain = mv.AGE + mv.FX[fx]
    elif fx in ("phone", "glass"):
        chain = mv.FX[fx]
    else:
        chain = PLAIN
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        sf.write(raw, wav, rate)
        dry = Path(tmp) / "dry.wav"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af",
                        f"{chain},adelay=120,apad=pad_dur=0.25,aresample=44100", "-ac", "1", str(dry)], check=True)
        gain = mv.LOUDNESS - mv.loudness(dry)
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(dry),
                        "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                        "-c:a", "libvorbis", "-q:a", "6", str(out)], check=True)


def load(name: str):
    import torch
    from qwen_tts import Qwen3TTSModel
    torch.set_num_threads(4)
    # bf16 and one model at a time: both in fp32 do not fit in 15 GB.
    return Qwen3TTSModel.from_pretrained(name, device_map="cpu", dtype=torch.bfloat16)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", help="line ids to redo")
    ap.add_argument("--who", nargs="*", help="only these characters")
    ap.add_argument("--design", nargs="*", help="make the reference voice of these characters first")
    ap.add_argument("--out", help="write the takes here instead of voice/ (auditions)")
    args = ap.parse_args()

    script = json.loads((VOICE / "script.json").read_text(encoding="utf-8"))
    cast = script["characters"]
    lines = {l["id"]: l for l in script["lines"]}

    if args.design:
        import soundfile as sf
        design = load(DESIGN)
        for who in args.design:
            q = cast[who]["qwen"]
            ref_line = lines[q["ref_line_id"]] if "ref_line_id" in q else next(
                l for l in script["lines"] if l["who"] == who)
            text = qwen_text(ref_line)
            wavs, rate = design.generate_voice_design(text=text, language="Russian", instruct=q["instruct"])
            sf.write(VOICE / q["ref"], wavs[0], rate)
            q["ref_text"] = text
            print("designed", who, flush=True)
        (VOICE / "script.json").write_text(json.dumps(script, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        del design
        gc.collect()

    base = load(BASE)
    out = Path(args.out) if args.out else VOICE
    out.mkdir(parents=True, exist_ok=True)
    prompts = {}
    for line in script["lines"]:
        who = line.get("who", "gordeev")
        if args.only and line["id"] not in args.only:
            continue
        if args.who and who not in args.who:
            continue
        if who not in prompts:
            q = cast[who]["qwen"]
            prompts[who] = base.create_voice_clone_prompt(ref_audio=str(VOICE / q["ref"]), ref_text=q["ref_text"])
        t0 = time.time()
        wavs, rate = base.generate_voice_clone(text=qwen_text(line), language="Russian",
                                               voice_clone_prompt=prompts[who])
        finish(who, line, wavs[0], rate, out / f"{line['id']}.ogg")
        print(line["id"], who, f"{time.time() - t0:.0f}s", flush=True)

    if not args.out:
        subprocess.run([sys.executable, str(Path(__file__).with_name("make_voice.py")), "--index-only"], check=True)


if __name__ == "__main__":
    main()
