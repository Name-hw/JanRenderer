const std = @import("std");
const zmath = @import("zmath");
const common = @import("common.zig");
const c = common.c;
const JrVulkanContext = @import("JrVulkanContext.zig");

const Self = @This();

vulkan_ctx: *JrVulkanContext,
image: c.VkImage,
image_view: c.VkImageView,
vma_allocation: c.VmaAllocation,
vma_allocation_create_info: c.VmaAllocationCreateInfo,
image_format: c.VkFormat,
image_extent: c.VkExtent3D,
image_mip_levels: u32,
image_sample_count: c.VkSampleCountFlagBits,
image_usage: c.VkImageUsageFlags,
image_aspect_mask: c.VkImageAspectFlags,

pub fn createImage(self: *Self, tiling: c.VkImageTiling) void {
    const create_info = c.VkImageCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .imageType = c.VK_IMAGE_TYPE_2D,
        .format = self.image_format,
        .extent = self.image_extent,
        .mipLevels = self.image_mip_levels,
        .arrayLayers = 1,
        .samples = self.image_sample_count,
        .tiling = tiling,
        .usage = self.image_usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 1,
        .pQueueFamilyIndices = &self.vulkan_ctx.queueFamilyIndices.graphics_family.?,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
    };

    if (c.vmaCreateImage(self.vulkan_ctx.vma_allocator.*, &create_info, &self.vma_allocation_create_info, &self.image, &self.vma_allocation, null) !=
        c.VK_SUCCESS)
    {
        @panic("Failed to create image!");
    }
}

pub fn createImageView(self: *Self) void {
    const create_info = c.VkImageViewCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .pNext = null,
        //.flags = 0,
        .image = self.image,
        .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
        .format = self.image_format,
        //.components = c.VkComponentMapping{
        //    .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        //    .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        //    .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        //    .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        //},
        .subresourceRange = c.VkImageSubresourceRange{
            .aspectMask = self.image_aspect_mask,
            .baseMipLevel = 0,
            .levelCount = self.image_mip_levels,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    };

    if (c.vkCreateImageView.?(self.vulkan_ctx.device.*, &create_info, null, &self.image_view) !=
        c.VK_SUCCESS)
    {
        @panic("Failed to create image view!");
    }
}

pub fn init(self: *Self, tiling: c.VkImageTiling) void {
    self.createImage(tiling);
    self.createImageView();
}

pub fn destroy(self: *Self) void {
    c.vkDestroyImageView.?(self.vulkan_ctx.device.*, self.image_view, null);
    c.vmaDestroyImage(self.vulkan_ctx.vma_allocator.*, self.image, self.vma_allocation);
}
