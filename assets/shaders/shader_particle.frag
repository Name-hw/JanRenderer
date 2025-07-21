#version 450

// vertexToFragment
layout(location = 0) in vec3 fragColor;

// outs
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(fragColor, 1.0);
}