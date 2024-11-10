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
const Surface = display.Surface;
const int = types.int;
const uint = types.uint;

pub const Label = struct {
    wnd: Wnd = .{
        .m_class = "Label",
        .m_vtable = .{
            .on_paint = Label.on_paint,
            .pre_create_wnd = Label.pre_create_wnd,
        },
    },
    pub fn asWnd(this: *Label) *Wnd {
        const w = &this.wnd;
        return w;
    }
    // public:
    fn on_paint(w: *Wnd) !void {
        std.log.debug("label on_paint", .{});
        var rect: Rect = Rect.init();
        const bg_color = if (w.m_bg_color != 0) w.m_bg_color else w.m_parent.?.get_bg_color();
        w.get_screen_rect(&rect);
        if (w.m_str) |str| {
            if (w.m_surface) |surface| {
                const _rect = Rect.init2(rect.m_left, rect.m_top, @as(u32, @bitCast(rect.m_right)), @as(u32, @bitCast(rect.m_bottom)));
                surface.fill_rect(_rect, bg_color, w.m_z_order);
                Word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font, w.m_font_color, bg_color, api.ALIGN_LEFT | api.ALIGN_VCENTER);
            }
        }
    }
    // protected:
    fn pre_create_wnd(w: *Wnd) !void {
        w.m_attr = .ATTR_VISIBLE;
        w.m_font_color = Theme.get_color(.COLOR_WND_FONT);
        w.m_font = Theme.get_font(.FONT_DEFAULT);
    }
};
