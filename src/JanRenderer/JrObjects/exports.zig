const zmath = @import("zmath");
const zglfw = @import("zglfw");
const common = @import("common.zig");
const c = common.c;

// JrQueueFamilyIndices
const JrQueueFamilyIndices = @import("JrQueueFamilyIndices.zig");

export fn jrQueueFamilyIndices_isComplete(self: *JrQueueFamilyIndices) callconv(.C) bool {
    return JrQueueFamilyIndices.isComplete(self);
}

// JrCamera
const JrCamera = @import("JrCamera.zig");

export fn jrCamera_init(self: *JrCamera) void {
    JrCamera.init(self);
}
export fn jrCamera_getRotationMatrix(self: *JrCamera) c.mat4s {
    return JrCamera.getRotationMatrix(self);
}
export fn jrCamera_getViewMatrix(self: *JrCamera) c.mat4s {
    return JrCamera.getViewMatrix(self);
}
export fn jrCamera_getProjectionMatrix(self: *JrCamera, aspectRatio: f32) c.mat4s {
    return JrCamera.getProjectionMatrix(self, aspectRatio);
}
export fn jrCamera_keyCallback(window: *zglfw.Window, key: zglfw.Key, scancode: c_int, action: zglfw.Action, mods: zglfw.Mods) void {
    JrCamera.keyCallback(window, key, scancode, action, mods);
}
export fn jrCamera_cursorPositionCallback(window: *zglfw.Window, xpos: f64, ypos: f64) void {
    JrCamera.cursorPositionCallback(window, xpos, ypos);
}
export fn jrCamera_mouseButtonCallback(window: *zglfw.Window, button: zglfw.MouseButton, action: zglfw.Action, mods: zglfw.Mods) void {
    JrCamera.mouseButtonCallback(window, button, action, mods);
}
export fn jrCamera_scrollCallback(window: *zglfw.Window, xoffset: f64, yoffset: f64) void {
    JrCamera.scrollCallback(window, xoffset, yoffset);
}
export fn jrCamera_update(self: *JrCamera, deltaTime: f32) void {
    JrCamera.update(self, deltaTime);
}

// JrGui
const JrGui = @import("JrGui.zig");

export fn jrGui_init(self: *JrGui) void {
    JrGui.init(self);
}
export fn jrGui_newFrame(self: *JrGui, width: u32, height: u32, currentFrame: u32) void {
    JrGui.newFrame(self, width, height, currentFrame);
}
export fn jrGui_recreateSwapchain(self: *JrGui, swapChainImageFormat: c.VkFormat, swapChainExtent: c.VkExtent2D, swapChainImageViews: *[3]c.VkImageView) void {
    JrGui.recreateSwapchain(self, swapChainImageFormat, swapChainExtent, swapChainImageViews);
}
export fn jrGui_render(self: *JrGui, imageIndex: u32, waitSemaphoreCount: u32, pWaitSemaphores: *c.VkSemaphore, fence: c.VkFence) void {
    JrGui.render(self, imageIndex, waitSemaphoreCount, pWaitSemaphores, fence);
}
export fn jrGui_destroy(self: *JrGui) void {
    JrGui.destroy(self);
}

// JrImage
const JrImage = @import("JrImage.zig");

export fn jrImage_init(self: *JrImage, tiling: c.VkImageTiling) void {
    JrImage.init(self, tiling);
}
export fn jrImage_destroy(self: *JrImage) void {
    JrImage.destroy(self);
}
