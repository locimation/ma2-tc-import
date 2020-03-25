# MA2 REAPER Marker Sync

[![Watch the video](https://img.youtube.com/vi/CD4CgqdhI_Y/maxresdefault.jpg)](https://youtu.be/CD4CgqdhI_Y)
**Click to play demo video**

## How it works

This plugin connects to REAPER's Web Control interface on port 18080.

(Both MA2 and REAPER must be running on the same PC.)

It then polls REAPER's list of markers twice per second, and if any changes are detected, these are synchronised to MA2's cue trigger times.

Cues and markers are matched by Cue number and Marker number.
