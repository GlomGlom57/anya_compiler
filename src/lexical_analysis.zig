const std = @import("std");

const separator = ',';

pub const Token = struct { line: u32, content: []u8 };

pub fn lexical_analysis(content: []const u8, tokens: *std.ArrayList(Token), gpa: std.mem.Allocator) !void {
    var ara = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = ara.allocator();
    var buffer = try std.ArrayList(u8).initCapacity(alloc, 0);

    var is_string = false;
    var curr_line: u32 = 1;

    for (0..content.len) |i| {
        const c = content[i];

        if ((c == ' ' or c == '\n' or c == '\t') and !is_string) {
            if (buffer.items.len != 0) {
                const copy = try gpa.dupe(u8, buffer.items);
                try tokens.append(gpa, Token{ .line = curr_line, .content = copy });
                buffer.clearRetainingCapacity();
            }
            if (c == '\n') curr_line += 1;
            continue;
        }

        if (c == '"') {
            is_string = !is_string;

            if (buffer.items.len != 0) {
                const copy = try gpa.dupe(u8, buffer.items);
                try tokens.append(gpa, Token{ .line = curr_line, .content = copy });
                buffer.clearRetainingCapacity();
            }

            continue;
        }

        if (c == separator and !is_string) {
            if (buffer.items.len != 0) {
                const copy = try gpa.dupe(u8, buffer.items);
                try tokens.append(gpa, Token{ .line = curr_line, .content = copy });

                buffer.clearRetainingCapacity();
            }
            continue;
        }

        try buffer.append(alloc, c);
    }
}
