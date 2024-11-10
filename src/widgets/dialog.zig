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
    wnd: c_wnd = .{ .m_class = "c_dialog", .m_vtable = .{
        .on_paint = c_dialog.on_paint,
        .pre_create_wnd = c_dialog.pre_create_wnd,
    } },
    pub fn new() c_dialog {
        const this = c_dialog{};
        return this;
    }
    pub fn asWnd(this: *c_dialog) *c_wnd {
        const w = &this.wnd;
        return w;
    }
    // public:
    pub fn open_dialog(p_dlg: *c_dialog, modal_mode: bool) !void {
        if (p_dlg.wnd.get_surface()) |surface| {
            if (get_the_dialog(surface)) |cur_dlg| {
                if (cur_dlg == p_dlg) {
                    return;
                }

                cur_dlg.wnd.set_attr(.ATTR_UNKNOWN);
            }
            var rc: c_rect = c_rect.init();

            p_dlg.wnd.get_screen_rect(&rc);
            surface.activate_layer(rc, p_dlg.wnd.m_z_order);

            p_dlg.wnd.set_attr(@enumFromInt(if (modal_mode) wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS | wnd.ATTR_PRIORITY else wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS));
            p_dlg.wnd.show_window();
            try p_dlg.set_me_the_dialog();
        } else {
            return error.open_dialog_surface;
        }
    }

    pub fn close_dialog(surface: *c_surface) !void {
        const _dlg = get_the_dialog(surface);
        if (_dlg) |dlg| {
            dlg.wnd.set_attr(.ATTR_UNKNOWN);
            surface.activate_layer(c_rect(), dlg.m_z_order); //inactivate the layer of dialog by empty rect.

            //clear the dialog
            // for (int i = 0; i < SURFACE_CNT_MAX; i++)
            for (0..SURFACE_CNT_MAX) |i| {
                if (ms_the_dialogs[i].surface == surface) {
                    ms_the_dialogs[i].dialog = null;
                    return;
                }
            }
        }
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
    fn pre_create_wnd(w: *c_wnd) !void {
        w.m_attr = .ATTR_UNKNOWN; // no focus/visible
        w.m_z_order = @intFromEnum(display.Z_ORDER_LEVEL.Z_ORDER_LEVEL_1);
        w.m_bg_color = api.GL_RGB(33, 42, 53);
    }
    fn on_paint(w: *c_wnd) !void {
        var rect: c_rect = c_rect.init();
        w.get_screen_rect(&rect);
        w.m_surface.?.fill_rect(rect, w.m_bg_color, w.m_z_order);

        if (w.m_str) |str| {
            if (w.m_surface) |surface| {
                if (c_theme.get_font(.FONT_DEFAULT)) |font| {
                    c_word.draw_string(surface, w.m_z_order, str, rect.m_left + 35, rect.m_top, font, api.GL_RGB(255, 255, 255), api.GL_ARGB(0, 0, 0, 0));
                }
            }
        }
    }
    // private:
    fn set_me_the_dialog(this: *c_dialog) !void {
        const w = &this.wnd;
        const surface = w.get_surface();
        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == surface) {
                ms_the_dialogs[i].dialog = this;
                return;
            }
        }

        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == null) {
                ms_the_dialogs[i].dialog = this;
                ms_the_dialogs[i].surface = surface;
                return;
            }
        }
        return error.set_me_the_dialog;
    }
    var ms_the_dialogs: [SURFACE_CNT_MAX]DIALOG_ARRAY = undefined;
};
