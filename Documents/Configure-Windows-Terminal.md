# Introduction
How to setup a new computer using the profile settings and prompt and what-not we like to use.


# Steps:
- Install terminal from the Windows Store (is already included in Windows 11)
- Install winget, windows store: app installer (Should be included in windows 11 but one of mine was missing it, might be a Home edition / upgrade thing)
- _winget install oh-my-posh_ Install Oh My Posh prompt (https://ohmyposh.dev/docs/installation/windows)
- _winget install github.cli_ Install github client
- _winget install git.git_ Install the git client
- _winget install neovim.neovim_
- _install-module terminal-icons_ Install terminal icons. These show icons in the terminal, for instance when you do a directory listing
- Download / install Caskaydia Cove Nerd Font Complete (https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip). You can also use another 'Nerd' font if you like, most should work (supposedly)
- _Download https://gist.github.com/AndrevdG/739b47cb134c1ed069a780b810a35c83#file-andrevdg-omp-json_ This is the Oh My Posh theme file. Save as $env:userprofile\AppData\Local\Programs\oh-my-posh\themes\andrevdg.omp.json
- _Download https://gist.github.com/AndrevdG/739b47cb134c1ed069a780b810a35c83#file-powershell_profile-ps1_ This is the PowerShell profile, save in $PROFILE
- Edit the Windows Terminal settings json and replace the following with:
```json
        "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
        "defaults": 
        {
            "font": 
            {
                "face": "CaskaydiaCove NF"
            },
            "opacity": 75
        },
```

# Sources
These (main) sources were uses as inspiration and for the most part, a lot of the PowerShell Profile and Oh My Posh configuration come from watching these guys:

Scott Hanselman:
- https://www.youtube.com/watch?v=VT2L1SXFq9U
- https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal

Takuya Matsuyama:
- https://www.youtube.com/watch?v=5-aK2_WwrmM
- https://github.com/craftzdog/dotfiles-public