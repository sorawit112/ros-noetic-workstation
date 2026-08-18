#!/bin/bash

IMAGE_NAME="ros-noetic-workstation"
REMOTE_IMAGE="chinouplus/ros-noetic-workstation:latest"

# -------------------------------------------------------------
# Input handling for AMR_HOST_NAME and AMR_TYPE
# -------------------------------------------------------------
# Initialize variables if not already set by environment
AMR_HOST_NAME="${AMR_HOST_NAME:-}"
AMR_TYPE="${AMR_TYPE:-}"

# Parse arguments (overwrites environment variables if passed)
for arg in "$@"; do
    arg_upper="${arg^^}"
    if [[ "$arg_upper" == "MAG_FORK" || "$arg_upper" == "MAG_LIFT" || "$arg_upper" == "ONE_SHOT" ]]; then
        AMR_TYPE="$arg_upper"
    else
        AMR_HOST_NAME="$arg"
    fi
done

# Prompt for AMR_HOST_NAME if empty
if [ -z "$AMR_HOST_NAME" ]; then
    read -p "Enter AMR_HOST_NAME (e.g., BODYSHOP_FL, PAINTSHOP_FL): " AMR_HOST_NAME
fi

# Normalize AMR_TYPE to uppercase
AMR_TYPE="${AMR_TYPE^^}"

# Prompt for AMR_TYPE if empty or invalid
while [[ "$AMR_TYPE" != "MAG_FORK" && "$AMR_TYPE" != "MAG_LIFT"  && "$AMR_TYPE" != "ONE_SHOT" ]]; do
    read -p "Enter AMR_TYPE (MAG_FORK or MAG_LIFT or ONE_SHOT): " AMR_TYPE
    AMR_TYPE="${AMR_TYPE^^}"
done

echo "🤖 AMR Host Name: $AMR_HOST_NAME"
echo "🔧 AMR Type: $AMR_TYPE"

# Resolve IP address from .ssh/config
AMR_HOST_NAME_IP=$(ssh -G "$AMR_HOST_NAME" 2>/dev/null | awk '/^hostname / {print $2}')

if [ -z "$AMR_HOST_NAME_IP" ] || [ "$AMR_HOST_NAME_IP" = "${AMR_HOST_NAME,,}" ]; then
    # Fallback to checking if the input itself is an IP address
    if [[ "$AMR_HOST_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        AMR_HOST_NAME_IP="$AMR_HOST_NAME"
    else
        echo "❌ Error: Could not resolve IP for host '$AMR_HOST_NAME' from .ssh/config, and it is not a valid IP."
        exit 1
    fi
fi
echo "🌐 Resolved AMR IP: $AMR_HOST_NAME_IP"

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

# Configure route using resolved IP
echo "🛠️ Configuring route..."
sudo route add -net 19.214.4.0 netmask 255.255.255.0 gw "19.214.4.1"
sudo route del -net 192.168.127.0 netmask 255.255.255.0 2>/dev/null
sudo route add -net 192.168.127.0 netmask 255.255.255.0 gw "$AMR_HOST_NAME_IP"

# Modify rviz configuration namespaces using sudo (since they are owned by root)
RVIZ_CONFIG_DIR="catkin_ws/src/rviz_config"
if [ ! -d "$RVIZ_CONFIG_DIR" ]; then
    RVIZ_CONFIG_DIR="catkin_ws/src/rviz/config"
fi

TARGET_FILE=""
if [ "$AMR_TYPE" = "MAG_LIFT" ]; then
    TARGET_FILE="$RVIZ_CONFIG_DIR/MAG_LIFT.rviz"
elif [ "$AMR_TYPE" = "MAG_FORK" ]; then
    TARGET_FILE="$RVIZ_CONFIG_DIR/MAG_FORK.rviz"
elif [ "$AMR_TYPE" = "ONE_SHOT" ]; then
    TARGET_FILE="$RVIZ_CONFIG_DIR/ONE_SHOT.rviz"
fi

if [ -n "$TARGET_FILE" ] && [ -f "$TARGET_FILE" ]; then
    BACKUP_FILE="${TARGET_FILE}.bak"
    # Create backup if it doesn't exist
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Creating backup of $(basename "$TARGET_FILE")..."
        sudo cp "$TARGET_FILE" "$BACKUP_FILE"
    fi

    # Restore from backup to start with a clean state
    # echo "Restoring clean template for $(basename "$TARGET_FILE")..."
    # sudo cp "$BACKUP_FILE" "$TARGET_FILE"

    # Replace namespaces using Python with sudo
    echo "Replacing topic namespaces in $(basename "$TARGET_FILE") with '$AMR_HOST_NAME'..."
    sudo python3 -c "
import re

filename = '$TARGET_FILE'
amr_hostname = '$AMR_HOST_NAME'

exclude = {'april_pose_array', 'clicked_point', 'initialpose', 'move_base_simple', 'PL', 'VM'}

with open(filename, 'r') as f:
    content = f.read()

def repl(match):
    prefix = match.group(1)
    ns = match.group(2)
    suffix = match.group(3) or ''
    if ns in exclude:
        return match.group(0)
    return f'{prefix}{amr_hostname}{suffix}'

pattern = re.compile(r'((?:Topic|Marker Topic|Robot Description):\s+/)([^/\s]+)(/.*)?')
content = pattern.sub(repl, content)

with open(filename, 'w') as f:
    f.write(content)
"
    echo "✅ Successfully updated $(basename "$TARGET_FILE") topic namespaces."
else
    echo "⚠️ Warning: Target rviz config file for AMR_TYPE '$AMR_TYPE' not found at '$TARGET_FILE'."
fi

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
  --env-file .env \
  -e AMR_HOST_NAME="$AMR_HOST_NAME" \
  -e AMR_TYPE="$AMR_TYPE" \
  -e LIBGL_ALWAYS_SOFTWARE=1 \
  -e QT_X11_NO_MITSHM=1 \
  -v "$(pwd)/catkin_ws:/root/catkin_ws" \
  $IMAGE_NAME
