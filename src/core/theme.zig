const std = @import("std");
const types = @import("./types.zig");
const api = @import("./api.zig");
const resource = @import("./resource.zig");
//Rebuild gui library once you change this file
pub const FONT_LIST = enum(u16) {
    FONT_NULL, //
    FONT_DEFAULT,
    FONT_CUSTOM1,
    FONT_CUSTOM2,
    FONT_CUSTOM3,
    FONT_CUSTOM4,
    FONT_CUSTOM5,
    FONT_CUSTOM6,

    FONT_MAX,
};

pub const IMAGE_LIST = enum(u16) {
    IMAGE_CUSTOM1, //
    IMAGE_CUSTOM2,
    IMAGE_CUSTOM3,
    IMAGE_CUSTOM4,
    IMAGE_CUSTOM5,
    IMAGE_CUSTOM6,

    IMAGE_MAX,
};

pub const COLOR_LIST = enum(u16) {
    COLOR_WND_FONT, //
    COLOR_WND_NORMAL,
    COLOR_WND_PUSHED,
    COLOR_WND_FOCUS,
    COLOR_WND_BORDER,

    COLOR_CUSTOME1,
    COLOR_CUSTOME2,
    COLOR_CUSTOME3,
    COLOR_CUSTOME4,
    COLOR_CUSTOME5,
    COLOR_CUSTOME6,

    COLOR_MAX,
};

pub const BITMAP_TYPE = enum {
    BITMAP_CUSTOM1, //
    BITMAP_CUSTOM2,
    BITMAP_CUSTOM3,
    BITMAP_CUSTOM4,
    BITMAP_CUSTOM5,
    BITMAP_CUSTOM6,
    BITMAP_MAX,
};

pub const Theme = struct {
    // public:
    pub fn add_font(index: FONT_LIST, font: *anyopaque) types.int {
        std.log.debug("theme.add_font(index:{} font:{})", .{ index, font });
        const uIdx: usize = @intFromEnum(index);
        if (uIdx >= @intFromEnum(FONT_LIST.FONT_MAX)) {
            api.ASSERT(false);
            return -1;
        }
        Theme.s_font_map[uIdx] = font;
        return 0;
    }

    pub fn get_font(index: FONT_LIST) ?*anyopaque {
        const uindex = @intFromEnum(index);
        if (uindex >= @intFromEnum(FONT_LIST.FONT_MAX)) {
            api.ASSERT(false);
            return null;
        }
        std.log.debug("theme.get_font index:{any}", .{index});
        return Theme.s_font_map[uindex];
    }

    pub fn add_image(index: IMAGE_LIST, image_info: *anyopaque) types.int {
        if (@intFromEnum(index) >= @intFromEnum(IMAGE_LIST.IMAGE_MAX)) {
            api.ASSERT(false);
            return -1;
        }
        Theme.s_image_map[@intFromEnum(index)] = image_info;
        return 0;
    }

    pub fn get_image(index: IMAGE_LIST) *anyopaque {
        const uidx: usize = @intFromEnum(index);
        if (uidx >= @intFromEnum(IMAGE_LIST.IMAGE_MAX)) {
            api.ASSERT(false);
            return 0;
        }
        return s_image_map[uidx];
    }

    pub fn add_color(index: COLOR_LIST, color: types.uint) types.int {
        const uidx: usize = @intFromEnum(index);
        if (uidx >= @intFromEnum(COLOR_LIST.COLOR_MAX)) {
            api.ASSERT(false);
            return -1;
        }
        Theme.s_color_map[uidx] = color;
        return 0;
    }

    pub fn get_color(index: COLOR_LIST) types.uint {
        const uindex = @intFromEnum(index);
        if (uindex >= @intFromEnum(COLOR_LIST.COLOR_MAX)) {
            api.ASSERT(false);
            return 0;
        }
        if (s_color_map[uindex]) |c| {
            return c;
        }
        return 0;
    }
    pub fn add_bmp(index: BITMAP_TYPE, bmp: *const resource.BITMAP_INFO) !void {
        const uidx: usize = @intFromEnum(index);
        if (uidx >= @intFromEnum(COLOR_LIST.COLOR_MAX)) {
            return error.OutOfRange;
        }
        Theme.s_bmp_map[uidx] = bmp;
    }
    pub fn get_bmp(index: BITMAP_TYPE) !*const resource.BITMAP_INFO {
        const uindex = @intFromEnum(index);
        if (uindex >= @intFromEnum(BITMAP_TYPE.BITMAP_MAX)) {
            return error.OutOfRange;
        }
        const bmp = s_bmp_map[uindex];
        if (bmp) |b| {
            return b;
        }
        return error.NullBitmap;
    }
    // private:
    var s_font_map = std.mem.zeroes([@intFromEnum(FONT_LIST.FONT_MAX)]?*anyopaque);
    var s_image_map = std.mem.zeroes([@intFromEnum(IMAGE_LIST.IMAGE_MAX)]?*anyopaque);
    var s_color_map = std.mem.zeroes([@intFromEnum(COLOR_LIST.COLOR_MAX)]?types.uint);
    var s_bmp_map = std.mem.zeroes([@intFromEnum(BITMAP_TYPE.BITMAP_MAX)]?*const resource.BITMAP_INFO);
};
