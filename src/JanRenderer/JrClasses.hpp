#pragma once

// cglm
#define CGLM_FORCE_DEPTH_ZERO_TO_ONE
#include <cglm/struct.h>

extern "C" {
typedef struct JrCamera {
  vec3s position;
  vec3s velocity;

  float pitch;
  float yaw;
} JrCamera;
/*
typedef JrCamera *(*JrCamera_new)();
typedef mat4s (*JrCamera_getRotationMatrix)(JrCamera *);
typedef mat4s (*JrCamera_getViewMatrix)(JrCamera *);
typedef void (*JrCamera_update)(JrCamera *);
*/

JrCamera *jrCamera_new();
mat4s jrCamera_getRotationMatrix(JrCamera *self);
mat4s jrCamera_getViewMatrix(JrCamera *self);
void jrCamera_update(JrCamera *self);
}