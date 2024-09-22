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
const int = types.int;
const uint = types.uint;

const WND_CALLBACK = wnd.WND_CALLBACK;
const TOUCH_ACTION = wnd.TOUCH_ACTION;
pub const c_button = struct {
    wnd: wnd.c_wnd = .{ .m_class = "c_button", .m_vtable = .{
        .on_paint = c_button.on_paint,
        .on_focus = c_button.on_focus,
        .on_kill_focus = c_button.on_kill_focus,
        .pre_create_wnd = c_button.pre_create_wnd,
        .on_touch = c_button.on_touch,
        .on_navigate = c_button.on_navigate,
    } },
    on_click: ?WND_CALLBACK = null,

    pub fn asWnd(this: *c_button) *wnd.c_wnd {
        const w = &this.wnd;
        return w;
    }
    // public:
    // 	void set_on_click(WND_CALLBACK on_click) { this.on_click = on_click; }
    pub fn set_on_click(this: *c_button, on_click: WND_CALLBACK) void {
        this.on_click = on_click;
    }
    // protected:
    fn on_paint(w: *c_wnd) void {
        std.log.debug("button on_paint font:{*}", .{w.m_font});
        // const this: *c_button = @fieldParentPtr("wnd", w);
        var rect: c_rect = c_rect.init();
        w.get_screen_rect(&rect);
        std.log.debug("screen ({},{},{},{})", .{ rect.m_left, rect.m_top, rect.width(), rect.height() });

        var surface = w.m_surface.?;
        switch (w.m_status) {
            .STATUS_NORMAL => {
                surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_NORMAL), w.m_z_order);
                if (w.m_str) |str| {
                    c_word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font, w.m_font_color, c_theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            },
            .STATUS_FOCUSED => {
                surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_FOCUS), w.m_z_order);
                if (w.m_str) |str| {
                    c_word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font, w.m_font_color, c_theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            },
            .STATUS_PUSHED => {
                surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_PUSHED), w.m_z_order);
                surface.draw_rect(rect, c_theme.get_color(.COLOR_WND_BORDER), 2, w.m_z_order);
                if (w.m_str) |str| {
                    c_word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font.?, w.m_font_color, c_theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
    fn on_focus(w: *c_wnd) void {
        w.m_status = .STATUS_FOCUSED;
        w.on_paint();
    }
    fn on_kill_focus(w: *c_wnd) void {
        w.m_status = .STATUS_NORMAL;
        w.on_paint();
    }
    fn pre_create_wnd(w: *c_wnd) void {
        const this: *c_button = @fieldParentPtr("wnd", w);
        this.on_click = null;
        w.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
        w.m_font = c_theme.get_font(.FONT_DEFAULT);
        w.m_font_color = c_theme.get_color(.COLOR_WND_FONT);
        std.log.debug("button pre_create_wnd font:{*} font_color:{any}", .{ w.m_font, w.m_font_color });
    }

    fn on_touch(w: *c_wnd, x: int, y: int, action: TOUCH_ACTION) void {
        _ = x;
        _ = y;
        const this: *c_button = @fieldParentPtr("wnd", w);
        if (action == .TOUCH_DOWN) {
            _ = w.m_parent.?.set_child_focus(w);
            w.m_status = .STATUS_PUSHED;
            w.on_paint();
        } else {
            w.m_status = .STATUS_FOCUSED;
            w.on_paint();
            if (this.on_click) |click| {
                // (m_parent.*(on_click))(m_id, 0);
                click(w.m_id, 0);
            }
        }
    }
    fn on_navigate(w: *c_wnd, key: wnd.NAVIGATION_KEY) void {
        switch (key) {
            .NAV_ENTER => {
                on_touch(w, w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_DOWN);
                on_touch(w, w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_UP);
            },
            .NAV_FORWARD, .NAV_BACKWARD => {},
        }
        return c_wnd.on_navigate(w, key);
    }
};
