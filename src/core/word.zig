const std = @import("std");
const api = @import("./api.zig");
const resource = @import("./resource.zig");
const display = @import("./display.zig");
const types = @import("./types.zig");

const c_surface = display.c_surface;
const c_rect = api.c_rect;
const int = types.int;
const uint = types.uint;
const BITMAP_INFO = resource.BITMAP_INFO;
const LATTICE_FONT_INFO = resource.LATTICE_FONT_INFO;
const LATTICE = resource.LATTICE;
const GL_RGB_B = api.GL_RGB_B;
const GL_RGB_G = api.GL_RGB_G;
const GL_RGB_R = api.GL_RGB_R;
const GL_RGB = api.GL_RGB;
const GL_ARGB_A = api.GL_ARGB_A;

pub const VALUE_STR_LEN = 16;

// class c_surface;
pub const c_font_operator = struct {
    // public:
    fn draw_string(
        surface: *c_surface, //
        z_order: int,
        string: [*]const u8,
        x: int,
        y: int,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
    ) void {
        _ = surface;
        _ = z_order;
        _ = string;
        _ = x;
        _ = y;
        _ = font;
        _ = font_color;
        _ = bg_color;
    }
    fn draw_string_in_rect(
        surface: *c_surface, //
        z_order: int,
        string: [*]const u8,
        rect: c_rect,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
        align_type: int,
    ) void {
        _ = surface;
        _ = z_order;
        _ = string;
        _ = rect;
        _ = font_color;
        _ = bg_color;
        _ = font;
        _ = align_type;
    }
    fn draw_value(
        surface: *c_surface, //
        z_order: int,
        value: int,
        dot_position: int,
        x: int,
        y: int,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
    ) void {
        _ = surface;
        _ = z_order;
        _ = x;
        _ = y;
        _ = font_color;
        _ = bg_color;
        _ = font;
        _ = value;
        _ = dot_position;
    }
    fn draw_value_in_rect(
        surface: *c_surface, //
        z_order: int,
        value: int,
        dot_position: int,
        rect: c_rect,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
        align_type: int,
    ) void {
        _ = surface;
        _ = z_order;
        _ = font_color;
        _ = bg_color;
        _ = font;
        _ = value;
        _ = dot_position;
        _ = rect;
        _ = align_type;
    }
    fn get_str_size(string: [*]const u8, font: *anyopaque, width: *int, height: *int) int {
        _ = string;
        _ = font;
        _ = width;
        _ = height;
        return 0;
    }

    pub fn get_string_pos(string: [*]const u8, font: *anyopaque, rect: c_rect, align_type: int, x: *int, y: *int) void {
        var x_size: int = 0;
        var y_size: int = 0;
        _ = c_font_operator.get_str_size(string, font, &x_size, &y_size);
        const height = rect.m_bottom - rect.m_top + 1;
        const width = rect.m_right - rect.m_left + 1;
        x.* = 0;
        y.* = 0;
        switch (align_type & api.ALIGN_HMASK) {
            api.ALIGN_HCENTER => {
                //m_text_org_x=0
                if (width > x_size) {
                    x.* = @divTrunc(width - x_size, 2);
                }
            },
            api.ALIGN_LEFT => {
                x.* = 0;
            },
            api.ALIGN_RIGHT => {
                //m_text_org_x=0
                if (width > x_size) {
                    x.* = width - x_size;
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
        switch (align_type & api.ALIGN_VMASK) {
            api.ALIGN_VCENTER => {
                //m_text_org_y=0
                if (height > y_size) {
                    y.* = @divTrunc(height - y_size, 2);
                }
            },
            api.ALIGN_TOP => {
                y.* = 0;
            },
            api.ALIGN_BOTTOM => {
                //m_text_org_y=0
                if (height > y_size) {
                    y.* = height - y_size;
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
};

// class c_lattice_font_op : public c_font_operator
pub const c_lattice_font_op = struct {
    // parent: c_font_operator,

    // public:
    fn draw_string(surface: *c_surface, z_order: int, string: [*]const u8, x: int, y: int, font: ?*anyopaque, font_color: int, bg_color: uint) void {
        var s = string;
        // if (0 == s)
        // {
        // 	return;
        // }

        var offset: int = 0;
        var utf8_code: int = 0;
        while (s[0] != 0) {
            const uchar = @as(usize, @intCast(get_utf8_code(s, &utf8_code)));
            s += uchar;
            const _font: ?*LATTICE_FONT_INFO = @ptrCast(@alignCast(font));
            offset += draw_single_char(surface, z_order, utf8_code, (x + offset), y, _font, font_color, bg_color);
        }
    }

    fn draw_string_in_rect(surface: *c_surface, z_order: int, string: [*]const u8, rect: c_rect, font: ?*anyopaque, font_color: uint, bg_color: uint, align_type: uint) void {
        var x: int = 0;
        var y: int = 0;
        std.log.debug("draw_string_in_rect font:{*}", .{font});
        if (font) |_anyfont| {
            const _font: *LATTICE_FONT_INFO = @ptrCast(@alignCast(_anyfont));
            c_font_operator.get_string_pos(string, _font, rect, align_type, &x, &y);
            c_lattice_font_op.draw_string(surface, z_order, string, rect.m_left + x, rect.m_top + y, font, font_color, bg_color);
        }
    }

    fn draw_value(surface: *c_surface, z_order: int, value: int, dot_position: int, x: int, y: int, font: *anyopaque, font_color: uint, bg_color: uint) void {
        const buf: [VALUE_STR_LEN]u8 = undefined;
        const _font: *LATTICE_FONT_INFO = @ptrCast(font);
        value_2_string(value, dot_position, buf, VALUE_STR_LEN);
        c_lattice_font_op.draw_string(surface, z_order, buf, x, y, _font, font_color, bg_color);
    }

    fn draw_value_in_rect(surface: *c_surface, z_order: int, value: int, dot_position: int, rect: c_rect, font: *anyopaque, font_color: uint, bg_color: uint, align_type: uint) void {
        const buf: [VALUE_STR_LEN]u8 = undefined;
        value_2_string(value, dot_position, buf, VALUE_STR_LEN);
        const _font: *LATTICE_FONT_INFO = @ptrCast(font);
        draw_string_in_rect(surface, z_order, buf, rect, _font, font_color, bg_color, align_type);
    }

    fn get_str_size(string: [*]const u8, font: *anyopaque, width: *int, height: *int) int {
        var s = string;
        // if (null == s or null == font)
        // {
        // 	width = 0;
        //     height = 0;
        // 	return -1;
        // }

        var lattice_width: int = 0;
        var utf8_code: uint = 0;
        var utf8_bytes: usize = 0;
        const _font: *LATTICE_FONT_INFO = @ptrCast(font);
        while (s.* != 0) {
            utf8_bytes = get_utf8_code(s, &utf8_code);
            const p_lattice = get_lattice(_font, utf8_code);
            lattice_width += if (p_lattice != null) p_lattice.width else _font.height;
            s += utf8_bytes;
        }
        width = lattice_width;
        height = _font.height;
        return 0;
    }
    // private:
    fn value_2_string(value: int, dot_position: int, _buf: [*]u8, len: int) void {
        // memset(buf, 0, len);
        const buf: []u8 = _buf[0..len];
        switch (dot_position) {
            0 => {
                // sprintf(buf, "%d", value);
                std.fmt.bufPrint(buf, "{d}", .{value});
            },
            1 => {
                // sprintf(buf, "%.1f", value * 1.0 / 10);
                std.fmt.bufPrint(buf, "{.1e}", .{value * 1.0 / 10.0});
            },
            2 => {
                // sprintf(buf, "%.2f", value * 1.0 / 100);
                std.fmt.bufPrint(buf, "{.2e}", .{value * 1.0 / 100.0});
            },
            3 => {
                // sprintf(buf, "%.3f", value * 1.0 / 1000);
                std.fmt.bufPrint(buf, "{.3e}", .{value * 1.0 / 1000.0});
            },
            else => {
                api.ASSERT(false);
            },
        }
    }

    fn draw_single_char(surface: *c_surface, z_order: int, utf8_code: uint, x: int, y: int, _font: ?*LATTICE_FONT_INFO, font_color: uint, bg_color: uint) int {
        var error_color: uint = @bitCast(@as(u32, 0xFF_FF_FF_FF));
        if (_font) |font| {
            const p_lattice = get_lattice(font, utf8_code);
            if (p_lattice) |_lattice| {
                draw_lattice(surface, z_order, x, y, _lattice.width, font.height, @ptrCast(_lattice.pixel_buffer), font_color, bg_color);
                return _lattice.width;
            }
        } else {
            error_color = api.GL_RGB(255, 0, 0);
        }

        //lattice/font not found, draw "X"
        const len: int = 16;
        // for (int y_ = 0; y_ < len; y_++)
        for (0..len) |y_| {
            // for (int x_ = 0; x_ < len; x_++)
            for (0..len) |x_| {
                const diff = (x_ - y_);
                const sum = (x_ + y_);
                const ix: i32 = @truncate(@as(isize, @bitCast(x_)));
                const iy: i32 = @truncate(@as(isize, @bitCast(y_)));
                if (diff == 0 or diff == -1 or diff == 1 or sum == len or sum == (len - 1) or sum == (len + 1))
                    surface.draw_pixel((x + ix), (y + iy), error_color, @enumFromInt(z_order))
                else
                    surface.draw_pixel((x + ix), (y + iy), 0, @enumFromInt(z_order));
            }
        }
        return len;
    }

    fn draw_lattice(surface: *c_surface, z_order: int, x: int, y: int, width: int, height: int, _p_data: [*]u8, font_color: uint, bg_color: uint) void {
        var r: uint = 0;
        var g: uint = 0;
        var b: uint = 0;
        var rgb: uint = 0;
        var p_data = @constCast(_p_data);
        var blk_value = p_data[0];
        var blk_cnt = p_data[1];
        p_data += 2;
        b = (GL_RGB_B(font_color) * blk_value + GL_RGB_B(bg_color) * (255 - blk_value)) >> 8;
        g = (GL_RGB_G(font_color) * blk_value + GL_RGB_G(bg_color) * (255 - blk_value)) >> 8;
        r = (GL_RGB_R(font_color) * blk_value + GL_RGB_R(bg_color) * (255 - blk_value)) >> 8;
        rgb = GL_RGB(r, g, b);
        // for (int y_ = 0; y_ < height; y_++)
        const uheight: usize = @as(u32, @bitCast(height));
        const uwidth: usize = @as(u32, @bitCast(width));
        for (0..uheight) |y_| {
            // for (int x_ = 0; x_ < width; x_++)
            const iy: int = @truncate(@as(isize, @bitCast(y_)));
            for (0..uwidth) |x_| {
                const ix: int = @truncate(@as(isize, @bitCast(x_)));
                api.ASSERT(blk_cnt != 0);
                if (0x00 == blk_value) {
                    if (GL_ARGB_A(bg_color) != 0) {
                        surface.draw_pixel(x + ix, y + iy, bg_color, @enumFromInt(z_order));
                    }
                } else {
                    surface.draw_pixel((x + ix), (y + iy), rgb, @enumFromInt(z_order));
                }
                blk_cnt -= 1;
                if (blk_cnt == 0) { //reload new block
                    blk_value = p_data[0];
                    blk_cnt = p_data[1];
                    p_data += 2;
                    b = (GL_RGB_B(font_color) * blk_value + GL_RGB_B(bg_color) * (255 - blk_value)) >> 8;
                    g = (GL_RGB_G(font_color) * blk_value + GL_RGB_G(bg_color) * (255 - blk_value)) >> 8;
                    r = (GL_RGB_R(font_color) * blk_value + GL_RGB_R(bg_color) * (255 - blk_value)) >> 8;
                    rgb = GL_RGB(r, g, b);
                }
            }
        }
    }

    fn get_lattice(font: *LATTICE_FONT_INFO, utf8_code: uint) ?*LATTICE {
        var first: usize = 0;
        var last: usize = @as(u32, @bitCast(font.count)) - 1;
        var middle: usize = @bitCast(@divTrunc(first + last, 2));

        while (first <= last) {
            const lattice_array: [*]LATTICE = @ptrCast(font.lattice_array);
            if (lattice_array[middle].utf8_code < utf8_code) {
                first = middle + 1;
            } else if (lattice_array[middle].utf8_code == utf8_code) {
                return &lattice_array[middle];
            } else {
                last = middle - 1;
            }
            middle = (first + last) / 2;
        }
        return null;
    }

    fn get_utf8_code(s: [*]const u8, output_utf8_code: *int) int {
        const s_utf8_length_table: [256]u8 =
            .{
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, //
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
            4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 1, 1,
        };

        const us = s;
        const utf8_bytes: int = @intCast(s_utf8_length_table[us[0]]);
        const us0: i32 = @as(i32, us[0]);
        const us1: i32 = @as(i32, us[1]);
        const us2: i32 = @as(i32, us[2]);
        const us3: i32 = @as(i32, us[3]);
        switch (utf8_bytes) {
            1 => {
                output_utf8_code.* = us0;
            },
            2 => {
                output_utf8_code.* = (us0 << 8) | (us1);
            },
            3 => {
                output_utf8_code.* = (us0 << 16) | ((us1) << 8) | us2;
            },
            4 => {
                output_utf8_code.* = (us0 << 24) | ((us1) << 16) | (us2 << 8) | us3;
            },
            else => {
                api.ASSERT(false);
            },
        }
        return utf8_bytes;
    }
    fn init() void {}
};

pub const c_word = struct {
    // public:
    fn draw_string(
        surface: *c_surface, //
        z_order: int,
        string: [*]const u8,
        x: int,
        y: int,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
    ) void {
        fontOperator.draw_string(surface, z_order, string, x, y, font, font_color, bg_color);
    }
    pub fn draw_string_in_rect(
        surface: *c_surface, //
        z_order: int,
        string: [*]const u8,
        rect: c_rect,
        font: ?*anyopaque,
        font_color: int,
        bg_color: int,
        align_type: int,
    ) void {
        fontOperator.draw_string_in_rect(surface, z_order, string, rect, font, font_color, bg_color, align_type);
    }
    fn draw_value_in_rect(
        surface: *c_surface, //
        z_order: int,
        value: int,
        dot_position: int,
        rect: c_rect,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
        align_type: int,
    ) void {
        fontOperator.draw_value_in_rect(surface, z_order, value, dot_position, rect, font, font_color, bg_color, align_type);
    }
    fn draw_value(
        surface: *c_surface, //
        z_order: int,
        value: int,
        dot_position: int,
        x: int,
        y: int,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
    ) void {
        fontOperator.draw_value(surface, z_order, value, dot_position, x, y, font, font_color, bg_color);
    }
    fn get_str_size(string: [*]const u8, font: *anyopaque, width: *int, height: *int) int {
        return fontOperator.get_str_size(string, font, width, height);
    }
};

const fontOperator = blk: {
    break :blk c_lattice_font_op;
};
