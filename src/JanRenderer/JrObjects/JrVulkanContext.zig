const std = @import("std");
const volk = @cImport({
    @cInclude("volk.h");
});
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});
const JrQueueFamilyIndices = @import("JrQueueFamilyIndices.zig");

const Self = @This();

instance: *volk.VkInstance,

physicalDevice: *volk.VkPhysicalDevice,
device: *volk.VkDevice,

queueFamilyIndices: *JrQueueFamilyIndices,
graphics_queue: *volk.VkQueue,
present_queue: *volk.VkQueue,
transfer_queue: *volk.VkQueue,
compute_queue: *volk.VkQueue,

swapchain: *volk.VkSwapchainKHR,
swapchain_images: *[3]volk.VkImage,
swapchain_format: *volk.VkFormat,
swapchain_extent: *volk.VkExtent2D,
swapchain_imageViews: *[3]volk.VkImageView,

renderPass: *volk.VkRenderPass,
