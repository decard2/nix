{ config, inputs, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    extraConfig = ''
            #vars
            $term = kitty

            #bindings
            $mod = SUPER
            bind = $mod, M, exit,
            bind = $mod, Return, exec, $term      
            bind = CTRL, grave, togglespecialworkspace, terminal
            bind = $mod, T, togglespecialworkspace, tg
            bind = $mod, D, exec, tofi-drun --drun-launch=true | xargs hyprctl dispatch exec --
            bind = $mod, Q, killactive,
            bind=,XF86MonBrightnessDown, exec, brightnessctl -q s 2%-
            bind=,XF86MonBrightnessUp, exec, brightnessctl -q s +2%
            bind = $mod, W, exec, /home/decard/nix/home/scripts/runvm.sh
            bind = SUPER_SHIFT, W, exec, virsh --connect qemu:///system suspend win11
            bind = $mod, c, exec, thorium
            bind = SUPER, V, exec, cliphist list | tofi  | cliphist decode | wl-copy

            # Apps to start on login
            exec-once = ${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland      
            exec-once = ${pkgs.polkit-kde-agent}/bin/polkit-kde-authentication-agent-1            
            exec-once = [workspace special:terminal silent] $term
            exec-once = [workspace special:tg silent] telegram-desktop
            exec-once = wl-paste --type text --watch cliphist store #Stores only text data
            exec-once = wl-paste --type image --watch cliphist store #Stores only image data
      
            # rules
            windowrulev2 = noborder, title:(Noodl)

            general {
              cursor_inactive_timeout = 3
              gaps_in = 2
              gaps_out = 5
              border_size = 1        
              layout = dwindle
              resize_on_border = true
              col.active_border = rgba(bb9af7ff) rgba(b4f9f8ff) 45deg
              col.inactive_border = rgba(565f89cc) rgba(9aa5cecc) 45deg
            }

            bezier=slow,0,0.85,0.3,1
            bezier=overshot,0.7,0.6,0.1,1.1
            bezier=bounce,1,1.6,0.1,0.85
            bezier=slingshot,1,-2,0.9,1.25
            bezier=nice,0,6.9,0.5,-4.20

            animations {
              enabled=1
              animation=windows,1,5,bounce,slide
              animation=border,1,20,default
              animation=fade,1,5,default
              animation=workspaces,1,5,overshot,slide
            }

            decoration {
                rounding = 6
                drop_shadow = false
                blur {
                    enabled = true
                    size = 6
                    passes = 3
                    new_optimizations = on
                    ignore_opacity = on
                    xray = true              
                }
            }

            input {
              numlock_by_default = true
      	      kb_layout = us,ru
      	      kb_options = grp:win_space_toggle,grp_led:scroll
            }

            # workspaces
            workspace=1, monitor:eDP-1
            workspace=2, monitor:DP-1
            workspace=3, monitor:DP-1
            workspace=4, monitor:DP-1
            workspace=5, monitor:eDP-1
            workspace=6, monitor:DP-1
            workspace=7, monitor:eDP-1
            workspace=8, monitor:DP-1
      
            ${builtins.concatStringsSep "\n" (builtins.genList (
              x: let
                ws = let
                  c = (x + 1) / 10;
                in
                  builtins.toString (x + 1 - (c * 10));
                in ''
                  bind = $mod, ${ws}, workspace, ${toString (x + 1)}
                  bind = $mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
                ''
              )
            10)}
            # Fixes
            # blurry X11 apps, hidpi
            exec-once = xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 24c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2
            xwayland {
              force_zero_scaling = true
            };
            # ENV
            env=NIXOS_OZONE_WL, 1      
            env=XCURSOR_SIZE,32
            env=GDK_SCALE,2    
            env=QT_AUTO_SCREEN_SCALE_FACTOR,0
            env=QT_SCALE_FACTOR,1.5
            env=XDG_SESSION_TYPE,wayland      
            #env=WLR_NO_HARDWARE_CURSORS,1      
            env=GDK_BACKEND,wayland,x11
            env=QT_QPA_PLATFORM,wayland;xcb
            env=SDL_VIDEODRIVER,wayland
            env=CLUTTER_BACKEND,wayland
            env=XDG_CURRENT_DESKTOP,Hyprland      
            env=XDG_SESSION_DESKTOP,Hyprland
            env=QT_AUTO_SCREEN_SCALE_FACTOR,1  
            env=QT_WAYLAND_DISABLE_WINDOWDECORATION,1
            env=QT_QPA_PLATFORMTHEME,qt5ct
    '';
  };
}
