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
void jrCamera_init(JrCamera *);
mat4s jrCamera_getRotationMatrix(JrCamera *);
mat4s jrCamera_getViewMatrix(JrCamera *);
void jrCamera_update(JrCamera *);
void jrCamera_keyCallback(GLFWwindow *window, int key, int scancode, int action,
                          int mods);
void jrCamera_cursorPositionCallback(GLFWwindow *window, double xpos,
                                     double ypos);
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
}