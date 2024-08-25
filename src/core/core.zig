const std = @import("std");
const api = @import("./api.zig");
const theme = @import("./theme.zig");
const display = @import("./display.zig");
const image = @import("./image.zig");
// c_bitmap_operator the_bitmap_op = c_bitmap_operator();
// c_image_operator* c_image::image_operator = &the_bitmap_op;

// c_lattice_font_op the_lattice_font_op = c_lattice_font_op();
// c_font_operator* c_word::fontOperator = &the_lattice_font_op;

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// defer _ = gpa.deinit();
pub const allocator = gpa.allocator();
