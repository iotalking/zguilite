const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const button = @import("./button.zig");
const wave_buffer = @import("./wave_buffer.zig");
const Wnd = wnd.Wnd;
const Rect = api.Rect;
const Word = word.Word;
const Theme = theme.Theme;
const int = types.int;
const uint = types.uint;

inline fn CORRECT(x: *int, high_limit: int, low_limit: int) void {
    x.* = if (x.* > high_limit) high_limit else x.*;
    x.* = if (x.* < low_limit) low_limit else x.*;
}

const WAVE_CURSOR_WIDTH: int = 8;
const WAVE_LINE_WIDTH: int = 1;
const WAVE_MARGIN: int = 5;

pub const WaveCtrl = struct {
    wnd: wnd.Wnd = .{
        .m_class = "Table",
        .m_vtable = .{
            .on_paint = WaveCtrl.on_paint,
            .pre_create_wnd = WaveCtrl.pre_create_wnd,
            // .on_init_children = WaveCtrl.on_init_children,
        },
    },
    m_wave_name: []const u8 = "",
    m_wave_unit: []const u8 = "",

    m_wave_name_font: ?*anyopaque = null, //Theme.get_font(.FONT_DEFAULT),
    m_wave_unit_font: ?*anyopaque = null, //Theme.get_font(.FONT_DEFAULT),

    m_wave_name_color: uint = api.GL_RGB(255, 0, 0),
    m_wave_unit_color: uint = api.GL_RGB(255, 0, 0),

    m_wave_color: uint = api.GL_RGB(0, 0, 0),
    m_back_color: uint = api.GL_RGB(0, 0, 0),

    m_wave_left: int = 0,
    m_wave_right: int = 0,
    m_wave_top: int = 0,
    m_wave_bottom: int = 0,

    m_max_data: i16 = 0,
    m_min_data: i16 = 0,

    m_wave: ?*wave_buffer.WaveBuffer = null,
    m_bg_fb: ?[]uint = null, //background frame buffer, could be used to draw scale line.
    m_wave_cursor: int = 0,
    m_wave_speed: int = 0, //pixels per refresh
    m_wave_data_rate: uint = 0, //data sample rate
    m_wave_refresh_rate: uint = 0, //refresh cycle in millisecond
    m_frame_len_map: [64]u8 = std.mem.zeroes([64]u8),
    m_frame_len_map_index: u8 = 0,

    m_allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) WaveCtrl {
        const ctrl = WaveCtrl{
            .m_allocator = allocator,
        };
        return ctrl;
    }
    pub fn deinit(this: *WaveCtrl) void {
        if (this.m_bg_fb) |fb| {
            this.m_allocator.free(fb);
        }
    }
    pub fn asWnd(this: *WaveCtrl) *Wnd {
        return &this.wnd;
    }

    fn on_paint(thisWnd: *Wnd) anyerror!void {
        const this: *WaveCtrl = @fieldParentPtr("wnd", thisWnd);

        var rect = Rect.init();
        thisWnd.get_screen_rect(&rect);
        if (thisWnd.m_surface) |surface| {
            surface.fill_rect(rect, this.m_back_color, thisWnd.m_z_order);

            //show name
            api.ASSERT(this.m_wave_name_font != null);
            Word.draw_string(surface, thisWnd.m_z_order, this.m_wave_name, this.m_wave_left + 10, rect.m_top, this.m_wave_name_font.?, this.m_wave_name_color, api.GL_ARGB(0, 0, 0, 0));
            //show unit
            api.ASSERT(this.m_wave_unit_font != null);

            Word.draw_string(surface, thisWnd.m_z_order, this.m_wave_unit, this.m_wave_left + 60, rect.m_top, this.m_wave_unit_font.?, this.m_wave_unit_color, api.GL_ARGB(0, 0, 0, 0));
        }
        try this.save_background();
    }

    fn pre_create_wnd(thisWnd: *Wnd) anyerror!void {
        const this: *WaveCtrl = @fieldParentPtr("wnd", thisWnd);
        var rect = Rect.init();

        thisWnd.get_screen_rect(&rect);

        this.m_wave_left = rect.m_left + WAVE_MARGIN;
        this.m_wave_right = rect.m_right - WAVE_MARGIN;
        this.m_wave_top = rect.m_top + WAVE_MARGIN;
        this.m_wave_bottom = rect.m_bottom - WAVE_MARGIN;
        this.m_wave_cursor = this.m_wave_left;
        this.m_wave_name_font = Theme.get_font(.FONT_CUSTOM1);
        this.m_wave_unit_font = Theme.get_font(.FONT_CUSTOM1);
        this.m_bg_fb = try this.m_allocator.alloc(uint, @intCast(rect.width() * rect.height()));
    }

    pub fn set_wave_name(this: *WaveCtrl, wave_name: []const u8) void {
        this.m_wave_name = wave_name;
    }
    pub fn set_wave_unit(this: *WaveCtrl, wave_unit: []const u8) void {
        this.m_wave_unit = wave_unit;
    }

    pub fn set_wave_name_font(this: *WaveCtrl, wave_name_font_type: *const resource.LatticeFontInfo) void {
        this.m_wave_name_font = wave_name_font_type;
    }
    pub fn set_wave_unit_font(this: *WaveCtrl, wave_unit_font_type: *const resource.LatticeFontInfo) void {
        this.m_wave_unit_font = wave_unit_font_type;
    }

    pub fn set_wave_name_color(this: *WaveCtrl, wave_name_color: uint) void {
        this.m_wave_name_color = wave_name_color;
    }
    pub fn set_wave_unit_color(this: *WaveCtrl, wave_unit_color: uint) void {
        this.m_wave_unit_color = wave_unit_color;
    }
    pub fn set_wave_color(this: *WaveCtrl, color: uint) void {
        this.m_wave_color = color;
    }
    pub fn set_wave_in_out_rate(this: *WaveCtrl, data_rate: uint, refresh_rate: uint) void {
        this.m_wave_data_rate = data_rate;
        this.m_wave_refresh_rate = refresh_rate;
        if (this.m_wave_refresh_rate != 0) {
            const read_times_per_second: usize = @divFloor(@as(usize, @intCast(this.m_wave_speed * 1000)), this.m_wave_refresh_rate);

            if (read_times_per_second != 0) {
                @memset(&this.m_frame_len_map, 0);
                for (1..@as(usize, @intCast(this.m_frame_len_map.len + 1))) |i| {
                    this.m_frame_len_map[i - 1] = @as(u8, @truncate(@divFloor(data_rate * i, read_times_per_second) - @divFloor(data_rate * (i - 1), read_times_per_second)));
                }
            }
        }
        this.m_frame_len_map_index = 0;
    }
    pub fn set_wave_speed(this: *WaveCtrl, speed: uint) void {
        this.m_wave_speed = @bitCast(speed);
        this.set_wave_in_out_rate(this.m_wave_data_rate, this.m_wave_refresh_rate);
    }
    pub fn set_max_min(this: *WaveCtrl, max_data: i16, min_data: i16) void {
        this.m_max_data = max_data;
        this.m_min_data = min_data;
    }
    pub fn set_wave(this: *WaveCtrl, wave: *wave_buffer.WaveBuffer) void {
        this.m_wave = wave;
    }
    pub fn get_wave(this: *const WaveCtrl) *wave_buffer.WaveBuffer {
        return this.m_wave.?;
    }
    pub fn clear_data(this: *const WaveCtrl) void {
        if (this.m_wave == null) {
            api.ASSERT(false);
            return;
        }
        this.m_wave.?.clear_data();
    }
    pub fn is_data_enough(this: *const WaveCtrl) bool {
        if (this.m_wave == null) {
            api.ASSERT(false);
            return false;
        }
        return (this.m_wave.?.get_cnt() - this.m_frame_len_map[this.m_frame_len_map_index] * this.m_wave_speed);
    }
    pub fn refresh_wave(this: *WaveCtrl, frame: u8) !void {
        if (this.m_wave == null) {
            return error.m_wave_null;
        }

        var max: i16 = 0;
        var min: i16 = 0;
        var mid: int = 0;
        for (0..@as(usize, @intCast(this.m_wave_speed))) |offset| {
            //get wave value
            mid = this.m_wave.?.read_wave_data_by_frame(&max, &min, this.m_frame_len_map[this.m_frame_len_map_index], frame, offset);
            this.m_frame_len_map_index +%= 1;
            this.m_frame_len_map_index %= @as(u8, @truncate(this.m_frame_len_map.len));

            //map to wave ctrl
            var y_min: int = 0;
            var y_max: int = 0;
            if (this.m_max_data == this.m_min_data) {
                return error.max_eq_min;
            }
            y_max = @as(int, @intCast(this.m_wave_bottom)) + WAVE_LINE_WIDTH - @divFloor((this.m_wave_bottom - this.m_wave_top) * @as(int, @intCast((min - this.m_min_data))), @as(int, @intCast(this.m_max_data - this.m_min_data)));
            y_min = @as(int, @intCast(this.m_wave_bottom)) - WAVE_LINE_WIDTH - @divFloor((this.m_wave_bottom - this.m_wave_top) * @as(int, @intCast(max - this.m_min_data)), @as(int, @intCast((this.m_max_data - this.m_min_data))));
            mid = @as(int, @intCast(this.m_wave_bottom)) - @divFloor((this.m_wave_bottom - this.m_wave_top) * @as(int, @intCast(mid - this.m_min_data)), @as(int, @intCast(this.m_max_data - this.m_min_data)));

            CORRECT(&y_min, this.m_wave_bottom, this.m_wave_top);
            CORRECT(&y_max, this.m_wave_bottom, this.m_wave_top);
            CORRECT(&mid, this.m_wave_bottom, this.m_wave_top);

            if (this.m_wave_cursor > this.m_wave_right) {
                this.m_wave_cursor = this.m_wave_left;
            }
            this.draw_smooth_vline(y_min, y_max, mid, this.m_wave_color);
            this.restore_background();
            this.m_wave_cursor +%= 1;
        }
    }
    pub fn clear_wave(this: *WaveCtrl) void {
        if (this.wnd.m_surface) |surface| {
            surface.fill_rect(this.m_wave_left, this.m_wave_top, this.m_wave_right, this.m_wave_bottom, this.m_back_color, this.m_z_order);
            this.m_wave_cursor = this.m_wave_left;
        }
    }
    pub fn draw_smooth_vline(this: *WaveCtrl, y_min: int, y_max: int, mid: int, rgb: uint) void {
        const dy: int = y_max - y_min;
        const r = api.GL_RGB_R(rgb);
        const g = api.GL_RGB_G(rgb);
        const b = api.GL_RGB_B(rgb);
        const index: int = (dy >> 1) + 2;
        var y: int = 0;
        if (this.wnd.m_surface) |surface| {
            surface.draw_pixel(this.m_wave_cursor, mid, rgb, @enumFromInt(this.wnd.m_z_order));

            if (dy < 1) {
                return;
            }

            var cur_r: uint = 0;
            var cur_g: uint = 0;
            var cur_b: uint = 0;
            var cur_rgb: uint = 0;
            const ir: int = @intCast(r);
            const ig: int = @intCast(g);
            const ib: int = @intCast(b);
            for (1..(@as(usize, @intCast(dy)) >> 1) + 1) |i| {
                const ii: int = @truncate(@as(isize, @bitCast(i)));
                if ((mid + ii) <= y_max) {
                    y = mid + ii;
                    cur_r = @bitCast(@divFloor(ir * (index - ii), index));
                    cur_g = @bitCast(@divFloor(ig * (index - ii), index));
                    cur_b = @bitCast(@divFloor(ib * (index - ii), index));
                    cur_rgb = api.GL_RGB(cur_r, cur_g, cur_b);
                    surface.draw_pixel(this.m_wave_cursor, y, cur_rgb, @enumFromInt(this.wnd.m_z_order));
                }
                if ((mid - ii) >= y_min) {
                    y = mid - ii;
                    cur_r = @bitCast(@divFloor(ir * (index - ii), index));
                    cur_g = @bitCast(@divFloor(ig * (index - ii), index));
                    cur_b = @bitCast(@divFloor(ib * (index - ii), index));
                    cur_rgb = api.GL_RGB(cur_r, cur_g, cur_b);
                    surface.draw_pixel(this.m_wave_cursor, y, cur_rgb, @enumFromInt(this.wnd.m_z_order));
                }
            }
        }
    }
    pub fn restore_background(this: *WaveCtrl) void {
        var x = this.m_wave_cursor + WAVE_CURSOR_WIDTH;
        if (x > this.m_wave_right) {
            x -= (this.m_wave_right - this.m_wave_left + 1);
        }

        var rect = Rect.init();
        this.wnd.get_screen_rect(&rect);
        const width = @as(usize, @intCast(rect.width()));
        const top = @as(usize, @intCast(rect.m_top));
        const left = @as(usize, @intCast(rect.m_left));
        const s = @as(usize, @intCast(this.m_wave_top + 1));
        const e = @as(usize, @intCast(this.m_wave_bottom + 1));
        for (s..e) |y_pos| {
            if (this.wnd.m_surface) |m_surface| {
                if (this.m_bg_fb) |m_bg_fb| {
                    const iypos: int = @intCast(@as(u32, @truncate(y_pos)));
                    const ux: usize = @intCast(x);
                    m_surface.draw_pixel(x, iypos, m_bg_fb[(y_pos - top) * width + (ux - left)], @enumFromInt(this.wnd.m_z_order));
                } else {
                    const iypos: int = @intCast(@as(u32, @truncate(y_pos)));
                    m_surface.draw_pixel(x, iypos, 0, @enumFromInt(this.wnd.m_z_order));
                }
            }
        }
    }
    pub fn save_background(this: *WaveCtrl) !void {
        if (this.m_bg_fb == null) {
            return error.m_bg_fb_null;
        }
        var rect = Rect.init();
        this.wnd.get_screen_rect(&rect);

        var p_des = this.m_bg_fb.?;
        if (this.wnd.m_surface) |m_surface| {
            for (@as(usize, @intCast(rect.m_top))..@as(usize, @intCast(rect.m_bottom + 1))) |y| {
                for (@as(usize, @intCast(rect.m_left))..@as(usize, @intCast(rect.m_right))) |x| {
                    const ix = @as(int, @intCast(x));
                    const iy = @as(int, @intCast(y));
                    p_des[0] = try m_surface.get_pixel(ix, iy, this.wnd.m_z_order);
                    p_des = p_des[1..];
                }
            }
        }
    }
};
