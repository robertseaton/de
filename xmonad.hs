import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.CycleRecentWS
import XMonad.Actions.WindowBringer
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.Paste
import XMonad.Util.Run
import XMonad.Util.Scratchpad
import XMonad.Util.WorkspaceCompare

import System.IO

import qualified XMonad.StackSet as W

myManageHook = composeAll
   [ resource  =? "emacs"         --> doShift "1:emacs"
--   , className =? "Firefox"       --> doShift "2:www"
   , title     =? "rtorrent"      --> doShift "rtorrent"
   , manageDocks
   ] <+> manageScratchpad

manageScratchpad :: ManageHook
manageScratchpad = scratchpadManageHook(W.RationalRect l t w h)
                where
                        h = 1 / 3
                        w = 1 / 3
                        t = 0.33
                        l = 0.33


backgroundColor, textColor, color3, color4, color5 :: [Char]
backgroundColor = "#181818"
textColor = "#d8d8d8"
color5 = "#DC9656"
color4 = "#A1B56C"
color3 = "#AB4642"

lemonColor :: String -> String -> String -> String
lemonColor fgcolor bgcolor str = "%{F" ++ fgcolor ++ "}" ++ str -- ++ "%{B" ++ bgcolor ++ "}"


myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ defaultPP
    {
        ppCurrent           =   lemonColor color3 backgroundColor . pad
      , ppVisible           =   lemonColor color5 backgroundColor . pad
      , ppHidden            =   lemonColor textColor backgroundColor . pad . noScratchpad
      , ppHiddenNoWindows   =   lemonColor textColor backgroundColor . pad . noScratchpad
      , ppUrgent            =   lemonColor color4 backgroundColor . pad
      , ppWsSep             =   " "
      , ppSep               =   "  |  "
      , ppLayout            =   lemonColor color3 backgroundColor
      , ppTitle             =   (" " ++) . lemonColor textColor backgroundColor . dzenEscape
      , ppOutput            =   hPutStrLn h
    }
    where
        noScratchpad ws = if ws == "NSP" then "" else ws

myTerminal = "xfce4-terminal"
myXMonadBar = "dzen2 -dock -xs 1 -fn Inconsolata-10 -ta l -bg '" ++ backgroundColor ++ "' -w '550' -h '24'"
topBar = "ruby ~/sh/make-status.rb | lemonbar -f Inconsolata-10 -f \"Material Icons:size=10\" -g 1920x30 -B '" ++ backgroundColor ++ "' -F '" ++ textColor ++ "' -U '" ++ color5 ++ "' -u 5"
bottomBar = "lemonbar -f Inconsolata-10 -b -g 1920x24"

layout' = tall' ||| Full
  where
    tall' = Tall nmaster delta ratio
    nmaster = 1
    ratio = 0.618034 -- Golden ratio with a + b = 1.
    delta = 3/100

dmenu_cmd = "dmenu_run -h 24 -fn Inconsolata-10 -nb '" ++ backgroundColor ++ "' -nf '" ++ textColor ++ "' -sb '" ++ color3 ++ "' -sf '" ++ textColor ++ "'"
workspaces' = ["1:emacs", "2:www", "3:misc", "4:pdf", "5:office", "6:spotify", "7:anki", "8:rails"]

main = do
--  dzenRightBar <- spawnPipe topBar
  dzenLeftBar <- spawnPipe topBar
  xmonad $ ewmh defaultConfig
            { terminal = myTerminal
            , focusFollowsMouse = True
            , modMask = mod4Mask
            , layoutHook = smartBorders $ avoidStruts $ spacing 5 $ layout'
            , manageHook = myManageHook <+> manageHook defaultConfig 
            , workspaces = workspaces'
            , borderWidth = 1
            , normalBorderColor = backgroundColor
            , focusedBorderColor = color3
            , logHook = myLogHook dzenLeftBar
            , handleEventHook = handleEventHook defaultConfig <+> fullscreenEventHook
            }
            `additionalMouseBindings`
            [ ((0, 8), \w -> prevWS ) -- Use mouse button to move to the previous workspace.
            , ((0, 9), \w -> nextWS ) -- Use mouse button to move to the next workspace.
            ]
            `additionalKeysP`
            ([ ("C-d q", spawn "killall conky lemonbar && xmonad --recompile && xmonad --restart")
	    , ("C-d s", spawn dmenu_cmd)
            , ("C-d f", windows W.focusDown)                            -- Select next window.
            , ("C-d <Right>", windows W.focusDown)                      -- ^ 
            , ("C-d d", windows W.focusUp)                              -- Select the previous window.
            , ("C-d <Left>", windows W.focusUp)                         -- ^
            , ("C-d <Return>", windows W.swapMaster)                    -- Swap master window and focused window.
            , ("C-h", sendMessage Shrink)                               -- Shrink the master area.
            , ("C-l", sendMessage Expand)                               -- Grow the master area.
            , ("C-d x", kill)                                           -- Kill the selected window.
            , ("C-d c", spawn myTerminal)                               -- Start terminal.
            , ("C-d <Space>", sendMessage NextLayout)                   -- Switch layout.
            , ("C-d n", windows W.swapDown)                             -- Swap focused window with next window.
            , ("C-d p", windows W.swapUp)                               -- Swap focused window with the previous window.
            , ("C-d +", sendMessage (IncMasterN 1))                     -- Increment the number of windows in the master area.
            , ("C-d -", sendMessage (IncMasterN (-1)))                  -- Decrement the number of windows in the master area.
            , ("C-d 4", spawn "gnome-screenshot --area")                -- OS X style screenshotting.
            , ("C-d t", withFocused $ windows . W.sink)                 -- Force app back into tiling.
            , ("C-d v", pasteSelection)                                 -- Pastes the x buffer clipboard.
            , ("C-d w", gotoMenu)                                       -- Takes you to a window.
            , ("C-d l", spawn "slock")                                  -- Locks screen.
            , ("<XF86MonBrightnessDown>", spawn "sudo xbacklight -dec 10") -- Enable screen brightness function key.
            , ("<XF86MonBrightnessUp>", spawn "sudo xbacklight -inc 10")    -- ,
            , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume 1 +5%")
            , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume 1 -5%")
            , ("<XF86AudioMute>", spawn "pactl set-sink-mute 1 toggle")
            , ("M4-<Space>", sendMessage NextLayout)
            , ("C-d ,", spawn "playerctl previous")
            , ("C-d .", spawn "playerctl next")
            , ("C-d /", spawn "playerctl play-pause")
            , ("M4-<Tab>", cycleRecentWS [xK_Super_L] xK_Tab xK_Tab)
            ]
            ++
            [ (otherModMasks ++ "M4-" ++ key, action tag)
            | (tag, key)  <- zip workspaces' (map show [1..12])
            , (otherModMasks, action) <- [ ("", windows . W.greedyView) -- or W.view
                                         , ("S-", windows . W.shift)]
            ])
