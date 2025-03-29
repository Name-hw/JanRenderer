#version 450

// attributes
layout(location = 0) in vec3 vaPosition;
layout(location = 1) in vec3 vaColor;
layout(location = 2) in vec2 vaTexCoord;
//layout(location = 3) in vec3 vaNormal;

// vertexToFragment
layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;
layout(location = 3) out vec2 fragNormal;

// uniforms
layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(vaPosition, 1.0);
    fragColor = vaColor;
    fragTexCoord = vaTexCoord;

    //diff += vec3(0.01, 0.01, 0.01);
}