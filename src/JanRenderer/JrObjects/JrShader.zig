const std = @import("std");
const common = @import("common.zig");
const c = common.c;
const JrVulkanContext = @import("JrVulkanContext.zig");

const Self = @This();

vulkan_ctx: *JrVulkanContext,
shader: c.VkShaderEXT,
shader_create_info: c.VkShaderCreateInfoEXT,
spirv: []u32,
shader_stage: c.VkShaderStageFlagBits,

pub fn init(
    self: *Self,
    next_stage: c.VkShaderStageFlags,
    descriptor_set_layout_count: u32,
    p_descriptor_set_layouts: *c.VkDescriptorSetLayout,
    push_constant_range_count: u32,
    p_push_constant_ranges: *c.VkPushConstantRange,
) void {
    //self.spirv = glsl_source;

    // Fill out the shader create info struct
    self.shader_create_info = c.VkShaderCreateInfoEXT{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_CREATE_INFO_EXT,
        .pNext = null,
        .flags = 0,
        .stage = self.shader_stage,
        .nextStage = next_stage,
        .codeType = c.VK_SHADER_CODE_TYPE_SPIRV_EXT,
        .codeSize = self.spirv.len * @sizeOf(u32),
        .pCode = self.spirv.ptr,
        .pName = "main",
        .setLayoutCount = descriptor_set_layout_count,
        .pSetLayouts = p_descriptor_set_layouts,
        .pushConstantRangeCount = push_constant_range_count,
        .pPushConstantRanges = p_push_constant_ranges,
        .pSpecializationInfo = null,
    };
}

pub fn buildLinkedShaders(vert_shader: *Self, frag_shader: *Self) void {
    var shader_create_infos = [2]c.VkShaderCreateInfoEXT{
        vert_shader.shader_create_info,
        frag_shader.shader_create_info,
    };

    for (&shader_create_infos) |*shader_createInfo| {
        shader_createInfo.flags |= c.VK_SHADER_CREATE_LINK_STAGE_BIT_EXT;
    }

    var shaders: [2]c.VkShaderEXT = undefined;

    if (c.vkCreateShadersEXT.?(vert_shader.vulkan_ctx.device.*, 2, &shader_create_infos, null, &shaders) != c.VK_SUCCESS) {
        @panic("Failed to create linked shaders!");
    }

    setShader(vert_shader, shaders[0]);
    setShader(frag_shader, shaders[1]);
}

pub fn bindShader(self: *Self, command_buffer: c.VkCommandBuffer) void {
    c.vkCmdBindShadersEXT.?(command_buffer, 1, getStage(self), getShader(self));
}

pub fn getShader(self: *Self) *c.VkShaderEXT {
    return &self.shader;
}

pub fn getStage(self: *Self) *c.VkShaderStageFlagBits {
    return &self.shader_stage;
}

pub fn getNextStage(self: *Self) *c.VkShaderStageFlags {
    return &self.shader_next_stage;
}

pub fn setShader(self: *Self, shader_: c.VkShaderEXT) void {
    self.shader = shader_;
}

pub fn destroy(self: *Self) void {
    c.vkDestroyShaderEXT.?(self.vulkan_ctx.device.*, self.shader, null);
}
