# Introduction

To be added later






# syncLocalSettings.json
Very important: Makes sure that the syncLocalSettings.json file contains the following section:

```json
    "ignoreUploadFolders": [
        "workspaceStorage",
        "History",
        "globalStorage"
    ],
```

By default this section only contains 'workspaceStorage' but then other files from your projects will get synced. This will break the sync (because the files in the gist get to big), but may also lead to private information being uploaded!