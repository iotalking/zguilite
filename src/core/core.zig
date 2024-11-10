const std = @import("std");
const api = @import("./api.zig");
const theme = @import("./theme.zig");
const display = @import("./display.zig");
const image = @import("./image.zig");
// BitmapOperator the_bitmap_op = BitmapOperator();
// ImageOperator* Image::image_operator = &the_bitmap_op;

// LatticeFontOp the_lattice_font_op = LatticeFontOp();
// FontOperator* Word::fontOperator = &the_lattice_font_op;

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// defer _ = gpa.deinit();
pub const allocator = gpa.allocator();
