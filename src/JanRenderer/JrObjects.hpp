#pragma once

#include <common.hpp>

extern "C" {
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
  VkShaderStageFlagBits stage;
  VkShaderStageFlags nextStage;
  VkShaderEXT shaderEXT;
  VkShaderCreateInfoEXT shaderEXT_createInfo;
  char *shader_name;
  uint32_t *spirv;
};
void createLinkedShaders(VkDevice device, JrShader *vertShader,
                         JrShader *fragShader);

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
  VkDevice device;
  uint32_t queueFamilyIndex;
  VkQueue queue;
  VkFormat swapChainImageFormat;
  VkExtent2D swapChainExtent;
  VkImageView *swapChainImageViews;
  VkFramebuffer swapChainFramebuffers[3];
  VkRenderPass renderPass;
  VkCommandPool commandPool;
  VkCommandBuffer commandBuffers[3];
  VkSemaphore renderFinishedSemaphores[3];
  VkDescriptorPool descriptorPool;
  uint32_t currentFrame;
  VkSampleCountFlagBits msaaSamples;
  GLFWwindow *window;
  ImGui_ImplVulkan_InitInfo initInfo;
  void *fontSet;
  ImGuiStyle *style;
  JrGuiViewModel *viewModel;
};
void jrGui_init(JrGui *);
void jrGui_newFrame(JrGui *, uint32_t width, uint32_t height,
                    uint32_t currentFrame);
// void jrGui_setupDockSpace(JrGui *);
void jrGui_recreateSwapChain(JrGui *, VkFormat swapChainImageFormat_,
                             VkExtent2D swapChainExtent_,
                             VkImageView *swapChainImageViews_);
void jrGui_render(JrGui *, uint32_t imageIndex, uint32_t waitSemaphoreCount,
                  VkSemaphore *pWaitSemaphores, VkFence fence);
void jrGui_destroy(JrGui *);
}