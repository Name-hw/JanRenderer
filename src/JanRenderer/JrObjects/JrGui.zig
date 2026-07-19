const std = @import("std");
const zmath = @import("zmath");
const zglfw = @import("zglfw");
const zgui = @import("zgui");
const common = @import("common.zig");
const c = common.c;
const JrVulkanContext = @import("JrVulkanContext.zig");

const GuiError = error{
    FailedToCreateDescriptorPool,
    FailedToCreateCommandPool,
    FailedToAllocateCommandBuffer,
    ImguiError,
};

pub const FontSet = struct {
    name: []const u8,
    light: zgui.Font,
    regular: zgui.Font,
    medium: zgui.Font,
    bold: zgui.Font,

    pub fn init(self: *FontSet) !void {
        var buffer: [128]u8 = undefined;

        self.light = zgui.io.addFontFromFile(try std.fmt.bufPrintSentinel(&buffer, "assets/fonts/{s}/{s}-Light.otf", .{ self.name, self.name }, 0), 16.0);
        self.regular = zgui.io.addFontFromFile(try std.fmt.bufPrintSentinel(&buffer, "assets/fonts/{s}/{s}-Regular.otf", .{ self.name, self.name }, 0), 16.0);
        self.medium = zgui.io.addFontFromFile(try std.fmt.bufPrintSentinel(&buffer, "assets/fonts/{s}/{s}-Medium.otf", .{ self.name, self.name }, 0), 16.0);
        self.bold = zgui.io.addFontFromFile(try std.fmt.bufPrintSentinel(&buffer, "assets/fonts/{s}/{s}-Bold.otf", .{ self.name, self.name }, 0), 16.0);
    }
};

// MVVM pattern
pub const JrGuiViewModel = extern struct {
    CameraPosition: *c.vec3s,
    CameraVelocity: *c.vec3s,
    CameraPitch: *f32,
    CameraYaw: *f32,
    CameraSpeed: *f32,
    CameraFieldOfView: *f32,
    CaemraIsRotatable: *bool,
};

const Self = @This();

vulkan_ctx: *JrVulkanContext,
swapchain_framebuffers: [3]c.VkFramebuffer,
render_pass: c.VkRenderPass,
//pipeline: c.VkPipeline,
//pipelineLayout: c.VkPipelineLayout,
command_pool: c.VkCommandPool,
command_buffers: [3]c.VkCommandBuffer,
render_finished_semaphores: [3]c.VkSemaphore,
descriptor_pool: c.VkDescriptorPool,
window: *zglfw.Window,
init_info: zgui.backend.ImGui_ImplVulkan_InitInfo,
font_set: *FontSet,
style: *zgui.Style,
viewModel: *JrGuiViewModel,
msaa_samples: c.VkSampleCountFlagBits,
current_frame: u32,

// Will use this in other code
//pub const MessageType = enum { Print, Warning, Error };

//pub fn debugCallback(messageType: MessageType, comptime message: anytype) void {
//    if (messageType == .Print) {
//        std.debug.panic("{}", message);
//    } else if (messageType == .Warning) {
//        std.debug.panic("\x1b[1;33m" ++ "[WARNING]" ++ "\x1b[1;0m" ++ " {}", .{message});
//    } else if (messageType == .Error) {
//        std.debug.panic("\x1b[1;31m" ++ "[ERROR]" ++ "\x1b[1;0m" ++ " {}", .{message});
//    }
//}

pub fn init(self: *Self, allocator: std.mem.Allocator) void {
    createGuiRenderPass(self);
    createFramebuffers(self);
    createDescriptorPool(self);
    createCommandPool(self);
    createCommandBuffers(self, c.VK_COMMAND_BUFFER_LEVEL_PRIMARY);
    createSyncObjects(self);

    self.init_info = zgui.backend.ImGui_ImplVulkan_InitInfo{
        .api_version = c.VK_API_VERSION_1_4,
        .instance = self.vulkan_ctx.instance.*,
        .physical_device = self.vulkan_ctx.physical_device.*,
        .device = self.vulkan_ctx.device.*,
        .queue_family = self.vulkan_ctx.queueFamilyIndices.graphics_family.?,
        .queue = self.vulkan_ctx.graphics_queue.*,

        .descriptor_pool = self.descriptor_pool,
        .render_pass = self.render_pass,
        .min_image_count = 3,
        .image_count = 3,
        .msaa_samples = self.msaa_samples,
        .use_dynamic_rendering = false,
        .check_vk_result_fn = checkVkResult,
        .min_allocation_size = 1024 * 1024,
    };

    zgui.init(allocator);

    var font_set = allocator.create(FontSet) catch {
        @panic("Failed to create font set!");
    };
    defer allocator.destroy(font_set);
    font_set.* = FontSet{
        .name = "Pretendard",
        .light = undefined,
        .regular = undefined,
        .medium = undefined,
        .bold = undefined,
    };
    font_set.init() catch @panic("Failed to initialize font set!");

    self.font_set = font_set;
    self.style = zgui.getStyle();

    zgui.backend.init(self.init_info, self.window);

    const configFlags = zgui.ConfigFlags{
        .dock_enable = true,
        .viewport_enable = false,
    };
    zgui.io.setConfigFlags(configFlags);
    zgui.io.setDefaultFont(self.font_set.regular);
}

pub fn checkVkResult(err: u32) callconv(.c) void {
    if (err != c.VK_SUCCESS) {
        std.debug.print("Vulkan error in ImGui: {}\n", .{err});
        @panic("Imgui error!");
    }
}

pub fn createGuiRenderPass(self: *Self) void {
    const color_attachment = c.VkAttachmentDescription{
        .format = self.vulkan_ctx.swapchain_format.*,
        .samples = self.msaa_samples,
        .loadOp = c.VK_ATTACHMENT_LOAD_OP_LOAD,
        .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .finalLayout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .flags = 0,
    };

    const color_attachment_ref = c.VkAttachmentReference{
        .attachment = 0,
        .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const subpass = c.VkSubpassDescription{
        .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &color_attachment_ref,
        .inputAttachmentCount = 0,
        .pInputAttachments = null,
        .pResolveAttachments = null,
        .pDepthStencilAttachment = null,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments = null,
        .flags = 0,
    };

    const dependency = c.VkSubpassDependency{
        .srcSubpass = c.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .srcAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };

    const renderPassInfo = c.VkRenderPassCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .attachmentCount = 1,
        .pAttachments = &color_attachment,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
    };

    if (c.vkCreateRenderPass.?(self.vulkan_ctx.device.*, &renderPassInfo, null, &self.render_pass) != c.VK_SUCCESS) {
        @panic("Failed to create gui render pass!");
    }
}

pub fn createFramebuffers(self: *Self) void {
    for (self.vulkan_ctx.swapchain_images.*, 0..) |swapchainImage, i| {
        const framebufferInfo = c.VkFramebufferCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = self.render_pass,
            .attachmentCount = 1,
            .pAttachments = &swapchainImage.image_view,
            .width = self.vulkan_ctx.swapchain_extent.*.width,
            .height = self.vulkan_ctx.swapchain_extent.*.height,
            .layers = 1,
        };

        if (c.vkCreateFramebuffer.?(self.vulkan_ctx.device.*, &framebufferInfo, null, &self.swapchain_framebuffers[i]) != c.VK_SUCCESS) {
            @panic("Failed to create framebuffer!");
        }
    }
}

pub fn createDescriptorPool(self: *Self) void {
    const poolSizes = [_]c.VkDescriptorPoolSize{
        .{ .type = c.VK_DESCRIPTOR_TYPE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, .descriptorCount = 1000 },
    };
    const poolInfo = c.VkDescriptorPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .flags = c.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
        .maxSets = 1000,
        .poolSizeCount = poolSizes.len,
        .pPoolSizes = &poolSizes,
    };

    if (c.vkCreateDescriptorPool.?(self.vulkan_ctx.device.*, &poolInfo, null, &self.descriptor_pool) != c.VK_SUCCESS) {
        @panic("Failed to create descriptor pool!");
    }
}

pub fn createCommandPool(self: *Self) void {
    const poolInfo = c.VkCommandPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .pNext = null,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = self.vulkan_ctx.queueFamilyIndices.graphics_family.?,
    };

    if (c.vkCreateCommandPool.?(self.vulkan_ctx.device.*, &poolInfo, null, &self.command_pool) != c.VK_SUCCESS) {
        @panic("Failed to create command pool!");
    }
}

pub fn createCommandBuffers(self: *Self, level: c.VkCommandBufferLevel) void {
    var allocInfo = c.VkCommandBufferAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .pNext = null,
        .commandPool = self.command_pool,
        .level = level,
        .commandBufferCount = 3,
    };

    if (c.vkAllocateCommandBuffers.?(self.vulkan_ctx.device.*, &allocInfo, &self.command_buffers) != c.VK_SUCCESS) {
        @panic("Failed to allocate command buffer!");
    }
}

pub fn createSyncObjects(self: *Self) void {
    var semaphoreInfo = c.VkSemaphoreCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    for (0..3) |i| {
        if (c.vkCreateSemaphore.?(self.vulkan_ctx.device.*, &semaphoreInfo, null, &self.render_finished_semaphores[i]) != c.VK_SUCCESS) {
            @panic("Failed to create synchronization objects for a frame!");
        }
    }
}

pub fn newFrame(self: *Self, width: u32, height: u32, current_frame: u32) void {
    self.current_frame = current_frame;
    zgui.backend.newFrame(width, height);

    if (zgui.begin("window", .{})) {
        zgui.bulletText("한글 테스트 {d}", .{1});

        zgui.spacing();

        //if (zgui.dragFloat("Drag 1", .{ .v = &self.args.items[0] })) {
        //    // value0 has changed
        //}

        if (zgui.collapsingHeader("Camera", .{ .default_open = true })) {
            _ = zgui.inputFloat3("Camera Position", .{ .v = &self.viewModel.CameraPosition.raw });
            _ = zgui.inputFloat3("Camera Velocity", .{ .v = &self.viewModel.CameraVelocity.raw });
            _ = zgui.inputFloat("Camera Pitch", .{ .v = self.viewModel.CameraPitch });
            _ = zgui.inputFloat("Camera Yaw", .{ .v = self.viewModel.CameraYaw });
            _ = zgui.sliderFloat("Camera Speed", .{ .v = self.viewModel.CameraSpeed, .min = 0.0, .max = 10.0 });
            _ = zgui.inputFloat("Camera FieldOfView", .{ .v = self.viewModel.CameraFieldOfView });
            _ = zgui.checkbox("Camera IsRotatable", .{ .v = self.viewModel.CaemraIsRotatable });
        }

        zgui.spacing();

        zgui.bulletText("FPS: {d:.1}", .{zgui.io.getFramerate()});
        zgui.bulletText("Frame Time: {d:.3}", .{1000 / zgui.io.getFramerate()});
        zgui.bulletText("Width: {d}", .{width});
        zgui.bulletText("Height: {d}", .{height});
    }
    zgui.end();

    zgui.showDemoWindow(null);
}

//pub fn setupDockSpace(self: *Self) void {
//    _ = self;
//    const dockNodeFlags = zgui.DockNodeFlags{};
//    const dockSpace = zgui.DockSpaceOverViewport(zgui.getMainViewport().getId(), zgui.getMainViewport(), dockNodeFlags);
//    _ = dockSpace;
//}

pub fn recreateSwapchain(self: *Self) void {
    destroyFramebuffers(self);
    createFramebuffers(self);
}

pub fn render(self: *Self, imageIndex: u32, p_wait_semaphores_slice: *[]c.VkSemaphore, fence: c.VkFence) void {
    _ = c.vkResetCommandBuffer.?(self.command_buffers[self.current_frame], 0);

    recordCommandBuffer(self, imageIndex);

    const waitStages = [_]c.VkPipelineStageFlags{
        c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
    };

    var submitInfo = c.VkSubmitInfo{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = @intCast(p_wait_semaphores_slice.len),
        .pWaitSemaphores = p_wait_semaphores_slice.ptr,
        .pWaitDstStageMask = &waitStages,
        .commandBufferCount = 1,
        .pCommandBuffers = &self.command_buffers[self.current_frame],
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &self.render_finished_semaphores[self.current_frame],
    };

    if (c.vkQueueSubmit.?(self.vulkan_ctx.graphics_queue.*, 1, &submitInfo, fence) != c.VK_SUCCESS) {
        @panic("Failed to submit gui command buffer!");
    }

    zgui.updatePlatformWindows();
    zgui.renderPlatformWindowsDefault();
}

pub fn recordCommandBuffer(self: *Self, image_index: u32) void {
    var beginInfo = c.VkCommandBufferBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = 0,
        .pInheritanceInfo = null,
    };
    if (c.vkBeginCommandBuffer.?(self.command_buffers[self.current_frame], &beginInfo) != c.VK_SUCCESS) {
        @panic("Failed to begin recording gui command buffer!");
    }

    var clearValues = [_]c.VkClearValue{
        .{ .color = .{ .uint32 = [4]u32{ 0, 0, 0, 0 } } },
    };

    const render_pass_info = c.VkRenderPassBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = self.render_pass,
        .framebuffer = self.swapchain_framebuffers[image_index],
        .renderArea = c.VkRect2D{
            .offset = c.VkOffset2D{ .x = 0, .y = 0 },
            .extent = self.vulkan_ctx.swapchain_extent.*,
        },
        .clearValueCount = 1,
        .pClearValues = &clearValues,
    };
    _ = c.vkCmdBeginRenderPass.?(self.command_buffers[self.current_frame], &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);

    zgui.backend.render(self.command_buffers[self.current_frame]);

    _ = c.vkCmdEndRenderPass.?(self.command_buffers[self.current_frame]);

    if (c.vkEndCommandBuffer.?(self.command_buffers[self.current_frame]) != c.VK_SUCCESS) {
        @panic("Failed to record gui command buffer!");
    }
}

pub fn deinit(self: *Self) void {
    zgui.backend.deinit();
    zgui.deinit();

    destroyFramebuffers(self);

    c.vkDestroyRenderPass.?(self.vulkan_ctx.device.*, self.render_pass, null);

    c.vkDestroyDescriptorPool.?(self.vulkan_ctx.device.*, self.descriptor_pool, null);
    c.vkDestroyCommandPool.?(self.vulkan_ctx.device.*, self.command_pool, null);

    for (self.render_finished_semaphores) |renderFinishedSemaphore| {
        c.vkDestroySemaphore.?(self.vulkan_ctx.device.*, renderFinishedSemaphore, null);
    }
}

pub fn destroyFramebuffers(self: *Self) void {
    for (self.swapchain_framebuffers) |framebuffer| {
        c.vkDestroyFramebuffer.?(self.vulkan_ctx.device.*, framebuffer, null);
    }
}
