{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    davinci-resolve
  ];

  # Zellij config — Moonlander-specific keybinds (Alt+HTCN Dvorak + arrows)
  xdg.configFile."zellij/config.kdl".source =
    "${inputs.self}/home/assets/zellij/config.kdl";

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ################
      ### MONITORS ###
      ################

      # Dell U4320Q (center-top, scale 1.07 → logical 3589x2019)
      monitor=desc:Dell Inc. DELL U4320Q 30F6XN3,3840x2160@60.00,1440x22,1

      # BOE Display (below Dell, centered, scale 1.2 → logical 1800x1200)
      monitor=desc:BOE Display demoset-1,2160x1440@60.00,2482x2182,1.2

      # LG right (portrait)
      monitor=desc:LG Electronics LG HDR 4K 0x0003E009,3840x2160@30.00,5280x22,1.5,transform,3

      # LG left (not connected yet — portrait)
      monitor=desc:LG Electronics LG HDR 4K 0x00046040,3840x2160@30.00,0x22,1.5,transform,1

      # fallback for any unmatched monitor
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

      # exec-once = $terminal
      # exec-once = nm-applet &
      # exec-once = waybar & hyprpaper & firefox
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

      input {
          kb_layout = us
          kb_options = caps:escape
      }

      gesture = 3, horizontal, workspace

      # Moonlander outputs Dvorak at firmware level, so no kb_variant here.
      # kb_variant must be explicitly empty or it inherits from the global input block.
      # It registers as several sub-devices; override all of them.
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

      # MelGeek Mojo68 — standard keyboard, Dvorak applied via Hyprland (not firmware).
      device {
          name = melgeek-mojo68
          kb_layout = us
          kb_variant = dvorak
          kb_options = caps:escape
      }

      device {
          name = melgeek-mojo68-system-control
          kb_layout = us
          kb_variant = dvorak
          kb_options = caps:escape
      }

      device {
          name = melgeek-mojo68-consumer-control
          kb_layout = us
          kb_variant = dvorak
          kb_options = caps:escape
      }

      device {
          name = epic-mouse-v1
          sensitivity = -0.5
      }


      ###################
      ### KEYBINDINGS ###
      ###################

      $mainMod = SUPER

      bind = $mainMod, Return, exec, $terminal
      bind = $mainMod, Q, killactive
      bind = $mainMod SHIFT, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit
      bind = $mainMod SHIFT, F, exec, kitty --title snippet-search --override close_on_child_death=yes -e ~/tooling/snippet-search.sh
      bind = $mainMod, E, exec, rofi -show drun
      bind = $mainMod, B, exec, zen
      bind = $mainMod, W, exec, obsidian
      bind = $mainMod, U, exec, emacs
      bind = $mainMod, A, exec, kitty -e bluetuith
      bind = $mainMod, P, exec, gradia
      bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
      bind = $mainMod, R, exec, $menu
      bind = $mainMod, J, togglesplit
      bind = $mainMod, F, fullscreen

      # Move focus between windows
      bind = $mainMod, H, movefocus, l
      bind = $mainMod, N, movefocus, r
      bind = $mainMod, C, movefocus, u
      bind = $mainMod, T, movefocus, d

      # resize
      bind = $mainMod CTRL, H, resizeactive, -20 0 # shrink width
      bind = $mainMod CTRL, N, resizeactive, 20 0 # grow width
      bind = $mainMod CTRL, C, resizeactive, 0 -20 # shrink height
      bind = $mainMod CTRL, T, resizeactive, 0 20 # grow height

      # Workspace assignment DELL
      workspace = name:desk1, monitor:desc:Dell Inc. DELL U4320Q 30F6XN3, persistent:true, default:true
      workspace = name:desk2, monitor:desc:Dell Inc. DELL U4320Q 30F6XN3, persistent:true
      workspace = name:desk3, monitor:desc:Dell Inc. DELL U4320Q 30F6XN3, persistent:true
      workspace = name:desk4, monitor:desc:Dell Inc. DELL U4320Q 30F6XN3, persistent:true
      workspace = name:desk5, monitor:desc:Dell Inc. DELL U4320Q 30F6XN3, persistent:true

      # Workspace assignment BOE
      workspace = name:boe1, monitor:desc:BOE Display demoset-1, persistent:true, default:true
      workspace = name:boe2, monitor:desc:BOE Display demoset-1, persistent:true
      workspace = name:boe3, monitor:desc:BOE Display demoset-1, persistent:true
      workspace = name:boe4, monitor:desc:BOE Display demoset-1, persistent:true
      workspace = name:boe5, monitor:desc:BOE Display demoset-1, persistent:true

      # Create workspaces DELL
      exec-once = hyprctl dispatch workspace name:desk1
      exec-once = hyprctl dispatch workspace name:desk2
      exec-once = hyprctl dispatch workspace name:desk3
      exec-once = hyprctl dispatch workspace name:desk4
      exec-once = hyprctl dispatch workspace name:desk5

      # Create workspaces BOE
      exec-once = hyprctl dispatch workspace name:boe1
      exec-once = hyprctl dispatch workspace name:boe2
      exec-once = hyprctl dispatch workspace name:boe3
      exec-once = hyprctl dispatch workspace name:boe4
      exec-once = hyprctl dispatch workspace name:boe5

      # Workspace movement DELL
      bind = $mainMod, 1, workspace, name:desk1
      bind = $mainMod, 2, workspace, name:desk2
      bind = $mainMod, 3, workspace, name:desk3
      bind = $mainMod, 4, workspace, name:desk4
      bind = $mainMod, 5, workspace, name:desk5

      # Workspace movement BOE
      bind = $mainMod, 6, workspace, name:boe1
      bind = $mainMod, 7, workspace, name:boe2
      bind = $mainMod, 8, workspace, name:boe3
      bind = $mainMod, 9, workspace, name:boe4
      bind = $mainMod, 0, workspace, name:boe5

      # Move window to workspace DELL
      bind = $mainMod SHIFT, 1, movetoworkspace, name:desk1
      bind = $mainMod SHIFT, 2, movetoworkspace, name:desk2
      bind = $mainMod SHIFT, 3, movetoworkspace, name:desk3
      bind = $mainMod SHIFT, 4, movetoworkspace, name:desk4
      bind = $mainMod SHIFT, 5, movetoworkspace, name:desk5

      # Move window to workspace BOE
      bind = $mainMod SHIFT, 6, movetoworkspace, name:boe1
      bind = $mainMod SHIFT, 7, movetoworkspace, name:boe2
      bind = $mainMod SHIFT, 8, movetoworkspace, name:boe3
      bind = $mainMod SHIFT, 9, movetoworkspace, name:boe4
      bind = $mainMod SHIFT, 0, movetoworkspace, name:boe5

      # ensure that on startup I start on lap1 and desk1 workspaces
      exec-once = hyprctl dispatch workspace name:boe1
      exec-once = hyprctl dispatch workspace name:desk1   # keep this LAST so you land here

      bind = $mainMod, L, exec, loginctl lock-session
      bind = $mainMod, S, exec, kitty --title sinkswitch -e bash ~/.local/bin/sinkswitch.sh
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Dual-monitor helpers
      # Cycle focus across monitors; move windows between monitors
      bind = $mainMod, bracketright, focusmonitor, +1
      bind = $mainMod, bracketleft,  focusmonitor, -1
      bind = $mainMod SHIFT, N, movewindow, mon:r
      bind = $mainMod SHIFT, H,  movewindow, mon:l
      bind = $mainMod SHIFT, C,  movewindow, mon:u
      bind = $mainMod SHIFT, T,  movewindow, mon:d
      
      # swap windows
      bind = $mainMod ALT, N, swapwindow, r
      bind = $mainMod ALT, H, swapwindow, l
      bind = $mainMod ALT, C, swapwindow, u
      bind = $mainMod ALT, T, swapwindow, d

      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
      bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = ,XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+
      bindel = ,XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-

      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous


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
      windowrule {
          name = float-snippet-search
          match:initial_title = snippet-search
          float = on
          size = 1200 500
          center = true
      }
    '';
  };
}
