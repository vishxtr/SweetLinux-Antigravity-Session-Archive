# Antigravity Skills Backup & Ecosystem

This directory houses the complete backup of the custom Antigravity AI skills utilized throughout the development, debugging, and release cycle of **SweetLinux**.

## Structure

- **`agents_skills/`**: Core device engineering skills directly invoked during kernel patching, recovery troubleshooting, ADB/Fastboot operations, and Android crash diagnostics.
- **`agent_skills_library/`**: Comprehensive software engineering disciplines, including bug diagnosis, code review, git guardrails, and architectural patterns.

---

## Key Skills Index

### 1. Embedded Android & Hardware Engineering (`agents_skills/`)
| Skill | Trigger Keywords | Description |
|-------|------------------|-------------|
| **`android`** | `adb`, `logcat`, `dumpsys`, `screenshot`, `shell` | Android device management, UI automation, runtime system inspection via ADB. |
| **`android-build`** | `gradle build`, `AOSP`, `LineageOS`, `lunch`, `brunch` | Android OS and app compilation workflows. |
| **`android-fastboot`** | `fastboot`, `flash boot.img`, `bootloader`, `TWRP`, `sideload` | Low-level partition flashing, recovery operations, and bootloader handling. |
| **`crash-analyzer`** | `app crashed`, `debug ANR`, `tombstone`, `native crash` | Tombstone parser, stacktrace demangler, and fatal kernel panic analyzer. |
| **`lineageos`** | `LineageOS`, `repopick`, `vendor/lineage`, `mka bacon` | LineageOS ROM development and device tree synchronization. |
| **`lineageos-rom-inspector`** | `inspect ROM`, `payload.bin`, `extract partition` | ROM ZIP inspection, OTA payload parsing, and partition image validation. |
| **`termux-voice`** | `voice`, `microphone`, `/voice`, `speech to text` | Audio recording and voice synthesis inside the Android Termux environment. |

### 2. Engineering Disciplines (`agent_skills_library/`)
- **`diagnosing-bugs`**: Systematic root-cause isolation and regression tracing.
- **`git-guardrails`**: Enforces atomic commits, conventional commit formatting, and credential leakage prevention.
- **`code-review`**: Static analysis and review checklists for embedded shell, Python, and C/C++ code.
- **`architecture-discipline`**: Layered decoupling between HAL, vendor blobs, and userspace display compositors (Mir/Lomiri).
- **`anti-slop`**: Eliminates unnecessary boilerplate, ensuring clean and maintainable codebase structure.

---

## How to Install Skills in a New AGY Environment

To restore or install these skills into a new Antigravity CLI installation:

```bash
# Copy device engineering skills to ~/.agents/skills
mkdir -p ~/.agents/skills
cp -r agents_skills/* ~/.agents/skills/

# Copy general developer skills to ~/.agent-skills
mkdir -p ~/.agent-skills
cp -r agent_skills_library/* ~/.agent-skills/
```
