const std = @import("std");
const la = @import("lexical_analysis.zig");
const sa = @import("syntax_analysis.zig");
const sma = @import("semantic_analysis.zig");

fn deinitTokens(tokens: *std.ArrayList(la.Token), gpa: std.mem.Allocator) void {
    for (tokens.items) |token| gpa.free(token.content);
    tokens.deinit(gpa);
}

fn analyze(file: []const u8, io: std.Io, gpa: std.mem.Allocator, stdout: *std.Io.Writer, imports: *std.ArrayList([]const u8), functions: *std.ArrayList([]const u8), constants: *std.ArrayList(sa.Constant), files: *std.ArrayList(sma.FileContent), is_main: bool) !void {
    // Read file
    const content = std.Io.Dir.cwd().readFileAlloc(io, file, gpa, .unlimited) catch |e| {
        std.log.err("Error reading file {s}: {}", .{ file, e });
        std.process.exit(2);
    };

    defer gpa.free(content);

    var tokens = try std.ArrayList(la.Token).initCapacity(gpa, 0);
    defer deinitTokens(&tokens, gpa);

    try stdout.print("{s} lexical analysis... ", .{file});
    try stdout.flush();
    try la.lexical_analysis(content, &tokens, gpa);
    try stdout.print("OK.\n", .{});
    try stdout.flush();

    var file_content: sma.FileContent = .{ .file = file, .functions = try std.ArrayList(sma.Function).initCapacity(gpa, 0) };
    defer file_content.functions.deinit(gpa);

    try stdout.print("{s} syntax analysis... ", .{file});
    try stdout.flush();
    try sa.syntax_analysis(&file_content, tokens, imports, functions, constants, gpa);

    try files.append(gpa, file_content);
    file_content.functions = .empty;

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
            if (!std.mem.eql(u8, import, file[0..])) try analyze(import, io, gpa, stdout, imports, functions, constants, files, false);
            i += 1;
        }

        try stdout.print("\tImports readed.\n", .{});
        try stdout.flush();
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
    defer {
        for (functions.items) |function| gpa.free(function);
        functions.deinit(gpa);
    }

    var constants = try std.ArrayList(sa.Constant).initCapacity(gpa, 0);
    defer {
        for (constants.items) |*constant| constant.deinit(gpa);
        constants.deinit(gpa);
    }

    var buffer: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout();
    var writer = stdout.writer(io, &buffer);

    var files = try std.ArrayList(sma.FileContent).initCapacity(gpa, 0);
    defer {
        for (files.items) |*file| {
            for (file.functions.items) |*function| {
                gpa.free(function.id);
                deinitTokens(&function.tokens, gpa);
            }
            file.functions.deinit(gpa);
        }
        files.deinit(gpa);
    }

    try analyze(args[1], io, gpa, &writer.interface, &imports, &functions, &constants, &files, true);

    try writer.interface.print("\tFunctions... \n", .{});
    try writer.interface.flush();

    for (functions.items) |f| {
        std.log.info("{s}", .{f});
    }

    try writer.interface.print("\n", .{});
    try writer.interface.flush();

    try writer.interface.print("\tSemantic analysis... \n", .{});
    try writer.interface.flush();

    try sma.semantic_analisys(files, constants, functions, &writer.interface, gpa);

    try writer.interface.print("\tAll analysis completed.\n", .{});
    try writer.interface.flush();
}
