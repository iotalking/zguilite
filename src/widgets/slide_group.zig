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
const gesture = @import("./gesture.zig");

const KEY_TYPE = wnd.KEY_TYPE;
const TOUCH_ACTION = wnd.TOUCH_ACTION;
const WND_TREE = wnd.WND_TREE;
const Z_ORDER_LEVEL = display.Z_ORDER_LEVEL;
const Surface = display.Surface;

pub const MAX_PAGES = 5;

// 定义 SlideGroup 结构体
pub const SlideGroup = struct {
    wnd: Wnd = .{
        .m_class = "SlideGroup",
        .m_vtable = .{
            .on_touch = on_touch,
        },
    },

    m_slides: [MAX_PAGES]?*Wnd = std.mem.zeroes([MAX_PAGES]?*Wnd),
    m_active_slide_index: i32 = 0,
    m_gesture: ?gesture.Gesture = null,

    pub fn asWnd(this: *SlideGroup) *Wnd {
        return &this.wnd;
    }
    // 构造函数
    pub fn init(self: *SlideGroup) void {
        self.m_gesture = gesture.Gesture.init(self);
    }

    // set_active_slide 函数
    pub fn set_active_slide(self: *SlideGroup, index: i32, is_redraw: bool) !void {
        if (index >= MAX_PAGES or index < 0) {
            return error.OutOfIndex;
        }
        if (self.m_slides[@intCast(index)] == null) {
            return error.SlideNull;
        }
        self.m_active_slide_index = index;
        var i: i32 = 0;
        while (i < MAX_PAGES) : (i += 1) {
            if (self.m_slides[@intCast(i)]) |slide| {
                if (i == index) {
                    self.m_slides[@intCast(i)].?.get_surface().?.set_active(true);
                    self.add_child_2_tail(slide);
                    if (is_redraw) {
                        var rc = Rect{ .m_left = 0, .m_top = 0, .m_right = 0, .m_bottom = 0 };
                        self.get_screen_rect(&rc);
                        _ = slide.get_surface().?.flush_screen(rc.m_left, rc.m_top, rc.m_right, rc.m_bottom);
                    }
                } else {
                    slide.get_surface().?.set_active(false);
                }
            }
        }
        return;
    }

    // get_slide 函数
    pub fn get_slide(self: *SlideGroup, index: i32) ?*Wnd {
        return self.m_slides[@intCast(index)];
    }

    // get_active_slide 函数
    pub fn get_active_slide(self: *SlideGroup) ?*Wnd {
        return self.m_slides[@intCast(self.m_active_slide_index)];
    }

    // get_active_slide_index 函数
    pub fn get_active_slide_index(self: *SlideGroup) i32 {
        return self.m_active_slide_index;
    }

    // add_slide 函数
    pub fn add_slide(self: *SlideGroup, slide: *Wnd, resource_id: u16, x: i16, y: i16, width: i16, height: i16, p_child_tree: ?[]?*WND_TREE, max_zorder: Z_ORDER_LEVEL) !void {
        const _old_surface = self.get_surface();
        if (_old_surface == null) {
            return error.SurfaceNUll;
        }
        const old_surface = _old_surface.?;
        const rect = Rect.init2(x, y, @intCast(width), @intCast(height));
        const new_surface = try old_surface.get_display().?.allocSurface(max_zorder, rect);
        new_surface.set_active(false);
        self.set_surface(new_surface);
        try slide.connect(&self.wnd, resource_id, null, x, y, width, height, p_child_tree);
        self.set_surface(old_surface);
        var i: i32 = 0;
        while (i < MAX_PAGES) : (i += 1) {
            if (self.m_slides[@intCast(i)] == slide) {
                std.debug.assert(false);
                return error.SlideExist;
            }
        }
        i = 0;
        while (i < MAX_PAGES) : (i += 1) {
            if (self.m_slides[@intCast(i)] == null) {
                self.m_slides[@intCast(i)] = slide;
                try slide.show_window();
                return;
            }
        }
        return error.NeverHere;
    }

    // add_clone_silde 函数
    pub fn add_clone_silde(self: *SlideGroup, slide: *Wnd, resource_id: u16, x: i16, y: i16, width: i16, height: i16, p_child_tree: ?*WND_TREE, max_zorder: Z_ORDER_LEVEL) !void {
        const _old_surface = self.get_surface();
        if (null == _old_surface) {
            return error.SurfaceNUll;
        }
        const old_surface = _old_surface.?;
        var new_surface = old_surface.get_display().alloc_surface(max_zorder);
        new_surface.set_active(false);
        self.set_surface(new_surface);
        var page_tmp = slide.connect_clone(self, resource_id, 0, x, y, width, height, p_child_tree);
        self.set_surface(old_surface);
        var i: i32 = 0;
        while (i < MAX_PAGES) : (i += 1) {
            if (self.m_slides[@intCast(i)] == page_tmp) {
                std.debug.assert(false);
                return error.SlideExist;
            }
        }
        i = 0;
        while (i < MAX_PAGES) : (i += 1) {
            if (self.m_slides[@intCast(i)] == null) {
                self.m_slides[@intCast(i)] = page_tmp;
                page_tmp.show_window();
                return;
            }
        }
        std.debug.assert(false);
        return error.NeverHere;
    }

    // disabel_all_slide 函数
    pub fn disabel_all_slide(self: *SlideGroup) void {
        var i: i32 = 0;
        while (i < MAX_PAGES) : (i += 1) {
            if (self.m_slides[@intCast(i)]) |slide| {
                slide.get_surface().?.set_active(false);
            }
        }
    }

    // on_touch 函数
    pub fn on_touch(w: *Wnd, _x: i32, _y: i32, action: TOUCH_ACTION) !void {
        const self: *SlideGroup = @fieldParentPtr("wnd", w);
        const x = _x - w.m_wnd_rect.m_left;
        const y = _y - w.m_wnd_rect.m_top;
        var _gesture = &(self.m_gesture orelse return error.GestureNull);
        try _gesture.handle_swipe(x, y, action);
        if (self.m_slides[@intCast(self.m_active_slide_index)]) |slide| {
            try slide.on_touch(x, y, action);
        }
    }

    // on_key 函数
    pub fn on_key(self: *SlideGroup, key: KEY_TYPE) bool {
        if (self.m_slides[@intCast(self.m_active_slide_index)]) |slide| {
            slide.on_key(key);
        }
        return true;
    }

    // 以下是一些占位函数，根据实际情况完善
    pub inline fn add_child_2_tail(self: *SlideGroup, child: *Wnd) void {
        self.wnd.add_child_2_tail(child);
    }
    pub inline fn get_screen_rect(self: *SlideGroup, rc: *Rect) void {
        self.wnd.get_screen_rect(rc);
    }
    pub inline fn get_surface(self: *SlideGroup) ?*Surface {
        return self.wnd.get_surface();
    }
    pub inline fn set_surface(self: *SlideGroup, surface: *Surface) void {
        self.wnd.set_surface(surface);
    }
};
