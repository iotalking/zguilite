const std = @import("std");
const types = @import("./types.zig");
const api = @import("./api.zig");
const core = @import("./core.zig");
const int = types.int;
const uint = types.uint;
const c_rect = api.c_rect;
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
    draw_pixel: ?*const fn (x: int, y: int, rgb: int) void,
    // void(*fill_rect)(int x0, int y0, int x1, int y1, unsigned int rgb);
    fill_rect: ?*const fn (x0: int, y0: int, x1: int, y1: int, rgb: int) void,
};

// class c_surface;
pub const c_display = struct {
    // 	friend class c_surface;
    // public:
    pub inline fn init(phy_fb: *anyopaque, display_width: int, display_height: int, surface: *c_surface, driver: *DISPLAY_DRIVER) c_display {
        const this = c_display{};
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
    pub inline fn init2(this: *c_display, phy_fb: [*]u8, display_width: int, display_height: int, surface_width: int, surface_height: int, color_bytes: uint, surface_cnt: int, driver: ?*DISPLAY_DRIVER) !void {
        this.* = c_display{
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
            // const tmp_surface = try core.allocator.create(c_surface);
            // tmp_surface = c_surface.init(width: uint, height: uint, color_bytes: uint, max_zorder: Z_ORDER_LEVEL, overlpa_rect: c_rect)
            const tmp_surface = try c_surface.init(core.allocator, surface_width, surface_height, color_bytes, .Z_ORDER_LEVEL_0, c_rect.init());
            this.m_surface_group[i] = tmp_surface;
            // 		m_surface_group[i]->attach_display(this);
            tmp_surface.attach_display(this);
        }
        return;
    }
    pub inline fn alloc_surface(this: *c_display, max_zorder: Z_ORDER_LEVEL, layer_rect: c_rect) !*c_surface {
        std.log.debug("display alloc_surface max_zorder:{}", .{max_zorder});
        api.ASSERT(@intFromEnum(max_zorder) < @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX) and this.m_surface_index < this.m_surface_cnt);
        std.log.debug("alloc_surface m_surface_index:{}", .{this.m_surface_index});
        const m_surface_index: usize = @intCast(this.m_surface_index);
        if (layer_rect.eql(c_rect.init())) {
            if (this.m_surface_group[m_surface_index]) |surface| {
                try surface.set_surface(max_zorder, c_rect.init2(0, 0, this.m_width, this.m_height));
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
    inline fn swipe_surface(this: *c_display, s0: *c_surface, s1: *c_surface, x0: int, x1: int, y0: int, y1: int, offset: int) int {
        const surface_width = s0.m_width;
        const surface_height = s0.m_height;
        if (offset < 0 and offset > surface_width and y0 < 0 and y0 >= surface_height or
            y1 < 0 or y1 >= surface_height or x0 < 0 or x0 >= surface_width or x1 < 0 or x1 >= surface_width)
        {
            api.ASSERT(false);
            return -1;
        }
        const width = (x1 - x0 + 1);
        if (width < 0 or width > surface_width or width < offset) {
            api.ASSERT(false);
            return -1;
        }
        x0 = if (x0 >= this.m_width) (this.m_width - 1) else x0;
        x1 = if (x1 >= this.m_width) (this.m_width - 1) else x1;
        y0 = if (y0 >= this.m_height) (this.m_height - 1) else y0;
        y1 = if (y1 >= this.m_height) (this.m_height - 1) else y1;
        if (this.m_phy_fb != null) {
            // 		for (int y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                //Left surface
                const size = offset * this.m_color_bytes;
                var s_offset = (y * surface_width + x0 + offset) * this.m_color_bytes;
                var addr_s = s0.m_fb[s_offset..(s_offset + size)];
                var d_offset = (y * this.m_width + x0) * this.m_color_bytes;
                var addr_d = this.m_phy_fb[d_offset..(d_offset + size)];
                // 			memcpy(addr_d, addr_s, (width - offset) * m_color_bytes);
                @memcpy(addr_d, addr_s);
                //Right surface
                // 			addr_s = ((char*)(s1->m_fb) + (y * surface_width + x0) * m_color_bytes);
                s_offset = (y * surface_width + x0) * this.m_color_bytes;
                addr_s = s1.m_fb[s_offset..(s_offset + size)];

                d_offset = (y * this.m_width + x0 + (width - offset)) * this.m_color_bytes;
                // 			addr_d = ((char*)(m_phy_fb)+(y * m_width + x0 + (width - offset)) * m_color_bytes);
                addr_d = this.m_phy_fb[d_offset..(d_offset + size)];
                // 			memcpy(addr_d, addr_s, offset * m_color_bytes);
                @memcpy(addr_d, addr_s);
            }
        } else if (this.m_color_bytes == 2) {
            // 		void(*draw_pixel)(int x, int y, unsigned int rgb) = m_driver->draw_pixel;
            const draw_pixel = this.m_driver.draw_pixel;
            // 		for (int y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                //Left surface
                // 			for (int x = x0; x <= (x1 - offset); x++)
                for (x0..(x1 - offset)) |x| {
                    const fb_u16: [*]u16 = @ptrCast(s0.m_fb);
                    draw_pixel(x, y, api.GL_RGB_16_to_32(fb_u16[y * this.m_width + x + offset]));
                }
                //Right surface
                // 			for (int x = x1 - offset; x <= x1; x++)
                for ((x1 - offset)..(x1 + 1)) |x| {
                    const fb_u16: [*]u16 = @ptrCast(s1.m_fb);
                    draw_pixel(x, y, api.GL_RGB_16_to_32(fb_u16[y * this.m_width + x + offset - x1 + x0]));
                }
            }
        } else //m_color_bytes == 3/4...
        {
            // 		void(*draw_pixel)(int x, int y, unsigned int rgb) = m_driver->draw_pixel;
            const draw_pixel = this.m_driver.draw_pixel;
            // 		for (int y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                //Left surface
                // 			for (int x = x0; x <= (x1 - offset); x++)
                for (x0..(x1 - offset)) |x| {
                    const fb_u16: [*]u16 = @ptrCast(s0.m_fb);
                    draw_pixel(x, y, fb_u16[y * this.m_width + x + offset]);
                }
                //Right surface
                // 			for (int x = x1 - offset; x <= x1; x++)
                for ((1 - offset)..(x1 + 1)) |x| {
                    const fb_u16: [*]u16 = @ptrCast(s1.m_fb);

                    draw_pixel(x, y, fb_u16[y * this.m_width + x + offset - x1 + x0]);
                }
            }
        }

        this.m_phy_write_index += 1;
        return 0;
    }

    // 	inline c_display(void* phy_fb, int display_width, int display_height, int surface_width, int surface_height, unsigned int color_bytes, int surface_cnt, DISPLAY_DRIVER* driver = 0);//multiple surface
    // 	inline c_surface* alloc_surface(Z_ORDER_LEVEL max_zorder, c_rect layer_rect = c_rect());//for slide group
    // 	inline int swipe_surface(c_surface* s0, c_surface* s1, int x0, int x1, int y0, int y1, int offset);
    fn get_width(this: c_display) int {
        return this.m_width;
    }
    fn get_height(this: c_display) int {
        return this.m_height;
    }
    fn get_phy_fb(this: c_display) [*]u8 {
        return this.m_phy_fb;
    }

    fn get_updated_fb(this: *c_display, width: *int, height: *int, force_update: bool) ?*anyopaque {
        // if (width and height)
        // 		{
        width.* = this.m_width;
        height.* = this.m_height;
        // 		}
        if (force_update) {
            return this.m_phy_fb;
        }
        if (this.m_phy_read_index == this.m_phy_write_index) { //No update
            return null;
        }
        this.m_phy_read_index = this.m_phy_write_index;
        return this.m_phy_fb;
    }

    fn snap_shot(this: *c_display, file_name: [*]const u8) !int {
        if (this.m_phy_fb or (this.m_color_bytes != 2 and this.m_color_bytes != 4)) {
            return -1;
        }

        //16 bits framebuffer
        if (this.m_color_bytes == 2) {
            return api.build_bmp(file_name, this.m_width, this.m_height, this.m_phy_fb);
        }

        //32 bits framebuffer
        // unsigned short* p_bmp565_data = new unsigned short[m_width * m_height];
        const p_bmp565_data = try core.allocator.alloc(@sizeOf(*u16) * this.m_width * this.m_height);
        defer core.allocator.free(p_bmp565_data);
        // 		unsigned int* p_raw_data = (unsigned int*)m_phy_fb;
        const p_raw_data: *uint = @ptrCast(p_bmp565_data);
        // 		for (int i = 0; i < m_width * m_height; i++)
        for (0..(this.m_width * this.m_height)) |i| {
            // 			unsigned int rgb = *p_raw_data++;
            const rgb = p_raw_data[0];
            p_raw_data += 1;
            p_bmp565_data[i] = api.GL_RGB_32_to_16(rgb);
        }

        const ret = api.build_bmp(file_name, this.m_width, this.m_height, p_bmp565_data);
        // 		delete[]p_bmp565_data;
        return ret;
    }

    // protected:
    fn draw_pixel_impl(this: *c_display, x: int, y: int, rgb: uint) void {
        std.log.debug("display draw_pixel_impl({},{},{})", .{ x, y, rgb });
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

    fn fill_rect_impl(this: *c_display, x0: int, y0: int, x1: int, y1: int, rgb: uint) void {
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
                for (uy0..(uy1 + 1)) |y| {
                    // for (int x = x0; x <= x1; x++)
                    for (ux0..(ux1 + 1)) |x| {
                        draw_pixel(@intCast(x), @intCast(y), rgb);
                    }
                }
            }
            return;
        }

        const _width: usize = @intCast(@as(u32, @bitCast(this.m_width)));
        const _height = this.m_height;
        // 		int x, y;
        if (this.m_color_bytes == 2) {
            // 			unsigned short* phy_fb;
            // 			for (y = y0; y <= y1; y++)
            const rgb_16 = api.GL_RGB_32_to_16(rgb);
            var fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_phy_fb.?));
            for (uy0..(uy1 + 1)) |y| {
                // 				for (x = x0; x <= x1; x++)
                for (ux0..(ux1 + 1)) |x| {
                    if ((x < _width) and (y < _height)) {
                        fb_u16[y * _width + x] = rgb_16;
                    }
                }
            }
        } else {
            // 			unsigned int* phy_fb;
            // 			for (y = y0; y <= y1; y++)
            const rgb_32: u32 = @bitCast(rgb);
            // std.log.debug("this.m_phy_fb:{*}", .{this.m_phy_fb});
            const phy_fb: [*]u32 = @alignCast(@ptrCast(this.m_phy_fb.?));
            for (@intCast(y0)..@intCast(y1 + 1)) |y| {
                // 				for (x = x0; x <= x1; x++)
                for (ux0..(ux1 + 1)) |x| {
                    if ((x < _width) and (y < _height)) {
                        // std.log.debug("phy_fb:{*},_width:{} ({},{})={}", .{ phy_fb, _width, x, y, rgb_32 });
                        phy_fb[y * _width + x] = rgb_32;
                    }
                }
            }
        }
    }

    fn flush_screen_impl(this: *c_display, left: int, top: int, right: int, bottom: int, fb: *anyopaque, fb_width: int) int {
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
        *c_display, //
        int,
        int,
        uint,
    ) void = draw_pixel_impl,
    fill_rect: *const fn (
        *c_display, //
        int,
        int,
        int,
        int,
        uint,
    ) void = fill_rect_impl,
    flush_screen: *const fn (
        this: *c_display, //
        left: int,
        top: int,
        right: int,
        bottom: int,
        fb: *anyopaque,
        fb_width: int,
    ) int = flush_screen_impl,

    m_width: int = 0, //in pixels
    m_height: int = 0, //in pixels
    m_color_bytes: int = 0, //16/32 bits for default
    m_phy_fb: ?[*]u8 = null, //physical framebuffer for default
    m_driver: ?*DISPLAY_DRIVER = null, //Rendering by external method without default physical framebuffer

    m_phy_read_index: int = 0,
    m_phy_write_index: int = 0,
    m_surface_group: [SURFACE_CNT_MAX]?*c_surface = undefined,
    m_surface_cnt: int = 0, //surface count
    m_surface_index: int = 0,
};

pub const c_layer = struct {
    // public:
    // 	c_layer() { fb = 0; }
    fb: ?*anyopaque = null, //framebuffer
    rect: c_rect = .{}, //framebuffer area
    active_rect: c_rect = .{},
};

pub const c_surface = struct {
    // 	friend class c_display; friend class c_bitmap_operator;
    // public:
    // 	Z_ORDER_LEVEL get_max_z_order() { return m_max_zorder; }

    inline fn init(allocator: std.mem.Allocator, width: uint, height: uint, color_bytes: uint, max_zorder: Z_ORDER_LEVEL, overlpa_rect: c_rect) !*c_surface
    // : m_width(width), m_height(height), m_color_bytes(color_bytes), m_fb(0), m_is_active(false),
    // m_top_zorder(Z_ORDER_LEVEL_0), m_phy_write_index(0), m_display(0)
    {
        var this = try allocator.create(c_surface);
        errdefer allocator.destroy(this);
        this.* = .{
            .m_width = width,
            .m_height = height,
            .m_color_bytes = color_bytes,
            .m_is_active = false,
            .m_top_zorder = .Z_ORDER_LEVEL_0,
            .m_phy_write_index = null,
        };

        // if(overlpa_rect.eql(.{})  set_surface(max_zorder, c_rect(0, 0, width, height)) : set_surface(max_zorder, overlpa_rect);
        if (overlpa_rect.eql(.{})) {
            _ = try this.set_surface(max_zorder, c_rect.init2(0, 0, width, height));
        } else {
            _ = try this.set_surface(max_zorder, overlpa_rect);
        }
        return this;
    }

    pub fn get_pixel(this: @This(), x: int, y: int, z_order: uint) !uint {
        if (x >= this.m_width or y >= this.m_height or x < 0 or y < 0 or z_order >= .Z_ORDER_LEVEL_MAX) {
            api.ASSERT(false);
            return 0;
        }
        if (this.m_layers[z_order].fb) {
            const fb_u16: [*]u16 = @ptrCast(this.m_layers[z_order].fb);
            const fb_uint: [*]uint = @ptrCast(this.m_layers[z_order].fb);
            return if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[y * this.m_width + x]) else fb_uint[y * this.m_width + x];
        } else if (this.m_fb != null) {
            const fb_u16: [*]u16 = @ptrCast(this.m_fb[z_order].fb);
            const fb_uint: [*]uint = @ptrCast(this.m_fb[z_order].fb);
            return if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[y * this.m_width + x]) else fb_uint[y * this.m_width + x];
        } else if (this.m_display.m_phy_fb != null) {
            const fb_u16: [*]u16 = @ptrCast(this.m_display.m_phy_fb[z_order].fb);
            const fb_uint: [*]uint = @ptrCast(this.m_display.m_phy_fb[z_order].fb);
            return if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[y * this.m_width + x]) else fb_uint[y * this.m_width + x];
        }
        return 0;
    }

    fn draw_pixel_impl(this: *c_surface, x: int, y: int, rgb: uint, z_order: Z_ORDER_LEVEL) void {
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
            const idx: usize = @intCast(@as(u32, @bitCast((x - layer_rect.m_left) + (y - layer_rect.m_top) * layer_rect.width())));
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

    fn fill_rect_impl(this: *c_surface, _x0: int, _y0: int, _x1: int, _y1: int, rgb: uint, z_order: uint) void {
        const x0 = if (_x0 < 0) 0 else _x0;
        var y0 = if (_y0 < 0) 0 else _y0;
        const x1 = if (_x1 > (this.m_width - 1)) (this.m_width - 1) else _x1;
        const y1 = if (_y1 > (this.m_height - 1)) (this.m_height - 1) else _y1;

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
            for (@intCast(y0)..@intCast(y1 + 1)) |y| {
                // 				for (int x = x0; x <= x1; x++)
                for (@intCast(x0)..@intCast(x1 + 1)) |x| {
                    if (layer_rect.pt_in_rect(@intCast(x), @intCast(y))) {
                        if (this.m_color_bytes == 2) {
                            const fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_layers[uz_order].fb));
                            fb_u16[(y - @as(usize, @intCast(layer_rect.m_top))) * @as(usize, @as(u32, @bitCast(width))) + (x - @as(usize, @as(u32, @bitCast(layer_rect.m_left))))] = rgb_16;
                        } else {
                            const fb_uint: [*]uint = @ptrCast(@alignCast(this.m_layers[uz_order].fb));
                            fb_uint[(y - @as(usize, @as(u32, @bitCast(layer_rect.m_top)))) * @as(usize, @as(u32, @bitCast(width))) + (x - @as(usize, @as(u32, @bitCast(layer_rect.m_left))))] = rgb;
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

    pub fn draw_hline(this: *c_surface, _x0: int, _x1: int, y: int, rgb: uint, z_order: uint) void {
        const x0: usize = @as(u32, @bitCast(_x0));
        const x1: usize = @as(u32, @bitCast(_x1));
        // 		for (; x0 <= x1; x0++)
        for (x0..(x1 + 1)) |x| {
            const ix: i32 = @intCast(x);
            this.draw_pixel(ix, y, rgb, @enumFromInt(z_order));
        }
    }

    pub fn draw_vline(this: *c_surface, x: int, y0: int, y1: int, rgb: uint, z_order: uint) void {
        // for (; y0 <= y1; y0++)
        const _y0: usize = @as(usize, @as(u32, @bitCast(y0)));
        const _y1: usize = @as(usize, @as(u32, @bitCast(y1)));
        for (_y0..(_y1 + 1)) |y| {
            const iy: int = @truncate(@as(i64, @bitCast(y)));
            this.draw_pixel(x, iy, rgb, @enumFromInt(z_order));
        }
    }

    pub fn draw_line(this: *c_surface, _x1: int, _y1: int, _x2: int, _y2: int, rgb: uint, z_order: uint) void {
        // int dx, dy, x, y, e;
        var dx: int = 0;
        var dy: int = 0;
        var x: int = 0;
        var y: int = 0;
        var e: int = 0;
        var x1 = _x1;
        var x2 = _x2;
        var y1 = _y1;
        var y2 = _y2;
        if (x1 > x2) dx = x1 - x2 else dx = x2 - x1;
        if (y1 > y2) dy = y1 - y2 else dy = y2 - y1;

        if (((dx > dy) and (x1 > x2)) or ((dx <= dy) and (y1 > y2))) {
            x = x2;
            y = y2;
            x2 = x1;
            y2 = y1;
            x1 = x;
            y1 = y;
        }
        x = x1;
        y = y1;

        if (dx > dy) {
            e = dy - @divTrunc(dx, 2);
            // for (; x1 <= x2; ++x1, e += dy)
            while (x1 <= x2) : ({
                x1 +%= 1;
                e +%= dy;
            }) {
                this.draw_pixel(x1, y1, rgb, @enumFromInt(z_order));
                if (e > 0) {
                    e -%= dx;
                    if (y > y2) y1 +%= 1 else y1 +%= 1;
                }
            }
        } else {
            e = dx - @divTrunc(dy, 2);
            // for (; y1 <= y2; ++y1, e += dx)
            while (y1 <= y2) : ({
                y1 +%= 1;
                e +%= 1;
            }) {
                this.draw_pixel(x1, y1, rgb, @enumFromInt(z_order));
                if (e > 0) {
                    e -%= dy;
                    if (x > x2) x1 +%= 1 else x1 +%= 1;
                }
            }
        }
    }

    pub fn draw_rect_pos(this: *c_surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint, size: uint) void {
        // for (unsigned int offset = 0; offset < size; offset++)
        const _usize: usize = @as(usize, @as(u32, @bitCast(size)));
        for (0.._usize) |_offset| {
            const offset: int = @bitCast(@as(u32, @truncate(_offset)));
            this.draw_hline(x0 + offset, x1 - offset, y0 + offset, rgb, z_order);
            this.draw_hline(x0 + offset, x1 - offset, y1 - offset, rgb, z_order);
            this.draw_vline(x0 + offset, y0 + offset, y1 - offset, rgb, z_order);
            this.draw_vline(x1 - offset, y0 + offset, y1 - offset, rgb, z_order);
        }
    }

    pub fn draw_rect(this: *c_surface, rect: c_rect, rgb: int, size: uint, z_order: uint) void {
        this.draw_rect_pos(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, rgb, z_order, size);
    }

    pub fn flush_screen(this: *c_surface, left: int, top: int, right: int, bottom: int) int {
        if (!this.m_is_active) {
            return -1;
        }

        if (left < 0 or left >= this.m_width or right < 0 or right >= this.m_width or
            top < 0 or top >= this.m_height or bottom < 0 or bottom >= this.m_height)
        {
            api.ASSERT(false);
        }

        this.m_display.flush_screen(left, top, right, bottom, this.m_fb, this.m_width);
        this.m_phy_write_index.* = this.m_phy_write_index.* + 1;
        return 0;
    }

    fn is_active(this: c_surface) bool {
        return this.m_is_active;
    }
    fn get_display(this: c_surface) *c_display {
        return this.m_display;
    }

    pub fn activate_layer(this: *c_surface, active_rect: c_rect, active_z_order: uint) void //empty active rect means inactivating the layer
    {
        api.ASSERT(active_z_order > Z_ORDER_LEVEL_0 and active_z_order <= Z_ORDER_LEVEL_MAX);

        const uactive_z_order: usize = @as(u32, @bitCast(active_z_order));
        //Show the layers below the current active rect.
        const current_active_rect = this.m_layers[uactive_z_order].active_rect;
        // for(int low_z_order = Z_ORDER_LEVEL_0; low_z_order < active_z_order; low_z_order++)
        for (Z_ORDER_LEVEL_0..uactive_z_order) |low_z_order| {
            const low_layer_rect = this.m_layers[low_z_order].rect;
            const low_active_rect = this.m_layers[low_z_order].active_rect;
            const fb = this.m_layers[low_z_order].fb;
            const width: usize = @as(u32, @bitCast(low_layer_rect.width()));
            // for (int y = current_active_rect.m_top; y <= current_active_rect.m_bottom; y++)
            const uleft: usize = @as(u32, @bitCast(current_active_rect.m_left));
            const utop: usize = @as(u32, @bitCast(current_active_rect.m_top));
            const uright: usize = @as(u32, @bitCast(current_active_rect.m_right));
            const ubottom: usize = @as(u32, @bitCast(current_active_rect.m_bottom));
            for (utop..(ubottom + 1)) |y| {
                const iy: i32 = @truncate(@as(i64, @bitCast(y)));
                // for (int x = current_active_rect.m_left; x <= current_active_rect.m_right; x++)
                for (uleft..(uright + 1)) |x| {
                    const ix: i32 = @truncate(@as(i64, @bitCast(x)));
                    if (low_active_rect.pt_in_rect(ix, iy) and low_layer_rect.pt_in_rect(ix, iy)) //active rect maybe is bigger than layer rect
                    {
                        const fb_u16: [*]u16 = @alignCast(@ptrCast(fb));
                        const fb_uint: [*]uint = @alignCast(@ptrCast(fb));
                        const ulayer_rect_left: usize = @as(u32, @bitCast(low_layer_rect.m_left));
                        const ulayer_rect_top: usize = @as(u32, @bitCast(low_layer_rect.m_top));

                        const rgb = if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[(x - ulayer_rect_left) + (y - ulayer_rect_top) * width]) else fb_uint[(x - ulayer_rect_left) + (y - ulayer_rect_top) * width];
                        this.draw_pixel_low_level(ix, iy, rgb);
                    }
                }
            }
        }
        this.m_layers[uactive_z_order].active_rect = active_rect; //set the new acitve rect.
    }

    pub fn set_active(this: *c_surface, flag: bool) void {
        this.m_is_active = flag;
    }
    // protected:
    fn fill_rect_low_level_impl(this: *c_surface, _x0: int, _y0: int, _x1: int, _y1: int, rgb: int) void { //fill rect on framebuffer of surface
        const x0: usize = @as(u32, @bitCast(_x0));
        const y0: usize = @as(u32, @bitCast(_y0));
        const x1: usize = @as(u32, @bitCast(_x1));
        const y1: usize = @as(u32, @bitCast(_y1));
        const m_width: usize = @as(u32, @bitCast(this.m_width));
        std.log.debug("fill_rect_low_level_impl x0:{d} y0:{d} x1:{d} y1:{d} rgb:{d} m_color_bytes:{} m_fb:{*}", .{ x0, y0, x1, y1, rgb, this.m_color_bytes, this.m_fb });
        // int x, y;
        if (this.m_fb) |_fb| {
            if (this.m_color_bytes == 2) {
                const fb: [*]u16 = @ptrCast(@alignCast(_fb));
                const rgb_16 = api.GL_RGB_32_to_16(rgb);
                // for (y = y0; y <= y1; y++)
                for (y0..(y1 + 1)) |y| {
                    const _xfb = fb + y * m_width + x0;
                    // for (x = x0; x <= x1; x++)
                    for (x0..(x1 + 1)) |x| {
                        _xfb[x] = rgb_16;
                        std.log.debug("({},{}) = {}", .{ x, y, rgb_16 });
                    }
                }
            } else {
                const fb: [*]uint = @ptrCast(@alignCast(_fb));
                std.log.debug("_fb:{*} fb:{*}", .{ _fb, fb });
                // for (y = y0; y <= y1; y++)
                for (y0..(y1 + 1)) |y| {
                    // for (x = x0; x <= x1; x++)
                    for (x0..(x1 + 1)) |ix| {
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

    fn draw_pixel_low_level_impl(this: *c_surface, x: int, y: int, rgb: uint) void {
        // std.log.debug("draw_pixel_low_level_impl x:{d} y:{d} rgb:{d}", .{ x, y, rgb });
        if (this.m_fb != null) { //draw pixel on framebuffer of surface
            const fb_u16: [*]u16 = @ptrCast(@alignCast(this.m_fb));
            const fb_uint: [*]uint = @ptrCast(@alignCast(this.m_fb));
            const fb_idx: usize = @as(usize, @as(u32, @bitCast(y * this.m_width + x)));
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

    fn attach_display(this: *c_surface, display: *c_display) void {
        this.m_display = display;
        this.m_phy_write_index = &display.m_phy_write_index;
    }

    fn set_surface(this: *c_surface, max_z_order: Z_ORDER_LEVEL, layer_rect: c_rect) !void {
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
        // 		for (int i = Z_ORDER_LEVEL_0; i < m_max_zorder; i++)
        for (@intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_0)..@intFromEnum(this.m_max_zorder)) |j| {
            i = j; //Top layber fb always be 0
            this.m_layers[i].fb = @ptrCast(try core.allocator.alloc(u8, fb_size));
            // 			ASSERT(m_layers[i].fb = calloc(layer_rect.width() * layer_rect.height(), m_color_bytes));
            // 			m_layers[i].rect = layer_rect;
            this.m_layers[i].rect = layer_rect;
        }

        // 		m_layers[Z_ORDER_LEVEL_0].active_rect = layer_rect;
    }

    pub fn draw_pixel(this: *c_surface, x: int, y: int, rgb: uint, z_order: Z_ORDER_LEVEL) void {
        this.m_vtable.draw_pixel(this, x, y, rgb, z_order);
    }
    // pub fn fill_rect(this: *c_surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint) void {
    //     this.m_vtable.fill_rect(this, x0, y0, x1, y1, rgb, z_order);
    // }
    pub fn fill_rect(this: *c_surface, rect: c_rect, rgb: uint, z_order: uint) void {
        this.m_vtable.fill_rect(this, rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, rgb, z_order);
    }
    pub fn fill_rect_low_level(this: *c_surface, x0: int, y0: int, x1: int, y1: int, rgb: int) void {
        this.m_vtable.fill_rect_low_level(this, x0, y0, x1, y1, rgb);
    }
    pub fn draw_pixel_low_level(this: *c_surface, x: int, y: int, rgb: uint) void {
        this.m_vtable.draw_pixel_low_level(this, x, y, rgb);
    }
    const VTable = struct {
        draw_pixel: *const fn (this: *c_surface, x: int, y: int, rgb: uint, z_order: Z_ORDER_LEVEL) void = draw_pixel_impl,
        fill_rect: *const fn (this: *c_surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint) void = fill_rect_impl,
        fill_rect_low_level: *const fn (this: *c_surface, x0: int, y0: int, x1: int, y1: int, rgb: int) void = fill_rect_low_level_impl,
        draw_pixel_low_level: *const fn (this: *c_surface, x: int, y: int, rgb: uint) void = draw_pixel_low_level_impl,
    };

    m_vtable: VTable = .{},
    m_width: int = 0, //in pixels
    m_height: int = 0, //in pixels
    m_color_bytes: int = 0, //16 bits, 32 bits for default
    m_fb: ?[*]u8 = null, //frame buffer you could see
    m_layers: [@intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX)]c_layer = undefined, //all graphic layers
    m_is_active: bool, //active flag
    m_max_zorder: Z_ORDER_LEVEL = .Z_ORDER_LEVEL_0, //the highest graphic layer the surface will have
    m_top_zorder: Z_ORDER_LEVEL = .Z_ORDER_LEVEL_0, //the current highest graphic layer the surface have
    m_phy_write_index: ?*int = null,
    m_display: ?*c_display = null,
};

// inline c_display::c_display(void* phy_fb, int display_width, int display_height, c_surface* surface, DISPLAY_DRIVER* driver) : m_phy_fb(phy_fb), m_width(display_width), m_height(display_height), m_driver(driver), m_phy_read_index(0), m_phy_write_index(0), m_surface_cnt(1), m_surface_index(0)
// {
// 	m_color_bytes = surface->m_color_bytes;
// 	surface->m_is_active = true;
// 	(m_surface_group[0] = surface)->attach_display(this);
// }

// inline c_display::c_display(void* phy_fb, int display_width, int display_height, int surface_width, int surface_height, unsigned int color_bytes, int surface_cnt, DISPLAY_DRIVER* driver) : m_phy_fb(phy_fb), m_width(display_width), m_height(display_height), m_color_bytes(color_bytes), m_phy_read_index(0), m_phy_write_index(0), m_surface_cnt(surface_cnt), m_driver(driver), m_surface_index(0)
// {
// 	ASSERT(color_bytes == 2 or color_bytes == 4);
// 	ASSERT(m_surface_cnt <= SURFACE_CNT_MAX);
// 	memset(m_surface_group, 0, sizeof(m_surface_group));

// 	for (int i = 0; i < m_surface_cnt; i++)
// 	{
// 		m_surface_group[i] = new c_surface(surface_width, surface_height, color_bytes);
// 		m_surface_group[i]->attach_display(this);
// 	}
// }

// inline c_surface* c_display::alloc_surface(Z_ORDER_LEVEL max_zorder, c_rect layer_rect)
// {
// 	ASSERT(max_zorder < Z_ORDER_LEVEL_MAX and m_surface_index < m_surface_cnt);
// 	(layer_rect == c_rect()) ? m_surface_group[m_surface_index]->set_surface(max_zorder, c_rect(0, 0, m_width, m_height)) : m_surface_group[m_surface_index]->set_surface(max_zorder, layer_rect);
// 	return m_surface_group[m_surface_index++];
// }

// inline int c_display::swipe_surface(c_surface* s0, c_surface* s1, int x0, int x1, int y0, int y1, int offset)
// {
// 	int surface_width = s0->m_width;
// 	int surface_height = s0->m_height;

// 	if (offset < 0 or offset > surface_width or y0 < 0 or y0 >= surface_height or
// 		y1 < 0 or y1 >= surface_height or x0 < 0 or x0 >= surface_width or x1 < 0 or x1 >= surface_width)
// 	{
// 		ASSERT(false);
// 		return -1;
// 	}

// 	int width = (x1 - x0 + 1);
// 	if (width < 0 or width > surface_width or width < offset)
// 	{
// 		ASSERT(false);
// 		return -1;
// 	}

// 	x0 = (x0 >= m_width) ? (m_width - 1) : x0;
// 	x1 = (x1 >= m_width) ? (m_width - 1) : x1;
// 	y0 = (y0 >= m_height) ? (m_height - 1) : y0;
// 	y1 = (y1 >= m_height) ? (m_height - 1) : y1;

// 	if (m_phy_fb)
// 	{
// 		for (int y = y0; y <= y1; y++)
// 		{
// 			//Left surface
// 			char* addr_s = ((char*)(s0->m_fb) + (y * surface_width + x0 + offset) * m_color_bytes);
// 			char* addr_d = ((char*)(m_phy_fb)+(y * m_width + x0) * m_color_bytes);
// 			memcpy(addr_d, addr_s, (width - offset) * m_color_bytes);
// 			//Right surface
// 			addr_s = ((char*)(s1->m_fb) + (y * surface_width + x0) * m_color_bytes);
// 			addr_d = ((char*)(m_phy_fb)+(y * m_width + x0 + (width - offset)) * m_color_bytes);
// 			memcpy(addr_d, addr_s, offset * m_color_bytes);
// 		}
// 	}
// 	else if (m_color_bytes == 2)
// 	{
// 		void(*draw_pixel)(int x, int y, unsigned int rgb) = m_driver->draw_pixel;
// 		for (int y = y0; y <= y1; y++)
// 		{
// 			//Left surface
// 			for (int x = x0; x <= (x1 - offset); x++)
// 			{
// 				draw_pixel(x, y, GL_RGB_16_to_32(((unsigned short*)s0->m_fb)[y * m_width + x + offset]));
// 			}
// 			//Right surface
// 			for (int x = x1 - offset; x <= x1; x++)
// 			{
// 				draw_pixel(x, y, GL_RGB_16_to_32(((unsigned short*)s1->m_fb)[y * m_width + x + offset - x1 + x0]));
// 			}
// 		}
// 	}
// 	else //m_color_bytes == 3/4...
// 	{
// 		void(*draw_pixel)(int x, int y, unsigned int rgb) = m_driver->draw_pixel;
// 		for (int y = y0; y <= y1; y++)
// 		{
// 			//Left surface
// 			for (int x = x0; x <= (x1 - offset); x++)
// 			{
// 				draw_pixel(x, y, ((unsigned int*)s0->m_fb)[y * m_width + x + offset]);
// 			}
// 			//Right surface
// 			for (int x = x1 - offset; x <= x1; x++)
// 			{
// 				draw_pixel(x, y, ((unsigned int*)s1->m_fb)[y * m_width + x + offset - x1 + x0]);
// 			}
// 		}
// 	}

// 	m_phy_write_index++;
// 	return 0;
// }
