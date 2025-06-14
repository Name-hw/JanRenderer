const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});

pub const GLM_MAT4_IDENTITY_INIT = [4][4]f32{ [4]f32{ 1.0, 0.0, 0.0, 0.0 }, [4]f32{ 0.0, 1.0, 0.0, 0.0 }, [4]f32{ 0.0, 0.0, 1.0, 0.0 }, [4]f32{ 0.0, 0.0, 0.0, 1.0 } };
pub const GLM_MAT4_ZERO_INIT = [4][4]f32{ [4]f32{ 0.0, 0.0, 0.0, 0.0 }, [4]f32{ 0.0, 0.0, 0.0, 0.0 }, [4]f32{ 0.0, 0.0, 0.0, 0.0 }, [4]f32{ 0.0, 0.0, 0.0, 0.0 } };
pub const GLM_MAT4_IDENTITY: cglm.mat4 = @as(cglm.mat4, GLM_MAT4_IDENTITY_INIT);
pub const GLM_MAT4_ZERO: cglm.mat4 = @as(cglm.mat4, GLM_MAT4_ZERO_INIT);

pub const GLMS_MAT4_IDENTITY_INIT: cglm.mat4s = .{ .raw = GLM_MAT4_IDENTITY_INIT };
pub const GLMS_MAT4_ZERO_INIT: cglm.mat4s = .{ .raw = GLM_MAT4_ZERO_INIT };
pub const GLMS_MAT4_IDENTITY: cglm.mat4s = @as(cglm.mat4s, GLMS_MAT4_IDENTITY_INIT);
pub const GLMS_MAT4_ZERO: cglm.mat4s = @as(cglm.mat4s, GLMS_MAT4_ZERO_INIT);

//inline fn glm_mat4_mul(m1:cglm.mat4, m2:cglm.mat4, dest:cglm.mat4) void {

//}

pub inline fn glmm_load(p: [*]const f32) cglm.__m128 {
    return @as(*cglm.__m128, @ptrCast(@alignCast(@constCast(p)))).*;
}

pub inline fn glmm_shuff1(xmm: cglm.__m128, z: i32, y: i32, x: i32, w: i32) cglm.__m128 {
    return @shuffle(f32, xmm, xmm, @Vector(4, i32){
        z,
        y,
        x,
        w,
    });
}

pub inline fn glmm_splat(x: cglm.__m128, lane: anytype) cglm.__m128 {
    return glmm_shuff1(x, lane, lane, lane, lane);
}
pub inline fn glmm_splat_x(x: cglm.__m128) cglm.__m128 {
    return glmm_splat(x, 0);
}
pub inline fn glmm_splat_y(x: cglm.__m128) cglm.__m128 {
    return glmm_splat(x, 1);
}
pub inline fn glmm_splat_z(x: cglm.__m128) cglm.__m128 {
    return glmm_splat(x, 2);
}
pub inline fn glmm_splat_w(x: cglm.__m128) cglm.__m128 {
    return glmm_splat(x, 3);
}

pub inline fn glm_mat4_mulv(m: cglm.mat4, v: cglm.vec4, dest: *cglm.vec4) void {
    const m0: cglm.__m128 = glmm_load(&m[0]);
    const m1: cglm.__m128 = glmm_load(&m[1]);
    const m2: cglm.__m128 = glmm_load(&m[2]);
    const m3: cglm.__m128 = glmm_load(&m[3]);

    const x0: cglm.__m128 = glmm_load(&v);
    const v0: cglm.__m128 = glmm_splat_x(x0);
    const v1: cglm.__m128 = glmm_splat_y(x0);
    const v2: cglm.__m128 = glmm_splat_z(x0);
    const v3: cglm.__m128 = glmm_splat_w(x0);

    var x1: cglm.__m128 = m3 * v3;
    x1 = glmm_fmadd(m2, v2, x1);
    x1 = glmm_fmadd(m1, v1, x1);
    x1 = glmm_fmadd(m0, v0, x1);

    cglm.glmm_store(dest, x1);
}

pub inline fn glms_mat4_mulv(m: cglm.mat4s, v: cglm.vec4s) cglm.vec4s {
    var r: cglm.vec4s = cglm.glms_vec4_zero();
    glm_mat4_mulv(@as(*cglm.mat4, @ptrCast(@alignCast(@constCast(&m.raw)))).*, @as(*cglm.vec4, @ptrCast(@alignCast(@constCast(&v.raw)))).*, @as(*cglm.vec4, @ptrCast(@alignCast(&r.raw))));
    return r;
}

pub inline fn glmm_fmadd(a: cglm.__m128, b: cglm.__m128, c: cglm.__m128) cglm.__m128 {
    return a * b + c;
}
pub inline fn glmm_fnmadd(a: cglm.__m128, b: cglm.__m128, c: cglm.__m128) cglm.__m128 {
    return c - a * b;
}
pub inline fn glmm_vhadd(v: cglm.__m128) cglm.__m128 {
    var x0: cglm.__m128 = v + glmm_shuff1(v, 0, 1, 2, 3);
    x0 = x0 + glmm_shuff1(x0, 1, 0, 0, 1);
    return x0;
}

pub inline fn glm_mat4_inv(mat: cglm.mat4, dest: cglm.mat4) void {
    //__m128 r0, r1, r2, r3,
    //       v0, v1, v2, v3,
    //       t0, t1, t2, t3, t4, t5,
    //       x0, x1, x2, x3, x4, x5, x6, x7, x8, x9;

    // x8 = _mm_set_ps(-0.f, 0.f, -0.f, 0.f);
    const x8: cglm.__m128 = cglm.glmm_float32x4_SIGNMASK_NPNP;
    const x9: cglm.__m128 = glmm_shuff1(x8, 2, 1, 2, 1);

    // 127 <- 0
    const r0: cglm.__m128 = glmm_load(&mat[0]); //* d c b a */
    const r1: cglm.__m128 = glmm_load(&mat[1]); //* h g f e */
    const r2: cglm.__m128 = glmm_load(&mat[2]); //* l k j i */
    const r3: cglm.__m128 = glmm_load(&mat[3]); //* p o n m */

    var x0: cglm.__m128 = cglm._mm_movehl_ps(r3, r2); //* p o l k */
    var x3: cglm.__m128 = cglm._mm_movelh_ps(r2, r3); //* n m j i */
    var x1: cglm.__m128 = glmm_shuff1(x0, 1, 3, 3, 3); //* l p p p */
    var x2: cglm.__m128 = glmm_shuff1(x0, 0, 2, 2, 2); //* k o o o */
    var x4: cglm.__m128 = glmm_shuff1(x3, 1, 3, 3, 3); //* j n n n */
    const x7: cglm.__m128 = glmm_shuff1(x3, 0, 2, 2, 2); //* i m m m */

    const x6: cglm.__m128 = @shuffle(f32, r2, r1, @Vector(4, i32){
        0,
        0,
        0,
        0,
    }); //* e e i i */
    var x5: cglm.__m128 = @shuffle(f32, r2, r1, @Vector(4, i32){
        1,
        1,
        1,
        1,
    }); //* f f j j */
    x3 = @shuffle(f32, r2, r1, @Vector(4, i32){
        2,
        2,
        2,
        2,
    }); //* g g k k */
    x0 = @shuffle(f32, r2, r1, @Vector(4, i32){
        3,
        3,
        3,
        3,
    }); //* h h l l */

    var t0: cglm.__m128 = x3 * x1;
    var t1: cglm.__m128 = x5 * x1;
    var t2: cglm.__m128 = x5 * x2;
    var t3: cglm.__m128 = x6 * x1;
    var t4: cglm.__m128 = x6 * x2;
    var t5: cglm.__m128 = x6 * x4;

    //  /* t1[0] = k * p - o * l;
    //     t1[0] = k * p - o * l;
    //     t2[0] = g * p - o * h;
    //     t3[0] = g * l - k * h; */
    t0 = glmm_fnmadd(x2, x0, t0);

    //  /* t1[1] = j * p - n * l;
    //     t1[1] = j * p - n * l;
    //     t2[1] = f * p - n * h;
    //     t3[1] = f * l - j * h; */
    t1 = glmm_fnmadd(x4, x0, t1);

    //  /* t1[2] = j * o - n * k
    //     t1[2] = j * o - n * k;
    //     t2[2] = f * o - n * g;
    //     t3[2] = f * k - j * g; */
    t2 = glmm_fnmadd(x4, x3, t2);

    //  /* t1[3] = i * p - m * l;
    //     t1[3] = i * p - m * l;
    //     t2[3] = e * p - m * h;
    //     t3[3] = e * l - i * h; */
    t3 = glmm_fnmadd(x7, x0, t3);

    //  /* t1[4] = i * o - m * k;
    //     t1[4] = i * o - m * k;
    //     t2[4] = e * o - m * g;
    //     t3[4] = e * k - i * g; */
    t4 = glmm_fnmadd(x7, x3, t4);

    //  /* t1[5] = i * n - m * j;
    //     t1[5] = i * n - m * j;
    //     t2[5] = e * n - m * f;
    //     t3[5] = e * j - i * f; */
    t5 = glmm_fnmadd(x7, x5, t5);

    x4 = cglm._mm_movelh_ps(r0, r1); //* f e b a */
    x5 = cglm._mm_movehl_ps(r1, r0); //* h g d c */

    x0 = glmm_shuff1(x4, 0, 0, 0, 2); //* a a a e */
    x1 = glmm_shuff1(x4, 1, 1, 1, 3); //* b b b f */
    x2 = glmm_shuff1(x5, 0, 0, 0, 2); //* c c c g */
    x3 = glmm_shuff1(x5, 1, 1, 1, 3); //* d d d h */

    var v2: cglm.__m128 = x0 * t1;
    var v1: cglm.__m128 = x0 * t0;
    var v3: cglm.__m128 = x0 * t2;
    var v0: cglm.__m128 = x1 * t0;

    v2 = glmm_fnmadd(x1, t3, v2);
    v3 = glmm_fnmadd(x1, t4, v3);
    v0 = glmm_fnmadd(x2, t1, v0);
    v1 = glmm_fnmadd(x2, t3, v1);

    v3 = glmm_fmadd(x2, t5, v3);
    v0 = glmm_fmadd(x3, t2, v0);
    v2 = glmm_fmadd(x3, t5, v2);
    v1 = glmm_fmadd(x3, t4, v1);

    //  /*
    //   dest[0][0] =  f * t1[0] - g * t1[1] + h * t1[2];
    //   dest[0][1] =-(b * t1[0] - c * t1[1] + d * t1[2]);
    //   dest[0][2] =  b * t2[0] - c * t2[1] + d * t2[2];
    //   dest[0][3] =-(b * t3[0] - c * t3[1] + d * t3[2]); */
    v0 = cglm._mm_xor_ps(v0, x8);

    //  /*
    //   dest[2][0] =  e * t1[1] - f * t1[3] + h * t1[5];
    //   dest[2][1] =-(a * t1[1] - b * t1[3] + d * t1[5]);
    //   dest[2][2] =  a * t2[1] - b * t2[3] + d * t2[5];
    //   dest[2][3] =-(a * t3[1] - b * t3[3] + d * t3[5]);*/
    v2 = cglm._mm_xor_ps(v2, x8);

    //  /*
    //   dest[1][0] =-(e * t1[0] - g * t1[3] + h * t1[4]);
    //   dest[1][1] =  a * t1[0] - c * t1[3] + d * t1[4];
    //   dest[1][2] =-(a * t2[0] - c * t2[3] + d * t2[4]);
    //   dest[1][3] =  a * t3[0] - c * t3[3] + d * t3[4];
    v1 = cglm._mm_xor_ps(v1, x9);

    //   dest[3][0] =-(e * t1[2] - f * t1[4] + g * t1[5]);
    //   dest[3][1] =  a * t1[2] - b * t1[4] + c * t1[5];
    //   dest[3][2] =-(a * t2[2] - b * t2[4] + c * t2[5]);
    //   dest[3][3] =  a * t3[2] - b * t3[4] + c * t3[5];
    v3 = cglm._mm_xor_ps(v3, x9);

    // determinant
    x0 = @shuffle(f32, v0, v1, @Vector(4, i32){
        0,
        0,
        0,
        0,
    });
    x1 = @shuffle(f32, v2, v3, @Vector(4, i32){
        0,
        0,
        0,
        0,
    });
    x0 = @shuffle(f32, x0, x1, @Vector(4, i32){
        2,
        0,
        2,
        0,
    });

    x0 = cglm._mm_set1_ps(1.0) / glmm_vhadd(x0 * r0);

    cglm.glmm_store(@constCast(&dest[0]), v0 * x0);
    cglm.glmm_store(@constCast(&dest[1]), v1 * x0);
    cglm.glmm_store(@constCast(&dest[2]), v2 * x0);
    cglm.glmm_store(@constCast(&dest[3]), v3 * x0);
}

pub fn glms_mat4_inv(mat: cglm.mat4s) cglm.mat4s {
    var r: cglm.mat4s = GLMS_MAT4_ZERO;
    glm_mat4_inv(@as(*cglm.mat4, @ptrCast(@alignCast(@constCast(&mat.raw)))).*, @as(*cglm.mat4, @ptrCast(@alignCast(&r.raw))).*);
    return r;
}

pub inline fn glm_translate(m: *cglm.mat4, v: cglm.vec3) void {
    const m0: cglm.__m128 = glmm_load(&m[0]);
    const m1: cglm.__m128 = glmm_load(&m[1]);
    const m2: cglm.__m128 = glmm_load(&m[2]);
    const m3: cglm.__m128 = glmm_load(&m[3]);

    cglm.glmm_store(&m[3], glmm_fmadd(m0, cglm.glmm_set1(v[0]), glmm_fmadd(m1, cglm.glmm_set1(v[1]), glmm_fmadd(m2, cglm.glmm_set1(v[2]), m3))));
}

pub fn glms_translate(m: cglm.mat4s, v: cglm.vec3s) cglm.mat4s {
    glm_translate(@as(*cglm.mat4, @ptrCast(@alignCast(@constCast(&m.raw)))), @as(*cglm.vec3, @ptrCast(@alignCast(@constCast(&v.raw)))).*);
    return m;
}
