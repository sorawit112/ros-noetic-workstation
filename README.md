# 🐳 ROS Noetic Workstation (Ryzen AI / AMDGPU Optimized)

A high-performance, hardware-accelerated ROS Noetic development environment. This workstation is specifically tuned for **AMD Ryzen AI (RDNA3)** integrated GPUs and uses a non-conflicting display architecture to run alongside your host Linux desktop.

---

## 🏗 System Architecture

The container uses **Host Networking** for zero-latency communication with external ROS nodes and hardware. To prevent conflicts with your ExpertBook's native display, we use a virtual X-Server offset.



### 🔌 Port & Display Map
| Component | Identifier | Purpose |
| :--- | :--- | :--- |
| **Virtual Display** | `:99` | Isolates the container from Host Display `:0`. |
| **Web UI (noVNC)** | `6080` | Access via `http://localhost:6080`. |
| **VNC Stream** | `5999` | Internal video stream port. |
| **ROS Master** | `11311` | Standard ROS Master coordination. |

---

## 🚀 Graphics Acceleration

Optimized for **AMD Radeon 780M/760M** (RDNA3) hardware:
* **GPU Passthrough:** Maps `/dev/dri` for native RDNA3 performance.
* **Mesa Drivers:** Utilizes `radeonsi` for RViz and Gazebo hardware acceleration.
* **Efficiency:** Offloads 3D rendering from the CPU to the integrated GPU.



---

## 🛠 Features

### 💻 Custom UI & Desktop
- **Window Manager:** Lightweight Fluxbox with a custom dark tech wallpaper.
- **Terminal:** Pre-configured **Terminator** with dark themes and AMD-inspired styling.
- **Right-Click Menu:** - `Terminal`: Quick-launch shell.
  - `ROS Tools > Start roscore`: Launches ROS Master in a new window.
  - `VS Code`: Integrated development environment.

### 📝 VS Code: Robotics Developer Environment
The environment comes pre-installed with the **Ranch Hand Robotics RDE Pack**, featuring:
- URDF & Xacro visualizers.
- ROS message/service intellisense.
- Integrated Foxglove/Webviz support.

---

## 📂 Project Structure

* `Dockerfile`: ROS Noetic + AMD Drivers + VS Code + noVNC.
* `supervisord.conf`: Process manager (handles Xvfb, Fluxbox, and VNC).
* `fluxbox-menu`: Custom right-click desktop configuration.
* `start.sh`: Intelligent startup and browser automation script.
* `catkin_ws/`: Volume mapped directory for your persistent source code.

---

## 💻 Usage

### 1. Automated Setup (Recommended)
The provided `start.sh` script checks if the image exists locally. If not, it pulls it from Docker Hub, cleans host locks, and automatically opens your browser.

```bash
chmod +x start.sh
./start.sh
```

### 2. Build and Run the Image locally
```bash
docker build -t ros-noetic-workstation .
docker run -it \
  --name ros_workstation \
  --network host \
  --device=/dev/dri:/dev/dri \
  --shm-size=2g \
  -v "$(pwd)/catkin_ws:/root/catkin_ws" \
  ros-noetic-workstation
```

### 3. Run public DockerImage
```bash
docker run -it \
  --name ros_workstation \
  --network host \
  --device=/dev/dri:/dev/dri \
  --shm-size=2g \
  -v "$(pwd)/catkin_ws:/root/catkin_ws" \
  chinouplus/ros-noetic-workstation
```
