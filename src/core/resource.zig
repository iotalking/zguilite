const types = @import("./types.zig");
//BITMAP
pub const StructBitmapInfo = struct {
    width: u16,
    height: u16,
    color_bits: u16, //support 16 bits only
    pixel_color_array: *u16,
};
pub const BITMAP_INFO = StructBitmapInfo;

//FONT
pub const StructLattice = struct {
    utf8_code: types.uint,
    width: u8,
    pixel_buffer: []const u8,
};
pub const LATTICE = StructLattice;

pub const StructLatticeFontInfo = struct {
    height: u8,
    count: types.uint,
    lattice_array: []const LATTICE,
};
pub const LatticeFontInfo = StructLatticeFontInfo;
