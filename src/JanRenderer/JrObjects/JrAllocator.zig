const std = @import("std");
const common = @import("common.zig");
const c = common.c;
const JrVulkanContext = @import("JrVulkanContext.zig");

const Self = @This();

vulkan_ctx: *JrVulkanContext,
vma_allocator: *c.VmaAllocator,
debug_allocator: *@TypeOf(std.heap.DebugAllocator(.{}){}),

pub fn init(self: *Self) void {
    var allocatorCreateInfo = c.VmaAllocatorCreateInfo{
        .physicalDevice = self.vulkan_ctx.physical_device.*,
        .device = self.vulkan_ctx.device.*,
        .instance = self.vulkan_ctx.instance.*,
        .flags = c.VMA_ALLOCATOR_CREATE_BUFFER_DEVICE_ADDRESS_BIT,
    };

    var vulkanFunctions = c.VmaVulkanFunctions{};
    _ = c.vmaImportVulkanFunctionsFromVolk(&allocatorCreateInfo, &vulkanFunctions);

    allocatorCreateInfo.pVulkanFunctions = &vulkanFunctions;

    if (c.vmaCreateAllocator(&allocatorCreateInfo, self.vma_allocator) != c.VK_SUCCESS) {
        @panic("Failed to create VMA allocator!");
    }

    const debug_allocator = std.heap.c_allocator.create(@TypeOf(std.heap.DebugAllocator(.{}){})) catch {
        @panic("Failed to create debug allocator!");
    };
    debug_allocator.* = std.heap.DebugAllocator(.{}){};

    self.debug_allocator = debug_allocator;
}

pub fn getVmaAllocator(self: *Self) c.VmaAllocator {
    return self.vma_allocator.*;
}

pub fn getDebugAllocator(self: *Self) std.mem.Allocator {
    return self.debug_allocator.allocator();
}

pub fn deinit(self: *Self) void {
    c.vmaDestroyAllocator(self.getVmaAllocator());

    const deinit_status: std.heap.Check = self.debug_allocator.deinit();

    if (deinit_status == .leak) {
        @panic("Memory leak detected!");
    }
}
