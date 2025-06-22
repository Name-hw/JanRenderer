#pragma once

#ifdef __cplusplus

#define NOMINMAX

#include "common.hpp"

struct QueueFamily {
  std::optional<uint32_t> graphicsFamily;
  std::optional<uint32_t> presentFamily;
  std::optional<uint32_t> transferFamily;
  std::optional<uint32_t> computeFamily;

  bool isComplete() {
    return graphicsFamily.has_value() && presentFamily.has_value() &&
           transferFamily.has_value() && computeFamily.has_value();
  }
};

struct SwapChainSupportDetails {
  VkSurfaceCapabilitiesKHR capabilities;
  std::vector<VkSurfaceFormatKHR> formats;
  std::vector<VkPresentModeKHR> presentModes;
};

struct Vertex {
  vec3s pos;
  vec3s color;
  vec2s texCoord;

  static VkVertexInputBindingDescription getBindingDescription() {
    VkVertexInputBindingDescription bindingDescription{};
    bindingDescription.binding = 0;
    bindingDescription.stride = sizeof(Vertex);
    bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    return bindingDescription;
  }

  static std::array<VkVertexInputAttributeDescription, 3>
  getAttributeDescriptions() {
    std::array<VkVertexInputAttributeDescription, 3> attributeDescriptions{};

    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = VK_FORMAT_R32G32B32_SFLOAT;
    attributeDescriptions[0].offset = offsetof(Vertex, pos);

    attributeDescriptions[1].binding = 0;
    attributeDescriptions[1].location = 1;
    attributeDescriptions[1].format = VK_FORMAT_R32G32B32_SFLOAT;
    attributeDescriptions[1].offset = offsetof(Vertex, color);

    attributeDescriptions[2].binding = 0;
    attributeDescriptions[2].location = 2;
    attributeDescriptions[2].format = VK_FORMAT_R32G32_SFLOAT;
    attributeDescriptions[2].offset = offsetof(Vertex, texCoord);

    return attributeDescriptions;
  }
};
/*
namespace std {
template <> struct hash<Vertex> {
  size_t operator()(Vertex const &vertex) const {
    return ((hash<vec3s>()(vertex.pos) ^
             (hash<glm::vec3>()(vertex.color) << 1)) >>
            1) ^
           (hash<glm::vec2>()(vertex.texCoord) << 1);
  }
};
} // namespace std
*/
struct UniformBufferObject {
  /*
  alignas(16) mat4s model;
  alignas(16) mat4s view;
  alignas(16) mat4s proj;
  */

  mat4s model;
  mat4s view;
  mat4s proj;
};

struct Particle {
  vec2s position;
  vec2s velocity;
  vec4s color;

  static VkVertexInputBindingDescription getBindingDescription() {
    VkVertexInputBindingDescription bindingDescription{};
    bindingDescription.binding = 0;
    bindingDescription.stride = sizeof(Particle);
    bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    return bindingDescription;
  }
  static std::array<VkVertexInputAttributeDescription, 2>
  getAttributeDescriptions() {
    std::array<VkVertexInputAttributeDescription, 2> attributeDescriptions{};

    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = VK_FORMAT_R32G32_SFLOAT;
    attributeDescriptions[0].offset = offsetof(Particle, position);

    attributeDescriptions[1].binding = 0;
    attributeDescriptions[1].location = 1;
    attributeDescriptions[1].format = VK_FORMAT_R32G32B32A32_SFLOAT;
    attributeDescriptions[1].offset = offsetof(Particle, color);

    return attributeDescriptions;
  }
};

const size_t MAX_FRAMES_IN_FLIGHT = 2;

const uint32_t PARTICLE_COUNT = 8192;

const std::string MODEL_PATH = "assets/models/viking_room.obj";
const std::string TEXTURE_PATH = "assets/textures/viking_room.png";

const std::vector<const char *> validationLayers = {
    "VK_LAYER_KHRONOS_validation"};

const std::vector<const char *> deviceExtensions = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME, VK_EXT_SHADER_OBJECT_EXTENSION_NAME};

#ifdef _DEBUG
const bool enableValidationLayers = true;
#else
const bool enableValidationLayers = false;
#endif

class JanRenderer {

public:
  char *applicationName;
  int width;
  int height;

  struct GlfwUserPointer {
    JrCamera *camera;
    JanRenderer *renderer;
  };

  JanRenderer(const char *applicationName_, int width_, int height_);
  ~JanRenderer();
  void run();

private:
  GLFWwindow *window;
  GlfwUserPointer *glfwUserPointer;

  VkInstance instance;
  VkDebugUtilsMessengerEXT debugMessenger;
  VkSurfaceKHR surface;

  VkPhysicalDevice physicalDevice = VK_NULL_HANDLE;
  VkDevice device;

  // queue
  QueueFamily queueFamily;
  VkQueue graphicsQueue;
  VkQueue presentQueue;
  VkQueue transferQueue;
  VkQueue computeQueue;

  VkSwapchainKHR swapChain;
  std::vector<VkImage> swapChainImages;
  VkFormat swapChainImageFormat;
  VkExtent2D swapChainExtent;
  std::vector<VkImageView> swapChainImageViews;
  std::vector<VkFramebuffer> swapChainFramebuffers;

  VkRenderPass renderPass;
  VkDescriptorSetLayout descriptorSetLayout;
  VkPipelineLayout pipelineLayout;
  VkPipeline graphicsPipeline;

  VkDescriptorSetLayout computeDescriptorSetLayout;
  VkPipelineLayout computePipelineLayout;
  VkPipeline computePipeline;

  VkCommandPool commandPool;
  VkCommandPool transferCommandPool;
  VkCommandPool computeCommandPool;
  std::vector<VkCommandBuffer> commandBuffers;
  std::vector<VkCommandBuffer> computeCommandBuffers;
  VkCommandBuffer guiCommandBuffer;
  // secondary command buffers
  // ...

  std::vector<VkSemaphore> imageAvailableSemaphores;
  std::vector<VkSemaphore> renderFinishedSemaphores;
  std::vector<VkSemaphore> computeFinishedSemaphores;
  std::vector<VkFence> inFlightFences;
  std::vector<VkFence> computeInFlightFences;
  uint32_t currentFrame = 0;

  bool framebufferResized = false;

  std::vector<Vertex> vertices;
  std::vector<uint32_t> indices;
  VkBuffer vertexBuffer;
  VkDeviceMemory vertexBufferMemory;
  VkBuffer indexBuffer;
  VkDeviceMemory indexBufferMemory;

  std::vector<VkBuffer> uniformBuffers;
  std::vector<VkDeviceMemory> uniformBuffersMemory;
  std::vector<void *> uniformBuffersMapped;

  // descriptor pools
  VkDescriptorPool descriptorPool;
  std::vector<VkDescriptorSet> descriptorSets;

  VkDescriptorPool computeDescriptorPool;
  std::vector<VkDescriptorSet> computeDescriptorSets;

  uint32_t mipLevels;
  VkImage textureImage;
  VkDeviceMemory textureImageMemory;
  VkImageView textureImageView;
  VkSampler textureSampler;

  VkImage depthImage;
  VkDeviceMemory depthImageMemory;
  VkImageView depthImageView;

  VkSampleCountFlagBits msaaSamples = VK_SAMPLE_COUNT_1_BIT;

  VkImage colorImage;
  VkDeviceMemory colorImageMemory;
  VkImageView colorImageView;

  std::vector<VkBuffer> shaderStorageBuffers;
  std::vector<VkDeviceMemory> shaderStorageBuffersMemory;

  // HMODULE JrClasses_lib; dynamic loading of JrClasses library (old way)
  JrCamera *camera;
  JrGui *gui;

  float deltaTime = 0.0f;       // Time between current frame and last frame
  float timeOfLastFrame = 0.0f; // Time of last frame

  // helper functions
  void populateDebugMessengerCreateInfo(
      VkDebugUtilsMessengerCreateInfoEXT &createInfo);
  // populateDebugMessengerCreateInfo vkDebugCallback
  static VKAPI_ATTR VkBool32 VKAPI_CALL
  vkDebugCallback(VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
                  VkDebugUtilsMessageTypeFlagsEXT messageType,
                  const VkDebugUtilsMessengerCallbackDataEXT *pCallbackData,
                  void *pUserData) {

    if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) {
      std::cerr << "\033[1;33m" << "[WARNING] " << "\033[0m";
    }
    if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) {
      std::cerr << "\033[1;31m" << "[ERROR] " << "\033[0m";
    }

    std::cerr << "validation layer: " << pCallbackData->pMessage << std::endl;

    return VK_FALSE;
  }
  QueueFamily getQueueFamily(VkPhysicalDevice physicalDevice_);
  uint32_t findMemoryType(uint32_t typeFilter,
                          VkMemoryPropertyFlags properties);
  void createBuffer(VkDeviceSize size, VkBufferUsageFlags usage,
                    VkSharingMode sharingMode, uint32_t queueFamilyIndices_[],
                    VkMemoryPropertyFlags properties, VkBuffer &buffer,
                    VkDeviceMemory &bufferMemory);
  VkCommandBuffer beginSingleTimeCommands(VkCommandPool commandPool_);
  void endSingleTimeCommands(VkQueue queue, VkCommandPool commandPool_,
                             const VkCommandBuffer &commandBuffer);
  std::vector<VkCommandBuffer>
  setupCommandBuffer(VkCommandPool commandPool_,
                     const uint32_t commandBufferCount);
  void flushSetupCommands(VkQueue queue, VkCommandPool commandPool_,
                          const std::vector<VkCommandBuffer> &commandBuffers,
                          const uint32_t commandBufferCount);
  void copyBuffer(VkQueue queue, VkCommandPool commandPool_, VkBuffer srcBuffer,
                  VkBuffer dstBuffer, VkDeviceSize size);
  void createCommandPool(VkCommandPoolCreateFlags flags,
                         uint32_t queueFamilyIndex, VkCommandPool &commandPool);
  void transitionImageLayout(VkCommandBuffer commandBuffer, VkImage image,
                             VkFormat format, VkImageLayout oldLayout,
                             VkImageLayout newLayout, uint32_t mipLevels);
  void copyBufferToImage(const VkCommandBuffer &commandBuffer, VkBuffer buffer,
                         VkImage image, uint32_t width, uint32_t height);
  VkImageView createImageView(VkImage image, VkFormat format,
                              VkImageAspectFlags aspectFlags,
                              uint32_t mipLevels);
  bool hasStencilComponent(VkFormat format);
  VkSampleCountFlagBits getMaxUsableSampleCount();
  VkShaderModule createShaderModule(const std::vector<char> &code);

  // initVolk
  void initVolk();

  // initJrObjects
  void initJrObjects();

  // initWindow
  void initWindow();
  static void framebufferResizeCallback(GLFWwindow *window, int width,
                                        int height);

  // initVulkan
  void initVulkan();
  void createInstance();
  bool checkValidationLayerSupport();
  std::vector<const char *> getRequiredExtensions();
  void setupDebugMessenger();
  void createSurface();
  void pickPhysicalDevice();
  bool isDeviceSuitable(VkPhysicalDevice physicalDevice_);
  bool checkDeviceExtensionSupport(VkPhysicalDevice physicalDevice_);
  void createLogicalDevice();
  void createSwapChain();
  SwapChainSupportDetails
  querySwapChainSupport(VkPhysicalDevice physicalDevice_);
  VkSurfaceFormatKHR chooseSwapSurfaceFormat(
      const std::vector<VkSurfaceFormatKHR> &availableFormats);
  VkPresentModeKHR chooseSwapPresentMode(
      const std::vector<VkPresentModeKHR> &availablePresentModes);
  VkExtent2D chooseSwapExtent(const VkSurfaceCapabilitiesKHR &capabilities);
  void createImageViews();
  void createRenderPass();
  void createDescriptorSetLayout();
  void createComputeDescriptorSetLayout();
  void createGraphicsPipeline();
  void createComputePipeline();
  void createCommandPools();
  void createColorResources();
  void createDepthResources();
  VkFormat findDepthFormat();
  VkFormat findSupportedFormat(const std::vector<VkFormat> &candidates,
                               VkImageTiling tiling,
                               VkFormatFeatureFlags features);
  void createFramebuffers();
  void createTextureImage();
  void generateMipmaps(VkImage image, VkFormat imageFormat, int32_t texWidth,
                       int32_t texHeight, uint32_t mipLevels);
  void createImage(uint32_t width, uint32_t height, uint32_t mipLevels,
                   VkSampleCountFlagBits numSamples, VkFormat format,
                   VkImageTiling tiling, VkImageUsageFlags usage,
                   VkMemoryPropertyFlags properties, VkImage &image,
                   VkDeviceMemory &imageMemory);
  void createTextureImageView();
  void createTextureSampler();
  void loadModel();
  void createVertexBuffer();
  void createIndexBuffer();

  void createUniformBuffers();
  void createDescriptorPool();
  void createDescriptorSets();
  void createCommandBuffers();

  void createShaderStorageBuffers();
  void createComputeDescriptorPool();
  void createComputeDescriptorSets();
  void createComputeCommandBuffers();

  void createSyncObjects();

  // initGui
  void initGui();

  // mainLoop
  void mainLoop();
  void updateDeltaTime();
  void drawFrame();
  void recordCommandBuffer(VkCommandBuffer commandBuffer, uint32_t imageIndex);
  void recordComputeCommandBuffer(VkCommandBuffer commandBuffer);
  void updateUniformBuffer(uint32_t currentImage);
  void recreateSwapChain();

  // cleanup
  void cleanup();
  void cleanupSwapChain();
};

extern "C" {
__declspec(dllexport) JanRenderer *jrNew(const char *applicationName_,
                                         int width, int height);
__declspec(dllexport) void jrDelete(JanRenderer *self);
__declspec(dllexport) void jrRun(JanRenderer *self);
}

#endif