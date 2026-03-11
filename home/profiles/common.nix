{ pkgs, config,inputs,lib, ... }:

let
  lockAndRotate = pkgs.writeShellScript "lock-and-rotate" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.hyprlock pkgs.procps pkgs.swww pkgs.coreutils pkgs.findutils pkgs.bash ]}:$PATH

    # Guard against duplicate hyprlock instances
    if pidof hyprlock > /dev/null 2>&1; then
      exit 0
    fi

    # Lock the screen (blocks until unlock)
    hyprlock

    # Rotate wallpaper after unlock
    bash ~/.local/bin/rotate-wallpaper.sh
  '';

  cliphistLaunch = pkgs.writeShellScript "cliphist-launch" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.wl-clipboard pkgs.cliphist pkgs.coreutils pkgs.procps ]}

    if [ -z "''${XDG_RUNTIME_DIR-}" ]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi

    if [ -z "''${WAYLAND_DISPLAY-}" ]; then
      for s in "''${XDG_RUNTIME_DIR}"/wayland-*; do
        [ -S "''${s}" ] || continue
        export WAYLAND_DISPLAY="$(basename "''${s}")"
        break
      done
    fi

    for i in $(seq 1 200); do
      if [ -n "''${WAYLAND_DISPLAY-}" ] && [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
        break
      fi
      sleep 0.1
    done

    if [ -z "''${WAYLAND_DISPLAY-}" ] || [ ! -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
      echo "No Wayland socket yet; exiting so systemd can retry..."
      exit 1
    fi

    pkill -f "^${pkgs.wl-clipboard}/bin/wl-paste --type image --watch" || true
    pkill -f "^${pkgs.wl-clipboard}/bin/wl-paste --watch" || true

    ${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store &
    ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store &
    wait -n
  '';
  tableplus = let
    pname = "tableplus";
    version = "latest";
    src = pkgs.fetchurl {
      url = "https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage";
      hash = "sha256-ARg6NGGZsVFdjqxKD/Ji0FK6wvRUsmsvIxbktah0ULo=";
    };
    appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
  in pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/*.desktop -t $out/share/applications
      install -m 444 -D ${appimageContents}/*.png -t $out/share/icons/hicolor/256x256/apps
    '';

    meta = {
      description = "Database management made easy";
      homepage = "https://tableplus.com";
      license = lib.licenses.unfree;
      mainProgram = "tableplus";
    };
  };

  # LM Studio headless daemon + CLI.  The binaries (node / bun with embedded
  # JS) break if patchelf modifies the ELF — embedded data offsets shift and
  # the process segfaults.  We leave binaries unpatched and rely on nix-ld
  # (enabled in modules/base.nix) to provide /lib64/ld-linux-x86-64.so.2 and
  # the standard shared libraries at runtime.
  llmster = pkgs.stdenv.mkDerivation rec {
    pname = "llmster";
    version = "0.0.3-2";
    src = pkgs.fetchurl {
      url = "https://llmster.lmstudio.ai/download/${version}-linux-x64.full.tar.gz";
      hash = "sha256-OujH0W0x5d5ADeMvwF1B+ViAbh9CikX0QJy6OPQ4O1Q=";
    };
    sourceRoot = ".";
    # No autoPatchelfHook — binaries must stay unmodified (nix-ld handles them)
    dontPatchELF = true;
    dontStrip = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p $out/lib/llmster $out/bin
      cp -r .bundle $out/lib/llmster/
      cp llmster $out/lib/llmster/

      # Wrapper: run llmster bootstrap, which installs lms to ~/.lmstudio/bin/
      cat > $out/bin/llmster <<'WRAPPER'
#!/bin/sh
exec "$out_lib/llmster" "$@"
WRAPPER
      sed -i "s|\$out_lib|$out/lib/llmster|g" $out/bin/llmster
      chmod +x $out/bin/llmster
    '';
    meta = {
      description = "LM Studio headless daemon and CLI";
      homepage = "https://lmstudio.ai";
      license = lib.licenses.unfree;
      mainProgram = "llmster";
      platforms = [ "x86_64-linux" ];
    };
  };

  heif-convert = pkgs.python3Packages.buildPythonApplication rec {
    pname = "heif-convert";
    version = "1.2.1";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "NeverMendel";
      repo = "heif-convert";
      rev = "v${version}";
      hash = "sha256-0hKhogb9MntZdPJSfJw9/vb4j6gF7z8BoU4bALizReo=";
    };
    build-system = [ pkgs.python3Packages.setuptools ];
    dependencies = with pkgs.python3Packages; [
      pillow
      pillow-heif
    ];
    meta = {
      description = "CLI tool to convert HEIF/HEIC images";
      homepage = "https://github.com/NeverMendel/heif-convert";
      license = lib.licenses.mit;
      mainProgram = "heif-convert";
    };
  };
in
{
  imports = [
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    # basics
    btop
    nvtopPackages.intel # GPU monitor for Intel Arc
    intel-gpu-tools   # intel_gpu_top for Arc B580
    fastfetch
    kitty
    font-awesome
    pavucontrol
    wl-clipboard
    gradia # screenshots
    xdg-desktop-portal-gtk # .portal file needed in per-user profile
    cliphist
    rofi-pulse-select
    bat
    fzf
    libnotify
    lsd
    stripe-cli
    lazygit
    rmpc
    ueberzugpp
    slack
    gnupg
    speedcrunch
    zoom-us
    libreoffice
    zeal
    wordgrinder
    foliate
    bluebubbles
    feishin

    nwg-displays
    vlc
    streamcontroller

    # video / streaming
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        obs-vaapi                 # VA-API hardware encoding (Intel Arc)
        obs-pipewire-audio-capture # PipeWire app audio capture
        wlrobs                    # Wayland screen capture (Hyprland)
        obs-vkcapture             # Vulkan/OpenGL game capture
      ];
    })

    # kde stuff
    kdePackages.okular
    kdePackages.kdenlive

    # file manager
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler                   # thumbnail service

    # emacs / doom
    emacs-pgtk
    nerd-fonts.symbols-only

    # ai
    claude-code
    opencode
    lmstudio
    llmster       # LM Studio headless daemon — run `llmster bootstrap` once to install lms CLI

    # database
    tableplus

    (pkgs.wrapFirefox inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped {
      pname = "zen-browser";
      nativeMessagingHosts = [ pkgs._1password-gui ];
      extraPrefs = ''
        lockPref("browser.ai.control.default", "blocked");
        lockPref("browser.ai.control.linkPreviewKeyPoints", "blocked");
        lockPref("browser.ai.control.pdfjsAltText", "blocked");
        lockPref("browser.ai.control.sidebarChatbot", "blocked");
        lockPref("browser.ai.control.smartTabGroups", "blocked");
        lockPref("browser.ai.control.translations", "blocked");
      '';
    })


    obsidian
    bitwarden-desktop
    protonmail-bridge
    protonmail-desktop
    protonvpn-gui

    # neovim deps (LazyVim-friendly)
    nodejs
    lua-language-server
    stylua
    gcc
    ripgrep
    fd

    # google cloud / kubernetes
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.kubectl
    ])

    # wallpaper / lock
    swww

    # dev / cli tools
    cargo
    yq
    jq
    mpv
    mkcert
    ghostscript
    optipng
    jpegoptim
    advancecomp
    pngcrush
    imagemagick    # general image resize/convert (magick, convert commands)
    heif-convert   # HEIF/HEIC to JPG/PNG/WebP converter
    devenv
    stripe-cli
    pandoc
    yt-dlp
    unzip
    zip
    intelephense
  ];

  home.activation.llmsterBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x "${llmster}/lib/llmster/llmster" ]; then
      ${llmster}/lib/llmster/llmster bootstrap 2>/dev/null || true
    fi
  '';

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
    music = "${config.home.homeDirectory}/Music";
    desktop = "${config.home.homeDirectory}/Desktop";
    extraConfig = {
      SITES = "${config.home.homeDirectory}/Sites";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  home.sessionPath = [
    "$HOME/.lmstudio/bin"   # lms CLI installed by `llmster bootstrap`
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-dash ];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

    programs.vifm = {
    enable = true;
    extraConfig = ''
      set vicmd=nvim
      filetype *.rs,*.py,*.php,*.json,*.js,*.ts,*.jsx,*.tsx,*.lua,*.sh nvim
      filetype *.md,*.txt nvim
      filetype *.pdf okular %f &
      '';
  };

    programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

programs.git = {
  enable = true;

  signing = {
    signByDefault = true;
    key = "~/.ssh/id_ed25519.pub";
  };

  settings = {
    gpg.format = "ssh";
    user = {
      name = "Curtis McHale";
      email = "curtis@curtismchale.ca";
    };
    init.defaultBranch = "main";
  };
};

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = false;
  };

  xdg.configFile."gh-dash/config.yml".text = ''
    defaults:
      issuesLimit: 20
      notificationsLimit: 20
      prApproveComment: LGTM
      preview:
        open: true
        width: 120
      prsLimit: 20
      refetchIntervalMinutes: 30
      view: notifications
    notificationsSections:
    - title: All
      filters: ""
    - title: Created
      filters: "reason:author"
    - title: Participating
      filters: "reason:participating"
    - title: Mentioned
      filters: "reason:mention"
    - title: Review Requested
      filters: "reason:review-requested"
    - title: Assigned
      filters: "reason:assign"
    - title: Subscribed
      filters: "reason:subscribed"
    - title: Team Mentioned
      filters: "reason:team-mention"
  '';

  xdg.configFile."oh-my-posh/theme.omp.json".source =
    "${inputs.self}/home/assets/oh-my-posh/theme.omp.json";

  home.file.".local/bin/sinkswitch.sh" = {
    source = "${inputs.self}/home/assets/sinkswitch/sinkswitch.sh";
    executable = true;
  };

  home.file.".local/bin/rotate-wallpaper.sh" = {
    source = "${inputs.self}/home/assets/wallpaper/rotate-wallpaper.sh";
    executable = true;
  };

  home.file.".local/bin/lock-and-rotate.sh" = {
    source = "${inputs.self}/home/assets/wallpaper/lock-and-rotate.sh";
    executable = true;
  };


  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  programs.rofi = {
    enable = true;
    terminal = "${pkgs.kitty}/bin/kitty";
  };

  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };

  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      width = 320;
      margin = "10";
      padding = "10,14";
      "border-size" = 2;
      "border-radius" = 8;
      "border-color" = "#00bfffee";
      "background-color" = "#001a26ee";
      "text-color" = "#ffffff";
      font = "monospace 11";
      "default-timeout" = 7000;
    };
    extraConfig = ''
      [urgency=low]
      background-color=#001a07ff
      text-color=#cccccc
      border-color=#00ff00cc
      default-timeout=4000

      [urgency=critical]
      background-color=#1a0010ff
      text-color=#ffffff
      border-color=#ff1493
      default-timeout=0
    '';
  };


  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 5;
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.02;
          brightness = 0.7;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          outer_color = "rgba(0, 191, 255, 0.9)";
          inner_color = "rgba(0, 26, 38, 0.9)";
          font_color = "rgb(255, 255, 255)";
          fade_on_empty = true;
          placeholder_text = "Password...";
          halign = "center";
          valign = "center";
          position = "0, -20";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 64;
          color = "rgba(0, 191, 255, 0.9)";
          halign = "center";
          valign = "center";
          position = "0, 80";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${lockAndRotate}";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
          on-resume = "";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    playlistDirectory = "${config.home.homeDirectory}/Music/playlists";
    dataDir = "${config.xdg.stateHome}/mpd";
    extraConfig = ''
      auto_update "yes"
      restore_paused "yes"

      audio_output {
        type "pulse"
        name "PipeWire (PulseAudio)"
      }
    '';
  };

  xdg.configFile."rmpc/config.ron".text = ''
    (
      album_art: (
        method: Kitty,
      ),
    )
  '';

  systemd.user.services."cliphist-watcher" = {
    Unit = {
      Description = "Cliphist clipboard watcher (Wayland)";
    };
    Service = {
      Type = "simple";
      ExecStart = "${cliphistLaunch}";
      Restart = "always";
      RestartSec = 2;
      Environment = "XDG_RUNTIME_DIR=%t";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.startServices = "sd-switch";

  programs.firefox.profiles.default = {
    id = 0;
    isDefault = true;
    settings = {
      "browser.ai.control.default" = "blocked";
      "browser.ai.control.linkPreviewKeyPoints" = "blocked";
      "browser.ai.control.pdfjsAltText" = "blocked";
      "browser.ai.control.sidebarChatbot" = "blocked";
      "browser.ai.control.smartTabGroups" = "blocked";
      "browser.ai.control.translations" = "blocked";
    };
  };


 programs.zsh = {
  enable = true;

  shellAliases = {
    l   = "lsd -l";
    la  = "lsd -a";
    lla = "lsd -la";
    lt  = "lsd --tree";

    enix = "nvim /etc/nixos";
    eP = "echo $PATH";
    deploy-public = "bash /etc/nixos/scripts/deploy-public.sh";
    sshadd = "eval `ssh-agent -s` && ssh-add";
    dush = "du -sh -- *";


    playwaves = "play -n synth brownnoise synth pinknoise mix synth sine amod 0.3 10";
    playpink = "play -t sl -r48000 -c2 -n synth -1 pinknoise .1 60";

    rmpc-kitty = "kitty --detach rmpc";
    doom = "${config.home.homeDirectory}/.config/emacs/bin/doom";
    rpmc-kitty = "kitty --single-instance --detach rmpc";
    ythq = "yt-dlp -f 'bv*+ba/b'";
    resizeheic = "magick mogrify -format jpg -resize 1920x1080";
  };

  initContent = lib.mkAfter ''
    # Oh My Posh (pinned config)
    if [[ -o interactive ]] && command -v oh-my-posh >/dev/null 2>&1; then
      eval "$(oh-my-posh init zsh --config ${config.xdg.configHome}/oh-my-posh/theme.omp.json)"
    fi

    nixhost() { cat /etc/hostname 2>/dev/null || hostname; }

    nfu() { nix flake update --flake /etc/nixos; }
    nrs() { sudo nixos-rebuild switch --flake /etc/nixos#"$(nixhost)"; }
    nrt() { sudo nixos-rebuild test   --flake /etc/nixos#"$(nixhost)"; }
    nrd() { sudo nixos-rebuild dry-run --flake /etc/nixos#"$(nixhost)"; }

    ffedit() {
      if [ "$#" -lt 1 ]; then
        echo "Usage: ffedit input.mp4 [output.mp4]"
        return 1
      fi

      input="$1"
      if [ -n "$2" ]; then
        output="$2"
      else
        output="''${input%.*}_edit.mp4"
      fi

      ffmpeg -fflags +genpts \
        -i "$input" \
        -fps_mode cfr -r 60 \
        -c:v libx264 -preset veryfast -crf 18 \
        -g 60 -keyint_min 60 -sc_threshold 0 \
        -pix_fmt yuv420p \
        -c:a aac -b:a 192k \
        "$output"
    }

    # Fastfetch inside Zellij panes
    if [[ -o interactive ]] && [ -n "$ZELLIJ" ]; then
      fastfetch
    fi

    # Zellij autostart (interactive only)
    if [[ -o interactive ]] && [ -z "$ZELLIJ" ] && [ -z "$SSH_CONNECTION" ]; then
      TERM=xterm-256color command zellij
      [ "$ZELLIJ_AUTO_ATTACH" != "false" ] && exit
    fi
  '';
};


}
