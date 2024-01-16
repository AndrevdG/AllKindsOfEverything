# Introduction

Since a while now, you can use SSH directly from PowerShell (tbh not even sure when they introduced this, I used ssh in WSL before). Since this is now possible, I thought it might also be prudent to start using a SSH key for access to linux servers in stead of the password(s) I still tend to favor. I have tried this from linux machines before and it works great but I never bothered to set it up for Windows (PowerShell) before.

# Creating a key and making sure it will be available

1. Use keygen the same as you would on linux. Using a passphrase is highly recommended!
2. Set the ssh-agent service to start automatically and start it
3. Add your newly generated key to the ssh-agent


``` PowerShell
# Source: https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
ssh-keygen -t ed25519

# By default the ssh-agent service is disabled. Configure it to start automatically.
# Make sure you're running as an Administrator.
Get-Service ssh-agent | Set-Service -StartupType Automatic

# Start the service
Start-Service ssh-agent

# This should return a status of Running
Get-Service ssh-agent

# Now load your key files into ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

# Copy the public key to whatever server you will be using it on

You can also setup SSH on windows, this is something I haven't tried yet. For the moment just tested with linux. Also, in this case, I created a (Ubuntu) user for myself, with sudo permissions and added the public key:

``` bash
# Create a new user
$ sudo adduser <name>
$ sudo usermod -aG sudo <name>

# Login as that user
$ su - <name>

# Create the .ssh directory
$ mkdir ~/.ssh

# Open (and/or create) file to store the authorized keys and paste the public key
# This can be found (following the example above) in C:\users\<name>\.ssh\id_ed25519.pub
$ nano ~/.ssh/authorized_keys
```

Not strictly speaking part of this excersize, but you may also want to check if:
- SSH root login is disabled
- SSH password login is disabled (of course only if all valid users have setup keys)

Importantly, sshd_config (or a config file in sshd_config.d) should include:
- PasswordAuthentication no
- PubkeyAuthentication yes
- PermitRootLogin no





# Sources:
- https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
- https://thucnc.medium.com/how-to-create-a-sudo-user-on-ubuntu-and-allow-ssh-login-20e28065d9ff
