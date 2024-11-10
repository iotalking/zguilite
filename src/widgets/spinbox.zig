const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const button = @import("./button.zig");
const Wnd = wnd.Wnd;
const c_rect = api.c_rect;
const c_word = word.c_word;
const Theme = theme.Theme;
const int = types.int;
const uint = types.uint;

const ID_BT_ARROW_UP = 0x1111;
const ID_BT_ARROW_DOWN = 0x2222;
pub const SpinBox = struct {
    wnd: wnd.Wnd = .{ .m_class = "SpinBox", .m_vtable = .{
        .on_paint = SpinBox.on_paint,
        .pre_create_wnd = SpinBox.pre_create_wnd,
    } },
    m_cur_value: u16 = 0,
    m_value: u16 = 0,
    m_step: u16 = 0,
    m_max: u16 = 0,
    m_min: u16 = 0,
    m_digit: u16 = 0,
    m_bt_up: c_spin_button = .{},
    m_bt_down: c_spin_button = .{},
    on_change: ?wnd.WND_CALLBACK = null,

    pub fn asWnd(this: *SpinBox) *Wnd {
        return &this.wnd;
    }

    fn get_value(this: *SpinBox) u16 {
        return this.m_value;
    }
    fn set_value(this: *SpinBox, value: u16) void {
        this.m_value = value;
        this.m_cur_value = value;
    }
    fn set_max_min(this: *SpinBox, max: u16, min: u16) void {
        this.m_max = max;
        this.m_min = min;
    }
    fn set_step(this: *SpinBox, step: u16) void {
        this.m_step = step;
    }
    fn get_min(this: *SpinBox) u16 {
        return this.m_min;
    }
    fn get_max(this: *SpinBox) u16 {
        return this.m_max;
    }
    fn get_step(this: *SpinBox) u16 {
        return this.m_step;
    }
    fn set_value_digit(this: *SpinBox, digit: u16) void {
        this.m_digit = digit;
    }
    fn get_value_digit(this: *SpinBox) u16 {
        return this.m_digit;
    }
    fn set_on_change(this: *SpinBox, on_change: wnd.WND_CALLBACK) void {
        this.on_change = on_change;
    }

    fn pre_create_wnd(thisWnd: *Wnd) !void {
        var this: *SpinBox = @fieldParentPtr("wnd", thisWnd);
        thisWnd.m_attr = @enumFromInt(wnd.ATTR_VISIBLE);
        thisWnd.m_font = Theme.get_font(.FONT_DEFAULT);
        thisWnd.m_font_color = Theme.get_color(.COLOR_WND_FONT);

        var rect = c_rect.init();
        thisWnd.get_screen_rect(&rect);

        this.m_bt_down.m_spin_box = this;
        this.m_bt_up.m_spin_box = this;

        const x: i16 = @truncate(rect.m_left + @divFloor(rect.width() * @as(int, 2), @as(int, 3)));
        const y: i16 = @truncate(rect.m_top);
        const y2: i16 = @truncate(rect.m_top + @divFloor(rect.height(), 2));
        try this.m_bt_up.asWnd().connect(thisWnd.m_parent, ID_BT_ARROW_UP, "+", x, y, @truncate(@divFloor(rect.width(), 3)), @truncate(@divFloor(rect.height(), 3)), null);
        try this.m_bt_up.asWnd().connect(thisWnd.m_parent, ID_BT_ARROW_UP, "-", x, y2, @truncate(@divFloor(rect.width(), 3)), @truncate(@divFloor(rect.height(), 3)), null);
    }
    fn on_paint(thisWnd: *Wnd) !void {
        // const this: *SpinBox = @fieldParentPtr("wnd", thisWnd);

        var rect = c_rect.init();
        thisWnd.get_screen_rect(&rect);
        rect.m_right = rect.m_left + (@divFloor(rect.width() * 2, 3));

        if (thisWnd.m_parent) |_| {
            if (thisWnd.m_surface) |surface| {
                surface.draw_rect(rect, Theme.get_color(.COLOR_WND_NORMAL), thisWnd.m_z_order, 1);
                // c_word.draw_value_in_rect(surface, thisWnd.m_z_order, this.m_cur_value, this.m_digit, rect, thisWnd.m_font.?, thisWnd.m_font_color, Theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER) catch {};
            } else {
                api.ASSERT(false);
            }
        } else {
            api.ASSERT(false);
        }
    }

    fn on_arrow_up_bt_click(this: *SpinBox) !void {
        // _ = this;
        if (this.m_cur_value + this.m_step > this.m_max) {
            return;
        }
        this.m_cur_value += this.m_step;
        if (this.on_change) |on_change| {
            try on_change.on(this.asWnd().m_id, this.m_cur_value);
        }
        try this.wnd.on_paint();
    }
    fn on_arrow_down_bt_click(this: *SpinBox) !void {
        // _ = this;
        if (this.m_cur_value - this.m_step < this.m_min) {
            return;
        }
        this.m_cur_value -= this.m_step;
        if (this.on_change) |on_change| {
            try on_change.on(this.asWnd().m_id, this.m_cur_value);
        }
        try this.wnd.on_paint();
    }
};

pub const c_spin_button = struct {
    button: button.Button = btn: {
        var _btn = button.Button{};
        _btn.wnd.m_class = "c_spin_button";
        _btn.wnd.m_vtable.on_touch = c_spin_button.on_touch;
        break :btn _btn;
    },
    m_spin_box: *SpinBox = undefined,

    fn init(spinbox: *SpinBox) c_spin_button {
        const this = c_spin_button{ .m_spin_box = spinbox };
        return this;
    }
    pub fn asWnd(this: *c_spin_button) *Wnd {
        return this.button.asWnd();
    }
    fn on_touch(thisWnd: *Wnd, x: int, y: int, action: wnd.TOUCH_ACTION) !void {
        const _button: *button.Button = @fieldParentPtr("wnd", thisWnd);
        const this: *c_spin_button = @fieldParentPtr("button", _button);
        if (action == .TOUCH_UP) {
            if (thisWnd.m_id == ID_BT_ARROW_UP) {
                try this.m_spin_box.on_arrow_up_bt_click();
            } else {
                try this.m_spin_box.on_arrow_down_bt_click();
            }
        }
        try button.Button.on_touch(thisWnd, x, y, action);
    }
};
