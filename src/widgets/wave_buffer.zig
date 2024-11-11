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
const Rect = api.Rect;
const Word = word.Word;
const Theme = theme.Theme;
const int = types.int;
const uint = types.uint;

const WAVE_BUFFER_LEN: i16 = 1024;
const WAVE_READ_CACHE_LEN: i16 = 8;
const BUFFER_EMPTY: int = -1111;
const BUFFER_FULL: int = -2222;

pub const WaveBuffer = struct {
    m_wave_buf: [WAVE_BUFFER_LEN]i16 = std.mem.zeroes([WAVE_BUFFER_LEN]i16),
    m_head: i16 = 0,
    m_tail: i16 = 0,

    m_min_old: isize = 0,
    m_max_old: isize = 0,
    m_min_older: isize = 0,
    m_max_older: isize = 0,
    m_last_data: isize = 0,

    m_read_cache_min: [WAVE_READ_CACHE_LEN]i16 = std.mem.zeroes([WAVE_READ_CACHE_LEN]i16),
    m_read_cache_mid: [WAVE_READ_CACHE_LEN]i16 = std.mem.zeroes([WAVE_READ_CACHE_LEN]i16),
    m_read_cache_max: [WAVE_READ_CACHE_LEN]i16 = std.mem.zeroes([WAVE_READ_CACHE_LEN]i16),
    m_read_cache_sum: i16 = 0,
    m_refresh_sequence: usize = 0,

    pub fn write_wave_data(this: *WaveBuffer, data: i16) int {
        if (@mod((this.m_tail + 1), WAVE_BUFFER_LEN) == this.m_head) { //full
            //log_out("wave buf full\n");
            return BUFFER_FULL;
        }
        this.m_wave_buf[@as(usize, @intCast(this.m_tail))] = @intCast(data);
        this.m_tail = @mod((this.m_tail + 1), WAVE_BUFFER_LEN);
        return 1;
    }
    pub fn read_wave_data_by_frame(this: *WaveBuffer, max: *i16, min: *i16, frame_len: usize, sequence: uint, offset: usize) int {
        if (this.m_refresh_sequence != sequence) {
            this.m_refresh_sequence = sequence;
            this.m_read_cache_sum = 0;
        } else if (offset < this.m_read_cache_sum) //(m_refresh_sequence == sequence && offset < m_fb_sum)
        {
            max.* = this.m_read_cache_max[offset];
            min.* = this.m_read_cache_min[offset];
            return this.m_read_cache_mid[offset];
        }

        this.m_read_cache_sum +%= 1;
        api.ASSERT(this.m_read_cache_sum <= WAVE_READ_CACHE_LEN);
        var data: int = 0;
        var tmp_min = this.m_last_data;
        var tmp_max = this.m_last_data;
        const mid = (this.m_min_old + this.m_max_old) >> 1;

        for (0..frame_len) |_| {
            data = this.read_data();
            if (BUFFER_EMPTY == data) {
                break;
            }
            this.m_last_data = data;

            if (data < tmp_min) {
                tmp_min = data;
            }
            if (data > tmp_max) {
                tmp_max = data;
            }
        }

        this.m_read_cache_min[offset] = @as(i16, @truncate(@min(this.m_min_old, @min(tmp_min, this.m_min_older))));
        min.* = this.m_read_cache_min[offset];
        this.m_read_cache_max[offset] = @as(i16, @truncate(@max(this.m_max_old, @max(tmp_max, this.m_max_older))));
        max.* = this.m_read_cache_max[offset];

        this.m_min_older = this.m_min_old;
        this.m_max_older = this.m_max_old;
        this.m_min_old = tmp_min;
        this.m_max_old = tmp_max;
        this.m_read_cache_mid[offset] = @truncate(mid);
        return @intCast(mid);
    }
    fn reset(this: *WaveBuffer) void {
        this.m_head = this.m_tail;
    }
    fn clear_data(this: *WaveBuffer) void {
        this.m_head = 0;
        this.m_tail = 0;
        @memset(this.m_wave_buf, 0);
    }
    fn get_cnt(this: *const WaveBuffer) i16 {
        return if (this.m_tail >= this.m_head) (this.m_tail - this.m_head) else (this.m_tail - this.m_head + WAVE_BUFFER_LEN);
    }
    fn read_data(this: *WaveBuffer) int {
        if (this.m_head == this.m_tail) { //empty
            return BUFFER_EMPTY;
        }
        const ret = this.m_wave_buf[@intCast(this.m_head)];
        this.m_head = @mod((this.m_head + 1), WAVE_BUFFER_LEN);
        return ret;
    }
};
