const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const button = @import("./button.zig");
const c_wnd = wnd.c_wnd;
const c_rect = api.c_rect;
const c_word = word.c_word;
const c_theme = theme.c_theme;
const int = types.int;
const uint = types.uint;

const ID_BT_ARROW_UP = 0x1111;
const ID_BT_ARROW_DOWN = 0x2222;
pub const c_spin_box = struct {
    wnd: wnd.c_wnd = .{ .m_class = "c_spin_box", .m_vtable = .{
        .on_paint = c_spin_box.on_paint,
        .pre_create_wnd = c_spin_box.pre_create_wnd,
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

    pub fn asWnd(this: *c_spin_box) *c_wnd {
        return &this.wnd;
    }

    fn get_value(this: *c_spin_box) u16 {
        return this.m_value;
    }
    fn set_value(this: *c_spin_box, value: u16) void {
        this.m_value = value;
        this.m_cur_value = value;
    }
    fn set_max_min(this: *c_spin_box, max: u16, min: u16) void {
        this.m_max = max;
        this.m_min = min;
    }
    fn set_step(this: *c_spin_box, step: u16) void {
        this.m_step = step;
    }
    fn get_min(this: *c_spin_box) u16 {
        return this.m_min;
    }
    fn get_max(this: *c_spin_box) u16 {
        return this.m_max;
    }
    fn get_step(this: *c_spin_box) u16 {
        return this.m_step;
    }
    fn set_value_digit(this: *c_spin_box, digit: u16) void {
        this.m_digit = digit;
    }
    fn get_value_digit(this: *c_spin_box) u16 {
        return this.m_digit;
    }
    fn set_on_change(this: *c_spin_box, on_change: wnd.WND_CALLBACK) void {
        this.on_change = on_change;
    }

    fn pre_create_wnd(thisWnd: *c_wnd) void {
        var this: *c_spin_box = @fieldParentPtr("wnd", thisWnd);
        thisWnd.m_attr = @enumFromInt(wnd.ATTR_VISIBLE);
        thisWnd.m_font = c_theme.get_font(.FONT_DEFAULT);
        thisWnd.m_font_color = c_theme.get_color(.COLOR_WND_FONT);

        var rect = c_rect.init();
        thisWnd.get_screen_rect(&rect);

        this.m_bt_down.m_spin_box = this;
        this.m_bt_up.m_spin_box = this;

        const x: i16 = @truncate(rect.m_left + @divFloor(rect.width() * @as(int, 2), @as(int, 3)));
        const y: i16 = @truncate(rect.m_top);
        const y2: i16 = @truncate(rect.m_top + @divFloor(rect.height(), 2));
        _ = this.m_bt_up.asWnd().connect(thisWnd.m_parent, ID_BT_ARROW_UP, "+", x, y, @truncate(@divFloor(rect.width(), 3)), @truncate(@divFloor(rect.height(), 3)), null);
        _ = this.m_bt_up.asWnd().connect(thisWnd.m_parent, ID_BT_ARROW_UP, "-", x, y2, @truncate(@divFloor(rect.width(), 3)), @truncate(@divFloor(rect.height(), 3)), null);
    }
    fn on_paint(thisWnd: *c_wnd) void {
        // const this: *c_spin_box = @fieldParentPtr("wnd", thisWnd);

        var rect = c_rect.init();
        thisWnd.get_screen_rect(&rect);
        rect.m_right = rect.m_left + (@divFloor(rect.width() * 2, 3));

        if (thisWnd.m_parent) |_| {
            if (thisWnd.m_surface) |surface| {
                surface.draw_rect(rect, c_theme.get_color(.COLOR_WND_NORMAL), thisWnd.m_z_order, 1);
                // c_word.draw_value_in_rect(surface, thisWnd.m_z_order, this.m_cur_value, this.m_digit, rect, thisWnd.m_font.?, thisWnd.m_font_color, c_theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER) catch {};
            } else {
                api.ASSERT(false);
            }
        } else {
            api.ASSERT(false);
        }
    }

    fn on_arrow_up_bt_click(this: *c_spin_box) void {
        // _ = this;
        if (this.m_cur_value + this.m_step > this.m_max) {
            return;
        }
        this.m_cur_value += this.m_step;
        if (this.on_change) |on_change| {
            on_change.on(this.asWnd().m_id, this.m_cur_value);
        }
        this.wnd.on_paint();
    }
    fn on_arrow_down_bt_click(this: *c_spin_box) void {
        // _ = this;
        if (this.m_cur_value - this.m_step < this.m_min) {
            return;
        }
        this.m_cur_value -= this.m_step;
        if (this.on_change) |on_change| {
            on_change.on(this.asWnd().m_id, this.m_cur_value);
        }
        this.wnd.on_paint();
    }
};

pub const c_spin_button = struct {
    button: button.c_button = btn: {
        var _btn = button.c_button{};
        _btn.wnd.m_class = "c_spin_button";
        _btn.wnd.m_vtable.on_touch = c_spin_button.on_touch;
        break :btn _btn;
    },
    m_spin_box: *c_spin_box = undefined,

    fn init(spinbox: *c_spin_box) c_spin_button {
        const this = c_spin_button{ .m_spin_box = spinbox };
        return this;
    }
    pub fn asWnd(this: *c_spin_button) *c_wnd {
        return this.button.asWnd();
    }
    fn on_touch(thisWnd: *c_wnd, x: int, y: int, action: wnd.TOUCH_ACTION) void {
        const _button: *button.c_button = @fieldParentPtr("wnd", thisWnd);
        const this: *c_spin_button = @fieldParentPtr("button", _button);
        if (action == .TOUCH_UP) {
            if (thisWnd.m_id == ID_BT_ARROW_UP) {
                this.m_spin_box.on_arrow_up_bt_click();
            } else {
                this.m_spin_box.on_arrow_down_bt_click();
            }
        }
        button.c_button.on_touch(thisWnd, x, y, action);
    }
};
