# Changelog

## 2026-03-11

### Add: Zellij tab move keybindings

Added `MoveTab` keybindings to the `tab` mode in `home/assets/zellij/config.kdl`.

- `Ctrl+T` enters tab mode (already existed)
- `h` → `MoveTab "left"` (was `GoToPreviousTab`)
- `n` → `MoveTab "right"` (new binding)

Matches h/n directional convention used elsewhere (h=left, n=right per Dvorak pane movement).
Tab navigation still works via arrow keys and `j`/`k`/`l` in tab mode.

Requires Zellij restart to take effect (no hot-reload).

**Files changed**: `home/assets/zellij/config.kdl`

---

## 2026-03-04

### Add: Block AI features in Zen Browser

Zen is installed via `pkgs.wrapFirefox` in `home/profiles/common.nix`. Added `extraPrefs`
to the `wrapFirefox` call — this writes a `mozilla.cfg` that applies to all profiles
globally (no profile path needed).

Used `lockPref()` so settings cannot be changed from within the browser UI:
```js
lockPref("browser.ai.control.default", "blocked");
lockPref("browser.ai.control.linkPreviewKeyPoints", "blocked");
lockPref("browser.ai.control.pdfjsAltText", "blocked");
lockPref("browser.ai.control.sidebarChatbot", "blocked");
lockPref("browser.ai.control.smartTabGroups", "blocked");
lockPref("browser.ai.control.translations", "blocked");
```

**Files changed**: `home/profiles/common.nix`

---

## 2026-03-04

### Fix: Firefox AI-blocking settings moved to home-manager

**Problem**: `programs.firefox.profiles` was placed in `modules/base.nix` (a NixOS system
module), causing a build error: `The option 'programs.firefox.profiles' does not exist`.

**Root cause**: The NixOS `programs.firefox` module only supports `enable`, `package`, and
`policies`. The `profiles` option is home-manager only.

**Fix**:
- `modules/base.nix` — replaced full Firefox block with `programs.firefox.enable = true;`
- `home/profiles/common.nix` — added `programs.firefox.profiles.default` with AI-blocking settings

Settings applied:
```nix
"browser.ai.control.default" = "blocked";
"browser.ai.control.linkPreviewKeyPoints" = "blocked";
"browser.ai.control.pdfjsAltText" = "blocked";
"browser.ai.control.sidebarChatbot" = "blocked";
"browser.ai.control.smartTabGroups" = "blocked";
"browser.ai.control.translations" = "blocked";
```

**Files changed**: `modules/base.nix`, `home/profiles/common.nix`

---

## 2026-03-01

### Add: Fingerprint reader support

**Fix**: Added to `modules/laptop.nix`:
```nix
services.fprintd.enable = true;
security.pam.services.sddm.fprintAuth = true;
```

Works for `sudo` and SDDM login screen. hyprlock does not support fingerprint auth —
password still required to unlock after idle.

**Enroll fingerprint** (one-time per machine, must use sudo due to no polkit agent in Hyprland session):
```bash
sudo fprintd-enroll yourusername
```

**Files changed**: `modules/laptop.nix`

---

### Add: Framework laptop trackpad configuration

Added touchpad settings to `home/profiles/laptop.nix` (in the `input.touchpad` block):
- `natural_scroll = true` — scroll direction matches content movement
- `clickfinger_behavior = true` — two-finger click = right click, three-finger = middle
- `tap-to-click = false` — disables tap-to-click; physical click only

**Files changed**: `home/profiles/laptop.nix`

---

### Fix: WiFi not reconnecting after sleep

**Problem**: After waking from sleep the laptop lost its network connection.

**Root cause**: The saved WiFi connection was stored in the GNOME Keyring (user-owned,
`psk-flags=1`). NetworkManager can only read keyring secrets after the user logs in and
the keyring unlocks — so at boot and after wake, the password is unavailable.

**Fix**: Converted the saved connection to a system connection by setting
`connection.permissions = ""` and `psk-flags=0` via nmcli, which moves the
credential into `/etc/NetworkManager/system-connections/` (root-owned, mode 600).
This makes the password available before login.

```bash
sudo nmcli connection modify "NetworkName" connection.permissions ""
sudo nmcli connection modify "NetworkName" wifi-sec.psk-flags 0 wifi-sec.psk "password"
```

**Note**: `networking.networkmanager.wifi.powersave = false` was attempted first but
broke networking entirely on this hardware — do not use this option on the Framework.

**Files changed**: `/etc/NetworkManager/system-connections/` (manual, not Nix-managed)

---

### Fix: Waybar battery module not showing charging state

**Problem**: Battery widget showed percentage but no charging indicator or icon when
plugged in.

**Root cause (1)**: Waybar's battery module defaults to looking for an adapter named `AC`.
The Framework exposes `ACAD` (plus four `ucsi-source-psy-USBC000:00X` USB-C ports).
Without explicit `bat`/`adapter` config the module never detected charging.

**Root cause (2)**: The laptop bar in `laptop.nix` had no battery module configuration at
all. The `moduleConfig` in `waybar.nix` (which has all the format strings and icons) is
only merged into the desktop bars via `moduleConfig //`. The laptop bar fell back to
Waybar defaults for every module.

**Fix**: Added explicit battery config and all other module configs to the laptop bar in
`laptop.nix`, adding a `let i = ...` unicode helper matching the one in `waybar.nix`.
Battery config specifies `bat = "BAT1"` and `adapter = "ACAD"`.

Changed charging CSS in `waybar.nix` from gold to green (`#00ff00`) with a green glow.
Charging format uses plug icon (FA `f1e6`) instead of lightning bolt.

**Files changed**: `home/profiles/laptop.nix`, `home/profiles/waybar.nix`

---

## 2026-02-25

### Fix: TablePlus "Store in keyring" not working (no Secret Service daemon)

**Problem**: TablePlus's "Store in keyring" option showed no working keyring backend —
clicking it only offered "Ask every time" or "No password". Passwords could not be
saved between sessions.

**Root cause**: TablePlus relies on the freedesktop Secret Service API. The system had
no daemon providing it — no `gnome-keyring` or `kwallet`. The setup (Hyprland + SDDM)
only had GPG agent and 1Password, neither of which implements the Secret Service API.

**Fix**: Enabled `gnome-keyring` as the Secret Service provider and wired it into the
SDDM PAM session so the keyring unlocks automatically at login:
```nix
services.gnome.gnome-keyring.enable = true;
security.pam.services.sddm.enableGnomeKeyring = true;
```

**Requires**: `nrs` then log out and back in for gnome-keyring to start.

**Files changed**: `modules/desktop.nix`

---

## 2026-02-24

### Show date in Waybar clock

**Problem**: Waybar clock only showed the time (default format), no date.

**Fix**: Added `format = "{:%b %d  %H%M}"` to the clock module in `waybar.nix`.
Displays as e.g. `Feb 24  1321`. Click toggles to `2026-02-24` (existing alt format).

**Files changed**: `home/profiles/waybar.nix`

### Revert StreamController autostart

StreamController autostart via `exec-once = streamcontroller &` caused it to not run
properly in the background. Removed the line from `desktop.nix`.

**Files changed**: `home/profiles/desktop.nix`

**Files changed**: `home/profiles/desktop.nix`

## 2026-02-23

### Fix: Add yourusername to Nix trusted-users for devenv/cachix

**Problem**: `devenv` with `cachix.enable = true` failed with "you are not a trusted user
of the Nix store" when entering a project directory via direnv.

**Root cause**: `nix.settings.trusted-users` was added to `home/yourusername.nix` (a
home-manager file). This is a NixOS system-level option — home-manager silently ignores it.

**Fix**: Moved `nix.settings.trusted-users = [ "root" "yourusername" ]` to
`modules/base.nix` alongside the other `nix.settings` options.

**Files changed**: `modules/base.nix`, `home/yourusername.nix`

### Add libvirtd and virt-manager for VMs

Enabled `virtualisation.libvirtd` and `programs.virt-manager` in `modules/base.nix`.
Added `libvirtd` to user's `extraGroups`. For running NixOS VMs for blog series
companion videos.

**Files changed**: `modules/base.nix`

### Allow unprivileged port binding from port 80+

**Problem**: devenv's Caddy failed with `listen tcp :443: bind: permission denied`.
The `setcap` workaround from Fedora doesn't work on NixOS (read-only Nix store).

**Fix**: Added `boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80` to
`modules/base.nix`. Any user process can now bind ports 80+. Safe on a single-user desktop.

**Files changed**: `modules/base.nix`

---

## 2026-02-21

### Fix: Pin kernel to linuxPackages_6_19 (avoid 6.19.0 freeze bugs)

**Problem**: Two full system freezes requiring hard power-off. First when returning
from idle (mouse moved but nothing loaded/quit), second while adjusting fan curves
(btop froze, browser stopped, nvtop kept reporting).

**Root cause**: Kernel bugs in Linux 6.19.0 — three distinct crashes across two boots:

1. **Boot -2, 16:29**: `BUG: unable to handle page fault` in `sched_mm_cid_exit` —
   scheduler mm_cid (concurrency ID) subsystem, triggered by a `git` process exit.
   Write to kernel address with wrong page permissions.
2. **Boot -2, 17:30**: Cascading NULL pointer deref in `locked_inode_to_wb_and_lock_list`
   via mac80211/mt7921 WiFi stack. Kernel already tainted `[D]=DIE` from crash #1.
3. **Boot -1, 20:11**: `list_del corruption` in `plist_del` via `futex_wake` — linked
   list corruption in the futex subsystem. Cascaded into soft lockups on CPUs #0 and #8
   (160+ seconds stuck in `native_queued_spin_lock_slowpath`). stress-ng started 15 min
   *after* this bug, did not cause it.

All three involve pointer/list corruption in scheduler-adjacent kernel code refactored
in the 6.18→6.19 development cycle.

**Fix**: Changed `boot.kernelPackages` from `pkgs.linuxPackages_latest` to
`pkgs.linuxPackages_6_19`. This pins to the 6.19.x patch series so bug fixes arrive
via 6.19.1, 6.19.2, etc., without auto-bumping to 6.20.0 on `nix flake update`.

**Why not roll back further**: Intel Arc B580 (xe driver) gets significant improvements
each kernel release. 6.18.10 is the confirmed-stable fallback if 6.19.x patches don't
resolve the freezes, but going below 6.18 risks GPU performance/feature loss.

**Note**: The Intel xe driver `PCODE Mailbox failed: -6 Illegal Command` errors at boot
are cosmetic and unrelated — the GPU works fine after init.

**Files changed**: `hosts/b650e-desktop/configuration.nix`

---

### Added: llmster (LM Studio headless daemon + working lms CLI)

**Problem**: The `lms` CLI binary shipped with the nixpkgs `lmstudio` package (v0.4.2)
segfaults immediately on NixOS. strace shows `SEGV_MAPERR` during dynamic linking.

**Root cause**: `patchelf` (used by both nixpkgs and `autoPatchelfHook`) modifies ELF
headers, which shifts embedded data offsets in node/bun single-executable binaries.
Both `lms` (bun-based) and `llmster` (node-based) embed their JS payload inside the
binary — any ELF modification corrupts the embedded data, causing a null pointer
dereference on startup.

**Fix**: Packaged llmster as an inline `stdenv.mkDerivation` with `dontPatchELF`,
`dontStrip`, and `dontFixup` set to `true`. The unmodified binaries work via `nix-ld`
(already enabled in `modules/base.nix`), which provides `/lib64/ld-linux-x86-64.so.2`
and standard shared libraries.

The derivation provides only `bin/llmster` (wrapper script). The working `lms` CLI is
installed by `llmster bootstrap` to `~/.lmstudio/bin/lms`. A home-manager activation
script runs `llmster bootstrap` on every `nrs` automatically.
`home.sessionPath` adds `~/.lmstudio/bin` to PATH so the working `lms` is found before
the broken nixpkgs one.

**Key lesson**: Never use `autoPatchelfHook` or `patchelf` on node.js/bun
single-executable binaries — they embed JS payloads at fixed offsets inside the ELF.
Use `nix-ld` instead by leaving binaries completely unmodified.

**Iterations**:
1. First attempt: `autoPatchelfHook` — segfault (embedded data corrupted)
2. Second attempt: `autoPatchelfHook` with `autoPatchelfIgnoreMissingDeps` for CUDA/libcrypt — built OK but `.bundle/lms` showed bun help instead of lms (bun runtime without embedded context)
3. Third attempt: `lib.hiPrio` to resolve bin/lms collision — `lms` showed bun docs
4. Final: `dontPatchELF + dontFixup + nix-ld` — works, `llmster bootstrap` installs working `lms`

**Files changed**:
- `home/profiles/common.nix` — added `llmster` derivation, `home.sessionPath`,
  `home.activation.llmsterBootstrap`
- `flake.nix` — added `"llmster"` to unfree allowlist

---

## 2026-02-20

### Add: nvtop + intel_gpu_top for GPU monitoring

**Problem**: btop doesn't show Intel Arc B580 GPU data. The Intel xe driver doesn't
expose the standard sysfs entries (`gpu_busy_percent`, `mem_info_*`) that btop reads —
those only exist on the AMD iGPU (card1). btop's GPU box stays empty even with
`shown_boxes = "cpu mem net proc gpu0 gpu1"`.

**Fix**: Added dedicated GPU monitoring tools to `home/profiles/common.nix`:
- `nvtopPackages.intel` — htop-like GPU monitor with Intel xe driver support
- `intel-gpu-tools` — provides `sudo intel_gpu_top` for per-engine GPU stats

**Workaround**: Run `nvtop` in a separate Zellij pane alongside `btop` for full
CPU + GPU monitoring coverage.

**Files changed**: `home/profiles/common.nix`

---

### Add: CoolerControl + fan monitoring

**Problem**: No CPU fan monitoring or control available. The `nct6775` kernel module
(for the ASUS B650E Super I/O chip) wasn't loaded, so no motherboard fan sensors
were exposed.

**Fix**: Added to `modules/desktop.nix`:
- `boot.kernelModules = [ "nct6775" ]` — loads the fan sensor driver at boot
- `programs.coolercontrol.enable = true` — NixOS module that installs the GUI,
  sets up `coolercontrold` daemon, and starts it at boot
- `lm_sensors` added to system packages for the `sensors` command

**Note**: Intel Arc B580 fan control is **not possible** on Linux — the i915/xe driver
exposes fan RPM readings but no PWM control entries. GPU fans are firmware-controlled only.
LACT correctly greys out the controls.

**Files changed**: `modules/desktop.nix`

---

### Switch: Dolphin → Thunar file manager

**Problem**: Dolphin's "Open With" dialog showed an empty application list. The root
cause is KDE's sycoca database which needs a full Plasma session to stay updated —
running `kbuildsycoca6` didn't fix it outside Plasma.

**Fix**: Replaced Dolphin with Thunar (XFCE file manager) which uses the standard XDG
MIME system directly:
- Swapped `kdePackages.dolphin` for `thunar`, `thunar-archive-plugin`, `thunar-volman`,
  `tumbler` (thumbnails) in `home/profiles/common.nix`
- Changed `$fileManager = dolphin` → `thunar` in `home/profiles/desktop.nix`
- Removed Dolphin-specific windowrule, added Thunar progress dialog float rule
  (matches titles starting with Moving/Copying/Deleting/Renaming)

**Deprecation fixes** (same commit):
- `xfce.thunar` → `thunar` (moved to top-level in nixpkgs, same for plugins/tumbler)
- `services.gpg-agent.pinentryPackage` → `services.gpg-agent.pinentry.package`

**Files changed**: `home/profiles/common.nix`, `home/profiles/desktop.nix`

---

### Add: wtype and resizeheic alias

- Added `wtype` to `home/profiles/common.nix` — sends keyboard input on Wayland,
  useful for StreamController command actions
- Added `resizeheic` shell alias: `magick mogrify -format jpg -resize 1920x1080`
  — converts HEIC to JPG and resizes in one command. Usage: `resizeheic *.HEIC`

**Files changed**: `home/profiles/common.nix`

---

### Add: MPD module in Waybar on Dell monitor only

**Problem**: No MPD playback info visible in Waybar. The MPD module config and CSS
existed but the module was never added to the modules list (dropped during the initial
Waybar port).

**Fix**: Added `mpd` module to Waybar and split the bar config into two named instances
in `home/profiles/waybar.nix`:
- `dell` bar: targets `Dell Inc. DELL U4320Q 30F6XN3`, has MPD in `modules-left`
- `other` bar: targets BOE + both LG monitors explicitly, no MPD

**Gotchas discovered**:
- Waybar uses raw output descriptions (e.g. `"Dell Inc. DELL U4320Q 30F6XN3"`), NOT
  Hyprland's `desc:` prefix syntax — using `desc:` causes no monitor match and the
  bar disappears
- A bar with no `output` field shows on ALL monitors, so the "other" bar must
  explicitly list its monitors to avoid doubling up on the Dell
- Multiple bar configs need unique `name` fields so Waybar treats them as distinct instances

**Files changed**: `home/profiles/waybar.nix`

---

### Fix: BOE workspaces not pinning to BOE monitor

**Problem**: `Super+6` through `Super+0` switched to workspaces on the Dell monitor
instead of the BOE display. Named workspaces `boe1`–`boe5` were not pinned to the
correct monitor.

**Root cause**: The BOE workspace rules were missing the `desc:` prefix in the monitor
matcher. The Dell lines used `monitor:desc:Dell Inc. DELL U4320Q 30F6XN3` but the BOE
lines had `monitor:BOE Display demoset-1` (missing `desc:`). Without the prefix,
Hyprland couldn't match the description string to the actual monitor, so the workspaces
defaulted to the primary (Dell) display.

**Fix**: Added `desc:` prefix to all five BOE workspace rules in `home/profiles/desktop.nix`:
```
workspace = name:boe1, monitor:desc:BOE Display demoset-1, persistent:true, default:true
```

**Files changed**: `home/profiles/desktop.nix`

---

### Add: Named workspaces per monitor with keybinds

**Problem**: Default Hyprland workspaces are numbered and not pinned to specific monitors.
Needed dedicated workspaces for the Dell (primary) and BOE (secondary) displays.

**Fix**: Added named workspace config in `home/profiles/desktop.nix`:
- 5 persistent workspaces per monitor: `desk1`–`desk5` (Dell), `boe1`–`boe5` (BOE)
- Workspaces assigned to monitors via `desc:` matching
- `exec-once` lines create all workspaces at login
- Keybinds: `Super+1–5` → Dell workspaces, `Super+6–0` → BOE workspaces
- `Super+Shift+1–5` / `Super+Shift+6–0` → move window to workspace

**Files changed**: `home/profiles/desktop.nix`

---

### Update: Monitor scaling for Dell and BOE displays

**Problem**: Text on the Dell U4320Q (43" 4K at scale 1) was full-size but user wanted
it slightly smaller. Text on the BOE Display (scale 1) was too small after the Dell
scale change reduced its relative position.

**Fix**: Adjusted fractional scales and recalculated all monitor positions in
`home/profiles/desktop.nix`:
- Dell U4320Q: scale 1 → 1.07 (Hyprland rejected 1.1, suggested 1.07)
- BOE Display: scale 1 → 1.2 (makes text ~20% larger, clean integer logical 1800x1200)
- Right LG portrait: X position 4416 → 4165 (adjusted for Dell's new logical width)
- BOE: repositioned to 1471x2041 (re-centered under narrower Dell, Y adjusted for
  Dell's fractional logical height of 2018.69)

**Gotchas discovered**:
- Fractional scales produce non-integer logical dimensions; adjacent monitors at integer
  positions can trigger overlap warnings at the fractional boundary (cosmetic, renders OK)
- `hyprctl keyword monitor` live changes can cause black bar artifacts on scaled monitors
  that don't occur after a proper `nrs` rebuild — always verify with a rebuild
- Hyprland rejects certain fractional scales and suggests alternatives

**Files changed**: `home/profiles/desktop.nix`

---

## 2026-02-19

### Add: Nix garbage collection and generation limits

**Problem**: No GC configured — the Nix store and boot menu grow indefinitely,
especially with devenv creating per-project environments.

**Fix**: Two-phase daily cleanup in `modules/base.nix`:
- `nix-gc-generations` systemd service — prunes system profile to the 20 most recent
  generations (`nix-env --delete-generations +20`), runs before GC
- `nix.gc` — collects unreferenced store paths daily (no `--delete-older-than` —
  generation pruning controls what becomes unreferenced)
- `nix.settings.auto-optimise-store` — hardlinks identical store files to save space
- `boot.loader.systemd-boot.configurationLimit = 20` — keeps 20 boot menu entries

**Why two phases**: `nix-collect-garbage --delete-older-than 7d` deletes ALL generations
older than 7 days with no minimum-keep guarantee. If you don't rebuild for two weeks,
you'd lose every rollback generation. The separate pruning service ensures at least 20
generations always survive regardless of age.

**Files changed**: `modules/base.nix`

---

### Fix: hypridle lock never activating (bash not found)

**Problem**: Screen turned off (DPMS) after idle, but hyprlock never launched. User
could return after hours without being asked for a password.

**Root cause**: hypridle runs `lock_cmd` via `/bin/sh`, which on NixOS has a minimal
PATH that doesn't include `bash`. The configured `lock_cmd = "bash ~/.local/bin/lock-and-rotate.sh"`
failed silently with `bash: command not found`. Confirmed in journal:
```
hypridle[59677]: /bin/sh: line 1: bash: command not found
```

**Fix**: Created a `writeShellScript` wrapper (`lockAndRotate`) in `home/profiles/common.nix`
that sets PATH with all required binaries (`hyprlock`, `pidof`/procps, `swww`, `coreutils`,
`findutils`, `bash`) before running the lock-and-rotate logic. The `lock_cmd` now points
to this Nix store script instead of calling `bash` directly.

**Files changed**: `home/profiles/common.nix`

**Requires**: `nrs` then **log out and back in** (hypridle is a systemd user service).

---

## 2026-02-19

### Fix: Waybar crash loop on login (portal timeout cascade)

**Problem**: After logging in, waybar crashed every ~25 seconds in a loop. It would
start, run for 25s, then die with `Error calling StartServiceByName for
org.freedesktop.portal.Desktop: Timeout was reached`.

**Root cause**: A cascade of failures caused by the Wayland socket disappearing on logout:

1. `xdg-desktop-portal-hyprland` starts before `WAYLAND_DISPLAY` is in the systemd
   environment, segfaults in `CCWlOutput` destructor (or fails with "Couldn't connect
   to a wayland compositor"), hits the restart rate limit, stays **failed**
2. `xdg-desktop-portal` (frontend) tries to reach the dead hyprland backend via D-Bus,
   times out after 25 seconds
3. Waybar calls the portal for appearance detection (`Discovered appearance 'light'`),
   gets the 25s timeout error, and crashes
4. The previous `exec-once` fix only restarted waybar — not the portal services — so
   waybar would start, hit the portal timeout again, and crash in a 25s loop

**Fix**: Updated `exec-once` in `home/profiles/desktop.nix` to restart all three
services in dependency order after importing environment:
```
exec-once = sleep 2 && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user reset-failed xdg-desktop-portal-hyprland.service xdg-desktop-portal.service waybar.service 2>/dev/null; systemctl --user restart xdg-desktop-portal-hyprland.service && sleep 1 && systemctl --user restart xdg-desktop-portal.service && systemctl --user restart waybar.service
```
- `reset-failed` clears rate-limit state on all three services
- Restart order: hyprland portal (backend) → 1s delay → portal frontend → waybar
- The 1s delay between portal backend and frontend ensures the backend is ready before
  the frontend tries to reach it

**Files changed**: `home/profiles/desktop.nix`

---

### Wallpaper rotation + hyprlock + hypridle — lock screen and idle management

**Goal**: Random wallpaper from `~/Pictures/wallpaper` on login and after each unlock,
screen lock via hyprlock (Hyprland-native), and automatic idle lock/DPMS via hypridle.

**Files changed**: `home/profiles/common.nix`, `home/profiles/desktop.nix`,
`modules/hyprland.nix`, `home/assets/wallpaper/rotate-wallpaper.sh` (new),
`home/assets/wallpaper/lock-and-rotate.sh` (new)

**Components**:
- **swww**: Wallpaper daemon — scriptable, supports animated transitions (grow effect)
- **hyprlock**: Hyprland-native lock screen — blurred screenshot background, neon cyan
  clock + password field matching waybar theme, 5-second grace period
- **hypridle**: Idle daemon — locks after 5 min, DPMS off after 10 min

**Scripts** (installed to `~/.local/bin/` via `home.file`):
- `rotate-wallpaper.sh` — picks random image from `~/Pictures/wallpaper` (or arg dir),
  sets via `swww img` with grow transition (2s, 60fps)
- `lock-and-rotate.sh` — guards against duplicate hyprlock, runs hyprlock (blocks),
  rotates wallpaper on unlock

**System config**:
- `programs.hyprlock.enable = true` in `modules/hyprland.nix` — sets up PAM auth
  (without this, hyprlock locks but can't unlock)
- `misc` block: `force_default_wallpaper = 0`, `disable_hyprland_logo = true`
- `exec-once = swww-daemon && sleep 0.5 && bash ~/.local/bin/rotate-wallpaper.sh`
- `bind = $mainMod, L, exec, loginctl lock-session` (manual lock)
- hypridle `lock_cmd` calls `lock-and-rotate.sh` via `loginctl lock-session` signal

**Verification**:
1. `git add home/assets/wallpaper/` before `nrs`
2. Run `nrs`, then **log out and back in**
3. `systemctl --user status hypridle` — should be active
4. `swww query` — should show current wallpaper
5. `Super+L` to lock, unlock to see new wallpaper
6. Wait 5 min idle for auto-lock

---

### heif-convert + ImageMagick — image conversion and resizing

**Goal**: Convert HEIF/HEIC images (from iPhones) and resize images from the CLI.

**Files changed**: `home/profiles/common.nix`

- Added `heif-convert` as an inline `buildPythonApplication` derivation in `common.nix`
  - Source: `github:NeverMendel/heif-convert` v1.2.1
  - Dependencies: `pillow` + `pillow-heif` (both in nixpkgs)
  - Required `pyproject = true` and `build-system = [ setuptools ]` — newer nixpkgs
    no longer auto-detects setuptools; omitting these causes a build error
- Added `imagemagick` to `home.packages` for general image resizing/conversion

**Usage**:
```bash
# HEIF/HEIC conversion
heif-convert input.heic output.jpg
heif-convert -q 90 *.heic -o /output/dir

# Resize with ImageMagick
magick input.jpg -resize 1920x1080 output.jpg
magick input.jpg -resize 50% output.jpg
magick mogrify -resize 1920x1080 *.jpg   # in-place batch
```

---

### TablePlus — database GUI via AppImage

**Goal**: Install TablePlus database management tool. The nixpkgs package is
old/unmaintained, so we wrap the official Linux AppImage instead.

**Files changed**: `home/profiles/common.nix`, `flake.nix`

- Created inline `tableplus` derivation in `common.nix` using
  `pkgs.appimageTools.wrapType2` — extracts the AppImage into an FHS wrapper
- Source: `https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage`
- Hash: `sha256-MXDqrg2DezxUYeAtcGZgxkfUSVsYIE0eTI5KxxetDvA=`
- Installs `.desktop` file and icon from AppImage contents for launcher integration
- Added `tableplus` to `home.packages`
- Added `"tableplus"` to unfree allowlist in `flake.nix`

**Gotchas**:
- The `.desktop` file inside the AppImage already has `Exec=tableplus` (not
  `Exec=AppRun` like many AppImages) — no `substituteInPlace` needed
- Hash must be empty on first build; Nix prints the correct hash in the error output

**Future updates**: Same URL always points to latest. To update:
```bash
nix-prefetch-url https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage
nix hash convert --hash-algo sha256 --to sri <hash>
```
Replace the hash in `common.nix` and run `nrs`.

---

## 2026-02-18

### sinkswitch — PipeWire audio output switcher

**Goal**: Replace `rofi-pulse-select` on `Super+S` with sinkswitch, an fzf-based
PipeWire sink switcher designed for Hyprland.

**Source**: https://github.com/Seyloria/sinkswitch

**Files changed**: `home/profiles/common.nix`, `home/profiles/desktop.nix`,
`home/assets/sinkswitch/sinkswitch.sh` (new)

- Added `sinkswitch.sh` to `home/assets/sinkswitch/` (vendored bash script)
- Installed to `~/.local/bin/sinkswitch.sh` via `home.file` with `executable = true`
- Added `fzf` to `home.packages` (dependency)
- Changed `Super+S` keybind from `rofi -modi pulse:rofi-pulse-select -show pulse`
  to `kitty --title sinkswitch -e bash ~/.local/bin/sinkswitch.sh`
- Added `float-sinkswitch` windowrule: floats, 600x400, centered, matched by
  `initial_title = sinkswitch`

**Dependencies**: `fzf`, `wpctl` (from wireplumber, already present with PipeWire)

---

### fastfetch — neofetch replacement with Zellij autostart

**Goal**: System info display on new Zellij panes (neofetch replacement).

**Files changed**: `home/profiles/common.nix`

- Added `fastfetch` to `home.packages` (all machines)
- Added autostart in `initContent`: runs `fastfetch` when `$ZELLIJ` is set and shell
  is interactive — shows system info at the top of every new Zellij pane/tab
- Does not run outside Zellij or over SSH

---

### Monitor configuration — per-desc matching with future multi-monitor

**Goal**: Identify current monitor by description/serial for native 4K at correct
scaling, and pre-configure monitors for upcoming desk move.

**Files changed**: `home/profiles/desktop.nix`

- Replaced generic `monitor=,preferred,auto,auto` with `desc:` matched entries
- Current LG HDR 4K (`0x00068CED`): 3840x2160@60, scale 1.2 (tested 1.0 first — too small)
- Pre-configured Dell U4320Q (`30F6XN3`), two LG portrait monitors (`0x0003E009`,
  `0x00046040`) from old setup — positions from `~/Downloads/home-manager`
- Added `monitor=,preferred,auto,1` as fallback for unmatched monitors
- Uses `desc:` matching (make/model/serial) so configs survive port changes

**Note**: Positions will need recalculating when the machine moves and a new primary
monitor replaces `eDP-1` as the origin point.

---

### OBS Studio — with VA-API and Wayland plugins

**Goal**: Install OBS Studio with hardware-accelerated encoding (Intel Arc B580)
and native Wayland screen capture for Hyprland.

**Files changed**: `home/profiles/common.nix`

- Added `obs-studio` via `wrapOBS` with plugins:
  - `obs-vaapi` — VA-API hardware encoding via GStreamer (uses `intel-media-driver`)
  - `obs-pipewire-audio-capture` — per-app audio capture via PipeWire
  - `wlrobs` — Wayland screen capture for wlroots compositors (Hyprland)
  - `obs-vkcapture` — Vulkan/OpenGL game capture
- Not unfree — no changes needed to `flake.nix` allowlist
- Hardware encoding support provided by `intel-media-driver` already in
  `modules/desktop.nix` `hardware.graphics.extraPackages`

---

### Intel Arc B580 — GPU compute and video acceleration

**Goal**: Enable OpenCL, VA-API, and Quick Sync for the Intel Arc B580 discrete GPU
so apps like Kdenlive can use hardware acceleration.

**Files changed**: `modules/desktop.nix`

- Added `intel-media-driver` (VA-API / iHD) for hardware video decode/encode
- Added `vpl-gpu-rt` (oneVPL) for Quick Sync Video
- Added `intel-compute-runtime` (NEO) for OpenCL and Level Zero compute
- Set `LIBVA_DRIVER_NAME = "iHD"` session variable
- Desktop-only (`modules/desktop.nix`) since the laptop won't have this GPU

**Note**: DaVinci Resolve does not officially support Intel GPUs on Linux.
The B580 has known CL/GL interop issues with Resolve (crashes, missing OpenGL
entry points). Kdenlive is a better fit for this hardware.

**Verify after rebuild**:
```bash
nix-shell -p clinfo --run clinfo             # OpenCL devices
nix-shell -p libva-utils --run vainfo         # VA-API codecs
nix-shell -p vulkan-tools --run vulkaninfo | head -30  # Vulkan
```

---

### Kdenlive + DaVinci Resolve — video editors

**Files changed**: `home/profiles/common.nix`, `home/profiles/desktop.nix`, `flake.nix`

- Added `kdePackages.kdenlive` to `common.nix` (all machines)
- Added `davinci-resolve` to `desktop.nix` (desktop only — needs discrete GPU)
- Added `"davinci-resolve"` to unfree allowlist in `flake.nix`

---

### Zen Browser keybind — migrate from flatpak to nix package

**Problem**: `Super+B` ran `flatpak run app.zen_browser.zen` but Zen is now installed
via the `zen-browser` flake input, not flatpak. Keybind did nothing.

**Fix**: Changed `Super+B` exec command from `flatpak run app.zen_browser.zen` to `zen`
(the binary provided by the flake package).

**Files changed**: `home/profiles/desktop.nix`

---

### Google Cloud SDK — with GKE auth plugin and kubectl

**Goal**: Install Google Cloud CLI for managing Kubernetes clusters on GKE.

**Files changed**: `home/profiles/common.nix`

- Added `google-cloud-sdk` with `withExtraComponents` to include `gke-gcloud-auth-plugin`
  (required for kubectl authentication with GKE) and `kubectl` (bundled version)
- Uses nixpkgs-unstable version (552.0.0) — Google releases weekly so nixpkgs always
  lags upstream by a few versions, but updates come with normal `nix flake update`
- Not unfree — no changes needed to `flake.nix` allowlist
- `gcloud components install` does **not** work on NixOS (read-only store) — extra
  components must be declared via `withExtraComponents` in Nix

---

### Gradia screenshots — XDG portal fix

**Problem**: Gradia immediately reported "screenshot cancelled" with GDBus error:
`No such interface "org.freedesktop.portal.Screenshot"`.

**Root cause**: Home-manager's `wayland.windowManager.hyprland.enable = true` puts
`hyprland.portal` in the per-user profile (`/etc/profiles/per-user/yourusername/share/
xdg-desktop-portal/portals/`), which overrides the system path. But
`xdg-desktop-portal-gtk` (from `xdg.portal.extraPortals` in `modules/hyprland.nix`)
only installed `gtk.portal` to the system profile. The per-user dir only had
`hyprland.portal`, so `portals.conf`'s `default=hyprland;gtk` couldn't resolve the
`gtk` portal, breaking interface resolution for Screenshot.

**Fix**:

1. **`home/profiles/common.nix`**: Added `xdg-desktop-portal-gtk` to `home.packages`
   so `gtk.portal` appears in the per-user portal dir alongside `hyprland.portal`.

2. **`modules/hyprland.nix`**: Added `xdg.portal.config` with a `Hyprland` section
   (matching `XDG_CURRENT_DESKTOP`) specifying `default = [ "hyprland" "gtk" ]` and
   explicit Screenshot/ScreenCast interface routing to hyprland.

**Note**: Portal config changes require a full logout/login — `hyprctl reload` is
not sufficient.

---

### Zen Browser — added via flake input

**Goal**: Install Zen Browser on both desktop and laptop (not in nixpkgs, requires external flake).

**Files changed**: `flake.nix`, `home/profiles/common.nix`

- Added `zen-browser` input to `flake.nix` pointing to `github:youwen5/zen-browser-flake`
  with `inputs.nixpkgs.follows = "nixpkgs"`
- Added `zen-browser` to the `outputs` destructuring in `flake.nix`
- Added `inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default`
  to `home.packages` in `common.nix` — resolves correctly on any arch (desktop + laptop)
- `inputs` was already in `common.nix`'s function signature, no extra wiring needed

**Reference**: https://wiki.nixos.org/wiki/Zen_Browser

---

### Zellij — fix Alt+n creating new tab instead of moving focus

**Problem**: `Alt n` was creating a new tab instead of moving pane focus right.

**Root cause**: In tab mode, `bind "n" { NewTab; }` takes priority because terminals
can interpret `Alt n` as `Escape` + `n`. The bare `n` fires NewTab while in tab mode.

**Fix**: Rebound NewTab in `tab` mode from `n` to `t` (more mnemonic — "t" for new tab).

**Files changed**: `home/assets/zellij/config.kdl`

**Note**: Zellij caches config at session start. Must kill existing sessions and start
fresh to pick up keybind changes. Open a new terminal first, then `zellij kill-all-sessions`.

---

### Zellij — desktop-specific keybind config for Moonlander

**Goal**: Port custom zellij keybinds from old home-manager config, desktop-only since
binds are tuned for the Moonlander (Dvorak Alt+HTCN navigation).

**Files changed**: `home/profiles/desktop.nix`, `home/assets/zellij/config.kdl` (new)

- Copied `config.kdl` from `~/Downloads/home-manager/modules/zellij/config.kdl` to
  `home/assets/zellij/config.kdl`
- Added `xdg.configFile."zellij/config.kdl".source` in `desktop.nix` pointing to the asset
- Config is desktop-only — laptop will use zellij defaults until its own config is needed
- Added `inputs` to `desktop.nix` function args to allow `${inputs.self}` path reference

**Key bindings**:
- `Alt + arrows` → move focus between panes
- `Alt + h/t/c/n` → Dvorak pane navigation (left/down/up/right)
- `Alt + i/o` → move tabs left/right
- `Ctrl + p/t/n/h/s/o/b` → switch to pane/tab/resize/move/scroll/session/tmux modes
- `Ctrl + q` → quit

**Note**: `home/assets/zellij/config.kdl` must be `git add`ed before `nrs`.

---

### Waybar — ported from old home-manager config

**Goal**: Bring waybar config from `~/Downloads/home-manager` into the NixOS flake, available on both desktop and laptop.

**Files changed**: `home/profiles/common.nix`, `home/profiles/waybar.nix` (new)

- Created `home/profiles/waybar.nix` ported from `~/Downloads/home-manager/hypr/waybar.nix`
- Kept full cyberpunk CSS theme and all module configs intact
- Simplified to a single bar (no monitor-specific output filtering — one monitor on desktop,
  laptop monitor IDs unknown)
- Dropped MPD module (was specific to the old Dell 45" monitor setup)
- `systemd.enable = true` — waybar starts as a systemd user service, no `exec-once` needed
- Added `imports = [ ./waybar.nix ]` to `common.nix` — loads on both desktop and laptop
- Added `font-awesome` and `pavucontrol` to `home.packages` in `common.nix`

**Gotcha**: New files in a flake repo must be `git add`ed before `nrs` or the build fails
with "path does not exist". Also, previous `sudo` operations had left root-owned objects
in `.git/objects/e6/` — fixed with `sudo chown -R yourusername:users /etc/nixos/.git`.

---

### Obsidian — installed from nixpkgs unstable

**Goal**: Install Obsidian from nixpkgs (already on nixos-unstable, no extra input needed).

**Files changed**: `flake.nix`, `home/profiles/common.nix`, `home/profiles/desktop.nix`

- Added `"obsidian"` to the unfree allowlist in `flake.nix` (Obsidian is proprietary)
- Added `obsidian` to `home.packages` in `common.nix` — available on both desktop and laptop
- Updated `Super+W` keybind in `desktop.nix` from `flatpak run md.obsidian.Obsidian` to `obsidian`
- No new flake input needed — `nixpkgs` already tracks `nixos-unstable`

---

### MelGeek Mojo68 keyboard — Dvorak support

**Goal**: MelGeek Mojo68 plugged in as a secondary keyboard types Dvorak with Caps Lock as Escape.

**Files changed**: `home/profiles/desktop.nix`

- Detected keyboard via `hyprctl devices`: registers as three sub-devices:
  - `melgeek-mojo68`
  - `melgeek-mojo68-system-control`
  - `melgeek-mojo68-consumer-control`
- Unlike the Moonlander, the Mojo68 does **not** remap Dvorak at firmware level, so
  `kb_variant = dvorak` must be applied by Hyprland via per-device blocks
- Added `device` blocks for all three sub-devices with `kb_layout = us`,
  `kb_variant = dvorak`, `kb_options = caps:escape`
- Applied immediately to live session via `hyprctl keyword` without requiring `nrs`

---

### cliphist — clipboard history

**Goal**: `Super+V` opens rofi clipboard picker with actual history (was empty before).

**Files changed**: `home/profiles/common.nix`

**Root cause**: `cliphist` was installed and the keybind was correct, but no process was
recording clipboard events into the database.

**Fix**: Added `cliphist-watcher` systemd user service in `common.nix` running two
`wl-paste --watch` processes (text + image) piped into `cliphist store`. The launch
script waits up to 20s for the Wayland socket before exiting so systemd can retry safely.

---

### XDG user dirs — deprecation fix

**Files changed**: `home/profiles/common.nix`

- Renamed `XDG_SITES_DIR` key to `SITES` in `xdg.userDirs.extraConfig` — home-manager
  now adds the `XDG_` prefix automatically.

---

### claude-code — removed overlay, use nixpkgs directly

**Files changed**: `flake.nix`, `home/profiles/common.nix`

**Problem**: `evaluation warning: 'system' has been renamed to 'stdenv.hostPlatform.system'`
came from `claude-code-overlay`'s `prev.system` usage in its overlay definition.

**Fix**: `claude-code` is now in `nixpkgs-unstable` natively. Removed `claude-code-overlay`
flake input and its overlay wiring. `pkgs.claude-code` just works without an overlay.
Ran `nix flake lock --update-input claude-code-overlay` to clean the lock file.

---

### Dolphin — installed as GUI file manager

**Files changed**: `home/profiles/common.nix`

- Added `kdePackages.dolphin` to `home.packages` — complements vifm (terminal) with a GUI
  option. `$fileManager = dolphin` was already set in `desktop.nix`.

---

### Glacier NAS — SMB automount at ~/Glacier

**Goal**: Mount Glacier NAS share at `~/Glacier` on all machines, automounting on access.

**Files changed**: `modules/base.nix`, `CLAUDE.md`, `README.md`

- Added `services.avahi` (with `nssmdns4 = true`) for `.local` hostname resolution
- Added `cifs-utils` to system packages
- Added `systemd.tmpfiles.rules` to create the mount point directory
- Added `fileSystems` entry with `x-systemd.automount`, `nofail`, `_netdev`, 5-min idle timeout

**Debugging notes**:
- Initial error was "could not resolve address" — fixed by adding Avahi
- Second error was "No such file or directory" — share name is `glacier-shared`, not `Glacier`
  (discovered via `nix-shell -p samba --run "smbclient -L glacier.local -U user%pass"`)
- Credentials stored in `~/.smbcredentials` (mode 600, not managed by Nix) — see README

---

### Mako — notifications (replacing Dunst)

**Goal**: Native Wayland notification daemon styled to match Waybar cyberpunk theme.

**Files changed**: `home/profiles/common.nix`

**Why Mako over Dunst**: Mako is native Wayland (wlr-layer-shell); Dunst was X11-first.

- Configured via `services.mako` in `common.nix` (all hosts)
- Added `libnotify` for `notify-send`
- Neon cyberpunk palette matching Waybar: cyan (normal), green (low), hot pink (critical)
- **Gotcha**: criteria sections (`[urgency=low]` etc.) must use `extraConfig` with raw INI
  text — nested attrsets in `settings` generate `[[double brackets]]` which mako rejects
- All top-level options migrated to `services.mako.settings` (old camelCase names deprecated)

---

### MPD + rmpc — music playback with album art

**Goal**: MPD music daemon + rmpc TUI client with working album art.

**Files changed**: `home/profiles/common.nix`

- Added `services.mpd` (home-manager service) pointing to `~/Music`, PipeWire/PulseAudio output
- Added `rmpc` and `ueberzugpp` to `home.packages`
- Added `xdg.configFile."rmpc/config.ron"` with `method: Kitty`
- Added `rmpc-kitty = "kitty --detach rmpc"` alias

**Album art investigation**:
- `UeberzugWayland` tried first — creates a Wayland layer surface but cannot correctly
  map terminal cell coordinates when inside a multiplexer; images rendered in wrong positions
- `UeberzugWayland` does not appear in `hyprctl clients` (layer surface, not a window)
- Final approach: `method: Kitty` + dedicated kitty window via `rmpc-kitty` alias
- `--single-instance` removed from alias — that flag reuses existing kitty process
  (which runs Zellij), causing the same coordinate issue. Fresh window required.

---

### lsd — modern ls replacement

**Files changed**: `home/profiles/common.nix`

- Added `lsd` to `home.packages`
- Added shell aliases (all hosts): `l`, `la`, `lla`, `lt`

---

### Rofi — set kitty as terminal for TUI apps

**Goal**: btop, vifm, and other TUI apps launched from rofi open in kitty with proper
fonts instead of a bare xterm.

**Files changed**: `home/profiles/common.nix`

**Root cause**: Rofi defaults to xterm when launching terminal apps. xterm has no font
config and renders poorly on HiDPI/Wayland.

**Fix**: Replaced bare `rofi` package with `programs.rofi` (home-manager module) and
set `terminal = "${pkgs.kitty}/bin/kitty"`. Removed `rofi` from `home.packages`.

---

### Syncthing

**Goal**: Syncthing running at boot on all machines, no manual start required.

**Files changed**: `modules/base.nix`

- Added `services.syncthing` as a NixOS system service (not home-manager) so it starts
  before login
- Runs as user `yourusername`, data at `~/`, config at `~/.config/syncthing`
- `openDefaultPorts = true` opens ports 22000 (sync) and 21027 (local discovery) in
  the NixOS firewall automatically

---

### Doom Emacs

**Goal**: Install Doom Emacs with working icons and personal config.

**Files changed**: `home/profiles/common.nix`, `README.md`

- Added `emacs-pgtk` (native Wayland via pure GTK) to `home.packages`
- Added `nerd-fonts.symbols-only` for Doom's `nerd-icons` UI icons
- Doom itself is installed manually (not via Nix) — see README Setup section
- Added Doom setup instructions to README including backup step for existing `~/.config/doom`

**Lessons learned**:
- `~/.emacs.d` existing causes Emacs to ignore `~/.config/emacs` — must rename it:
  `mv ~/.emacs.d ~/.emacs.d.bak`
- Doom v3 has no `init.el` at the repo root — uses a profile system; `doom sync`
  generates `~/.config/emacs/.local/etc/@/init.30.2.el`; `early-init.el` bootstraps it
- Missing icons (boxes with hex codes like `EB27`) = Nerd Fonts not installed;
  fixed by `nerd-fonts.symbols-only` + `fc-cache -f`
- Doom dependencies already satisfied by `common.nix`: `ripgrep`, `fd`, `gcc`, `nodejs`
- feedsmith local package recipe:
  `(package! feedsmith :recipe (:host github :repo "yourusername/feedsmith" :local-repo "~/Projects/feedsmith"))`

---

### Dolphin copy dialog — float windowrule

**Goal**: Dolphin copy/move/delete progress dialogs should float instead of tiling.

**Files changed**: `home/profiles/desktop.nix`

- Added `windowrule` block to float Dolphin progress dialogs

**Lessons learned**:
- `windowrulev2` is deprecated — use the new `windowrule` block format
- Float action is `float = on` not `float = yes`
- Hyprland regex is **full-match** — `^(Copying|...)` does not match "Copying — Dolphin"
  because it doesn't consume the full string; use `(Copying|...).*` instead
- Match field names use underscores: `match:initial_class`, `match:initial_title`
  (not `initialClass`, `initialclass`, or `initialTitle`)
- The overwrite/confirm dialog floats automatically because KDE marks it as a dialog
  window type; the copy progress window is a normal window type requiring an explicit rule

**Final rule**:
```
windowrule {
    name = float-dolphin-dialogs
    match:initial_class = org.kde.dolphin
    match:initial_title = (Copying|Moving|Deleting|Renaming|Progress).*
    float = on
}
```

---

## 2026-02-17

### Hyprland keyboard configuration

**Goal**: All keyboards type Dvorak; Caps Lock mapped to Escape.
Moonlander Mark I must not have Dvorak applied by Hyprland (it remaps at firmware level).

**Files changed**: `home/profiles/desktop.nix`

- Migrated from empty profile to full Hyprland home-manager config using
  `wayland.windowManager.hyprland.extraConfig`
- Moved the autogenerated `~/.config/hypr/hyprland.conf` content under NixOS management
  (the file is now generated by home-manager on `nrs`)
- Set default `input` block to `kb_layout = us`, `kb_variant = dvorak`,
  `kb_options = caps:escape` — covers all keyboards not explicitly matched
- Added `device` blocks for all four Moonlander sub-devices to clear the dvorak variant:
  - `zsa-technology-labs-moonlander-mark-i`
  - `zsa-technology-labs-moonlander-mark-i-keyboard`
  - `zsa-technology-labs-moonlander-mark-i-system-control`
  - `zsa-technology-labs-moonlander-mark-i-consumer-control`

**Gotcha**: `kb_variant` must be set explicitly to empty (`kb_variant =`) inside a
device block. Omitting the key causes it to inherit the global `dvorak` value.
Confirmed working via `hyprctl devices` showing `v ""` and `active keymap: English (US)`
on all Moonlander sub-devices after reload.

### Hyprland cursor configuration

**Goal**: Consistent cursor theme across Wayland, GTK apps, and XWayland.

**Files changed**: `home/profiles/common.nix`, `home/profiles/desktop.nix`

- Set `home.pointerCursor` in `common.nix` with `name = "Adwaita"`,
  `package = pkgs.adwaita-icon-theme`, `size = 24`, and `gtk.enable = true`
- Added `exec-once = hyprctl setcursor Adwaita 24` in desktop Hyprland config
  to apply the cursor at session start
- Added `env = XCURSOR_THEME,Adwaita` environment variable
- Removed `HYPRCURSOR_SIZE` (not needed; `XCURSOR_SIZE` covers it)

### Application launch keybinds

**Goal**: Match keybinds from previous home-manager setup in `~/Downloads/home-manager`.

**Files changed**: `home/profiles/desktop.nix`

- `Super+Return` → kitty terminal (added alongside existing `Super+Q`)
- `Super+E` → `rofi -show drun` (was: file manager)
- `Super+B` → `zen` (was: `flatpak run app.zen_browser.zen`; updated 2026-02-18)
- `Super+W` → `flatpak run md.obsidian.Obsidian` (new)
- `Super+U` → `emacs` (new)
- `Super+A` → `kitty -e bluetuith` (new)
- `Super+P` → `gradia` screenshot tool (was: pseudo tile toggle)
- `Super+V` → `cliphist list | rofi -dmenu | cliphist decode | wl-copy` (was: togglefloating)
- `Super+S` → `rofi -modi pulse:rofi-pulse-select -show pulse` (was: special workspace toggle)

### Keybind layout fix — remove global kb_variant = dvorak

**Problem**: Keybinds were mismatched. Pressing Super+Q typed 'q' in the focused window
instead of triggering `killactive`. Super+. (Dvorak 'E' position) launched rofi instead
of Super+E.

**Root cause**: Hyprland resolves keybind letter names using the **global** `input` layout,
not per-device layouts. With `kb_variant = dvorak` set globally, `bind = SUPER, Q` meant
the key that produces 'q' in Dvorak (physical QWERTY 'X'), not the 'Q' keysym the
Moonlander sends. The Moonlander's per-device `kb_variant =` (empty) only affects how
that device types — it does not affect keybind name resolution.

**Fix**: Removed `kb_variant = dvorak` from the global `input` block. Keybinds now resolve
against plain US layout, matching what the Moonlander sends at firmware level.

**Files changed**: `home/profiles/desktop.nix`

**Framework implication**: The laptop's built-in keyboard must get `kb_variant = dvorak`
in its own **device block** (`at-translated-set-2-keyboard`), NOT in the global input.
The global input must stay plain US on all machines for keybinds to work correctly.
