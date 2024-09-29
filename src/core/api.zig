const std = @import("std");
pub const types = @import("./types.zig");
pub const REAL_TIME_TASK_CYCLE_MS = 50;
pub inline fn MAX(a: type, b: type) @TypeOf(a) {
    return @max(a, b);
}
pub inline fn MIN(a: type, b: type) @TypeOf(a) {
    return @min(a, b);
}
pub inline fn GL_ARGB(a: types.int, r: types.int, g: types.int, b: types.int) types.int {
    return ((((a)) << 24) | (((r)) << 16) | (((g)) << 8) | ((b)));
}
pub inline fn GL_ARGB_A(rgb: types.int) types.int {
    return ((rgb >> 24) & 0xFF);
}
pub inline fn GL_RGB(r: types.int, g: types.int, b: types.int) types.int {
    const ret = ((@as(usize, 0xFF) << 24) | ((@as(usize, @as(u32, @bitCast(r)))) << 16) | (((@as(usize, @as(u32, @bitCast(g))))) << 8) | ((@as(usize, @as(u32, @bitCast(b))))));
    return @bitCast(@as(u32, @truncate(ret)));
}
pub inline fn GL_RGB_R(rgb: types.int) types.int {
    return ((((rgb)) >> 16) & 0xFF);
}
pub inline fn GL_RGB_G(rgb: types.int) types.int {
    return ((((rgb)) >> 8) & 0xFF);
}
pub inline fn GL_RGB_B(rgb: types.int) types.int {
    return (((rgb)) & 0xFF);
}
pub inline fn GL_RGB_32_to_16(rgb: types.int) u16 {
    const ret: i16 = @truncate(((((rgb)) & 0xFF) >> 3) | ((((rgb)) & 0xFC00) >> 5) | ((((rgb)) & 0xF80000) >> 8));
    return @bitCast(ret);
}
pub inline fn GL_RGB_16_to_32(rgb: types.int) types.int {
    return ((@as(types.int, 0xFF) << 24) | ((((rgb)) & 0x1F) << 3) | ((((rgb)) & 0x7E0) << 5) | ((((rgb)) & 0xF800) << 8));
}

pub const ALIGN_HCENTER = 0x00000000;
pub const ALIGN_LEFT = 0x01000000;
pub const ALIGN_RIGHT = 0x02000000;
pub const ALIGN_HMASK = 0x03000000;

pub const ALIGN_VCENTER = 0x00000000;
pub const ALIGN_TOP = 0x00100000;
pub const ALIGN_BOTTOM = 0x00200000;
pub const ALIGN_VMASK = 0x00300000;

pub const T_TIME = struct {
    year: u16,
    month: u16,
    date: u16,
    day: u16,
    hour: u16,
    minute: u16,
    second: u16,
};

pub fn register_debug_function(my_assert: *const fn (file: [*]const u8, line: types.int) void, my_log_out: *const fn (log: [*]const u8) void) void {
    _ = my_assert;
    _ = my_log_out;
}

// #define ASSERT(condition)	\
// 	do{                     \
// 	if(!(condition))_assert(__FILE__, __LINE__);\
// 	}while(0)

pub noinline fn ASSERT(condition: bool) void {
    if (!condition) {
        // const loc = @src();
        // std.log.err("ASSERT {s}:{d}:{d}", .{ loc.file, loc.line, loc.column });
        std.debug.dumpCurrentStackTrace(null);
        std.process.exit(1);
    }
}
pub fn log_out(log: [*]const u8) void {
    _ = log;
}

pub fn get_time_in_second() i64 {
    return 0;
}
pub fn second_to_day(second: i64) T_TIME {
    _ = second;
    return .{};
}
pub fn get_time() T_TIME {
    return .{};
}

pub fn start_real_timer(func: *const fn (arg: *anyopaque) void) void {
    _ = func;
}
pub fn register_timer(milli_second: types.int, func: *const fn (param: *anyopaque) void, param: *anyopaque) void {
    _ = milli_second;
    _ = func;
    _ = param;
}

pub fn get_cur_thread_id() types.uint {
    return 0;
}
pub fn create_thread(thread_id: types.ulong, attr: *anyopaque, start_routine: *const fn (*anyopaque) *anyopaque, arg: *anyopaque) void {
    _ = thread_id;
    _ = attr;
    _ = start_routine;
    _ = arg;
}
pub fn thread_sleep(milli_seconds: types.uint) void {
    _ = milli_seconds;
}
pub fn build_bmp(filename: [*]const u8, width: types.uint, height: types.uint, data: [*]const u8) types.int {
    _ = filename;
    _ = width;
    _ = height;
    _ = data;
    return 0;
}

pub const FIFO_BUFFER_LEN = 1024;

pub const c_fifo = struct {
    pub fn init() c_fifo {
        return .{};
    }
    fn read(_: c_fifo, buf: *anyopaque, len: types.int) types.int {
        _ = buf;
        _ = len;
        return 0;
    }

    fn write(_: c_fifo, buf: *anyopaque, len: types.int) types.int {
        _ = buf;
        _ = len;
        return 0;
    }
    m_buf: [FIFO_BUFFER_LEN]u8,
    m_head: types.int,
    m_tail: types.int,
    m_read_sem: *anyopaque,
    m_write_mutex: *anyopaque,
};

pub const c_rect = struct {
    // public:
    pub fn init() c_rect {
        return .{
            .m_left = -1,
            .m_top = -1,
            .m_right = -1,
            .m_bottom = -1,
        };
    }
    pub fn init2(left: types.int, top: types.int, _width: types.int, _height: types.int) c_rect {
        var rect = c_rect{};
        rect.set_rect(left, top, _width, _height);
        return rect;
    }
    pub fn set_rect(
        this: *c_rect,
        left: types.int,
        top: types.int,
        _width: types.int,
        _height: types.int,
    ) void {
        ASSERT(_width > 0 and _height > 0);
        this.m_left = left;
        this.m_top = top;
        this.m_right = left + _width - 1;
        this.m_bottom = top + _height - 1;
    }
    pub fn pt_in_rect(this: c_rect, x: types.int, y: types.int) bool {
        return x >= this.m_left and x <= this.m_right and y >= this.m_top and y <= this.m_bottom;
    }
    pub fn eql(this: c_rect, rect: c_rect) bool {
        return (this.m_left == rect.m_left) and //
            (this.m_top == rect.m_top) and //
            (this.m_right == rect.m_right) and //
            (this.m_bottom == rect.m_bottom);
    }
    pub fn width(this: c_rect) types.int {
        return this.m_right - this.m_left + 1;
    }
    pub fn height(this: c_rect) types.int {
        return this.m_bottom - this.m_top + 1;
    }

    m_left: types.int = -1,
    m_top: types.int = -1,
    m_right: types.int = -1,
    m_bottom: types.int = -1,
};

pub fn strlen(str: []const u8) usize {
    std.mem.len(@as([*c]const u8, str));
}
