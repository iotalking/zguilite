const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const button = @import("./button.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const Wnd = wnd.Wnd;
const c_rect = api.c_rect;
const c_word = word.c_word;
const Theme = theme.Theme;
const c_surface = display.c_surface;
const int = types.int;
const uint = types.uint;

pub const KEY_WIDTH = 65;
pub const KEY_HEIGHT = 38;
pub const KEYBOARD_WIDTH = (KEY_WIDTH + 2) * 10;

pub const KEYBOARD_HEIGHT: u32 = ((KEY_HEIGHT + 2) * 4);
pub const NUM_BOARD_WIDTH: u32 = ((KEY_WIDTH + 2) * 4);
pub const NUM_BOARD_HEIGHT: u32 = ((KEY_HEIGHT + 2) * 4);
pub const CAPS_WIDTH: u32 = (KEY_WIDTH * 3 / 2);
pub const DEL_WIDTH: u32 = (KEY_WIDTH * 3 / 2 + 1);
pub const ESC_WIDTH = (KEY_WIDTH * 2 + 2);
pub const SWITCH_WIDTH = (KEY_WIDTH * 3 / 2);
pub const SPACE_WIDTH = (KEY_WIDTH * 3 + 2 * 2);
pub const DOT_WIDTH = (KEY_WIDTH * 3 / 2 + 3);
pub const ENTER_WIDTH = (KEY_WIDTH * 2 + 2);
pub inline fn POS_X(c: u32) u32 {
    return ((KEY_WIDTH * c) + (c + 1) * 2);
}
pub inline fn POS_Y(r: u32) u32 {
    return ((KEY_HEIGHT * r) + (r + 1) * 2);
}

pub const KEYBOARD_STATUS = enum { STATUS_UPPERCASE, STATUS_LOWERCASE };
pub const KEYBOARD_STYLE = enum { STYLE_ALL_BOARD, STYLE_NUM_BOARD };
pub const CLICK_STATUS = enum { CLICK_CHAR, CLICK_ENTER, CLICK_ESC };

pub const KeyboardButton = struct {
    base: button.Button = base: {
        var btn = button.Button{};
        btn.wnd.m_class = "KeyboardButton";
        btn.wnd.m_vtable.pre_create_wnd = KeyboardButton.pre_create_wnd;
        break :base btn;
    },
    pub fn asWnd(this: *KeyboardButton) *Wnd {
        const w = this.base.asWnd();
        return w;
    }
    pub fn pre_create_wnd(w: *Wnd) !void {
        const base: *button.Button = @fieldParentPtr("wnd", w);
        const this: *KeyboardButton = @fieldParentPtr("base", base);
        _ = this;
        try button.Button.pre_create_wnd(w);
        w.m_font = Theme.get_font(.FONT_CUSTOM1);
    }
};

var s_button_0: KeyboardButton = .{};
var s_button_1: KeyboardButton = .{};
var s_button_2: KeyboardButton = .{};
var s_button_3: KeyboardButton = .{};
var s_button_4: KeyboardButton = .{};
var s_button_5: KeyboardButton = .{};
var s_button_6: KeyboardButton = .{};
var s_button_7: KeyboardButton = .{};
var s_button_8: KeyboardButton = .{};
var s_button_9: KeyboardButton = .{};

var s_button_A: KeyboardButton = .{};
var s_button_B: KeyboardButton = .{};
var s_button_C: KeyboardButton = .{};
var s_button_D: KeyboardButton = .{};
var s_button_E: KeyboardButton = .{};
var s_button_F: KeyboardButton = .{};
var s_button_G: KeyboardButton = .{};
var s_button_H: KeyboardButton = .{};
var s_button_I: KeyboardButton = .{};
var s_button_J: KeyboardButton = .{};

var s_button_K: KeyboardButton = .{};
var s_button_L: KeyboardButton = .{};
var s_button_M: KeyboardButton = .{};
var s_button_N: KeyboardButton = .{};
var s_button_O: KeyboardButton = .{};
var s_button_P: KeyboardButton = .{};
var s_button_Q: KeyboardButton = .{};
var s_button_R: KeyboardButton = .{};
var s_button_S: KeyboardButton = .{};
var s_button_T: KeyboardButton = .{};

var s_button_U: KeyboardButton = .{};
var s_button_V: KeyboardButton = .{};
var s_button_W: KeyboardButton = .{};
var s_button_X: KeyboardButton = .{};
var s_button_Y: KeyboardButton = .{};
var s_button_Z: KeyboardButton = .{};

var s_button_dot: KeyboardButton = .{};
var s_button_caps: KeyboardButton = .{};
var s_button_space: KeyboardButton = .{};
var s_button_enter: KeyboardButton = .{};
var s_button_del: KeyboardButton = .{};
var s_button_esc: KeyboardButton = .{};
var s_button_num_switch: KeyboardButton = .{};

var g_key_board_children = [_]?*const wnd.WND_TREE{
    //Row 1
    &.{
        .p_wnd = s_button_Q.asWnd(),
        .resource_id = 'Q',
        .str = "Q",
        .x = POS_X(0),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_W.asWnd(),
        .resource_id = 'W',
        .str = "W",
        .x = POS_X(1),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_E.asWnd(),
        .resource_id = 'E',
        .str = "E",
        .x = POS_X(2),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_R.asWnd(),
        .resource_id = 'R',
        .str = "R",
        .x = POS_X(3),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_T.asWnd(),
        .resource_id = 'T',
        .str = "T",
        .x = POS_X(4),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_Y.asWnd(),
        .resource_id = 'Y',
        .str = "Y",
        .x = POS_X(5),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_U.asWnd(),
        .resource_id = 'U',
        .str = "U",
        .x = POS_X(6),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_I.asWnd(),
        .resource_id = 'I',
        .str = "I",
        .x = POS_X(7),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_O.asWnd(),
        .resource_id = 'O',
        .str = "O",
        .x = POS_X(8),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_P.asWnd(),
        .resource_id = 'P',
        .str = "P",
        .x = POS_X(9),
        .y = POS_Y(0),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    // //Row 2
    &.{
        .p_wnd = s_button_A.asWnd(),
        .resource_id = 'A',
        .str = "A",
        .x = ((KEY_WIDTH / 2) + POS_X(0)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_S.asWnd(),
        .resource_id = 'S',
        .str = "S",
        .x = ((KEY_WIDTH / 2) + POS_X(1)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_D.asWnd(),
        .resource_id = 'D',
        .str = "D",
        .x = ((KEY_WIDTH / 2) + POS_X(2)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_F.asWnd(),
        .resource_id = 'F',
        .str = "F",
        .x = ((KEY_WIDTH / 2) + POS_X(3)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_G.asWnd(),
        .resource_id = 'G',
        .str = "G",
        .x = ((KEY_WIDTH / 2) + POS_X(4)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_H.asWnd(),
        .resource_id = 'H',
        .str = "H",
        .x = ((KEY_WIDTH / 2) + POS_X(5)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_J.asWnd(),
        .resource_id = 'J',
        .str = "J",
        .x = ((KEY_WIDTH / 2) + POS_X(6)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_K.asWnd(),
        .resource_id = 'K',
        .str = "K",
        .x = ((KEY_WIDTH / 2) + POS_X(7)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_L.asWnd(),
        .resource_id = 'L',
        .str = "L",
        .x = ((KEY_WIDTH / 2) + POS_X(8)),
        .y = POS_Y(1),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    // //Row 3
    &.{
        .p_wnd = s_button_caps.asWnd(),
        .resource_id = 0x14,
        .str = "Caps",
        .x = POS_X(0),
        .y = POS_Y(2),
        .width = CAPS_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_Z.asWnd(),
        .resource_id = 'Z',
        .str = "Z",
        .x = ((KEY_WIDTH / 2) + POS_X(1)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_X.asWnd(),
        .resource_id = 'X',
        .str = "X",
        .x = ((KEY_WIDTH / 2) + POS_X(2)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_C.asWnd(),
        .resource_id = 'C',
        .str = "C",
        .x = ((KEY_WIDTH / 2) + POS_X(3)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_V.asWnd(),
        .resource_id = 'V',
        .str = "V",
        .x = ((KEY_WIDTH / 2) + POS_X(4)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_B.asWnd(),
        .resource_id = 'B',
        .str = "B",
        .x = ((KEY_WIDTH / 2) + POS_X(5)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_N.asWnd(),
        .resource_id = 'N',
        .str = "N",
        .x = ((KEY_WIDTH / 2) + POS_X(6)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_M.asWnd(),
        .resource_id = 'M',
        .str = "M",
        .x = ((KEY_WIDTH / 2) + POS_X(7)),
        .y = POS_Y(2),
        .width = KEY_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_del.asWnd(),
        .resource_id = 0x7F,
        .str = "Back",
        .x = ((KEY_WIDTH / 2) + POS_X(8)),
        .y = POS_Y(2),
        .width = DEL_WIDTH,
        .height = KEY_HEIGHT,
    },
    // //Row 4
    &.{
        .p_wnd = s_button_esc.asWnd(),
        .resource_id = 0x1B,
        .str = "Esc",
        .x = POS_X(0),
        .y = POS_Y(3),
        .width = ESC_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_num_switch.asWnd(),
        .resource_id = 0x90,
        .str = "?123",
        .x = POS_X(2),
        .y = POS_Y(3),
        .width = SWITCH_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_space.asWnd(),
        .resource_id = ' ',
        .str = "Space",
        .x = ((KEY_WIDTH / 2) + POS_X(3)),
        .y = POS_Y(3),
        .width = SPACE_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_dot.asWnd(),
        .resource_id = '.',
        .x = ((KEY_WIDTH / 2) + POS_X(6)),
        .y = POS_Y(3),
        .width = DOT_WIDTH,
        .height = KEY_HEIGHT,
    },
    &.{
        .p_wnd = s_button_enter.asWnd(),
        .resource_id = '\n',
        .str = "Enter",
        .x = POS_X(8),
        .y = POS_Y(3),
        .width = ENTER_WIDTH,
        .height = KEY_HEIGHT,
    },

    null,
};

var g_number_board_children = [_]?*const wnd.WND_TREE{
    &.{ .p_wnd = s_button_1.asWnd(), .resource_id = '1', .str = "1", .x = POS_X(0), .y = POS_Y(0), .width = KEY_WIDTH, .height = KEY_HEIGHT }, //
    &.{ .p_wnd = s_button_2.asWnd(), .resource_id = '2', .str = "2", .x = POS_X(1), .y = POS_Y(0), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_3.asWnd(), .resource_id = '3', .str = "3", .x = POS_X(2), .y = POS_Y(0), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_del.asWnd(), .resource_id = 0x7F, .str = "Back", .x = POS_X(3), .y = POS_Y(0), .width = KEY_WIDTH, .height = KEY_HEIGHT * 2 + 2 },
    &.{ .p_wnd = s_button_4.asWnd(), .resource_id = '4', .str = "4", .x = POS_X(0), .y = POS_Y(1), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_5.asWnd(), .resource_id = '5', .str = "5", .x = POS_X(1), .y = POS_Y(1), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_6.asWnd(), .resource_id = '6', .str = "6", .x = POS_X(2), .y = POS_Y(1), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_7.asWnd(), .resource_id = '7', .str = "7", .x = POS_X(0), .y = POS_Y(2), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_8.asWnd(), .resource_id = '8', .str = "8", .x = POS_X(1), .y = POS_Y(2), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_9.asWnd(), .resource_id = '9', .str = "9", .x = POS_X(2), .y = POS_Y(2), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_enter.asWnd(), .resource_id = '\n', .str = "Enter", .x = POS_X(3), .y = POS_Y(2), .width = KEY_WIDTH, .height = KEY_HEIGHT * 2 + 2 },
    &.{ .p_wnd = s_button_esc.asWnd(), .resource_id = 0x1B, .str = "Esc", .x = POS_X(0), .y = POS_Y(3), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_0.asWnd(), .resource_id = '0', .str = "0", .x = POS_X(1), .y = POS_Y(3), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    &.{ .p_wnd = s_button_dot.asWnd(), .resource_id = '.', .str = ".", .x = POS_X(2), .y = POS_Y(3), .width = KEY_WIDTH, .height = KEY_HEIGHT },
    null,
};
pub const Keyboard = struct {
    wnd: Wnd = .{
        .m_class = "Keyboard",
        .m_vtable = .{
            .on_paint = Keyboard.on_paint,
            .on_init_children = Keyboard.on_init_children,
            .pre_create_wnd = Keyboard.pre_create_wnd,
        },
    },
    m_on_click: ?wnd.WND_CALLBACK = null,
    m_cap_status: KEYBOARD_STATUS = .STATUS_LOWERCASE,

    m_str: [32]u8 = std.mem.zeroes([32]u8),
    m_str_len: u32 = 0,

    pub fn asWnd(this: *Keyboard) *Wnd {
        const w = &this.wnd;
        return w;
    }

    pub fn open_keyboard(this: *Keyboard, user: *wnd.Wnd, resource_id: u16, style: KEYBOARD_STYLE, click: ?wnd.WND_CALLBACK) !void {
        // _ = this;
        // _ = user;
        // _ = resource_id;
        // _ = style;
        const thisWnd: *Wnd = this.asWnd();
        var user_rect: c_rect = c_rect.init();
        user.get_wnd_rect(&user_rect);
        this.m_on_click = click;
        if (style == .STYLE_ALL_BOARD) { //Place keyboard at the bottom of user's parent window.
            var user_parent_rect = c_rect.init();
            if (user.get_parent()) |p| {
                p.get_wnd_rect(&user_parent_rect);
            }
            const ix: i16 = @truncate(0 - user_rect.m_left);
            const iy: i16 = @truncate(user_parent_rect.height() - user_rect.m_top - KEYBOARD_HEIGHT);
            try thisWnd.connect(user, resource_id, null, ix, iy, KEYBOARD_WIDTH, KEYBOARD_HEIGHT, &g_key_board_children);
        } else if (style == .STYLE_NUM_BOARD) { //Place keyboard below the user window.
            const ix: i16 = 0;
            const iy: i16 = @truncate(user_rect.height());
            try thisWnd.connect(user, resource_id, null, ix, iy, NUM_BOARD_WIDTH, NUM_BOARD_HEIGHT, &g_number_board_children);
        } else {
            api.ASSERT(false);
        }
    }
    pub fn on_init_children(this: *Wnd) !void {
        var next = this.m_top_child;
        const keyboard: *Keyboard = @fieldParentPtr("wnd", this);
        while (next) |child| {
            const btn = button.Button.asButton(child);
            std.log.debug("keyboard.on_init_children.btn:{any} parent:{*}", .{ this.get_id(), btn.asWnd().m_parent.? });
            btn.set_on_click(wnd.WND_CALLBACK.init(keyboard, &Keyboard.on_key_clicked));
            next = child.get_next_sibling();
        }
    }
    fn on_key_clicked(this: *Keyboard, id: int, param: int) !void {
        std.log.debug("keyboard.on_key_clicked(id:{any},param:{any})", .{ id, param });
        // _ = this;
        switch (id) {
            0x14 => {
                try this.on_caps_clicked(id, param);
            },
            '\n' => {
                try this.on_enter_clicked(id, param);
            },
            0x1B => {
                try this.on_esc_clicked(id, param);
            },
            0x7F => {
                try this.on_del_clicked(id, param);
            },
            else => {
                try this.on_char_clicked(id, param);
            },
        }
    }

    fn on_caps_clicked(this: *Keyboard, id: int, param: int) !void {
        _ = id;
        _ = param;
        var _wnd = this.asWnd();
        this.m_cap_status = if (this.m_cap_status == .STATUS_LOWERCASE) .STATUS_UPPERCASE else .STATUS_LOWERCASE;
        try _wnd.show_window();
    }
    fn on_enter_clicked(this: *Keyboard, id: int, param: int) !void {
        // _ = this;
        _ = id;
        _ = param;
        @memset(&this.m_str, 0);
        if (this.m_on_click) |on_click| {
            try on_click.on(this.asWnd().m_id, @intFromEnum(CLICK_STATUS.CLICK_ENTER));
        } else {
            api.ASSERT(false);
        }
    }
    fn on_esc_clicked(this: *Keyboard, id: int, param: int) !void {
        // _ = this;
        _ = id;
        _ = param;
        @memset(&this.m_str, 0);
        if (this.m_on_click) |on_click| {
            try on_click.on(this.asWnd().m_id, @intFromEnum(CLICK_STATUS.CLICK_ESC));
        } else {
            api.ASSERT(false);
        }
    }
    fn on_del_clicked(this: *Keyboard, id: int, param: int) !void {
        // _ = this;
        _ = id;
        _ = param;
        if (this.m_str_len <= 0) {
            return;
        }
        this.m_str_len -= 1;
        this.m_str[this.m_str_len] = 0;

        if (this.m_on_click) |on_click| {
            try on_click.on(this.asWnd().m_id, @intFromEnum(CLICK_STATUS.CLICK_CHAR));
        } else {
            api.ASSERT(false);
        }
    }
    fn on_char_clicked(this: *Keyboard, _id: int, param: int) !void {
        // _ = this;
        var id = _id;
        _ = param;
        //id = char ascii code.
        if (this.m_str_len >= this.m_str.len) {
            return;
        }
        InputChar: {
            if ((id >= '0' and id <= '9') or id == ' ' or id == '.') {
                break :InputChar;
            }

            if (id >= 'A' and id <= 'Z') {
                if (.STATUS_LOWERCASE == this.m_cap_status) {
                    id += 0x20;
                }
                break :InputChar;
            }
            if (id == 0x90) return; //TBD
            api.ASSERT(false);
        }
        // InputChar:
        this.m_str_len += 1;
        this.m_str[this.m_str_len] = @truncate(@as(u32, @bitCast(id)));

        if (this.m_on_click) |click| {
            try click.on(id, @intFromEnum(CLICK_STATUS.CLICK_CHAR));
        }
    }

    pub fn get_str(this: *const Keyboard) []const u8 {
        return &this.m_str;
    }
    fn pre_create_wnd(w: *Wnd) !void {
        const this: *Keyboard = @fieldParentPtr("wnd", w);
        w.m_font = Theme.get_font(.FONT_CUSTOM1);
        _ = this;
    }
    fn on_paint(w: *Wnd) !void {
        const this: *Keyboard = @fieldParentPtr("wnd", w);
        const _w = this.asWnd();
        var rect = c_rect.init();
        _w.get_screen_rect(&rect);
        if (_w.m_surface) |m_surface| {
            m_surface.fill_rect(rect, api.GL_RGB(0, 0, 0), _w.m_z_order);
        }
    }
    pub fn close_keyboard(this: *Keyboard) void {
        const w = this.asWnd();
        w.disconnect();
        if (w.m_surface) |surface| {
            surface.activate_layer(c_rect.init(), w.m_z_order); //inactivate the layer of keyboard by empty rect.
        }
    }
};
