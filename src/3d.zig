const std = @import("std");
const guilite = @import("./guilite.zig");
const SHAPE_CNT = 2;

const UI_WIDTH = 480;
const UI_HEIGHT = 320;
const SHAPE_SIZE = 50;
const Z_ORDER_LEVEL_0 = guilite.Z_ORDER_LEVEL.Z_ORDER_LEVEL_0;
// 3D engine
pub fn multiply(m: usize, n: usize, p: usize, a: [*]f64, b: [*]f64, c: [*]f64) void // a[m][n] * b[n][p] = c[m][p]
{
    // for (int i = 0; i < m; i++) {
    for (0..m) |i| {
        // for (int j = 0; j < p; j++) {
        for (0..p) |j| {
            // c[i * p + j] = 0;
            const pcf: *f64 = &c[i * p + j];
            pcf.* = 0;
            // for (int k = 0; k < n; k++) {
            for (0..n) |k| {
                // std.log.err("a:{d:.2}", .{b[k * p + j]});
                // c[i * p + j] += a[i * n + k] * b[k * p + j];
                pcf.* = a[i * n + k] * b[k * p + j];
                // std.log.err("pcf:{d:0.2}", .{pcf.*});
            }
        }
    }
}

pub fn rotateX(angle: f64, point: [*]f64, output: [*]f64) void // rotate matrix for X
{
    var rotation: [3][3]f64 = undefined;
    rotation[0][0] = 1;
    rotation[1][1] = @cos(angle);
    rotation[1][2] = 0 - @sin(angle);
    rotation[2][1] = @sin(angle);
    rotation[2][2] = @cos(angle);
    multiply(3, 3, 1, @ptrCast(&rotation), point, output);
}

pub fn rotateY(angle: f64, point: [*]f64, output: [*]f64) void // rotate matrix for Y
{
    var rotation: [3][3]f64 = undefined;
    rotation[0][0] = @cos(angle);
    rotation[0][2] = @sin(angle);
    rotation[1][1] = 1;
    rotation[2][0] = 0 - @sin(angle);
    rotation[2][2] = @cos(angle);
    multiply(3, 3, 1, @ptrCast(&rotation), point, output);
}

pub fn rotateZ(angle: f64, point: [*]f64, output: [*]f64) void // rotate matrix for Z
{
    var rotation: [3][3]f64 = undefined;
    rotation[0][0] = @cos(angle);
    rotation[0][1] = 0 - @sin(angle);
    rotation[1][0] = @sin(angle);
    rotation[1][1] = @cos(angle);
    rotation[2][2] = 1;
    multiply(3, 3, 1, @ptrCast(&rotation), point, output);
}

//zFactor:default 1
pub fn projectOnXY(point: [*]f64, output: [*]f64, zFactor: f64) void {
    var projection: [2][3]f64 = undefined; //project on X/Y face
    projection[0][0] = zFactor; //the raio of point.z and camera.z
    projection[1][1] = zFactor; //the raio of point.z and camera.z
    multiply(2, 3, 1, @ptrCast(&projection), point, output);
}

// // Shape
// class Shape {
// public:
// 	Shape() { angle = 0.5; }
// 	virtual void draw(int x, int y, bool isErase) = 0;
// 	virtual void rotate() = 0;
// protected:
// 	double angle;
// };

pub const Shape = struct {
    pub fn subclass(this: *Shape, sub: type) void {
        this.m_vtable.draw = sub.draw;
        this.m_vtable.rotate = sub.rotate;
    }

    pub fn draw(this: *Shape, x: f64, y: f64, isErase: bool) void {
        this.m_vtable.draw(this, x, y, isErase);
    }
    pub fn rotate(this: *Shape) void {
        this.m_vtable.rotate(this);
    }
    pub const VTable = struct {
        pub fn draw(this: *Shape, x: f64, y: f64, isErase: bool) void {
            _ = this;
            _ = x;
            _ = y;
            _ = isErase;
        }
        pub fn rotate(this: *Shape) void {
            _ = this;
        }

        draw: *const fn (this: *Shape, x: f64, y: f64, isErase: bool) void = VTable.draw,
        rotate: *const fn (
            this: *Shape,
        ) void = VTable.rotate,
    };

    m_vtable: VTable = .{},
    angle: f64 = 0,
};

var s_surface: ?*guilite.Surface = null;
pub fn draw_line(surface: *guilite.Surface, x1: f64, y1: f64, x2: f64, y2: f64, rgb: u32, z_order: guilite.Z_ORDER_LEVEL) void {
    std.log.debug("draw_line({d:.0},{d:.0})({d:.0},{d:.0}) rgb:{d:.2}", .{ x1, y1, x2, y2, rgb });
    const fx1 = @as(i32, @bitCast(@as(u32, @truncate(@as(u64, @bitCast(x1))))));
    const fx2 = @as(i32, @bitCast(@as(u32, @truncate(@as(u64, @bitCast(x2))))));
    const fy1 = @as(i32, @bitCast(@as(u32, @truncate(@as(u64, @bitCast(y1))))));
    const fy2 = @as(i32, @bitCast(@as(u32, @truncate(@as(u64, @bitCast(y2))))));
    const irgb: i32 = @bitCast(rgb);
    surface.draw_line(fx1, fy1, fx2, fy2, irgb, @intFromEnum(z_order));
}

pub const Cube = struct {
    pub fn asShape(this: *Cube) *Shape {
        const shape = &this.shape;
        shape.subclass(@This());
        return shape;
    }
    pub fn draw(this: *Shape, x: f64, y: f64, isErase: bool) void {
        std.log.debug("cube draw ({d:.0},{d:.0})", .{ x, y });
        const cube: *Cube = @fieldParentPtr("shape", this);
        // var points = cube.points;
        const points2d = cube.points2d;
        // for (int i = 0; i < 8; i++)
        // for (0..8) |i| {
        //     projectOnXY(@ptrCast(&points), @ptrCast(&points2d[i]), 1);
        // }
        // std.log.err("points:{any}", .{points});
        // std.log.err("points2d:{any}", .{points2d});
        if (s_surface) |surface| {
            for (0..4) |i| {
                draw_line(surface, points2d[i][0] + x, points2d[i][1] + y, points2d[(i + 1) % 4][0] + x, points2d[(i + 1) % 4][1] + y, if (isErase) 0 else 0xffff0000, Z_ORDER_LEVEL_0);
                draw_line(surface, points2d[i + 4][0] + x, points2d[i + 4][1] + y, points2d[((i + 1) % 4) + 4][0] + x, points2d[((i + 1) % 4) + 4][1] + y, if (isErase) 0 else 0xff00ff00, Z_ORDER_LEVEL_0);
                draw_line(surface, points2d[i][0] + x, points2d[i][1] + y, points2d[(i + 4)][0] + x, points2d[(i + 4)][1] + y, if (isErase) 0 else 0xffffff00, Z_ORDER_LEVEL_0);
            }
        }
    }
    pub fn rotate(this: *Shape) void {
        const cube: *Cube = @fieldParentPtr("shape", this);
        var rotateOut1: [3][1]f64 = undefined;
        var rotateOut2: [3][1]f64 = undefined;
        var rotateOut3: [3][1]f64 = undefined;
        // var points = cube.points;
        const angle = this.angle;
        var points2d = cube.points2d;
        // for (int i = 0; i < 8; i++)
        for (0..8) |i| {
            // const f: [*]f64 = &points[i];
            // std.log.err("points:{any},{},{}", .{ f[0], f[1], f[2] });
            rotateX(angle, &points[i], @ptrCast(&rotateOut1));
            rotateY(angle, @ptrCast(&rotateOut1), @ptrCast(&rotateOut2));
            rotateZ(angle, @ptrCast(&rotateOut2), @ptrCast(&rotateOut3));
            projectOnXY(@ptrCast(&rotateOut3), @ptrCast(&points2d[i]), 1);
        }
        this.angle += 0.1;
    }
    // private:
    var points: [8][3]f64 = .{
        .{ -SHAPE_SIZE, -SHAPE_SIZE, -SHAPE_SIZE }, // x, y, z
        .{ SHAPE_SIZE, -SHAPE_SIZE, -SHAPE_SIZE },
        .{ SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE },
        .{ -SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE },
        .{ -SHAPE_SIZE, -SHAPE_SIZE, SHAPE_SIZE },
        .{ SHAPE_SIZE, -SHAPE_SIZE, SHAPE_SIZE },
        .{ SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE },
        .{ -SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE },
    };
    shape: Shape = .{},
    points2d: [8][2]f64 = undefined,
};

// double Cube::points[8][3] = {
// 	{-SHAPE_SIZE, -SHAPE_SIZE, -SHAPE_SIZE},// x, y, z
// 	{SHAPE_SIZE, -SHAPE_SIZE, -SHAPE_SIZE},
// 	{SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE},
// 	{-SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE},
// 	{-SHAPE_SIZE, -SHAPE_SIZE, SHAPE_SIZE},
// 	{SHAPE_SIZE, -SHAPE_SIZE, SHAPE_SIZE},
// 	{SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE},
// 	{-SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE}
// };

pub const Pyramid = struct {
    pub fn draw(this: *Shape, x: f64, y: f64, isErase: bool) void {
        const pyranid: *Pyramid = @fieldParentPtr("shape", this);
        const points2d = pyranid.points2d;
        if (s_surface) |surface| {
            draw_line(surface, points2d[0][0] + x, points2d[0][1] + y, points2d[2][0] + x, points2d[2][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);
            draw_line(surface, points2d[0][0] + x, points2d[0][1] + y, points2d[3][0] + x, points2d[3][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);
            draw_line(surface, points2d[0][0] + x, points2d[0][1] + y, points2d[4][0] + x, points2d[4][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);

            draw_line(surface, points2d[1][0] + x, points2d[1][1] + y, points2d[2][0] + x, points2d[2][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);
            draw_line(surface, points2d[2][0] + x, points2d[2][1] + y, points2d[3][0] + x, points2d[3][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);
            draw_line(surface, points2d[3][0] + x, points2d[3][1] + y, points2d[4][0] + x, points2d[4][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);
            draw_line(surface, points2d[4][0] + x, points2d[4][1] + y, points2d[1][0] + x, points2d[1][1] + y, if (isErase) 0 else 0xff007acc, Z_ORDER_LEVEL_0);
        }
    }

    pub fn rotate(this: *Shape) void {
        const pyranid: *Pyramid = @fieldParentPtr("shape", this);
        var rotateOut1: [3][1]f64 = undefined;
        var rotateOut2: [3][1]f64 = undefined;

        // for (int i = 0; i < 5; i++)
        const angle = this.angle;
        var points = pyranid.points;
        var points2d = pyranid.points2d;
        for (0..5) |i| {
            rotateY(angle, @ptrCast(&points[i]), @ptrCast(&rotateOut1));
            rotateX(0.1, @ptrCast(&rotateOut1), @ptrCast(&rotateOut2));
            const zFactor = @divExact(SHAPE_SIZE, (2.2 * SHAPE_SIZE - rotateOut2[2][0]));
            projectOnXY(@ptrCast(&rotateOut2), @ptrCast(&points2d[i]), zFactor);
        }
        this.angle += 0.1;
    }
    pub fn asShape(this: *Pyramid) *Shape {
        const shape = &this.shape;
        shape.subclass(@This());
        return shape;
    }
    // private:
    shape: Shape = .{},
    points: [5][3]f64 = .{
        .{ 0, -SHAPE_SIZE, 0 }, // top
        .{ -SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE },
        .{ SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE },
        .{ SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE },
        .{ -SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE },
    },
    points2d: [5][2]f64 = undefined,
};

pub fn create_ui(display: *guilite.Display) !void {
    s_surface = try display.alloSurface(.Z_ORDER_LEVEL_0, guilite.Rect.init2(300, 300, UI_WIDTH, UI_HEIGHT));

    if (s_surface) |surface| {
        const rect = guilite.Rect.init2(0, 0, UI_WIDTH - 1, UI_HEIGHT - 1);
        surface.set_active(true);
        surface.fill_rect(rect, guilite.GL_RGB(0, 0, 0), @intFromEnum(guilite.Z_ORDER_LEVEL.Z_ORDER_LEVEL_0));

        var theCube: [SHAPE_CNT]Cube = .{ .{}, .{} };
        var thePyramid: [SHAPE_CNT]Pyramid = .{ .{}, .{} };
        while (true) {
            // for (int i = 0; i < SHAPE_CNT; i++)
            for (0..SHAPE_CNT) |i| {
                var shape: *Shape = theCube[i].asShape();
                const fx: f64 = @bitCast(120 + i * 240);
                std.log.debug("int fx:{d}", .{@as(i64, @bitCast(fx))});
                shape.draw(fx, 100, true); //erase footprint
                shape.rotate();
                shape.draw(fx, 100, false); //refresh cube

                shape = thePyramid[i].asShape();
                shape.draw(fx, 250, true); //erase footprint
                shape.rotate();
                shape.draw(fx, 250, false); //refresh pyramid
            }
            // thread_sleep(50);
            std.time.sleep(50);
        }
    }
}
