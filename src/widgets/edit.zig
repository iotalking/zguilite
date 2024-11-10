const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const keyboard = @import("./keyboard.zig");
const Wnd = wnd.Wnd;
const Rect = api.Rect;
const Word = word.Word;
const Theme = theme.Theme;
const int = types.int;
const uint = types.uint;

pub const MAX_EDIT_STRLEN = 32;
pub const IDD_KEY_BOARD = 0x1;

pub const Edit = struct {
    wnd: wnd.Wnd = .{ .m_class = "Edit", .m_vtable = .{
        .on_paint = Edit.on_paint,
        .on_focus = Edit.on_focus,
        .on_kill_focus = Edit.on_kill_focus,
        .pre_create_wnd = Edit.pre_create_wnd,
        .on_touch = Edit.on_touch,
        .on_navigate = Edit.on_navigate,
    } },
    m_kb_style: keyboard.KEYBOARD_STYLE = .STYLE_ALL_BOARD,
    m_str_input: [MAX_EDIT_STRLEN]u8 = std.mem.zeroes([MAX_EDIT_STRLEN]u8),
    m_str: [MAX_EDIT_STRLEN]u8 = std.mem.zeroes([MAX_EDIT_STRLEN]u8),
    var s_keyboard: keyboard.Keyboard = .{};

    pub fn asWnd(this: *Edit) *Wnd {
        return &this.wnd;
    }
    fn get_text(this: *Edit) []const u8 {
        return this.m_str;
    }
    fn set_text(this: *Edit, str: []const u8) void {
        // std.log.err("edit set_text str len:{d}", .{str.len});
        api.strcpy(&this.m_str, str);
        // std.log.err("edit set_text m_str strlen:{d}", .{api.strlen(&this.m_str)});
    }
    fn set_keyboard_style(this: *Edit, kb_sytle: keyboard.KEYBOARD_STYLE) void {
        this.m_kb_style = kb_sytle;
    }
    fn on_touch(w: *Wnd, x: int, y: int, action: wnd.TOUCH_ACTION) !void {
        const this: *Edit = @fieldParentPtr("wnd", w);
        if (action == .TOUCH_DOWN) {
            try this.on_touch_down(x, y);
        } else {
            try this.on_touch_up(x, y);
        }
    }
    fn on_touch_down(this: *Edit, x: int, y: int) !void {
        var kb_rect_relate_2_edit_parent: Rect = undefined;
        const keyboardWnd = s_keyboard.asWnd();
        keyboardWnd.get_wnd_rect(&kb_rect_relate_2_edit_parent);

        const thisWnd = &this.wnd;
        kb_rect_relate_2_edit_parent.m_left += thisWnd.m_wnd_rect.m_left;
        kb_rect_relate_2_edit_parent.m_right += thisWnd.m_wnd_rect.m_left;
        kb_rect_relate_2_edit_parent.m_top += thisWnd.m_wnd_rect.m_top;
        kb_rect_relate_2_edit_parent.m_bottom += thisWnd.m_wnd_rect.m_top;

        if (thisWnd.m_wnd_rect.pt_in_rect(x, y)) { //click edit box
            if (.STATUS_NORMAL == thisWnd.m_status) {
                if (thisWnd.m_parent) |m_parent| {
                    _ = try m_parent.set_child_focus(thisWnd);
                }
            }
        } else if (kb_rect_relate_2_edit_parent.pt_in_rect(x, y)) { //click key board
            // 	Wnd::on_touch(x, y, TOUCH_DOWN);
            try thisWnd.on_touch(x, y, .TOUCH_DOWN);
        } else {
            if (.STATUS_PUSHED == thisWnd.m_status) {
                thisWnd.m_status = .STATUS_FOCUSED;
                try thisWnd.on_paint();
            }
        }
    }
    fn on_touch_up(this: *Edit, x: int, y: int) !void {
        const thisWnd = &this.wnd;
        if (.STATUS_FOCUSED == thisWnd.m_status) {
            thisWnd.m_status = .STATUS_PUSHED;
            try thisWnd.on_paint();
        } else if (.STATUS_PUSHED == thisWnd.m_status) {
            if (thisWnd.m_wnd_rect.pt_in_rect(x, y)) { //click edit box
                thisWnd.m_status = .STATUS_FOCUSED;
                try thisWnd.on_paint();
            } else {
                try thisWnd.on_touch(x, y, .TOUCH_UP);
            }
        }
    }
    fn on_navigate(w: *Wnd, key: wnd.NAVIGATION_KEY) !void {
        switch (key) {
            .NAV_ENTER => {
                if (w.m_status == .STATUS_PUSHED) {
                    try s_keyboard.asWnd().on_navigate(key);
                } else {
                    try w.on_touch(w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_DOWN);
                    try w.on_touch(w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_UP);
                }
            },
            .NAV_BACKWARD, .NAV_FORWARD => {
                if (w.m_status == .STATUS_PUSHED) {
                    try s_keyboard.asWnd().on_navigate(key);
                } else {
                    try w.on_navigate(key);
                }
            },
        }
    }
    fn on_kill_focus(this: *Wnd) !void {
        this.m_status = .STATUS_NORMAL;
        try this.on_paint();
    }
    fn on_focus(this: *Wnd) !void {
        this.m_status = .STATUS_FOCUSED;
        try this.on_paint();
    }
    fn on_paint(this: *Wnd) !void {
        const edit: *Edit = @fieldParentPtr("wnd", this);
        var rect = Rect.init();
        var kb_rect = Rect.init();
        this.get_screen_rect(&rect);
        const keyboard_wnd = s_keyboard.asWnd();
        keyboard_wnd.get_screen_rect(&kb_rect);
        switch (this.m_status) {
            .STATUS_NORMAL => {
                if ((keyboard_wnd.get_attr() & wnd.ATTR_VISIBLE) == wnd.ATTR_VISIBLE) {
                    s_keyboard.close_keyboard();
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
                }
                if (this.m_surface) |m_surface| {
                    // m_surface.fill_rect(rect, api.GL_RGB(255, 0, 0), this.m_z_order);
                    m_surface.fill_rect(rect, Theme.get_color(.COLOR_WND_NORMAL), this.m_z_order);
                    if (this.m_parent) |m_parent| {
                        Word.draw_string_in_rect(m_surface, m_parent.get_z_order(), &edit.m_str, rect, this.m_font, this.m_font_color, Theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    } else {
                        api.ASSERT(false);
                    }
                }
            },
            .STATUS_FOCUSED => {
                if ((keyboard_wnd.get_attr() & wnd.ATTR_VISIBLE) == wnd.ATTR_VISIBLE) {
                    s_keyboard.close_keyboard();
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
                }
                if (this.m_surface) |m_surface| {
                    m_surface.fill_rect(rect, Theme.get_color(.COLOR_WND_FOCUS), this.m_z_order);
                    if (this.m_str) |m_str| {
                        if (this.m_parent) |m_parent| {
                            Word.draw_string_in_rect(m_surface, m_parent.get_z_order(), m_str, rect, this.m_font, this.m_font_color, Theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                        } else {
                            api.ASSERT(false);
                        }
                    }
                }
            },
            .STATUS_PUSHED => {
                if ((s_keyboard.asWnd().get_attr() & wnd.ATTR_VISIBLE) != wnd.ATTR_VISIBLE) {
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS | wnd.ATTR_PRIORITY);
                    _ = try s_keyboard.open_keyboard(this, IDD_KEY_BOARD, edit.m_kb_style, wnd.WND_CALLBACK.init(edit, Edit.on_key_board_click));
                }
                if (this.m_surface) |m_surface| {
                    if (this.m_parent) |m_parent| {
                        m_surface.fill_rect(rect, Theme.get_color(.COLOR_WND_PUSHED), m_parent.get_z_order());
                        m_surface.draw_rect(rect, Theme.get_color(.COLOR_WND_BORDER), m_parent.get_z_order(), 2);
                        if (api.strlen(edit.m_str_input[0..]) > 0) {
                            Word.draw_string_in_rect(m_surface, m_parent.get_z_order(), edit.m_str_input[0..], rect, this.m_font, this.m_font_color, Theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                        } else {
                            if (this.m_str) |m_str| {
                                Word.draw_string_in_rect(m_surface, m_parent.get_z_order(), m_str, rect, this.m_font, this.m_font_color, Theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                            }
                        }
                    } else {
                        api.ASSERT(false);
                    }
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
    fn on_key_board_click(this: *Edit, id: int, param: int) !void {
        // _ = this;
        _ = id;
        // _ = param;
        const thisWnd = this.asWnd();
        const clickStatus: keyboard.CLICK_STATUS = @enumFromInt(param);
        switch (clickStatus) {
            .CLICK_CHAR => {
                api.strcpy(&this.m_str_input, s_keyboard.get_str());
                try thisWnd.on_paint();
            },
            .CLICK_ENTER => {
                if (api.strlen(&this.m_str_input) > 0) {
                    @memcpy(&this.m_str, &this.m_str_input);
                }
                thisWnd.m_status = .STATUS_FOCUSED;
                try thisWnd.on_paint();
            },
            .CLICK_ESC => {
                // memset(m_str_input, 0, sizeof(m_str_input));
                @memset(&this.m_str_input, 0);
                thisWnd.m_status = .STATUS_FOCUSED;
                try thisWnd.on_paint();
            },
        }
    }
    fn pre_create_wnd(this: *Wnd) !void {
        this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
        const edit: *Edit = @fieldParentPtr("wnd", this);
        edit.m_kb_style = .STYLE_ALL_BOARD;
        this.m_font = Theme.get_font(.FONT_CUSTOM1);
        this.m_font_color = Theme.get_color(.COLOR_WND_FONT);
        this.m_status = .STATUS_PUSHED;
        if (this.m_str) |str| {
            const strlen = api.strlen(str);
            edit.set_text(str[0..strlen]);
        }
    }
};
