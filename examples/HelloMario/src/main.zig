const std = @import("std");
const zguilite = @import("zguilite");
const x11 = @import("x11");
const UI_WIDTH: i32 = 240; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 320; // 示例值，根据实际情况修改
const UI_BOTTOM_HEIGHT = 76;

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;
const Z_ORDER_LEVEL_1 = zguilite.Z_ORDER_LEVEL_1;
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

const MARIO_WIDTH: i32 = 16;
const MARIO_HEIGHT: i32 = 32;
const FULL_STEP: i32 = 9;
const MARIO_INIT_X: i32 = 0;
const MARIO_INIT_Y: i32 = (UI_BOTTOM_HEIGHT - 1);
const RYU_X: i32 = 85;
const RYU_Y: i32 = 90;
const ACC_X: i32 = 0;
const ACC_Y: i32 = 1;
const BITMAP_INFO = zguilite.BITMAP_INFO;
const Surface = zguilite.Surface;
const Theme = zguilite.Theme;
const Bitmap = zguilite.Bitmap;
const Rect = zguilite.Rect;

const title_bmp: BITMAP_INFO = @import("./title_bmp.zig").title_bmp;
const background_bmp: BITMAP_INFO = @import("./background_bmp.zig").background_bmp;
const step1_bmp: BITMAP_INFO = @import("./step1_bmp.zig").step1_bmp;
const step2_bmp: BITMAP_INFO = @import("./step2_bmp.zig").step2_bmp;
const step3_bmp: BITMAP_INFO = @import("./step3_bmp.zig").step3_bmp;
const jump_bmp: BITMAP_INFO = @import("./jump_bmp.zig").jump_bmp;
const frame_00_bmp: BITMAP_INFO = @import("./frame_00_bmp.zig").frame_00_bmp;
const frame_01_bmp: BITMAP_INFO = @import("./frame_01_bmp.zig").frame_01_bmp;
const frame_02_bmp: BITMAP_INFO = @import("./frame_02_bmp.zig").frame_02_bmp;
const frame_03_bmp: BITMAP_INFO = @import("./frame_03_bmp.zig").frame_03_bmp;
const frame_04_bmp: BITMAP_INFO = @import("./frame_04_bmp.zig").frame_04_bmp;
const frame_05_bmp: BITMAP_INFO = @import("./frame_05_bmp.zig").frame_05_bmp;
const frame_06_bmp: BITMAP_INFO = @import("./frame_06_bmp.zig").frame_06_bmp;
const frame_07_bmp: BITMAP_INFO = @import("./frame_07_bmp.zig").frame_07_bmp;
const frame_08_bmp: BITMAP_INFO = @import(".//frame_08_bmp.zig").frame_08_bmp;
const frame_09_bmp: BITMAP_INFO = @import("./frame_09_bmp.zig").frame_09_bmp;
const frame_10_bmp: BITMAP_INFO = @import("./frame_10_bmp.zig").frame_10_bmp;
const frame_11_bmp: BITMAP_INFO = @import("./frame_11_bmp.zig").frame_11_bmp;
const frame_12_bmp: BITMAP_INFO = @import("./frame_12_bmp.zig").frame_12_bmp;
const frame_13_bmp: BITMAP_INFO = @import("./frame_13_bmp.zig").frame_13_bmp;

const s_frames = [_]BITMAP_INFO{
    frame_00_bmp, frame_01_bmp, frame_02_bmp, frame_03_bmp, frame_04_bmp, frame_05_bmp,
    frame_06_bmp, frame_07_bmp, frame_08_bmp, frame_09_bmp, frame_10_bmp, frame_11_bmp,
    frame_12_bmp, frame_13_bmp,
};

var s_surface_top: *Surface = undefined;
var s_surface_bottom: *Surface = undefined;

fn draw_easter_egg() !void {
    for (s_frames) |frame| {
        try Theme.add_bmp(.BITMAP_CUSTOM1, &frame);
        try Bitmap.draw_bitmap(s_surface_top, Z_ORDER_LEVEL_0, try Theme.get_bmp(.BITMAP_CUSTOM1), RYU_X, RYU_Y, 0x5588DD);
        try x11.refreshApp();
        std.time.sleep(20 * std.time.ns_per_ms);
    }
    const rect = Rect.init2(RYU_X, RYU_Y, RYU_X + frame_00_bmp.width - 1, RYU_Y + frame_00_bmp.height - 1);
    s_surface_top.fill_rect(rect, 0x836E53, Z_ORDER_LEVEL_0);
}

const c_mario = struct {
    x: i32,
    y: i32,
    x_velocity: i32,
    y_velocity: i32,
    step: u32,
    is_jump: bool,

    pub fn init() c_mario {
        return .{
            .x = MARIO_INIT_X,
            .y = MARIO_INIT_Y,
            .x_velocity = 3,
            .y_velocity = 0,
            .step = 0,
            .is_jump = false,
        };
    }

    pub fn jump(self: *c_mario) void {
        self.is_jump = true;
        self.y_velocity = -9;
    }

    pub fn move(self: *c_mario) !void {
        if (self.step == FULL_STEP) {
            self.step = 0;
        }
        self.step += 1;
        self.x_velocity += ACC_X;
        self.x += self.x_velocity;
        if (self.is_jump) {
            self.y_velocity += ACC_Y;
            self.y += self.y_velocity;
        }
        if (self.x + MARIO_WIDTH - 1 >= UI_WIDTH) {
            self.x = 0;
        }
        if (self.y >= UI_BOTTOM_HEIGHT) {
            self.y = MARIO_INIT_Y;
            self.y_velocity = 0;
            self.is_jump = false;
        }
        if (self.y < MARIO_HEIGHT) {
            self.y = MARIO_HEIGHT;
            self.y_velocity = 0;
        }

        // Just joking
        if (self.x == 93) {
            self.jump();
        }
        if (self.x == 117) {
            try draw_easter_egg();
        }
    }

    pub fn draw(self: *c_mario) !void {
        const mario_bmp: *const BITMAP_INFO = if (self.is_jump) &jump_bmp else if (self.step < (FULL_STEP / 3)) &step1_bmp else if (self.step < (FULL_STEP * 2 / 3)) &step2_bmp else &step3_bmp;
        const mario_rect = Rect.init2(self.x, self.y - @as(i32, @intCast(mario_bmp.height)), @as(u32, @intCast(self.x)) + mario_bmp.width - 1, @as(u32, @intCast(self.y)));
        s_surface_bottom.activate_layer(mario_rect, Z_ORDER_LEVEL_1);
        try Bitmap.draw_bitmap(s_surface_bottom, Z_ORDER_LEVEL_1, mario_bmp, self.x, self.y - mario_bmp.height, 0xFFFFFF);
    }
};

var frameBuffer: []u8 = undefined;

fn draw_pixel(x: i32, _y: i32, rgb: u32) void {
    std.log.debug("main draw_pixel ({},{})", .{ x, _y });
    var y = _y;
    y += 244;

    const phy_fb: [*]u32 = @alignCast(@ptrCast(frameBuffer.ptr));
    phy_fb[@intCast(y * UI_WIDTH + x)] = (rgb);
}
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();
    // zguilite.init();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    frameBuffer = try x11.createFrameBuffer(allocator, screen_width, screen_height, &color_bytes);
    defer allocator.free(frameBuffer);

    var _display_top: zguilite.Display = .{};
    try _display_top.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, (screen_height - UI_BOTTOM_HEIGHT), color_bytes, 1, null);
    s_surface_top = try _display_top.allocSurface(.Z_ORDER_LEVEL_0, zguilite.Rect.init2(0, 0, screen_width, (screen_height - UI_BOTTOM_HEIGHT)));
    s_surface_top.set_active(true);
    var rect = Rect.init2(0, 0, UI_WIDTH, screen_height - UI_BOTTOM_HEIGHT);
    s_surface_top.fill_rect(rect, zguilite.GL_RGB(131, 110, 83), Z_ORDER_LEVEL_0);
    try Bitmap.draw_bitmap(s_surface_top, Z_ORDER_LEVEL_0, &title_bmp, 30, 20, zguilite.DEFAULT_MASK_COLOR);
    _ = &rect;

    var _display_bottom: zguilite.Display = .{};
    try _display_bottom.init2(frameBuffer.ptr, screen_width, screen_height, UI_WIDTH, (UI_BOTTOM_HEIGHT), color_bytes, 1, &.{
        .draw_pixel = draw_pixel,
        .fill_rect = null,
    });
    s_surface_bottom = try _display_bottom.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, (UI_BOTTOM_HEIGHT)));
    s_surface_bottom.set_active(true);
    rect = Rect.init2(0, 0, UI_WIDTH, UI_BOTTOM_HEIGHT);
    s_surface_bottom.fill_rect(rect, 0, Z_ORDER_LEVEL_0);
    try Bitmap.draw_bitmap(s_surface_bottom, Z_ORDER_LEVEL_0, &background_bmp, 3, 0, zguilite.DEFAULT_MASK_COLOR);

    x11.onIdleCallback = zguilite.WND_CALLBACK.init(s_surface_top, struct {
        fn onIdle(user: *const Main, id: i32, param: i32) !void {
            _ = user; // autofix
            _ = id;
            _ = param;
            var mario = c_mario.init();
            while (true) {
                try mario.draw();
                try mario.move();
                try x11.refreshApp();
                std.time.sleep(50 * std.time.ns_per_ms);
            }
        }
    }.onIdle);
    try x11.appLoop();

    std.log.err("main exited", .{});
}

fn loadResource() !void {
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
