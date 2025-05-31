const std = @import("std");
const testing = std.testing;
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});
const FixedCglm = @import("utils/FixedCglm.zig");
const glfw = @cImport({
    @cDefine("VK_USE_PLATFORM_WIN32_KHR", "");
    @cDefine("GLFW_INCLUDE_VULKAN", "");
    @cInclude("GLFW/glfw3.h");
});
const zmath = @import("zmath");
const common = @import("common.zig");

pub const JrCamera = extern struct {
    position: cglm.vec3s,
    velocity: cglm.vec3s,

    pitch: f32,
    yaw: f32,

    speed: f32,
    fov: f32,
};

pub export fn jrCamera_init(self: *JrCamera) callconv(.C) void {
    self.position = cglm.glms_vec3_zero();
    self.velocity = cglm.glms_vec3_zero();

    self.pitch = 0.0;
    self.yaw = 0.0;
    self.speed = 0.05;
    self.fov = 45;
}

pub export fn jrCamera_getRotationMatrix(self: *JrCamera) callconv(.C) cglm.mat4s {
    const pitchRotation: zmath.Quat = zmath.quatFromNormAxisAngle(zmath.Vec{ 1, 0, 0, 0 }, self.pitch);
    const yawRotation: zmath.Quat = zmath.quatFromNormAxisAngle(zmath.Vec{ 0, -1, 0, 0 }, self.yaw);

    const r = zmath.matToArr(zmath.mul(zmath.matFromQuat(pitchRotation), zmath.matFromQuat(yawRotation)));

    return cglm.glms_mat4_make(&r);
}

pub export fn jrCamera_getViewMatrix(self: *JrCamera) callconv(.C) cglm.mat4s {
    const cameraTranslation: zmath.Mat = zmath.translation(self.position.raw[0], self.position.raw[1], self.position.raw[2]);
    const cameraRotation: zmath.Mat = zmath.matFromArr(@as(*[16]f32, @ptrCast(@constCast(&jrCamera_getRotationMatrix(self)))).*);

    const r = zmath.matToArr(zmath.inverse(zmath.mul(cameraRotation, cameraTranslation)));

    return cglm.glms_mat4_make(&r);
}

pub export fn jrCamera_keyCallback(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = scancode;
    _ = mods;
    const self = @as(*common.GlfwUserPointer, @ptrCast(@alignCast(glfw.glfwGetWindowUserPointer(window)))).camera orelse @panic("Problem with key callback");

    if (action == glfw.GLFW_PRESS) {
        if (key == glfw.GLFW_KEY_W) {
            self.velocity.unnamed_0.z += self.speed * -1;
        }
        if (key == glfw.GLFW_KEY_S) {
            self.velocity.unnamed_0.z += self.speed * 1;
        }
        if (key == glfw.GLFW_KEY_A) {
            self.velocity.unnamed_0.x += self.speed * -1;
        }
        if (key == glfw.GLFW_KEY_D) {
            self.velocity.unnamed_0.x += self.speed * 1;
        }
    } else if (action == glfw.GLFW_RELEASE) {
        if (key == glfw.GLFW_KEY_W) {
            self.velocity.unnamed_0.z -= self.speed * -1;
        }
        if (key == glfw.GLFW_KEY_S) {
            self.velocity.unnamed_0.z -= self.speed * 1;
        }
        if (key == glfw.GLFW_KEY_A) {
            self.velocity.unnamed_0.x -= self.speed * -1;
        }
        if (key == glfw.GLFW_KEY_D) {
            self.velocity.unnamed_0.x -= self.speed * 1;
        }
    }
}

//test "test keyCallback" {
//    const window = glfw.glfwCreateWindow(800, 600, "test keyCallback", null, null);
//    keyCallback(window, glfw.GLFW_KEY_S, 0, glfw.GLFW_PRESS, 0);
//    try testing.expect(self.velocity.unnamed_0.z == 1);
//}

pub export fn jrCamera_cursorPositionCallback(window: ?*glfw.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    const self = @as(*common.GlfwUserPointer, @ptrCast(@alignCast(glfw.glfwGetWindowUserPointer(window)))).camera orelse @panic("Problem with cursor position callback");
    const static = struct {
        var firstMouse: bool = true;
        var lastXpos: f64 = 0;
        var lastYpos: f64 = 0;
    };

    if (static.firstMouse) {
        static.lastXpos = xpos;
        static.lastYpos = ypos;
        static.firstMouse = false;
    }

    const sensitivity = 0.01;

    const xoffset = (xpos - static.lastXpos) * sensitivity;
    const yoffset = (ypos - static.lastYpos) * sensitivity;
    static.lastXpos = xpos;
    static.lastYpos = ypos;

    self.yaw += @floatCast(xoffset);
    self.pitch -= @floatCast(yoffset);

    if (self.pitch > 89) self.pitch = 89;
    if (self.pitch < -89) self.pitch = -89;
}

pub export fn jrCamera_scrollCallback(window: ?*glfw.GLFWwindow, xoffset: f64, yoffset: f64) callconv(.C) void {
    _ = xoffset;
    const self = @as(*common.GlfwUserPointer, @ptrCast(@alignCast(glfw.glfwGetWindowUserPointer(window)))).camera orelse @panic("Problem with scroll callback");
    self.fov -= @floatCast(yoffset);

    if (self.pitch < 1) self.pitch = 1;
    if (self.pitch > 45) self.pitch = 45;
}

pub export fn jrCamera_update(self: *JrCamera) callconv(.C) void {
    //std.debug.print("({d}, {d}, {d}), ({d}, {d}, {d})\n", .{ self.position.unnamed_0.x, self.position.unnamed_0.y, self.position.unnamed_0.z, self.velocity.unnamed_0.x, self.velocity.unnamed_0.y, self.velocity.unnamed_0.z });

    const cameraRotation: cglm.mat4s = jrCamera_getRotationMatrix(self);
    self.position = cglm.glms_vec3_add(self.position, cglm.glms_vec4_copy3(FixedCglm.glms_mat4_mulv(cameraRotation, cglm.glms_vec4(cglm.glms_vec3_scale(self.velocity, 0.5), 0.0))));
}
