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
}