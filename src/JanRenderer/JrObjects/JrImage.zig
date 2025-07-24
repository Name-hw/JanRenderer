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
image_layout: c.VkImageLayout,
image_format: c.VkFormat,
image_extent: c.VkExtent3D,
image_mip_levels: u32,
image_sample_count: c.VkSampleCountFlagBits,
image_usage: c.VkImageUsageFlags,
image_aspect_mask: c.VkImageAspectFlags,

pub fn init(self: *Self, tiling: c.VkImageTiling) void {
    self.createImage(tiling);
    self.createImageView();
}

pub fn init_from_swapchain(self: *Self) void {
    self.createImageView();
}

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

pub fn transition_image_layout(self: *Self, command_buffer: c.VkCommandBuffer, new_layout: c.VkImageLayout) void {
    const old_layout = self.image_layout;
    var barrier = c.VkImageMemoryBarrier{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .pNext = null,
        .srcAccessMask = 0,
        .dstAccessMask = 0,
        .oldLayout = old_layout,
        .newLayout = new_layout,
        .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .image = self.image,
        .subresourceRange = c.VkImageSubresourceRange{
            .aspectMask = self.image_aspect_mask,
            .baseMipLevel = 0,
            .levelCount = self.image_mip_levels,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    };

    var sourceStage: c.VkPipelineStageFlags = 0;
    var destinationStage: c.VkPipelineStageFlags = 0;

    if (old_layout == c.VK_IMAGE_LAYOUT_UNDEFINED and // VK_IMAGE_LAYOUT_UNDEFINED -> VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
        new_layout == c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    {
        barrier.srcAccessMask = 0;
        barrier.dstAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT;

        sourceStage = c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        destinationStage = c.VK_PIPELINE_STAGE_TRANSFER_BIT;
    } else if (old_layout == c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL and // VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL -> VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
        new_layout == c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
    {
        barrier.srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT;
        barrier.dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT;

        sourceStage = c.VK_PIPELINE_STAGE_TRANSFER_BIT;
        destinationStage = c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
    } else if (old_layout == c.VK_IMAGE_LAYOUT_UNDEFINED and // VK_IMAGE_LAYOUT_UNDEFINED -> VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        new_layout == c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    {
        barrier.srcAccessMask = 0;
        barrier.dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;

        sourceStage = c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        destinationStage = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    } else if (old_layout == c.VK_IMAGE_LAYOUT_UNDEFINED and // VK_IMAGE_LAYOUT_UNDEFINED -> VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
        new_layout == c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
    {
        barrier.srcAccessMask = 0;
        barrier.dstAccessMask = c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT |
            c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;

        sourceStage = c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        destinationStage = c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
    } else if (old_layout == c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL and // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL -> VK_IMAGE_LAYOUT_UNDEFINED
        new_layout == c.VK_IMAGE_LAYOUT_UNDEFINED)
    {
        barrier.srcAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
        barrier.dstAccessMask = 0;

        sourceStage = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        destinationStage = c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
    } else if (old_layout == c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL and // VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL -> VK_IMAGE_LAYOUT_UNDEFINED
        new_layout == c.VK_IMAGE_LAYOUT_UNDEFINED)
    {
        barrier.srcAccessMask = c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT |
            c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
        barrier.dstAccessMask = 0;

        sourceStage = c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
        destinationStage = c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
    } else {
        @panic("Unsupported layout transition!");
    }

    c.vkCmdPipelineBarrier.?(command_buffer, sourceStage, destinationStage, 0, 0, null, 0, null, 1, &barrier);

    self.image_layout = new_layout;
}

pub fn copy_to_image(self: *Self, command_buffer: c.VkCommandBuffer, destination: *Self) void {
    const blit_region = c.VkImageBlit2{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_BLIT_2,
        .srcSubresource = c.VkImageSubresourceLayers{
            .aspectMask = self.image_aspect_mask,
            .mipLevel = self.image_mip_levels,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .srcOffsets = [2]c.VkOffset3D{
            .{ .x = 0, .y = 0, .z = 0 },
            .{ .x = @intCast(self.image_extent.width), .y = @intCast(self.image_extent.height), .z = @intCast(self.image_extent.depth) },
        },
        .dstSubresource = c.VkImageSubresourceLayers{
            .aspectMask = destination.image_aspect_mask,
            .mipLevel = destination.image_mip_levels,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .dstOffsets = [2]c.VkOffset3D{
            .{ .x = 0, .y = 0, .z = 0 },
            .{ .x = @intCast(destination.image_extent.width), .y = @intCast(destination.image_extent.height), .z = @intCast(destination.image_extent.depth) },
        },
    };

    const blit_info = c.VkBlitImageInfo2{
        .sType = c.VK_STRUCTURE_TYPE_BLIT_IMAGE_INFO_2,
        .srcImage = self.image,
        .srcImageLayout = c.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
        .dstImage = destination.image,
        .dstImageLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .regionCount = 1,
        .pRegions = &blit_region,
        .filter = c.VK_FILTER_LINEAR, // or VK_FILTER_NEAREST
    };

    c.vkCmdBlitImage2.?(command_buffer, &blit_info);
}

pub fn destroy(self: *Self) void {
    c.vkDestroyImageView.?(self.vulkan_ctx.device.*, self.image_view, null);
    c.vmaDestroyImage(self.vulkan_ctx.vma_allocator.*, self.image, self.vma_allocation);
    //c.vkDestroyImage.?(self.vulkan_ctx.device.*, self.image, null);
}
