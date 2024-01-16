_**Deprecated: VS Code now has native support: https://www.automagical.eu/posts/syncing-and-configuring-profiles-vscode-revisited/**_

# Introduction

While VS Code has a built in options for syncing your settings, it can be limited and does not allow you to easily switch between multiple profiles with different settings and different extentions loaded. When I first attempted to set this up I used different shortcuts for VS Code pointing to different folders for the user settings and extension storage. While this works, it is also pretty inefficient: Some extensions you might have in more profiles and this setup causes them to be downloaded multiple times. Disk storage is cheap, but it can get cumbursome. Especially when you want to be able to reuse your setup over multiple machines.

For the second attempt I found the VS Code extension **'Extensions profiles'**. This extension was written with the exact idea in mind and uses two other extensions to make the magic work, **'Settings Cycler'** and **'Settings Sync'**. Links to the extensions can be found in the Sources section below

# Installation
For the initial installation we will complete all the needed settings for the first profile. My advice is to follow these steps and only add new profiles after the initial setup is complete.

## Extensions profiles initial setup
Install the _Extension Profiles_ extension (and you might as well install _Settings Cycler_ and _Settings Sync_ as well)
Especially if you have a (fairly) clean install of VS Code you can just download and install the exentsion into your VS Code. This should automatically setup the correct folder structure and will name the current profile as _Default_

If this does not work and you get a permissions error, you can fairly easy create the folder structure yourself: 

   - In %userprofile%\.vscode create an empty folder _profiles_
   - Move the exension folder from %userprofile%\.vscode into the subfolder _profiles_
   - Rename the extensions folder. I created first an empty folder _Default_ as a standard profile with almost no extensions but you can of course name it something else
   - Start a cmd windows with Administrator priviliges and run _mklink /D %USERPROFILE%\.vscode\extensions %USERPROFILE%\.vscode\profiles\Default_ (or whatever name you decided to give your first profile)
   - Start VS Code

## Settings Cycler
After installing the _Settings Cycler_ extension into VS Code, you can use this to apply configuration specific to the active profile. For instance you can change to a different theme or apply different colors. For instance I like to set the _Activity Bar_ to a different color, depending on the active profile as a visual reminder that I am in a certain profile.

See the extension information for more details, but as an example:

```json
    "settings.cycle": [
        {
            "id": "Default", // must be unique
            "overrideWorkspaceSettings": false,
            "values": [
                {
                    // other settings...
                    "workbench.colorCustomizations": {
                        "activityBar.background": "#2c2c49"
                    }
                }
            ]
        }
    ]
```

Important is that:
- _id_ has to be unique and has to be the same name as the profile folder
- Under values you can add any settings that are unique for this profile. Note that these values override settings outside of the 'settings.cycle' settings in the _settings.json_. 

Settings are not removed however, so if you add 'activityBar.background' only in one profile, upon switching the settings is created, but when switching back to the other profile the settings keeps applied. So any setting that you need to be different between profiles, you need to specify with the correct value to prevent unexpected consequences. I would advise to have every _values_ section under a profile contain the same settings with the correct value for that specific profile.

## Settings Sync
By using the _Settings Sync_ extension you can sync each profile you created before to its own [Github gist](https://docs.github.com/en/get-started/writing-on-github/editing-and-sharing-content-with-gists/creating-gists#about-gists). This allows you te easily sync one or more of the profiles you created with other machines. A gist can be made private or public. If you create a gist to be public you can even share the VS Code profile with your friends or colleagues. Keep in mind that even a private gist is not secret. If you send someone the url to it, or someone happens upon it, they will be able to see the content.

With this in mind, we first have to update a local configuration file to prevent the extension from uploading unrelated files. Not sure why this happens, might be a bug. The solution seems relatively simple.

Open this file: %appdata%\Code\User\syncLocalSettings.json and edit the _ignoreUploadFolders_ to look like this:

```json
    "ignoreUploadFolders": [
        "workspaceStorage",
        "History",
        "globalStorage"
    ],
```

After you install the extension, the 'Welcome to Settings Sync' page will open, every time you start VS Code, until you configure the settings.

To configure, open the welcome page and:
- Press the login with Github button and login
- Accept the Authorization prompt to allow the extension access to gists
- Close the browser and go back to VS Code

If you did already have gists in your github account, the exention will ask you which one to download. Otherwise it will give you a skip button. Lets presume this is the first time you use the extension. So, to continue, open de _command palette_ and select _Sync: Update/Upload Settings_. It will give you a warning that this will force upload the settings to the gist (but thats ok, since there is nothing there)

If you open _Settings.json_ you will see that a new option has been added:

```json
    "sync.gist": "<GistIdentifier>"
```

Now, because we want to sync each profile to its own gist, we have to copy this _sync.gist_ setting to the _settings.cycle_ setting of the currenlty active profile.

So, this section should now look something like this:
```json
    "settings.cycle": [
        {
            "id": "Default", // must be unique
            "overrideWorkspaceSettings": false,
            "values": [
                {
                    "sync.gist": "<GistIdentifier>",
                    "sync.autoDownload": true,
                    "sync.autoUpload": true,
                    "sync.forceDownload": false,
                    "sync.forceUpload": false,
                    "sync.quietSync": false,
                    "sync.removeExtensions": true,
                    "sync.syncExtensions": true,
                    // other settings...
                    "workbench.colorCustomizations": {
                        "activityBar.background": "#2c2c49"
                    }
                }
            ]
        }
    ]
```
_Besides sync.gist the other settings are more or less optional. For me I want autoDownload and autoUpload and syncExtensions and removeExtensions active. So I add in all the settings in each profile and set them as needed (though all my profiles have the above settings._
This completes the basic settings for the first profile

## Create additional profiles
Now, to the important part. All the work we have done so far is only really useful if we can actually create additional profiles! 

I find the best way to start is to first, manually, create a new empty gist for use by this profile. You can do this from the github portal, by pressing the '+' right next to your profile settings.
- Give the json a description
- Create a file (you cannot create an empty gist), just call it test.json and type '{}' as content.

Once created, if you check your browsers URL box, the identifier is the last part of the URL.

Create a new _settings.cycle_ section by copying the default profile and change the _gistIdentifier_ to the one you just created. Also change any other settings relevant for you, like the _activityBar.background_ in the example below

```json
    "settings.cycle": [
        {
            "id": "Default", // must be unique
            "overrideWorkspaceSettings": false,
            "values": [
                {
                    "sync.gist": "<GistIdentifier>",
                    "sync.autoDownload": true,
                    "sync.autoUpload": true,
                    "sync.forceDownload": false,
                    "sync.forceUpload": false,
                    "sync.quietSync": false,
                    "sync.removeExtensions": true,
                    "sync.syncExtensions": true,
                    // other settings...
                    "workbench.colorCustomizations": {
                        "activityBar.background": "#2c2c49"
                    }
                }
            ]
        },
        {
            "id": "Profile2", // must be unique
            "overrideWorkspaceSettings": false,
            "values": [
                {
                    "sync.gist": "<NewGistIdentifier>",
                    "sync.autoDownload": true,
                    "sync.autoUpload": true,
                    "sync.forceDownload": false,
                    "sync.forceUpload": false,
                    "sync.quietSync": false,
                    "sync.removeExtensions": true,
                    "sync.syncExtensions": true,
                    // other settings...
                    "workbench.colorCustomizations": {
                        "activityBar.background": "#0d0d35"
                    }
                }
            ]
        }
    ]
```

To create the new profile you can just use the following command palette commands:
- Profiles: Clone
- Profiles: Create

If you have a fairly empty profile (maybe the default profile if your started from a clean install), I advise using the _Profiles: Clone_ command on the default profile (or whichever other profile). If you use create (or just create an empty folders in the profiles folder), remember that you will have to install the _Settings Sync_ and _Settings Cycler_ extensions into these, otherwise the profiles won't fully function.

_If you copy/create the profile folder manually you have to restart VS Code before it picks it up_

Test the setup by swapping to the newly created profile. Make sure to open the _command palette_ and selecting _Sync: Update/Upload Settings_ to force upload the settings once

Keep in mind that _Settings Sync_ will upload several configuration files to the gist as part of the sync, but most importantly the _settings.json_ and _extensions.json_. These files are downloaded (and locally overwritten) everytime you swap profile. This means that when you add additional profiles, you need to update the _settings.cycle_ section in all the profiles. If you do not do this you may end up overwriting the wrong gist with the wrong data.

So, to prevent this, you have two options: 
- Copy the _settings.cycle_ section to the clipboard
- Rotate through all the profiles and replace the _settings.cycle_ section
Or:
- Edit settings.json in each (associated) gist and replace the _settings.cycle_ section here


## Setting up an addition or new machine with the configured profiles
Basically you follow the same steps as we initially followed:
- Install the extensions: _Extension Profiles_, _Settings Cycler_ and _Settings Sync_
- **Important:** Open this file: %appdata%\Code\User\syncLocalSettings.json and edit the _ignoreUploadFolders_ to look like this:
```json
    "ignoreUploadFolders": [
        "workspaceStorage",
        "History",
        "globalStorage"
    ],
```
- Clone the created default profile and create each profile that you want available on this machine (which does not need to be all of them), using the _command palette_ **Note:** Sometimes clone does not work the first time. As a work around you can just create an empty random profile. After this the clone command works. You can remove the random profile.
- Go to the 'Welcome to Settings Sync' tab
   - Login to github
   - Select the gist that belongs with the active profile (likely Default at this stage)
   - Use the _command palette_ and issue _Sync: Download Settings_

You only have to do this for one profile, because now we have a settings.json file which already contains all the needed information for the other profiles. So as long as you created (cloned) the specific profile folder, you can now switch to it and it will setup the workspace for this profile, including downloading needed extensions


# Sources

- https://marketplace.visualstudio.com/items?itemName=cyberbiont.vscode-profiles
- https://marketplace.visualstudio.com/items?itemName=hoovercj.vscode-settings-cycler
- https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync
