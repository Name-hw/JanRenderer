const std = @import("std");
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});

pub const JrCamera = extern struct {
    position: cglm.vec3s = cglm.glms_vec3_zero(),
    velocity: cglm.vec3s = cglm.glms_vec3_zero(),

    pitch: f32 = 0.0,
    yaw: f32 = 0.0,

    fn getRotationMatrix(self: *JrCamera) cglm.mat4s {
        const pitchRotation: cglm.versors = cglm.glms_quat(self.pitch, 1, 0, 0);
        const yawRotation: cglm.versors = cglm.glms_quat(self.yaw, 0, -1, 0);

        return cglm.glms_mat4_mul(cglm.glms_quat_mat4(yawRotation), cglm.glms_quat_mat4(pitchRotation));
    }
    fn getViewMatrix(self: *JrCamera) cglm.mat4s {
        const cameraTranslation: cglm.mat4s = cglm.glms_translate(cglm.GLMS_MAT4_IDENTITY, self.position);
        const cameraRotation: cglm.mat4s = self.getRotationMatrix();

        return cglm.glms_mat4_inv(cglm.glms_mat4_mul(cameraRotation, cameraTranslation));
    }
    fn update(self: *JrCamera) void {
        const cameraRotation: cglm.mat4s = self.getRotationMatrix();
        self.position = cglm.glms_vec3_add(self.position, cglm.glms_vec4_copy3(cglm.glms_mat4_mulv(cameraRotation, cglm.glms_vec4(cglm.glms_vec3_scale(self.velocity, 0.5), 0.0))));
    }
};

pub export fn jrCamera_new() callconv(.C) *JrCamera {
    const allocator = std.heap.c_allocator;
    const newJrCamera = allocator.create(JrCamera) catch unreachable;

    newJrCamera.* = JrCamera{};

    return newJrCamera;
}

pub export fn jrCamera_getRotationMatrix(self: *JrCamera) callconv(.C) cglm.mat4s {
    return self.*.getRotationMatrix();
}

pub export fn jrCamera_getViewMatrix(self: *JrCamera) callconv(.C) cglm.mat4s {
    return self.*.getRotationMatrix();
}

pub export fn jrCamera_update(self: *JrCamera) callconv(.C) void {
    self.*.update();
}
