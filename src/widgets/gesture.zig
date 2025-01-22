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

const slide_group = @import("./slide_group.zig");
const SlideGroup = slide_group.SlideGroup;
const TOUCH_ACTION = wnd.TOUCH_ACTION;
const MOVE_THRESHOLD = 10;
const SWIPE_STEP = 10;
const MAX_PAGES = slide_group.MAX_PAGES;

// 定义 TOUCH_STATE 枚举类型
const TOUCH_STATE = enum {
    TOUCH_MOVE,
    TOUCH_IDLE,
};
// 定义 Gesture 结构体
pub const Gesture = struct {
    m_down_x: i32,
    m_down_y: i32,
    m_move_x: i32,
    m_move_y: i32,
    m_state: TOUCH_STATE,
    m_slide_group: *SlideGroup,

    // 构造函数
    pub fn init(group: *SlideGroup) Gesture {
        return Gesture{
            .m_down_x = 0,
            .m_down_y = 0,
            .m_move_x = 0,
            .m_move_y = 0,
            .m_state = TOUCH_STATE.TOUCH_IDLE,
            .m_slide_group = group,
        };
    }

    // handle_swipe 函数
    pub fn handle_swipe(self: *Gesture, x: i32, y: i32, action: TOUCH_ACTION) !void {
        std.log.debug("SlideGroup handle_swipe self:{*},({},{}) action:{} state:{}", .{ self, x, y, action, self.m_state });
        switch (action) {
            .TOUCH_DOWN => {
                if (self.m_state == TOUCH_STATE.TOUCH_IDLE) {
                    self.m_state = TOUCH_STATE.TOUCH_MOVE;
                    self.m_move_x = x;
                    self.m_down_x = x;
                    std.log.debug("SlideGroup handle_swipe touch idle", .{});
                    return;
                } else { // TOUCH_MOVE
                    return self.on_move(x);
                }
            },
            .TOUCH_UP => {
                if (self.m_state == TOUCH_STATE.TOUCH_MOVE) {
                    self.m_state = TOUCH_STATE.TOUCH_IDLE;
                    return self.on_swipe(x);
                } else {
                    return error.NotInTouchMove;
                }
            },
            .TOUCH_MOVE => {
                if (self.m_state != .TOUCH_IDLE) {
                    return self.on_move(x);
                }
            },
        }
        return;
    }

    // on_move 函数
    pub fn on_move(self: *Gesture, x: i32) !void {
        std.log.debug("SlideGroup on_move x:{d} m_down_x:{d} m_move_x:{d}", .{ x, self.m_down_x, self.m_move_x });
        if (@abs(x - self.m_move_x) < MOVE_THRESHOLD) {
            return error.MoveDistanceTooShort;
        }
        self.m_slide_group.disabel_all_slide();
        self.m_move_x = x;
        if ((self.m_move_x - self.m_down_x) > 0) {
            try self.move_right();
        } else {
            try self.move_left();
        }
    }

    // on_swipe 函数
    pub fn on_swipe(self: *Gesture, x: i32) !void {
        std.log.debug("SlideGroup on_swipe[[ x:{}", .{x});
        defer std.log.debug("SlideGroup on_swipe]] x:{}", .{x});
        if ((self.m_down_x == self.m_move_x) and (@abs(x - self.m_down_x) < MOVE_THRESHOLD)) {
            return error.MoveDistanceTooShort;
        }
        self.m_slide_group.disabel_all_slide();
        var page: i32 = -1;
        self.m_move_x = x;
        if ((self.m_move_x - self.m_down_x) > 0) {
            page = try self.swipe_right();
        } else {
            page = try self.swipe_left();
        }
        if (page >= 0) {
            try self.m_slide_group.set_active_slide(page, true);
        } else {
            try self.m_slide_group.set_active_slide(self.m_slide_group.get_active_slide_index(), false);
        }
        return;
    }

    // swipe_left 函数
    pub fn swipe_left(self: *Gesture) !i32 {
        const index = self.m_slide_group.get_active_slide_index();
        if ((index + 1) >= MAX_PAGES) {
            return error.OutOfIndex;
        }

        const slide0 = self.m_slide_group.get_slide(index) orelse return error.SlideNull;
        const slide1 = self.m_slide_group.get_slide(index + 1) orelse return error.SlideNull;
        const s1 = slide1.get_surface() orelse return error.SurfaceNUll;
        const s2 = slide0.get_surface() orelse return error.SurfaceNUll;
        const display1 = s1.get_display() orelse return error.DisplayNull;
        const disylay2 = s2.get_display() orelse return error.DisplayNull;
        if (display1 != disylay2) {
            return error.DisplayNotSame;
        }
        var step = self.m_down_x - self.m_move_x;
        var rc = Rect.init();
        self.m_slide_group.get_screen_rect(&rc);
        while (step < rc.width()) : (step += SWIPE_STEP) {
            try display1.swipe_surface(s2, s1, rc.m_left, rc.m_right, rc.m_top, rc.m_bottom, step);
        }
        if (step != rc.width()) {
            try display1.swipe_surface(s2, s1, rc.m_left, rc.m_right, rc.m_top, rc.m_bottom, @intCast(rc.width()));
        }
        return (index + 1);
    }

    // swipe_right 函数
    pub fn swipe_right(self: *Gesture) !i32 {
        const index = self.m_slide_group.get_active_slide_index();
        if (index <= 0) {
            return error.OutOfIndex;
        }
        const slide0 = self.m_slide_group.get_slide(index - 1) orelse return error.SlideNull;
        const slide1 = self.m_slide_group.get_slide(index) orelse return error.SlideNull;
        const s1 = slide0.get_surface() orelse return error.SurfaceNUll;
        const display1 = s1.get_display() orelse return error.DisplayNull;
        const s2 = slide1.get_surface() orelse return error.SurfaceNUll;
        const display2 = s2.get_display() orelse return error.DisplayNull;

        if (display1 != display2) {
            return error.DisplayNotSame;
        }
        var rc = Rect.init();
        self.m_slide_group.get_screen_rect(&rc);
        var step = @as(i32, @intCast(rc.width())) - (self.m_move_x - self.m_down_x);
        while (step > 0) : (step -= SWIPE_STEP) {
            try display1.swipe_surface(s1, s2, rc.m_left, rc.m_right, rc.m_top, rc.m_bottom, step);
        }
        if (step != 0) {
            try display2.swipe_surface(s1, s2, rc.m_left, rc.m_right, rc.m_top, rc.m_bottom, 0);
        }
        return (index - 1);
    }

    // move_left 函数
    pub fn move_left(self: *Gesture) !void {
        const index = self.m_slide_group.get_active_slide_index();
        if ((index + 1) >= MAX_PAGES) {
            return error.ActiveIndex;
        }
        const _slide0 = self.m_slide_group.get_slide(index + 1);
        const _slide1 = self.m_slide_group.get_slide(index);
        if (_slide0 == null) {
            return error.SlideNull;
        }
        if (_slide1 == null) {
            return error.SlideNull;
        }
        const slide0 = _slide0.?;
        const slide1 = _slide1.?;

        const s1 = slide0.get_surface() orelse return error.SurfaceNUll;
        const s1Display = s1.get_display() orelse return error.DsplayNull;

        const s2 = slide1.get_surface() orelse return error.SurfaceNUll;

        const s2Display = s2.get_display() orelse return error.DsplayNull;

        var rc = Rect.init();
        self.m_slide_group.get_screen_rect(&rc);
        if (s1Display == s2Display) {
            try s1Display.swipe_surface(s2, s1, rc.m_left, rc.m_right, rc.m_top, rc.m_bottom, (self.m_down_x - self.m_move_x));
        }
    }

    // move_right 函数
    pub fn move_right(self: *Gesture) !void {
        const index = self.m_slide_group.get_active_slide_index();
        if (index <= 0) {
            return error.ActiveIndex;
        }
        const _slide0 = self.m_slide_group.get_slide(index - 1);
        const _slide1 = self.m_slide_group.get_slide(index);
        if (_slide0 == null) {
            return error.SlideNull;
        }
        if (_slide1 == null) {
            return error.SlideNull;
        }
        const slide0 = _slide0.?;
        const slide1 = _slide1.?;

        const s1 = slide0.get_surface() orelse return error.SurfaceNUll;
        const s1Display = s1.get_display() orelse return error.DsplayNull;

        const s2 = slide1.get_surface() orelse return error.SurfaceNUll;

        const s2Display = s2.get_display() orelse return error.DsplayNull;

        var rc = Rect.init();
        self.m_slide_group.get_screen_rect(&rc);
        if (s1Display == s2Display) {
            s2Display.swipe_surface(s1, s2, rc.m_left, rc.m_right, rc.m_top, rc.m_bottom, (@as(i32, @intCast(rc.width())) - self.m_move_x - self.m_down_x)) catch {};
        }
    }
};
