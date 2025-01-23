const std = @import("std");
const zguilite = @import("zguilite");
const X11 = @import("x11");
const _3d = @import("./3d.zig");
const UI_WIDTH: i32 = 1024; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 1024; // 示例值，根据实际情况修改
const SHAPE_SIZE = 100;
const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;
const SHAPE_CNT = 2;
const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        if (w.m_surface) |surface| {
            _ = surface; // autofix
        }
    }
};

fn ShapeClass(T: type) type {
    const NewType = struct {
        obj: T,
        const Self = @This();
        pub fn init(t: anytype) Self {
            return .{
                .obj = t,
            };
        }
        pub fn draw(this: *Self, x: i32, y: i32, isErase: bool) void {
            this.obj.draw(x, y, isErase);
        }
        pub fn rotate(this: *Self) void {
            this.obj.rotate();
        }
    };
    return NewType;
}

fn Shape(sub: anytype) ShapeClass(@TypeOf(sub)) {
    const T = ShapeClass(@TypeOf(sub));
    return T.init(sub);
}

var s_surface: *zguilite.Surface = undefined;

const Cube = struct {
    const Self = @This();
    const points: [8][3]f64 = blk: {
        var arr: [8][3]f64 = undefined;
        arr[0] = .{ -SHAPE_SIZE, -SHAPE_SIZE, -SHAPE_SIZE };
        arr[1] = .{ SHAPE_SIZE, -SHAPE_SIZE, -SHAPE_SIZE };
        arr[2] = .{ SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE };
        arr[3] = .{ -SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE };
        arr[4] = .{ -SHAPE_SIZE, -SHAPE_SIZE, SHAPE_SIZE };
        arr[5] = .{ SHAPE_SIZE, -SHAPE_SIZE, SHAPE_SIZE };
        arr[6] = .{ SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE };
        arr[7] = .{ -SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE };
        break :blk arr;
    };
    points2d: [8][2]f64 = undefined,
    angle: f64 = 0.5,

    pub fn draw(self: *Self, x: i32, y: i32, isErase: bool) void {
        var points2d: [8][2]i32 = undefined;
        for (0..8) |i| {
            points2d[i][0] = @intFromFloat(self.points2d[i][0]);
            points2d[i][1] = @intFromFloat(self.points2d[i][1]);
        }
        for (0..4) |i| {
            s_surface.draw_line(
                points2d[i][0] + x,
                points2d[i][1] + y,
                points2d[(i + 1) % 4][0] + x,
                points2d[(i + 1) % 4][1] + y,
                if (isErase) 0 else 0xffff0000,
                0,
            );
            s_surface.draw_line(
                points2d[i + 4][0] + x,
                points2d[i + 4][1] + y,
                points2d[((i + 1) % 4) + 4][0] + x,
                points2d[((i + 1) % 4) + 4][1] + y,
                if (isErase) 0 else 0xff00ff00,
                0,
            );
            s_surface.draw_line(
                points2d[i][0] + x,
                points2d[i][1] + y,
                points2d[(i + 4)][0] + x,
                points2d[(i + 4)][1] + y,
                if (isErase) 0 else 0xffffff00,
                0,
            );
        }
    }

    pub fn rotate(self: *Self) void {
        var rotateOut1: [3]f64 = undefined;
        var rotateOut2: [3]f64 = undefined;
        var rotateOut3: [3]f64 = undefined;
        for (0..8) |i| {
            _3d.rotateX(self.angle, &Cube.points[i], &rotateOut1);
            _3d.rotateY(self.angle, &rotateOut1, &rotateOut2);
            _3d.rotateZ(self.angle, &rotateOut2, &rotateOut3);
            _3d.projectOnXY(&rotateOut3, &self.points2d[i], 1);
        }
        self.angle += 0.1;
    }
};

const Pyramid = struct {
    const Self = @This();
    const points: [5][3]f64 = blk: {
        var arr: [5][3]f64 = undefined;
        arr[0] = .{ 0, -SHAPE_SIZE, 0 };
        arr[1] = .{ -SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE };
        arr[2] = .{ SHAPE_SIZE, SHAPE_SIZE, -SHAPE_SIZE };
        arr[3] = .{ SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE };
        arr[4] = .{ -SHAPE_SIZE, SHAPE_SIZE, SHAPE_SIZE };
        break :blk arr;
    };
    points2d: [5][2]f64 = undefined,
    angle: f64 = 0.5,

    pub fn draw(self: *Self, _x: i32, _y: i32, isErase: bool) void {
        const x: f64 = @floatFromInt(_x);
        const y: f64 = @floatFromInt(_y);

        const color: u32 = if (isErase) 0 else 0xff007acc;
        s_surface.draw_line(
            @intFromFloat(self.points2d[0][0] + x),
            @intFromFloat(self.points2d[0][1] + y),
            @intFromFloat(self.points2d[1][0] + x),
            @intFromFloat(self.points2d[1][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
        s_surface.draw_line(
            @intFromFloat(self.points2d[0][0] + x),
            @intFromFloat(self.points2d[0][1] + y),
            @intFromFloat(self.points2d[2][0] + x),
            @intFromFloat(self.points2d[2][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
        s_surface.draw_line(
            @intFromFloat(self.points2d[0][0] + x),
            @intFromFloat(self.points2d[0][1] + y),
            @intFromFloat(self.points2d[3][0] + x),
            @intFromFloat(self.points2d[3][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
        s_surface.draw_line(
            @intFromFloat(self.points2d[0][0] + x),
            @intFromFloat(self.points2d[0][1] + y),
            @intFromFloat(self.points2d[4][0] + x),
            @intFromFloat(self.points2d[4][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );

        s_surface.draw_line(
            @intFromFloat(self.points2d[1][0] + x),
            @intFromFloat(self.points2d[1][1] + y),
            @intFromFloat(self.points2d[2][0] + x),
            @intFromFloat(self.points2d[2][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
        s_surface.draw_line(
            @intFromFloat(self.points2d[2][0] + x),
            @intFromFloat(self.points2d[2][1] + y),
            @intFromFloat(self.points2d[3][0] + x),
            @intFromFloat(self.points2d[3][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
        s_surface.draw_line(
            @intFromFloat(self.points2d[3][0] + x),
            @intFromFloat(self.points2d[3][1] + y),
            @intFromFloat(self.points2d[4][0] + x),
            @intFromFloat(self.points2d[4][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
        s_surface.draw_line(
            @intFromFloat(self.points2d[4][0] + x),
            @intFromFloat(self.points2d[4][1] + y),
            @intFromFloat(self.points2d[1][0] + x),
            @intFromFloat(self.points2d[1][1] + y),
            color,
            Z_ORDER_LEVEL_0,
        );
    }
    pub fn rotate(self: *Self) void {
        var rotateOut1: [3]f64 = undefined;
        var rotateOut2: [3]f64 = undefined;
        for (0..5) |i| {
            _3d.rotateY(self.angle, &Pyramid.points[i], &rotateOut1);
            _3d.rotateX(0.1, &rotateOut1, &rotateOut2);
            const zFactor = SHAPE_SIZE / (2.2 * SHAPE_SIZE - rotateOut2[2]);
            _3d.projectOnXY(&rotateOut2, &self.points2d[i], zFactor);
        }
        self.angle += 0.1;
    }
};
var app = X11{};
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();
    // zguilite.init();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const frameBuffer = try app.init(allocator,"main", screen_width, screen_height, &color_bytes);
    defer app.deinit();

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    var surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);

    surface.fill_rect(rect, zguilite.COLORS.BLACK, Z_ORDER_LEVEL_0); // clear previous image

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    const ID_DESKTOP = 1;
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();

    const onIdleCallback = zguilite.WND_CALLBACK.init(&mainWnd, struct {
        fn onIdle(user: *const Main, id: i32, param: i32) !void {
            _ = user; // autofix
            _ = id;
            _ = param;

            var theCube: [SHAPE_CNT]Cube = undefined;
            // for(0..SHAPE_CNT)|i|{
            //     theCube[i] = Cube.init();
            // }
            var thePyramid: [SHAPE_CNT]Pyramid = undefined;

            while (true) {
                for (0..SHAPE_CNT) |i| {
                    const ii = @as(i32, @intCast(@as(u32, @truncate(i))));
                    theCube[i].draw(120 + ii * 240, 100, true); // erase footprint
                    theCube[i].rotate();
                    theCube[i].draw(120 + ii * 240, 100, false); // refresh cube

                    thePyramid[i].draw(120 + ii * 240, 250, true); // erase footprint
                    thePyramid[i].rotate();
                    thePyramid[i].draw(120 + ii * 240, 250, false); // refresh pyramid
                }
                try app.refresh();
                std.time.sleep(50 * std.time.ns_per_ms);
            }
        }
    }.onIdle);
    s_surface = surface;
    app.setIdleCallback(onIdleCallback);

    try app.loop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
