
Target System
------------------------------------------


-  |intel| processors:

   -  |atom| processor with |intel| SSE4.1 support
   -  |intel| Pentium® processor N4200/5, N3350/5, N3450/5 with |intel| HD Graphics
   -  |core| Ultra processors (Series 1)
   -  15th Generation |core| processors with |xe| or |intel| UHD Graphics *(partial support - see note below)*
   -  14th Generation |core| processors with |xe| or |intel| UHD Graphics
   -  13th Generation |core| processors with |xe| or |intel| UHD Graphics
   -  12th Generation |core| processors with |xe| or |intel| UHD Graphics
   -  11th Generation |core| processors with |xe| or |intel| UHD Graphics
   -  10th Generation |core| processors with an integrated GPU and |intel| UHD Graphics

-  8 GB or more RAM
-  Free space on hard drive:

   -  10 GB for standard install
   -  30 GB for complete install

-  |ubuntu_version|
-  |realsense| camera D435i
-  Slamtec* RPLIDAR A3 2D LIDAR (optional)

.. note::
   | There are known issues when deploying Robotics AI Suite with ROS2 Humble, where the underlying OS is Ubuntu 22.04 with kernel version less or equal 6.8. Such setups does not fully support GPU/NPU offload scenarios for 15th gen processors so only CPU-based examples should be used.

.. note::

   | Intel does not recommend running simulations, like Gazebo*, on a physical robot.
