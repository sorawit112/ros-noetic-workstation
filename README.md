# 🐳 ROS Noetic + Ryzen AI (AMDGPU) Docker Environment

This repository contains a high-performance, hardware-accelerated ROS development environment. It is specifically tuned for **Ryzen AI (RDNA3)** integrated GPUs and solves common conflicts when running Docker with `--network host` on a Linux host (ExpertBook).

---

## 🏗 System Architecture

The container shares the **Host Network Stack**. This allows for seamless communication with robots or other devices on your local network without the complexity of Docker NAT port-forwarding.



---

## 🔌 Port & Display Map

To avoid crashing your host OS, the container is "offset" to non-standard ports and displays. This prevents "Address already in use" errors on your ExpertBook.

| Component | Identifier | Purpose |
| :--- | :--- | :--- |
| **Virtual Display** | `:99` | Prevents conflict with host display `:0` or `:1`. |
| **Web UI Port** | `6080` | Access the desktop at `http://localhost:6080`. |
| **VNC Stream** | `5999` | Internal stream between x11vnc and noVNC. |
| **ROS Master** | `11311` | The standard ROS coordination port. |

---

## 🚀 Graphics Acceleration (AMD Ryzen AI)

This container is optimized for the **RDNA3 architecture** (e.g., Radeon 780M/760M).

* **Passthrough:** Maps `/dev/dri` to the container for direct hardware access.
* **Driver:** Uses the `radeonsi` Gallium driver via Mesa.
* **Offloading:** RViz and Gazebo 3D rendering are handled by the GPU, keeping CPU usage low.



---

## 🛠 Functional Workflow (Supervisord)

The container uses `supervisord` to manage the startup sequence. This ensures that the environment is ready before ROS components launch:

1.  **Cleanup:** Clears stale `/tmp/.X99-lock` files from the shared host directory.
2.  **Xvfb (Display :99):** Creates the virtual canvas in memory.
3.  **Fluxbox:** Provides the window manager and taskbar.
4.  **x11vnc:** Grabs the `:99` canvas and serves it on port `5999`.
5.  **noVNC:** Converts the VNC stream to WebSockets for your browser on port `6080`.
6.  **roscore:** Launches the ROS Master automatically.

---

## 📂 Project Structure

* **Dockerfile:** Installs ROS Noetic, AMD Mesa drivers, VS Code, and noVNC.
* **supervisord.conf:** Defines the "Keep-Alive" logic and display offsets.
* **catkin_ws:** (Volume Mapped) Your source code lives here on the host for persistence.

---

## 💻 Usage

### 1. Build the Image
```bash
docker build -t ros-noetic-novnc .
docker run -it \
  --name ros_workstation \
  --network host \
  --device=/dev/dri:/dev/dri \
  --shm-size=2g \
  -v "$(pwd)/catkin_ws:/root/catkin_ws" \
  ros-noetic-novnc
```
