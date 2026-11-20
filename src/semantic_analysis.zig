const sa = @import("syntax_analysis.zig");
const la = @import("lexical_analysis.zig");
const kw = @import("keywords.zig");
const std = @import("std");

const i8_middle = 127;
const i16_middle = 32767;

pub const Function = struct {
    id: []const u8,
    tokens: std.ArrayList(la.Token),
};

pub const FileContent = struct {
    file: []const u8,
    functions: std.ArrayList(Function),
};

// Test
const DataType = enum(u8) {
    U8,
    I8,
    U16,
    I16,
};

const Const = struct {
    id: []const u8,
    datatype: DataType,
    value: u16,
    reserve: bool,
};

const Var = struct {
    id: []u8,
    datatype: DataType,
    reserve: bool,
};

pub fn semantic_analisys(files: std.ArrayList(FileContent), constants: std.ArrayList(sa.Constant), functions: std.ArrayList([]const u8), writer: *std.Io.Writer, gpa: std.mem.Allocator) !void {
    // Verify constants
    try writer.print("-----Verifying {d} constants.-----\n", .{constants.items.len});
    try writer.flush();

    var objconsts = try std.ArrayList(Const).initCapacity(gpa, 0);
    defer objconsts.deinit(gpa);

    for (constants.items) |constant| {
        var tmpcnst = Const{ .id = constant.id, .reserve = false, .datatype = undefined, .value = undefined };
        try writer.print("{s}... ", .{tmpcnst.id});
        try writer.flush();

        // Get const type
        for (0..kw.UNRESERVED_TYPES.len) |i| {
            if (std.mem.eql(u8, constant.datatype, kw.UNRESERVED_TYPES[i][0..])) {
                tmpcnst.datatype = @fromBackingInt(@intCast(i));
                break;
            }
        }

        // Verify if value is valid
        tmpcnst.value = switch (tmpcnst.datatype) {
            DataType.U8, DataType.U16 => try std.fmt.parseInt(u16, constant.value, 10),
            DataType.I8 => @intCast(@as(i16, i8_middle) + @as(i16, try std.fmt.parseInt(i8, constant.value, 10))),
            DataType.I16 => @intCast(@as(i32, i16_middle) + @as(i32, try std.fmt.parseInt(i16, constant.value, 10))),
        };

        try objconsts.append(gpa, tmpcnst);

        try writer.print("OK\n", .{});
        try writer.flush();
    }

    try writer.print("-----All constants OK.-----\n", .{});
    try writer.flush();

    try writer.print("-----Verifying program.-----\n", .{});
    try writer.flush();

    {
        var expecting_func = false;
        var expecting_var = false;
        var expecting_id = false;
        var expecting_const = false;
        var expecting_type: DataType = undefined;
        var current_type: DataType = undefined;

        var local_vars = try std.ArrayList(Var).initCapacity(gpa, 0);
        defer {
            for (local_vars.items) |*localv| gpa.free(localv.id);
            local_vars.deinit(gpa);
        }
        var curr_var: Var = .{ .datatype = undefined, .id = undefined, .reserve = undefined };

        for (files.items) |file| {
            try writer.print("{s}... ", .{file.file});
            try writer.flush();

            for (file.functions.items) |func| {
                for (func.tokens.items) |token| {
                    const content = token.content;
                    const line = token.line;

                    if (expecting_func) {
                        for (functions.items) |f| {
                            if (std.mem.eql(u8, content, f[0..])) {
                                expecting_func = false;
                                break;
                            }
                        }
                        if (expecting_func) { // Func not found
                            std.log.err("Error at line {d}: Function {s} not found.", .{ line, content });
                            std.process.exit(1);
                        }
                    } else if (expecting_var) {
                        for (local_vars.items) |v| {
                            if (std.mem.eql(u8, content, v.id[0..])) {
                                expecting_var = false;
                                break;
                            }
                        }
                        if (expecting_var) { // Var not found
                            std.log.err("Error at line {d}: Var {s} not found.", .{ line, content });
                            std.process.exit(1);
                        }
                    } else if (expecting_id) {
                        for (local_vars.items) |v| {
                            if (std.mem.eql(u8, content, v.id[0..])) {
                                std.log.err("Error at line {d}: Var {s} already exists.", .{ line, content });
                                std.process.exit(1);
                            }
                        }

                        curr_var.id = try gpa.dupe(u8, content);
                        try local_vars.append(gpa, curr_var);
                        expecting_id = false;
                    } else if (expecting_const) {
                        for (constants.items) |c| {
                            if (std.mem.eql(u8, content, c.id[0..])) {
                                expecting_const = false;
                                break;
                            }
                        }
                        if (expecting_const) { // Const not found
                            std.log.err("Error at line {d}: Const {s} not found.", .{ line, content });
                            std.process.exit(1);
                        }
                    } else {
                        var found = false;

                        // Should expect var
                        for (0..kw.VAR_OPERANDS.len) |i| {
                            if (std.mem.eql(u8, content, kw.VAR_OPERANDS[i][0..])) {
                                expecting_var = true;
                                found = true;
                                break;
                            }
                        }

                        if (found) continue;

                        // Should expect func
                        for (0..kw.FUNC_OPERANDS.len) |i| {
                            if (std.mem.eql(u8, content, kw.FUNC_OPERANDS[i][0..])) {
                                expecting_func = true;
                                found = true;
                                break;
                            }
                        }

                        if (found) continue;

                        // Creating var
                        for (0..kw.DATATYPES.len) |i| {
                            if (std.mem.eql(u8, content, kw.DATATYPES[i][0..])) {
                                expecting_id = true;
                                found = true;
                                break;
                            }
                        }
                    }
                }
            }
            try writer.print("OK.\n", .{});
            try writer.flush();
        }
        try writer.print("-----All programs OK.-----\n", .{});
        try writer.flush();
    }
}
