const std = @import("std");
const la = @import("lexical_analysis.zig");
const sma = @import("semantic_analysis.zig");
const kw = @import("keywords.zig");

const Section = enum {
    Imports,
    Data,
    Text,
    NoSection,
};

pub const Constant = struct {
    id: []const u8,
    datatype: []const u8,
    value: []const u8,

    pub fn deinit(self: *Constant, gpa: std.mem.Allocator) void {
        gpa.free(self.id);
        gpa.free(self.datatype);
        gpa.free(self.value);
    }
};

pub fn syntax_analysis(file_content: *sma.FileContent, tokens: std.ArrayList(la.Token), imports: *std.ArrayList([]const u8), functions: *std.ArrayList([]const u8), constants: *std.ArrayList(Constant), gpa: std.mem.Allocator) !void {
    var expecting_id = false;
    var expecting_value = false;
    var expecting_section = false;
    var expecting_operands: u8 = 0;
    var in_func = false;

    var section: Section = Section.NoSection;
    var tmp_const: Constant = undefined;
    var func: sma.Function = .{
        .id = undefined,
        .tokens = .empty,
    };

    for (tokens.items) |token| {
        const line = token.line;
        const content = token.content;

        if (std.mem.eql(u8, content, kw.ENDSECTION[0..])) {
            section = Section.NoSection;
            continue;
        }

        switch (section) {
            Section.NoSection => {
                // Expect section
                if (!expecting_section) {
                    if (std.mem.eql(u8, content, kw.SECTION[0..])) {
                        expecting_section = true;
                    } else {
                        std.log.err("Trying to create instructions before defining section at line {d}: {s}", .{ line, content });
                        std.process.exit(1);
                    }
                } else {
                    // Get section
                    section = if (std.mem.eql(u8, content, kw.IMPORTS[0..])) Section.Imports else if (std.mem.eql(u8, content, kw.DATA[0..])) Section.Data else if (std.mem.eql(u8, content, kw.TEXT[0..])) Section.Text else {
                        std.log.err("Invalid section type at line {d}: {s}", .{ line, content });
                        std.process.exit(1);
                    };

                    expecting_section = false;
                }
            },
            Section.Imports => {
                var already_imported = false;
                for (imports.items) |import| {
                    if (std.mem.eql(u8, content, import[0..])) {
                        already_imported = true;
                        break;
                    }
                }

                if (!already_imported) {
                    const import_copy = try gpa.dupe(u8, content);
                    try imports.append(gpa, import_copy);
                }
            },

            Section.Data => {
                if (!expecting_id and !expecting_value) {
                    var found = false;
                    for (0..kw.UNRESERVED_TYPES.len) |i| {
                        if (std.mem.eql(u8, content, kw.UNRESERVED_TYPES[i][0..])) {
                            expecting_id = true;
                            found = true;
                            tmp_const.datatype = try gpa.dupe(u8, content);
                            break;
                        }
                    }

                    if (!found) {
                        std.log.err("Invalid data '{s}' type at line {d}, or trying to create reserved data when it must be unreserved.", .{ content, line });
                        std.process.exit(1);
                    }
                } else if (expecting_id) { // Const ID
                    // Verify if the const already exists
                    for (constants.items) |c| {
                        if (std.mem.eql(u8, c.id, content[0..])) {
                            std.log.err("Trying to create const {s} at line {d} that already exists.", .{ content, line });
                            std.process.exit(1);
                        }
                    }
                    tmp_const.id = try gpa.dupe(u8, content);
                    expecting_value = true;
                    expecting_id = false;
                } else if (expecting_value) {
                    tmp_const.value = try gpa.dupe(u8, content);
                    try constants.append(gpa, tmp_const);
                    expecting_value = false;
                }
            },

            Section.Text => {
                // Is function
                if (content[content.len - 1] == ':') {
                    for (functions.items) |f| {
                        if (std.mem.eql(u8, f, content[0 .. content.len - 1])) {
                            std.log.err("Trying to create a function {s} at line {d} that already exists.", .{ f, line });
                            std.process.exit(1);
                        }
                    }

                    if (!in_func) {
                        func = .{ .id = try gpa.dupe(u8, content), .tokens = try std.ArrayList(la.Token).initCapacity(gpa, 0) };
                        in_func = true;
                    } else {
                        try file_content.functions.append(gpa, func);
                        func = .{ .id = try gpa.dupe(u8, content), .tokens = try std.ArrayList(la.Token).initCapacity(gpa, 0) };
                    }

                    const copy = try gpa.dupe(u8, content[0 .. content.len - 1]);
                    try functions.append(gpa, copy);
                    continue;
                }

                // Is instruction
                if (expecting_operands == 0) {
                    var found = false;

                    // Two operand instructions
                    for (0..kw.TWO_OPERAND_INSTRUCTIONS.len) |i| {
                        if (std.mem.eql(u8, content, kw.TWO_OPERAND_INSTRUCTIONS[i][0..])) {
                            expecting_operands = 2;
                            found = true;
                            break;
                        }
                    }

                    if (!found) {
                        for (0..kw.ONE_OPERAND_INSTRUCTIONS.len) |i| {
                            if (std.mem.eql(u8, content, kw.ONE_OPERAND_INSTRUCTIONS[i][0..])) {
                                expecting_operands = 1;
                                found = true;
                                break;
                            }
                        }
                    }

                    if (!found) {
                        for (0..kw.ZERO_OPERAND_INSTRUCTIONS.len) |i| {
                            if (std.mem.eql(u8, content, kw.ZERO_OPERAND_INSTRUCTIONS[i][0..])) {
                                found = true;
                                break;
                            }
                        }
                    }

                    if (!found) {
                        std.log.err("Invalid instruction at line {d}: {s}", .{ line, content });
                        std.process.exit(1);
                    }
                } else expecting_operands -= 1; // Is parameter
                try func.tokens.append(gpa, .{
                    .line = token.line,
                    .content = try gpa.dupe(u8, token.content),
                });
            },
        }
    }

    if (in_func) try file_content.functions.append(gpa, func);
}
