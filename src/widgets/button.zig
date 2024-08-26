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
    wnd: wnd.c_wnd,
    on_click: ?WND_CALLBACK,
    pub fn asWnd(this: *c_button) *wnd.c_wnd {
        const w = &this.wnd;
        w.m_vtable.on_paint = this.on_paint;
        w.m_vtable.on_focus = this.on_focus;
        w.m_vtable.on_kill_focus = this.on_kill_focus;
        w.m_vtable.pre_create_wnd = this.pre_create_wnd;
        w.m_vtable.on_touch = this.on_touch;
        w.m_vtable.on_navigate = this.on_navigate;
        return &this.wnd;
    }
    // public:
    // 	void set_on_click(WND_CALLBACK on_click) { this.on_click = on_click; }
    pub fn set_on_click(this: *c_button, on_click: WND_CALLBACK) void {
        this.on_click = on_click;
    }
    // protected:
    fn on_paint(w: *c_wnd) void {
        // const this: *c_button = @fieldParentPtr("wnd", w);
        const rect: c_rect = c_rect.init();
        w.get_screen_rect(rect);

        switch (w.m_status) {
            .STATUS_NORMAL => {
                w.m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_NORMAL), w.m_z_order);
                if (w.m_str) {
                    c_word.draw_string_in_rect(w.m_surface, w.m_z_order, w.m_str, rect, w.m_font, w.m_font_color, c_theme.get_color(.COLOR_WND_NORMAL), .ALIGN_HCENTER | .ALIGN_VCENTER);
                }
            },
            .STATUS_FOCUSED => {
                w.m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_FOCUS), w.m_z_order);
                if (w.m_str) {
                    c_word.draw_string_in_rect(w.m_surface, w.m_z_order, w.m_str, rect, w.m_font, w.m_font_color, c_theme.get_color(.COLOR_WND_FOCUS), .ALIGN_HCENTER | .ALIGN_VCENTER);
                }
            },
            .STATUS_PUSHED => {
                w.m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_PUSHED), w.m_z_order);
                w.m_surface.draw_rect(rect, c_theme.get_color(.COLOR_WND_BORDER), 2, w.m_z_order);
                if (.m_str) {
                    c_word.draw_string_in_rect(w.m_surface, w.m_z_order, w.m_str, rect, w.m_font, w.m_font_color, c_theme.get_color(.COLOR_WND_PUSHED), .ALIGN_HCENTER | .ALIGN_VCENTER);
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
        w.m_attr = @as(wnd.WND_ATTRIBUTION, .ATTR_VISIBLE | .ATTR_FOCUS);
        w.m_font = c_theme.get_font(.FONT_DEFAULT);
        w.m_font_color = c_theme.get_color(.COLOR_WND_FONT);
    }

    fn on_touch(w: *c_wnd, x: int, y: int, action: TOUCH_ACTION) void {
        _ = x;
        _ = y;
        const this: *c_button = @fieldParentPtr("wnd", w);
        if (action == .TOUCH_DOWN) {
            w.m_parent.set_child_focus(w);
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
                on_touch(w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_DOWN);
                on_touch(w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_UP);
            },
            .NAV_FORWARD, .NAV_BACKWARD => {},
        }
        return c_wnd.on_navigate(key);
    }
};
