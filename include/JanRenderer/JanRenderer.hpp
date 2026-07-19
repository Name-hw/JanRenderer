#pragma once

#ifdef __cplusplus

#define NOMINMAX

#include "common.hpp"

// struct QueueFamilyIndices {
//   std::optional<uint32_t> graphicsFamily;
//   std::optional<uint32_t> presentFamily;
//   std::optional<uint32_t> transferFamily;
//   std::optional<uint32_t> computeFamily;

//  bool isComplete() {
//    return graphicsFamily.has_value() && presentFamily.has_value() &&
//           transferFamily.has_value() && computeFamily.has_value();
//  }
//};

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
  vec4s position;
  vec3s velocity;
  vec4s color;

  static VkVertexInputBindingDescription2EXT getBindingDescription() {
    VkVertexInputBindingDescription2EXT bindingDescription{};
    bindingDescription.sType =
        VK_STRUCTURE_TYPE_VERTEX_INPUT_BINDING_DESCRIPTION_2_EXT;
    bindingDescription.binding = 1;
    bindingDescription.stride = sizeof(Particle);
    bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;
    bindingDescription.divisor = 0;

    return bindingDescription;
  }

  static std::array<VkVertexInputAttributeDescription2EXT, 2>
  getAttributeDescriptions() {
    std::array<VkVertexInputAttributeDescription2EXT, 2>
        attributeDescriptions{};

    attributeDescriptions[0].sType =
        VK_STRUCTURE_TYPE_VERTEX_INPUT_ATTRIBUTE_DESCRIPTION_2_EXT;
    attributeDescriptions[0].location = 10;
    attributeDescriptions[0].binding = 1;
    attributeDescriptions[0].format = VK_FORMAT_R32G32B32A32_SFLOAT;
    attributeDescriptions[0].offset = offsetof(Particle, position);

    attributeDescriptions[1].sType =
        VK_STRUCTURE_TYPE_VERTEX_INPUT_ATTRIBUTE_DESCRIPTION_2_EXT;
    attributeDescriptions[1].location = 11;
    attributeDescriptions[1].binding = 1;
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

const std::vector<VkValidationFeatureEnableEXT> validationFeatures = {
    // VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT,
};

const std::vector<const char *> deviceExtensions = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME, VK_EXT_SHADER_OBJECT_EXTENSION_NAME};

#ifdef NDEBUG
const bool enableValidationLayers = false;
#else
const bool enableValidationLayers = true;
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
  JrQueueFamilyIndices queueFamilyIndices;
  VkQueue graphicsQueue;
  VkQueue presentQueue;
  VkQueue transferQueue;
  VkQueue computeQueue;

  VkSwapchainKHR swapChain;
  std::vector<std::unique_ptr<JrImage>> swapChainImages;
  VkFormat swapChainImageFormat;
  VkExtent2D swapChainExtent;

  VkDescriptorSetLayout descriptorSetLayout;
  VkPipelineLayout pipelineLayout;
  VkPipeline graphicsPipeline;

  VkDescriptorSetLayout computeDescriptorSetLayout;
  VkPipelineLayout computePipelineLayout;
  VkPipeline computePipeline;

  VkCommandPool graphicsCommandPool;
  VkCommandPool transferCommandPool;
  VkCommandPool computeCommandPool;
  std::vector<VkCommandBuffer> computeCommandBuffers;
  std::vector<VkCommandBuffer> commandBuffers;
  std::vector<VkCommandBuffer> transitionCommandBuffers;
  VkCommandBuffer guiCommandBuffer;
  // secondary command buffers
  // ...

  std::vector<VkSemaphore> imageAvailableSemaphores;
  std::vector<VkSemaphore> computeFinishedSemaphores;
  std::vector<VkSemaphore> renderFinishedSemaphores;
  std::vector<VkSemaphore> presentReadySemaphores;
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
  std::unique_ptr<JrImage> textureImage;
  VkSampler textureSampler;

  std::unique_ptr<JrImage> depthImage;

  VkSampleCountFlagBits msaaSamples = VK_SAMPLE_COUNT_1_BIT;

  std::unique_ptr<JrImage> colorImage;
  // VkFormat colorFormat = VK_FORMAT_R16G16B16A16_SFLOAT;

  std::vector<VkBuffer> shaderStorageBuffers;
  std::vector<VkDeviceMemory> shaderStorageBuffersMemory;

  // JrObjects
  // HMODULE JrClasses_lib; dynamic loading of JrClasses library (old way)
  std::unique_ptr<JrAllocator> allocator;
  JrVulkanContext vulkanCtx;
  JrCamera *camera;
  JrGui *gui;

  std::unique_ptr<JrShader> particleVertShader;
  std::unique_ptr<JrShader> particleFragShader;

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
  JrQueueFamilyIndices getQueueFamilyIndices(VkPhysicalDevice physicalDevice_);
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
  void copyBufferToImage(const VkCommandBuffer &commandBuffer, VkBuffer buffer,
                         VkImage image, uint32_t width, uint32_t height);
  bool hasStencilComponent(VkFormat format);
  VkSampleCountFlagBits getMaxUsableSampleCount();
  VkShaderModule createShaderModule(const std::vector<char> &code);

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
  void createVulkanContextBeforeCreateSwapChain();
  void createAllocators();
  void createSwapChain();
  SwapChainSupportDetails
  querySwapChainSupport(VkPhysicalDevice physicalDevice_);
  VkSurfaceFormatKHR chooseSwapSurfaceFormat(
      const std::vector<VkSurfaceFormatKHR> &availableFormats);
  VkPresentModeKHR chooseSwapPresentMode(
      const std::vector<VkPresentModeKHR> &availablePresentModes);
  VkExtent2D chooseSwapExtent(const VkSurfaceCapabilitiesKHR &capabilities);
  void createDescriptorSetLayout();
  void createComputeDescriptorSetLayout();
  void createGraphicsPipeline();
  void createComputePipeline();
  void createShaderObjects();
  void createCommandPools();
  void createVulkanContext();
  void createColorResources();
  void createDepthResources();
  VkFormat findDepthFormat();
  VkFormat findSupportedFormat(const std::vector<VkFormat> &candidates,
                               VkImageTiling tiling,
                               VkFormatFeatureFlags features);
  void createTextureImage();
  void generateMipmaps(VkImage image, VkFormat imageFormat, int32_t texWidth,
                       int32_t texHeight, uint32_t mipLevels);
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

  void createTransitionCommandBuffers();

  void createSyncObjects();

  // initJrObjectsAfterInitVulkan
  void initJrObjectsAfterInitVulkan();
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