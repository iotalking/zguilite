const std = @import("std");
const zguilite = @import("zguilite");

const c = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
});

const Surface = zguilite.Surface;
const Rect = zguilite.Rect;
const int = i32;
const uint = u32;
const GL_ARGB_A = zguilite.GL_ARGB_A;
const GL_RGB = zguilite.GL_RGB;
const GL_RGB_R = zguilite.GL_RGB_R;
const GL_RGB_G = zguilite.GL_RGB_G;
const GL_RGB_B = zguilite.GL_RGB_B;

fn call_c(func:anytype,args:anytype)!void{
    if(@call(.auto,func,args) != 0){
        return error.call;
    }
}
pub const FreetypeOperator = struct{
    const Self = @This();

    var library: ?c.FT_Library = null;
    
    pub fn init() !void{
        var _library: c.FT_Library = undefined;
        const ret = c.FT_Init_FreeType(&_library);
        std.log.debug("FreetypeOperator init ret:{d} lib:{*}",.{ret,_library});
        Self.library = _library;
    }
    pub fn deinit()void{
        if(Self.library)|lib|{
            _ = c.FT_Done_FreeType(lib);
            Self.library = null;
        }
    }
    pub fn set_font(filepathname: []const u8, width_px: u32, height_px: u32) !c.FT_Face {
        var face: c.FT_Face = undefined;
        const lib = Self.library orelse return error.lib;
        try call_c(c.FT_New_Face,.{lib, filepathname.ptr, 0, &face});
        try call_c(c.FT_Set_Pixel_Sizes, .{ face, width_px, height_px });
        return face;
    }
    pub fn draw_string(
        surface: *Surface, //
        z_order: int,
        string: []const u8,
        x: int,
        _y: int,
        font: ?*anyopaque,
        font_color: uint,
        bg_color: uint,
    ) !void {

        const face:c.FT_Face = @alignCast(@ptrCast(font));
        const font_height:i32 = @truncate(@divTrunc(face.*.size.*.metrics.height , 64));

        var x_ = x;
        var y = _y;
        y += font_height;

        var i: usize = 0;
        while (string[i..].len > 0 ) {
            if (string[i] == '\n') {
                std.log.debug("FreetypeOperator draw_string new line i:{d}",.{i});
                y += font_height;
                x_ = x;
                i += 1;
                continue;
            }
            const strcur = string[i..];
            var utf8_code:u32 = 0;
            const uchar = @as(usize, @intCast(zguilite.LatticeFontOp.get_utf8_code(strcur, &utf8_code)));
            std.log.debug("FreetypeOperator draw_string uchar:{d} utf8_code:{d}",.{uchar,utf8_code});
            i += uchar;
            const u16Char = try std.unicode.utf8Decode(strcur[0..uchar]);
            
            x_ += try Self.draw_single_char(surface, z_order, @intCast(u16Char), x_, y, face, font_color, bg_color);
        }
    }
    fn draw_single_char(surface: ?*zguilite.Surface, z_order: i32, code: u16, x: i32, y: i32, face: c.FT_Face, font_color: u32, bg_color: u32) !i32 {
        try call_c(c.FT_Load_Char, .{ face, code, c.FT_LOAD_RENDER });
        if (code == ' ') {
            return @truncate(@divTrunc(face.*.glyph.*.advance.x , 64));
        }
        if (surface == null) {
            return @bitCast(face.*.glyph.*.bitmap.width);
        }
        return Self.draw_lattice(surface.?, z_order, &face.*.glyph.*.bitmap, x, (y - face.*.glyph.*.bitmap_top), font_color, bg_color);
    }
    fn draw_lattice(surface: *zguilite.Surface, z_order: i32, bitmap: *c.FT_Bitmap, x: i32, y: i32, font_color: u32, bg_color: u32) i32 {
        const width = bitmap.width;
        const height = bitmap.rows;
        const e_z_order:zguilite.Z_ORDER_LEVEL = @enumFromInt(z_order);
        var i: usize = 0;
        var y_:i32 = 0;
        const fr = GL_RGB_R(font_color);
        const fg = GL_RGB_G(font_color);
        const fb = GL_RGB_B(font_color);
        const br = GL_RGB_R(bg_color);
        const bg = GL_RGB_G(bg_color);
        const bb = GL_RGB_B(bg_color);
        
        while(y_ < height):(y_ += 1) {
            var x_:i32 = 0;
            while(x_ < width):(x_ += 1){
                const grey_value = bitmap.buffer[i];
                i += 1;

                if (grey_value == 0) {
                    if (GL_ARGB_A(bg_color) != 0) {
                        surface.draw_pixel(x + x_, y + y_, bg_color, e_z_order);
                    }
                    continue;
                }

                const b = (fb * grey_value + bb * (255 - grey_value)) >> 8;
                const g = (fg * grey_value + bg * (255 - grey_value)) >> 8;
                const r = (fr * grey_value + br * (255 - grey_value)) >> 8;
                surface.draw_pixel(x + x_, y + y_, GL_RGB(r, g, b), e_z_order);
            }
        }
        return @bitCast(width);
    }
    pub fn draw_string_in_rect(surface: *zguilite.Surface, z_order: i32, string:[]const u8,rect: zguilite.Rect, font: ?*anyopaque, font_color: u32, bg_color: u32, align_type: u32) !void {

        var x: i32 = undefined;
        var y: i32 = undefined;
        try zguilite.FontOperator.get_string_pos(string, font, rect, align_type, &x, &y);
        try Self.draw_string(surface, z_order, string, rect.m_left + x, rect.m_top + y, font, font_color, bg_color);
    }
    pub fn draw_value_in_rect(
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
    fn draw_value(surface: *Surface, z_order: int, value: int, dot_position: int, x: int, y: int, font: ?*anyopaque, font_color: uint, bg_color: uint) !void {
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
    pub fn get_str_size(string: []const u8, font: ?*anyopaque, width: *i32, height: *i32) !i32 {
        const face:*c.FT_Face = @ptrCast(font);

        width.* = 0;
        height.* = (face.size.metrics.height / 64);

        var i: usize = 0;
        while (string[i] != 0) : (i += 1) {
            width.* += Self.draw_single_char(null, 0, string[i], 0, 0, face, 0, 0);
        }
        return 0;
    }
    pub fn ToFontOperator()zguilite.FontOperator{
        return .{
            .virtual_table = .{
                .draw_string = Self.draw_string,
                .draw_string_in_rect = Self.draw_string_in_rect,
                .draw_value = Self.draw_value,
                .draw_value_in_rect = Self.draw_value_in_rect,
            },
        };
    }
};