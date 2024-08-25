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

pub const DISPLAY_DRIVER = struct {
    // void(*draw_pixel)(int x, int y, unsigned int rgb);
    draw_pixel: ?*const fn (x: int, y: int) void,
    // void(*fill_rect)(int x0, int y0, int x1, int y1, unsigned int rgb);
    fill_rect: ?*const fn (x0: int, y0: int, x1: int, y1: int, rgb: int) void,
};

// class c_surface;
pub const c_display = struct {
    // 	friend class c_surface;
    // public:
    inline fn init1(phy_fb: *anyopaque, display_width: int, display_height: int, surface: *c_surface, driver: *DISPLAY_DRIVER) c_display {
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
    inline fn init2(phy_fb: *anyopaque, display_width: int, display_height: int, surface_width: int, surface_height: int, color_bytes: uint, surface_cnt: int, driver: *DISPLAY_DRIVER) c_display {
        var this = c_display{
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
        @memset(this.m_surface_group, 0);

        var i = 0;
        errdefer {
            while (i >= 0) {
                const free_surface = this.m_surface_group[i];
                core.allocator.free(free_surface);
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
        return this;
    }
    inline fn alloc_surface(this: *c_display, max_zorder: Z_ORDER_LEVEL, layer_rect: c_rect) *c_surface {
        api.ASSERT(max_zorder < .Z_ORDER_LEVEL_MAX and this.m_surface_index < this.m_surface_cnt);
        if (layer_rect.eql(c_rect.init())) {
            this.m_surface_group[this.m_surface_index].set_surface(max_zorder, c_rect.init2(0, 0, this.m_width, this.m_height));
        } else {
            this.m_surface_group[this.m_surface_index].set_surface(max_zorder, layer_rect);
        }
        const ret = this.m_surface_group[this.m_surface_index];
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
        if ((x >= this.m_width) or (y >= this.m_height)) {
            return;
        }

        if (this.m_driver and this.m_driver.draw_pixel) {
            return this.m_driver.draw_pixel(x, y, rgb);
        }

        if (this.m_color_bytes == 2) {
            this.m_phy_fb[y * this.m_width + x] = api.GL_RGB_32_to_16(rgb);
        } else {
            this.m_phy_fb[y * this.m_width + x] = rgb;
        }
    }

    fn fill_rect_impl(this: *c_display, x0: int, y0: int, x1: int, y1: int, rgb: uint) void {
        if (this.m_driver != null and this.m_driver.fill_rect != null) {
            return this.m_driver.fill_rect(x0, y0, x1, y1, rgb);
        }

        if (this.m_driver != null and this.m_driver.draw_pixel != null) {
            // for (int y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                // for (int x = x0; x <= x1; x++)
                for (x0..(x1 + 1)) |x| {
                    this.m_driver.draw_pixel(x, y, rgb);
                }
            }
            return;
        }

        const _width = this.m_width;
        const _height = this.m_height;
        // 		int x, y;
        if (this.m_color_bytes == 2) {
            // 			unsigned short* phy_fb;
            const rgb_16 = api.GL_RGB_32_to_16(rgb);
            // 			for (y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                var phy_fb: [*]anyopaque = &this.m_phy_fb[y * _width + x0];
                // 				for (x = x0; x <= x1; x++)
                for (x0..(x1 + 1)) |x| {
                    if ((x < _width) and (y < _height)) {
                        phy_fb[0] = rgb_16;
                        phy_fb += 1;
                    }
                }
            }
        } else {
            // 			unsigned int* phy_fb;
            // 			for (y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                var phy_fb: [*]anyopaque = &this.m_phy_fb[y * _width + x0];
                // 				for (x = x0; x <= x1; x++)
                for (x0..(x1 + 1)) |x| {
                    if ((x < _width) and (y < _height)) {
                        phy_fb[0] = rgb;
                        phy_fb += 1;
                    }
                }
            }
        }
    }

    fn flush_screen_impl(this: *c_display, left: int, top: int, right: int, bottom: int, fb: *anyopaque, fb_width: int) int {
        if ((0 == this.m_phy_fb) or (0 == fb)) {
            return -1;
        }

        const _width = this.m_width;
        const _height = this.m_height;

        const _left = if (left >= _width) (_width - 1) else left;
        const _right = if (right >= _width) (_width - 1) else right;
        const _top = if (top >= _height) (_height - 1) else top;
        const _bottom = if (bottom >= _height) (_height - 1) else bottom;

        // // // for (int y = top; y < bottom; y++)
        for (_top.._bottom) |y| {
            const count = (_right - _left) * this.m_color_bytes;
            const s_addr: [count]anyopaque = fb + ((y * fb_width + _left) * this.m_color_bytes);
            const d_addr: [count]anyopaque = this.m_phy_fb + ((y * _width + _left) * this.m_color_bytes);
            // memcpy(d_addr, s_addr, (right - left) * m_color_bytes);
            @memcpy(d_addr, s_addr);
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

    m_width: int, //in pixels
    m_height: int, //in pixels
    m_color_bytes: int, //16/32 bits for default
    m_phy_fb: ?[*]u8, //physical framebuffer for default
    m_driver: ?*DISPLAY_DRIVER, //Rendering by external method without default physical framebuffer

    m_phy_read_index: int,
    m_phy_write_index: int,
    m_surface_group: [SURFACE_CNT_MAX]*c_surface,
    m_surface_cnt: int, //surface count
    m_surface_index: int,
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
        errdefer allocator.free(this);
        this.m_width = width;
        this.m_height = height;
        this.m_color_bytes = color_bytes;
        this.m_is_active = false;
        this.m_top_zorder = .Z_ORDER_LEVEL_0;
        this.m_phy_write_index = 0;

        // if(overlpa_rect.eql(.{})  set_surface(max_zorder, c_rect(0, 0, width, height)) : set_surface(max_zorder, overlpa_rect);
        if (overlpa_rect.eql(.{})) {
            this.set_surface(max_zorder, c_rect.init2(0, 0, width, height));
        } else {
            this.set_surface(max_zorder, overlpa_rect);
        }
        return this;
    }

    fn get_pixel(this: @This(), x: int, y: int, z_order: uint) !uint {
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

    fn draw_pixel_impl(this: *c_display, x: int, y: int, rgb: uint, z_order: uint) void {
        if (x >= this.m_width or y >= this.m_height or x < 0 or y < 0) {
            return;
        }

        if (z_order > this.m_max_zorder) {
            api.ASSERT(false);
            return;
        }

        if (z_order > this.m_top_zorder) {
            this.m_top_zorder = @enumFromInt(z_order);
        }

        if (z_order == this.m_max_zorder) {
            return this.draw_pixel_low_level(x, y, rgb);
        }

        if (this.m_layers[z_order].rect.pt_in_rect(x, y)) {
            const layer_rect = this.m_layers[z_order].rect;
            if (this.m_color_bytes == 2) {
                ((this.m_layers[z_order].fb))[(x - layer_rect.m_left) + (y - layer_rect.m_top) * layer_rect.width()] = api.GL_RGB_32_to_16(rgb);
            } else {
                ((this.m_layers[z_order].fb))[(x - layer_rect.m_left) + (y - layer_rect.m_top) * layer_rect.width()] = rgb;
            }
        }

        if (z_order == this.m_top_zorder) {
            return this.draw_pixel_low_level(x, y, rgb);
        }

        var be_overlapped = false;
        var tmp_z_order = @intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX) - 1;
        // for (unsigned int tmp_z_order = Z_ORDER_LEVEL_MAX - 1; tmp_z_order > z_order; tmp_z_order--)
        while (tmp_z_order > z_order) : (tmp_z_order -= 1) {
            if (this.m_layers[tmp_z_order].active_rect.pt_in_rect(x, y)) {
                be_overlapped = true;
                break;
            }
        }

        if (!be_overlapped) {
            this.draw_pixel_low_level(x, y, rgb);
        }
    }

    fn fill_rect_impl(this: c_surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint) void {
        x0 = if (x0 < 0) 0 else x0;
        y0 = if (y0 < 0) 0 else y0;
        x1 = if (x1 > (this.m_width - 1)) (this.m_width - 1) else x1;
        y1 = if (y1 > (this.m_height - 1)) (this.m_height - 1) else y1;

        if (z_order == this.m_max_zorder) {
            return this.fill_rect_low_level(x0, y0, x1, y1, rgb);
        }

        if (z_order == this.m_top_zorder) {
            const width = this.m_layers[z_order].rect.width();
            const layer_rect = this.m_layers[z_order].rect;
            const rgb_16 = api.GL_RGB_32_to_16(rgb);
            // 			for (int y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                // 				for (int x = x0; x <= x1; x++)
                for (x0..(x1 + 1)) |x| {
                    if (layer_rect.pt_in_rect(x, y)) {
                        if (this.m_color_bytes == 2) {
                            const fb_u16: [*]u16 = @ptrCast(this.m_layers[z_order].fb);
                            fb_u16[(y - layer_rect.m_top) * width + (x - layer_rect.m_left)] = rgb_16;
                        } else {
                            const fb_uint: [*]uint = @ptrCast(this.m_layers[z_order].fb);
                            fb_uint[(y - layer_rect.m_top) * width + (x - layer_rect.m_left)] = rgb;
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

    fn draw_hline(this: c_surface, x0: int, x1: int, y: int, rgb: uint, z_order: uint) void {
        // 		for (; x0 <= x1; x0++)
        for (x0..(x1 + 1)) |x| {
            this.draw_pixel(x, y, rgb, z_order);
        }
    }

    fn draw_vline(this: c_surface, x: int, y0: int, y1: int, rgb: uint, z_order: uint) void {
        // for (; y0 <= y1; y0++)
        for (y0..(y1 + 1)) |y| {
            this.draw_pixel(x, y, rgb, z_order);
        }
    }

    fn draw_line(this: c_surface, x1: int, y1: int, x2: int, y2: int, rgb: uint, z_order: uint) void {
        // int dx, dy, x, y, e;
        var dx: int = 0;
        var dy: int = 0;
        var x: int = 0;
        var y: int = 0;
        var e: int = 0;

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
            e = dy - dx / 2;
            // for (; x1 <= x2; ++x1, e += dy)
            while (x1 <= x2) : ({
                x1 += 1;
                e += dy;
            }) {
                this.draw_pixel(x1, y1, rgb, z_order);
                if (e > 0) {
                    e -= dx;
                    if (y > y2) y1 += 1 else y1 += 1;
                }
            }
        } else {
            e = dx - dy / 2;
            // for (; y1 <= y2; ++y1, e += dx)
            while (y1 <= y2) : ({
                y1 += 1;
                e += 1;
            }) {
                this.draw_pixel(x1, y1, rgb, z_order);
                if (e > 0) {
                    e -= dy;
                    if (x > x2) x1 += 1 else x1 += 1;
                }
            }
        }
    }

    fn draw_rect(this: c_surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint, size: uint) void {
        // for (unsigned int offset = 0; offset < size; offset++)
        for (0..size) |offset| {
            this.draw_hline(x0 + offset, x1 - offset, y0 + offset, rgb, z_order);
            this.draw_hline(x0 + offset, x1 - offset, y1 - offset, rgb, z_order);
            this.draw_vline(x0 + offset, y0 + offset, y1 - offset, rgb, z_order);
            this.draw_vline(x1 - offset, y0 + offset, y1 - offset, rgb, z_order);
        }
    }

    // fn draw_rect(this: c_surface, rect: c_rect, rgb: int, size: uint, z_order: uint) void {
    //     this.draw_rect(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, rgb, z_order, size);
    // }

    fn fill_rect(this: c_surface, rect: c_rect, rgb: int, z_order: uint) void {
        this.fill_rect(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, rgb, z_order);
    }

    fn flush_screen(this: c_surface, left: int, top: int, right: int, bottom: int) int {
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

    fn activate_layer(this: c_surface, active_rect: c_rect, active_z_order: uint) void //empty active rect means inactivating the layer
    {
        api.ASSERT(active_z_order > .Z_ORDER_LEVEL_0 and active_z_order <= .Z_ORDER_LEVEL_MAX);

        //Show the layers below the current active rect.
        const current_active_rect = this.m_layers[active_z_order].active_rect;
        // for(int low_z_order = Z_ORDER_LEVEL_0; low_z_order < active_z_order; low_z_order++)
        for (@intFromEnum(.Z_ORDER_LEVEL_0)..active_z_order) |low_z_order| {
            const low_layer_rect = this.m_layers[low_z_order].rect;
            const low_active_rect = this.m_layers[low_z_order].active_rect;
            const fb = this.m_layers[low_z_order].fb;
            const width = low_layer_rect.width();
            // for (int y = current_active_rect.m_top; y <= current_active_rect.m_bottom; y++)
            for (current_active_rect.m_top..(current_active_rect.m_bottom + 1)) |y| {
                // for (int x = current_active_rect.m_left; x <= current_active_rect.m_right; x++)
                for (current_active_rect.m_left..(current_active_rect.m_right + 1)) |x| {
                    if (low_active_rect.pt_in_rect(x, y) and low_layer_rect.pt_in_rect(x, y)) //active rect maybe is bigger than layer rect
                    {
                        const fb_u16: [*]u16 = @ptrCast(fb);
                        const fb_uint: [*]uint = @ptrCast(fb);
                        const rgb = if (this.m_color_bytes == 2) api.GL_RGB_16_to_32(fb_u16[(x - low_layer_rect.m_left) + (y - low_layer_rect.m_top) * width]) else fb_uint[(x - low_layer_rect.m_left) + (y - low_layer_rect.m_top) * width];
                        this.draw_pixel_low_level(x, y, rgb);
                    }
                }
            }
        }
        this.m_layers[active_z_order].active_rect = active_rect; //set the new acitve rect.
    }

    fn set_active(this: c_surface, flag: bool) void {
        this.m_is_active = flag;
    }
    // protected:
    fn fill_rect_low_level_impl(this: c_surface, x0: int, y0: int, x1: int, y1: int, rgb: int) void { //fill rect on framebuffer of surface
        // int x, y;
        if (this.m_color_bytes == 2) {
            var fb: ?[*]u16 = null;
            const rgb_16 = api.GL_RGB_32_to_16(rgb);
            // for (y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                fb = @ptrCast(this.m_fb);
                fb = if (this.m_fb != null) &(fb)[y * this.m_width + x0] else null;
                if (fb == null) {
                    break;
                }
                // for (x = x0; x <= x1; x++)
                for (x0..(x1 + 1)) |_| {
                    fb[0] = rgb_16;
                    fb += 1;
                }
            }
        } else {
            var fb: ?[*]uint = null;
            // for (y = y0; y <= y1; y++)
            for (y0..(y1 + 1)) |y| {
                fb = @ptrCast(this.m_fb);
                fb = if (this.m_fb != null) &fb[y * this.m_width + x0] else null;
                if (fb == null) {
                    break;
                }
                // for (x = x0; x <= x1; x++)
                for (x0..(x1 + 1)) |_| {
                    fb[0] = rgb;
                    fb += 1;
                }
            }
        }

        if (this.m_is_active == false) {
            return;
        }
        this.m_display.fill_rect(x0, y0, x1, y1, rgb);
        this.m_phy_write_index.* = this.m_phy_write_index.* + 1;
    }

    fn draw_pixel_low_level_impl(this: c_surface, x: int, y: int, rgb: uint) void {
        if (this.m_fb != null) { //draw pixel on framebuffer of surface
            const fb_u16: [*]u16 = @ptrCast(this.m_fb);
            const fb_uint: [*]uint = @ptrCast(this.m_fb);
            if (this.m_color_bytes == 2) fb_u16[y * this.m_width + x] = api.GL_RGB_32_to_16(rgb) else fb_uint[y * this.m_width + x] = rgb;
        }
        if (this.m_is_active == false) {
            return;
        }
        this.m_display.draw_pixel(x, y, rgb);
        this.m_phy_write_index.* = this.m_phy_write_index.* + 1;
    }

    fn attach_display(this: c_surface, display: *c_display) void {
        this.ASSERT(display != null);
        this.m_display = display;
        this.m_phy_write_index = &display.m_phy_write_index;
    }

    fn set_surface(this: *c_surface, max_z_order: Z_ORDER_LEVEL, layer_rect: c_rect) !void {
        this.m_max_zorder = max_z_order;
        if (this.m_display and (this.m_display.m_surface_cnt > 1)) {
            // m_fb = calloc(m_width * m_height, m_color_bytes);
            this.m_fb = try core.allocator.alloc(u8, this.m_width * this.m_height, this.m_color_bytes);
        }
        var i = 0;
        errdefer {
            core.allocator.free(this.m_fb);
        }

        errdefer {
            while (i >= 0) {
                const layer = this.m_layers[i];
                core.allocator.free(layer);
            }
        }
        // 		for (int i = Z_ORDER_LEVEL_0; i < m_max_zorder; i++)
        for (Z_ORDER_LEVEL.Z_ORDER_LEVEL_0..this.m_max_zorder) |j| {
            i = j; //Top layber fb always be 0
            this.m_layers[i] = try core.allocator.alloc(u8, layer_rect.width() * layer_rect.height(), this.m_color_bytes);
            // 			ASSERT(m_layers[i].fb = calloc(layer_rect.width() * layer_rect.height(), m_color_bytes));
            // 			m_layers[i].rect = layer_rect;
            this.m_layers[i].rect = layer_rect;
        }

        // 		m_layers[Z_ORDER_LEVEL_0].active_rect = layer_rect;
    }

    draw_pixel: *const fn (this: *c_display, x: int, y: int, rgb: uint, z_order: uint) void = draw_pixel_impl,
    fill_rect_impl: *const fn (this: c_surface, x0: int, y0: int, x1: int, y1: int, rgb: uint, z_order: uint) void = fill_rect_impl,
    fill_rect_low_level: *const fn (this: c_surface, x0: int, y0: int, x1: int, y1: int, rgb: int) void = fill_rect_low_level_impl,
    draw_pixel_low_level: *const fn (this: c_surface, x: int, y: int, rgb: uint) void = draw_pixel_low_level_impl,

    m_width: int, //in pixels
    m_height: int, //in pixels
    m_color_bytes: int, //16 bits, 32 bits for default
    m_fb: ?[*]u8, //frame buffer you could see
    m_layers: [@intFromEnum(Z_ORDER_LEVEL.Z_ORDER_LEVEL_MAX)]c_layer, //all graphic layers
    m_is_active: bool, //active flag
    m_max_zorder: Z_ORDER_LEVEL, //the highest graphic layer the surface will have
    m_top_zorder: Z_ORDER_LEVEL, //the current highest graphic layer the surface have
    m_phy_write_index: *int,
    m_display: *c_display,
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
