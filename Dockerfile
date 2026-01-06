# Use ROS Noetic Desktop Full as base
FROM osrf/ros:noetic-desktop-full

# Avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Networking, AMD GPU Drivers, and General Dependencies
RUN apt-get update && apt-get install -y \
    net-tools iputils-ping iproute2 curl wget git vim gpg terminator python3-pip \
    libgl1-mesa-dri libgl1-mesa-glx libgl1-mesa-dev mesa-utils mesa-vulkan-drivers libglx-mesa0 \
    xvfb x11vnc fluxbox supervisor feh \
    && rm -rf /var/lib/apt/lists/*
    
# Create the fluxbox settings directory and download bg
RUN mkdir -p /root/.fluxbox
RUN mkdir -p /usr/share/wallpapers && \
    curl -L https://images.wallpapersden.com/image/download/dark-black-abstract-art_aWltaGeUmZqaraWkpJRmbmdlrWZnZWU.jpg -o /usr/share/wallpapers/background.jpg
    
# Create Terminal config
RUN mkdir -p /root/.config/terminator/

# Copy the fluxbox menu file 
COPY fluxbox-menu /root/.fluxbox/menu
# Copy the teminal config
COPY terminator-config /root/.config/terminator/config

# Configure Fluxbox to use the dark wallpaper and custom menu
# Configure wallpaper
RUN echo "session.screen0.rootCommand: feh --bg-fill /usr/share/wallpapers/background.jpg" >> /root/.fluxbox/init && \
    echo "session.menuFile: /root/.fluxbox/menu" >> /root/.fluxbox/init

# 2. Install VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && rm -f packages.microsoft.gpg \
    && apt-get update && apt-get install -y code \
    && rm -rf /var/lib/apt/lists/*

# 3. Install noVNC and Websockify
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
    && chmod +x /opt/noVNC/utils/novnc_proxy

# 4. Setup Directories and Permissions
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix && \
    mkdir -p /etc/supervisor/conf.d

# 5. Configure ROS Environment and VS Code Alias
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /root/catkin_ws/devel/setup.bash ]; then source /root/catkin_ws/devel/setup.bash; fi" >> /root/.bashrc && \
    echo "alias code='code --user-data-dir=/root --no-sandbox'" >> /root/.bashrc && \
    echo "export ROS_HOSTNAME=localhost" >> /root/.bashrc && \
    echo "export ROS_MASTER_URI=http://localhost:11311" >> /root/.bashrc

# 6. Pre-install ROS VS Code Extension
RUN code --user-data-dir=/root --no-sandbox --install-extension ms-iot.vscode-ros \
         --install-extension ms-vscode.cpptools \
         --install-extension twxs.cmake \
         --install-extension ms-python.python

# 7. Finalize Environment
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ENV DISPLAY=:99
ENV SCREEN_RESOLUTION=1920x1080
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV GALLIUM_DRIVER=llvmpipe

EXPOSE 6080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
