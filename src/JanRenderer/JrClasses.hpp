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
}