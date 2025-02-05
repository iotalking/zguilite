const std = @import("std");
const api = @import("./api.zig");
const resource = @import("./resource.zig");
const display = @import("./display.zig");
const types = @import("./types.zig");

const Surface = display.Surface;
const Rect = api.Rect;
const int = types.int;
const uint = types.uint;
const BITMAP_INFO = resource.BITMAP_INFO;
const LatticeFontInfo = resource.LatticeFontInfo;
// class Wnd;
// class Surface;

pub const WND_ATTRIBUTION = enum(u32) {
    ATTR_UNKNOWN = 0x0,
    ATTR_VISIBLE = 0x40000000,
    ATTR_FOCUS = 0x20000000,
    ATTR_PRIORITY = 0x10000000, // Handle touch action at high priority
    _,
};

pub const ATTR_VISIBLE: u32 = @intFromEnum(WND_ATTRIBUTION.ATTR_VISIBLE);
pub const ATTR_FOCUS: u32 = @intFromEnum(WND_ATTRIBUTION.ATTR_FOCUS);
pub const ATTR_PRIORITY: u32 = @intFromEnum(WND_ATTRIBUTION.ATTR_PRIORITY);

pub const WND_STATUS = enum(u16) {
    STATUS_NORMAL, //
    STATUS_PUSHED,
    STATUS_FOCUSED,
    STATUS_DISABLED,
};

pub const NAVIGATION_KEY = enum(u16) {
    NAV_FORWARD, //
    NAV_BACKWARD,
    NAV_ENTER,
};

pub const TOUCH_ACTION = enum(u16) {
    TOUCH_DOWN, //
    TOUCH_UP,
    TOUCH_MOVE,
};

pub const KEY_TYPE = enum(u16) {
    KEY_FORWARD,
    KEY_BACKWARD,
    KEY_ENTER,
};

pub const struct_wnd_tree = struct {
    p_wnd: ?*Wnd = null, //window instance
    resource_id: u16 = 0, //ID
    str: ?[]const u8 = null, //caption
    x: i16 = 0, //position x
    y: i16 = 0, //position y
    width: i16 = 0,
    height: i16 = 0,
    p_child_tree: ?[]?*struct_wnd_tree = null, //sub tree
    user_data: ?*const anyopaque = null,
};
pub const WND_TREE = struct_wnd_tree;

// typedef void (Wnd::*WND_CALLBACK)(int, int);
// pub const WND_CALLBACK = *const fn (int, int) void;
pub const WND_CALLBACK = struct {
    m_callback: CALLBACK,
    m_user: *const anyopaque,
    const CALLBACK = *const fn (user: *const anyopaque, id: int, param: int) anyerror!void;
    pub fn init(user: *const anyopaque, callback: anytype) WND_CALLBACK {
        return .{
            .m_user = user,
            .m_callback = @ptrCast(&callback),
        };
    }
    pub fn on(this: *const WND_CALLBACK, id: int, param: int) !void {
        try this.m_callback(this.m_user, id, param);
    }
};

pub const Wnd = struct {
    // public:
    // 	Wnd() : m_status(STATUS_NORMAL), m_attr((WND_ATTRIBUTION)(ATTR_VISIBLE | ATTR_FOCUS)), m_parent(0), m_top_child(0), m_prev_sibling(0), m_next_sibling(0),
    // 		m_str(0), m_font_color(0), m_bg_color(0), m_id(0), m_z_order(Z_ORDER_LEVEL_0), m_focus_child(0), m_surface(0) {};

    pub fn init() Wnd {
        return .{};
    }
    pub fn deinit(this: *Wnd) void {
        _ = this;
    }
    // 	virtual ~Wnd() {};
    pub fn connect_impl(this: *Wnd, parent: ?*Wnd, resource_id: u16, str: ?[]const u8, x: i16, y: i16, width: i16, height: i16, p_child_tree: ?[]?*const WND_TREE) !void {
        if (0 == resource_id) {
            api.ASSERT(false);
            return error.resource_id_zero;
        }
        std.log.debug("wnd.class:{s}", .{this.m_class});
        this.m_id = resource_id;
        this.set_str(str);
        this.m_parent = parent;
        this.m_status = .STATUS_NORMAL;
        if (parent) |_parent| {
            this.m_z_order = _parent.m_z_order;
            this.m_surface = _parent.m_surface;
        }
        if (null == this.m_surface) {
            api.ASSERT(false);
            return error.surface_null;
        }

        // /* (cs.x = x * 1024 / 768) for 1027*768=>800*600 quickly*/
        this.m_wnd_rect.m_left = x;
        this.m_wnd_rect.m_top = y;
        this.m_wnd_rect.m_right = (x + width - 1);
        this.m_wnd_rect.m_bottom = (y + height - 1);

        try this.pre_create_wnd();

        if (parent) |p| {
            p.add_child_2_tail(this);
        }

        if (try this.load_child_wnd(p_child_tree) >= 0) {
            try this.on_init_children();
        }
    }

    pub fn disconnect(this: *Wnd) void {
        if (null != this.m_top_child) {
            var child: ?*Wnd = this.m_top_child;
            var next_child: ?*Wnd = null;

            while (child) |_child| {
                next_child = _child.m_next_sibling;
                _child.disconnect();
                child = next_child;
            }
        }

        if (this.m_parent) |parent| {
            _ = parent.unlink_child(this);
        }
        this.m_focus_child = null;
        this.m_attr = .ATTR_UNKNOWN;
    }

    pub fn on_init_children_impl(this: *Wnd) !void {
        _ = this;
    }
    pub fn on_paint_impl(this: *Wnd) !void {
        _ = this;
    }
    pub fn show_window(this: *Wnd) !void {
        std.log.debug("show_window class:{s}", .{this.m_class});
        if (ATTR_VISIBLE == (@intFromEnum(this.m_attr) & ATTR_VISIBLE)) {
            try this.on_paint();
            var _child: ?*Wnd = this.m_top_child;
            while (_child) |child| {
                std.log.debug("child:{*} font:{*}", .{ child, child.m_font });
                try child.show_window();
                _child = child.m_next_sibling;
            }
        } else {
            std.log.debug("show_window no visibale", .{});
        }
    }

    pub fn get_id(this: *Wnd) u16 {
        return this.m_id;
    }
    pub fn get_z_order(this: *Wnd) int {
        return this.m_z_order;
    }
    pub fn get_wnd_ptr(this: *Wnd, id: u16) ?*Wnd {
        var _child = this.m_top_child;

        while (_child) |child| {
            if (child.get_id() == id) {
                break;
            }

            _child = child.m_next_sibling;
        }

        return _child;
    }
    pub fn get_attr(this: *Wnd) uint {
        return @bitCast(@intFromEnum(this.m_attr));
    }

    pub fn set_str(this: *Wnd, str: ?[]const u8) void {
        this.m_str = str;
    }
    pub fn set_attr(this: *Wnd, attr: WND_ATTRIBUTION) void {
        this.m_attr = attr;
    }
    pub fn is_focus_wnd(this: *Wnd) bool {
        return if ((this.m_attr == .ATTR_VISIBLE) and (this.m_attr == .ATTR_FOCUS)) true else false;
    }

    pub fn set_font_color(this: *Wnd, color: uint) void {
        this.m_font_color = color;
    }
    pub fn get_font_color(this: *Wnd) uint {
        return this.m_font_color;
    }
    pub fn set_bg_color(this: *Wnd, color: uint) void {
        this.m_bg_color = color;
    }
    pub fn get_bg_color(this: *Wnd) uint {
        return this.m_bg_color;
    }
    pub fn set_font_type(this: *Wnd, font_type: *LatticeFontInfo) void {
        this.m_font = font_type;
    }
    pub fn get_font_type(this: *Wnd) ?*Wnd {
        return this.m_font;
    }
    pub fn get_wnd_rect(this: *Wnd, rect: *Rect) void {
        rect.* = this.m_wnd_rect;
    }

    pub fn get_screen_rect(this: *Wnd, rect: *Rect) void {
        var l: int = 0;
        var t: int = 0;
        this.wnd2screen(&l, &t);
        rect.set_rect(l, t, this.m_wnd_rect.width(), this.m_wnd_rect.height());
    }

    pub fn set_child_focus(this: *Wnd, _focus_child: ?*Wnd) !?*Wnd {
        api.ASSERT(null != _focus_child);
        const focus_child = _focus_child.?;
        api.ASSERT(focus_child.m_parent != null);
        api.ASSERT(focus_child.m_parent.? == this);

        const old_focus_child = this.m_focus_child;
        if (focus_child.is_focus_wnd()) {
            if (focus_child != old_focus_child) {
                if (old_focus_child) |child| {
                    try child.on_kill_focus();
                }
                this.m_focus_child = focus_child;
                try focus_child.on_focus();
            }
        }
        return this.m_focus_child;
    }

    pub fn get_parent(this: *Wnd) ?*Wnd {
        return this.m_parent;
    }
    pub fn get_last_child(this: *Wnd) ?*Wnd {
        if (null == this.m_top_child) {
            return null;
        }

        var child: ?*Wnd = this.m_top_child;
        var pre: ?*Wnd = child;
        while (child) |_child| {
            pre = child;
            child = _child.m_next_sibling;
        }

        return pre;
    }
    pub fn unlink_child(this: *Wnd, child: *Wnd) int {
        if ((this != child.m_parent)) {
            return -1;
        }

        if (null == this.m_top_child) {
            return -2;
        }

        var find = false;

        var tmp_child = this.m_top_child;
        if (tmp_child == child) {
            this.m_top_child = child.m_next_sibling;
            if (child.m_next_sibling) |next_sibling| {
                next_sibling.m_prev_sibling = null;
            }

            find = true;
        } else {
            if (tmp_child) |_child| {
                while (_child.m_next_sibling) |*next_sibling| {
                    if (child == next_sibling.*) {
                        next_sibling.* = child.m_next_sibling.?;
                        if (child.m_next_sibling) |m_next_sibling| {
                            m_next_sibling.m_prev_sibling = _child;
                        }

                        find = true;
                        break;
                    }

                    tmp_child = next_sibling.*;
                }
            }
        }

        if (true == find) {
            if (this.m_focus_child == child) {
                this.m_focus_child = null;
            }

            child.m_next_sibling = null;
            child.m_prev_sibling = null;
            return 1;
        } else {
            return 0;
        }
    }
    pub fn get_prev_sibling(this: *Wnd) ?*Wnd {
        return this.m_prev_sibling;
    }
    pub fn get_next_sibling(this: *Wnd) ?*Wnd {
        return this.m_next_sibling;
    }

    pub fn search_priority_sibling(_: *Wnd, _root: ?*Wnd) ?*Wnd {
        var priority_wnd: ?*Wnd = null;
        var looproot = _root;
        while (looproot) |root| {
            if ((root.m_attr == .ATTR_PRIORITY) and (root.m_attr == .ATTR_VISIBLE)) {
                priority_wnd = root;
                break;
            }
            looproot = root.m_next_sibling;
        }

        return priority_wnd;
    }

    pub fn on_touch_impl(this: *Wnd, _x: int, _y: int, action: TOUCH_ACTION) !void {
        var x = _x;
        var y = _y;
        x -= this.m_wnd_rect.m_left;
        y -= this.m_wnd_rect.m_top;

        const priority_wnd = this.search_priority_sibling(this.m_top_child);
        if (priority_wnd) |_priority_wnd| {
            return _priority_wnd.on_touch(x, y, action);
        }

        var _child: ?*Wnd = this.m_top_child;
        while (_child) |child| {
            std.log.debug("on_touch_impl check focus", .{});
            // if (child.is_focus_wnd()) {
            var rect = Rect.init();
            child.get_wnd_rect(&rect);
            if (true == rect.pt_in_rect(x, y)) {
                return child.on_touch(x, y, action);
            }
            // }
            _child = child.m_next_sibling;
        }
    }

    pub fn on_key_impl(self: *Wnd, key: KEY_TYPE) !bool {
        std.debug.assert(key == KEY_TYPE.KEY_FORWARD or key == KEY_TYPE.KEY_BACKWARD or key == KEY_TYPE.KEY_ENTER);
        // Find current focus wnd.
        var old_focus_wnd: ?*Wnd = self.m_focus_child;
        while (old_focus_wnd != null and old_focus_wnd.?.m_focus_child != null) {
            old_focus_wnd = old_focus_wnd.?.m_focus_child;
        }
        if (old_focus_wnd != null and !try old_focus_wnd.?.on_key(key)) {
            return true;
        }
        // Default moving focus(Default handle KEY_FOWARD/KEY_BACKWARD)
        if (key == KEY_TYPE.KEY_ENTER) {
            return true;
        }
        if (old_focus_wnd == null) {
            // No current focus wnd, new one.
            var child: ?*Wnd = self.m_top_child;
            var new_focus_wnd: ?*Wnd = null;
            while (child) |_child| {
                if (_child.m_attr == .ATTR_VISIBLE) {
                    if (_child.is_focus_wnd()) {
                        new_focus_wnd = child;
                        _ = try new_focus_wnd.?.m_parent.?.set_child_focus(new_focus_wnd.?);
                        child = _child.m_top_child;
                        continue;
                    }
                }
                child = child.?.m_next_sibling;
            }
            return true;
        }
        // Move focus from old wnd to next wnd
        var next_focus_wnd: ?*Wnd = if (key == KEY_TYPE.KEY_FORWARD) old_focus_wnd.?.m_next_sibling else old_focus_wnd.?.m_prev_sibling;
        while (next_focus_wnd != null and !next_focus_wnd.?.is_focus_wnd()) {
            // Search neighbor of old focus wnd
            next_focus_wnd = if (key == KEY_TYPE.KEY_FORWARD) next_focus_wnd.?.m_next_sibling else next_focus_wnd.?.m_prev_sibling;
        }
        if (next_focus_wnd == null) {
            // Search whole brother wnd
            next_focus_wnd = if (key == KEY_TYPE.KEY_FORWARD) old_focus_wnd.?.m_parent.?.m_top_child else old_focus_wnd.?.m_parent.?.get_last_child();
            while (next_focus_wnd != null and !next_focus_wnd.?.is_focus_wnd()) {
                next_focus_wnd = if (key == KEY_TYPE.KEY_FORWARD) next_focus_wnd.?.m_next_sibling else next_focus_wnd.?.m_prev_sibling;
            }
        }
        if (next_focus_wnd != null) {
            _ = try next_focus_wnd.?.m_parent.?.set_child_focus(next_focus_wnd.?);
        }
        return true;
    }
    pub fn on_navigate_impl(this: *Wnd, key: NAVIGATION_KEY) !void {
        std.log.debug("wnd.on_navigate_impl", .{});
        const priority_wnd = this.search_priority_sibling(this.m_top_child);
        if (priority_wnd) |w| {
            return w.on_navigate(key);
        }

        if (this.is_focus_wnd()) {
            std.log.debug("wnd.on_navigate_impl is_focus_wnd", .{});
            return;
        }
        if (key != .NAV_BACKWARD and key != .NAV_FORWARD) {
            if (this.m_focus_child) |child| {
                try child.on_navigate(key);
            } else {
                std.log.debug("wnd.on_navigate_impl no m_focus_child", .{});
            }
            return;
        }

        // Move focus
        const _old_focus_wnd = this.m_focus_child;
        // No current focus wnd, new one.
        if (_old_focus_wnd == null) {
            var _child = this.m_top_child;
            var new_focus_wnd: ?*Wnd = null;
            while (_child) |child| {
                if (child.is_focus_wnd()) {
                    new_focus_wnd = child;
                    if (new_focus_wnd) |nw| {
                        if (nw.m_parent) |parent| {
                            _ = try parent.set_child_focus(nw);
                        }
                    }
                    _child = child.m_top_child;
                    continue;
                }
                _child = child.m_next_sibling;
            }
            return;
        }
        const old_focus_wnd = _old_focus_wnd.?;
        // Move focus from old wnd to next wnd
        var _next_focus_wnd: ?*Wnd = if (key == .NAV_FORWARD) old_focus_wnd.m_next_sibling else old_focus_wnd.m_prev_sibling;
        while (_next_focus_wnd) |next_focus_wnd| { // Search neighbor of old focus wnd
            if ((next_focus_wnd.is_focus_wnd())) {
                break;
            }
            _next_focus_wnd = if (key == .NAV_FORWARD) next_focus_wnd.m_next_sibling else next_focus_wnd.m_prev_sibling;
        }
        if (_next_focus_wnd == null) { // Search whole brother wnd
            _next_focus_wnd = if (key == .NAV_FORWARD) old_focus_wnd.m_parent.?.m_top_child else old_focus_wnd.m_parent.?.get_last_child();
            while (_next_focus_wnd) |next_focus_wnd| {
                if (next_focus_wnd.is_focus_wnd()) {
                    break;
                }
                _next_focus_wnd = if (key == .NAV_FORWARD) next_focus_wnd.m_next_sibling else next_focus_wnd.m_prev_sibling;
            }
        }
        if (_next_focus_wnd) |next_focus_wnd| {
            _ = try next_focus_wnd.m_parent.?.set_child_focus(next_focus_wnd);
        }
    }

    pub fn get_surface(this: *Wnd) ?*Surface {
        return this.m_surface;
    }
    pub fn set_surface(this: *Wnd, surface: *Surface) void {
        this.m_surface = surface;
    }
    // protected:

    pub fn add_child_2_tail(this: *Wnd, _child: ?*Wnd) void {
        if (null == _child) return;
        std.log.debug("add_child_2_tail _child:{*}", .{_child});
        const child = _child.?;
        if (child == this.get_wnd_ptr(child.m_id)) return;

        if (null == this.m_top_child) {
            std.log.debug("m_top_child == null", .{});
            this.m_top_child = child;
            child.m_prev_sibling = null;
            child.m_next_sibling = null;
        } else {
            const _last_child = this.get_last_child();
            if (_last_child) |last_child| {
                last_child.m_next_sibling = child;
                child.m_prev_sibling = last_child;
                child.m_next_sibling = null;
            } else {
                api.ASSERT(false);
            }
        }
    }

    pub fn wnd2screen(this: *Wnd, x: *int, y: *int) void {
        var _parent = this.m_parent;
        var rect = Rect.init();

        x.* += this.m_wnd_rect.m_left;
        y.* += this.m_wnd_rect.m_top;

        while (_parent) |parent| {
            parent.get_wnd_rect(&rect);
            x.* += rect.m_left;
            y.* += rect.m_top;

            _parent = parent.m_parent;
        }
    }

    pub fn load_child_wnd(this: *Wnd, _p_child_tree: ?[]?*const WND_TREE) !int {
        std.log.debug("load_child_wnd", .{});
        var sum: int = 0;

        if (_p_child_tree) |p_child_tree| {
            for (p_child_tree, 0..) |op_cur, i| {
                std.log.debug("class:{s} loop wnd i:{d}", .{ this.m_class, i });
                if (op_cur) |p_cur| {
                    std.log.debug("loop wnd tree resource_id:{d}", .{p_cur.resource_id});
                    if (p_cur.p_wnd) |p_wnd| {
                        if (p_cur.user_data) |userData| {
                            p_wnd.m_user_data = userData;
                        }
                        try p_wnd.connect(this, p_cur.resource_id, p_cur.str, p_cur.x, p_cur.y, p_cur.width, p_cur.height, p_cur.p_child_tree);
                    } else {
                        api.ASSERT(false);
                    }
                }
                sum += 1;
            }
        }
        return sum;
    }
    pub fn set_active_child(this: *Wnd, child: *Wnd) void {
        this.m_focus_child = child;
    }
    pub fn on_focus_impl(this: *Wnd) !void {
        _ = this;
    }
    pub fn on_kill_focus_impl(this: *Wnd) !void {
        _ = this;
    }
    pub fn pre_create_wnd_impl(this: *Wnd) !void {
        _ = this;
    }

    pub fn connect(this: *Wnd, parent: ?*Wnd, resource_id: u16, str: ?[]const u8, x: i16, y: i16, width: i16, height: i16, p_child_tree: ?[]?*const WND_TREE) !void {
        return this.m_vtable.connect(this, parent, resource_id, str, x, y, width, height, p_child_tree);
    }
    pub fn on_init_children(this: *Wnd) !void {
        return this.m_vtable.on_init_children(this);
    }
    pub fn on_paint(this: *Wnd) !void {
        std.log.debug("on_paint class:{s}", .{this.m_class});
        try this.m_vtable.on_paint(this);
    }
    pub fn on_touch(this: *Wnd, x: int, y: int, action: TOUCH_ACTION) !void {
        try this.m_vtable.on_touch(this, x, y, action);
    }
    pub fn on_key(this: *Wnd, key: KEY_TYPE) !bool {
        return this.m_vtable.on_key(this, key);
    }
    pub fn on_focus(this: *Wnd) !void {
        try this.m_vtable.on_focus(this);
    }
    pub fn on_kill_focus(this: *Wnd) !void {
        try this.m_vtable.on_kill_focus(this);
    }
    pub fn pre_create_wnd(this: *Wnd) !void {
        try this.m_vtable.pre_create_wnd(this);
    }
    pub fn on_navigate(this: *Wnd, key: NAVIGATION_KEY) !void {
        try this.m_vtable.on_navigate(this, key);
    }
    pub const vtable = struct {
        connect: *const fn (this: *Wnd, parent: ?*Wnd, resource_id: u16, str: ?[]const u8, x: i16, y: i16, width: i16, height: i16, p_child_tree: ?[]?*const WND_TREE) anyerror!void = connect_impl,
        on_init_children: *const fn (this: *Wnd) anyerror!void = on_init_children_impl,
        on_paint: *const fn (this: *Wnd) anyerror!void = on_paint_impl,
        on_touch: *const fn (this: *Wnd, x: int, y: int, action: TOUCH_ACTION) anyerror!void = on_touch_impl,
        on_focus: *const fn (this: *Wnd) anyerror!void = on_focus_impl,
        on_kill_focus: *const fn (this: *Wnd) anyerror!void = on_kill_focus_impl,
        on_navigate: *const fn (this: *Wnd, key: NAVIGATION_KEY) anyerror!void = on_navigate_impl,
        pre_create_wnd: *const fn (this: *Wnd) anyerror!void = pre_create_wnd_impl,
        on_key: *const fn (this: *Wnd, key: KEY_TYPE) anyerror!bool = on_key_impl,
    };
    // protected:
    m_vtable: vtable = .{},
    m_class: []const u8 = "Wnd",
    m_id: u16 = 0,
    m_status: WND_STATUS = .STATUS_NORMAL,
    m_attr: WND_ATTRIBUTION = .ATTR_VISIBLE,
    m_wnd_rect: Rect = Rect.init(), //position relative to parent window.
    m_parent: ?*Wnd = null, //parent window
    m_top_child: ?*Wnd = null, //the first sub window would be navigated
    m_prev_sibling: ?*Wnd = null, //previous brother
    m_next_sibling: ?*Wnd = null, //next brother
    m_focus_child: ?*Wnd = null, //current focused window
    m_str: ?[]const u8 = null, //caption

    m_font: ?*anyopaque = null, //font face
    m_font_color: uint = 0,
    m_bg_color: uint = 0,

    m_z_order: int = 0, //the graphic level for rendering
    m_surface: ?*Surface = null,

    m_user_data: ?*const anyopaque = null,
};
