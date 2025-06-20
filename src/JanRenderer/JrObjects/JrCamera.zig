const std = @import("std");
const testing = std.testing;
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});
const FixedCglm = @import("utils/FixedCglm.zig");
const zmath = @import("zmath");
const zglfw = @import("zglfw");
const common = @import("common.zig");

pub const JrCamera = extern struct {
    position: cglm.vec3s,
    velocity: cglm.vec3s,

    pitch: f32,
    yaw: f32,

    speed: f32,
    fieldOfView: f32,

    isRotatable: bool,
};

pub export fn jrCamera_init(self: *JrCamera) callconv(.C) void {
    self.position = cglm.glms_vec3_zero();
    self.velocity = cglm.glms_vec3_zero();

    self.pitch = 0.0;
    self.yaw = 0.0;

    self.speed = 0.05;
    self.fieldOfView = 45;

    self.isRotatable = false;
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

pub export fn jrCamera_keyCallback(window: *zglfw.Window, key: zglfw.Key, scancode: c_int, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    _ = scancode;
    _ = mods;
    const self = zglfw.getWindowUserPointer(window, common.GlfwUserPointer).?.camera orelse @panic("Problem with key callback");

    if (action == zglfw.Action.press) {
        if (key == zglfw.Key.w) {
            self.velocity.unnamed_0.z += self.speed * -1;
        }
        if (key == zglfw.Key.s) {
            self.velocity.unnamed_0.z += self.speed * 1;
        }
        if (key == zglfw.Key.a) {
            self.velocity.unnamed_0.x += self.speed * -1;
        }
        if (key == zglfw.Key.d) {
            self.velocity.unnamed_0.x += self.speed * 1;
        }
    } else if (action == zglfw.Action.release) {
        if (key == zglfw.Key.w) {
            self.velocity.unnamed_0.z -= self.speed * -1;
        }
        if (key == zglfw.Key.s) {
            self.velocity.unnamed_0.z -= self.speed * 1;
        }
        if (key == zglfw.Key.a) {
            self.velocity.unnamed_0.x -= self.speed * -1;
        }
        if (key == zglfw.Key.d) {
            self.velocity.unnamed_0.x -= self.speed * 1;
        }
    }
}

//test "test keyCallback" {
//    const window = glfw.glfwCreateWindow(800, 600, "test keyCallback", null, null);
//    keyCallback(window, glfw.GLFW_KEY_S, 0, glfw.GLFW_PRESS, 0);
//    try testing.expect(self.velocity.unnamed_0.z == 1);
//}

pub export fn jrCamera_cursorPositionCallback(window: *zglfw.Window, xpos: f64, ypos: f64) callconv(.C) void {
    const self = zglfw.getWindowUserPointer(window, common.GlfwUserPointer).?.camera orelse @panic("Problem with cursor position callback");
    const static = struct {
        var firstMouse: bool = true;
        var lastXpos: f64 = 0;
        var lastYpos: f64 = 0;
    };

    if (self.isRotatable) {
        if (static.firstMouse) {
            static.lastXpos = xpos;
            static.lastYpos = ypos;
            static.firstMouse = false;
        }

        const sensitivity = 0.01;

        const xoffset = (xpos - static.lastXpos) * sensitivity;
        const yoffset = (ypos - static.lastYpos) * sensitivity;

        self.yaw += @floatCast(xoffset);
        self.pitch -= @floatCast(yoffset);

        if (self.pitch > 89) self.pitch = 89;
        if (self.pitch < -89) self.pitch = -89;
    }

    static.lastXpos = xpos;
    static.lastYpos = ypos;
}

pub export fn jrCamera_mouseButtonCallback(window: *zglfw.Window, button: zglfw.MouseButton, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    _ = mods;
    const self = zglfw.getWindowUserPointer(window, common.GlfwUserPointer).?.camera orelse @panic("Problem with mouse button callback");

    if (button == zglfw.MouseButton.right) {
        if (action == zglfw.Action.press) {
            self.isRotatable = true;
        } else if (action == zglfw.Action.release) {
            self.isRotatable = false;
        }
    }
}

pub export fn jrCamera_scrollCallback(window: *zglfw.Window, xoffset: f64, yoffset: f64) callconv(.C) void {
    _ = xoffset;
    const self = zglfw.getWindowUserPointer(window, common.GlfwUserPointer).?.camera orelse @panic("Problem with scroll callback");
    self.fieldOfView -= @floatCast(yoffset);

    if (self.fieldOfView < 1) self.fieldOfView = 1;
    if (self.fieldOfView > 180) self.fieldOfView = 180;
}

pub export fn jrCamera_update(self: *JrCamera, deltaTime: f32) callconv(.C) void {
    //std.debug.print("({d}, {d}, {d}), ({d}, {d}, {d})\n", .{ self.position.unnamed_0.x, self.position.unnamed_0.y, self.position.unnamed_0.z, self.velocity.unnamed_0.x, self.velocity.unnamed_0.y, self.velocity.unnamed_0.z });

    const cameraRotation: cglm.mat4s = jrCamera_getRotationMatrix(self);
    self.position = cglm.glms_vec3_add(self.position, cglm.glms_vec4_copy3(FixedCglm.glms_mat4_mulv(cameraRotation, cglm.glms_vec4(cglm.glms_vec3_scale(self.velocity, deltaTime), 0.0))));
}
