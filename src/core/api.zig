const std = @import("std");
pub const types = @import("./types.zig");
const int = types.int;
const uint = types.uint;
pub const REAL_TIME_TASK_CYCLE_MS = 50;
pub inline fn MAX(a: type, b: type) @TypeOf(a) {
    return @max(a, b);
}
pub inline fn MIN(a: type, b: type) @TypeOf(a) {
    return @min(a, b);
}
pub inline fn GL_ARGB(a: uint, r: uint, g: uint, b: uint) uint {
    return ((((a)) << 24) | (((r)) << 16) | (((g)) << 8) | ((b)));
}
pub inline fn GL_ARGB_A(rgb: uint) uint {
    return ((rgb >> 24) & 0xFF);
}
pub inline fn GL_RGB(r: uint, g: uint, b: uint) uint {
    const ret: uint = ((@as(uint, 0xFF) << 24) | ((@as(uint, @as(u32, @bitCast(r)))) << 16) | (((@as(uint, @as(u32, @bitCast(g))))) << 8) | ((@as(uint, @as(u32, @bitCast(b))))));
    return ret;
}
pub inline fn GL_RGB_R(rgb: uint) uint {
    return ((((rgb)) >> 16) & 0xFF);
}
pub inline fn GL_RGB_G(rgb: uint) uint {
    return ((((rgb)) >> 8) & 0xFF);
}
pub inline fn GL_RGB_B(rgb: uint) uint {
    return (((rgb)) & 0xFF);
}
pub inline fn GL_RGB_32_to_16(rgb: uint) u16 {
    const ret: u16 = @truncate(((((rgb)) & 0xFF) >> 3) | ((((rgb)) & 0xFC00) >> 5) | ((((rgb)) & 0xF80000) >> 8));
    return ret;
}
pub inline fn GL_RGB_16_to_32(rgb: uint) uint {
    return ((@as(uint, 0xFF) << 24) | ((((rgb)) & 0x1F) << 3) | ((((rgb)) & 0x7E0) << 5) | ((((rgb)) & 0xF800) << 8));
}

// 1.计算最终的Alpha值：
// A=255−((255−A1)×(255−A2))/255
// 2.计算最终的RGB
// R=((R1×A1+R2×(255−A1))×255)/(A×255)
// G=((G1×A1+G2×(255−A1))×255)/(A×255)
// B=((B1×A1+B2×(255−A1))×255)/(A×255)
pub inline fn GL_MIX_COLOR(rgb1: uint, rgb2: uint) uint {
    const A1 = GL_ARGB_A(rgb1);
    const R1 = GL_RGB_R(rgb1);
    const G1 = GL_RGB_G(rgb1);
    const B1 = GL_RGB_B(rgb1);
    const A2 = GL_ARGB_A(rgb2);
    const R2 = GL_RGB_R(rgb2);
    const G2 = GL_RGB_G(rgb2);
    const B2 = GL_RGB_B(rgb2);
    if (A2 > 0) {
        if (A2 == 255) {
            const A = 255;
            const R = R2;
            const G = G2;
            const B = B2;
            std.log.debug("GL_MIX_COLOR rgb1:{X} rgb2:{X}", .{ rgb1, rgb2 });
            std.log.debug("GL_MIX_COLOR A:{d} R:{d} G:{d} B:{d}", .{ A, R, G, B });
            return GL_ARGB(A, R, G, B);
        } else {
            const A = 255 - ((255 - A1) * (255 - A2) >> 8);
            const R = (R1 * A1 + R2 * A2) >> 8 & 0xFF;
            const G = (G1 * A1 + G2 * A2) >> 8 & 0xFF;
            const B = (B1 * A1 + B2 * A2) >> 8 & 0xFF;
            const ret = GL_ARGB(A, R, G, B);

            std.log.debug("GL_MIX_COLOR rgb1:{X} rgb2:{X}", .{ rgb1, rgb2 });
            std.log.debug("GL_MIX_COLOR A:{d} R:{d} G:{d} B:{d} rgb:{X}", .{ A, R, G, B, ret });
            return ret;
        }
    } else {
        std.log.debug("GL_MIX_COLOR no transparent", .{});
        return rgb2;
    }
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

pub fn register_debug_function(my_assert: *const fn (file: [*]const u8, line: int) void, my_log_out: *const fn (log: [*]const u8) void) void {
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
pub fn register_timer(milli_second: int, func: *const fn (param: *anyopaque) void, param: *anyopaque) void {
    _ = milli_second;
    _ = func;
    _ = param;
}

pub fn get_cur_thread_id() uint {
    return 0;
}
pub fn create_thread(thread_id: types.ulong, attr: *anyopaque, start_routine: *const fn (*anyopaque) *anyopaque, arg: *anyopaque) void {
    _ = thread_id;
    _ = attr;
    _ = start_routine;
    _ = arg;
}
pub fn thread_sleep(milli_seconds: uint) void {
    _ = milli_seconds;
}
pub fn build_bmp(filename: [*]const u8, width: uint, height: uint, data: [*]const u8) int {
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
    fn read(_: c_fifo, buf: *anyopaque, len: int) int {
        _ = buf;
        _ = len;
        return 0;
    }

    fn write(_: c_fifo, buf: *anyopaque, len: int) int {
        _ = buf;
        _ = len;
        return 0;
    }
    m_buf: [FIFO_BUFFER_LEN]u8,
    m_head: int,
    m_tail: int,
    m_read_sem: *anyopaque,
    m_write_mutex: *anyopaque,
};

pub const Rect = struct {
    // public:
    pub fn init() Rect {
        return .{
            .m_left = 0,
            .m_top = 0,
            .m_right = 0,
            .m_bottom = 0,
        };
    }
    pub fn init2(left: int, top: int, _width: uint, _height: uint) Rect {
        var rect = Rect{};
        rect.set_rect(left, top, _width, _height);
        return rect;
    }
    pub fn set_rect(
        this: *Rect,
        left: int,
        top: int,
        _width: uint,
        _height: uint,
    ) void {
        ASSERT(_width > 0 and _height > 0);
        this.m_left = left;
        this.m_top = top;
        this.m_right = left + @as(i32, @bitCast(_width)) - 1;
        this.m_bottom = top + @as(i32, @bitCast(_height)) - 1;
    }
    pub fn scale_pixel(this: Rect, size: int) Rect {
        var rect = this;
        rect.m_left += -size;
        rect.m_top += -size;
        rect.m_right += size;
        rect.m_bottom += size;
        return rect;
    }
    pub fn pt_in_rect(this: Rect, x: int, y: int) bool {
        return x >= this.m_left and x <= this.m_right and y >= this.m_top and y <= this.m_bottom;
    }
    pub fn eql(this: Rect, rect: Rect) bool {
        return (this.m_left == rect.m_left) and //
            (this.m_top == rect.m_top) and //
            (this.m_right == rect.m_right) and //
            (this.m_bottom == rect.m_bottom);
    }
    pub fn add(this: *Rect, other: Rect) void {
        this.m_left +%= other.m_left;
        this.m_top +%= other.m_top;
        this.m_right +%= other.m_right;
        this.m_bottom +%= other.m_bottom;
    }
    pub fn width(this: Rect) uint {
        return @as(u32, @bitCast(this.m_right - this.m_left + 1));
    }
    pub fn height(this: Rect) uint {
        return @as(uint, @bitCast(this.m_bottom - this.m_top + 1));
    }

    m_left: int = 0,
    m_top: int = 0,
    m_right: int = 0,
    m_bottom: int = 0,
};

pub fn strlen(str: []const u8) usize {
    return std.mem.len(@as([*c]const u8, str.ptr));
}

pub fn strcpy(dst: []u8, src: []const u8) void {
    // std.mem.copyForwards(u8, dst, src);
    const end = dst.len - 1;
    var dstCnt: usize = 0;
    for (0.., src) |i, c| {
        if (i < end) {
            dst[i] = c;
        }
        dstCnt += 1;
    }
    if (dstCnt < end) {
        dst[dstCnt + 1] = 0;
        // std.log.err("strcpy dstCnt:{d}", .{dstCnt});
    }
}
