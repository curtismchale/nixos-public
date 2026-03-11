{ config, lib, pkgs, ... }:
let
  # Font Awesome icon helper - converts hex codepoint to Unicode character
  # Nix strings don't support \u escapes, so we round-trip through JSON
  i = code: builtins.fromJSON "\"\\u${code}\"";

  # Module configs shared across all bars
  moduleConfig = {
    idle_inhibitor = {
      format = "{icon}";
      "format-icons" = {
        activated = i "f06e";
        deactivated = i "f070";
      };
    };
    clock = {
      format = "{:%b %d  %H%M}";
      "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      "format-alt" = "{:%Y-%m-%d}";
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
      "format-charging" = "{capacity}% ${i "f5e7"}";
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
    tray = {
      spacing = 10;
    };
  };
in
{
  programs.waybar = {
    enable = true;

    settings =
      let
        rightModules = [
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "power-profiles-daemon"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "clock"
          "tray"
        ];
      in [
        # Dell monitor — includes MPD
        (moduleConfig // {
          name = "dell";
          layer = "top";
          spacing = 4;
          output = ["Dell Inc. DELL U4320Q 30F6XN3"];
          "modules-left" = ["mpd"];
          "modules-center" = [];
          "modules-right" = rightModules;
        })
        # All other monitors — no MPD
        (moduleConfig // {
          name = "other";
          layer = "top";
          spacing = 4;
          output = [
            "BOE Display demoset-1"
            "LG Electronics LG HDR 4K 0x0003E009"
            "LG Electronics LG HDR 4K 0x00046040"
          ];
          "modules-left" = [];
          "modules-center" = [];
          "modules-right" = rightModules;
        })
      ];

    style = ''
        /* started with this base: https://github.com/aranel616/neon-nexus/blob/main/configs/waybar/style.css */
        * {
            /* Modern monospace font for cyberpunk feel */
            font-family: 'Fira Code', 'Source Code Pro', 'JetBrains Mono', 'Roboto Mono', FontAwesome, monospace;
            font-size: 14px;
            font-weight: 500;
            min-height: 0;
            border: none;
            border-radius: 0;
        }

        window#waybar{background-color:rgba(10, 10, 10, 0.7); color:#fff;}

        window#waybar.hidden {
            opacity: 0.3;
        }

        /* Keep window variants transparent too */
        window#waybar.kitty,
        window#waybar.firefox {
            background: transparent;
        }

        /* Button styling */
        button {
            box-shadow: inset 0 -2px transparent;
            border: none;
            border-radius: 0;
            transition: all 0.2s ease;
            background: transparent;
            color: #ffffff;
        }

        button:hover {
            background: rgba(255, 102, 0, 0.2);
            box-shadow:
                inset 0 -2px #ff6600,
                0 0 15px rgba(255, 102, 0, 0.4);
            color: #ff6600;
        }

        /* Common module styling - Individual floating modules */
        #clock,
        #battery,
        #cpu,
        #memory,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #tray,
        #idle_inhibitor,
        #power-profiles-daemon,
        #mpd,
        #custom-media,
        #custom-power {
            padding: 6px 12px;
            margin: 0 3px;
            color: #ffffff;
            background: rgba(26, 26, 26, 0.9);
            border-radius: 8px;
            transition: all 0.3s ease;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        /* Clock - Neon Yellow */
        #clock {
            background: rgba(255, 215, 0, 0.15);
            color: #ffd700;
            font-weight: bold;
            font-size: 15px;
            border: 1px solid rgba(255, 215, 0, 0.5);
            box-shadow: 0 0 10px rgba(255, 215, 0, 0.4);
        }
        #clock:hover {
            box-shadow: 0 0 20px rgba(255, 215, 0, 0.6);
        }

        /* Battery */
        #battery {
            background: rgba(0, 255, 0, 0.15);
            border: 1px solid rgba(0, 255, 0, 0.5);
            color: #00ff00;
        }

        #battery.charging, #battery.plugged {
            background: rgba(0, 255, 0, 0.2);
            color: #00ff00;
            border: 1px solid rgba(0, 255, 0, 0.6);
            box-shadow: 0 0 15px rgba(0, 255, 0, 0.4);
        }

        #battery.warning {
            background: rgba(255, 165, 0, 0.25);
            color: #ffa500;
            border: 1px solid rgba(255, 165, 0, 0.6);
        }

        #battery.critical:not(.charging) {
            background: rgba(255, 20, 147, 0.3);
            color: #ffffff;
            border: 1px solid #ff1493;
            box-shadow: 0 0 25px rgba(255, 20, 147, 0.8);
        }

        /* CPU - Neon Orange */
        #cpu {
            background: rgba(255, 102, 0, 0.15);
            color: #ff6600;
            border: 1px solid rgba(255, 102, 0, 0.5);
        }

        #cpu:hover {
            box-shadow: 0 0 15px rgba(255, 102, 0, 0.5);
        }

        /* Memory - Electric Pink */
        #memory {
            background: rgba(255, 20, 147, 0.15);
            color: #ff1493;
            border: 1px solid rgba(255, 20, 147, 0.5);
        }

        /* Temperature */
        #temperature {
            background: rgba(255, 165, 0, 0.15);
            color: #ffa500;
            border: 1px solid rgba(255, 165, 0, 0.5);
        }

        #temperature.critical {
            background: rgba(255, 20, 147, 0.3);
            color: #ffffff;
            border: 1px solid #ff1493;
            box-shadow: 0 0 20px rgba(255, 20, 147, 0.8);
        }

        /* Network */
        #network {
            background: rgba(0, 191, 255, 0.15);
            color: #00bfff;
            border: 1px solid rgba(0, 191, 255, 0.5);
        }

        #network.disconnected {
            background: rgba(255, 20, 147, 0.3);
            color: #ffffff;
            border: 1px solid #ff1493;
            box-shadow: 0 0 15px rgba(255, 20, 147, 0.7);
        }

        /* Audio */
        #pulseaudio {
            background: rgba(255, 215, 0, 0.15);
            color: #ffd700;
            border: 1px solid rgba(255, 215, 0, 0.5);
        }

        #pulseaudio.muted {
            background: rgba(128, 128, 128, 0.25);
            color: #808080;
            border: 1px solid rgba(128, 128, 128, 0.5);
        }

        #pulseaudio:hover {
            box-shadow: 0 0 15px rgba(255, 215, 0, 0.5);
        }

        /* Power profiles */
        #power-profiles-daemon.performance {
            background: rgba(255, 20, 147, 0.3);
            color: #ffffff;
            border: 1px solid #ff1493;
        }

        #power-profiles-daemon.balanced {
            background: rgba(255, 165, 0, 0.25);
            color: #ffa500;
            border: 1px solid rgba(255, 165, 0, 0.6);
        }

        #power-profiles-daemon.power-saver {
            background: rgba(0, 255, 0, 0.15);
            color: #00ff00;
            border: 1px solid rgba(0, 255, 0, 0.5);
        }

        /* System tray */
        #tray {
            background: rgba(0, 0, 0, 0.4);
            border: 1px solid rgba(255, 0, 64, 0.3);
            border-radius: 6px;
            padding: 0 8px;
        }

        #tray > .passive {
            -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
            -gtk-icon-effect: highlight;
            background: rgba(255, 0, 64, 0.3);
            border-radius: 4px;
        }

        /* Media player */
        #custom-media {
            background: rgba(102, 204, 153, 0.15);
            color: #66cc99;
            border: 1px solid rgba(102, 204, 153, 0.5);
        }

        #custom-media.custom-spotify {
            color: #1db954;
            background: rgba(29, 185, 84, 0.15);
            border: 1px solid rgba(29, 185, 84, 0.5);
        }

        /* MPD */
        #mpd {
            background: rgba(102, 204, 153, 0.15);
            color: #66cc99;
            border: 1px solid rgba(102, 204, 153, 0.5);
        }

        #mpd.disconnected {
            background: rgba(255, 20, 147, 0.2);
            color: #ff1493;
            border: 1px solid rgba(255, 20, 147, 0.5);
        }

        #mpd.stopped {
            background: rgba(128, 128, 128, 0.2);
            color: #808080;
        }

        #mpd.paused {
            background: rgba(255, 165, 0, 0.15);
            color: #ffa500;
            border: 1px solid rgba(255, 165, 0, 0.5);
        }

        /* Idle inhibitor */
        #idle_inhibitor {
            background: rgba(45, 52, 54, 0.3);
            color: #636e72;
        }

        #idle_inhibitor.activated {
            background: rgba(255, 215, 0, 0.25);
            color: #ffd700;
            border: 1px solid rgba(255, 215, 0, 0.6);
        }

        /* Keyboard state */
        #keyboard-state {
            background: rgba(151, 225, 173, 0.1);
            color: #97e1ad;
            padding: 0;
            margin: 0 5px;
            border-radius: 6px;
        }

        #keyboard-state > label {
            padding: 0 8px;
            transition: all 0.2s ease;
        }

        #keyboard-state > label.locked {
            background: rgba(255, 20, 147, 0.25);
            color: #ff1493;
            border-radius: 4px;
            font-weight: bold;
            border: 1px solid rgba(255, 20, 147, 0.5);
        }

        /* Backlight */
        #backlight {
            background: rgba(144, 177, 177, 0.15);
            color: #90b1b1;
            border: 1px solid rgba(144, 177, 177, 0.5);
        }

        /* Custom power button */
        #custom-power {
            background: rgba(0, 34, 68, 0.9);
            color: #00ffff;
            font-size: 16px;
            font-weight: bold;
            border: 1px solid #00ffff;
            border-radius: 8px;
            margin: 0 8px;
            padding: 0 15px;
            transition: all 0.3s ease;
            box-shadow: 0 0 10px rgba(0, 255, 255, 0.3);
        }

        #custom-power:hover {
            background: rgba(0, 255, 255, 0.2);
            color: #ffffff;
            box-shadow: 0 0 20px rgba(0, 255, 255, 0.8);
        }

        /* Margins and spacing adjustments */
        .modules-left > widget:first-child > #workspaces {
            margin-left: 8px;
        }

        .modules-right > widget:last-child > #custom-power {
            margin-right: 8px;
        }

        /* Hover effects for all modules */
        #clock:hover,
        #battery:hover,
        #cpu:hover,
        #memory:hover,
        #temperature:hover,
        #network:hover,
        #pulseaudio:hover,
        #custom-media:hover,
        #mpd:hover {
            opacity: 0.9;
        }
    '';

    systemd = {
      enable = true;
    };
  };
}
