const std = @import("std");
const zguilite = @import("zguilite");
const Microsoft_YaHei_28 = @import("./Microsoft_YaHei_28.zig");
const X11 = @import("x11");
const random = std.crypto.random;
const UI_WIDTH: i32 = 800; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 800; // 示例值，根据实际情况修改

const EMITTER_X: i32 = UI_WIDTH / 2;
const EMITTER_Y: i32 = UI_HEIGHT / 2;
const ACC_X: i32 = 0;
const ACC_Y: i32 = 1;
const PARTICAL_WITH: i32 = 3;
const PARTICAL_HEIGHT: i32 = 3;

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;

const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        if (w.m_surface) |surface| {
            Particle.s_surface = surface;
            var particle_array: [100]Particle = undefined;
            for (&particle_array) |*particle| {
                particle.initialize();
            }
            while (true) {
                for (&particle_array) |*particle| {
                    particle.move();
                    particle.draw();
                    try app.refresh();
                    std.log.debug("main refreshApp", .{});
                }
                // std.time.sleep(50 * std.time.ns_per_ms);
            }
        }
    }
};
const Particle = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },
    m_x: i32 = EMITTER_X,
    m_y: i32 = EMITTER_Y,
    m_x_velocity: i32 = 0,
    m_y_velocity: i32 = 0,

    var s_surface: *zguilite.Surface = undefined;

    fn initialize(this: *Particle) void {
        this.m_x = EMITTER_X;
        this.m_y = EMITTER_Y;
        this.m_x_velocity = random.intRangeAtMostBiased(i32, -3, 3);
        this.m_y_velocity = -15 - (random.intRangeAtMostBiased(i32, 0, 3));
    }
    pub fn move(self: *Particle) void {
        const rect = zguilite.Rect.init2(self.m_x, //
            self.m_y, //
            PARTICAL_WITH, //
            PARTICAL_HEIGHT);
        std.log.debug("rect {}", .{rect});
        Particle.s_surface.fill_rect(rect, zguilite.COLORS.BLACK, Z_ORDER_LEVEL_0); // clear previous image
        self.m_x_velocity += ACC_X;
        self.m_y_velocity += ACC_Y;
        self.m_x +|= self.m_x_velocity;
        self.m_y +|= self.m_y_velocity;
        if (self.m_x < 0 or ((self.m_x + PARTICAL_WITH - 1) >= UI_WIDTH) or (self.m_y < 0) or ((self.m_y + PARTICAL_HEIGHT - 1) >= UI_HEIGHT)) {
            self.initialize();
        }
    }
    pub fn draw(self: *Particle) void {
        const red = random.intRangeAtMostBiased(u8, 0, 4) * 63;
        const green = random.intRangeAtMostBiased(u8, 0, 4) * 63;
        const blue = random.intRangeAtMostBiased(u8, 0, 4) * 63;
        const rect = zguilite.Rect.init2(self.m_x, //
            self.m_y, //
            PARTICAL_WITH, //
            PARTICAL_HEIGHT);
        Particle.s_surface.fill_rect(rect, zguilite.GL_RGB(red, green, blue), Z_ORDER_LEVEL_0); // draw current image
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
    const surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    const ID_DESKTOP = 1;

    const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);

    surface.fill_rect(rect, zguilite.COLORS.BLACK, Z_ORDER_LEVEL_0); // clear previous image

    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();

    const onIdleCallback = zguilite.WND_CALLBACK.init(&mainWnd, struct {
        fn onIdle(user: *const Main, id: i32, param: i32) !void {
            _ = id;
            _ = param;
            try Main.on_paint(@constCast(&user.wnd));
        }
    }.onIdle);
    _ = onIdleCallback; // autofix
    
    try app.loop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&Microsoft_YaHei_28.Microsoft_YaHei_28)));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
