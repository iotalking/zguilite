const types = @import("../core/types.zig");
const api = @import("./api.zig");
const resource = @import("./resource.zig");
const display = @import("./display.zig");

const Surface = display.Surface;
const Rect = api.Rect;
const int = types.int;
const uint = types.uint;
const BITMAP_INFO = resource.BITMAP_INFO;

pub const DEFAULT_MASK_COLOR = 0xFF080408;
// class Surface;

pub const ImageOperator = struct {
    // public:
    draw_image: ?*const fn (surface: *Surface, z_order: int, image_info: *anyopaque, x: int, y: int, mask_rgb: uint) void = null,

    draw_image_from_src: ?*const fn (surface: *Surface, z_order: int, image_info: *anyopaque, x: int, y: int, src_x: int, src_y: int, width: int, height: int, mask_rgb: uint) void = null,
};

pub const BitmapOperator = struct {
    parent: ImageOperator,

    fn init() BitmapOperator {
        return .{ .parent = .{
            .draw_pixel = BitmapOperator.draw_image,
            .draw_image_from_src = BitmapOperator.draw_image_from_src,
        } };
    }
    // public:
    fn draw_image(surface: *Surface, z_order: int, image_info: *anyopaque, x: int, y: int, mask_rgb: uint) void {
        api.ASSERT(image_info != null);
        const pBitmap: *BITMAP_INFO = @ptrCast(image_info);
        var lower_fb_16: ?[*]u16 = null;
        var lower_fb_32: ?[*]uint = null;
        var lower_fb_width = 0;
        var lower_fb_rect: Rect = Rect.init();
        if (z_order >= .Z_ORDER_LEVEL_1) {
            lower_fb_16 = @ptrCast(surface.m_layers[z_order - 1].fb);
            lower_fb_32 = @ptrCast(surface.m_layers[z_order - 1].fb);
            lower_fb_rect = surface.m_layers[z_order - 1].rect;
            lower_fb_width = lower_fb_rect.width();
        }
        const mask_rgb_16 = api.GL_RGB_32_to_16(mask_rgb);
        const xsize = pBitmap.width;
        const ysize = pBitmap.height;
        const pData: [*]u16 = @ptrCast(pBitmap.pixel_color_array);
        const color_bytes = surface.m_color_bytes;
        // for (int y_ = y; y_ < y + ysize; y_++)
        for (y..(y * ysize)) |y_| {
            // for (int x_ = x; x_ < x + xsize; x_++)
            for (x..(x + xsize)) |x_| {
                const rgb = pData[0];
                pData += 1;
                if (mask_rgb_16 == rgb) {
                    if (lower_fb_rect.pt_in_rect(x_, y_)) { //show lower layer
                        surface.draw_pixel(x_, y_, if (color_bytes == 4) lower_fb_32[(y_ - lower_fb_rect.m_top) * lower_fb_width + (x_ - lower_fb_rect.m_left)] else api.GL_RGB_16_to_32(lower_fb_16[(y_ - lower_fb_rect.m_top) * lower_fb_width + (x_ - lower_fb_rect.m_left)]), z_order);
                    }
                } else {
                    surface.draw_pixel(x_, y_, api.GL_RGB_16_to_32(rgb), z_order);
                }
            }
        }
    }

    fn draw_image_from_src(surface: *Surface, z_order: int, image_info: *anyopaque, x: int, y: int, src_x: int, src_y: int, width: int, height: int, mask_rgb: uint) void {
        api.ASSERT(image_info != null);
        const pBitmap: ?*BITMAP_INFO = @ptrCast(image_info);
        if (null == pBitmap or (src_x + width > pBitmap.width) or (src_y + height > pBitmap.height)) {
            return;
        }

        var lower_fb_16: ?[*]u16 = null;
        var lower_fb_32: ?[*]uint = null;
        var lower_fb_width = 0;
        var lower_fb_rect: Rect = Rect.init();
        if (z_order >= .Z_ORDER_LEVEL_1) {
            lower_fb_16 = @ptrCast(surface.m_layers[z_order - 1].fb);
            lower_fb_32 = @ptrCast(surface.m_layers[z_order - 1].fb);
            lower_fb_rect = surface.m_layers[z_order - 1].rect;
            lower_fb_width = lower_fb_rect.width();
        }
        const mask_rgb_16 = api.GL_RGB_32_to_16(mask_rgb);
        const pData: [*]u16 = @ptrCast(pBitmap.pixel_color_array);
        const color_bytes = surface.m_color_bytes;
        // for (int y_ = 0; y_ < height; y_++)
        for (0..height) |y_| {
            const p: [*]u16 = &pData[src_x + (src_y + y_) * pBitmap.width];
            // for (int x_ = 0; x_ < width; x_++)
            for (0..width) |x_| {
                const rgb = p[0];
                p += 1;
                if (mask_rgb_16 == rgb) {
                    if (lower_fb_rect.pt_in_rect(x + x_, y + y_)) { //show lower layer
                        surface.draw_pixel(x + x_, y + y_, if (color_bytes == 4) lower_fb_32[(y + y_ - lower_fb_rect.m_top) * lower_fb_width + x + x_ - lower_fb_rect.m_left] else api.GL_RGB_16_to_32(lower_fb_16[(y + y_ - lower_fb_rect.m_top) * lower_fb_width + x + x_ - lower_fb_rect.m_left]), z_order);
                    }
                } else {
                    surface.draw_pixel(x + x_, y + y_, api.GL_RGB_16_to_32(rgb), z_order);
                }
            }
        }
    }
};

pub const Image = struct {
    // public:
    fn draw_image(surface: *Surface, z_order: int, image_info: *anyopaque, x: int, y: int, mask_rgb: uint) void {
        image_operator.draw_image(surface, z_order, image_info, x, y, mask_rgb);
    }

    fn draw_image_from_src(surface: *Surface, z_order: int, image_info: *anyopaque, x: int, y: int, src_x: int, src_y: int, width: int, height: int, mask_rgb: uint) void {
        image_operator.draw_image_from_src(surface, z_order, image_info, x, y, src_x, src_y, width, height, mask_rgb);
    }

    const image_operator = ImageOperator.init();
};
