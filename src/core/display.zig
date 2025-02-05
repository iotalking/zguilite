const std = @import("std");
const types = @import("./types.zig");
const api = @import("./api.zig");
const core = @import("./core.zig");
const int = types.int;
const uint = types.uint;
const Rect = api.Rect;
pub const SURFACE_CNT_MAX = 6; //root + pages

pub const Z_ORDER_LEVEL = enum {
    Z_ORDER_LEVEL_0, //lowest graphic level
    Z_ORDER_LEVEL_1, //middle graphic level, call activate_layer before use it, draw everything inside the active rect.
    Z_ORDER_LEVEL_2, //highest graphic level, call activate_layer before use it, draw everything inside the active rect.
    Z_ORDER_LEVEL_MAX,
};

pub const Z_ORDER_LEVEL_0 = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_0);
pub const Z_ORDER_LEVEL_1 = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_1);
pub const Z_ORDER_LEVEL_2 = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_2);
pub const Z_ORDER_LEVEL_MAX = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX);

pub const DISPLAY_DRIVER = struct {
    // void(*draw_pixel)(int x, int y, unsigned int rgb);
    draw_pixel: ?*const fn (x: int, y: int, rgb: uint) void,
    // void(*fill_rect)(int x0, int y0, int x1, int y1, unsigned int rgb);
    fill_rect: ?*const fn (x0: int, y0: int, x1: int, y1: int, rgb: uint) void,
};

// class Surface;
pub const Display = struct {
    // 	friend class Surface;
    // public:
    pub inline fn init(phy_fb: *anyopaque, display_width: int, display_height: int, surface: *Surface, driver: *DISPLAY_DRIVER) Display {
        const this = Display{};
        this.m_phy_fb = phy_fb;
        this.m_width = display_width;
        this.m_height = display_height;
        this.m_driver = driver;
        this.m_phy_read_index = 0;
        this.m_phy_write_index = 0;
        this.m_surface_cnt = 1;
        this.m_surface_index = 0;
        this.m_color_bytes = surface.m_color_bytes;
        surface.m_is_active = true;
        this.m_surface_group[0] = surface;
        surface.*.attach_display(this);
        return this;
    }
    pub inline fn init2(this: *Display, phy_fb: [*]u8, display_width: int, display_height: int, surface_width: int, surface_height: int, color_bytes: uint, surface_cnt: int, driver: ?*const DISPLAY_DRIVER) !void {
        this.* = Display{
            .m_phy_fb = phy_fb,
            .m_width = display_width,
            .m_height = display_height,
            .m_color_bytes = color_bytes,
            .m_phy_read_index = 0,
            .m_phy_write_index = 0,
            .m_surface_cnt = surface_cnt,
            .m_driver = driver,
            .m_surface_index = 0,
        };
        api.ASSERT(color_bytes == 2 or color_bytes == 4);
        api.ASSERT(this.m_surface_cnt <= SURFACE_CNT_MAX);
        @memset(&this.m_surface_group, null);

        var i: usize = 0;
        errdefer {
            while (i >= 0) {
                const _free_surface = this.m_surface_group[i];
                if (_free_surface) |free_surface| {
                    core.allocator.destroy(free_surface);
                }
            }
        }
        while (i < this.m_surface_cnt) : (i += 1) {
            // const tmp_surface = try core.allocator.create(Surface);
            // tmp_surface = Surface.init(width: uint, height: uint, color_bytes: uint, max_zorder: Z_ORDER_LEVEL, overlpa_rect: Rect)
            const tmp_surface = try Surface.init(core.allocator, surface_width, surface_height, color_bytes, .Z_ORDER_LEVEL_0, Rect.init());
            this.m_surface_group[i] = tmp_surface;
            // 		m_surface_group[i]->attach_display(this);
            tmp_surface.attach_display(this);
        }
        return;
    }
    pub inline fn allocSurface(this: *Display, max_zorder: Z_ORDER_LEVEL, layer_rect: Rect) !*Surface {
        std.log.debug("display allocSurface max_zorder:{} m_surface_index:{} m_surface_cnt:{}", .{ max_zorder, this.m_surface_index, this.m_surface_cnt });
        api.ASSERT(@intFromEnum(max_zorder) < @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX) and this.m_surface_index < this.m_surface_cnt);
        const m_surface_index: usize = @intCast(this.m_surface_index);
        if (layer_rect.eql(Rect.init())) {
            if (this.m_surface_group[m_surface_index]) |surface| {
                try surface.set_surface(max_zorder, Rect.init2(0, 0, @as(u32, @bitCast(this.m_width)), @as(u32, @bitCast(this.m_height))));
            }
        } else {
            if (this.m_surface_group[m_surface_index]) |surface| {
                try surface.set_surface(max_zorder, layer_rect);
            }
        }
        const ret = this.m_surface_group[m_surface_index].?;
        this.m_surface_index += 1;
        return ret;
    }
    pub fn swipe_surface(self: *Display, s0: *Surface, s1: *Surface, _x0: int, _x1: int, _y0: int, _y1: int, _offset: int) !void {
        const surface_width = s0.m_width;
        const surface_height = s0.m_height;
        const offset: u32 = @bitCast(_offset);

        if (offset < 0 or offset > surface_width or _y0 < 0 or _y0 >= surface_height or
            _y1 < 0 or _y1 >= surface_height or _x0 < 0 or _x0 >= surface_width or
            _x1 < 0 or _x1 >= surface_width)
        {
            return error.ParamInvalid;
        }

        const width: u32 = @bitCast(_x1 - _x0 + 1);
        if (width < 0 or width > surface_width or width < offset) {
            std.debug.assert(false);
            return error.ParamInvalid;
        }

        const x0: u32 = @bitCast(if (_x0 >= self.m_width) self.m_width - 1 else _x0);
        const x1: u32 = @bitCast(if (_x1 >= self.m_width) self.m_width - 1 else _x1);
        const y0: u32 = @bitCast(if (_y0 >= self.m_height) self.m_height - 1 else _y0);
        const y1: u32 = @bitCast(if (_y1 >= self.m_height) self.m_height - 1 else _y1);
        const um_width: u32 = @bitCast(self.m_width);
        if (self.m_phy_fb) |phy_fb| {
            // for (y0..y1) |y| {
            var y: u32 = @bitCast(y0);
            while (y <= y1) : (y += 1) {
                // Left surface
                const addr_s: [*]u8 = @ptrFromInt(@intFromPtr(s0.m_fb) + (y * surface_width + x0 + offset) * self.m_color_bytes);
                const addr_d: [*]u8 = @ptrFromInt(@intFromPtr(phy_fb) + (y * um_width + x0) * self.m_color_bytes);
                // std.mem.copyForwards(u8, addr_d[0..(width - offset) * self.m_color_bytes], addr_s[0..(width - offset) * self.m_color_bytes]);
                @memcpy(addr_d[0 .. (width - offset) * self.m_color_bytes], addr_s[0 .. (width - offset) * self.m_color_bytes]);

                // Right surface
                const addr_s_right: [*]u8 = @ptrFromInt(@intFromPtr(s1.m_fb) + (y * surface_width + x0) * self.m_color_bytes);
                const addr_d_right: [*]u8 = @ptrFromInt(@intFromPtr(phy_fb) + (y * um_width + x0 + (width - offset)) * self.m_color_bytes);
                // std.mem.copyForwards(u8, addr_d_right[0..offset * self.m_color_bytes], addr_s_right[0..offset * self.m_color_bytes]);
                @memcpy(addr_d_right[0 .. offset * self.m_color_bytes], addr_s_right[0 .. offset * self.m_color_bytes]);
            }
        } else if (self.m_color_bytes == 4) {
            // const draw_pixel = s0.m_gfx_op.?.draw_pixel;
            const draw_pixel = self.m_driver.?.draw_pixel.?;
            // for (y0..y1) |y| {
            var y: u32 = @intCast(y0);
            while (y <= y1) : (y += 1) {
                // Left surface
                // for (x0..(x1 - offset)) |x| {
                var x: u32 = @intCast(x0);
                const iy: i32 = @intCast(y);
                while (x <= (x1 - offset)) : (x += 1) {
                    const ix: i32 = @intCast(x);
                    draw_pixel(ix, iy, @as([*]u32, @alignCast(@ptrCast(s0.m_fb)))[y * um_width + x + offset]);
                }

                // Right surface
                // for ((x1 - offset)..x1) |x| {
                x = x1 - offset;
                while (x <= x1) : (x += 1) {
                    const ix: i32 = @intCast(x);
                    draw_pixel(ix, iy, @as([*]u32, @alignCast(@ptrCast(s1.m_fb)))[y * um_width + x + offset - x1 + x0]);
                }
            }
        } else if (self.m_color_bytes == 2) {
            const draw_pixel = self.m_driver.?.draw_pixel.?;
            var y: u32 = @intCast(y0);
            while (y <= y1) : (y += 1) {
                // Left surface
                const iy: i32 = @intCast(y);
                // for (x0..(x1 - offset)) |x| {
                var x: u32 = x0;
                while (x <= (x1 - offset)) : (x += 1) {
                    const ix: i32 = @intCast(x);
                    draw_pixel(ix, iy, api.GL_RGB_16_to_32(@as([*]u16, @alignCast(@ptrCast(s0.m_fb)))[y * um_width + x + offset]));
                }

                // Right surface
                x = x1 - offset;
                // for ((x1 - offset)..x1) |x| {
                while (x <= x1) : (x += 1) {
                    const ix: i32 = @intCast(x);
                    draw_pixel(ix, iy, api.GL_RGB_16_to_32(@as([*]u16, @alignCast(@ptrCast(s1.m_fb)))[y * um_width + x + offset - x1 + x0]));
                }
            }
        }

        self.m_phy_write_index += 1;
        if (self.m_phy_fb) |fb| {
            _ = self.flush_screen(self, _x0, _y0, _x1, _y1, fb, @intCast(surface_width));
        }

        return;
    }

    // 	inline Display(void* phy_fb, int display_width, int display_height, int surface_width, int surface_height, unsigned int color_bytes, int surface_cnt, DISPLAY_DRIVER* driver = 0);//multiple surface
    // 	inline Surface* allocSurface(Z_ORDER_LEVEL max_zorder, Rect layer_rect = Rect());//for slide group
    // 	inline int swipe_surface(Surface* s0, Surface* s1, int x0, int x1, int y0, int y1, int offset);
    fn get_width(this: Display) int {
        return this.m_width;
    }
    fn get_height(this: Display) int {
        return this.m_height;
    }
    fn get_phy_fb(this: Display) [*]u8 {
        return this.m_phy_fb;
    }

    pub fn get_updated_fb(this: *Display, width: ?*int, height: ?*int, force_update: bool) ?*anyopaque {
        if (width != null)
        {
            width.?.* = this.m_width;
        }
        if (height != null)
        {
            height.?.* = this.m_height;
        }
        
        if (force_update) {
            return this.m_phy_fb;
        }
        if (this.m_phy_read_index == this.m_phy_write_index) { //No update
            return null;
        }
        this.m_phy_read_index = this.m_phy_write_index;
        return this.m_phy_fb;
    }

    fn snap_shot(this: *Display, file_name: [*]const u8) !int {
        if (this.m_phy_fb or (this.m_color_bytes != 2 and this.m_color_bytes != 4)) {
            return -1;
        }

        //16 bits framebuffer
        if (this.m_color_bytes == 2) {
            return api.build_bmp(file_name, this.m_width, this.m_height, this.m_phy_fb);
        }

        //32 bits framebuffer
        const p_bmp565_data = try core.allocator.alloc(@sizeOf(*u16) * this.m_width * this.m_height);
        defer core.allocator.free(p_bmp565_data);
        const p_raw_data: *uint = @ptrCast(p_bmp565_data);
        for (0..(this.m_width * this.m_height)) |i| {
            const rgb = p_raw_data[0];
            p_raw_data += 1;
            p_bmp565_data[i] = api.GL_RGB_32_to_16(rgb);
        }

        const ret = api.build_bmp(file_name, this.m_width, this.m_height, p_bmp565_data);
        return ret;
    }

    // protected:
    fn draw_pixel_impl(this: *Display, x: int, y: int, rgb: uint) void {
        // std.log.debug("display draw_pixel_impl({},{},{})", .{ x, y, rgb });
        if ((x >= this.m_width) or (y >= this.m_height)) {
            return;
        }

        if (this.m_driver) |driver| {
            if (driver.draw_pixel) |draw_pixel| {
                return draw_pixel(x, y, rgb);
            }
        }

        if (this.m_color_bytes == 2) {
            const fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_phy_fb.?));
            fb_u16[@intCast(y * @as(int, @intCast(this.m_width)) + x)] = api.GL_RGB_32_to_16(rgb);
        } else {
            // std.log.debug("({},{}) m_width:{}", .{ x, y, this.m_width });
            const fb_u32: [*]u32 = @ptrCast(@alignCast(this.m_phy_fb.?));
            fb_u32[@intCast(y * this.m_width + x)] = @bitCast(rgb);
        }
    }

    fn fill_rect_impl(this: *Display, x0: int, y0: int, x1: int, y1: int, rgb: uint) void {
        const ux0: usize = @intCast(x0);
        const uy0: usize = @intCast(y0);
        const ux1: usize = @intCast(x1);
        const uy1: usize = @intCast(y1);

        if (this.m_driver) |driver| {
            if (driver.fill_rect) |fill_rect| {
                return fill_rect(x0, y0, x1, y1, rgb);
            }
        }

        if (this.m_driver) |driver| {
            // for (int y = y0; y <= y1; y++)
            if (driver.draw_pixel) |draw_pixel| {
                var y = uy0;
                while (y <= uy1) : (y += 1) {
                    var x = ux0;
                    while (x <= ux1) : (x += 1) {
                        draw_pixel(@intCast(x), @intCast(y), rgb);
                    }
                }
            }
            return;
        }

        const _width: usize = @intCast(@as(u32, @bitCast(this.m_width)));
        const _height = this.m_height;
        if (this.m_color_bytes == 2) {
            const rgb_16 = api.GL_RGB_32_to_16(rgb);
            var fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_phy_fb.?));
            var y = uy0;
            while(y <= uy1):(y += 1){
                var x = ux0;
                while(x <= ux1):(x += 1){
                    if ((x < _width) and (y < _height)) {
                        fb_u16[y * _width + x] = rgb_16;
                    }
                }
            }
        } else {
            const rgb_32: u32 = @bitCast(rgb);
            // std.log.debug("this.m_phy_fb:{*}", .{this.m_phy_fb});
            const phy_fb: [*]u32 = @alignCast(@ptrCast(this.m_phy_fb.?));
            var y = uy0;
            while(y <= y1):(y += 1){
                var x = ux0;
                while(x <= ux1):(x += 1){
                    if ((x < _width) and (y < _height)) {
                        // std.log.debug("phy_fb:{*},_width:{} ({},{})={}", .{ phy_fb, _width, x, y, rgb_32 });
                        phy_fb[y * _width + x] = rgb_32;
                    }
                }
            }
        }
    }

    fn flush_screen_impl(this: *Display, left: int, top: int, right: int, bottom: int, fb: *anyopaque, fb_width: int) int {
        if ((null == this.m_phy_fb)) {
            return -1;
        }
        const m_phy_fb = this.m_phy_fb.?;

        const uleft: usize = @intCast(@as(u32, @bitCast(left)));
        const utop: usize = @intCast(@as(u32, @bitCast(top)));
        const uright: usize = @intCast(@as(u32, @bitCast(right)));
        const ubottom: usize = @intCast(@as(u32, @bitCast(bottom)));
        const _width: usize = @intCast(@as(u32, @bitCast(this.m_width)));
        const _height: usize = @intCast(@as(u32, @bitCast(this.m_height)));
        const color_bytes: usize = @intCast(@as(u32, @bitCast(this.m_color_bytes)));
        const _left = if (uleft >= _width) (_width - 1) else uleft;
        const _right = if (uright >= _width) (_width - 1) else uright;
        const _top = if (utop >= _height) (_height - 1) else utop;
        const _bottom = if (ubottom >= _height) (_height - 1) else ubottom;

        const ufbwidth: usize = @intCast(@as(u32, @bitCast(fb_width)));
        const _fb: [*]u8 = @ptrCast(fb);
        // // // for (int y = top; y < bottom; y++)
        const count = (_right - _left) * color_bytes;
        for (_top.._bottom) |y| {
            // std.log.debug("_right:{},_left:{},color_bytes:{} y:{} count:{}", .{ _right, _left, color_bytes, y, count });
            const s_addr: []u8 = (_fb + ((y * ufbwidth + _left) * color_bytes))[0..count];
            const d_addr: []u8 = (m_phy_fb + ((y * _width + _left) * color_bytes))[0..count];
            // memcpy(d_addr, s_addr, (right - left) * m_color_bytes);
            // @memcpy(d_addr, s_addr);
            std.mem.copyForwards(u8, d_addr, s_addr);
        }
        return 0;
    }

    // vtable
    draw_pixel: *const fn (
        *Display, //
        int,
        int,
        uint,
    ) void = draw_pixel_impl,
    fill_rect: *const fn (
        *Display, //
        int,
        int,
        int,
        int,
        uint,
    ) void = fill_rect_impl,
    flush_screen: *const fn (
        this: *Display, //
        left: int,
        top: int,
        right: int,
        bottom: int,
        fb: *anyopaque,
        fb_width: int,
    ) int = flush_screen_impl,

    m_width: int = 0, //in pixels
    m_height: int = 0, //in pixels
    m_color_bytes: uint = 0, //16/32 bits for default
    m_phy_fb: ?[*]u8 = null, //physical framebuffer for default
    m_driver: ?*const DISPLAY_DRIVER = null, //Rendering by external method without default physical framebuffer

    m_phy_read_index: int = 0,
    m_phy_write_index: int = 0,
    m_surface_group: [SURFACE_CNT_MAX]?*Surface = undefined,
    m_surface_cnt: int = 0, //surface count
    m_surface_index: int = 0,
};

pub const Layer = struct {
    // public:
    // 	Layer() { fb = 0; }
    fb: ?*anyopaque = null, //framebuffer
    rect: Rect = .{}, //framebuffer area
    active_rect: Rect = Rect.init(),
};

pub const Surface = struct {
    // 	friend class Display; friend class BitmapOperator;
    // public:
    // 	Z_ORDER_LEVEL get_max_z_order() { return m_max_zorder; }

    inline fn init(allocator: std.mem.Allocator, width: uint, height: uint, color_bytes: uint, max_zorder: Z_ORDER_LEVEL, overlpa_rect: Rect) !*Surface
    // : m_width(width), m_height(height), m_color_bytes(color_bytes), m_fb(0), m_is_active(false),
    // m_top_zorder(Z_ORDER_LEVEL_0), m_phy_write_index(0), m_display(0)
    {
        var this = try allocator.create(Surface);
        errdefer allocator.destroy(this);
        this.* = .{
            .m_width = width,
            .m_height = height,
            .m_color_bytes = color_bytes,
            .m_is_active = false,
            .m_top_zorder = .Z_ORDER_LEVEL_0,
            .m_phy_write_index = null,
        };

        // if(overlpa_rect.eql(.{})  set_surface(max_zorder, Rect(0, 0, width, height)) : set_surface(max_zorder, overlpa_rect);
        if (overlpa_rect.eql(.{})) {
            _ = try this.set_surface(max_zorder, Rect.init2(0, 0, width, height));
        } else {
            _ = try this.set_surface(max_zorder, overlpa_rect);
        }
        return this;
    }

    pub fn get_pixel(this: @This(), x: int, y: int, _z_order: int) !uint {
        if (x >= this.m_width or y >= this.m_height or x < 0 or y < 0 or _z_order >= @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX)) {
            return error.get_pixel_error;
        }
        if (this.m_display == null) {
            return error.m_display_null;
        }
        const z_order = @as(usize, @intCast(_z_order));
        const idx: usize = @intCast(y * @as(int, @intCast(this.m_width)) + x);
        if (this.m_layers[z_order].fb) |fb| {
            const fb_u16: [*]align(1) u16 = @ptrCast(fb);
            const fb_uint: [*]align(1) uint = @ptrCast(fb);
            return if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[idx]) else fb_uint[idx];
        } else if (this.m_fb) |fb| {
            const fb_u16: [*]align(1) u16 = @ptrCast(fb);
            const fb_uint: [*]align(1) uint = @ptrCast(fb);
            return if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[idx]) else fb_uint[idx];
        } else if (this.m_display.?.m_phy_fb) |fb| {
            const fb_u16: [*]align(1) u16 = @ptrCast(fb);
            const fb_uint: [*]align(1) uint = @ptrCast(fb);
            return if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[idx]) else fb_uint[idx];
        }
        return 0;
    }

    fn draw_pixel_impl(this: *Surface, x: int, y: int, rgb: uint, z_order: Z_ORDER_LEVEL) void {
        // std.log.debug("surface draw_pixel_impl(this:{*},x:{},y:{},rgb:{},z_order:{})", .{ this, x, y, rgb, z_order });

        if (x >= this.m_width or y >= this.m_height or x < 0 or y < 0) {
            return;
        }
        const uz_order: usize = @intFromEnum(z_order);
        if (uz_order > @intFromEnum(this.m_max_zorder)) {
            api.ASSERT(false);
            return;
        }

        if (uz_order > @intFromEnum(this.m_top_zorder)) {
            this.m_top_zorder = z_order;
        }

        if (uz_order == @intFromEnum(this.m_max_zorder)) {
            return this.draw_pixel_low_level(x, y, rgb);
        }

        if (this.m_layers[uz_order].rect.pt_in_rect(x, y)) {
            const layer_rect = this.m_layers[uz_order].rect;
            const idx: usize = @intCast(@as(u32, @bitCast((x - layer_rect.m_left) + (y - layer_rect.m_top) * @as(i32, @bitCast(layer_rect.width())))));
            const fb = this.m_layers[uz_order].fb.?;
            if (this.m_color_bytes == 2) {
                const fb_u16: [*]u16 = @ptrCast(@alignCast(fb));
                fb_u16[idx] = api.GL_RGB_32_to_16(rgb);
            } else {
                const fb_uint: [*]u32 = @ptrCast(@alignCast(fb));
                fb_uint[idx] = @bitCast(rgb);
            }
        }

        if (z_order == this.m_top_zorder) {
            return this.draw_pixel_low_level(x, y, rgb);
        }

        var be_overlapped = false;
        var tmp_z_order: usize = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX) - 1;
        // for (unsigned int tmp_z_order = Z_ORDER_LEVEL_MAX - 1; tmp_z_order > z_order; tmp_z_order--)
        while (tmp_z_order > uz_order) : (tmp_z_order -= 1) {
            if (this.m_layers[tmp_z_order].active_rect.pt_in_rect(x, y)) {
                be_overlapped = true;
                break;
            }
        }

        if (!be_overlapped) {
            this.draw_pixel_low_level(x, y, rgb);
        }
    }

    fn fill_rect_impl(this: *Surface, _x0: int, _y0: int, _x1: int, _y1: int, rgb: uint, z_order: int) void {
        const x0 = if (_x0 < 0) 0 else _x0;
        var y0 = if (_y0 < 0) 0 else _y0;
        const iw = @as(i32, @bitCast(this.m_width));
        const ih = @as(i32, @bitCast(this.m_height));
        const x1 = if (_x1 > (iw - 1)) (iw - 1) else _x1;
        const y1 = if (_y1 > (ih - 1)) (ih - 1) else _y1;

        const ez_order: Z_ORDER_LEVEL = @enumFromInt(z_order);
        const uz_order: usize = @intCast(z_order);

        std.log.debug("fill_rect_impl z_order:{d}", .{z_order});
        if (ez_order == this.m_max_zorder) {
            return this.fill_rect_low_level(x0, y0, x1, y1, rgb);
        }
        if (ez_order == this.m_top_zorder) {
            const width = this.m_layers[uz_order].rect.width();
            const layer_rect = this.m_layers[uz_order].rect;
            const rgb_16 = api.GL_RGB_32_to_16(rgb);
            // 			for (int y = y0; y <= y1; y++)
            // for (@intCast(@as(u32, @bitCast(y0)))..@intCast(@as(u32, @bitCast((y1 + 1))))) |y| {
            var y:usize = @intCast(y0);
            while(y < (y1 + 1)):(y += 1){
                // 				for (int x = x0; x <= x1; x++)
                var x:usize = @intCast(x0);
                // for (@intCast(@as(u32, @bitCast(x0)))..@intCast(@as(u32, @bitCast(x1 + 1)))) |x| {
                while(x < (x1 + 1)):(x += 1){
                    if (layer_rect.pt_in_rect(@intCast(x), @intCast(y))) {
                        if (this.m_color_bytes == 2) {
                            const fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_layers[uz_order].fb));
                            fb_u16[(y - @as(usize, @intCast(layer_rect.m_top))) * @as(usize, @as(u32, @bitCast(width))) + (x - @as(usize, @as(u32, @bitCast(layer_rect.m_left))))] = rgb_16;
                        } else {
                            const fb_uint: [*]uint = @ptrCast(@alignCast(this.m_layers[uz_order].fb));
                            const rgbPtr = &fb_uint[(y - @as(usize, @as(u32, @bitCast(layer_rect.m_top)))) * @as(usize, @as(u32, @bitCast(width))) + (x - @as(usize, @as(u32, @bitCast(layer_rect.m_left))))];
                            rgbPtr.* = rgb;
                        }
                    }
                }
            }
            return this.fill_rect_low_level(x0, y0, x1, y1, rgb);
        }

        // for (; y0 <= y1; y0++)
        while (y0 <= y1) : (y0 += 1) {
            this.draw_hline(x0, x1, y0, rgb, z_order);
        }
    }

    pub fn draw_hline(this: *Surface, _x0: int, _x1: int, y: int, rgb: uint, z_order: int) void {
        const x0: usize = @as(u32, @bitCast(_x0));
        const x1: usize = @as(u32, @bitCast(_x1));
        // 		for (; x0 <= x1; x0++)
        for (x0..(x1 + 1)) |x| {
            const ix: i32 = @intCast(x);
            this.draw_pixel(ix, y, rgb, @enumFromInt(z_order));
        }
    }

    pub fn draw_vline(this: *Surface, x: int, y0: int, y1: int, rgb: uint, z_order: int) void {
        // for (; y0 <= y1; y0++)
        const _y0: usize = @as(usize, @as(u32, @bitCast(y0)));
        const _y1: usize = @as(usize, @as(u32, @bitCast(y1)));
        for (_y0..(_y1 + 1)) |y| {
            const iy: int = @truncate(@as(i64, @bitCast(y)));
            this.draw_pixel(x, iy, rgb, @enumFromInt(z_order));
        }
    }

    pub fn draw_line(this: *Surface, _x1: i32, _y1: i32, x2: i32, y2: i32, rgb: u32, _z_order: u32) void {
        var dx: i32 = x2 -% _x1;
        var dy: i32 = y2 -% _y1;
        var x1 = _x1;
        var y1 = _y1;
        var e: i32 = undefined;
        const z_order: Z_ORDER_LEVEL = @enumFromInt(_z_order);
        if ((dx >= 0) and (dy >= 0)) {
            if (dx >= dy) {
                e = dy - @divTrunc(dx, @as(i32, 2));
                var i: i32 = x1;
                while (i <= x2) : (i += 1) {
                    this.draw_pixel(i, y1, rgb, z_order);
                    if (e > 0) {
                        y1 += 1;
                        e -= dx;
                    }
                    e += dy;
                }
            } else {
                e = dx - @divTrunc(dx, @as(i32, 2));
                var i: i32 = y1;
                while (i <= y2) : (i += 1) {
                    this.draw_pixel(x1, i, rgb, z_order);
                    if (e > 0) {
                        x1 += 1;
                        e -= dy;
                    }
                    e += dx;
                }
            }
        } else if ((dx >= 0) and (dy < 0)) {
            dy = -dy;
            if (dx >= dy) {
                e = dy - @divTrunc(dx, @as(i32, 2));
                var i: i32 = x1;
                while (i <= x2) : (i += 1) {
                    this.draw_pixel(i, y1, rgb, z_order);
                    if (e > 0) {
                        y1 -= 1;
                        e -= dx;
                    }
                    e += dy;
                }
            } else {
                e = dx - @divTrunc(dx, @as(i32, 2));
                var i: i32 = y1;
                while (i >= y2) : (i -= 1) {
                    this.draw_pixel(x1, i, rgb, z_order);
                    if (e > 0) {
                        x1 += 1;
                        e -= dy;
                    }
                    e += dx;
                }
            }
        } else if ((dx < 0) and (dy >= 0)) {
            dx = -dx;
            if (dx >= dy) {
                e = dy - @divTrunc(dx, @as(i32, 2));
                var i: i32 = x1;
                while (i >= x2) : (i -= 1) {
                    this.draw_pixel(i, y1, rgb, z_order);
                    if (e > 0) {
                        y1 += 1;
                        e -= dx;
                    }
                    e += dy;
                }
            } else {
                e = dx - @divTrunc(dx, @as(i32, 2));
                var i: i32 = y1;
                while (i <= y2) : (i += 1) {
                    this.draw_pixel(x1, i, rgb, z_order);
                    if (e > 0) {
                        x1 -= 1;
                        e -= dy;
                    }
                    e += dx;
                }
            }
        } else if ((dx < 0) and (dy < 0)) {
            dx = -dx;
            dy = -dy;
            if (dx >= dy) {
                e = dy - @divTrunc(dx, @as(i32, 2));
                var i: i32 = x1;
                while (i >= x2) : (i -= 1) {
                    this.draw_pixel(i, y1, rgb, z_order);
                    if (e > 0) {
                        y1 -= 1;
                        e -= dx;
                    }
                    e += dy;
                }
            } else {
                e = dx - @divTrunc(dx, @as(i32, 2));
                var i: i32 = y1;
                while (i >= y2) : (i -= 1) {
                    this.draw_pixel(x1, i, rgb, z_order);
                    if (e > 0) {
                        x1 -= 1;
                        e -= dy;
                    }
                    e += dx;
                }
            }
        }
    }

    pub fn draw_rect_pos(this: *Surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: int, size: uint) void {
        // for (unsigned int offset = 0; offset < size; offset++)

        std.log.debug("draw_rect_pos({d},{d},{d},{d},{d})", .{ x0, y0, x1, y1, rgb });
        const _usize: usize = @as(usize, @as(u32, @bitCast(size)));
        for (0.._usize) |_offset| {
            const offset: int = @bitCast(@as(u32, @truncate(_offset)));
            this.draw_hline(x0 + offset, x1 - offset, y0 + offset, rgb, z_order);
            this.draw_hline(x0 + offset, x1 - offset, y1 - offset, rgb, z_order);
            this.draw_vline(x0 + offset, y0 + offset, y1 - offset, rgb, z_order);
            this.draw_vline(x1 - offset, y0 + offset, y1 - offset, rgb, z_order);
        }
    }

    pub fn draw_rect(this: *Surface, rect: Rect, rgb: uint, z_order: int, size: uint) void {
        this.draw_rect_pos(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, rgb, z_order, size);
    }
    pub fn flush_screen_all(this: *Surface) !void{
        if(this.flush_screen(0,0,this.m_width - 1,this.m_height - 1) != 0){
            return error.flush_screen;
        }
    }
    pub fn flush_screen(this: *Surface, left: int, top: int, right: int, bottom: int) int {
        if (!this.m_is_active) {
            return -1;
        }

        if (left < 0 or left >= this.m_width or right < 0 or right >= this.m_width or
            top < 0 or top >= this.m_height or bottom < 0 or bottom >= this.m_height)
        {
            api.ASSERT(false);
        }
        if (this.m_display) |display| {
            return display.flush_screen(display, left, top, right, bottom, this.m_fb.?, @intCast(this.m_width));
        }
        if (this.m_phy_write_index) |m_phy_write_index| {
            m_phy_write_index.* = m_phy_write_index.* + 1;
        }
        return 0;
    }

    pub fn is_active(this: Surface) bool {
        return this.m_is_active;
    }
    pub fn get_display(this: Surface) ?*Display {
        return this.m_display;
    }

    // 激活图层
    pub fn activate_layer(self: *Surface, active_rect: Rect, active_z_order: i32) void {
        std.debug.assert(active_z_order > @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_0) and active_z_order <= Z_ORDER_LEVEL_MAX);
        // Show the layers below the current active rect.
        const uactive_z_order: u32 = @intCast(active_z_order);
        const current_active_rect = self.m_layers[uactive_z_order].active_rect;
        var low_z_order: u32 = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_0);
        while (low_z_order < active_z_order) : (low_z_order += 1) {
            const low_layer_rect = self.m_layers[low_z_order].rect;
            const low_active_rect = self.m_layers[low_z_order].active_rect;
            const fb = self.m_layers[low_z_order].fb;
            const width = low_layer_rect.width();
            var y: i32 = current_active_rect.m_top;
            while (y <= current_active_rect.m_bottom) : (y += 1) {
                var x: i32 = current_active_rect.m_left;
                while (x <= current_active_rect.m_right) : (x += 1) {
                    if (low_active_rect.pt_in_rect(x, y) and low_layer_rect.pt_in_rect(x, y)) {
                        const rgb = if (self.m_color_bytes == 2) api.GL_RGB_16_to_32(@as([*]u16, @alignCast(@ptrCast(fb)))[@as(usize, @intCast((x - low_layer_rect.m_left) + (y - low_layer_rect.m_top) * @as(i32, @intCast(width))))]) else @as([*]u32, @alignCast(@ptrCast(fb)))[@as(usize, @intCast((x - low_layer_rect.m_left) + (y - low_layer_rect.m_top) * @as(i32, @intCast(width))))];
                        self.draw_pixel_low_level(x, y, rgb);
                    }
                }
            }
        }
        self.m_layers[uactive_z_order].active_rect = active_rect;
    }

    pub fn set_active(this: *Surface, flag: bool) void {
        this.m_is_active = flag;
    }
    // protected:
    fn fill_rect_low_level_impl(this: *Surface, _x0: int, _y0: int, _x1: int, _y1: int, rgb: uint) void { //fill rect on framebuffer of surface
        const x0: usize = if(_x0 > 0) @as(u32, @bitCast(_x0)) else 0;
        const y0: usize = if(_y0 > 0) @as(u32, @bitCast(_y0)) else 0;
        const x1: usize = if(_x1 > 0) @as(u32, @bitCast(_x1)) else 0;
        const y1: usize = if(_y1 > 0) @as(u32, @bitCast(_y1)) else 0;
        const m_width: usize = @as(u32, @bitCast(this.m_width));
        std.log.debug("fill_rect_low_level_impl x0:{d} y0:{d} x1:{d} y1:{d} rgb:{d} m_color_bytes:{} m_fb:{*}", .{ x0, y0, x1, y1, rgb, this.m_color_bytes, this.m_fb });
        // int x, y;
        if (this.m_fb) |_fb| {
            if (this.m_color_bytes == 2) {
                const fb: [*]u16 = @ptrCast(@alignCast(_fb));
                const rgb_16 = api.GL_RGB_32_to_16(rgb);
                var y = y1;
                while(y <= y1):(y += 1){
                    const _xfb = fb + y * m_width + x0;
                    var x = x1;
                    while(x <= x1):(x += 1){
                        _xfb[x] = rgb_16;
                        std.log.debug("({},{}) = {}", .{ x, y, rgb_16 });
                    }
                }
            } else {
                const fb: [*]uint = @ptrCast(@alignCast(_fb));
                std.log.debug("x1:{d} y1:{d}", .{ x1, y1 });
                var y = y0;
                while(y <= y1):(y += 1){
                    var ix = x0;
                    while(ix <= x1):(ix += 1){
                        fb[y * m_width + ix] = rgb;
                        // std.log.debug("({},{}) = {}", .{ ix, y, rgb });
                    }
                }
            }
        }

        if (this.m_is_active == false) {
            return;
        }
        if (this.m_display) |display| {
            display.fill_rect(display, _x0, _y0, _x1, _y1, rgb);
        }
        if (this.m_phy_write_index) |m_phy_write_index| {
            m_phy_write_index.* = m_phy_write_index.* + 1;
        }
    }

    fn draw_pixel_low_level_impl(this: *Surface, x: int, y: int, rgb: uint) void {
        // std.log.debug("draw_pixel_low_level_impl x:{d} y:{d} rgb:{d}", .{ x, y, rgb });
        if (this.m_fb != null) { //draw pixel on framebuffer of surface
            const fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_fb));
            const fb_uint: [*]uint = @ptrCast(@alignCast(this.m_fb));
            const fb_idx: usize = @as(usize, @as(u32, @bitCast(y * @as(int, @bitCast(this.m_width)) + x)));
            if (this.m_color_bytes == 2) fb_u16[fb_idx] = api.GL_RGB_32_to_16(rgb) else fb_uint[fb_idx] = rgb;
        }
        if (this.m_is_active == false) {
            return;
        }
        if (this.m_display) |display| {
            display.draw_pixel(display, x, y, rgb);
        }
        if (this.m_phy_write_index) |phy_write_index| {
            phy_write_index.* = phy_write_index.* + 1;
        }
    }

    fn attach_display(this: *Surface, display: *Display) void {
        this.m_display = display;
        this.m_phy_write_index = &display.m_phy_write_index;
    }

    fn set_surface(this: *Surface, max_z_order: Z_ORDER_LEVEL, layer_rect: Rect) !void {
        this.m_max_zorder = max_z_order;
        // std.log.debug("surface.set_surface m_display:{*}", .{this.m_display});
        // std.debug.dumpCurrentStackTrace(null);
        if (this.m_display) |display| {
            std.log.debug("display.m_surface_cnt:{d}", .{display.m_surface_cnt});
            //why display.m_surface_cnt > 1 in guilite code
            if (display.m_surface_cnt > 0) {
                // m_fb = calloc(m_width * m_height, m_color_bytes);
                this.m_fb = @ptrCast(try core.allocator.alloc(u8, @intCast(this.m_width * this.m_height * this.m_color_bytes)));
            }
        }
        var i: usize = 0;
        errdefer {
            core.allocator.free(this.m_fb);
        }

        const fb_size: usize = @intCast(layer_rect.width() * layer_rect.height() * this.m_color_bytes);
        errdefer {
            while (i >= 0) {
                const layer = this.m_layers[i];
                const fb_u8: [*]u8 = @ptrCast(@alignCast(layer.fb.?));
                core.allocator.free(fb_u8[0..fb_size]);
            }
        }
        for (@intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_0)..@intFromEnum(this.m_max_zorder)) |j| {
            i = j; //Top layber fb always be 0
            std.log.debug("set_surface alloc layers[{d}] fb m_max_zorder:{} layer_rect:{}", .{ i, this.m_max_zorder, layer_rect });
            this.m_layers[i].fb = @ptrCast(try core.allocator.alloc(u8, fb_size));
            this.m_layers[i].rect = layer_rect;
            this.m_layers[i].active_rect = layer_rect;
        }
    }

    pub fn draw_pixel(this: *Surface, x: int, y: int, rgb: uint, z_order: Z_ORDER_LEVEL) void {
        this.m_vtable.draw_pixel(this, x, y, rgb, z_order);
    }
    // pub fn fill_rect(this: *Surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint) void {
    //     this.m_vtable.fill_rect(this, x0, y0, x1, y1, rgb, z_order);
    // }
    pub fn fill_rect(this: *Surface, rect: Rect, rgb: uint, z_order: int) void {
        this.m_vtable.fill_rect(this, rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, rgb, z_order);
    }
    pub fn fill_rect_low_level(this: *Surface, x0: int, y0: int, x1: int, y1: int, rgb: uint) void {
        this.m_vtable.fill_rect_low_level(this, x0, y0, x1, y1, rgb);
    }
    pub fn draw_pixel_low_level(this: *Surface, x: int, y: int, rgb: uint) void {
        this.m_vtable.draw_pixel_low_level(this, x, y, rgb);
    }
    const VTable = struct {
        draw_pixel: *const fn (this: *Surface, x: int, y: int, rgb: uint, z_order: Z_ORDER_LEVEL) void = draw_pixel_impl,
        fill_rect: *const fn (this: *Surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: int) void = fill_rect_impl,
        fill_rect_low_level: *const fn (this: *Surface, x0: int, y0: int, x1: int, y1: int, rgb: uint) void = fill_rect_low_level_impl,
        draw_pixel_low_level: *const fn (this: *Surface, x: int, y: int, rgb: uint) void = draw_pixel_low_level_impl,
    };

    m_vtable: VTable = .{},
    m_width: uint = 0, //in pixels
    m_height: uint = 0, //in pixels
    m_color_bytes: uint = 0, //16 bits, 32 bits for default
    m_fb: ?[*]u8 = null, //frame buffer you could see
    m_layers: [@intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX)]Layer = undefined, //all graphic layers
    m_is_active: bool, //active flag
    m_max_zorder: Z_ORDER_LEVEL = .Z_ORDER_LEVEL_0, //the highest graphic layer the surface will have
    m_top_zorder: Z_ORDER_LEVEL = .Z_ORDER_LEVEL_0, //the current highest graphic layer the surface have
    m_phy_write_index: ?*int = null,
    m_display: ?*Display = null,
};