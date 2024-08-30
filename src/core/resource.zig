const types = @import("./types.zig");
//BITMAP
pub const struct_bitmap_info = struct {
    width: u16,
    height: u16,
    color_bits: u16, //support 16 bits only
    pixel_color_array: *u16,
};
pub const BITMAP_INFO = struct_bitmap_info;

//FONT
pub const struct_lattice = struct {
    utf8_code: types.uint,
    width: u8,
    pixel_buffer: []const u8,
};
pub const LATTICE = struct_lattice;

pub const struct_lattice_font_info = struct {
    height: u8,
    count: types.uint,
    lattice_array: []const LATTICE,
};
pub const LATTICE_FONT_INFO = struct_lattice_font_info;
