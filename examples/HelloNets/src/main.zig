const std = @import("std");
const zguilite = @import("zguilite");
const X11 = @import("x11");
const UI_WIDTH: i32 = 480; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 320; // 示例值，根据实际情况修改
const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;
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

const POINT_COL = 25;
const POINT_ROW = 20;
const X_SPACE = 18;
const Y_SPACE = 25;
const STRING_LENGTH = 12;

const FRICTION: f32 = 0.98;
const GRAVITY_ACC: f32 = 0.05;
const DELTA_TIME: f32 = 0.1;

var s_surface: *zguilite.Surface = undefined;
pub const c_point = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    last_x: f32,
    last_y: f32,
    fixed: bool,

    pub fn set(self: *c_point, x: f32, y: f32, fixed: bool) void {
        self.x = x;
        self.y = y;
        self.vx = 0;
        self.vy = 0;
        self.last_x = x;
        self.last_y = y;
        self.fixed = fixed;
    }

    pub fn update_location(self: *c_point, dt: f32) void {
        if (self.fixed) return;
        self.last_x = self.x;
        self.last_y = self.y;
        s_surface.draw_pixel(@intFromFloat(self.x), @intFromFloat(self.y), zguilite.GL_RGB(0, 0, 0), .Z_ORDER_LEVEL_0);
        self.vx *= FRICTION;
        self.vy *= FRICTION;
        self.x += self.vx * dt;
        self.y += self.vy * dt;
        s_surface.draw_pixel(@intFromFloat(self.x), @intFromFloat(self.y), zguilite.GL_RGB(255, 255, 255), .Z_ORDER_LEVEL_0);
    }

    pub fn distance(self: *const c_point, p: *const c_point) f32 {
        const dx = self.x - p.x;
        const dy = self.y - p.y;
        return std.math.sqrt(dx * dx + dy * dy);
    }
};
pub const c_string = struct {
    p1: *c_point,
    p2: *c_point,
    length: f32,

    pub fn init(p1: *c_point, p2: *c_point, length: f32) c_string {
        return .{
            .p1 = p1,
            .p2 = p2,
            .length = length,
        };
    }

    pub fn update_point_velocity(self: *c_string) void {
        const force = (self.p1.distance(self.p2) - self.length) / 2;
        const dx = self.p1.x - self.p2.x;
        const dy = self.p1.y - self.p2.y;
        const d = std.math.sqrt(dx * dx + dy * dy);

        const nx = dx / d;
        const ny = dy / d;

        if (!self.p1.fixed) {
            self.p1.vx -= nx * force;
            self.p1.vy -= ny * force;
            self.p1.vy += GRAVITY_ACC;
        }

        if (!self.p2.fixed) {
            self.p2.vx += nx * force;
            self.p2.vy += ny * force;
            self.p2.vy += GRAVITY_ACC;
        }
    }

    pub fn draw(self: *c_string) void {
        if (self.p1.x == self.p1.last_x and self.p1.y == self.p1.last_y and
            self.p2.x == self.p2.last_x and self.p2.y == self.p2.last_y)
        {
            return;
        }

        s_surface.draw_line(@intFromFloat(self.p1.last_x), @intFromFloat(self.p1.last_y), @intFromFloat(self.p2.last_x), @intFromFloat(self.p2.last_y), zguilite.GL_RGB(0, 0, 0), Z_ORDER_LEVEL_0);
        s_surface.draw_line(@intFromFloat(self.p1.x), @intFromFloat(self.p1.y), @intFromFloat(self.p2.x), @intFromFloat(self.p2.y), zguilite.GL_RGB(255, 255, 255), Z_ORDER_LEVEL_0);
    }
};

var points: [POINT_COL][POINT_ROW]c_point = undefined;
var strings: [((POINT_COL - 1) * POINT_ROW + POINT_COL * (POINT_ROW - 1))]c_string = undefined;

pub fn trigger(x: i32, y: i32, is_down: bool) void {
    if (is_down) {
        points[POINT_COL / 2][POINT_ROW / 2].set(@floatFromInt(x), @floatFromInt(y), true);
    } else {
        points[POINT_COL / 2][POINT_ROW / 2].set(@floatFromInt(x), @floatFromInt(y), false);
    }
}

pub fn run(exit:*bool) !void {

    // 初始化点
    for (0..POINT_ROW) |y| {
        for (0..POINT_COL) |x| {
            const fx: f32 = @floatFromInt(x);
            const fy: f32 = @floatFromInt(y);
            points[x][y].set(X_SPACE * 2 + fx * X_SPACE, Y_SPACE * 2 + fy * Y_SPACE, y == 0);
        }
    }

    // 初始化线
    var sum: usize = 0;
    for (0..POINT_ROW) |y| {
        for (0..POINT_COL - 1) |x| {
            strings[sum] = c_string.init(&points[x][y], &points[x + 1][y], STRING_LENGTH);
            sum += 1;
        }
    }
    for (0..POINT_ROW - 1) |y| {
        for (0..POINT_COL) |x| {
            strings[sum] = c_string.init(&points[x][y], &points[x][y + 1], STRING_LENGTH);
            sum += 1;
        }
    }
    std.debug.assert(sum == strings.len);

    var count: usize = 0;

    // 更新
    while (!exit.*) {
        for (0..sum) |i| {
            strings[i].update_point_velocity();
        }

        for (0..POINT_ROW) |y| {
            for (0..POINT_COL) |x| {
                points[x][y].update_location(DELTA_TIME);
            }
        }

        for (0..sum) |i| {
            strings[i].draw();
        }

        std.time.sleep(10 * std.time.ns_per_ms);

        // 自动触发（仅限MCU）
        if (count % 500 == 0) {
            trigger(0, 0, true);
            trigger(0, 0, false);
        }
        count += 1;
    }
}
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
    s_surface = surface;

    const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);

    surface.fill_rect(rect, zguilite.COLORS.BLACK, Z_ORDER_LEVEL_0); // clear previous image

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    const ID_DESKTOP = 1;
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();

    var exit = false;
    const t = try std.Thread.spawn(.{},run,.{&exit});
    defer {
        exit = true;
        t.join();
    }
    try app.loop();

    std.log.err("main exited", .{});
}

fn loadResource() !void {
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
