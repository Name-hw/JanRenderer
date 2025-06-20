const std = @import("std");
const volk = @cImport({
    @cInclude("volk.h");
});
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});
const zmath = @import("zmath");
const zglfw = @import("zglfw");
const zgui = @import("zgui");
const allocator = std.heap.c_allocator;

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

    //pub fn init(self: *FontSet) !void {
    //    self.light = zgui.io.addFontFromFileWithConfig(try std.fmt.allocPrintZ(allocator, "assets/fonts/{s}/{s}-Light.otf", .{ self.name, self.name }), 16.0, null, zgui.io.getGlyphRangesKorean());
    //    self.regular = zgui.io.addFontFromFileWithConfig(try std.fmt.allocPrintZ(allocator, "assets/fonts/{s}/{s}-Regular.otf", .{ self.name, self.name }), 16.0, null, zgui.io.getGlyphRangesKorean());
    //    self.medium = zgui.io.addFontFromFileWithConfig(try std.fmt.allocPrintZ(allocator, "assets/fonts/{s}/{s}-Medium.otf", .{ self.name, self.name }), 16.0, null, zgui.io.getGlyphRangesKorean());
    //    self.bold = zgui.io.addFontFromFileWithConfig(try std.fmt.allocPrintZ(allocator, "assets/fonts/{s}/{s}-Bold.otf", .{ self.name, self.name }), 16.0, null, zgui.io.getGlyphRangesKorean());
    //}
};

// MVVM pattern
pub const JrGuiViewModel = extern struct {
    CameraPosition: *cglm.vec3s,
    CameraVelocity: *cglm.vec3s,
    CameraPitch: *f32,
    CameraYaw: *f32,
    CameraSpeed: *f32,
    CameraFieldOfView: *f32,
    CaemraIsRotatable: *bool,
};

pub const JrGui = extern struct {
    device: volk.VkDevice,
    queueFamilyIndex: u32,
    queue: volk.VkQueue,
    swapChainImageFormat: volk.VkFormat,
    swapChainExtent: volk.VkExtent2D,
    swapChainImageViews: *[3]volk.VkImageView,
    swapChainFramebuffers: [3]volk.VkFramebuffer,
    renderPass: volk.VkRenderPass,
    //pipeline: volk.VkPipeline,
    //pipelineLayout: volk.VkPipelineLayout,
    commandPool: volk.VkCommandPool,
    commandBuffers: [3]volk.VkCommandBuffer,
    renderFinishedSemaphores: [3]volk.VkSemaphore,
    descriptorPool: volk.VkDescriptorPool,
    currentFrame: u32,
    msaaSamples: volk.VkSampleCountFlagBits,
    window: *zglfw.Window,
    initInfo: zgui.backend.ImGui_ImplVulkan_InitInfo,
    fontSet: *FontSet,
    style: *zgui.Style,
    viewModel: *JrGuiViewModel,
};

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

pub export fn jrGui_init(self: *JrGui) callconv(.C) void {
    createGuiRenderPass(self);
    createFramebuffers(self);
    createDescriptorPool(self);
    createCommandPool(self);
    allocateCommandBuffer(self, volk.VK_COMMAND_BUFFER_LEVEL_PRIMARY);
    createSyncObjects(self);

    self.initInfo.device = self.device;
    self.initInfo.queue_family = self.queueFamilyIndex;
    self.initInfo.queue = self.queue;
    self.initInfo.descriptor_pool = self.descriptorPool;
    self.initInfo.render_pass = self.renderPass;
    self.initInfo.msaa_samples = self.msaaSamples;
    self.initInfo.check_vk_result_fn = checkVkResult;

    zgui.init(allocator);

    var fontSet = FontSet{
        .name = "Pretendard",
        .light = undefined,
        .regular = undefined,
        .medium = undefined,
        .bold = undefined,
    };
    //fontSet.init() catch {};
    self.fontSet = &fontSet;
    self.style = zgui.getStyle();

    zgui.backend.init(self.initInfo, self.window);

    const configFlags = zgui.ConfigFlags{
        .dock_enable = true,
        .viewport_enable = true,
    };
    zgui.io.setConfigFlags(configFlags);
    //zgui.io.setDefaultFont(self.fontSet.regular);
}

pub export fn checkVkResult(err: u32) callconv(.C) void {
    if (err != volk.VK_SUCCESS) @panic("Imgui error!");
}

pub fn createDescriptorPool(self: *JrGui) void {
    const poolSizes = [_]volk.VkDescriptorPoolSize{
        .{ .type = volk.VK_DESCRIPTOR_TYPE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = volk.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, .descriptorCount = 1000 },
    };
    const poolInfo = volk.VkDescriptorPoolCreateInfo{
        .sType = volk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .flags = volk.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
        .maxSets = 1000,
        .poolSizeCount = poolSizes.len,
        .pPoolSizes = &poolSizes,
    };

    if (volk.vkCreateDescriptorPool.?(self.device, &poolInfo, null, &self.descriptorPool) != volk.VK_SUCCESS) {
        @panic("Failed to create descriptor pool!");
    }
}

pub fn createGuiRenderPass(self: *JrGui) void {
    const colorAttachment = volk.VkAttachmentDescription{
        .format = self.swapChainImageFormat,
        .samples = self.msaaSamples,
        .loadOp = volk.VK_ATTACHMENT_LOAD_OP_LOAD,
        .storeOp = volk.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = volk.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = volk.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = volk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .finalLayout = volk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        .flags = 0,
    };

    const colorAttachmentRef = volk.VkAttachmentReference{
        .attachment = 0,
        .layout = volk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const subpass = volk.VkSubpassDescription{
        .pipelineBindPoint = volk.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &colorAttachmentRef,
        .inputAttachmentCount = 0,
        .pInputAttachments = null,
        .pResolveAttachments = null,
        .pDepthStencilAttachment = null,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments = null,
        .flags = 0,
    };

    const dependency = volk.VkSubpassDependency{
        .srcSubpass = volk.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = volk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .dstStageMask = volk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .srcAccessMask = 0,
        .dstAccessMask = volk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };

    const renderPassInfo = volk.VkRenderPassCreateInfo{
        .sType = volk.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .attachmentCount = 1,
        .pAttachments = &colorAttachment,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
    };

    if (volk.vkCreateRenderPass.?(self.device, &renderPassInfo, null, &self.renderPass) != volk.VK_SUCCESS) {
        @panic("Failed to create gui render pass!");
    }
}

pub fn createFramebuffers(self: *JrGui) void {
    for (self.swapChainImageViews, 0..) |swapChainImageView, i| {
        const framebufferInfo = volk.VkFramebufferCreateInfo{
            .sType = volk.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = self.renderPass,
            .attachmentCount = 1,
            .pAttachments = &swapChainImageView,
            .width = self.swapChainExtent.width,
            .height = self.swapChainExtent.height,
            .layers = 1,
        };

        if (volk.vkCreateFramebuffer.?(self.device, &framebufferInfo, null, &self.swapChainFramebuffers[i]) != volk.VK_SUCCESS) {
            @panic("Failed to create framebuffer!");
        }
    }
}

pub fn createCommandPool(self: *JrGui) void {
    const poolInfo = volk.VkCommandPoolCreateInfo{
        .sType = volk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .pNext = null,
        .flags = volk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = self.queueFamilyIndex,
    };

    if (volk.vkCreateCommandPool.?(self.device, &poolInfo, null, &self.commandPool) != volk.VK_SUCCESS) {
        @panic("Failed to create command pool!");
    }
}

pub fn allocateCommandBuffer(self: *JrGui, level: volk.VkCommandBufferLevel) void {
    var allocInfo = volk.VkCommandBufferAllocateInfo{
        .sType = volk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .pNext = null,
        .commandPool = self.commandPool,
        .level = level,
        .commandBufferCount = 3,
    };

    if (volk.vkAllocateCommandBuffers.?(self.device, &allocInfo, &self.commandBuffers) != volk.VK_SUCCESS) {
        @panic("Failed to allocate command buffer!");
    }
}

pub fn createSyncObjects(self: *JrGui) void {
    var semaphoreInfo = volk.VkSemaphoreCreateInfo{
        .sType = volk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    for (0..3) |i| {
        if (volk.vkCreateSemaphore.?(self.device, &semaphoreInfo, null, &self.renderFinishedSemaphores[i]) != volk.VK_SUCCESS) {
            @panic("Failed to create synchronization objects for a frame!");
        }
    }
}

pub export fn jrGui_newFrame(self: *JrGui, width: u32, height: u32, currentFrame: u32) callconv(.C) void {
    self.currentFrame = currentFrame;
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

//pub export fn jrGui_setupDockSpace(self: *JrGui) callconv(.C) void {
//    _ = self;
//    const dockNodeFlags = zgui.DockNodeFlags{};
//    const dockSpace = zgui.DockSpaceOverViewport(zgui.getMainViewport().getId(), zgui.getMainViewport(), dockNodeFlags);
//    _ = dockSpace;
//}

pub export fn jrGui_recreateSwapChain(self: *JrGui, swapChainImageFormat_: volk.VkFormat, swapChainExtent_: volk.VkExtent2D, swapChainImageViews_: *[3]volk.VkImageView) callconv(.C) void {
    self.swapChainImageFormat = swapChainImageFormat_;
    self.swapChainExtent = swapChainExtent_;
    self.swapChainImageViews = swapChainImageViews_;

    destroyFramebuffers(self);
    createFramebuffers(self);
}

pub export fn jrGui_render(self: *JrGui, imageIndex: u32, waitSemaphoreCount: u32, pWaitSemaphores: *volk.VkSemaphore, fence: volk.VkFence) callconv(.C) void {
    _ = volk.vkResetCommandBuffer.?(self.commandBuffers[self.currentFrame], 0);

    recordCommandBuffer(self, imageIndex);

    const waitStages = [_]volk.VkPipelineStageFlags{
        volk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
    };

    var submitInfo = volk.VkSubmitInfo{
        .sType = volk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = waitSemaphoreCount,
        .pWaitSemaphores = pWaitSemaphores,
        .pWaitDstStageMask = &waitStages,
        .commandBufferCount = 1,
        .pCommandBuffers = &self.commandBuffers[self.currentFrame],
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &self.renderFinishedSemaphores[self.currentFrame],
    };

    if (volk.vkQueueSubmit.?(self.queue, 1, &submitInfo, fence) != volk.VK_SUCCESS) {
        @panic("Failed to submit gui command buffer!");
    }

    _ = volk.vkQueueWaitIdle.?(self.queue);

    zgui.updatePlatformWindows();
    zgui.renderPlatformWindowsDefault();
}

pub fn recordCommandBuffer(self: *JrGui, imageIndex: u32) void {
    var beginInfo = volk.VkCommandBufferBeginInfo{
        .sType = volk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = 0,
        .pInheritanceInfo = null,
    };
    if (volk.vkBeginCommandBuffer.?(self.commandBuffers[self.currentFrame], &beginInfo) != volk.VK_SUCCESS) {
        @panic("Failed to begin recording gui command buffer!");
    }

    var clearValues = [_]volk.VkClearValue{
        .{ .color = .{ .uint32 = [4]u32{ 0, 0, 0, 0 } } },
    };

    const renderPassInfo = volk.VkRenderPassBeginInfo{
        .sType = volk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = self.renderPass,
        .framebuffer = self.swapChainFramebuffers[imageIndex],
        .renderArea = .{
            .offset = .{ .x = 0, .y = 0 },
            .extent = self.swapChainExtent,
        },
        .clearValueCount = 1,
        .pClearValues = &clearValues,
    };
    _ = volk.vkCmdBeginRenderPass.?(self.commandBuffers[self.currentFrame], &renderPassInfo, volk.VK_SUBPASS_CONTENTS_INLINE);

    zgui.backend.render(self.commandBuffers[self.currentFrame]);

    _ = volk.vkCmdEndRenderPass.?(self.commandBuffers[self.currentFrame]);
    if (volk.vkEndCommandBuffer.?(self.commandBuffers[self.currentFrame]) != volk.VK_SUCCESS) {
        @panic("Failed to record gui command buffer!");
    }
}

pub export fn jrGui_destroy(self: *JrGui) callconv(.C) void {
    zgui.backend.deinit();
    zgui.deinit();

    destroyFramebuffers(self);

    volk.vkDestroyRenderPass.?(self.device, self.renderPass, null);

    volk.vkDestroyDescriptorPool.?(self.device, self.descriptorPool, null);
    volk.vkDestroyCommandPool.?(self.device, self.commandPool, null);

    for (self.renderFinishedSemaphores) |renderFinishedSemaphore| {
        volk.vkDestroySemaphore.?(self.device, renderFinishedSemaphore, null);
    }
}

pub fn destroyFramebuffers(self: *JrGui) void {
    for (self.swapChainFramebuffers) |framebuffer| {
        volk.vkDestroyFramebuffer.?(self.device, framebuffer, null);
    }
}
