{ inputs, pkgs, ... }:
let
  i = code: builtins.fromJSON "\"\\u${code}\"";
in
{
  # Zellij config — same Moonlander-compatible keybinds as desktop
  xdg.configFile."zellij/config.kdl".source =
    "${inputs.self}/home/assets/zellij/config.kdl";

  # Laptop waybar bar — no output restriction so it shows on the built-in
  # display (and any connected external). The dell/other bars defined in
  # waybar.nix won't match laptop outputs so only this bar appears.
  programs.waybar.settings = [
    {
      name = "laptop";
      layer = "top";
      spacing = 4;
      "modules-left" = ["mpd"];
      "modules-center" = [];
      "modules-right" = [
        "idle_inhibitor"
        "pulseaudio"
        "network"
        "power-profiles-daemon"
        "cpu"
        "memory"
        "temperature"
        "battery"
        "clock"
        "tray"
      ];
      idle_inhibitor = {
        format = "{icon}";
        "format-icons" = {
          activated = i "f06e";
          deactivated = i "f070";
        };
      };
      cpu = {
        format = "{usage}% ${i "f2db"}";
        tooltip = false;
      };
      memory = {
        format = "{}% ${i "f0c9"}";
      };
      temperature = {
        "critical-threshold" = 80;
        format = "{temperatureC}${i "00b0"}C {icon}";
        "format-icons" = [(i "f76b") (i "f2c9") (i "f769")];
      };
      backlight = {
        format = "{percent}% {icon}";
        "format-icons" = [(i "e38d") (i "e3d3") (i "e3d1") (i "e3cf") (i "e3ce") (i "e3cd") (i "e3ca") (i "e3c8") (i "e39b")];
      };
      battery = {
        bat = "BAT1";
        adapter = "ACAD";
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        "format-full" = "{capacity}% {icon}";
        "format-charging" = "{capacity}% ${i "f1e6"}";
        "format-plugged" = "{capacity}% ${i "f1e6"}";
        "format-alt" = "{time} {icon}";
        "format-icons" = [(i "f244") (i "f243") (i "f242") (i "f241") (i "f240")];
      };
      network = {
        "format-wifi" = "{essid} ({signalStrength}%) ${i "f1eb"}";
        "format-ethernet" = "{ipaddr}/{cidr} ${i "f796"}";
        "tooltip-format" = "{ifname} via {gwaddr} ${i "f796"}";
        "format-linked" = "{ifname} (No IP) ${i "f796"}";
        "format-disconnected" = "Disconnected ${i "26a0"}";
        "format-alt" = "{ifname}: {ipaddr}/{cidr}";
      };
      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        "format-bluetooth" = "{volume}% {icon}${i "f294"} {format_source}";
        "format-bluetooth-muted" = "${i "f6a9"} {icon}${i "f294"} {format_source}";
        "format-muted" = "${i "f6a9"} {format_source}";
        "format-source" = "{volume}% ${i "f130"}";
        "format-source-muted" = i "f131";
        "format-icons" = {
          headphone = i "f025";
          "hands-free" = i "f590";
          headset = i "f590";
          phone = i "f095";
          portable = i "f095";
          car = i "f1b9";
          default = [(i "f026") (i "f027") (i "f028")];
        };
        "on-click" = "pavucontrol";
      };
      "power-profiles-daemon" = {
        format = "{icon}";
        "tooltip-format" = "Power profile: {profile}\nDriver: {driver}";
        tooltip = true;
        "format-icons" = {
          default = i "f0e7";
          performance = i "f0e7";
          balanced = i "f24e";
          "power-saver" = i "f06c";
        };
      };
      mpd = {
        format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ";
        "format-disconnected" = "Disconnected ${i "f001"}";
        "format-stopped" = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ${i "f001"}";
        "consume-icons" = { on = "${i "f2f5"} "; };
        "random-icons" = { off = "<span color=\"#f53c3c\">${i "f074"} </span>"; on = "${i "f074"} "; };
        "repeat-icons" = { on = "${i "f363"} "; };
        "single-icons" = { on = "1 "; };
        "state-icons" = { paused = i "f04c"; playing = i "f04b"; };
        tooltip = false;
      };
      clock = {
        format = "{:%b %d  %H%M}";
        "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        "format-alt" = "{:%Y-%m-%d}";
      };
      tray = {
        spacing = 10;
      };
    }
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ################
      ### MONITORS ###
      ################

      monitor=desc:LG Electronics LG HDR 4K 0x00068CED,3840x2160@30,0x0,1.07
      monitor=eDP-1,2256x1504@60,347x2030,1.07
      monitor=,preferred,auto,1


      ###################
      ### MY PROGRAMS ###
      ###################

      $terminal = kitty
      $fileManager = thunar
      $menu = hyprlauncher


      #################
      ### AUTOSTART ###
      #################

      exec-once = hyprctl setcursor Adwaita 24
      exec-once = swww-daemon &
      exec-once = sleep 1 && bash ~/.local/bin/rotate-wallpaper.sh
      exec-once = sleep 2 && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user reset-failed xdg-desktop-portal-hyprland.service xdg-desktop-portal.service waybar.service 2>/dev/null; systemctl --user restart xdg-desktop-portal-hyprland.service && sleep 1 && systemctl --user restart xdg-desktop-portal.service && systemctl --user restart waybar.service


      #############################
      ### ENVIRONMENT VARIABLES ###
      #############################

      env = XCURSOR_THEME,Adwaita
      env = XCURSOR_SIZE,24


      #####################
      ### LOOK AND FEEL ###
      #####################

      general {
          gaps_in = 5
          gaps_out = 20
          border_size = 4
          col.active_border = rgba(ff1493ee) rgba(ff69b4ee) 45deg
          col.inactive_border = rgba(595959aa)
          resize_on_border = false
          allow_tearing = false
          layout = dwindle
      }

      cursor {
          inactive_timeout = 5
      }

      decoration {
          rounding = 10
          rounding_power = 2
          active_opacity = 1.0
          inactive_opacity = 1.0

          shadow {
              enabled = true
              range = 4
              render_power = 3
              color = rgba(1a1a1aee)
          }

          blur {
              enabled = true
              size = 3
              passes = 1
              vibrancy = 0.1696
          }
      }

      animations {
          enabled = yes, please :)

          bezier = easeOutQuint,   0.23, 1,    0.32, 1
          bezier = easeInOutCubic, 0.65, 0.05, 0.36, 1
          bezier = linear,         0,    0,    1,    1
          bezier = almostLinear,   0.5,  0.5,  0.75, 1
          bezier = quick,          0.15, 0,    0.1,  1

          animation = global,        1,     10,    default
          animation = border,        1,     5.39,  easeOutQuint
          animation = windows,       1,     4.79,  easeOutQuint
          animation = windowsIn,     1,     4.1,   easeOutQuint, popin 87%
          animation = windowsOut,    1,     1.49,  linear,       popin 87%
          animation = fadeIn,        1,     1.73,  almostLinear
          animation = fadeOut,       1,     1.46,  almostLinear
          animation = fade,          1,     3.03,  quick
          animation = layers,        1,     3.81,  easeOutQuint
          animation = layersIn,      1,     4,     easeOutQuint, fade
          animation = layersOut,     1,     1.5,   linear,       fade
          animation = fadeLayersIn,  1,     1.79,  almostLinear
          animation = fadeLayersOut, 1,     1.39,  almostLinear
          animation = workspaces,    1,     1.94,  almostLinear, fade
          animation = workspacesIn,  1,     1.21,  almostLinear, fade
          animation = workspacesOut, 1,     1.94,  almostLinear, fade
          animation = zoomFactor,    1,     7,     quick
      }

      dwindle {
          pseudotile = true
          preserve_split = true
      }

      master {
          new_status = master
      }

      misc {
          force_default_wallpaper = 0
          disable_hyprland_logo = true
      }


      #############
      ### INPUT ###
      #############

      # Global input — plain US, no kb_variant. Required for letter-keyed
      # binds (e.g. bind = SUPER, Q) to resolve correctly regardless of device.
      input {
          kb_layout = us
          kb_variant = dvorak
          kb_options = caps:escape

          touchpad {
              natural_scroll = true
              clickfinger_behavior = true
              tap-to-click = false
          }
      }

      gesture = 3, horizontal, workspace

      # Framework built-in keyboard — Hyprland applies Dvorak layout
      device {
          name = at-translated-set-2-keyboard
          kb_layout = us
          kb_variant = dvorak
          kb_options = caps:escape
      }

      # Moonlander (if connected) — firmware handles Dvorak, explicitly clear
      # kb_variant to prevent inheriting the global input block's options.
      device {
          name = zsa-technology-labs-moonlander-mark-i
          kb_layout = us
          kb_variant =
          kb_options = caps:escape
      }

      device {
          name = zsa-technology-labs-moonlander-mark-i-keyboard
          kb_layout = us
          kb_variant =
          kb_options = caps:escape
      }

      device {
          name = zsa-technology-labs-moonlander-mark-i-system-control
          kb_layout = us
          kb_variant =
          kb_options = caps:escape
      }

      device {
          name = zsa-technology-labs-moonlander-mark-i-consumer-control
          kb_layout = us
          kb_variant =
          kb_options = caps:escape
      }


      ###################
      ### KEYBINDINGS ###
      ###################

      $mainMod = SUPER

      bind = $mainMod, Return, exec, $terminal
      bind = $mainMod, Q, killactive
      bind = $mainMod SHIFT, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit
      bind = $mainMod, E, exec, rofi -show drun
      bind = $mainMod, B, exec, zen
      bind = $mainMod, W, exec, obsidian
      bind = $mainMod, U, exec, emacs
      bind = $mainMod, A, exec, kitty -e bluetuith
      bind = $mainMod, P, exec, gradia
      bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
      bind = $mainMod, R, exec, $menu
      bind = $mainMod, J, togglesplit

      # Move focus between windows
      bind = $mainMod, H, movefocus, l
      bind = $mainMod, N, movefocus, r
      bind = $mainMod, C, movefocus, u
      bind = $mainMod, T, movefocus, d

      # Resize
      bind = $mainMod CTRL, H, resizeactive, -20 0
      bind = $mainMod CTRL, N, resizeactive, 20 0
      bind = $mainMod CTRL, C, resizeactive, 0 -20
      bind = $mainMod CTRL, T, resizeactive, 0 20

      # Workspaces — named, no monitor pin (single/flexible display)
      workspace = name:lap1, persistent:true, default:true
      workspace = name:lap2, persistent:true
      workspace = name:lap3, persistent:true
      workspace = name:lap4, persistent:true
      workspace = name:lap5, persistent:true

      bind = $mainMod, 1, workspace, name:lap1
      bind = $mainMod, 2, workspace, name:lap2
      bind = $mainMod, 3, workspace, name:lap3
      bind = $mainMod, 4, workspace, name:lap4
      bind = $mainMod, 5, workspace, name:lap5

      bind = $mainMod SHIFT, 1, movetoworkspace, name:lap1
      bind = $mainMod SHIFT, 2, movetoworkspace, name:lap2
      bind = $mainMod SHIFT, 3, movetoworkspace, name:lap3
      bind = $mainMod SHIFT, 4, movetoworkspace, name:lap4
      bind = $mainMod SHIFT, 5, movetoworkspace, name:lap5

      # Extra workspaces (6-10) — unnamed, for overflow / external monitor use
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      exec-once = hyprctl dispatch workspace name:lap1

      bind = $mainMod, L, exec, loginctl lock-session
      bind = $mainMod, S, exec, kitty --title sinkswitch -e bash ~/.local/bin/sinkswitch.sh
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Monitor focus / window move (useful when external monitor connected)
      bind = $mainMod, bracketright, focusmonitor, +1
      bind = $mainMod, bracketleft,  focusmonitor, -1
      bind = $mainMod SHIFT, N, movewindow, mon:r
      bind = $mainMod SHIFT, H, movewindow, mon:l
      bind = $mainMod SHIFT, C, movewindow, mon:u
      bind = $mainMod SHIFT, T, movewindow, mon:d

      # Swap windows
      bind = $mainMod ALT, N, swapwindow, r
      bind = $mainMod ALT, H, swapwindow, l
      bind = $mainMod ALT, C, swapwindow, u
      bind = $mainMod ALT, T, swapwindow, d

      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      bindel = ,XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = ,XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindel = ,XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindel = ,XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = ,XF86MonBrightnessUp,   exec, brightnessctl -e4 -n2 set 5%+
      bindel = ,XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-

      bindl = , XF86AudioNext,  exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay,  exec, playerctl play-pause
      bindl = , XF86AudioPrev,  exec, playerctl previous


      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      windowrule {
          name = suppress-maximize-events
          match:class = .*
          suppress_event = maximize
      }

      windowrule {
          name = fix-xwayland-drags
          match:class = ^$
          match:title = ^$
          match:xwayland = true
          match:float = true
          match:fullscreen = false
          match:pin = false
          no_focus = true
      }

      windowrule {
          name = move-hyprland-run
          match:class = hyprland-run
          move = 20 monitor_h-120
          float = yes
      }

      windowrule {
          name = float-thunar-progress
          match:initial_class = thunar
          match:initial_title = (Moving|Copying|Deleting|Renaming).*
          float = on
      }

      windowrule {
          name = float-sinkswitch
          match:initial_title = sinkswitch
          float = on
          size = 600 400
          center = true
      }
    '';
  };
}
