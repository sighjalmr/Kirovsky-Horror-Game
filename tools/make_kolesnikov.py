"""Участковый Колесников: the Rocketbox avatar Professions/Police_Male_01
(MIT, see models/people/CREDITS.md) redressed as a Soviet militia lieutenant
of 1988.

Takes the avatar from a checkout of github.com/microsoft/Microsoft-Rocketbox
and writes models/people/kolesnikov/: the FBX as it is and 1024 px textures
with the foreign insignia painted out, Soviet shoulder boards (grey, red
piping, two stars) and a red sleeve shield painted in, the trousers darker
than the shirt, the patrol cap greyed (the peaked cap itself is built in
scripts/characters.gd) and the goatee shaved, leaving the moustache.

    git clone --filter=blob:none --sparse https://github.com/microsoft/Microsoft-Rocketbox rb
    git -C rb sparse-checkout set --no-cone 'Assets/Avatars/Professions/Police_Male_01/*'
    pip install opencv-python-headless pillow
    python tools/make_kolesnikov.py rb
"""

import shutil
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "models/people/kolesnikov"


def convert(src: Path) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    shutil.copy(src / "Export/Police_Male_01.fbx", OUT / "kolesnikov.fbx")
    for part in ["body", "head", "equipment", "pistol"]:
        for kind in ["color", "normal"]:
            im = Image.open(src / f"Textures/m220_{part}_{kind}.tga").convert("RGB")
            if im.width > 1024:
                im = im.resize((1024, im.height * 1024 // im.width), Image.LANCZOS)
            im.save(OUT / f"{part}_{kind}.jpg", quality=90)


def shave() -> None:
    im=cv2.imread(str(OUT / 'head_color.jpg')).astype(np.float32)
    h,w=im.shape[:2]
    region=np.zeros((h,w),np.uint8)
    cv2.ellipse(region,(512,482),(104,100),0,0,360,255,-1)
    region[:402,:]=0
    lips=np.zeros_like(region); cv2.ellipse(lips,(512,414),(60,20),0,0,360,255,-1)
    region[lips>0]=0
    patch=im[440:560,330:415]
    patch=np.concatenate([patch,patch[:,::-1]],1)
    patch=np.concatenate([patch,patch[::-1]],0)
    tile=np.tile(patch,(5,4,1))
    fill=np.zeros_like(im); fill[380:380+tile.shape[0],400:400+tile.shape[1]]=tile[:h-380,:w-400]
    # match the fill's brightness to the skin just outside the beard on each side
    ring=cv2.dilate(region,np.ones((31,31)))-cv2.dilate(region,np.ones((9,9)))
    ring[lips>0]=0
    target=im[ring>0].mean(0); got=fill[region>0].mean(0)
    fill=fill*(target/got)
    soft=cv2.GaussianBlur(region.astype(np.float32)/255,(0,0),5)[...,None]
    out=im*(1-soft)+fill*soft
    im = out.clip(0, 255)
    # the patrol cap in the lower half of the texture: blue-grey, darker
    sub = im[560:, :]
    m = cv2.GaussianBlur((sub[..., 0] > sub[..., 2] + 15).astype(np.float32), (0, 0), 1.5)[..., None]
    im[560:] = sub * (1 - m) + sub * np.array([0.66, 0.6, 0.58]) * m
    cv2.imwrite(str(OUT / 'head_color.jpg'), im.astype(np.uint8), [cv2.IMWRITE_JPEG_QUALITY, 92])


def uniform() -> None:
    im=cv2.imread(str(OUT / 'body_color.jpg')).astype(np.float32)
    def patch(x0,y0,x1,y1,dx,dy):
        src=im[y0+dy:y1+dy,x0+dx:x1+dx].copy()
        m=np.zeros((y1-y0,x1-x0),np.float32); cv2.rectangle(m,(4,4),(x1-x0-5,y1-y0-5),1,-1)
        m=cv2.GaussianBlur(m,(0,0),3)[...,None]
        im[y0:y1,x0:x1]=im[y0:y1,x0:x1]*(1-m)+src*m
    patch(108,505,190,568,0,90)        # Afghan flag, left sleeve
    patch(830,495,912,580,-10,95)      # emblem, right sleeve
    # trousers: darker blue-grey than the shirt
    for x0,y0,x1,y1 in [(0,0,312,412),(738,0,1024,412),(328,0,676,328)]:
        sub=im[y0:y1,x0:x1]
        a=(sub.sum(2)>40).astype(np.float32)[...,None]
        im[y0:y1,x0:x1]=sub*(1-a)+sub*np.array([0.66,0.6,0.58])*a
    # shoulder boards: grey, red piping and one red stripe, two small gold stars
    for x0,y0,x1,y1 in [(398,372,448,400),(568,372,628,400)]:
        cv2.rectangle(im,(x0,y0),(x1,y1),(70,62,170),-1)          # red piping (BGR)
        cv2.rectangle(im,(x0+3,y0+3),(x1-3,y1-3),(132,128,124),-1)  # grey board
        cy=(y0+y1)//2
        cv2.line(im,(x0+3,cy),(x1-3,cy),(55,48,165),2)
        for k in (1,2):
            cx=x0+(x1-x0)*k//3
            cv2.circle(im,(cx,cy-5),3,(60,190,230),-1)
    # sleeve patch on the left sleeve where the flag was: a red shield, gold rim
    pts=np.array([[132,512],[166,512],[166,540],[149,556],[132,540]],np.int32)
    cv2.fillPoly(im,[pts],(60,190,225)); cv2.fillPoly(im,[((pts-[[149,534]])*0.78+[[149,534]]).astype(np.int32)],(40,40,150))
    cv2.circle(im,(149,530),5,(60,190,225),-1)
    noise=np.random.default_rng(1).normal(0,3,im.shape)
    im=np.clip(im+noise*0.5,0,255)
    cv2.imwrite(str(OUT / 'body_color.jpg'), im.astype(np.uint8), [cv2.IMWRITE_JPEG_QUALITY, 92])



if __name__ == "__main__":
    convert(Path(sys.argv[1]) / "Assets/Avatars/Professions/Police_Male_01")
    shave()
    uniform()
