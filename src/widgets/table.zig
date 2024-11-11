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

const MAX_COL_NUM = 30;
const MAX_ROW_NUM = 30;

pub const TableDataItem = struct {
    str: []const u8,
    color: uint,
    w: uint = 0,
    h: uint = 0,
};
pub const TableData = struct {
    borderColor: uint = 0,
    bgColor: uint = 0,
    borderSize: uint = 1,
    items: ?[]const []const TableDataItem = null,
};
pub const Table = struct {
    wnd: wnd.Wnd = .{ .m_class = "Table", .m_vtable = .{
        .on_paint = Table.on_paint,
        .pre_create_wnd = Table.pre_create_wnd,
    } },
    m_align_type: uint = api.ALIGN_HCENTER | api.ALIGN_VCENTER,
    m_row_num: usize = 0,
    m_col_num: usize = 0,

    m_row_height: [MAX_ROW_NUM]uint = std.mem.zeroes([MAX_ROW_NUM]uint),
    m_col_width: [MAX_COL_NUM]uint = std.mem.zeroes([MAX_COL_NUM]uint),

    m_border_color: uint = 0,
    m_bg_color: uint = 0,

    pub fn asWnd(this: *Table) *Wnd {
        return &this.wnd;
    }

    fn on_paint(thisWnd: *Wnd) anyerror!void {
        const this: *Table = @fieldParentPtr("wnd", thisWnd);

        if (thisWnd.m_user_data) |userData| {
            const itemData: *align(1) const TableData = @ptrCast(userData);
            if (itemData.items) |items| {
                this.set_col_num(@truncate(items[0].len));
                this.set_row_num(@truncate(items.len));

                var rect = Rect.init();
                thisWnd.get_screen_rect(&rect);
                if (thisWnd.m_surface) |surface| {
                    const bgRect = rect.scale_pixel(-@as(int, @intCast(itemData.borderSize)));
                    surface.fill_rect(bgRect, itemData.bgColor, 0);
                }

                for (items, 0..) |rows, r| {
                    for (rows, 0..) |*col, c| {
                        const iRow: uint = @truncate(r);
                        const iCol: uint = @truncate(c);
                        _ = try this.set_col_width_by_index(c, col.w);
                        _ = try this.set_row_height_by_index(r, col.h);
                        this.draw_item(iRow, iCol, col.str, col.color);
                        std.log.debug("table ({d},{d}) {any}", .{ iRow, iCol, col.* });
                    }
                }

                if (thisWnd.m_surface) |surface| {
                    surface.draw_rect(rect, itemData.borderColor, 0, itemData.borderSize);
                }
            }
        }
    }
    fn pre_create_wnd(thisWnd: *Wnd) !void {
        thisWnd.m_attr = .ATTR_VISIBLE;
        thisWnd.m_font = Theme.get_font(.FONT_DEFAULT);
        thisWnd.m_font_color = Theme.get_color(.COLOR_WND_FONT);
        if (thisWnd.m_user_data) |userData| {
            const this: *Table = @fieldParentPtr("wnd", thisWnd);
            const itemData: *align(1) const TableData = @ptrCast(userData);
            this.m_border_color = itemData.*.borderColor;
            this.m_bg_color = itemData.*.bgColor;
        }
    }
    fn draw_item(this: *Table, row: uint, col: uint, str: []const u8, color: uint) void {
        const rect = this.get_item_rect(row, col);

        std.log.debug("table rect({d},{d}):{any} {s}", .{ row, col, rect, str });
        if (this.wnd.m_surface) |surface| {
            const bgRect = rect.scale_pixel(-1);
            std.log.debug("GL_MIX_COLOR item gbcolor:{X}", .{color});
            surface.fill_rect(bgRect, api.GL_MIX_COLOR(this.m_bg_color, color), this.wnd.m_z_order);
            Word.draw_string_in_rect(surface, this.wnd.m_z_order, str, rect, this.wnd.m_font, this.wnd.m_font_color, api.GL_ARGB(0, 0, 0, 0), this.m_align_type);
        }
    }

    fn get_item_rect(this: *Table, row: uint, col: uint) Rect {
        const Local = struct {
            var rect: Rect = Rect.init();
        };
        if (row >= MAX_ROW_NUM or col >= MAX_COL_NUM) {
            return Local.rect;
        }

        const uRow = row;
        const uCol = col;
        var width: uint = 0;
        var height: uint = 0;
        for (0..uCol) |i| {
            width += this.m_col_width[i];
        }
        for (0..uRow) |j| {
            height += this.m_row_height[j];
        }
        std.log.debug("table width:{d} height:{d}", .{ width, height });
        var wRect = Rect.init();
        this.wnd.get_screen_rect(&wRect);

        Local.rect.m_left = wRect.m_left + @as(int, @bitCast(width));
        Local.rect.m_right = Local.rect.m_left + @as(int, @bitCast(this.m_col_width[uCol]));
        if (Local.rect.m_right > wRect.m_right) {
            Local.rect.m_right = wRect.m_right;
        }
        Local.rect.m_top = wRect.m_top + @as(int, @bitCast(height));
        Local.rect.m_bottom = Local.rect.m_top + @as(int, @bitCast(this.m_row_height[uRow]));
        if (Local.rect.m_bottom > wRect.m_bottom) {
            Local.rect.m_bottom = wRect.m_bottom;
        }
        return Local.rect;
    }

    fn set_sheet_align(this: *Table, align_type: uint) void {
        this.m_align_type = align_type;
    }
    fn set_row_num(this: *Table, row_num: uint) void {
        this.m_row_num = row_num;
    }
    fn set_col_num(this: *Table, col_num: uint) void {
        this.m_col_num = col_num;
    }
    fn set_row_height(this: *Table, height: uint) void {
        std.log.debug("table set_row_height:{d}", .{height});
        for (0..this.m_row_num) |i| {
            this.m_row_height[i] = height;
        }
    }
    fn set_col_width(this: *Table, width: uint) void {
        for (0..this.m_col_num) |i| {
            this.m_col_width[i] = width;
        }
    }
    fn set_row_height_by_index(this: *Table, index: usize, height: uint) !usize {
        if (this.m_row_num > index) {
            this.m_row_height[index] = height;
            return index;
        }
        return error.row_num_gt_index;
    }
    fn set_col_width_by_index(this: *Table, index: usize, width: uint) !usize {
        if (this.m_col_num > index) {
            this.m_col_width[index] = width;
            return index;
        }
        return error.col_num_gt_index;
    }
    fn set_item(this: *Table, row: uint, col: uint, str: []const u8, color: uint) void {
        this.draw_item(row, col, str, color);
    }

    fn get_row_num(this: *const Table) uint {
        return this.m_row_num;
    }
    fn get_col_num(this: *const Table) uint {
        return this.m_col_num;
    }
};
