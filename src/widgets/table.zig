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
};
pub const TableData = struct {
    items: ?[]const []const TableDataItem = null,
};
pub const Table = struct {
    wnd: wnd.Wnd = .{ .m_class = "Table", .m_vtable = .{
        .pre_create_wnd = Table.pre_create_wnd,
    } },
    m_align_type: uint = 0,
    m_row_num: uint = 0,
    m_col_num: uint = 0,

    m_row_height: [MAX_ROW_NUM]uint = std.mem.zeroes([MAX_ROW_NUM]uint),
    m_col_width: [MAX_COL_NUM]uint = std.mem.zeroes([MAX_COL_NUM]uint),

    pub fn asWnd(this: *Table) *Wnd {
        return &this.wnd;
    }

    fn pre_create_wnd(thisWnd: *Wnd) !void {
        const this: *Table = @fieldParentPtr("wnd", thisWnd);
        thisWnd.m_attr = .ATTR_VISIBLE;
        thisWnd.m_font = Theme.get_font(.FONT_DEFAULT);
        thisWnd.m_font_color = Theme.get_color(.COLOR_WND_FONT);

        this.set_row_height(30);
        this.set_col_width(40);
        if (thisWnd.m_user_data) |userData| {
            const itemData: *align(1) const TableData = @ptrCast(userData);
            if (itemData.items) |items| {
                for (items, 0..) |rows, r| {
                    this.set_col_num(@truncate(rows.len));
                    this.set_row_num(@truncate(items.len));
                    for (rows, 0..) |*col, c| {
                        const iRow: int = @truncate(@as(isize, @bitCast(r)));
                        const iCol: int = @truncate(@as(isize, @bitCast(c)));
                        this.set_item(iRow, iCol, col.str, col.color);
                        std.log.debug("table ({d},{d}) str:{s},color:({d})", .{ iRow, iCol, col.str, col.color });
                    }
                }
            }
        }
    }
    fn draw_item(this: *Table, row: int, col: int, str: []const u8, color: uint) void {
        const rect = this.get_item_rect(row, col);
        if (this.wnd.m_surface) |surface| {
            const inerRect = Rect.init2(rect.m_left + 1, rect.m_top + 1, @as(u32, @bitCast(rect.m_right - 1)), @as(u32, @bitCast(rect.m_bottom - 1)));
            surface.fill_rect(inerRect, color, this.wnd.m_z_order);
            Word.draw_string_in_rect(surface, this.wnd.m_z_order, str, rect, this.wnd.m_font, this.wnd.m_font_color, api.GL_ARGB(0, 0, 0, 0), this.m_align_type);
        }
    }

    fn get_item_rect(this: *Table, row: int, col: int) Rect {
        const Local = struct {
            var rect: Rect = Rect.init();
        };
        if (row >= MAX_ROW_NUM or col >= MAX_COL_NUM) {
            return Local.rect;
        }

        const uRow = @as(u32, @bitCast(row));
        const uCol = @as(u32, @bitCast(col));
        var width: uint = 0;
        var height: uint = 0;
        for (0..uRow) |i| {
            width += this.m_col_width[i];
        }
        for (0..uCol) |j| {
            height += this.m_row_height[j];
        }

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
        for (0..@as(uint, @bitCast(this.m_row_num))) |i| {
            this.m_row_height[i] = height;
        }
    }
    fn set_col_width(this: *Table, width: uint) void {
        for (0..@as(uint, @bitCast(this.m_col_num))) |i| {
            this.m_col_width[i] = width;
        }
    }
    fn set_row_height_by_index(this: *Table, index: uint, height: uint) !uint {
        if (this.m_row_num > index) {
            this.m_row_height[index] = height;
            return index;
        }
        return error.row_num_gt_index;
    }
    fn set_col_width_by_index(this: *Table, index: uint, width: uint) !uint {
        if (this.m_col_num > index) {
            this.m_col_width[index] = width;
            return index;
        }
        return error.col_num_gt_index;
    }
    fn set_item(this: *Table, row: int, col: int, str: []const u8, color: uint) void {
        this.draw_item(row, col, str, color);
    }

    fn get_row_num(this: *const Table) uint {
        return this.m_row_num;
    }
    fn get_col_num(this: *const Table) uint {
        return this.m_col_num;
    }
};
