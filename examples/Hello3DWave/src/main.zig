const std = @import("std");
const zguilite = @import("zguilite");
const X11 = @import("x11");
const _3d = @import("./3d.zig");

const UI_WIDTH: i32 = 240; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 320; // 示例值，根据实际情况修改
const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;

const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },
    fn on_paint(w: *zguilite.Wnd) !void {
        _ = w; // autofix
    }
};

var app = X11{};
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const frameBuffer = try app.init(allocator, "main", screen_width, screen_height, &color_bytes);
    defer app.deinit();

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    var surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);

    surface.fill_rect(rect, zguilite.COLORS.BLACK, Z_ORDER_LEVEL_0); // clear previous image

    s_surface = surface;

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    const ID_DESKTOP = 1;
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();

    const t = try std.Thread.spawn(.{}, draw, .{surface});
    defer {
        exit = true;
        t.join();
    }
    try app.loop();
}

fn loadResource() !void {}

var exit = false;
const SPACE: u32 = 13;
const ROW: u32 = 15;
const COL: u32 = 15;
const POINT_CNT: u32 = ROW * COL;
const AMPLITUDE: f32 = 50.0;

var s_surface: *zguilite.Surface = undefined;
const Wave = struct {
    points: [POINT_CNT][3]f32,
    points2d: [POINT_CNT][2]f32,
    angle: f32,
    rotate_angle: f32,
    const fSpace: f32 = @floatFromInt(SPACE);
    const fW: f32 = @floatFromInt(UI_WIDTH);
    const fH: f32 = @floatFromInt(UI_HEIGHT);
    fn init() Wave {
        var self = Wave{
            .points = undefined,
            .points2d = undefined,
            .angle = 0.0,
            .rotate_angle = 0.0,
        };
        for (0..ROW) |y| {
            const fy: f32 = @floatFromInt(y);
            for (0..COL) |x| {
                const fx: f32 = @floatFromInt(x);
                self.points[y * COL + x][0] = fx * fSpace - fW / 2.0;
                self.points[y * COL + x][1] = fy * fSpace - fW / 2.0;
            }
        }
        return self;
    }

    fn draw(self: *Wave, x: u32, y: u32, isErase: bool) void {
        const fx: f32 = @floatFromInt(x);
        const fy: f32 = @floatFromInt(y);
        for (0..POINT_CNT) |i| {
            const factor = (1.0 + self.points[i][2] / AMPLITUDE) / 2.0;
            const color = zguilite.GL_RGB(@intFromFloat(210 * factor), @intFromFloat(130 * factor), @intFromFloat(255 * factor));
            const x0:i32 = @intFromFloat(self.points2d[i][0] + fx);
            const y0:i32 = @intFromFloat(self.points2d[i][1] + fy);
            std.log.debug("Wave draw x0:{d} y:{d}",.{x0,y0});
            if(x0 >= 0 and y0 >= 0){
                const rect = zguilite.Rect.init2(
                    x0,
                    y0,
                    4,
                    4,
                );
                std.log.debug("Wave draw rect:{any}",.{rect});
                s_surface.fill_rect(
                    rect,
                    if (isErase) 0 else color,
                    zguilite.Z_ORDER_LEVEL_0,
                );
            }
        }
    }

    fn swing(self: *Wave, rotate_angle_diff: f32) void {
        if (rotate_angle_diff == 0.0) {
            self.angle += 0.1;
            const frow:f32 = @floatFromInt(ROW);
            const fcol:f32 = @floatFromInt(COL);
            for (0..ROW) |y| {
                const fy:f32 = @floatFromInt(y);
                for (0..COL) |x| {
                    const fx:f32 = @floatFromInt(x);
                    const fxx = (fx - fcol / 2);
                    const fyy = (fy - frow / 2);
                    const offset = @sqrt(fxx * fxx + fyy * fyy) / 2.0;
                    self.points[y * COL + x][2] = @sin(self.angle + offset) * AMPLITUDE;
                }
            }
        } else {
            self.rotate_angle += rotate_angle_diff;
            if (self.rotate_angle > 1.0) {
                self.rotate_angle = 1.0;
            }
            if (self.rotate_angle < 0.0) {
                self.rotate_angle = 0.0;
            }
        }

        var rotateOut1: [3]f64 = undefined;
        for (0..POINT_CNT) |i| {
            var points: [3]f64 = undefined;
            for (0..3) |j| {
                points[j] = @floatCast(self.points[i][j]);
            }
            _3d.rotateX(self.rotate_angle, &points, &rotateOut1);
            const zFactor = @as(f32, @floatFromInt(UI_WIDTH)) / (fW - rotateOut1[2]);
            var points2d: [2]f64 = undefined;
            _3d.projectOnXY(&rotateOut1, &points2d, zFactor);
            for (0..2) |j| {
                self.points2d[i][j] = @floatCast(points2d[j]);
            }
        }
    }
};
fn draw(surface: *zguilite.Surface) void {
    _ = surface; // autofix
    var theCwave = Wave.init();
    var step: u32 = 0;
    while (!exit) {
        theCwave.draw(30 + @as(u32, @intCast(UI_WIDTH / 2)), @as(u32, @intCast(UI_HEIGHT / 2)), true);

        if (step > 400) {
            step = 0;
        } else if (step > 300) {
            theCwave.swing(-0.01);
        } else if (step > 200) {
            theCwave.swing(0.0);
        } else if (step > 100) {
            theCwave.swing(0.01);
        } else {
            theCwave.swing(0.0);
        }

        theCwave.draw(30 + @as(u32, @intCast(UI_WIDTH / 2)), @as(u32, @intCast(UI_HEIGHT / 2)), false);
        std.time.sleep(17 * std.time.ns_per_ms);
        step += 1;
    }
}
