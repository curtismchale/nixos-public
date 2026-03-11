# NixOS Configuration

Flakes-based NixOS configuration for multiple machines. Currently managing:

- **b650e-desktop** — AMD B650E desktop (primary, fully configured)
- **framework** — Framework laptop (currently running Fedora + home-manager; NixOS migration planned)

## Structure

```
/etc/nixos/
├── flake.nix                        # Entry point — defines all hosts and inputs
├── modules/
│   ├── base.nix                     # Shared system config (applied to all hosts)
│   ├── desktop.nix                  # KDE Plasma 6 + SDDM (desktop machines)
│   └── hyprland.nix                 # Hyprland compositor + Wayland tools
├── hosts/
│   └── b650e-desktop/
│       ├── configuration.nix        # Host-specific: hostname, boot, LUKS, state version
│       └── hardware-configuration.nix  # Auto-generated, do not hand-edit
└── home/
    ├── curtismchale.nix             # Home Manager entry point (selects profiles per host)
    └── profiles/
        ├── common.nix               # User packages and config shared across all machines
        ├── desktop.nix              # Desktop-specific user config (currently empty)
        └── laptop.nix               # Laptop-specific user config (currently empty)
```

## Layer Responsibilities

| Layer | File(s) | Purpose |
|---|---|---|
| System shared | `modules/base.nix` | Networking, locale, audio, user account, nix-ld |
| System per-type | `modules/desktop.nix`, `modules/hyprland.nix` | DE, WM, display manager |
| System per-host | `hosts/<name>/configuration.nix` | Hostname, bootloader, LUKS, kernel |
| User shared | `home/profiles/common.nix` | Packages, shell, git, dev tools |
| User per-type | `home/profiles/desktop.nix`, `home/profiles/laptop.nix` | Machine-type user config |

`home/curtismchale.nix` selects which profiles to load based on hostname.

## Common Commands

All commands should be run from any directory; they use the system flake at `/etc/nixos`.

```bash
# Test a build without activating
nrt

# Rebuild and switch (standard deploy)
nrs

# Edit NixOS config and rebuild
enix   # alias: opens config dir in editor
```

These aliases are defined in `home/profiles/common.nix`.

## Adding a New Machine

1. **Create the host directory:**
   ```
   hosts/<hostname>/
   ├── configuration.nix
   └── hardware-configuration.nix
   ```

2. **Generate hardware config on the target machine:**
   ```bash
   nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
   ```

3. **Write `configuration.nix`** — copy from `hosts/b650e-desktop/configuration.nix` and update:
   - `networking.hostName`
   - `boot.initrd.luks.devices` (LUKS UUID from the new disk)
   - Module imports (swap `desktop.nix` for a `laptop.nix` module if needed)
   - `system.stateVersion`

4. **Register the host in `flake.nix`** under `nixosConfigurations`:
   ```nix
   <hostname> = mkHost {
     hostname = "<hostname>";
     extraModules = [ ./modules/base.nix ./modules/hyprland.nix ];
   };
   ```

5. **Update `home/curtismchale.nix`** to import the correct profile for the new hostname.

6. **Deploy** on the new machine:
   ```bash
   nixos-rebuild switch --flake /etc/nixos#<hostname>
   ```

## Adding a New System Module

Put system-level config (services, packages available system-wide) in `modules/`.

- If it applies to **all machines**: add it to `base.nix` or create a new module and import it in `flake.nix` `extraModules` for each host.
- If it applies to **a machine type** (desktop vs laptop): create `modules/laptop.nix` and import it per host.
- If it applies to **one machine only**: put it directly in `hosts/<hostname>/configuration.nix`.

## Adding User-Level Config

User packages, dotfiles, and shell config go in `home/profiles/`.

- Shared across all machines → `common.nix`
- Desktop-specific → `desktop.nix`
- Laptop-specific → `laptop.nix`

Home Manager is integrated into the NixOS build; `home-manager switch` is not needed separately.

## Key Details

- **Nixpkgs channel**: `nixpkgs-unstable`
- **User**: `curtismchale` (wheel, networkmanager groups; zsh shell)
- **Disk encryption**: LUKS on all hosts (UUID varies per machine)
- **Kernel**: `linuxPackages_6_19` on desktop (pinned — see Kernel section below)
- **Unfree packages**: Explicit allowlist in `flake.nix` (`allowUnfreePredicate`); currently allows `claude-code`, `protonmail-bridge`, `protonmail-desktop`, `protonvpn-gui`
- **Claude Code**: Installed directly from `nixpkgs-unstable` (no overlay needed)
- **Git signing**: SSH signing with `~/.ssh/id_ed25519.pub`

## Setup

One-time setup steps required after rebuilding on a new machine or after first installing a package.

### Doom Emacs

Emacs (`emacs-pgtk`, native Wayland) is installed via Nix. Doom itself is not packaged
in nixpkgs — it must be installed manually once per machine.

1. Clone Doom:
   ```bash
   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
   ```

2. Run the installer:
   ```bash
   ~/.config/emacs/bin/doom install
   ```

3. Bring in your personal Doom config (your `~/.config/doom` repo):
   ```bash
   mv ~/.config/doom ~/.config/doom.bak
   git clone git@github.com:curtismchale/doom.git ~/.config/doom
   doom sync
   ```

The `doom` shell alias in `common.nix` points to `~/.config/emacs/bin/doom` so `doom sync`,
`doom upgrade`, etc. work from any terminal after the install.

Doom dependencies (`ripgrep`, `fd`, `gcc`, `nodejs`) are already installed via `common.nix`.

---

### Glacier NAS

The Glacier SMB share mounts automatically at `~/Glacier` on first access. Before this will
work, you must create a credentials file on each machine — this is intentionally not managed
by Nix since the Nix store is world-readable.

1. Create the file with restricted permissions:
   ```bash
   install -m 600 /dev/null ~/.smbcredentials
   ```

2. Edit it and add exactly these two lines:
   ```
   username=YOUR_GLACIER_USERNAME
   password=YOUR_GLACIER_PASSWORD
   ```

3. Verify the permissions are correct:
   ```bash
   ls -la ~/.smbcredentials
   # should show: -rw------- 1 curtismchale ...
   ```

After `nrs`, navigate to `~/Glacier` in any terminal or in Dolphin and the share will mount
automatically. If it fails, check the mount log:

```bash
journalctl -u home-curtismchale-Glacier.mount -n 20
```

### Protonmail

Three packages are installed: `protonmail-bridge`, `protonmail-desktop`, and `protonvpn-gui`. Each requires a separate first-time login.

**Protonmail Desktop**

Just launch it and sign in. Nothing special required.

**ProtonVPN**

Launch `protonvpn-gui` and sign in with your Proton account credentials.

**Protonmail Bridge**

The bridge runs a local IMAP/SMTP proxy so that a standard email client can talk to Protonmail. It must be authenticated before your email client will work.

1. Launch the bridge GUI from your app launcher or run `protonmail-bridge` in a terminal.
2. Sign in with your Proton account credentials.
3. Once authenticated, the bridge will show you a **bridge password** — this is a separate, generated password (not your Proton account password). Note it down; your email client will use it.
4. The bridge listens on:
5. Configure your email client with those ports and the bridge password.
6. The bridge should autostart on login via its desktop autostart entry. If it does not, you may need to add a systemd user service or autostart entry — note this in the config when resolved.

---

### Image Conversion and Resizing

Tools for converting HEIF/HEIC images (e.g. from iPhones) and general image manipulation.

**Convert HEIF/HEIC to other formats** (`heif-convert`):

```bash
# Single file
heif-convert input.heic output.jpg

# Set quality (0-100)
heif-convert -q 90 input.heic output.jpg

# Batch convert all HEIC files to a directory
heif-convert *.heic -o /output/dir
```

**Resize and convert images** (`magick` / ImageMagick):

```bash
# Resize to specific dimensions (maintains aspect ratio)
magick input.jpg -resize 1920x1080 output.jpg

# Resize by percentage
magick input.jpg -resize 50% output.jpg

# Force exact dimensions (ignores aspect ratio)
magick input.jpg -resize 1920x1080! output.jpg

# Batch resize in-place
magick mogrify -resize 1920x1080 *.jpg

# Convert and resize
magick mogrify -format jpg -resize 1920x1080 *.HEIC

# Convert between formats
magick input.png output.webp
magick input.heic output.jpg
```

**Optimize images** (already installed):

```bash
# Optimize PNG
optipng input.png
pngcrush input.png output.png

# Optimize JPEG
jpegoptim --max=85 input.jpg

# Optimize GIF/PNG (recompress)
advpng -z -4 input.png
```

---

## Framework Migration Context

The Framework laptop currently runs **Fedora with a standalone home-manager configuration** at `~/Downloads/home-manager` on this machine. The goal is:

1. Port that config to this NixOS desktop (with changes as needed)
2. Stabilize the desktop as the primary work machine
3. Then install NixOS on the Framework and bring it in as a proper host

The Fedora home-manager config is the reference for what the working environment should look like. Key things it has that this NixOS config does not yet have:

**Hyprland / desktop environment:**
- Waybar status bar (with MPD track info on primary monitor) — `hypr/waybar.nix`
- Dunst notifications — `hypr/dunst.nix`
- Rofi app launcher — `hypr/rofi.nix`
- Cliphist clipboard manager with systemd service — `hypr/cliphist.nix`
- Full Hyprland keybindings (Dvorak-based: H/T/C/N for directional focus/move)
- Hyprpaper wallpaper daemon

**Applications:**
- Lazygit
- LSD (modern `ls` replacement)
- MPV, SOX, cmus, rmpc, MPD music stack
- Pass (password manager, Wayland-compatible)
- Protonmail Bridge + Desktop, ProtonVPN GUI
- Stripe CLI, WP-CLI
- Various language servers: nil, intelephense, marksman, bash-language-server, yaml-language-server
- Fonts: noto, dejavu, font-awesome (needed for Waybar icons)

**Services / modules:**
- SSH agent as a systemd user service (auto-adds `~/.ssh/id_ed25519` on login)
- SMB/CIFS mount module (mounts to `~/Glacier` by default)
- OBSBot camera setup via v4l2 controls + systemd service
- MPD as a home-manager service
- RMPC music client config (Kitty album art protocol)

**Shell:**
- `ffedit` ffmpeg function (same as desktop, confirm it's already in common.nix)
- Composer vendor/bin on PATH

**Zellij:**
- Custom KDL keybindings (Dvorak navigation) — `modules/zellij/config.kdl`
- Needs to be ported into `home/profiles/common.nix` or a dedicated module

**Monitor layout (Framework-specific, goes in laptop home profile):**
- Framework built-in: 2256x1504@60Hz, 1.333 scale (eDP-1)
- Dell U4320Q: 3840x2160@60Hz
- Two LG 4K displays: 3840x2160@30Hz with transforms
- Dvorak on built-in keyboard, US layout on Moonlander

**Keyboard (Framework-specific):**
- Dvorak on `at-translated-set-2-keyboard` (built-in)
- US on `zsa-technology-labs-moonlander-mark-i`
- Caps Lock → Escape on both

Things intentionally **not** porting or differing on the desktop:
- OBSBot module (desktop may not have same USB path — verify)
- Monitor layout (desktop has different monitors, needs its own Hyprland config)
- Keyboard layout (desktop may not have the Framework built-in keyboard)
- nixpkgs channel: Fedora config uses `nixos-25.05`; this NixOS config uses `nixpkgs-unstable` — packages should be available in both but versions may differ

## Pending Work

- [x] deal with garbage collection
- [x] Tableplus
- [x] devenv - does anything need to be install in nix first?
- [x] add HEIC image conversion to tooling and create an alias for it
- [ ] the highlight around windows in hyprland isn't very noticable aim for a hot pink and make it a bid wider
- [ ] ?? add workspace number to the top of the screen or some indicator in waybar?
- [x] add a lock/sleep system so the computer locks when I'm away for a bit but processes still run in the background
- [ ] the login screen sddm is ugly
- [ ] Add Hyprland keybindings for desktop monitors to `modules/hyprland.nix`
- [ ] Port SSH agent systemd service from `~/Downloads/home-manager/modules/ssh-agent.nix`
- [ ] `home/profiles/desktop.nix` — desktop-specific user config (monitor layout, OBSBot if applicable)
- [ ] `home/profiles/laptop.nix` — Framework-specific user config (monitor layout, keyboard layout, battery/backlight)
- [ ] `hosts/framework/` — generate hardware config and write configuration.nix when the laptop is available
- [ ] Consider extracting a `modules/laptop.nix` system module when laptop needs diverge from desktop

---

## Kernel Version Management

**Current**: `linuxPackages_6_19` (pinned to 6.19.x series) in `hosts/b650e-desktop/configuration.nix`.

### Why pinned (2026-02-21)

Linux 6.19.0 has kernel bugs in the scheduler (`sched_mm_cid_exit`) and futex subsystem
(`plist_del` via `futex_wake`) that cause full system freezes requiring hard power-off.
Two freeze events confirmed:

1. Returning from idle — kernel page fault in scheduler CID cleanup, cascading NULL deref
   in WiFi/mac80211 stack. Mouse moved but nothing else responded.
2. During stress-ng / CoolerControl — linked list corruption in futex subsystem (happened
   *before* stress-ng started), cascaded into soft lockups on multiple CPUs.

Both are core kernel regressions in code refactored during the 6.18→6.19 cycle.

### What the pin does

`linuxPackages_6_19` tracks the 6.19.x patch series (6.19.1, 6.19.2, etc.) which will
include fixes for these bugs as they're backported. It does **not** auto-bump to 6.20.0
when that releases (unlike `linuxPackages_latest`).

### Action items

- [ ] **Check kernel stability**: After a few weeks on 6.19.x patches, confirm no more
  freezes. If freezes persist, fall back to `linuxPackages_6_18` (6.18.10, confirmed stable,
  full Intel Arc B580 xe driver support).
- [ ] **Evaluate 6.20**: When Linux 6.20 has a few patch releases (6.20.2+), consider
  switching to `linuxPackages_6_20` for continued xe driver improvements. Do NOT use
  `linuxPackages_latest` — it will put you on 6.20.0 day one.
- [ ] **Intel Arc B580 consideration**: Don't roll back further than 6.18 — the xe driver
  gets significant improvements each kernel release and older kernels may lack performance
  features or bug fixes for the B580.
