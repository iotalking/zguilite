const std = @import("std");
const math = std.math;

pub fn multiply(m: i32, n: i32, p: i32, a: []const f64, b: []const f64, c: []f64) void {
    const um: usize = @intCast(m);
    const up: usize = @intCast(p);
    const un: usize = @intCast(n);
    for (0..um) |i| {
        for (0..up) |j| {
            c[i * up + j] = 0;
            for (0..un) |k| {
                c[i * up + j] += a[i * un + k] * b[k * up + j];
            }
        }
    }
}

pub fn rotateX(angle: f64, point: []const f64, output: []f64) void {
    var rotation = [3][3]f64{
        .{ 1, 0, 0 },
        .{ 0, @cos(angle), -@sin(angle) },
        .{ 0, @sin(angle), @cos(angle) },
    };
    multiply(3, 3, 1, @as([*]f64, @ptrCast(&rotation[0][0]))[0..9], point, output);
}

pub fn rotateY(angle: f64, point: []const f64, output: []f64) void {
    var rotation = [3][3]f64{
        .{ @cos(angle), 0, @sin(angle) },
        .{ 0, 1, 0 },
        .{ -@sin(angle), 0, @cos(angle) },
    };
    multiply(3, 3, 1, @as([*]f64, @ptrCast(&rotation[0][0]))[0..9], point, output);
}

pub fn rotateZ(angle: f64, point: []const f64, output: []f64) void {
    var rotation = [3][3]f64{
        .{ @cos(angle), -@sin(angle), 0 },
        .{ @sin(angle), @cos(angle), 0 },
        .{ 0, @sin(angle), 1 },
    };
    multiply(3, 3, 1, @as([*]f64, @ptrCast(&rotation[0][0]))[0..9], point, output);
}

pub fn projectOnXY(point: []const f64, output: []f64, zFactor: f64) void {
    // var projection = std.mem.zeroes([2][3]f64);
    // projection[0][0] = zFactor;
    // projection[1][1] = zFactor;
    var projection = [2][3]f64{
        .{ zFactor, 0, 0 },
        .{ 0, zFactor, 0 },
    };
    multiply(2, 3, 1, @as([*]f64, @ptrCast(&projection[0][0]))[0..6], point, output);
}
