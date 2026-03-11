# Claude Memory — NixOS Config

Running context for Claude Code sessions on this repo.

---

## Blog Posts

- Always markdown format
- Technical posts assume a reasonably technical audience — comfortable with the terminal, familiar with home-manager if the topic is NixOS
- Skip beginner-level explanations unless explicitly told the post is for beginners
- **Ready folder**: `/home/curtismchale/Documents/main/Writing/010 - Ready`
- **Working folder**: `/home/curtismchale/Documents/main/Writing/020 - Working`

---

## System

- **Host**: `b650e-desktop` (AMD B650E desktop)
- **OS**: NixOS with flakes
- **WM**: Hyprland (Wayland)
- **User**: curtismchale
- **Shell**: zsh
- **Rebuild command**: `nrs` (alias for `sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)`)

---

## Zen Browser (2026-03-04)

Installed via `pkgs.wrapFirefox` wrapping the `youwen5/zen-browser-flake` unwrapped package
in `home/profiles/common.nix`. No home-manager module exists for Zen.

To set preferences for all profiles, use `extraPrefs` in the `wrapFirefox` call — it writes
`mozilla.cfg` which applies globally. Use `lockPref()` to prevent in-browser overrides.

AI features are blocked this way (not via `programs.firefox.profiles`).

---

## Firefox (2026-03-04)

`programs.firefox.enable = true` is in `modules/base.nix` (NixOS system option).
`programs.firefox.profiles` and all profile `settings` must go in home-manager files
(e.g. `home/profiles/common.nix`) — the NixOS module does not know about `profiles`.

AI features are blocked via `programs.firefox.profiles.default.settings` in `common.nix`.

---

## Nix Trusted Users (2026-02-23)

`nix.settings.trusted-users = [ "root" "curtismchale" ]` is set in `modules/base.nix`.
Required for devenv/cachix to automatically configure binary caches. This is a **NixOS
system-level** option — it does nothing in home-manager files.

---

## Virtualisation (2026-02-23)

QEMU/KVM via `virtualisation.libvirtd` and `programs.virt-manager` enabled in
`modules/base.nix`. User added to `libvirtd` group. Requires logout/login after
`nrs` for group membership to take effect.

---

## Unprivileged Port Binding (2026-02-23)

`boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80` is set in `modules/base.nix`.
Allows any user process to bind ports 80+. Needed for devenv Caddy — the `setcap` workaround
does **not** work on NixOS (read-only Nix store).

---

## Nix Store & Garbage Collection (2026-02-19)

Configured in `modules/base.nix` (applies to all machines). Two-phase daily cleanup:

1. **Generation pruning** (`nix-gc-generations.service`) — runs `nix-env --delete-generations +20`
   on the system profile, keeping the 20 most recent generations regardless of age. Runs
   *before* GC via `before = [ "nix-gc.service" ]`.
2. **Store GC** (`nix.gc`) — collects unreferenced store paths daily (no `--delete-older-than`,
   so it only collects what's already been pruned from profiles).
3. **Store optimisation**: `auto-optimise-store = true` — hardlinks identical files.
4. **Boot entries**: `configurationLimit = 20` — systemd-boot menu pruned on each `nrs`.

Net effect: always at least 20 rollback generations; unreferenced store paths cleaned daily.

---

## Repo Structure

```
/etc/nixos/
  flake.nix               # Flake entrypoint, defines hosts + home-manager
  hosts/b650e-desktop/    # Desktop host system config
  modules/                # Shared NixOS modules (hyprland.nix, desktop.nix, etc.)
  home/
    curtismchale.nix      # Home-manager entrypoint; imports profile by hostname
    profiles/
      common.nix          # Packages + programs shared across all machines
      desktop.nix         # Desktop-specific home-manager config (Hyprland settings)
      laptop.nix          # Framework laptop home-manager config (empty, future)
    assets/               # Static files (oh-my-posh theme, etc.)
```

---

## Keyboard Setup

### Keybind resolution — critical rule

**Hyprland resolves keybind letter names using the global `input` layout, not per-device layouts.**

This means `bind = SUPER, Q` means "the key that produces Q in the global layout".
The global `input` block **must NOT have `kb_variant = dvorak`** on any machine, or all
letter-keyed binds will be offset to Dvorak positions.

Dvorak must be applied per-device only (in `device` blocks), never in the global `input`.

### Desktop (b650e-desktop)

Configured in `home/profiles/desktop.nix` via `wayland.windowManager.hyprland.extraConfig`.

**Default `input` block** — plain US, no variant:
- Layout: `us`, Options: `caps:escape`
- No `kb_variant` — required for keybinds to resolve correctly

**Moonlander device blocks** — the ZSA Moonlander Mark I handles Dvorak remapping
at firmware level, so Hyprland must NOT apply the dvorak variant on top of it.
The Moonlander registers as multiple sub-devices; all are overridden:
- `zsa-technology-labs-moonlander-mark-i`
- `zsa-technology-labs-moonlander-mark-i-keyboard`
- `zsa-technology-labs-moonlander-mark-i-system-control`
- `zsa-technology-labs-moonlander-mark-i-consumer-control`

Each gets: `kb_layout = us`, `kb_variant =` (empty — must be explicit), `kb_options = caps:escape`

> **Key lesson**: `kb_variant` must be explicitly set to empty (`kb_variant =`) in a
> device block to clear the inherited global value. Omitting the key causes the device
> to inherit from the global `input` block.

**MelGeek Mojo68 device blocks** — standard keyboard, Dvorak applied by Hyprland (not firmware).
Registers as three sub-devices:
- `melgeek-mojo68`
- `melgeek-mojo68-system-control`
- `melgeek-mojo68-consumer-control`

Each gets: `kb_layout = us`, `kb_variant = dvorak`, `kb_options = caps:escape`

### Framework Laptop (future — `home/profiles/laptop.nix`)

- Global `input` block → plain US, **no `kb_variant`** (same as desktop — keybind rule)
- `at-translated-set-2-keyboard` (built-in) → device block with `kb_variant = dvorak`
- `zsa-technology-labs-moonlander-mark-i-*` → same Moonlander override blocks as desktop (empty variant)

---

## Cursor Setup

Cursor theme is set consistently across Wayland, GTK, and XWayland via three mechanisms:

- `home.pointerCursor` in `home/profiles/common.nix` — sets theme for home-manager
  managed apps and GTK (`gtk.enable = true`):
  - `name = "Adwaita"`, `package = pkgs.adwaita-icon-theme`, `size = 24`
- `env = XCURSOR_THEME,Adwaita` and `env = XCURSOR_SIZE,24` in Hyprland extraConfig
  — covers XWayland apps
- `exec-once = hyprctl setcursor Adwaita 24` in Hyprland extraConfig — applies
  cursor at session start for native Wayland apps

---

## Kernel (2026-02-21)

Pinned to `linuxPackages_6_19` in `hosts/b650e-desktop/configuration.nix`. Do **not**
use `linuxPackages_latest` — it auto-bumps to new major versions (e.g. 6.20.0) on
`nix flake update`, putting you on day-one kernels with potential regressions.

Linux 6.19.0 had kernel bugs (scheduler `sched_mm_cid_exit` page fault + futex `plist_del`
list corruption) causing full system freezes requiring hard power-off. The 6.19.x pin
picks up patch releases (6.19.1, 6.19.2, etc.) with fixes while avoiding 6.20.0.

**Intel Arc B580 constraint**: Don't go below `linuxPackages_6_18` — the xe driver
gets significant improvements each release. 6.18.10 is the confirmed-stable fallback.

When bumping kernels: change to `linuxPackages_6_XX` (not `_latest`), wait for a few
patch releases before adopting a new major version.

---

## Monitor Setup (2026-02-20)

Configured in `home/profiles/desktop.nix` via `monitor=` lines using `desc:` matching
(by make/model/serial) so configs survive port changes.

### Current layout

| Monitor | Serial | Resolution | Scale | Position | Logical size | Notes |
|---|---|---|---|---|---|---|
| Dell U4320Q | `30F6XN3` | 3840x2160@60 | 1.07 | 576x22 | 3589x2019 | Center-top |
| BOE Display | `demoset-1` | 2160x1440@60 | 1.2 | 1471x2041 | 1800x1200 | Below Dell, centered |
| LG HDR 4K | `0x0003E009` | 3840x2160@30 | 1.5 | 4165x22 | 1440x2560 | Right, portrait (transform 3) |
| LG HDR 4K | `0x00046040` | 3840x2160@30 | 1.5 | -864x22 | 1440x2560 | Left, portrait (transform 1) |

Fallback line `monitor=,preferred,auto,1` catches any unmatched monitor.

### Fractional scaling position gotchas

When a monitor uses a fractional scale (e.g. 1.07), its logical dimensions are
non-integer (e.g. 3840/1.07 = 3588.79). Adjacent monitors must be positioned at
integer coordinates, so perfect alignment is impossible. Hyprland may emit an
overlap warning when the next monitor's position rounds to the same pixel as the
fractional edge. This is cosmetic — the layout renders correctly.

**Key rules**:
- Changing a monitor's scale changes its logical size; all adjacent monitor
  positions must be recalculated
- Use `hyprctl keyword monitor "desc:...,RESxRES@HZ,XxY,SCALE"` to test positions
  live without rebuilding — but note that live scale changes can cause black bar
  artifacts that don't occur after a proper `nrs` rebuild
- Prefer scales that divide the resolution cleanly (e.g. 1.2 on 2160x1440 →
  1800x1200) to minimize fractional edge issues
- Hyprland may reject certain scales and suggest alternatives (e.g. 1.1 → 1.07)

### Named workspaces (2026-02-20)

Each monitor has 5 persistent named workspaces, configured in `home/profiles/desktop.nix`:

| Keys | Workspaces | Monitor |
|---|---|---|
| `Super+1–5` | desk1–desk5 | Dell U4320Q |
| `Super+6–0` | boe1–boe5 | BOE Display |

`Super+Shift+<key>` moves the focused window to that workspace.
Workspaces are pinned to monitors via `desc:` matching and created at login via `exec-once`.

**Important**: Workspace `monitor:` values must use the `desc:` prefix (e.g.
`monitor:desc:BOE Display demoset-1`) to match by description. Without `desc:`,
Hyprland treats the value as a connector name (like `DP-1`) and the match fails
silently, causing workspaces to land on the default monitor.

---

## Gradia / XDG Portal Screenshot

Gradia uses the XDG portal `org.freedesktop.portal.Screenshot` interface (via `libportal-gtk4`).
If it says "screenshot cancelled" immediately, the portal isn't providing the Screenshot interface.

### Root cause (diagnosed 2026-02-18)

The error is: `GDBus.Error:org.freedesktop.DBus.Error.UnknownMethod: No such interface
"org.freedesktop.portal.Screenshot"` — the frontend portal object doesn't expose Screenshot at all.

**Why**: NixOS sets `NIX_XDG_DESKTOP_PORTAL_DIR` which tells `xdg-desktop-portal` where to
find `.portal` definition files. Home-manager's `wayland.windowManager.hyprland.enable = true`
puts `hyprland.portal` in the **per-user** profile (`/etc/profiles/per-user/curtismchale/share/
xdg-desktop-portal/portals/`), and this overrides the system path. But `xdg-desktop-portal-gtk`
(from `xdg.portal.extraPortals` in the NixOS system config) only goes to the **system** profile
(`/run/current-system/sw/share/xdg-desktop-portal/portals/`). Result: the per-user portal dir
only has `hyprland.portal`, and `gtk.portal` is missing.

The `portals.conf` references `gtk` in `default=hyprland;gtk`, but `gtk.portal` doesn't exist
in the per-user dir. This causes repeated "Requested gtk.portal is unrecognized" errors and
breaks interface resolution for Screenshot (even though hyprland supports it — likely a bug in
xdg-desktop-portal 1.20.3 where unresolvable portal names in the default list interfere with
specific interface entries).

Key evidence: `grim` works fine directly (bypasses portal). The hyprland backend D-Bus service
DOES expose `org.freedesktop.impl.portal.Screenshot`. Running `xdg-desktop-portal --verbose`
with the **system** portal dir (both .portal files) provides Screenshot correctly.

### Fix (confirmed working 2026-02-18)

Two changes:

1. **`home/profiles/common.nix`**: Added `xdg-desktop-portal-gtk` to `home.packages` so
   `gtk.portal` appears in the per-user profile alongside `hyprland.portal`.

2. **`modules/hyprland.nix`**: Added a `Hyprland` desktop-specific section to
   `xdg.portal.config` (in addition to `common`) so the portal uses a section matching
   `XDG_CURRENT_DESKTOP=Hyprland` instead of the generic `[preferred]` fallback.

Portal config changes require a full **logout and back in** to take effect — `hyprctl reload`
is not sufficient.

---

## Sinkswitch (2026-02-18)

PipeWire audio output switcher (fzf-based, designed for Hyprland).
Source: https://github.com/Seyloria/sinkswitch

- Script vendored at `home/assets/sinkswitch/sinkswitch.sh`, installed to
  `~/.local/bin/sinkswitch.sh` via `home.file`
- `Super+S` launches it in a floating kitty window (title `sinkswitch`)
- Windowrule `float-sinkswitch` in `desktop.nix`: float, 600x400, centered
- Dependencies: `fzf`, `wpctl` (wireplumber)
- Supports `-exclude` flag to hide specific sink IDs

---

## Wallpaper + Lock Screen + Idle (2026-02-19)

Random wallpaper rotation using **swww**, lock screen via **hyprlock**, idle management
via **hypridle**. All configured in `home/profiles/common.nix` (hyprlock/hypridle) and
`home/profiles/desktop.nix` (swww autostart, keybind).

### swww (wallpaper daemon)

- Starts on login: `exec-once = swww-daemon && sleep 0.5 && bash ~/.local/bin/rotate-wallpaper.sh`
- `rotate-wallpaper.sh` picks a random image from `~/Pictures/wallpaper` and sets it
  with a grow transition (2s, 60fps)
- Wallpaper rotates on every unlock (called by `lock-and-rotate.sh`)

### hyprlock (lock screen)

- Hyprland-native, configured via `programs.hyprlock` in `common.nix`
- PAM auth enabled via `programs.hyprlock.enable = true` in `modules/hyprland.nix`
  (without this, hyprlock locks but **cannot unlock**)
- Theme: blurred screenshot background, neon cyan clock + password field
- 5-second grace period (unlock without password if locked < 5s ago)
- Manual lock: `Super+L` (runs `loginctl lock-session`)

### hypridle (idle daemon)

- Configured via `services.hypridle` in `common.nix` (home-manager systemd service)
- `lock_cmd` → `lockAndRotate` writeShellScript wrapper (sets PATH for NixOS)
- `before_sleep_cmd` → `loginctl lock-session` (locks before suspend)
- `after_sleep_cmd` → `hyprctl dispatch dpms on` (screen on after wake)
- Listener 1: Lock after 300s (5 min) idle
- Listener 2: DPMS off after 600s (10 min) idle

### Scripts

- `home/assets/wallpaper/rotate-wallpaper.sh` → `~/.local/bin/rotate-wallpaper.sh`
- `home/assets/wallpaper/lock-and-rotate.sh` → `~/.local/bin/lock-and-rotate.sh`
  (kept for reference, but hypridle now uses the `lockAndRotate` writeShellScript wrapper
  in `common.nix` instead — the asset script is no longer called directly by hypridle)

**NixOS PATH gotcha**: hypridle runs commands via `/bin/sh`, which has a minimal PATH
that does NOT include `bash` or most user-profile binaries. Any command in `lock_cmd`,
`before_sleep_cmd`, etc. must either use absolute Nix store paths or a `writeShellScript`
wrapper that sets PATH explicitly. `loginctl` and `hyprctl` happen to be in
`/run/current-system/sw/bin/` (included in `/bin/sh`'s PATH), but `bash`, `hyprlock`,
`swww`, etc. are not.

After `nrs`, must **log out and back in** for hypridle to start (systemd user service).

---

## Framework Battery / Power Supply (2026-03-01)

Power supply devices exposed by the Framework laptop:
- `BAT1` — the battery
- `ACAD` — the AC adapter (what Waybar's battery module must use as `adapter`)
- `ucsi-source-psy-USBC000:001` through `004` — the four USB-C ports

Waybar's battery module defaults to adapter `AC` — always set `bat = "BAT1"` and
`adapter = "ACAD"` explicitly in the laptop bar config.

**Do NOT set `networking.networkmanager.wifi.powersave = false`** on the Framework —
it broke networking entirely. For boot-time WiFi, save the connection as a system
connection (see WiFi section below).

## Framework WiFi — System Connections (2026-03-01)

To make a WiFi network auto-connect at boot (before keyring unlocks):

```bash
sudo nmcli connection modify "NetworkName" connection.permissions ""
sudo nmcli connection modify "NetworkName" wifi-sec.psk-flags 0 wifi-sec.psk "password"
```

Verify: `sudo cat /etc/NetworkManager/system-connections/NetworkName.nmconnection`
should show `psk=password` with no `psk-flags` line (or `psk-flags=0`).

Credentials live in `/etc/NetworkManager/system-connections/` — not Nix-managed,
persists across rebuilds.

## Waybar Laptop Bar Architecture (2026-03-01)

The laptop bar is defined in `home/profiles/laptop.nix` and merged with the desktop
bars from `waybar.nix` via home-manager list concatenation.

**Critical**: `moduleConfig` in `waybar.nix` is a Nix `let` binding — it is only
merged into the desktop bars via `moduleConfig //`. The laptop bar does NOT inherit
these module configs. Every module that needs non-default format strings or icons
must be explicitly configured in the laptop bar in `laptop.nix`.

`laptop.nix` has its own `let i = code: builtins.fromJSON "\"\\u${code}\"";` helper
to match the one in `waybar.nix`.

## Waybar (2026-02-24)

Configured in `home/profiles/waybar.nix` (imported by `common.nix`). Uses
`systemd.enable = true` so it runs as a systemd user service bound to
`graphical-session.target`.

**Multi-bar setup**: Two named bar instances targeting monitors by output description:
- `dell` bar → `Dell Inc. DELL U4320Q 30F6XN3` — includes MPD module in `modules-left`
- `other` bar → BOE + both LG monitors — no MPD

Waybar uses raw output descriptions for the `output` field (e.g.
`"Dell Inc. DELL U4320Q 30F6XN3"`). Do NOT use Hyprland's `desc:` prefix — Waybar
won't match it and the bar will not appear. Multiple bar configs must have unique
`name` fields and explicit `output` lists (a bar with no `output` shows on ALL monitors).

**Clock format**: `{:%b %d  %H%M}` — e.g. `Feb 24  1321`. Click toggles to
`{:%Y-%m-%d}` (alt format).

**Logout/login fix**: On logout, the Wayland socket disappears. Three systemd user
services crash and hit restart rate limits before the new session propagates
`WAYLAND_DISPLAY`: `xdg-desktop-portal-hyprland` (segfaults in `CCWlOutput` cleanup),
`xdg-desktop-portal` (times out reaching the dead hyprland backend after 25s), and
`waybar` (crashes when the portal timeout propagates). An `exec-once` in `desktop.nix`
imports the env vars and restarts all three in dependency order:
```
exec-once = sleep 2 && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user reset-failed xdg-desktop-portal-hyprland.service xdg-desktop-portal.service waybar.service 2>/dev/null; systemctl --user restart xdg-desktop-portal-hyprland.service && sleep 1 && systemctl --user restart xdg-desktop-portal.service && systemctl --user restart waybar.service
```
The `sleep 2` avoids a race where `exec-once` fires before Hyprland finishes propagating
the Wayland socket. The restart order matters: hyprland portal first (backend), then
portal frontend (needs backend), then waybar (needs portal for appearance detection).

**Desktop-irrelevant modules**: The config includes `temperature`, `backlight`, `battery`,
and `power-profiles-daemon` which log warnings on the desktop (no thermal zone, no
backlight, no batteries, no power-profiles-daemon). These are harmless — the modules
auto-disable — but could be moved to a laptop-only config later.

---

## OBS Studio (2026-02-18)

Installed in `home/profiles/common.nix` via `wrapOBS` with plugins:
- `obs-vaapi` — hardware encoding via VA-API (Intel Arc B580)
- `obs-pipewire-audio-capture` — per-app PipeWire audio capture
- `wlrobs` — Wayland screen capture (Hyprland/wlroots)
- `obs-vkcapture` — Vulkan/OpenGL game capture

Hardware encoding depends on `intel-media-driver` in `modules/desktop.nix`.

---

## Intel Arc B580 GPU (2026-02-18)

Desktop has an Intel Arc B580 discrete GPU. Compute and video acceleration configured
in `modules/desktop.nix` via `hardware.graphics.extraPackages`:
- `intel-media-driver` — VA-API (iHD) hardware video decode/encode
- `vpl-gpu-rt` — oneVPL / Quick Sync Video
- `intel-compute-runtime` — OpenCL + Level Zero

`LIBVA_DRIVER_NAME = "iHD"` set as a session variable.

**Do NOT** set `services.xserver.videoDrivers = [ "intel" ]` — causes boot failures
with Arc. The default `modesetting` driver is correct.

**DaVinci Resolve**: Not officially supported on Intel GPUs on Linux. Known crashes
and CL/GL interop bugs with B580. Installed but not reliable — use Kdenlive instead.

**Fan control**: Not possible on Linux — the xe driver exposes fan RPM readings
(`fan1_input`, `fan2_input`) but no PWM control. Fans are firmware-controlled only.
LACT greys out fan controls correctly.

**Hardware encoding in Kdenlive**: Use VA-API encoders (not QSV — QSV fails to find
Intel runtime libs on NixOS). Available: `hevc_vaapi`, `h264_vaapi`, `av1_vaapi`.
AV1 is the best quality-per-bit option on Arc.

**GPU monitoring**: btop cannot monitor the Arc B580 — the xe driver doesn't expose
the `gpu_busy_percent` / `mem_info_*` sysfs entries btop reads. Use `nvtop` or
`sudo intel_gpu_top` instead. The AMD iGPU (card1) does have these entries but btop
still doesn't show a GPU box.

---

## System Monitoring (2026-02-20)

Installed in `home/profiles/common.nix`:
- `btop` — CPU, RAM, network, processes (no Intel GPU support)
- `nvtopPackages.intel` — GPU monitor with Intel xe driver support
- `intel-gpu-tools` — `sudo intel_gpu_top` for per-engine Arc B580 stats
- `lm_sensors` — `sensors` CLI (system package in `modules/desktop.nix`)

For full coverage, run `nvtop` and `btop` in separate Zellij panes.

---

## Fan Monitoring & Control (2026-02-20)

Configured in `modules/desktop.nix`:
- `boot.kernelModules = [ "nct6775" ]` — ASUS B650E Super I/O chip, exposes
  motherboard fan RPMs and PWM control via hwmon
- `programs.coolercontrol.enable = true` — GUI + `coolercontrold` daemon for fan curves
- `lm_sensors` — `sensors` command for CLI monitoring

The nct6775 module exposes 7 fan headers (fan1–fan7). Without loading this module,
no motherboard fan data is visible to userspace.

---

## File Manager — Thunar (2026-02-20)

Switched from Dolphin to Thunar. Dolphin's "Open With" dialog was empty because
KDE's sycoca database doesn't stay updated outside a full Plasma session.

Installed in `home/profiles/common.nix`: `thunar`, `thunar-archive-plugin`,
`thunar-volman`, `tumbler` (thumbnails). These packages are top-level in nixpkgs
(not under `xfce.*`).

`$fileManager = thunar` set in `home/profiles/desktop.nix`.

Thunar progress dialogs (Moving/Copying/Deleting/Renaming) floated via windowrule
in `desktop.nix`.

---

## Google Cloud SDK (2026-02-18)

Installed in `home/profiles/common.nix` via `google-cloud-sdk.withExtraComponents`:
- `gke-gcloud-auth-plugin` — required for kubectl auth with GKE clusters
- `kubectl` — bundled kubectl from Google Cloud SDK

**Important**: `gcloud components install` does not work on NixOS (read-only Nix store).
All extra components must be declared via `withExtraComponents` in the Nix expression.

---

## Hyprland Windowrule Notes

- Use the new `windowrule` block format — `windowrulev2` is deprecated
- Float action: `float = on` (not `float = yes`)
- Regex is **full-match**: `^Copying` won't match "Copying — Dolphin"; use `Copying.*`
- Match field names use underscores: `match:initial_class`, `match:initial_title`
- KDE dialog-type windows (e.g. overwrite confirm) float automatically; normal-type
  windows (e.g. Dolphin copy progress) require an explicit `float = on` rule

---

## Hyprland Config Management

Hyprland config is managed entirely by home-manager via
`wayland.windowManager.hyprland.extraConfig` in the relevant profile.

Do **not** manually edit `~/.config/hypr/hyprland.conf` — it is generated on `nrs`
and will be overwritten.

After `nrs`, Hyprland picks up the new config on next login. To apply mid-session:
```
hyprctl reload
```

To test a per-device setting without rebuilding:
```
hyprctl keyword "device[device-name]:kb_variant" ""
```
Use `hyprctl devices` to see exact device names and current rules.

---

## Glacier NAS Mount

The Glacier SMB share is configured in `modules/base.nix` (applies to all machines) using
NixOS `fileSystems` with `x-systemd.automount`. It mounts on first access and unmounts
after 5 minutes idle. The machine will boot normally even if Glacier is offline (`nofail`).

- **Device**: `//glacier.local/glacier-shared`
- **Mount point**: `/home/curtismchale/Glacier` (i.e. `~/Glacier`)
- **Tools**: `cifs-utils` is installed system-wide
- **mDNS**: `services.avahi` (with `nssmdns4 = true`) is enabled in `base.nix` — required
  for `.local` hostname resolution. Without it, mount fails with "could not resolve address".

> **Debugging note**: The share name `glacier-shared` was discovered (not guessed) using:
> ```bash
> nix-shell -p samba --run "smbclient -L glacier.local -U curtismchale%PASSWORD"
> ```
> The NAS exposes: `glacier-shared`, `homes`, `PlexMediaServer`, `home`.

### One-time manual setup required per machine

The credentials file is intentionally **not** managed by Nix — the Nix store is
world-readable, so secrets must never go in it.

Create the file and lock it down:

```bash
install -m 600 /dev/null ~/.smbcredentials
```

Then edit it with exactly these two lines:

```
username=YOUR_GLACIER_USERNAME
password=YOUR_GLACIER_PASSWORD
```

The file must be owned by your user and mode `600` (no group/other read).
Verify with `ls -la ~/.smbcredentials`.

After `nrs`, the mount activates automatically the first time you `ls ~/Glacier` or
navigate there in Dolphin. To trigger it manually:

```bash
systemctl start home-curtismchale-Glacier.mount
```

---

## Claude Code Package

`claude-code` is installed via `home/profiles/common.nix` directly from `nixpkgs-unstable`.

The `claude-code-overlay` input was removed from `flake.nix` — its `prev.system` usage in
the overlay triggered a nixpkgs deprecation warning (`'system' has been renamed to
'stdenv.hostPlatform.system'`). Since `claude-code` is now in nixpkgs-unstable natively,
the overlay is no longer needed.

The `allowUnfreePredicate` in `flake.nix` still includes `"claude-code"` since it remains
an unfree package.

---

## LM Studio + llmster CLI (2026-02-21)

LM Studio GUI is installed from nixpkgs (`lmstudio` in `common.nix`). The `lms` CLI
bundled with the nixpkgs AppImage segfaults on NixOS (v0.4.2) — patchelf corrupts
embedded JS data inside the node/bun single-executable binaries.

**llmster** is LM Studio's standalone headless daemon, packaged as an inline
`stdenv.mkDerivation` in `home/profiles/common.nix`. Binaries are left **unpatched** —
`nix-ld` (enabled in `modules/base.nix`) provides `/lib64/ld-linux-x86-64.so.2` and
standard shared libraries at runtime.

- Source: `https://llmster.lmstudio.ai/download/0.0.3-2-linux-x64.full.tar.gz`
- `dontPatchELF = true; dontStrip = true; dontFixup = true;` — critical, patchelf
  breaks node/bun binaries with embedded JS payloads
- `home.activation.llmsterBootstrap` runs `llmster bootstrap` on every `nrs`, which
  installs the working `lms` CLI to `~/.lmstudio/bin/`
- `home.sessionPath` adds `~/.lmstudio/bin` so the working `lms` is found before the
  broken nixpkgs one (requires logout/login after first `nrs`)
- Added `"llmster"` to unfree allowlist in `flake.nix`

**Important**: `llmster` and the LM Studio GUI cannot run simultaneously. Close the
GUI before running `llmster`, or use the GUI's built-in server instead.

The Vulkan hardware survey fails (harmless warning) — falls back to CPU survey. The
`nvidia-smi` "not found" warning is expected (Intel GPU system).

**To update llmster**:
```bash
nix-prefetch-url https://llmster.lmstudio.ai/download/<NEW_VERSION>-linux-x64.full.tar.gz
nix hash convert --hash-algo sha256 --to sri <hash>
```
Replace version and hash in the `llmster` derivation in `common.nix` and `nrs`.

---

## Image Tools (2026-02-19)

CLI tools for converting and resizing images, installed in `home/profiles/common.nix`.

- **`heif-convert`** — converts HEIF/HEIC to JPG/PNG/WebP/etc. Inline
  `buildPythonApplication` derivation (not in nixpkgs). Source: `github:NeverMendel/heif-convert` v1.2.1.
  Requires `pyproject = true` and `build-system = [ setuptools ]`.
- **`imagemagick`** — general image resize/convert (`magick` command)

Also installed (image optimization): `optipng`, `jpegoptim`, `advancecomp`,
`pngcrush`, `ghostscript`.

---

## TablePlus (2026-02-19)

Database management GUI installed via AppImage wrapping (nixpkgs package is unmaintained).

- Derivation: inline `appimageTools.wrapType2` in `home/profiles/common.nix`
- Source: `https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage`
- Added to unfree allowlist in `flake.nix`
- `.desktop` file already has `Exec=tableplus` — no `substituteInPlace` needed

**To update** (same URL, new binary):
```bash
nix-prefetch-url https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage
nix hash convert --hash-algo sha256 --to sri <hash>
```
Replace hash in `common.nix` and `nrs`.

---

## MPD + rmpc

Music playback via MPD with rmpc as the TUI client.

### MPD

Configured in `home/profiles/common.nix` via `services.mpd` (all hosts):
- Music: `~/Music`, Playlists: `~/Music/playlists`, Data: `~/.local/state/mpd`
- Audio output: PulseAudio type (works via PipeWire's PulseAudio compat layer)
- `auto_update` and `restore_paused` enabled

### rmpc

- Package: `rmpc` (+ `ueberzugpp` installed but unused)
- Config: `~/.config/rmpc/config.ron` via `xdg.configFile` in `common.nix`
- Album art method: `Kitty` (Kitty graphics protocol)

### Album art — why rmpc-kitty alias is required

Album art via the Kitty graphics protocol does **not** work when rmpc runs inside
Zellij. Zellij intercepts the terminal escape sequences and the image renders in the
wrong position, causing other windows to be disrupted.

**Attempted alternative**: `UeberzugWayland` — creates a Wayland layer surface overlay,
bypassing terminal escape codes entirely. Does not appear in `hyprctl clients` (not a
normal window). Rejected because ueberzugpp cannot correctly map terminal cell
coordinates to screen positions when running inside a multiplexer, so images still
render in wrong positions.

**Working solution**: `rmpc-kitty` alias — `kitty --detach rmpc`

Spawns a **fresh standalone kitty window** running rmpc directly (no Zellij, no shell
autostart). The Kitty graphics protocol renders album art inline at the correct
coordinates. Key detail: `--single-instance` was intentionally removed — that flag
reuses the existing kitty process which may have Zellij running in it, causing the
same misplaced-image problem.

To launch: `rmpc-kitty`

---

## Syncthing

Configured as a NixOS system service in `modules/base.nix` (all machines).
Starts at boot before login, runs as `curtismchale`.

- Data dir: `~`, config dir: `~/.config/syncthing`
- Ports 22000 and 21027 opened in firewall via `openDefaultPorts = true`
- Folders and devices are configured via the web UI (not declaratively managed)

---

## Doom Emacs

Installed via `emacs-pgtk` (native Wayland) + `nerd-fonts.symbols-only` in `common.nix`.
Doom itself is installed manually — see README for steps.

**Key gotchas**:
- `~/.emacs.d` existing causes Emacs to ignore `~/.config/emacs` — rename it on new machines
- Doom v3 has no root `init.el`; uses profile system bootstrapped via `early-init.el`
- Missing icons = missing Nerd Fonts; run `fc-cache -f` after installing
- feedsmith local dev package needs `:host github :repo` so Doom can clone on new machines

---

## lsd

`lsd` (modern `ls` replacement) is installed in `home/profiles/common.nix` with these
aliases (all hosts):

| Alias | Command |
|---|---|
| `l` | `lsd -l` |
| `la` | `lsd -a` |
| `lla` | `lsd -la` |
| `lt` | `lsd --tree` |

---

## Notifications (Mako)

Notifications are handled by **Mako** (not Dunst) — native Wayland, purpose-built for
wlr-based compositors like Hyprland. Configured in `home/profiles/common.nix` via
`services.mako` (applies to all machines). `libnotify` is installed for `notify-send`.

### Theme

Neon cyberpunk palette matching Waybar. Global settings use `services.mako.settings`;
criteria sections use `extraConfig` (nested attrsets generate `[[double brackets]]` which
mako does not support — must use raw INI in `extraConfig`).

| Urgency | Background | Border | Meaning |
|---|---|---|---|
| low | `#001a07ff` dark green | `#00ff00cc` neon green | Minor / informational |
| normal | `#001a26ee` dark cyan | `#00bfffee` neon cyan | Standard |
| critical | `#1a0010ff` dark pink | `#ff1493` hot pink | Urgent — no timeout |

To test all three levels:
```bash
notify-send -u low "Low" "Something minor"
notify-send "Normal" "Standard notification"
notify-send -u critical "Critical" "Something urgent"
```

To reload without re-login:
```bash
systemctl --user restart mako
```

---

## Clipboard (cliphist)

`cliphist` is installed in `home/profiles/common.nix` alongside `wl-clipboard`.

A systemd user service `cliphist-watcher` is defined in `common.nix` (applies to all machines).
It runs two `wl-paste --watch` processes (one for text, one for images) that pipe every
clipboard change into `cliphist store`, populating the history database.

The service script waits up to 20 seconds for the Wayland socket before exiting so
systemd can retry — safe for use with `WantedBy = default.target`.

The `Super+V` keybind in `desktop.nix` invokes the picker:
```
bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
```

To check service status:
```
systemctl --user status cliphist-watcher
```
