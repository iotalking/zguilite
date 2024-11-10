const linux = @cImport({
    @cInclude("stdlib.h");
    @cInclude("string.h");
    @cInclude("stdio.h");
    @cInclude("fcntl.h");
    @cInclude("sys/ioctl.h");
    @cInclude("sys/shm.h");
    @cInclude("unistd.h");
    @cInclude("sys/mman.h");
    @cInclude("linux/fb.h");
    @cInclude("errno.h");
    @cInclude("sys/stat.h");
});

const printf = linux.printf;
const int = c_int;
fn get_dev_fb(path: []const u8, width: *int, height: *int, color_bytes: *int) !?*anyopaque {
    const fd = linux.open(@ptrCast(path), linux.O_RDWR);
    if (0 > fd) {
        return error.open_fb;
    }

    var vinfo: linux.fb_var_screeninfo = undefined;
    if (0 > linux.ioctl(fd, linux.FBIOGET_VSCREENINFO, &vinfo)) {
        // printf("get fb info failed!\n");
        // _exit(-1);
        return error.ioctl_screen_info;
    }

    width.* = @bitCast(vinfo.xres);
    height.* = @bitCast(vinfo.yres);
    const bits_per_pixel: int = @bitCast(vinfo.bits_per_pixel);
    color_bytes.* = @divExact(bits_per_pixel, 8);
    const ucolor_bytes: c_uint = @bitCast(color_bytes.*);
    if (width.* & 0x3 != 0) {
        _ = printf("Warning: vinfo.xres should be divided by 4!\nChange your display resolution to meet the rule.\n");
    }
    _ = printf("vinfo.xres=%d\n", vinfo.xres);
    _ = printf("vinfo.yres=%d\n", vinfo.yres);
    _ = printf("vinfo.bits_per_pixel=%d\n", vinfo.bits_per_pixel);

    const fbp = linux.mmap(@ptrFromInt(0), (vinfo.xres * vinfo.yres * ucolor_bytes), linux.PROT_READ | linux.PROT_WRITE, linux.MAP_SHARED, fd, 0);
    if (fbp == null) {
        _ = printf("mmap fb failed!\n");
        // linux._exit(-1);
        return error.mmap_fb;
    }
    _ = linux.memset(fbp, 0, (vinfo.xres * vinfo.yres * ucolor_bytes));
    return fbp;
}
