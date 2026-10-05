#!/usr/bin/env python3
"""App Store cards for Trophy Rooms - trophy cabinet identity.

Each card uses a different device composition (angle, offset, scale, count)
so the six read as a set rather than one template repeated.
"""
import subprocess
from pathlib import Path

HERE = Path(__file__).parent
SHOTS = HERE.parent / "shots"
OUT = HERE / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

SIL = {
    "cup": (95, 165, """<path d="M12 6 h71 v27 c0 33 -16 51 -35 51 c-19 0 -36 -18 -36 -51 z"/>
      <path d="M41 84 h13 l6 24 h-25 z"/><rect x="26" y="108" width="43" height="11" rx="3"/>
      <rect x="18" y="119" width="59" height="46" rx="4"/>"""),
    "star": (60, 117, """<polygon points="30,4 37,21 56,22 42,34 46,52 30,42 14,52 18,34 4,22 23,21"/>
      <rect x="24" y="52" width="12" height="42" rx="3"/><rect x="12" y="94" width="36" height="23" rx="4"/>"""),
    "medal": (75, 90, """<circle cx="37" cy="34" r="26"/><rect x="31" y="56" width="12" height="16" rx="3"/>
      <rect x="17" y="72" width="41" height="18" rx="4"/>"""),
    "obelisk": (55, 102, """<rect x="20" y="4" width="15" height="60" rx="4"/>
      <polygon points="27,0 34,12 21,12"/><rect x="10" y="64" width="35" height="16" rx="3"/>
      <rect x="4" y="80" width="47" height="22" rx="4"/>"""),
}


def sil(kind, css, width, fill="#0d0805"):
    vw, vh, inner = SIL[kind]
    h = round(width * vh / vw)
    return (f'<div class="sil" style="{css}"><svg width="{width}" height="{h}" '
            f'viewBox="0 0 {vw} {vh}" fill="{fill}">{inner}</svg></div>')


def device(shot, css, width, radius=54, border=8):
    return (f'<div class="device" style="{css} width:{width}px; border-radius:{radius}px; '
            f'border-width:{border}px;"><img src="file://{SHOTS / shot}"></div>')


SHELL = """<!DOCTYPE html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Anton&family=Yellowtail&display=swap" rel="stylesheet">
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
html, body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ position:relative; background:#241509; font-family:'Anton',sans-serif; }}
.wood {{ position:absolute; inset:0; background:
  repeating-linear-gradient(90deg, transparent 0 216px, rgba(0,0,0,.42) 216px 221px),
  repeating-linear-gradient(90deg, rgba(255,232,190,.020) 0 2px, transparent 2px 7px),
  repeating-linear-gradient(0deg, rgba(0,0,0,.10) 0 3px, transparent 3px 90px),
  linear-gradient(90deg,#241509 0%,#33200f 22%,#2a1a0c 47%,#362211 71%,#241509 100%); }}
.light {{ position:absolute; inset:0; background:
  radial-gradient(ellipse 62% 30% at {LX} {LY}, rgba(255,208,138,.17), transparent 68%),
  radial-gradient(ellipse 95% 85% at 50% 45%, transparent 45%, rgba(10,5,2,.75) 100%); }}
.grain {{ position:absolute; inset:0;
  background-image:radial-gradient(circle, rgba(255,236,205,.035) 1.3px, transparent 1.9px);
  background-size:9px 9px; }}
.glass {{ position:absolute; inset:0; z-index:60; background:
  linear-gradient(115deg, transparent 34%, rgba(239,231,210,.075) 40%, rgba(239,231,210,.02) 47%, transparent 52%),
  linear-gradient(115deg, transparent 58%, rgba(239,231,210,.04) 62%, transparent 66%); }}
.kicker {{ position:absolute; font-family:'Yellowtail',cursive; color:#c9a45c;
  text-shadow:0 4px 22px rgba(0,0,0,.6); z-index:30; }}
.headline {{ position:absolute; font-family:'Anton',sans-serif; text-transform:uppercase;
  color:#efe7d2; line-height:1.04; letter-spacing:1px;
  text-shadow:{SHADOW}px {SHADOW}px 0 rgba(122,26,34,.85); z-index:30; }}
.device {{ position:absolute; border-style:solid; border-color:#a5824a; overflow:hidden; z-index:20;
  box-shadow:0 0 0 2px rgba(43,27,16,.9), 0 40px 90px rgba(0,0,0,.8); }}
.device img {{ width:100%; display:block; }}
.sil {{ position:absolute; z-index:10; }}
.plaque {{ position:absolute; z-index:40; padding:16px 46px 12px;
  background:linear-gradient(180deg,#d9bd85 0%,#b8934e 45%,#8a6a33 100%);
  border-radius:10px; border:3px solid #5c4520;
  box-shadow:0 10px 30px rgba(0,0,0,.65), inset 0 2px 3px rgba(255,240,200,.7);
  font-size:{PLAQUE}px; letter-spacing:11px; text-indent:11px; color:#3a2a12;
  text-transform:uppercase; text-shadow:0 1px 0 rgba(255,240,200,.45); }}
</style></head><body>
<div class="wood"></div><div class="light"></div><div class="grain"></div>
{BODY}
<div class="glass"></div></body></html>"""


def build(name, w, h, body, light=("50%", "-8%"), shadow=7, plaque=42):
    html = SHELL.format(W=w, H=h, BODY=body, LX=light[0], LY=light[1],
                        SHADOW=shadow, PLAQUE=plaque)
    OUT.mkdir(exist_ok=True)
    hp = OUT / f"src-{name}.html"
    hp.write_text(html)
    out = OUT / f"{name}.png"
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--force-device-scale-factor=1",
                    f"--window-size={w},{h}", "--virtual-time-budget=9000",
                    f"--screenshot={out}", f"file://{hp}"], capture_output=True)
    print(f"  {out.name}")


# App Store Connect rejects anything that is not an exact listed size. The
# cards render at the native 6.9"/13" canvas, so the last step downsamples
# them to the 6.5"/12.9" slots the listing actually uses.
UPLOAD_SIZES = {(1320, 2868): (1284, 2778), (2064, 2752): (2048, 2732)}


def make_upload_set():
    dest = HERE / "upload"
    dest.mkdir(exist_ok=True)
    print("resizing for App Store Connect:")
    for src in sorted(OUT.glob("*.png")):
        w = int(subprocess.run(["sips", "-g", "pixelWidth", str(src)],
                               capture_output=True, text=True).stdout.split()[-1])
        h = int(subprocess.run(["sips", "-g", "pixelHeight", str(src)],
                               capture_output=True, text=True).stdout.split()[-1])
        target = UPLOAD_SIZES.get((w, h))
        if target is None:
            print(f"  !! {src.name}: unexpected {w}x{h}, skipped")
            continue
        tw, th = target
        subprocess.run(["sips", "-z", str(th), str(tw), str(src),
                        "--out", str(dest / src.name)], capture_output=True)
        print(f"  {src.name}  {w}x{h} -> {tw}x{th}")


# ---------------------------------------------------------------- iPhone 6.9"
IW, IH = 1320, 2868

# 1 - centred, gentle tilt, bleeding off the bottom
build("iphone-1-library", IW, IH,
      f"""<div class="kicker" style="top:150px; left:0; width:100%; text-align:center;
            font-size:98px; transform:rotate(-2.5deg);">Your library</div>
      <div class="headline" style="top:300px; left:0; width:100%; text-align:center;
            font-size:150px;">Every game.<br>One room.</div>
      {sil('cup','left:40px; bottom:0;',210)}{sil('star','left:250px; bottom:0;',120)}
      {sil('cup','right:40px; bottom:0;',185)}{sil('medal','right:230px; bottom:0;',150)}
      {device('ip-library.png','top:720px; left:50%; transform:translateX(-50%) rotate(-4deg);',900)}
      <div class="plaque" style="bottom:150px; left:50%; transform:translateX(-50%);">Library</div>""")

# 2 - device pushed right and angled, headline owns the left column
build("iphone-2-collection", IW, IH,
      f"""<div class="kicker" style="top:520px; left:70px; font-size:88px;
            transform:rotate(-3deg);">Your shelf</div>
      <div class="headline" style="top:650px; left:70px; width:620px; font-size:132px;">Boxed.<br>Sealed.<br>Tracked.</div>
      {sil('cup','left:60px; bottom:0;',230)}{sil('obelisk','left:290px; bottom:0;',120)}
      {device('ip-collection.png','top:560px; left:46%; transform:rotate(10deg);',860)}
      <div class="plaque" style="bottom:170px; left:70px;">The Collection</div>""",
      light=("72%", "0%"))

# 3 - device entering from the lower left, headline top-right
build("iphone-3-journal", IW, IH,
      f"""<div class="kicker" style="top:200px; right:80px; font-size:88px;
            transform:rotate(-2deg);">Day by day</div>
      <div class="headline" style="top:320px; right:80px; width:700px; text-align:right;
            font-size:130px;">Keep the<br>streak<br>alive.</div>
      {sil('medal','right:70px; bottom:0;',170)}{sil('star','right:270px; bottom:0;',115)}
      {device('ip-journal.png','top:900px; left:-140px; transform:rotate(-12deg);',880)}
      <div class="plaque" style="bottom:140px; right:80px;">Play Journal</div>""",
      light=("28%", "-4%"))

# 4 - two devices, overlapping, mirrored angles
build("iphone-4-logplay", IW, IH,
      f"""<div class="kicker" style="top:140px; left:0; width:100%; text-align:center;
            font-size:94px; transform:rotate(-2.5deg);">One tap</div>
      <div class="headline" style="top:280px; left:0; width:100%; text-align:center;
            font-size:138px;">Log tonight's<br>session.</div>
      {sil('cup','left:30px; bottom:0;',195)}{sil('cup','right:30px; bottom:0;',175)}
      {device('ip-journal.png','top:900px; left:-60px; transform:rotate(-8deg); opacity:.75;',680,44,7)}
      {device('ip-logplay.png','top:760px; left:340px; transform:rotate(5deg);',820)}
      <div class="plaque" style="bottom:130px; left:50%; transform:translateX(-50%);">Quick Log</div>""")

# 5 - oversized close-up, straight on, cropped by the canvas
build("iphone-5-detail", IW, IH,
      f"""<div class="kicker" style="top:150px; left:0; width:100%; text-align:center;
            font-size:92px; transform:rotate(-2deg);">The full story</div>
      <div class="headline" style="top:280px; left:0; width:100%; text-align:center;
            font-size:140px;">Every detail,<br>on record.</div>
      {device('ip-detail.png','top:700px; left:50%; transform:translateX(-50%) rotate(1.5deg);',1180,64,10)}""",
      shadow=8)

# 6 - upright on the shelf, the classic cabinet frame
build("iphone-6-home", IW, IH,
      f"""<div class="kicker" style="top:150px; left:0; width:100%; text-align:center;
            font-size:96px; transform:rotate(-2.5deg);">38 platforms</div>
      <div class="headline" style="top:300px; left:0; width:100%; text-align:center;
            font-size:146px;">28,000 games.<br>One search.</div>
      {sil('cup','left:50px; bottom:0;',215)}{sil('star','left:270px; bottom:0;',125)}
      {sil('medal','left:420px; bottom:0;',150)}{sil('cup','right:50px; bottom:0;',195)}
      {sil('obelisk','right:250px; bottom:0;',120)}
      {device('ip-home.png','top:760px; left:50%; transform:translateX(-50%);',820)}
      <div class="plaque" style="bottom:150px; left:50%; transform:translateX(-50%);">Browse</div>""")

# ------------------------------------------------------------------ iPad 13"
PW, PH = 2064, 2752

build("ipad-1-home", PW, PH,
      f"""<div class="kicker" style="top:130px; left:0; width:100%; text-align:center;
            font-size:96px; transform:rotate(-2deg);">38 platforms</div>
      <div class="headline" style="top:260px; left:0; width:100%; text-align:center;
            font-size:132px;">28,000 games. One search.</div>
      {sil('cup','left:70px; bottom:0;',215)}{sil('star','left:300px; bottom:0;',125)}
      {sil('cup','right:70px; bottom:0;',195)}{sil('medal','right:290px; bottom:0;',150)}
      {device('ipad-home.png','top:620px; left:50%; transform:translateX(-50%) rotate(-2deg);',1500,40,9)}
      <div class="plaque" style="bottom:120px; left:50%; transform:translateX(-50%);">Browse</div>""",
      plaque=44)

build("ipad-2-collection", PW, PH,
      f"""<div class="kicker" style="top:420px; left:110px; font-size:88px;
            transform:rotate(-3deg);">Your shelf</div>
      <div class="headline" style="top:540px; left:110px; width:780px; font-size:126px;">Boxed.<br>Sealed.<br>Tracked.</div>
      {sil('cup','left:90px; bottom:0;',225)}
      {device('ipad-collection.png','top:520px; left:44%; transform:rotate(7deg);',1320,36,9)}
      <div class="plaque" style="bottom:140px; left:110px;">The Collection</div>""",
      light=("70%", "0%"), plaque=44)

build("ipad-3-library", PW, PH,
      f"""<div class="kicker" style="top:150px; right:120px; font-size:90px;
            transform:rotate(-2deg);">Your library</div>
      <div class="headline" style="top:280px; right:120px; width:900px; text-align:right;
            font-size:128px;">Every game.<br>One room.</div>
      {sil('medal','right:100px; bottom:0;',165)}{sil('star','right:300px; bottom:0;',115)}
      {device('ipad-library.png','top:700px; left:-160px; transform:rotate(-6deg);',1420,36,9)}
      <div class="plaque" style="bottom:130px; right:120px;">Library</div>""",
      light=("30%", "-2%"), plaque=44)

build("ipad-4-trophies", PW, PH,
      f"""<div class="kicker" style="top:140px; left:0; width:100%; text-align:center;
            font-size:94px; transform:rotate(-2.5deg);">Your trophy room</div>
      <div class="headline" style="top:270px; left:0; width:100%; text-align:center;
            font-size:130px;">A cabinet worth filling.</div>
      {sil('cup','left:80px; bottom:0;',220)}{sil('obelisk','left:320px; bottom:0;',125)}
      {sil('cup','right:80px; bottom:0;',200)}{sil('star','right:310px; bottom:0;',130)}
      {device('ipad-trophies.png','top:640px; left:50%; transform:translateX(-50%) rotate(2deg);',1460,40,9)}
      <div class="plaque" style="bottom:120px; left:50%; transform:translateX(-50%);">Trophies</div>""",
      plaque=44)

make_upload_set()

print("done")
