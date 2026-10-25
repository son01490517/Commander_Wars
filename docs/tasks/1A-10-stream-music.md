# 1A-10 — Stream music instead of decoding whole tracks

- **Status:** Todo
- **Difficulty:** hard
- **Depends on:** 1A-01
- **Context budget:** ~80k tokens

## Goal
In handheld builds, music is decoded incrementally into a ring buffer (a few seconds) instead of decoding the
whole OGG into float samples. Sound effects stay as they are.

## Facts
- Path: `playMusic` (`coreengine/audiomanager.cpp:714`) → `SlotPlayMusic` (`:812`) → `loadMediaForFile`
  (`:871`) → `AudioDecoder::decode` (`coreengine/audiodecoder.cpp:255`). For OGG it tries `decodeOpus` (`:172`)
  and then `decodeOgg` (`:134`).
- `stb_vorbis_decode_memory` (`audiodecoder.cpp:144`) decodes the whole file. `convertAndResample` (`:33-102`)
  makes stereo and resampled copies. That is about 8 bytes per frame resident, ≈ 92 MB for a 4-minute track at
  48 kHz, with a higher peak during decode.
- Mixer: `paCallback` (`audiomanager.cpp:424`) → `mixMusic` (`:281-332`) reads `ms.samples` by frame index
  (`:321`), loop bounds at `:299-300`. One track is resident (`audiomanager.h:263`), swapped at `:896-904`.
  Track end is handled by the 50 ms poll timer (`:154-159`) → `SlotPlayRandom` (`:920-978`).
- Pull APIs already compiled in: `stb_vorbis_open_memory` / `stb_vorbis_get_samples_float_interleaved`
  (`3rd_party/audio_decoders/stb_vorbis.c:268`, `:353`) and `op_read_float_stereo` (`audiodecoder.cpp:202`,
  input rate fixed at 48000, `:218`).

## Design
- A `MusicStream` (new class) owns the compressed file bytes (OGG stays compressed in memory, a few MB) and a
  decoder handle. It fills a lock-free single-producer/single-consumer ring buffer of about 2 s of stereo
  float at the device rate. The fill runs on the existing audio thread's 50 ms timer.
- `mixMusic` reads from the ring buffer. On underrun it outputs silence (never blocks the PortAudio callback).
- Resampling is done per chunk (linear, as now).
- Looping and seeking (`:903`, `:952`) restart or seek the decoder.
- Desktop path unchanged.

## Read list
- `coreengine/audiomanager.h` (whole, about 280 lines)
- `coreengine/audiomanager.cpp:100-170`, `270-340`, `420-480`, `700-980`
- `coreengine/audiodecoder.cpp` (whole, about 280 lines), `audiodecoder.h`
- `3rd_party/audio_decoders/stb_vorbis.c`: only the declarations near lines 250-380

## Files to modify
`coreengine/audiomanager.cpp/.h`, `coreengine/audiodecoder.cpp/.h`, a new `coreengine/musicstream.cpp/.h`,
and `CommanderWarsSources.cmake` (add the new files).

## Out of scope
Sound effects, audio settings UI, codec changes of the files.

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game, and `game.log` shows music playback started (no audio
   init failure). If the Docker ALSA null device prevents playback, add an audio smoke test that decodes one
   track through `MusicStream` into a null sink and logs the bytes produced.
2. `peak_rss_mb` drops versus the previous RAM receipt. Write the size of the largest music file and the drop in the Result.
3. No new `Critical`/`Fatal` lines.
4. Desktop build still compiles: `.handheld/receipts/1A-10-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-10-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-10-build/build.log
tools/handheld/measure-ram.sh -l 1A-10-ram
grep -i "music\|audio\|portaudio" .handheld/receipts/1A-10-ram/game.log | head -40 > .handheld/receipts/1A-10-ram/audio.txt
tools/handheld/build-desktop-check.sh 1A-10-desktop
tools/jev-review.sh 1A-10
```

## Result

## Handoff notes
