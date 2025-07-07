const std = @import("std");
const common = @import("common.zig");
const c = common.c;
const JrQueueFamilyIndices = @import("JrQueueFamilyIndices.zig");

const Self = @This();

instance: *c.VkInstance,

physicalDevice: *c.VkPhysicalDevice,
device: *c.VkDevice,

queueFamilyIndices: *JrQueueFamilyIndices,
graphics_queue: *c.VkQueue,
present_queue: *c.VkQueue,
transfer_queue: *c.VkQueue,
compute_queue: *c.VkQueue,

swapchain: *c.VkSwapchainKHR,
swapchain_images: *[3]c.VkImage,
swapchain_format: *c.VkFormat,
swapchain_extent: *c.VkExtent2D,
swapchain_imageViews: *[3]c.VkImageView,

renderPass: *c.VkRenderPass,

vma_allocator: *c.VmaAllocator,
