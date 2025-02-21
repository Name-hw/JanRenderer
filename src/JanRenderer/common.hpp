#pragma once

// volk
#define VK_NO_PROTOTYPES
#define VOLK_IMPLEMENTATION
#include <volk.h>

// GLFW
#define VK_USE_PLATFORM_WIN32_KHR
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_WIN32
#include <GLFW/glfw3native.h>

// cglm
#define CGLM_FORCE_DEPTH_ZERO_TO_ONE
#include <cglm/struct.h>

// JrClasses
// There are many bugs in zig, so use JrClasses.hpp that I created instead of
// this automatically generated header file.
// #include <JrClasses.h>
#include "JrClasses.hpp"

// std
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <optional>
#include <random>
#include <set>
#include <stdexcept>
#include <unordered_map>
#include <vector>