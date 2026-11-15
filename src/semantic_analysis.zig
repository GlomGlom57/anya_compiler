const sa = @import("syntax_analysis.zig");
const la = @import("lexical_analysis.zig");
const std = @import("std");

const i8_middle = 127;
const i16_middle = 32767;

pub const FileContent = struct {
    file: []const u8,
    tokens: std.ArrayList(la.Token),
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

const UNRESERVED = [_][]const u8{ "u8u", "i8u", "u16u", "i16u" };

pub fn semantic_analisys(constants: std.ArrayList(sa.Constant), writer: *std.Io.Writer, gpa: std.mem.Allocator) !void {
    // Verify constants
    try writer.print("Verifying {d} constants...\n", .{constants.items.len});
    var objconsts = try std.ArrayList(Const).initCapacity(gpa, 0);

    for (constants.items) |constant| {
        std.log.info("id: {s}|type: {s}| value: {s}", .{ constant.id, constant.datatype, constant.value });
    }

    for (constants.items) |constant| {
        var tmpcnst = Const{ .id = constant.id, .reserve = false, .datatype = undefined, .value = undefined };

        // Get const type
        std.log.info("Str: {s}", .{constant.datatype});
        for (0..UNRESERVED.len) |i| {
            if (std.mem.eql(u8, constant.datatype, UNRESERVED[i][0..])) {
                tmpcnst.datatype = @fromBackingInt(@intCast(i));
                std.log.info("Type: {d}", .{i});
                break;
            }
        }

        std.log.info("Type: {d}", .{tmpcnst.datatype});

        // Verify if value is valid
        tmpcnst.value = switch (tmpcnst.datatype) {
            DataType.U8, DataType.U16 => try std.fmt.parseInt(u16, constant.value, 10),
            else => if (tmpcnst.datatype == DataType.I8) @intCast(i8_middle + try std.fmt.parseInt(i8, constant.value, 10)) else @intCast(i16_middle + try std.fmt.parseInt(i16, constant.value, 10)),
        };

        try objconsts.append(gpa, tmpcnst);
    }

    try writer.print("All constants OK.\n", .{});
}
