const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const c_wnd = wnd.c_wnd;
const c_rect = api.c_rect;
const c_word = word.c_word;
const c_theme = theme.c_theme;
const c_surface = display.c_surface;
const int = types.int;
const uint = types.uint;

pub const c_label = struct {
    wnd: c_wnd = .{
        .m_class = "c_label",
    },
    pub fn asWnd(this: *c_label) *c_wnd {
        const w = &this.wnd;
        w.m_vtable.on_paint = c_label.on_paint;
        w.m_vtable.pre_create_wnd = c_label.pre_create_wnd;
        return w;
    }
    // public:
    fn on_paint(w: *c_wnd) void {
        std.log.debug("label on_paint", .{});
        var rect: c_rect = c_rect.init();
        const bg_color = if (w.m_bg_color != 0) w.m_bg_color else w.m_parent.?.get_bg_color();
        w.get_screen_rect(&rect);
        if (w.m_str) |str| {
            if (w.m_surface) |surface| {
                const _rect = c_rect.init2(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom);
                surface.fill_rect(_rect, bg_color, w.m_z_order);
                c_word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font, w.m_font_color, bg_color, api.ALIGN_LEFT | api.ALIGN_VCENTER);
            }
        }
    }
    // protected:
    fn pre_create_wnd(w: *c_wnd) void {
        w.m_attr = .ATTR_VISIBLE;
        w.m_font_color = c_theme.get_color(.COLOR_WND_FONT);
        w.m_font = c_theme.get_font(.FONT_DEFAULT);
    }
};
