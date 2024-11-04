const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const keyboard = @import("./keyboard.zig");
const c_wnd = wnd.c_wnd;
const c_rect = api.c_rect;
const c_word = word.c_word;
const c_theme = theme.c_theme;
const int = types.int;
const uint = types.uint;

const MAX_ITEM_NUM = 4;
const ITEM_HEIGHT = 45;

pub const c_list_box = struct {
    wnd: wnd.c_wnd = .{ .m_class = "c_list_box", .m_vtable = .{
        .on_paint = c_list_box.on_paint,
        .on_focus = c_list_box.on_focus,
        .on_kill_focus = c_list_box.on_kill_focus,
        .pre_create_wnd = c_list_box.pre_create_wnd,
        .on_touch = c_list_box.on_touch,
        .on_navigate = c_list_box.on_navigate,
    } },
    m_selected_item: u16 = 0,
    m_item_total: u16 = 0,
    m_item_array: [MAX_ITEM_NUM][]const u8 = std.mem.zeroes([MAX_ITEM_NUM][]const u8),
    m_list_wnd_rect: c_rect = c_rect.init(), //rect relative to parent wnd.
    m_list_screen_rect: c_rect = c_rect.init(), //rect relative to physical screen(frame buffer)
    on_change: ?wnd.WND_CALLBACK = null,

    pub fn asWnd(this: *c_list_box) *c_wnd {
        return &this.wnd;
    }
    fn pre_create_wnd(thisWnd: *c_wnd) void {
        thisWnd.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
        thisWnd.m_font = c_theme.get_font(.FONT_DEFAULT);
        thisWnd.m_font_color = c_theme.get_color(.COLOR_WND_FONT);
        thisWnd.m_status = .STATUS_PUSHED;
    }
    fn on_paint(thisWnd: *c_wnd) void {
        const this: *c_list_box = @fieldParentPtr("wnd", thisWnd);

        var rect = c_rect.init();
        thisWnd.get_screen_rect(&rect);
        this.update_list_size();

        if (thisWnd.m_parent) |parent| {
            if (thisWnd.m_surface) |surface| {
                switch (thisWnd.m_status) {
                    .STATUS_NORMAL => {
                        if (thisWnd.m_z_order > parent.m_z_order) {
                            surface.activate_layer(rect, thisWnd.m_z_order);
                            thisWnd.m_z_order = parent.m_z_order;
                            thisWnd.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
                        }
                        surface.draw_rect(rect, c_theme.get_color(.COLOR_WND_NORMAL), thisWnd.m_z_order, 1);
                        c_word.draw_string_in_rect(surface, thisWnd.m_z_order, this.m_item_array[this.m_selected_item], rect, thisWnd.m_font, thisWnd.m_font_color, c_theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                        std.log.debug("c_list_box drawed {s} {*}", .{ this.m_item_array[0], this });
                    },
                    .STATUS_FOCUSED => {
                        if (thisWnd.m_z_order > parent.m_z_order) {
                            surface.activate_layer(rect, thisWnd.m_z_order);
                            thisWnd.m_z_order = parent.m_z_order;
                            thisWnd.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
                        }
                        surface.draw_rect(rect, c_theme.get_color(.COLOR_WND_FOCUS), thisWnd.m_z_order, 1);
                        c_word.draw_string_in_rect(surface, thisWnd.m_z_order, this.m_item_array[this.m_selected_item], rect, thisWnd.m_font, thisWnd.m_font_color, c_theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    },
                    .STATUS_PUSHED => {
                        surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_PUSHED), thisWnd.m_z_order);
                        c_word.draw_string_in_rect(surface, thisWnd.m_z_order, this.m_item_array[this.m_selected_item], rect, thisWnd.m_font, api.GL_RGB(2, 124, 165), api.GL_ARGB(0, 0, 0, 0), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                        //draw list
                        if (this.m_item_total > 0) {
                            if (thisWnd.m_z_order > parent.m_z_order) {
                                surface.activate_layer(rect, thisWnd.m_z_order);
                                thisWnd.m_z_order = parent.m_z_order;
                                thisWnd.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS | wnd.ATTR_PRIORITY);
                            }
                            this.show_list();
                        }
                    },
                    else => {},
                }
            } else {
                api.ASSERT(false);
            }
        } else {
            api.ASSERT(false);
        }
    }
    fn show_list(this: *c_list_box) void {
        //draw all items
        var tmp_rect = c_rect.init();
        if (this.wnd.m_surface) |surface| {
            for (0..this.m_item_total) |i| {
                const _i: i32 = @bitCast(@as(u32, @truncate(i)));
                tmp_rect.m_left = this.m_list_screen_rect.m_left;
                tmp_rect.m_right = this.m_list_screen_rect.m_right;
                tmp_rect.m_top = this.m_list_screen_rect.m_top + _i * ITEM_HEIGHT;
                tmp_rect.m_bottom = tmp_rect.m_top + ITEM_HEIGHT;

                if (this.m_selected_item == i) {
                    surface.fill_rect(tmp_rect, c_theme.get_color(.COLOR_WND_FOCUS), this.wnd.m_z_order);
                    c_word.draw_string_in_rect(surface, this.wnd.m_z_order, this.m_item_array[i], tmp_rect, this.wnd.m_font, this.wnd.m_font_color, c_theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                } else {
                    surface.fill_rect(tmp_rect, api.GL_RGB(17, 17, 17), this.wnd.m_z_order);
                    c_word.draw_string_in_rect(surface, this.wnd.m_z_order, this.m_item_array[i], tmp_rect, this.wnd.m_font, this.wnd.m_font_color, api.GL_RGB(17, 17, 17), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                }
            }
        }
    }
    fn on_focus(thisWnd: *c_wnd) void {
        thisWnd.m_status = .STATUS_FOCUSED;
        thisWnd.on_paint();
    }
    fn on_kill_focus(thisWnd: *c_wnd) void {
        thisWnd.m_status = .STATUS_NORMAL;
        thisWnd.on_paint();
    }
    fn on_navigate(thisWnd: *c_wnd, key: wnd.NAVIGATION_KEY) void {
        const this: *c_list_box = @fieldParentPtr("wnd", thisWnd);
        if (thisWnd.m_parent) |_| {
            switch (key) {
                .NAV_ENTER => {
                    if (thisWnd.m_status == .STATUS_PUSHED) {
                        if (this.on_change) |onchange| {
                            onchange.on(thisWnd.m_id, this.m_selected_item);
                        }
                    }
                    thisWnd.on_touch(thisWnd.m_wnd_rect.m_left, thisWnd.m_wnd_rect.m_top, .TOUCH_DOWN);
                    thisWnd.on_touch(thisWnd.m_wnd_rect.m_left, thisWnd.m_wnd_rect.m_top, .TOUCH_UP);
                },
                .NAV_BACKWARD => {
                    if (thisWnd.m_status != .STATUS_PUSHED) {
                        return thisWnd.on_navigate(key);
                    }
                    this.m_selected_item = if (this.m_selected_item > 0) (this.m_selected_item - 1) else this.m_selected_item;
                    this.show_list();
                },
                .NAV_FORWARD => {
                    if (thisWnd.m_status != .STATUS_PUSHED) {
                        return thisWnd.on_navigate(key);
                    }
                    this.m_selected_item = if (this.m_selected_item > 0) (this.m_selected_item + 1) else this.m_selected_item;
                    this.show_list();
                },
            }
        } else {
            api.ASSERT(false);
        }
    }
    fn on_touch(thisWnd: *c_wnd, x: int, y: int, action: wnd.TOUCH_ACTION) void {
        const this: *c_list_box = @fieldParentPtr("wnd", thisWnd);
        if (action == .TOUCH_DOWN) {
            this.on_touch_down(x, y);
        } else {
            this.on_touch_up(x, y);
        }
    }
    fn on_touch_down(this: *c_list_box, x: int, y: int) void {
        if (this.wnd.m_parent) |parent| {
            if (this.wnd.m_wnd_rect.pt_in_rect(x, y)) { //click base
                if (.STATUS_NORMAL == this.wnd.m_status) {
                    _ = parent.set_child_focus(null);
                }
            } else if (this.m_list_wnd_rect.pt_in_rect(x, y)) { //click extend list
                this.wnd.on_touch(x, y, .TOUCH_DOWN);
            } else {
                if (.STATUS_PUSHED == this.wnd.m_status) {
                    this.wnd.m_status = .STATUS_FOCUSED;
                    this.wnd.on_paint();
                    if (this.on_change) |on_change| {
                        on_change.on(this.wnd.m_id, this.m_selected_item);
                    }
                }
            }
        }
    }
    fn on_touch_up(this: *c_list_box, x: int, y: int) void {
        if (.STATUS_FOCUSED == this.wnd.m_status) {
            this.wnd.m_status = .STATUS_PUSHED;
            this.wnd.on_paint();
        } else if (.STATUS_PUSHED == this.wnd.m_status) {
            if (this.wnd.m_wnd_rect.pt_in_rect(x, y)) { //click base
                this.wnd.m_status = .STATUS_FOCUSED;
                this.wnd.on_paint();
            } else if (this.m_list_wnd_rect.pt_in_rect(x, y)) { //click extend list
                this.wnd.m_status = .STATUS_FOCUSED;
                this.select_item(@intCast(@divExact((y - this.m_list_wnd_rect.m_top), @as(int, ITEM_HEIGHT))));
                this.wnd.on_paint();
                if (this.on_change) |on_change| {
                    on_change.on(this.wnd.m_id, this.m_selected_item);
                }
            } else {
                this.wnd.on_touch(x, y, .TOUCH_UP);
            }
        }
    }
    fn select_item(this: *c_list_box, index: usize) void {
        if (index < 0 or index >= this.m_item_total) {
            api.ASSERT(false);
        }
        this.m_selected_item = @as(u16, @truncate(index));
    }

    fn set_on_change(this: *c_list_box, on_change: wnd.WND_CALLBACK) void {
        this.on_change = on_change;
    }
    fn get_item_count(this: *c_list_box) usize {
        return this.m_item_total;
    }

    fn update_list_size(this: *c_list_box) void {
        this.wnd.get_screen_rect(&this.m_list_screen_rect);
        this.m_list_screen_rect.m_top = this.m_list_screen_rect.m_bottom + 1;
        this.m_list_screen_rect.m_bottom = this.m_list_screen_rect.m_top + this.m_item_total * ITEM_HEIGHT;
    }
    pub fn add_item(this: *c_list_box, str: []const u8) !void {
        if (this.m_item_total >= MAX_ITEM_NUM) {
            return error.out_of_max_item_num;
        }
        this.m_item_array[this.m_item_total] = str;
        std.log.debug("c_list_box add_item str:{*}", .{this.m_item_array[this.m_item_total].ptr});
        this.m_item_total += 1;
        this.update_list_size();
    }
    pub fn clear_item(this: *c_list_box) void {
        this.m_selected_item = 0;
        this.m_item_total = 0;
        @memset(&this.m_item_array, &.{});
        this.update_list_size();
    }
};
