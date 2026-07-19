const std = @import("std");
const zmath = @import("zmath");
const zglfw = @import("zglfw");
const common = @import("common.zig");
const c = common.c;

const JrAllocator = @import("JrAllocator.zig");
const JrQueueFamilyIndices = @import("JrQueueFamilyIndices.zig");
const JrImage = @import("JrImage.zig");
const JrCamera = @import("JrCamera.zig");
const JrShader = @import("JrShader.zig");
const JrGui = @import("JrGui.zig");

// JrAllocator
export fn jrAllocator_init(self: *JrAllocator) callconv(.c) void {
    JrAllocator.init(self);
}
export fn jrAllocator_deinit(self: *JrAllocator) callconv(.c) void {
    JrAllocator.deinit(self);
}

// JrQueueFamilyIndices
export fn jrQueueFamilyIndices_isComplete(self: *JrQueueFamilyIndices) callconv(.c) bool {
    return JrQueueFamilyIndices.isComplete(self);
}

// JrImage
export fn jrImage_init(self: *JrImage, allocator: *JrAllocator, tiling: c.VkImageTiling) callconv(.c) void {
    JrImage.init(self, allocator, tiling);
}
export fn jrImage_initFromSwapchain(self: *JrImage) callconv(.c) void {
    JrImage.init_from_swapchain(self);
}
export fn jrImage_transitionImageLayout(self: *JrImage, commandBuffer: c.VkCommandBuffer, newLayout: c.VkImageLayout) callconv(.c) void {
    JrImage.transitionImageLayout(self, commandBuffer, newLayout);
}
export fn jrImage_transitionImageLayoutWithQueueSubmit(self: *JrImage, commandBuffer: c.VkCommandBuffer, newLayout: c.VkImageLayout, pWaitSemaphoresSlice: *[]c.VkSemaphore, pWaitStages: *c.VkPipelineStageFlags, pSignalSemaphoresSlice: *[]c.VkSemaphore, fence: c.VkFence) callconv(.c) void {
    JrImage.transitionImageLayoutWithQueueSubmit(
        self,
        commandBuffer,
        newLayout,
        pWaitSemaphoresSlice,
        pWaitStages,
        pSignalSemaphoresSlice,
        fence,
    );
}
export fn jrImage_copyToImage(self: *JrImage, commandBuffer: c.VkCommandBuffer, destination: *JrImage) callconv(.c) void {
    JrImage.copyToImage(self, commandBuffer, destination);
}
export fn jrImage_deinit(self: *JrImage, allocator: *JrAllocator) callconv(.c) void {
    JrImage.deinit(self, allocator);
}

// JrCamera
export fn jrCamera_init(self: *JrCamera) callconv(.c) void {
    JrCamera.init(self);
}
export fn jrCamera_getRotationMatrix(self: *JrCamera) callconv(.c) c.mat4s {
    return JrCamera.getRotationMatrix(self);
}
export fn jrCamera_getViewMatrix(self: *JrCamera) callconv(.c) c.mat4s {
    return JrCamera.getViewMatrix(self);
}
export fn jrCamera_getProjectionMatrix(self: *JrCamera, aspectRatio: f32) callconv(.c) c.mat4s {
    return JrCamera.getProjectionMatrix(self, aspectRatio);
}
export fn jrCamera_keyCallback(window: *zglfw.Window, key: zglfw.Key, scancode: c_int, action: zglfw.Action, mods: zglfw.Mods) callconv(.c) void {
    JrCamera.keyCallback(window, key, scancode, action, mods);
}
export fn jrCamera_cursorPositionCallback(window: *zglfw.Window, xpos: f64, ypos: f64) callconv(.c) void {
    JrCamera.cursorPositionCallback(window, xpos, ypos);
}
export fn jrCamera_mouseButtonCallback(window: *zglfw.Window, button: zglfw.MouseButton, action: zglfw.Action, mods: zglfw.Mods) callconv(.c) void {
    JrCamera.mouseButtonCallback(window, button, action, mods);
}
export fn jrCamera_scrollCallback(window: *zglfw.Window, xoffset: f64, yoffset: f64) callconv(.c) void {
    JrCamera.scrollCallback(window, xoffset, yoffset);
}
export fn jrCamera_update(self: *JrCamera, deltaTime: f32) callconv(.c) void {
    JrCamera.update(self, deltaTime);
}

// JrShader
export fn jrShader_init(
    self: *JrShader,
    nextStage: c.VkShaderStageFlags,
    descriptorSetLayoutCount: u32,
    pDescriptorSetLayouts: *c.VkDescriptorSetLayout,
    pushConstantRangeCount: u32,
    pPushConstantRanges: *c.VkPushConstantRange,
) callconv(.c) void {
    JrShader.init(self, nextStage, descriptorSetLayoutCount, pDescriptorSetLayouts, pushConstantRangeCount, pPushConstantRanges);
}
export fn jrShader_buildLinkedShaders(vertShader: *JrShader, fragShader: *JrShader) callconv(.c) void {
    JrShader.buildLinkedShaders(vertShader, fragShader);
}
export fn jrShader_bindShader(self: *JrShader, commandBuffer: c.VkCommandBuffer) callconv(.c) void {
    JrShader.bindShader(self, commandBuffer);
}
export fn jrShader_destroy(self: *JrShader) callconv(.c) void {
    JrShader.destroy(self);
}

// JrGui
export fn jrGui_init(self: *JrGui, allocator: *JrAllocator) callconv(.c) void {
    JrGui.init(self, allocator.getDebugAllocator());
}
export fn jrGui_newFrame(self: *JrGui, width: u32, height: u32, currentFrame: u32) callconv(.c) void {
    JrGui.newFrame(self, width, height, currentFrame);
}
export fn jrGui_recreateSwapchain(self: *JrGui) callconv(.c) void {
    JrGui.recreateSwapchain(self);
}
export fn jrGui_render(self: *JrGui, imageIndex: u32, pWaitSemaphoresSlice: *[]c.VkSemaphore, fence: c.VkFence) callconv(.c) void {
    JrGui.render(self, imageIndex, pWaitSemaphoresSlice, fence);
}
export fn jrGui_deinit(self: *JrGui) callconv(.c) void {
    JrGui.deinit(self);
}
