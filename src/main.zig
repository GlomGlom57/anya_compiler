const std = @import("std");
const la = @import("lexical_analysis.zig");
const sa = @import("syntax_analysis.zig");
const sma = @import("semantic_analysis.zig");

fn analyze(file: []const u8, io: std.Io, gpa: std.mem.Allocator, stdout: *std.Io.Writer, imports: *std.ArrayList([]const u8), functions: *std.ArrayList([]const u8), constants: *std.ArrayList(sa.Constant), files: *std.ArrayList(sma.FileContent), is_main: bool) !void {
    // Read file
    const content = std.Io.Dir.cwd().readFileAlloc(io, file, gpa, .unlimited) catch |e| {
        std.log.err("Error reading file {s}: {}", .{ file, e });
        std.process.exit(2);
    };

    defer gpa.free(content);

    var tokens = try std.ArrayList(la.Token).initCapacity(gpa, 0);

    try stdout.print("{s} lexical analysis... ", .{file});
    try stdout.flush();
    try la.lexical_analysis(content, &tokens, gpa);
    try stdout.print("OK.\n", .{});
    try stdout.flush();

    try stdout.print("{s} syntax analysis... ", .{file});
    try stdout.flush();
    try sa.syntax_analysis(tokens, imports, functions, constants, gpa);
    try stdout.print("OK.\n", .{});
    try stdout.flush();

    if (is_main) {
        try stdout.print("\n\tAnalyzing imports... \n", .{});
        try stdout.flush();

        var i: usize = 0;
        while (true) {
            const len = imports.items.len;
            if (i >= len) break;

            const import = imports.items[i];
            if (!std.mem.eql(u8, import, file[0..])) {
                try analyze(import, io, gpa, stdout, imports, functions, constants, files, false);
                const f = sma.FileContent{ .file = file, .tokens = tokens };
                try files.append(gpa, f);

                // Verify repeated consts
                for (constants.items, 0..) |constant1, j| {
                    for (constants.items, 0..) |costant2, k| {
                        if (std.mem.eql(u8, constant1.id, costant2.id[0..]) and j != k) {
                            std.log.err("Repeated const: {s}", .{constant1.id});
                            std.process.exit(1);
                        }
                    }
                }

                // Verify repeated functions
                for (functions.items, 0..) |fn1, j| {
                    for (functions.items, 0..) |fn2, k| {
                        if (std.mem.eql(u8, fn1, fn2[0..]) and j != k) {
                            std.log.err("Repeated function: {s}", .{fn1});
                            std.process.exit(1);
                        }
                    }
                }
            }
            i += 1;
        }

        try stdout.print("\tImports readed.\n", .{});
        try stdout.flush();

        for (constants.items) |constant| {
            std.log.info("id: {s}|type: {s}| value: {s}", .{ constant.id, constant.datatype, constant.value });
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    // Get arguments
    const args = try init.minimal.args.toSlice(gpa);
    defer gpa.free(args);

    if (args.len != 2) {
        std.log.err("Expected file, found {d} arguments.", .{args.len});
        std.process.exit(1);
    }

    var imports = try std.ArrayList([]const u8).initCapacity(gpa, 0);
    defer {
        for (imports.items) |import| gpa.free(import);

        imports.deinit(gpa);
    }

    var functions = try std.ArrayList([]const u8).initCapacity(gpa, 0);
    defer functions.deinit(gpa);

    var constants = try std.ArrayList(sa.Constant).initCapacity(gpa, 0);
    defer constants.deinit(gpa);

    var buffer: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout();
    var writer = stdout.writer(io, &buffer);

    var files = try std.ArrayList(sma.FileContent).initCapacity(gpa, 0);
    defer {
        files.deinit(gpa);
    }

    try analyze(args[1], io, gpa, &writer.interface, &imports, &functions, &constants, &files, true);

    try writer.interface.print("\tSemantic analysis... ", .{});
    try writer.interface.flush();

    try sma.semantic_analisys(constants, &writer.interface, gpa);

    try writer.interface.print("\tAll analysis completed.\n", .{});
    try writer.interface.flush();
}
