const std = @import("std");
const volk = @cImport({
    @cInclude("volk.h");
});
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});

pub const JrShader = extern struct {
    stage: volk.VkShaderStageFlagBits,
    nextStage: volk.VkShaderStageFlags,
    shaderEXT: volk.VkShaderEXT,
    shaderEXT_createInfo: volk.VkShaderCreateInfoEXT,
    shader_name: [*c]const u8,
    spirv: *[]u32,
};

// member functions
pub export fn jrShader_init(
    self_: *JrShader,
    stage_: volk.VkShaderStageFlagBits,
    nextStage_: volk.VkShaderStageFlags,
    shader_name_: [*c]const u8,
    spirv_: *[]u32,
    pSetLayouts: *const volk.VkDescriptorSetLayout,
    pPushConstantRange: *const volk.VkPushConstantRange,
) callconv(.C) void {
    var self = self_;

    self.stage = stage_;
    self.nextStage = nextStage_;
    self.shader_name = shader_name_;
    self.spirv = spirv_;

    // Fill out the shader create info struct
    self.shaderEXT_createInfo.sType = volk.VK_STRUCTURE_TYPE_SHADER_CREATE_INFO_EXT;
    self.shaderEXT_createInfo.pNext = null;
    self.shaderEXT_createInfo.flags = 0;
    self.shaderEXT_createInfo.stage = self.stage;
    self.shaderEXT_createInfo.nextStage = self.nextStage;
    self.shaderEXT_createInfo.codeType = volk.VK_SHADER_CODE_TYPE_SPIRV_EXT;
    self.shaderEXT_createInfo.codeSize = self.spirv.len * @sizeOf(u32);
    self.shaderEXT_createInfo.pCode = self.spirv.ptr;
    self.shaderEXT_createInfo.pName = "main";
    self.shaderEXT_createInfo.setLayoutCount = 1;
    self.shaderEXT_createInfo.pSetLayouts = pSetLayouts;
    self.shaderEXT_createInfo.pushConstantRangeCount = 1;
    self.shaderEXT_createInfo.pPushConstantRanges = pPushConstantRange;
    self.shaderEXT_createInfo.pSpecializationInfo = null;
}

pub export fn getName(self: *JrShader) callconv(.C) [*c]const u8 {
    return self.shader_name;
}

pub export fn getShaderEXT_createInfo(self: *JrShader) callconv(.C) volk.VkShaderCreateInfoEXT {
    return self.shaderEXT_createInfo;
}

pub export fn getShaderEXT(self: *JrShader) callconv(.C) *volk.VkShaderEXT {
    return &self.shaderEXT;
}

pub export fn getStage(self: *JrShader) callconv(.C) *volk.VkShaderStageFlagBits {
    return &self.stage;
}

pub export fn getNextStage(self: *JrShader) callconv(.C) *volk.VkShaderStageFlags {
    return &self.nextStage;
}

pub export fn setShaderEXT(self: *JrShader, shaderEXT_: volk.VkShaderEXT) callconv(.C) void {
    self.shaderEXT = shaderEXT_;
}

// other functions
pub export fn createLinkedShaders(device: volk.VkDevice, vertShader: *JrShader, fragShader: *JrShader) callconv(.C) void {
    var shaderEXT_createInfos = [2]volk.VkShaderCreateInfoEXT{
        getShaderEXT_createInfo(vertShader),
        getShaderEXT_createInfo(fragShader),
    };
    for (&shaderEXT_createInfos) |*shaderEXT_createInfo| {
        shaderEXT_createInfo.flags |= volk.VK_SHADER_CREATE_LINK_STAGE_BIT_EXT;
    }

    var shaderEXTs: [2]volk.VkShaderEXT = undefined;

    const result: volk.VkResult = volk.vkCreateShadersEXT.?(device, 2, &shaderEXT_createInfos, null, &shaderEXTs);
    if (result != volk.VK_SUCCESS) {
        @panic("failed to create linked shaders");
    }

    setShaderEXT(vertShader, shaderEXTs[0]);
    setShaderEXT(fragShader, shaderEXTs[1]);
}

pub export fn bindShader(cmd_buffer: volk.VkCommandBuffer, shader: *JrShader) callconv(.C) void {
    volk.vkCmdBindShadersEXT.?(cmd_buffer, 1, getStage(shader), getShaderEXT(shader));
}
