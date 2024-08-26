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

const WND_CALLBACK = wnd.WND_CALLBACK;
const TOUCH_ACTION = wnd.TOUCH_ACTION;
const SURFACE_CNT_MAX = display.SURFACE_CNT_MAX;

pub const DIALOG_ARRAY = struct {
    dialog: ?*c_dialog = null,
    surface: ?*c_surface = null,
};

pub const c_dialog = struct {
    wnd: c_wnd,
    pub fn asWnd(this: *c_dialog) *c_wnd {
        const w = &this.wnd;
        w.m_vtable.on_paint = this.on_paint;
        w.m_vtable.pre_create_wnd = this.pre_create_wnd;
        return w;
    }
    // public:
    pub fn open_dialog(p_dlg: *c_dialog, modal_mode: bool) int {
        const _dlg = get_the_dialog(p_dlg.get_surface());
        if (_dlg == null) {
            return 0;
        }
        const cur_dlg = _dlg.?;
        if (cur_dlg == p_dlg) {
            return 1;
        }

        cur_dlg.wnd.set_attr(.ATTR_UNKNOWN);

        var rc: c_rect = c_rect.init();

        p_dlg.get_screen_rect(&rc);
        p_dlg.get_surface().activate_layer(rc, p_dlg.m_z_order);

        p_dlg.set_attr(if (modal_mode) .ATTR_VISIBLE | .ATTR_FOCUS | .ATTR_PRIORITY else .ATTR_VISIBLE | .ATTR_FOCUS);
        p_dlg.show_window();
        p_dlg.set_me_the_dialog();
        return 1;
    }

    pub fn close_dialog(surface: *c_surface) int {
        const _dlg = get_the_dialog(surface);

        if (null == _dlg) {
            return 0;
        }
        const dlg = _dlg.?;

        dlg.wnd.set_attr(.ATTR_UNKNOWN);
        surface.activate_layer(c_rect(), dlg.m_z_order); //inactivate the layer of dialog by empty rect.

        //clear the dialog
        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == surface) {
                ms_the_dialogs[i].dialog = null;
                return 1;
            }
        }
        api.ASSERT(false);
        return -1;
    }

    pub fn get_the_dialog(surface: *c_surface) ?*c_dialog {
        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == surface) {
                return ms_the_dialogs[i].dialog;
            }
        }
        return null;
    }
    // protected:
    fn pre_create_wnd(w: *c_wnd) void {
        w.m_attr = .ATTR_UNKNOWN; // no focus/visible
        w.m_z_order = .Z_ORDER_LEVEL_1;
        w.m_bg_color = api.GL_RGB(33, 42, 53);
    }
    fn on_paint(w: *c_wnd) void {
        var rect: c_rect = c_rect.init();
        w.get_screen_rect(&rect);
        w.m_surface.fill_rect(rect, w.m_bg_color, w.m_z_order);

        if (w.m_str) {
            c_word.draw_string(w.m_surface, w.m_z_order, w.m_str, rect.m_left + 35, rect.m_top, c_theme.get_font(.FONT_DEFAULT), api.GL_RGB(255, 255, 255), api.GL_ARGB(0, 0, 0, 0));
        }
    }
    // private:
    fn set_me_the_dialog(this: *c_dialog) int {
        const w = &this.wnd;
        const surface = w.get_surface();
        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == surface) {
                ms_the_dialogs[i].dialog = this;
                return 0;
            }
        }

        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == null) {
                ms_the_dialogs[i].dialog = this;
                ms_the_dialogs[i].surface = surface;
                return 1;
            }
        }
        api.ASSERT(false);
        return -2;
    }
    var ms_the_dialogs: [SURFACE_CNT_MAX]DIALOG_ARRAY = undefined;
};
