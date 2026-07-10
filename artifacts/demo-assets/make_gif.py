from pathlib import Path
from PIL import Image

out = Path(r"D:\HarmonyOS\NewHealthyLife\artifacts\demo-assets")
frames_dir = out / "frames"
files = sorted(frames_dir.glob("*.png"))
images = []
for path in files:
    img = Image.open(path).convert("RGB")
    target_width = 420
    ratio = target_width / img.width
    target_height = int(img.height * ratio)
    images.append(img.resize((target_width, target_height), Image.Resampling.LANCZOS))

if images:
    images[0].save(
        out / "demo-recording.gif",
        save_all=True,
        append_images=images[1:],
        duration=1200,
        loop=0,
        optimize=True
    )
