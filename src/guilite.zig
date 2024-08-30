const std = @import("std");
const api = @import("./core/api.zig");
const display = @import("./core/display.zig");
const wnd = @import("./core/wnd.zig");
const button = @import("./widgets/button.zig");
const word = @import("./core/word.zig");
const resource = @import("./core/resource.zig");
const theme = @import("./core/theme.zig");
const Lucida_Console_27 = @import("./Lucida_Console_27.zig");
pub usingnamespace api;
pub usingnamespace display;
pub usingnamespace wnd;
pub usingnamespace button;
pub usingnamespace word;
pub usingnamespace resource;
pub usingnamespace theme;

const c_theme = theme.c_theme;

pub fn init() void {
    _ = c_theme.add_font(theme.FONT_LIST.FONT_DEFAULT, @ptrCast(@constCast(&Lucida_Console_27.Lucida_Console_27)));
    _ = c_theme.add_color(theme.COLOR_LIST.COLOR_WND_FONT, api.GL_RGB(255, 255, 255));
    _ = c_theme.add_color(theme.COLOR_LIST.COLOR_WND_NORMAL, api.GL_RGB(59, 75, 94));
    _ = c_theme.add_color(theme.COLOR_LIST.COLOR_WND_PUSHED, api.GL_RGB(33, 42, 53));
    _ = c_theme.add_color(theme.COLOR_LIST.COLOR_WND_FOCUS, api.GL_RGB(43, 118, 219));
    _ = c_theme.add_color(theme.COLOR_LIST.COLOR_WND_BORDER, api.GL_RGB(46, 59, 73));
    std.log.debug("inited", .{});
}
