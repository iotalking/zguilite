const std = @import("std");
const api = @import("./core/api.zig");
const display = @import("./core/display.zig");
const wnd = @import("./core/wnd.zig");
const button = @import("./widgets/button.zig");
const label = @import("./widgets/label.zig");
const edit = @import("./widgets/edit.zig");
const list_box = @import("./widgets/list_box.zig");
const spin_box = @import("./widgets/spinbox.zig");
const table = @import("./widgets/table.zig");
const dialog = @import("./widgets/dialog.zig");
const keyboard = @import("./widgets/keyboard.zig");
const word = @import("./core/word.zig");
const resource = @import("./core/resource.zig");
const theme = @import("./core/theme.zig");
const Lucida_Console_27 = @import("./Lucida_Console_27.zig");
const KaiTi_33B = @import("./KaiTi_33B.zig");
const Consolas_24B = @import("./Consolas_24B.zig");
const colors = @import("./core/colors.zig");
pub usingnamespace api;
pub usingnamespace display;
pub usingnamespace wnd;
pub usingnamespace button;
pub usingnamespace label;
pub usingnamespace edit;
pub usingnamespace list_box;
pub usingnamespace spin_box;
pub usingnamespace dialog;
pub usingnamespace table;
pub usingnamespace keyboard;
pub usingnamespace word;
pub usingnamespace resource;
pub usingnamespace theme;
pub usingnamespace colors;

const Theme = theme.Theme;

pub fn init() void {
    _ = Theme.add_font(theme.FONT_LIST.FONT_DEFAULT, @ptrCast(@constCast(&KaiTi_33B.KaiTi_33B)));
    _ = Theme.add_font(theme.FONT_LIST.FONT_CUSTOM1, @ptrCast(@constCast(&Consolas_24B.Consolas_24B)));
    _ = Theme.add_color(theme.COLOR_LIST.COLOR_WND_FONT, api.GL_RGB(255, 255, 255));
    _ = Theme.add_color(theme.COLOR_LIST.COLOR_WND_NORMAL, api.GL_RGB(59, 75, 94));
    _ = Theme.add_color(theme.COLOR_LIST.COLOR_WND_PUSHED, api.GL_RGB(33, 42, 53));
    _ = Theme.add_color(theme.COLOR_LIST.COLOR_WND_FOCUS, api.GL_RGB(43, 118, 219));
    _ = Theme.add_color(theme.COLOR_LIST.COLOR_WND_BORDER, api.GL_RGB(46, 59, 73));
    std.log.debug("inited", .{});
}
