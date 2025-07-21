#pragma once

#include <JanRenderer/common.hpp>

template <typename T> struct ZigSlice {
  T *ptr;
  size_t len;
};

extern "C" {
struct JrVulkanContext;

struct JrAllocator {
  JrVulkanContext *vulkanCtx;
  VmaAllocator *vmaAllocator;
  void *debugAllocator;
};
void jrAllocator_init(JrAllocator *);
void jrAllocator_deinit(JrAllocator *);

struct JrQueueFamilyIndices {
  uint32_t graphicsFamily;
  uint32_t presentFamily;
  uint32_t transferFamily;
  uint32_t computeFamily;
};
bool jrQueueFamilyIndices_isComplete(JrQueueFamilyIndices *);

struct JrImage {
  JrVulkanContext *vulkanCtx;
  VkImage image;
  VkImageView imageView;
  VmaAllocation vmaAllocation;
  VmaAllocationCreateInfo vmaAllocationCreateInfo;
  VkImageLayout imageLayout;
  VkFormat imageFormat;
  VkExtent3D imageExtent;
  uint32_t imageMipLevels;
  VkSampleCountFlagBits imageSampleCount;
  VkImageUsageFlags imageUsage;
  VkImageAspectFlags imageAspectMask;
};
void jrImage_init(JrImage *, JrAllocator *, VkImageTiling tiling);
void jrImage_initFromSwapchain(JrImage *);
void jrImage_transitionImageLayout(JrImage *, VkCommandBuffer commandBuffer,
                                   VkImageLayout newLayout);
void jrImage_transitionImageLayoutWithQueueSubmit(
    JrImage *, VkCommandBuffer commandBuffer, VkImageLayout newLayout,
    ZigSlice<VkSemaphore> *pWaitSemaphoresSlice,
    VkPipelineStageFlags *pWaitStages,
    ZigSlice<VkSemaphore> *pSignalSemaphoresSlice, VkFence fence);
void jrImage_copyToImage(JrImage *, VkCommandBuffer commandBuffer,
                         JrImage *destination);
void jrImage_deinit(JrImage *, JrAllocator *allocator);

struct JrVulkanContext {
  VkInstance *instance;

  VkPhysicalDevice *physicalDevice;
  VkDevice *device;

  JrQueueFamilyIndices *queueFamilyIndices;
  VkQueue *graphicsQueue;
  VkQueue *presentQueue;
  VkQueue *transferQueue;
  VkQueue *computeQueue;

  VkSwapchainKHR *swapchain;
  JrImage *(*swapchainImages)[3];
  VkFormat *swapchainFormat;
  VkExtent2D *swapchainExtent;

  VkCommandPool *graphicsCommandPool;
  VkCommandPool *transferCommandPool;
  VkCommandPool *computeCommandPool;
};

struct JrCamera {
  vec3s position;
  vec3s velocity;

  float pitch;
  float yaw;

  float speed;
  float fieldOfView;

  bool isRotatable;
};
void jrCamera_init(JrCamera *);
mat4s jrCamera_getRotationMatrix(JrCamera *);
mat4s jrCamera_getViewMatrix(JrCamera *);
mat4s jrCamera_getProjectionMatrix(JrCamera *, float aspectRatio);
void jrCamera_update(JrCamera *, float deltaTime);
void jrCamera_keyCallback(GLFWwindow *window, int key, int scancode, int action,
                          int mods);
void jrCamera_cursorPositionCallback(GLFWwindow *window, double xpos,
                                     double ypos);
void jrCamera_mouseButtonCallback(GLFWwindow *window, int button, int action,
                                  int mods);
void jrCamera_scrollCallback(GLFWwindow *window, double xoffset,
                             double yoffset);

struct JrShader {
  JrVulkanContext *vulkanCtx;
  VkShaderEXT shader;
  VkShaderCreateInfoEXT shaderCreateInfo;
  ZigSlice<uint32_t> spirv;
  VkShaderStageFlagBits shaderStage;
};
void jrShader_init(JrShader *, VkShaderStageFlags nextStage,
                   uint32_t descriptorSetLayoutCount,
                   VkDescriptorSetLayout *pDescriptorSetLayouts,
                   uint32_t pushConstantRangeCount,
                   VkPushConstantRange *pPushConstantRanges);
void jrShader_buildLinkedShaders(JrShader *vertShader, JrShader *fragShader);
void jrShader_bindShader(JrShader *, VkCommandBuffer commandBuffer);
void jrShader_destroy(JrShader *);

struct JrGuiViewModel {
  vec3s *CameraPosition;
  vec3s *CameraVelocity;
  float *CameraPitch;
  float *CameraYaw;
  float *CameraSpeed;
  float *CameraFieldOfView;
  bool *CameraIsRotatable;
};

struct JrGui {
  JrVulkanContext *vulkanCtx;
  VkFramebuffer swapChainFramebuffers[3];
  VkRenderPass renderPass;
  VkCommandPool commandPool;
  VkCommandBuffer commandBuffers[3];
  VkSemaphore renderFinishedSemaphores[3];
  VkDescriptorPool descriptorPool;
  GLFWwindow *window;
  ImGui_ImplVulkan_InitInfo initInfo;
  void *fontSet;
  ImGuiStyle *style;
  JrGuiViewModel *viewModel;
  VkSampleCountFlagBits msaaSamples;
  uint32_t currentFrame;
};
void jrGui_init(JrGui *, JrAllocator *);
void jrGui_newFrame(JrGui *, uint32_t width, uint32_t height,
                    uint32_t currentFrame);
// void jrGui_setupDockSpace(JrGui *);
void jrGui_recreateSwapchain(JrGui *);
void jrGui_render(JrGui *, uint32_t imageIndex, uint32_t waitSemaphoreCount,
                  VkSemaphore *pWaitSemaphores, VkFence fence);
void jrGui_deinit(JrGui *);
}