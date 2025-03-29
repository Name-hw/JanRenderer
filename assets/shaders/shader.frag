#version 450

// vertexToFragment
layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragTexCoord;

// outs
layout(location = 0) out vec4 outColor;

// uniforms
layout(binding = 1) uniform sampler2D texSampler;

void main() {
    outColor = vec4(fragColor * texture(texSampler, fragTexCoord).rgb, 1.0);
}