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

const WND_CALLBACK = wnd.WND_CALLBACK;
const TOUCH_ACTION = wnd.TOUCH_ACTION;
const SURFACE_CNT_MAX = display.SURFACE_CNT_MAX;

pub const DIALOG_ARRAY = struct {
    dialog: ?*Dialog = null,
    surface: ?*Surface = null,
};

pub const Dialog = struct {
    wnd: Wnd = .{ .m_class = "Dialog", .m_vtable = .{
        .on_paint = Dialog.on_paint,
        .pre_create_wnd = Dialog.pre_create_wnd,
    } },
    pub fn new() Dialog {
        const this = Dialog{};
        return this;
    }
    pub fn asWnd(this: *Dialog) *Wnd {
        const w = &this.wnd;
        return w;
    }
    // public:
    pub fn open_dialog(p_dlg: *Dialog, modal_mode: bool) !void {
        if (p_dlg.wnd.get_surface()) |surface| {
            if (get_the_dialog(surface)) |cur_dlg| {
                if (cur_dlg == p_dlg) {
                    return;
                }

                cur_dlg.wnd.set_attr(.ATTR_UNKNOWN);
            }
            var rc: Rect = Rect.init();

            p_dlg.wnd.get_screen_rect(&rc);
            surface.activate_layer(rc, p_dlg.wnd.m_z_order);

            p_dlg.wnd.set_attr(@enumFromInt(if (modal_mode) wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS | wnd.ATTR_PRIORITY else wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS));
            p_dlg.wnd.show_window();
            try p_dlg.set_me_the_dialog();
        } else {
            return error.open_dialog_surface;
        }
    }

    pub fn close_dialog(surface: *Surface) !void {
        const _dlg = get_the_dialog(surface);
        if (_dlg) |dlg| {
            dlg.wnd.set_attr(.ATTR_UNKNOWN);
            surface.activate_layer(Rect(), dlg.m_z_order); //inactivate the layer of dialog by empty rect.

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

    pub fn get_the_dialog(surface: *Surface) ?*Dialog {
        // for (int i = 0; i < SURFACE_CNT_MAX; i++)
        for (0..SURFACE_CNT_MAX) |i| {
            if (ms_the_dialogs[i].surface == surface) {
                return ms_the_dialogs[i].dialog;
            }
        }
        return null;
    }
    // protected:
    fn pre_create_wnd(w: *Wnd) !void {
        w.m_attr = .ATTR_UNKNOWN; // no focus/visible
        w.m_z_order = @intFromEnum(display.Z_ORDER_LEVEL.Z_ORDER_LEVEL_1);
        w.m_bg_color = api.GL_RGB(33, 42, 53);
    }
    fn on_paint(w: *Wnd) !void {
        var rect: Rect = Rect.init();
        w.get_screen_rect(&rect);
        w.m_surface.?.fill_rect(rect, w.m_bg_color, w.m_z_order);

        if (w.m_str) |str| {
            if (w.m_surface) |surface| {
                if (Theme.get_font(.FONT_DEFAULT)) |font| {
                    Word.draw_string(surface, w.m_z_order, str, rect.m_left + 35, rect.m_top, font, api.GL_RGB(255, 255, 255), api.GL_ARGB(0, 0, 0, 0));
                }
            }
        }
    }
    // private:
    fn set_me_the_dialog(this: *Dialog) !void {
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
