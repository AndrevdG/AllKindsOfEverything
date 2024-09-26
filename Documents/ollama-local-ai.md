After watching the YouTube video by Dave from Dave's Garage about running a local AI, I wanted to try it out.
This document is just containing the commands related to this, so I know where to find them if I need to (hopefully)

Link to the [video](https://www.youtube.com/watch?v=DYhC7nFRL5I)

# Basic install of ollama in WSL
- Installing ollama within WSL: _curl -fsSL https://ollama.com/install.sh | sh_
- Starting Ollama: _ollama serve_ (note: ollama was already running after install)
- Downloading the latest llama 3.1 model into ollama: _ollama pull llama3.1:latest_
- Listing installed (ai) modules: _ollama list_
- Running a module: _ollama run llama3.1:latest_

# Installing webui to generate a chatgpt like interface
- install docker: _sudo snap install docker_ (at least on Ubuntu, haven't tried it had docker installed already)
- install webui: _docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama_
(Note: make sure your user has access rights to administrate docker)
- open _http://localhost:3000/_
- sign up _Note: this will be the admin account_
- **Note: see error below!!**
- Once you are in the interface I did not have any models loaded, even though I installed llama3.1 before (see Dave's video)
  - In the interface click on your account (top right corner)
  - Select _Admin Panel_ and got to _Setting_
  - Go to _Models_
  - Enter a model name in _Pull a model from ollama.com_. You can click the link below the input box to get model names. **_Note: just copy the name and paste it in the input field. Do nt select a link and try download!!_**
  - You can repeat this process to download different models

## Errors:
_Note: I used the Ubuntu 22.04 image, other distros might be different_
- **_docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]._** In my case this error was reported because the NVIDIA Conatiner toolkit
  was not installed:
  - _curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list_
  - _sudo apt-get update_
  - _sudo apt-get install -y nvidia-container-toolkit_
  - _sudo reboot_
  - after installing this I updated the container: _docker pull ghcr.io/open-webui/open-webui_
  - remove the old container instance:
     - docker ps -a
     - docker rm <open-webui-instance>
     - docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama
