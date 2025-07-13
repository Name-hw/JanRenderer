const zmath = @import("zmath");
const zglfw = @import("zglfw");
const common = @import("common.zig");
const c = common.c;

const JrQueueFamilyIndices = @import("JrQueueFamilyIndices.zig");
const JrCamera = @import("JrCamera.zig");
const JrGui = @import("JrGui.zig");
const JrImage = @import("JrImage.zig");

// JrQueueFamilyIndices
export fn jrQueueFamilyIndices_isComplete(self: *JrQueueFamilyIndices) callconv(.C) bool {
    return JrQueueFamilyIndices.isComplete(self);
}

// JrCamera
export fn jrCamera_init(self: *JrCamera) callconv(.C) void {
    JrCamera.init(self);
}
export fn jrCamera_getRotationMatrix(self: *JrCamera) callconv(.C) c.mat4s {
    return JrCamera.getRotationMatrix(self);
}
export fn jrCamera_getViewMatrix(self: *JrCamera) callconv(.C) c.mat4s {
    return JrCamera.getViewMatrix(self);
}
export fn jrCamera_getProjectionMatrix(self: *JrCamera, aspectRatio: f32) callconv(.C) c.mat4s {
    return JrCamera.getProjectionMatrix(self, aspectRatio);
}
export fn jrCamera_keyCallback(window: *zglfw.Window, key: zglfw.Key, scancode: c_int, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    JrCamera.keyCallback(window, key, scancode, action, mods);
}
export fn jrCamera_cursorPositionCallback(window: *zglfw.Window, xpos: f64, ypos: f64) callconv(.C) void {
    JrCamera.cursorPositionCallback(window, xpos, ypos);
}
export fn jrCamera_mouseButtonCallback(window: *zglfw.Window, button: zglfw.MouseButton, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    JrCamera.mouseButtonCallback(window, button, action, mods);
}
export fn jrCamera_scrollCallback(window: *zglfw.Window, xoffset: f64, yoffset: f64) callconv(.C) void {
    JrCamera.scrollCallback(window, xoffset, yoffset);
}
export fn jrCamera_update(self: *JrCamera, deltaTime: f32) callconv(.C) void {
    JrCamera.update(self, deltaTime);
}

// JrGui
export fn jrGui_init(self: *JrGui) callconv(.C) void {
    JrGui.init(self);
}
export fn jrGui_newFrame(self: *JrGui, width: u32, height: u32, currentFrame: u32) callconv(.C) void {
    JrGui.newFrame(self, width, height, currentFrame);
}
export fn jrGui_recreateSwapchain(self: *JrGui) callconv(.C) void {
    JrGui.recreateSwapchain(self);
}
export fn jrGui_render(self: *JrGui, imageIndex: u32, waitSemaphoreCount: u32, pWaitSemaphores: *c.VkSemaphore, fence: c.VkFence) callconv(.C) void {
    JrGui.render(self, imageIndex, waitSemaphoreCount, pWaitSemaphores, fence);
}
export fn jrGui_destroy(self: *JrGui) callconv(.C) void {
    JrGui.destroy(self);
}

// JrImage
export fn jrImage_init(self: *JrImage, tiling: c.VkImageTiling) callconv(.C) void {
    JrImage.init(self, tiling);
}
export fn jrImage_initFromSwapchain(self: *JrImage) callconv(.C) void {
    JrImage.init_from_swapchain(self);
}
export fn jrImage_transitionImageLayout(self: *JrImage, commandBuffer: c.VkCommandBuffer, newLayout: c.VkImageLayout) callconv(.C) void {
    JrImage.transition_image_layout(self, commandBuffer, newLayout);
}
export fn jrImage_copyToImage(self: *JrImage, commandBuffer: c.VkCommandBuffer, destination: *JrImage) callconv(.C) void {
    JrImage.copy_to_image(self, commandBuffer, destination);
}
export fn jrImage_destroy(self: *JrImage) callconv(.C) void {
    JrImage.destroy(self);
}
