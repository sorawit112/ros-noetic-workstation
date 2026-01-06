#!/bin/bash

IMAGE_NAME="ros-noetic-workstation"
REMOTE_IMAGE="chinouplus/ros-noetic-workstation:latest"

# 1. Check if image exists locally
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    if [[ "$(docker images -q $REMOTE_IMAGE 2> /dev/null)" == "" ]]; then
        echo "☁️ Pulling from Docker Hub: $REMOTE_IMAGE..."
        docker pull $REMOTE_IMAGE
        docker tag $REMOTE_IMAGE $IMAGE_NAME
    else
        docker tag $REMOTE_IMAGE $IMAGE_NAME
    fi
else
    echo "✅ Using local image: $IMAGE_NAME"
fi

# 2. Cleanup stale X-server locks
sudo rm -f /tmp/.X99-lock

# 3. Launch browser in the background after a short delay
(
    echo "Waiting for GUI to initialize..."
    while ! curl -s localhost:6080 > /dev/null; do
        sleep 1
    done
    echo "🌐 Opening Browser at http://localhost:6080"
    # Works for Linux (xdg-open), Mac (open), and WSL/Windows (start)
    if command -v xdg-open > /dev/null; then xdg-open http://localhost:6080
    elif command -v open > /dev/null; then open http://localhost:6080
    else echo "Please open http://localhost:6080 manually"; fi
) &

# 4. Run the container with compatibility flags
echo "🏁 Starting ROS Workstation..."
docker run -it \
  --name ros-noetic-workstation \
  --rm \
  --network host \
  --device=/dev/dri:/dev/dri \
  --shm-size=2g \
  -e LIBGL_ALWAYS_SOFTWARE=1 \
  -e QT_X11_NO_MITSHM=1 \
  -v "$(pwd)/catkin_ws:/root/catkin_ws" \
  $IMAGE_NAME