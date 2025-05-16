#pragma once

#include <common.hpp>

extern "C" {
struct JrCamera {
  vec3s position;
  vec3s velocity;

  float pitch;
  float yaw;

  float speed;
  float fov;
};
void init(JrCamera *);
mat4s getRotationMatrix();
mat4s getViewMatrix();
void update(JrCamera *);
void keyCallback(GLFWwindow *window, int key, int scancode, int action,
                 int mods);
void cursorPositionCallback(GLFWwindow *window, double xpos, double ypos);
void scrollCallback(GLFWwindow *window, double xoffset, double yoffset);

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
  std::vector<float> *args;
};
void jrGui_init(JrGui *);
void jrGui_newFrame(JrGui *, uint32_t width, uint32_t height,
                    uint32_t currentFrame);
// void jrGui_setupDockSpace(JrGui *);
void jrGui_render(JrGui *, uint32_t imageIndex, uint32_t waitSemaphoreCount,
                  VkSemaphore *pWaitSemaphores, VkFence fence);
void jrGui_destroy(JrGui *);
}