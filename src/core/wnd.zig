const api = @import("./api.zig");
const resource = @import("./resource.zig");
const display = @import("./display.zig");
const types = @import("./types.zig");

const c_surface = display.c_surface;
const c_rect = api.c_rect;
const int = types.int;
const uint = types.uint;
const BITMAP_INFO = resource.BITMAP_INFO;
const LATTICE_FONT_INFO = resource.LATTICE_FONT_INFO;
// class c_wnd;
// class c_surface;

pub const WND_ATTRIBUTION = enum(u32) {
    ATTR_UNKNOWN = 0x0,
    ATTR_VISIBLE = 0x40000000,
    ATTR_FOCUS = 0x20000000,
    ATTR_PRIORITY = 0x10000000, // Handle touch action at high priority
};

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
};

pub const struct_wnd_tree = struct {
    p_wnd: ?*c_wnd, //window instance
    resource_id: u16, //ID
    str: [*]const u8, //caption
    x: i16, //position x
    y: i16, //position y
    width: i16,
    height: i16,
    p_child_tree: *struct_wnd_tree, //sub tree
};
pub const WND_TREE = struct_wnd_tree;

// typedef void (c_wnd::*WND_CALLBACK)(int, int);

pub const c_wnd = struct {
    // public:
    // 	c_wnd() : m_status(STATUS_NORMAL), m_attr((WND_ATTRIBUTION)(ATTR_VISIBLE | ATTR_FOCUS)), m_parent(0), m_top_child(0), m_prev_sibling(0), m_next_sibling(0),
    // 		m_str(0), m_font_color(0), m_bg_color(0), m_id(0), m_z_order(Z_ORDER_LEVEL_0), m_focus_child(0), m_surface(0) {};

    pub fn init() c_wnd {
        return .{};
    }
    pub fn deinit(this: *c_wnd) void {
        _ = this;
    }
    // 	virtual ~c_wnd() {};
    pub fn connect_impl(this: *c_wnd, parent: ?*c_wnd, resource_id: u16, str: [*]const u8, x: i16, y: i16, width: i16, height: i16, p_child_tree: *WND_TREE) int {
        if (0 == resource_id) {
            api.ASSERT(false);
            return -1;
        }

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
            return -2;
        }

        // /* (cs.x = x * 1024 / 768) for 1027*768=>800*600 quickly*/
        this.m_wnd_rect.m_left = x;
        this.m_wnd_rect.m_top = y;
        this.m_wnd_rect.m_right = (x + width - 1);
        this.m_wnd_rect.m_bottom = (y + height - 1);

        this.pre_create_wnd(this);

        if (parent) |p| {
            p.add_child_2_tail(this);
        }

        if (this.load_child_wnd(p_child_tree) >= 0) {
            this.on_init_children(this);
        }
        return 0;
    }

    pub fn disconnect(this: *c_wnd) void {
        if (null != this.m_top_child) {
            const child: ?*c_wnd = this.m_top_child;
            const next_child = null;

            while (child != null) {
                next_child = child.m_next_sibling;
                child.disconnect();
                child = next_child;
            }
        }

        if (null != this.m_parent) {
            this.m_parent.unlink_child(this);
        }
        this.m_focus_child = null;
        this.m_attr = .ATTR_UNKNOWN;
    }

    pub fn on_init_children_impl(this: *c_wnd) void {
        _ = this;
    }
    pub fn on_paint_impl(this: *c_wnd) void {
        _ = this;
    }
    pub fn show_window(this: *c_wnd) void {
        if (.ATTR_VISIBLE == (this.m_attr & .ATTR_VISIBLE)) {
            this.on_paint();
            const child: ?*c_wnd = this.m_top_child;
            if (null != child) {
                while (child) {
                    child.show_window();
                    child = child.m_next_sibling;
                }
            }
        }
    }

    pub fn get_id(this: *c_wnd) u16 {
        return this.m_id;
    }
    pub fn get_z_order(this: *c_wnd) int {
        return this.m_z_order;
    }
    pub fn get_wnd_ptr(this: *c_wnd, id: u16) ?*c_wnd {
        var _child = this.m_top_child;

        while (_child) |child| {
            if (child.get_id() == id) {
                break;
            }

            _child = child.m_next_sibling;
        }

        return _child;
    }
    pub fn get_attr(this: *c_wnd) uint {
        return this.m_attr;
    }

    pub fn set_str(this: *c_wnd, str: [*]const u8) void {
        this.m_str = str;
    }
    pub fn set_attr(this: *c_wnd, attr: WND_ATTRIBUTION) void {
        this.m_attr = attr;
    }
    pub fn is_focus_wnd(this: *c_wnd) bool {
        return if ((this.m_attr == .ATTR_VISIBLE) and (this.m_attr == .ATTR_FOCUS)) true else false;
    }

    pub fn set_font_color(this: *c_wnd, color: uint) void {
        this.m_font_color = color;
    }
    pub fn get_font_color(this: *c_wnd) uint {
        return this.m_font_color;
    }
    pub fn set_bg_color(this: *c_wnd, color: uint) void {
        this.m_bg_color = color;
    }
    pub fn get_bg_color(this: *c_wnd) uint {
        return this.m_bg_color;
    }
    pub fn set_font_type(this: *c_wnd, font_type: *LATTICE_FONT_INFO) void {
        this.m_font = font_type;
    }
    pub fn get_font_type(this: *c_wnd) ?*anyopaque {
        return this.m_font;
    }
    pub fn get_wnd_rect(this: *c_wnd, rect: *c_rect) void {
        rect.* = this.m_wnd_rect;
    }

    pub fn get_screen_rect(this: *c_wnd, rect: *c_rect) void {
        const l = 0;
        const t = 0;
        this.wnd2screen(l, t);
        rect.set_rect(l, t, this.m_wnd_rect.width(), this.m_wnd_rect.height());
    }

    pub fn set_child_focus(this: *c_wnd, focus_child: *c_wnd) ?*c_wnd {
        api.ASSERT(null != focus_child);
        api.ASSERT(focus_child.m_parent == this);

        var old_focus_child = this.m_focus_child;
        if (focus_child.is_focus_wnd()) {
            if (focus_child != old_focus_child) {
                if (old_focus_child) {
                    old_focus_child.on_kill_focus();
                }
                this.m_focus_child = focus_child;
                this.m_focus_child.on_focus();
            }
        }
        return this.m_focus_child;
    }

    pub fn get_parent(this: *c_wnd) ?*c_wnd {
        return this.m_parent;
    }
    pub fn get_last_child(this: *c_wnd) ?*c_wnd {
        if (null == this.m_top_child) {
            return null;
        }

        var child: ?*c_wnd = this.m_top_child;

        while (child) |_child| {
            if (_child.m_next_sibling) |next_sibling| {
                child = next_sibling;
            }
        }

        return child;
    }
    pub fn unlink_child(this: *c_wnd, child: *c_wnd) int {
        if ((null == child) or (this != child.m_parent)) {
            return -1;
        }

        if (null == this.m_top_child) {
            return -2;
        }

        var find = false;

        var tmp_child = this.m_top_child;
        if (tmp_child == child) {
            this.m_top_child = child.m_next_sibling;
            if (null != child.m_next_sibling) {
                child.m_next_sibling.m_prev_sibling = null;
            }

            find = true;
        } else {
            while (tmp_child.m_next_sibling) {
                if (child == tmp_child.m_next_sibling) {
                    tmp_child.m_next_sibling = child.m_next_sibling;
                    if (null != child.m_next_sibling) {
                        child.m_next_sibling.m_prev_sibling = tmp_child;
                    }

                    find = true;
                    break;
                }

                tmp_child = tmp_child.m_next_sibling;
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
    pub fn get_prev_sibling(this: *c_wnd) ?*c_wnd {
        return this.m_prev_sibling;
    }
    pub fn get_next_sibling(this: *c_wnd) ?*c_wnd {
        return this.m_next_sibling;
    }

    pub fn search_priority_sibling(_: *c_wnd, _root: ?*c_wnd) ?*c_wnd {
        var priority_wnd: ?*c_wnd = null;
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

    pub fn on_touch_impl(this: *c_wnd, _x: int, _y: int, action: TOUCH_ACTION) void {
        var x = _x;
        var y = _y;
        x -= this.m_wnd_rect.m_left;
        y -= this.m_wnd_rect.m_top;

        const priority_wnd = this.search_priority_sibling(this.m_top_child);
        if (priority_wnd) |_priority_wnd| {
            return _priority_wnd.on_touch(this, x, y, action);
        }

        var _child: ?*c_wnd = this.m_top_child;
        while (_child) |child| {
            if (child.is_focus_wnd()) {
                var rect = c_rect.init();
                child.get_wnd_rect(&rect);
                if (true == rect.pt_in_rect(x, y)) {
                    return child.on_touch(this, x, y, action);
                }
            }
            _child = child.m_next_sibling;
        }
    }
    pub fn on_navigate(this: *c_wnd, key: NAVIGATION_KEY) void {
        const priority_wnd = this.search_priority_sibling(this.m_top_child);
        if (priority_wnd == null) {
            return this.priority_wnd.on_navigate(key);
        }

        if (this.is_focus_wnd()) {
            return;
        }
        if (key != .NAV_BACKWARD and key != .NAV_FORWARD) {
            if (this.m_focus_child) {
                this.m_focus_child.on_navigate(key);
            }
            return;
        }

        // Move focus
        const old_focus_wnd = this.m_focus_child;
        // No current focus wnd, new one.
        if (old_focus_wnd == null) {
            const child = this.m_top_child;
            const new_focus_wnd = 0;
            while (child != null) {
                if (child.is_focus_wnd()) {
                    new_focus_wnd = child;
                    new_focus_wnd.m_parent.set_child_focus(new_focus_wnd);
                    child = child.m_top_child;
                    continue;
                }
                child = child.m_next_sibling;
            }
            return;
        }
        // Move focus from old wnd to next wnd
        const next_focus_wnd: ?*c_wnd = if (key == .NAV_FORWARD) old_focus_wnd.m_next_sibling else old_focus_wnd.m_prev_sibling;
        while (next_focus_wnd and (!next_focus_wnd.is_focus_wnd())) { // Search neighbor of old focus wnd
            next_focus_wnd = if (key == .NAV_FORWARD) next_focus_wnd.m_next_sibling else next_focus_wnd.m_prev_sibling;
        }
        if (next_focus_wnd == null) { // Search whole brother wnd
            next_focus_wnd = if (key == .NAV_FORWARD) old_focus_wnd.m_parent.m_top_child else old_focus_wnd.m_parent.get_last_child();
            while (next_focus_wnd != null and (next_focus_wnd.is_focus_wnd() != null)) {
                next_focus_wnd = if (key == .NAV_FORWARD) next_focus_wnd.m_next_sibling else next_focus_wnd.m_prev_sibling;
            }
        }
        if (next_focus_wnd) {
            next_focus_wnd.m_parent.set_child_focus(next_focus_wnd);
        }
    }

    pub fn get_surface(this: *c_wnd) *c_surface {
        return this.m_surface;
    }
    pub fn set_surface(this: *c_wnd, surface: *c_surface) void {
        this.m_surface = surface;
    }
    // protected:

    pub fn add_child_2_tail(this: *c_wnd, _child: ?*c_wnd) void {
        if (null == _child) return;
        const child = _child.?;
        if (child == this.get_wnd_ptr(child.m_id)) return;

        if (null == this.m_top_child) {
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

    pub fn wnd2screen(this: *c_wnd, x: *int, y: *int) void {
        const parent = this.m_parent;
        var rect = c_rect.init();

        x.* += this.m_wnd_rect.m_left;
        y.* += this.m_wnd_rect.m_top;

        while (null != parent) {
            parent.get_wnd_rect(&rect);
            x.* += rect.m_left;
            y.* += rect.m_top;

            parent = parent.m_parent;
        }
    }

    pub fn load_child_wnd(this: *c_wnd, _p_child_tree: ?*WND_TREE) int {
        if (null == _p_child_tree) {
            return 0;
        }
        const p_child_tree = _p_child_tree.?;
        var sum: int = 0;

        var _p_cur: [*]?*WND_TREE = @ptrCast(p_child_tree);
        while (_p_cur[0]) |p_cur| {
            if (p_cur.p_wnd) |p_wnd| {
                _ = p_wnd.connect(this, this, p_cur.resource_id, p_cur.str, p_cur.x, p_cur.y, p_cur.width, p_cur.height, p_cur.p_child_tree);
            }
            _p_cur += 1;
            sum += 1;
        }
        return sum;
    }
    pub fn set_active_child(this: *c_wnd, child: *c_wnd) void {
        this.m_focus_child = child;
    }
    pub fn on_focus_impl(this: *c_wnd) void {
        _ = this;
    }
    pub fn on_kill_focus_impl(this: *c_wnd) void {
        _ = this;
    }
    pub fn pre_create_wnd_impl(this: *c_wnd) void {
        _ = this;
    }

    connect: *const fn (this: *c_wnd, parent: *c_wnd, resource_id: u16, str: [*]const u8, x: i16, y: i16, width: i16, height: i16, p_child_tree: *WND_TREE) int = connect_impl,
    on_init_children: *const fn (this: *c_wnd) void = on_init_children_impl,
    on_paint_impl: *const fn (this: *c_wnd) void = on_paint_impl,
    on_touch: *const fn (this: *c_wnd, x: int, y: int, action: TOUCH_ACTION) void = on_touch_impl,
    on_focus: *const fn (this: *c_wnd) void = on_focus_impl,
    on_kill_focus: ?*const fn (this: *c_wnd) void = on_kill_focus_impl,
    pre_create_wnd: *const fn (this: *c_wnd) void = pre_create_wnd_impl,
    // protected:

    m_id: u16 = 0,
    m_status: WND_STATUS = .STATUS_DISABLED,
    m_attr: WND_ATTRIBUTION = .ATTR_UNKNOWN,
    m_wnd_rect: c_rect = c_rect.init(), //position relative to parent window.
    m_parent: ?*c_wnd = null, //parent window
    m_top_child: ?*c_wnd = null, //the first sub window would be navigated
    m_prev_sibling: ?*c_wnd = null, //previous brother
    m_next_sibling: ?*c_wnd = null, //next brother
    m_focus_child: ?*c_wnd = null, //current focused window
    m_str: ?[*]const u8 = null, //caption

    m_font: ?*anyopaque = null, //font face
    m_font_color: uint = 0,
    m_bg_color: uint = 0,

    m_z_order: int = 0, //the graphic level for rendering
    m_surface: ?*c_surface = null,
};