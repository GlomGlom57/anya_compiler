const std = @import("std");
const la = @import("lexical_analysis.zig");
const sa = @import("syntax_analysis.zig");

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

    // Read file
    const content = std.Io.Dir.cwd().readFileAlloc(io, args[1], gpa, .unlimited) catch |e| {
        std.log.err("Error reading file: {}", .{e});
        std.process.exit(2);
    };
    defer gpa.free(content);

    var tokens = try std.ArrayList(la.Token).initCapacity(gpa, 0);
    defer {
        for (tokens.items) |item| {
            gpa.free(item.content);
        }
        tokens.deinit(gpa);
    }
    try la.lexical_analysis(content, &tokens, gpa);

    var imports = try std.ArrayList([]u8).initCapacity(gpa, 0);
    defer imports.deinit(gpa);

    try sa.syntax_analysis(tokens, &imports, gpa);
}
