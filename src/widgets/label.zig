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
    wnd: c_wnd,
    pub fn asWnd(this: *c_label) *c_wnd {
        const w = &this.wnd;
        w.m_vtable.on_paint = this.on_paint;
        w.m_vtable.pre_create_wnd = this.pre_create_wnd;
        return w;
    }
    // public:
    fn on_paint(w: *c_wnd) void {
        const rect: c_rect = c_rect.init();
        const bg_color = if (w.m_bg_color) w.m_bg_color else w.m_parent.get_bg_color();
        w.get_screen_rect(rect);
        if (w.m_str) {
            w.m_surface.fill_rect(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, bg_color, w.m_z_order);
            c_word.draw_string_in_rect(w.m_surface, w.m_z_order, w.m_str, rect, w.m_font, w.m_font_color, bg_color, .ALIGN_LEFT | .ALIGN_VCENTER);
        }
    }
    // protected:
    fn pre_create_wnd(w: *c_wnd) void {
        w.m_attr = .ATTR_VISIBLE;
        w.m_font_color = c_theme.get_color(.COLOR_WND_FONT);
        w.m_font = c_theme.get_font(.FONT_DEFAULT);
    }
};
