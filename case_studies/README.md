# SweetLinux Engineering Case Studies

This directory contains in-depth post-mortem analyses, architectural breakdowns, and root-cause investigations conducted during the development, debugging, and release stabilization of SweetLinux (Halium 10 / Ubuntu Touch for Xiaomi Redmi Note 10 Pro / Pro Max `sweet`/`sweetin`).

---

## Case Study Index

| Document | Core Focus | Key Discoveries & Solutions |
|----------|------------|-----------------------------|
| **[`01_AMOLED_DISPLAY_AND_FLICKER_RESOLUTION.md`](01_AMOLED_DISPLAY_AND_FLICKER_RESOLUTION.md)** | Display Blackout & 1s Flickering | Virtual framebuffer (`video=vfb:enable`) collision with DRM/KMS, `console=tty0` fbcon interference, Samsung EA8076 11-bit PWM brightness scale, adaptive `ubports.sh` panel detection. |
| **[`02_CRTC_VSYNC_STORM_AND_PERFORMANCE.md`](02_CRTC_VSYNC_STORM_AND_PERFORMANCE.md)** | Refresh Rate & VSync Profiling | Naive subshell polling causing DRM vblank spinlock starvation, resolution via 1000ms atomic sampling window, 98% CPU load reduction, 120Hz smooth scrolling. |
| **[`03_TWRP_PACKAGING_AND_ZIP_OFFSET_LIMITS.md`](03_TWRP_PACKAGING_AND_ZIP_OFFSET_LIMITS.md)** | TWRP / Recovery Packaging | 32-bit `minizip` integer seek overflow past 2GB, the **Entry #0 Mandate** (`update-binary` at byte offset 0), `audit_installer.py` validation engine. |
| **[`04_STORAGE_MIGRATION_AND_CLOUD_SYNC.md`](04_STORAGE_MIGRATION_AND_CLOUD_SYNC.md)** | Google Drive FUSE & SD Card Cleanup | Colab FUSE deferred write buffer truncation, atomic sync with `drive.flush_and_unmount()`, multi-folder consolidation into unified `/SweetLinux/`. |
| **[`05_GITHUB_RELEASE_STREAMING_AND_BRANCH_ALIGNMENT.md`](05_GITHUB_RELEASE_STREAMING_AND_BRANCH_ALIGNMENT.md)** | Large Asset Upload & Branch Sync | cURL `--data-binary` OOM crashes on 2GB files vs `curl -T` streaming, resolving default branch divergence (`master` vs `main`). |
