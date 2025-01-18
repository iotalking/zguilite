const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const Wnd = wnd.Wnd;
const Rect = api.Rect;
const Word = word.Word;
const Theme = theme.Theme;
const int = types.int;
const uint = types.uint;

pub const Bitmap = struct {
    pub fn draw_bitmap(surface: *display.Surface, z_order: int, pBitmap: *const resource.BITMAP_INFO, x: int, y: int, mask_rgb: uint) void {

        // unsigned short* lower_fb = 0;
        var lower_fb: ?*u16 = null;
        const lower_fb_width = surface.m_width;
        if (z_order >= display.Z_ORDER_LEVEL_1) {
            lower_fb = @alignCast(@ptrCast(surface.m_layers[@intCast(z_order - 1)].fb));
        }
        const mask_rgb_16 = api.GL_RGB_32_to_16(mask_rgb);
        const xsize = pBitmap.width;
        const ysize = pBitmap.height;
        var pData = pBitmap.pixel_color_array.ptr;
        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);
        for (0..ysize) |j| {
            for (0..xsize) |i| {
                const rgb = pData[0];
                pData = pData + 1;
                if (mask_rgb_16 == rgb) {
                    if (lower_fb) |_fb| { //restore lower layer
                        const fb: [*]u16 = @constCast(@ptrCast(&_fb));
                        surface.draw_pixel(@intCast(ux + i), @intCast(uy + j), api.GL_RGB_16_to_32(fb[(uy + j) * lower_fb_width + ux + i]), @enumFromInt(z_order));
                    }
                } else {
                    surface.draw_pixel(@intCast(ux + i), @intCast(uy + j), api.GL_RGB_16_to_32(rgb), @enumFromInt(z_order));
                }
            }
        }
    }
    pub fn draw_bitmap_from_rect(surface: *display.Surface, z_order: int, pBitmap: *resource.BITMAP_INFO, x: int, y: int, src_x: int, src_y: int, width: int, height: int, mask_rgb: uint) void {
        if ((src_x + width > pBitmap.width) or (src_y + height > pBitmap.height)) {
            return;
        }
        var lower_fb: ?[*]u16 = null;
        const lower_fb_width = surface.m_width;
        if (z_order >= display.Z_ORDER_LEVEL_1) {
            lower_fb = @alignCast(@ptrCast(surface.m_layers[@intCast(z_order - 1)].fb));
        }
        const mask_rgb_16 = api.GL_RGB_32_to_16(mask_rgb);
        const pData = pBitmap.pixel_color_array.ptr;
        // for (int j = 0; j < height; j++)
        for (0..@intCast(height)) |j| {
            const isrc_x = @as(usize, @intCast(src_x));
            const isrc_y = @as(usize, @intCast(src_y));
            var p = pData + isrc_x + (isrc_y + j) * pBitmap.width;
            // for (int i = 0; i < width; i++)
            for (0..@intCast(width)) |i| {
                const ij: i32 = @intCast(@as(u32, @truncate(j)));
                const ii: i32 = @intCast(@as(u32, @truncate(i)));
                // unsigned int rgb = *p++;
                const rgb = p[0];
                p = p + 1;
                if (mask_rgb_16 == rgb) {
                    if (lower_fb) |_fb| { //restore lower layer
                        const idx: usize = @intCast((y + ij) * @as(i32, @intCast(lower_fb_width)) + x + ii);
                        surface.draw_pixel(x + ii, y + ij, api.GL_RGB_16_to_32(_fb[idx]), @enumFromInt(z_order));
                    }
                } else {
                    surface.draw_pixel(x + ii, y + ij, api.GL_RGB_16_to_32(rgb), @enumFromInt(z_order));
                }
            }
        }
    }
};
