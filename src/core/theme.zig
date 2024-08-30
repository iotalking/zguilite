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

pub const c_theme = struct {
    // public:
    pub fn add_font(this: c_theme, index: FONT_LIST, font: *anyopaque) types.int {
        if (index >= .FONT_MAX) {
            api.ASSERT(false);
            return -1;
        }
        this.s_font_map[index] = font;
        return 0;
    }

    pub fn get_font(index: FONT_LIST) ?*anyopaque {
        const uindex = @intFromEnum(index);
        if (uindex >= @intFromEnum(FONT_LIST.FONT_MAX)) {
            api.ASSERT(false);
            return null;
        }
        return c_theme.s_font_map[uindex];
    }

    pub fn add_image(this: c_theme, index: IMAGE_LIST, image_info: *anyopaque) types.int {
        if (index >= .IMAGE_MAX) {
            api.ASSERT(false);
            return -1;
        }
        this.s_image_map[index] = image_info;
        return 0;
    }

    pub fn get_image(this: c_theme, index: IMAGE_LIST) *anyopaque {
        if (index >= .IMAGE_MAX) {
            api.ASSERT(false);
            return 0;
        }
        return this.s_image_map[index];
    }

    pub fn add_color(this: c_theme, index: COLOR_LIST, color: types.uint) types.int {
        if (index >= .COLOR_MAX) {
            api.ASSERT(false);
            return -1;
        }
        this.s_color_map[index] = color;
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

    // private:
    const s_font_map = std.mem.zeroes([@intFromEnum(FONT_LIST.FONT_MAX)]?*anyopaque);
    const s_image_map = std.mem.zeroes([@intFromEnum(IMAGE_LIST.IMAGE_MAX)]?*anyopaque);
    const s_color_map = std.mem.zeroes([@intFromEnum(COLOR_LIST.COLOR_MAX)]?types.uint);
};
