# syntax=docker/dockerfile:1.2

FROM ros:noetic

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# First heavy install
RUN apt update && apt install -y \
    python3-pip \
    git \
    vim \
    openssh-client \
    build-essential \
    ros-noetic-desktop-full

# Then separately install VRPN
RUN apt update && apt install -y \
    ros-noetic-vrpn-client-ros
RUN pip3 install pyserial
RUN pip3 install ascii_graph

# Clean apt cache
RUN rm -rf /var/lib/apt/lists/*

# Prepare ssh known_hosts
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

# Clone fixed repositories A, B during build
# === Create proper catkin workspace ===
RUN mkdir -p /home/ros_ws/src

# === Clone fixed repositories into src ===
# WORKDIR /home/ros_ws/src

# RUN --mount=type=ssh \
#     git clone git@github.com:RLoad/ros_myo.git && \
#     git clone git@github.com:RLoad/vrpn_client_ros.git && \
#     git clone git@github.com:RLoad/net-ft-ros.git

# Create a symlink: make 'python' point to 'python3'
RUN ln -s /usr/bin/python3 /usr/bin/python

# === Set default working directory ===
WORKDIR /home/ros_ws

# === 8. Create entrypoint script ===
RUN echo '#!/bin/bash' > /home/entrypoint.sh && \
    echo 'source /opt/ros/noetic/setup.bash' >> /home/entrypoint.sh && \
    echo 'if [ ! -f /home/ros_ws/devel/setup.bash ]; then' >> /home/entrypoint.sh && \
    echo '  echo "First time build: running catkin_make..."' >> /home/entrypoint.sh && \
    echo '  cd /home/ros_ws && catkin_make' >> /home/entrypoint.sh && \
    echo 'fi' >> /home/entrypoint.sh && \
    echo 'source /home/ros_ws/devel/setup.bash' >> /home/entrypoint.sh && \
    echo 'exec bash' >> /home/entrypoint.sh

RUN chmod +x /home/entrypoint.sh



# === 9. Auto-source ROS setup when bash starts ===
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
RUN echo "source /home/ros_ws/devel/setup.bash" >> ~/.bashrc

# === 10. Set entrypoint ===
ENTRYPOINT ["/home/entrypoint.sh"]