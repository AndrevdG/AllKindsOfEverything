https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal

- download / install Caskaydia Cove Nerd Font Complete (https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip)
- install winget, windows store: app installer (Should be included in windows 11 but mine was missing it)
- download / install oh-my-posh (winget install oh-my-posh) (https://ohmyposh.dev/docs/installation/windows)
- download shanselman's ohmyposh them (or another one, the defualts are installed in %userprofile%\AppData\Local\Programs\oh-my-posh\themes) from: https://gist.github.com/shanselman/1f69b28bfcc4f7716e49eb5bb34d7b2c
- save the (raw) content %userprofile%\AppData\Local\Programs\oh-my-posh\themes\ohmyposhv3.json
- edit $profile and add 'oh-my-posh init pwsh --config %userprofile%\AppData\Local\Programs\oh-my-posh\themes\ohmyposhv3.json | Invoke-Expression'
(themes can be downloaded from https://ohmyposh.dev/docs/themes)
- (Optional) install github cli: winget install github.cli // useful if you work with github.
- (Optional) install git: winget install git.git // useful for azure devops (and others)
- install-module terminal-icons
- (Optional) change the opacity of terminal. Add "opacity": xx under profiles in settings.json (xx=percentage. 75/80 seems to be a nice starting point)