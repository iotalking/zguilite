const api = @import("./api.zig");

pub const COLORS = struct {
    pub const WHITE = api.GL_RGB(255, 255, 255);
    pub const BLACK = api.GL_RGB(0, 0, 0);
    pub const RED = api.GL_RGB(255, 0, 0);
    pub const GREED = api.GL_RGB(0, 255, 0);
    pub const BLUE = api.GL_RGB(0, 0, 255);
};
