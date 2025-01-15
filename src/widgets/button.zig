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

const WND_CALLBACK = wnd.WND_CALLBACK;
const TOUCH_ACTION = wnd.TOUCH_ACTION;
pub const Button = struct {
    wnd: wnd.Wnd = .{ .m_class = "Button", .m_vtable = .{
        .on_paint = Button.on_paint,
        .on_focus = Button.on_focus,
        .on_kill_focus = Button.on_kill_focus,
        .pre_create_wnd = Button.pre_create_wnd,
        .on_touch = Button.on_touch,
        .on_navigate = Button.on_navigate,
    } },
    on_click: ?WND_CALLBACK = null,

    pub fn asWnd(this: *Button) *wnd.Wnd {
        const w = &this.wnd;
        return w;
    }
    pub fn asButton(w: *Wnd) *Button {
        return @fieldParentPtr("wnd", w);
    }
    // public:
    // 	void set_on_click(WND_CALLBACK on_click) { this.on_click = on_click; }
    pub fn set_on_click(this: *Button, on_click: WND_CALLBACK) void {
        std.log.debug("button.set_on_click this:{*}", .{this});
        this.on_click = on_click;
    }
    // protected:
    fn on_paint(w: *Wnd) !void {
        std.log.debug("button on_paint font:{*}", .{w.m_font});
        // const this: *Button = @fieldParentPtr("wnd", w);
        var rect: Rect = Rect.init();
        w.get_screen_rect(&rect);
        std.log.debug("screen ({},{},{},{})", .{ rect.m_left, rect.m_top, rect.width(), rect.height() });

        var surface = w.m_surface.?;
        switch (w.m_status) {
            .STATUS_NORMAL => {
                surface.fill_rect(rect, Theme.get_color(.COLOR_WND_NORMAL), w.m_z_order);
                if (w.m_str) |str| {
                    Word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font, w.m_font_color, Theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            },
            .STATUS_FOCUSED => {
                surface.fill_rect(rect, Theme.get_color(.COLOR_WND_FOCUS), w.m_z_order);
                if (w.m_str) |str| {
                    Word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font, w.m_font_color, Theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            },
            .STATUS_PUSHED => {
                surface.fill_rect(rect, Theme.get_color(.COLOR_WND_PUSHED), w.m_z_order);
                surface.draw_rect(rect, Theme.get_color(.COLOR_WND_BORDER), w.m_z_order, 2);
                if (w.m_str) |str| {
                    Word.draw_string_in_rect(surface, w.m_z_order, str, rect, w.m_font.?, w.m_font_color, Theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
    fn on_focus(w: *Wnd) !void {
        w.m_status = .STATUS_FOCUSED;
        try w.on_paint();
    }
    fn on_kill_focus(w: *Wnd) !void {
        w.m_status = .STATUS_NORMAL;
        try w.on_paint();
    }
    pub fn pre_create_wnd(w: *Wnd) !void {
        const this: *Button = @fieldParentPtr("wnd", w);
        _ = this; // autofix
        // this.on_click = null;
        // std.log.debug("button pre_create_wnd set on_click = null", .{});
        w.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
        w.m_font = Theme.get_font(.FONT_DEFAULT);
        w.m_font_color = Theme.get_color(.COLOR_WND_FONT);
        std.log.debug("button pre_create_wnd font:{*} font_color:{any}", .{ w.m_font, w.m_font_color });
    }

    pub fn on_touch(w: *Wnd, x: int, y: int, action: TOUCH_ACTION) !void {
        std.log.debug("button.on_touch(x:{any},y:{any},action:{any})", .{ x, y, action });
        // _ = x;
        // _ = y;
        const this: *Button = @fieldParentPtr("wnd", w);
        std.log.debug("button on_touch this:{*}", .{this});
        if (w.m_parent == null) {
            return error.parent_null;
        }
        if (action == .TOUCH_DOWN) {
            _ = try w.m_parent.?.set_child_focus(w);
            w.m_status = .STATUS_PUSHED;
            try w.on_paint();
        } else {
            w.m_status = .STATUS_FOCUSED;
            try w.on_paint();
            if (this.on_click) |click| {
                // (m_parent.*(on_click))(m_id, 0);
                std.log.debug("button call click", .{});
                try click.on(w.m_id, 0);
            } else {
                std.log.debug("button on_touch up on_click == null", .{});
            }
        }
    }
    pub fn on_navigate(w: *Wnd, key: wnd.NAVIGATION_KEY) !void {
        std.log.debug("button.on_navigate key:{any}", .{key});
        switch (key) {
            .NAV_ENTER => {
                try on_touch(w, w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_DOWN);
                try on_touch(w, w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_UP);
            },
            .NAV_FORWARD, .NAV_BACKWARD => {},
        }
    }
};
