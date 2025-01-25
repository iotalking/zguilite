const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "freetype",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/freetype.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(b.path("./src/freetype_include/"));
    lib.linkLibC();
    lib.addLibraryPath(b.path("./src/libs/x86"));
    lib.linkSystemLibrary("freetype");

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const m = b.addModule("freetype", .{
        .root_source_file = b.path("./src/freetype.zig"),
        .target = target,
        .optimize = optimize,
    });
    m.addImport("zguilite", b.dependency("zguilite", .{}).module("zguilite"));
    m.addIncludePath(b.path("./src/freetype_include/"));
    m.link_libc = true;
    m.addLibraryPath(b.path("./src/libs/x86"));
    m.linkSystemLibrary("freetype",.{});
}
