const std = @import("std");
const zguilite = @import("zguilite");

const ffmpeg = @cImport({
    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavformat/avformat.h");
    @cInclude("libswscale/swscale.h");
});

pub const AV_PIX_FMT_RGB565LE = ffmpeg.AV_PIX_FMT_RGB565LE;
pub const AV_PIX_FMT_BGR0 = ffmpeg.AV_PIX_FMT_BGR0;

pub const Player = struct{
    pub fn init(w:u32,h:u32,colorBytes:u32)Player{
        return Player{
            .width = w,
            .height = h,
            .colorBytes = colorBytes,
        };
    }
    pub fn open(self:*Player,fileName:[]const u8)!void{
        ffmpeg.av_register_all();

        var av_format_ctx:*ffmpeg.AVFormatContext = ffmpeg.avformat_alloc_context() orelse return error.avformat_alloc_context;
        self.av_format_ctx = av_format_ctx;
        errdefer {
            ffmpeg.avformat_close_input(@ptrCast(&av_format_ctx));
            ffmpeg.avformat_free_context(@ptrCast(av_format_ctx));
            self.av_format_ctx = null;
        }
        var buf = std.mem.zeroes([128]u8);
        const cFileName = try std.fmt.bufPrintZ(&buf,"{s}",.{fileName});
        if (ffmpeg.avformat_open_input(&self.av_format_ctx, cFileName, null, null) != 0) {
            std.debug.print("Couldn't open video file\n", .{});
            return error.avformat_open_input;
        }

        var av_codec_params: ?*ffmpeg.AVCodecParameters = null;
        var av_codec: ?*ffmpeg.AVCodec = null;
        for (0..av_format_ctx.nb_streams) |i| {
            const streams:[*][*]ffmpeg.AVStream = @ptrCast(av_format_ctx.streams);
            av_codec_params = streams[i][0].codecpar;
            av_codec = ffmpeg.avcodec_find_decoder(av_codec_params.?.codec_id);
            if (av_codec == null) {
                continue;
            }
            if (av_codec_params.?.codec_type == ffmpeg.AVMEDIA_TYPE_VIDEO) {
                self.video_stream_index = @intCast(i);
                self.time_base = self.av_format_ctx.?.streams[i][0].time_base;
                break;
            }
        }
        if (self.video_stream_index == -1) {
            std.debug.print("Couldn't find valid video stream inside file\n", .{});
            return error.not_found_video_stream_index;
        }

        self.av_codec_ctx = ffmpeg.avcodec_alloc_context3(av_codec);
        if (self.av_codec_ctx == null) {
            std.debug.print("Couldn't create AVCodecContext\n", .{});
            return error.avcodec_alloc_context3;
        }
        errdefer {
            ffmpeg.avcodec_free_context(&self.av_codec_ctx);
            self.av_codec_ctx = null;
        }
        if (ffmpeg.avcodec_parameters_to_context(self.av_codec_ctx, av_codec_params) < 0) {
            std.debug.print("Couldn't initialize AVCodecContext\n", .{});
            return error.avcodec_parameters_to_context;
        }
        if (ffmpeg.avcodec_open2(self.av_codec_ctx, av_codec, null) < 0) {
            std.debug.print("Couldn't open codec\n", .{});
            return error.avcodec_open2;
        }

        self.av_frame = ffmpeg.av_frame_alloc();
        if (self.av_frame == null) {
            std.debug.print("Couldn't allocate AVFrame\n", .{});
            return error.av_frame_alloc;
        }
        errdefer {
            ffmpeg.av_frame_free(&self.av_frame);
            self.av_frame = null;
        }
        self.av_packet = ffmpeg.av_packet_alloc();
        if (self.av_packet == null) {
            std.debug.print("Couldn't allocate AVPacket\n", .{});
            return error.av_packet_alloc;
        }
    }
    pub fn close(self:*Player)void{
        std.log.debug("Player close",.{});
        if(self.av_format_ctx)|_|{
            ffmpeg.avformat_close_input(&self.av_format_ctx);
            ffmpeg.avformat_free_context(self.av_format_ctx);
            self.av_format_ctx = null;
        }
        if(self.av_frame)|_|{
            ffmpeg.av_frame_free(&self.av_frame);
            self.av_frame = null;
        }
        if(self.av_packet)|_|{
            ffmpeg.av_packet_free(&self.av_packet);
            self.av_packet = null;
        }
        if(self.av_codec_ctx)|_|{
            ffmpeg.avcodec_free_context(&self.av_codec_ctx);
            self.av_codec_ctx = null;
        }
    }
    pub fn readFrame(self: *Player, phy_fb: ?*anyopaque, pixel_format: ffmpeg.AVPixelFormat) !void {
        var response: i32 = 0;
        while (ffmpeg.av_read_frame(self.av_format_ctx, self.av_packet) >= 0) {
            if (self.av_packet.?.stream_index != self.video_stream_index) {
                ffmpeg.av_packet_unref(self.av_packet);
                continue;
            }

            response = ffmpeg.avcodec_send_packet(self.av_codec_ctx, self.av_packet);
            if (response < 0) {
                std.debug.print("Failed to decode packet\n", .{});
                return error.avcodec_send_packet;
            }

            response = ffmpeg.avcodec_receive_frame(self.av_codec_ctx, self.av_frame);
            if (response == ffmpeg.AVERROR(ffmpeg.EAGAIN) or response == ffmpeg.AVERROR(ffmpeg.EOF)) {
                ffmpeg.av_packet_unref(self.av_packet);
                continue;
            } else if (response < 0) {
                std.debug.print("Failed to decode packet\n", .{});
                return error.avcodec_receive_frame;
            }
            ffmpeg.av_packet_unref(self.av_packet);
            break;
        }

        if (phy_fb == null) {
            return ;
        }
        if (self.sws_ctx == null) {
            self.sws_ctx = ffmpeg.sws_getContext(
                self.av_codec_ctx.?.width,
                self.av_codec_ctx.?.height,
                self.av_codec_ctx.?.pix_fmt,
                @intCast(self.width),
                @intCast(self.height),
                pixel_format,
                ffmpeg.SWS_BILINEAR,
                null,
                null,
                null,
            );
        }

        const frame_buffer: [4]?*u8 = .{ @ptrCast(phy_fb), null, null, null };
        const stride: [4]i32 = .{ @bitCast(self.colorBytes * self.width), 0, 0, 0 };
        const av_frame = self.av_frame orelse return error.av_frame_null;
        const scaleRet = ffmpeg.sws_scale(
            self.sws_ctx,
            &av_frame.data,
            &av_frame.linesize,
            0,
            av_frame.height,
            &frame_buffer,
            &stride,
        );
        if(scaleRet != self.height) {
            std.log.err("Player readFrame sws_scale ret:{d} frame.height:{d}",.{scaleRet,self.height});
            return error.sws_scale;
        }
        std.log.debug("Player readFrame scaleRet:{d} ",.{scaleRet});
    }
    pub fn currentSeconds(self: *Player)!f64{
        const av_frame = self.av_frame orelse return error.av_frame_null;
        const fcur_seconds:f64 = @as(f64,@floatFromInt( av_frame.pts)) * (@as(f64,@floatFromInt(self.time_base.num)) / @as(f64,@floatFromInt(self.time_base.den)));
        std.log.debug("player currentSeconds pts:{d} time_base:{any} fcur_seconds:{d:.4}",.{av_frame.pts,self.time_base,fcur_seconds});
        return fcur_seconds;
    }
    pub fn seekFrame(self: *Player, ts: i64) !void {
        ffmpeg.av_seek_frame(self.av_format_ctx, self.video_stream_index, ts, ffmpeg.AVSEEK_FLAG_BACKWARD);

        var response: i32 = 0;
        while (ffmpeg.av_read_frame(self.av_format_ctx, self.av_packet) >= 0) {
            if (self.av_packet.?.stream_index != self.video_stream_index) {
                ffmpeg.av_packet_unref(self.av_packet);
                continue;
            }

            response = ffmpeg.avcodec_send_packet(self.av_codec_ctx, self.av_packet);
            if (response < 0) {
                std.debug.print("Failed to decode packet\n", .{});
                return error.avcodec_send_packet;
            }

            response = ffmpeg.avcodec_receive_frame(self.av_codec_ctx, self.av_frame);
            if (response == ffmpeg.AVERROR(ffmpeg.EAGAIN) or response == ffmpeg.AVERROR(ffmpeg.EOF)) {
                ffmpeg.av_packet_unref(self.av_packet);
                continue;
            } else if (response < 0) {
                std.debug.print("Failed to decode packet\n", .{});
                return error.avcodec_receive_frame;
            }

            ffmpeg.av_packet_unref(self.av_packet);
            break;
        }
    }
    pub fn renderRawData(self:*Player,surface:*zguilite.Surface)!void{
        const av_frame = self.av_frame orelse return error.av_frame_null;
        var luma = av_frame.data[0];
        var u = av_frame.data[1];
        var v = av_frame.data[2];

        const width = av_frame.width;
        const height = av_frame.height;
        const luma_stride = av_frame.linesize[0];
        const uv_stride = av_frame.linesize[1];

        var y: i32 = 0;
        while (y < height) : (y += 1) {
            var x: i32 = 0;
            while (x < width) : (x += 1) {
                // 获取 YUV 分量
                const ux:usize = @intCast(x);
                const ux2:usize = @intCast(@divTrunc(x ,2));
                const y_val = luma[ux];
                const u_val = u[ux2];
                const v_val = v[ux2];

                // YUV 转 RGB
                const f_y_val:f32 = @floatFromInt(y_val);
                const f_v_val:f32 = @floatFromInt(v_val);
                const f_u_val:f32 = @floatFromInt(u_val);
                var r:u32 = @bitCast(f_y_val + 1.402 * (f_v_val - 128));
                var g:u32 = @bitCast(f_y_val - 0.34414 * (f_u_val - 128) - 0.71414 * (f_v_val - 128));
                var b:u32 = @bitCast(f_y_val + 1.772 * (f_u_val - 128));

                // 限制 RGB 值在 0-255 范围内
                r = if (r > 255) 255 else if (r < 0) 0 else r;
                g = if (g > 255) 255 else if (g < 0) 0 else g;
                b = if (b > 255) 255 else if (b < 0) 0 else b;

                // 绘制像素
                surface.draw_pixel(x, y, zguilite.GL_RGB(r,g,b),.Z_ORDER_LEVEL_0);
            }

            // 移动到下一行
            const u_luma_stride = @as(usize,@intCast(luma_stride));
            luma += u_luma_stride;
            const u_uv_stride = @as(usize,@intCast(uv_stride));
            if (@mod(y , 2) == 0) {
                u += u_uv_stride;
                v += u_uv_stride;
            }
        }
    } 
    width:u32 = 0,
    height:u32 = 0,
    colorBytes:u32 = 0,
    sws_ctx: ?*ffmpeg.SwsContext = null,
    av_format_ctx: ?*ffmpeg.AVFormatContext = null,
    av_codec_ctx: ?*ffmpeg.AVCodecContext = null,
    av_frame: ?*ffmpeg.AVFrame = null,
    av_packet: ?*ffmpeg.AVPacket = null,
    video_stream_index: i32 = -1,
    time_base: ffmpeg.AVRational = undefined,

};