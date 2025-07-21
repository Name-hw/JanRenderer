#version 450

// attributes
layout(location = 10) in vec3 inPosition;
layout(location = 11) in vec3 inColor;

// vertexToFragment
layout(location = 0) out vec3 fragColor;

// uniforms
layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 1.0);
    gl_PointSize = 1.0;
    fragColor = inColor;
}