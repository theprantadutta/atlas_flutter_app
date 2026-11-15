# Atlas Play Store video

`atlas-promo-landscape.mp4` (1920x1080, 30 fps, about 94 s) is the video for the
Play listing. Upload it to YouTube and put the watch URL (not /shorts/) in Play
Console > Store presence > Main store listing > Video. Landscape on purpose: Play
shows the video in a 16:9 slot, and a portrait cut is pillarboxed.

`youtube-thumbnail-1280x720.png` is the feature graphic resized to 1280x720.

## Redoing it

1. Record on a phone with adb, Atlas in light mode, Do Not Disturb on:
   `adb shell screenrecord --bit-rate 8000000 --time-limit 175 /sdcard/recN.mp4`
   Stop with `adb shell pkill -INT screenrecord` (any other way leaves an
   unplayable file), then `adb pull`. Keep each clip under 175 s.
2. Put the clips next to these scripts as rec1.mp4, rec2.mp4, ... and edit
   `scenes.json` (clip, a to b seconds, caption).
3. Music is original, composed in code, so nothing can be claimed:
   `python compose.py dry.wav 96`, then soften and level it with ffmpeg
   (`aecho=0.8:0.55:180|290|420:0.32|0.22|0.14,highpass=f=35,lowpass=f=9000,loudnorm=I=-18:TP=-2:LRA=9`).
4. `python render_atlas.py <ffmpeg.exe> scenes.json music.wav out.mp4`
   (Pillow plus ffmpeg; the imageio_ffmpeg build works.)

Spot-check frames with `ffmpeg -ss T -i out.mp4 -frames:v 1 f.png` before using it.
