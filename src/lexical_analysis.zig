const std = @import("std");

const signs_len = 2;
const signs: [signs_len]u8 = .{ ':', ',' };

pub const Token = struct { line: u32, content: []u8 };

pub fn lexical_analysis(content: []u8, tokens: *std.ArrayList(Token), gpa: std.mem.Allocator) !void {
    var ara = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = ara.allocator();
    var buffer = try std.ArrayList(u8).initCapacity(alloc, 0);

    var curr_line: u32 = 1;

    for (0..content.len) |i| {
        const c = content[i];

        if (c == '#') { // Comment
            curr_line += 1;
            continue;
        }

        if (c == ' ' or c == '\n' or c == '\t') {
            if (c == '\n') curr_line += 1;
            if (buffer.items.len != 0) {
                const copy = try gpa.dupe(u8, buffer.items);
                try tokens.append(gpa, Token{ .line = @as(u32, @intCast(i)) - 1, .content = copy });

                buffer.clearRetainingCapacity();
                continue;
            }
        }

        var is_sign = false;
        for (0..signs_len) |s| {
            if (c == signs[s]) {
                if (buffer.items.len != 0) {
                    const copy = try gpa.dupe(u8, buffer.items);
                    try tokens.append(gpa, Token{ .line = @as(u32, @intCast(i)), .content = copy });

                    buffer.clearRetainingCapacity();
                }
                const tmp_buff = [_]u8{c};
                const copy = try gpa.dupe(u8, &tmp_buff);
                try tokens.append(gpa, Token{ .line = @as(u32, @intCast(i)), .content = copy });

                is_sign = true;
                break;
            }
        }

        if (is_sign) continue;

        try buffer.append(alloc, c);
    }
}
