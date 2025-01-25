const std = @import("std");
const debug_mode = @import("builtin").mode == .Debug;
const api = @import("./api.zig");
const resource = @import("./resource.zig");
const display = @import("./display.zig");
const types = @import("./types.zig");

const Surface = display.Surface;
const Rect = api.Rect;
const int = types.int;
const uint = types.uint;
const BITMAP_INFO = resource.BITMAP_INFO;
const LatticeFontInfo = resource.LatticeFontInfo;
const LATTICE = resource.LATTICE;
const GL_RGB_B = api.GL_RGB_B;
const GL_RGB_G = api.GL_RGB_G;
const GL_RGB_R = api.GL_RGB_R;
const GL_RGB = api.GL_RGB;
const GL_ARGB_A = api.GL_ARGB_A;

pub const VALUE_STR_LEN = 16;

// class Surface;
pub const FontOperator = struct {
    const Self = @This();
    
    virtual_table: struct {
        const VTable = @This();
        // public:
        fn draw_string(
            surface: *Surface, //
            z_order: int,
            string: []const u8,
            x: int,
            y: int,
            font: ?*anyopaque,
            font_color: uint,
            bg_color: uint,
        ) !void {
            _ = surface; // autofix
            _ = z_order; // autofix
            _ = string; // autofix
            _ = x; // autofix
            _ = y; // autofix
            _ = font; // autofix
            _ = font_color; // autofix
            _ = bg_color; // autofix
        }
        fn draw_string_in_rect(
            surface: *Surface, //
            z_order: int,
            string: []const u8,
            rect: Rect,
            font: ?*anyopaque,
            font_color: uint,
            bg_color: uint,
            align_type: uint,
        ) !void {
            _ = surface; // autofix
            _ = z_order; // autofix
            _ = string; // autofix
            _ = rect; // autofix
            _ = font; // autofix
            _ = font_color; // autofix
            _ = bg_color; // autofix
            _ = align_type; // autofix
        }
        fn draw_value(
            surface: *Surface, //
            z_order: int,
            value: int,
            dot_position: int,
            x: int,
            y: int,
            font: ?*anyopaque,
            font_color: uint,
            bg_color: uint,
        ) !void {
            _ = surface; // autofix
            _ = z_order; // autofix
            _ = value; // autofix
            _ = dot_position; // autofix
            _ = x; // autofix
            _ = y; // autofix
            _ = font; // autofix
            _ = font_color; // autofix
            _ = bg_color; // autofix
        }
        fn draw_value_in_rect(
            surface: *Surface, //
            z_order: int,
            value: int,
            dot_position: int,
            rect: Rect,
            font: ?*anyopaque,
            font_color: uint,
            bg_color: uint,
            align_type: uint,
        ) !void {
            _ = surface; // autofix
            _ = z_order; // autofix
            _ = value; // autofix
            _ = dot_position; // autofix
            _ = rect; // autofix
            _ = font; // autofix
            _ = font_color; // autofix
            _ = bg_color; // autofix
            _ = align_type; // autofix
        }
        fn get_str_size(string: []const u8, font: ?*anyopaque, width: *i32, height: *i32) !i32{
            _ = string; // autofix
            _ = font; // autofix
            _ = width; // autofix
            _ = height; // autofix
            return 0;
        }

        draw_string: *const fn (
            surface: *Surface,
            z_order: int,
            string: []const u8,
            x: int,
            y: int,
            font: ?*anyopaque,
            font_color: uint,
            bg_color: uint,
        ) anyerror!void = VTable.draw_string,
        draw_string_in_rect:*const fn (surface: *Surface, z_order: i32, string: []const u8, rect: Rect, font: ?*anyopaque, font_color: u32, bg_color: u32, align_type: u32) anyerror!void = VTable.draw_string_in_rect,
        get_str_size:*const fn (string: []const u8, font: ?*anyopaque, width: *i32, height: *i32) anyerror!i32 = VTable.get_str_size,
        draw_value:*const fn (surface: *Surface, z_order: i32, value: i32, dot_position: i32, x: i32, y: i32, font: ?*anyopaque, font_color: u32, bg_color: u32) anyerror!void = VTable.draw_value,
        draw_value_in_rect:*const fn (surface: *Surface, z_order: i32, value: i32, dot_position: i32, rect: Rect, font: ?*anyopaque, font_color: u32, bg_color: u32, align_type: u32) anyerror!void = VTable.draw_value_in_rect,
    },

    // public:
    fn draw_string(
        self:*Self,
        surface: *Surface, //
        z_order: int,
        string: []const u8,
        x: int,
        y: int,
        font: ?*anyopaque,
        font_color: uint,
        bg_color: uint,
    ) !void {
        return self.virtual_table.draw_string(surface,z_order,string,x,y,font,font_color,bg_color);
    }
    fn draw_string_in_rect(
        self:*Self,
        surface: *Surface, //
        z_order: int,
        string: []const u8,
        rect: Rect,
        font: ?*anyopaque,
        font_color: uint,
        bg_color: uint,
        align_type: uint,
    ) !void {
        return self.virtual_table.draw_string_in_rect(surface,z_order,string,rect,font,font_color,bg_color,align_type);   
    }
    fn draw_value(
        self:*Self,
        surface: *Surface, //
        z_order: int,
        value: int,
        dot_position: int,
        x: int,
        y: int,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
    ) !void {
        return self.virtual_table.draw_value(surface,z_order,value,dot_position,x,y,font,font_color,bg_color);
    }
    fn draw_value_in_rect(
        self:*Self,
        surface: *Surface, //
        z_order: int,
        value: int,
        dot_position: int,
        rect: Rect,
        font: *anyopaque,
        font_color: int,
        bg_color: int,
        align_type: int,
    ) !void {
        return self.virtual_table.draw_value_in_rect(surface,z_order,value,dot_position,rect,font,font_color,bg_color,align_type);
    }
    fn get_str_size(
        self:*Self,
        string: []const u8, font: ?*anyopaque, width: *int, height: *int) !int {
        return self.virtual_table.get_str_size(string,font,width,height);
    }

    pub fn get_string_pos(string: []const u8, font: ?*anyopaque, rect: Rect, align_type: uint, x: *int, y: *int) !void {
        var x_size: int = 0;
        var y_size: int = 0;
        _ = try fontOperator.get_str_size(string, font, &x_size, &y_size);
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
                    std.log.debug("get_string_pos height:{d} y_size:{d}", .{ height, y_size });
                    y.* = @divTrunc(height - y_size, 2);
                }
            },
            api.ALIGN_TOP => {
                y.* = 0;
            },
            api.ALIGN_BOTTOM => {
                //m_text_org_y=0
                if (height > y_size) {
                    std.log.debug("get_string_pos height:{d} y_size:{d}", .{ height, y_size });
                    y.* = height - y_size;
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
};

// class LatticeFontOp : public FontOperator
pub const LatticeFontOp = struct {
    const Self = @This();
    // public:
    fn draw_string(surface: *Surface, z_order: int, string: []const u8, x: int, y: int, font: ?*anyopaque, font_color: uint, bg_color: uint) !void {
        var offset: usize = 0;
        var strcur = string[offset..];
        var xoffset: int = 0;
        var utf8_code: uint = 0;
        while (strcur.len > 0) {
            const uchar = @as(usize, @intCast(get_utf8_code(strcur, &utf8_code)));
            offset += uchar;
            strcur = string[offset..];
            const _font: ?*LatticeFontInfo = @ptrCast(@alignCast(font));
            xoffset += draw_single_char(surface, z_order, utf8_code, (x + xoffset), y, _font, font_color, bg_color);
        }
    }

    fn draw_string_in_rect(surface: *Surface, z_order: int, string: []const u8, rect: Rect, font: ?*anyopaque, font_color: uint, bg_color: uint, align_type: uint) !void {
        var x: int = 0;
        var y: int = 0;
        std.log.debug("draw_string_in_rect font:{*}", .{font});
        if (font) |_anyfont| {
            const _font: *LatticeFontInfo = @ptrCast(@alignCast(_anyfont));
            try FontOperator.get_string_pos(string, _font, rect, align_type, &x, &y);
            std.log.debug("draw_string_in_rect ({d},{d}) ({d},{d})", .{ rect.m_left, rect.m_top, x, y });
            if (debug_mode) {
                var textRect = rect;
                textRect.m_left += x;
                textRect.m_top += y;
                surface.draw_rect(textRect, api.GL_RGB(0, 0, 255), 0, 1);
            }
            try LatticeFontOp.draw_string(surface, z_order, string, rect.m_left + x, rect.m_top + y, font, font_color, bg_color);
        }
    }

    fn draw_value(surface: *Surface, z_order: int, value: int, dot_position: int, x: int, y: int, font: ?*anyopaque, font_color: uint, bg_color: uint) !void {
        var buf: [VALUE_STR_LEN]u8 = undefined;
        const _font: *LatticeFontInfo = @alignCast(@ptrCast(font));
        try value_2_string(value, dot_position, &buf);
        try LatticeFontOp.draw_string(surface, z_order, &buf, x, y, _font, font_color, bg_color);
    }

    fn draw_value_in_rect(surface: *Surface, z_order: int, value: int, dot_position: int, rect: Rect, font: ?*anyopaque, font_color: uint, bg_color: uint, align_type: uint) !void {
        var buf: [VALUE_STR_LEN]u8 = undefined;
        try value_2_string(value, dot_position, &buf);

        const _font: *LatticeFontInfo = @alignCast(@ptrCast(@constCast(font)));
        try draw_string_in_rect(surface, z_order, &buf, rect, _font, font_color, bg_color, align_type);
    }

    fn get_str_size(string: []const u8, font: ?*anyopaque, width: *int, height: *int) !int {
        var offset: usize = 0;
        var strcur = string[offset..];
        var lattice_width: int = 0;
        var utf8_code: uint = 0;
        var utf8_bytes: usize = 0;
        const _font: *LatticeFontInfo = @alignCast(@ptrCast(font));
        while (strcur.len > 0) {
            // std.log.debug("strcur:{s}", .{strcur});
            utf8_bytes = @as(u32, @bitCast(get_utf8_code(strcur, &utf8_code)));
            // std.log.debug("utf8_code:{x}", .{utf8_code});
            const p_lattice = get_lattice(_font, utf8_code);
            if (p_lattice) |lattice| {
                lattice_width += lattice.width;
            } else {
                lattice_width += _font.height;
            }
            offset += utf8_bytes;
            strcur = string[offset..];
        }
        width.* = lattice_width;
        height.* = _font.height;
        return 0;
    }
    // private:
    fn value_2_string(value: int, dot_position: int, _buf: []u8) !void {
        // memset(buf, 0, len);
        const buf: []u8 = _buf;
        switch (dot_position) {
            0 => {
                // sprintf(buf, "%d", value);
                _ = try std.fmt.bufPrint(buf, "{d}", .{value});
            },
            1 => {
                // sprintf(buf, "%.1f", value * 1.0 / 10);
                const v = @divExact(@as(f32, @bitCast(value)) * 1.0, 10.0);
                _ = try std.fmt.bufPrint(buf, "{e:.1}", .{v});
            },
            2 => {
                const v = @divExact(@as(f32, @bitCast(value)) * 1.0, 100.0);
                _ = try std.fmt.bufPrint(buf, "{e:.2}", .{v});
            },
            3 => {
                const v = @divExact(@as(f32, @bitCast(value)) * 1.0, 1000.0);
                _ = try std.fmt.bufPrint(buf, "{e:.3}", .{v});
            },
            else => {
                api.ASSERT(false);
            },
        }
    }

    fn draw_single_char(surface: *Surface, z_order: int, utf8_code: uint, x: int, y: int, _font: ?*LatticeFontInfo, font_color: uint, bg_color: uint) int {
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
                const diff = (x_ -% y_);
                const sum = (x_ +| y_);
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

    fn draw_lattice(surface: *Surface, z_order: int, x: int, y: int, width: int, height: int, _p_data: [*]const u8, font_color: uint, bg_color: uint) void {
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

    fn get_lattice(font: *LatticeFontInfo, utf8_code: uint) ?*const LATTICE {
        var first: usize = 0;
        var last: usize = @as(u32, @bitCast(font.count)) - 1;
        var middle: usize = (first + last) / 2;
        while (first <= last and middle >= 0) {

            // std.log.debug("get_lattice middle:{d}", .{middle});
            const lattice_array: []const LATTICE = font.lattice_array;
            if (lattice_array[middle].utf8_code < utf8_code) {
                if (middle == last) {
                    break;
                }
                first = middle + 1;
            } else if (lattice_array[middle].utf8_code == utf8_code) {
                return &lattice_array[middle];
            } else {
                if (middle == first) {
                    break;
                }
                last = middle - 1;
            }
            middle = (first + last) / 2;
        }
        return null;
    }

    pub fn get_utf8_code(s: []const u8, output_utf8_code: *uint) int {
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
        const us0: u32 = @as(u32, us[0]);
        switch (utf8_bytes) {
            1 => {
                output_utf8_code.* = us0;
            },
            2 => {
                const us1: u32 = @as(u32, us[1]);
                output_utf8_code.* = (us0 << 8) | (us1);
            },
            3 => {
                const us1: u32 = @as(u32, us[1]);
                const us2: u32 = @as(u32, us[2]);
                output_utf8_code.* = (us0 << 16) | ((us1) << 8) | us2;
            },
            4 => {
                const us1: u32 = @as(u32, us[1]);
                const us2: u32 = @as(u32, us[2]);
                const us3: u32 = @as(u32, us[3]);
                output_utf8_code.* = (us0 << 24) | ((us1) << 16) | (us2 << 8) | us3;
            },
            else => {
                api.ASSERT(false);
            },
        }
        return utf8_bytes;
    }
    fn init() void {}

    fn ToFontOperator()FontOperator{
        return FontOperator{
            .virtual_table = .{
                .draw_string = Self.draw_string,
                .draw_string_in_rect = Self.draw_string_in_rect,
                .get_str_size = Self.get_str_size,
                .draw_value = Self.draw_value,
                .draw_value_in_rect = Self.draw_value_in_rect,
            },
        };
    }
};

pub const Word = struct {
    // public:
    pub fn draw_string(
        surface: *Surface, //
        z_order: int,
        string: []const u8,
        x: int,
        y: int,
        font: ?*anyopaque,
        font_color: uint,
        bg_color: uint,
    ) void {
        fontOperator.draw_string(surface, z_order, string, x, y, font, font_color, bg_color)  catch |e| {
            std.log.err("Word draw_string error {any}",.{e});
        };
    }
    pub fn draw_string_in_rect(
        surface: *Surface, //
        z_order: int,
        string: []const u8,
        rect: Rect,
        font: ?*anyopaque,
        font_color: uint,
        bg_color: uint,
        align_type: uint,
    ) void {
        std.log.debug("word draw_string_in_rect string:{s}", .{string});
        fontOperator.draw_string_in_rect(surface, z_order, string, rect, font, font_color, bg_color, align_type) catch |e|{
            std.log.err("Word draw_string_in_rect error:{any}",.{e});
            return ;
        };
    }
    pub fn draw_value_in_rect(
        surface: *Surface, //
        z_order: int,
        value: int,
        dot_position: int,
        rect: Rect,
        font: ?*anyopaque,
        font_color: int,
        bg_color: int,
        align_type: int,
    ) !void {
        try fontOperator.draw_value_in_rect(surface, z_order, value, dot_position, rect, font, font_color, bg_color, align_type);
    }
    fn draw_value(
        surface: *Surface, //
        z_order: int,
        value: int,
        dot_position: int,
        x: int,
        y: int,
        font: ?*anyopaque,
        font_color: int,
        bg_color: int,
    ) void {
        fontOperator.draw_value(surface, z_order, value, dot_position, x, y, font, font_color, bg_color);
    }
    fn get_str_size(string: [*]const u8, font: ?*anyopaque, width: *int, height: *int) int {
        return fontOperator.get_str_size(string, font, width, height);
    }
};



pub var fontOperator:FontOperator = LatticeFontOp.ToFontOperator();