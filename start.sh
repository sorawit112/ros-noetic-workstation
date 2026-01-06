#!/bin/bash

# Allow the container to connect to the host's X server if needed (optional)
xhost +local:docker

docker run -it \
  --name ros_workstation \
  --network host \
  --device=/dev/dri:/dev/dri \
  --shm-size=2g \
  --privileged \
  -v "$(pwd)/catkin_ws:/root/catkin_ws" \
  ros-noetic-workstation
