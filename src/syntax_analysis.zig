const std = @import("std");
const la = @import("lexical_analysis.zig");
const sma = @import("semantic_analysis.zig");

// Sections
const SECTION = "section";
const IMPORTS = ".imports";
const DATA = ".data";
const TEXT = ".text";
const ENDSECTION = "endsection";

// Data
const U8U = "u8u";
const I8U = "s8u";
const U16U = "u16u";
const I16U = "s16u";

const U8R = "u8r";
const I8R = "s8r";
const U16R = "u16r";
const I16R = "s16r";

// Math
const ADD = "add";
const SUB = "sub";
const MPL = "mpl";
const DIV = "div";
const PRIORITY_ON = "prioron";
const PRIORITY_OFF = "prioroff";

// Jumps
const JMP = "jmp";
const JMP_P = "jmpp";
const JMP_N = "jmpn";
const JMP_Z = "jmpz";
const JMP_NZ = "jmpnz";

// Functions
const CALL = "call";
const RET = "ret";

// Memory
//  SRAM Pointer
const SP_ADD = "@spadd";
const SP_SUB = "@spsub";

//  Loads
const LOAD_C = "@loadc";
const LOAD_U8 = "@loadu8";
const LOAD_S8 = "@loads8";
const LOAD_U16 = "@loadu16";
const LOAD_S16 = "@loads16";

//  SRAM Dirs and Values
const GET_VAL = "@getv";
const GET_DIR = "@getd";
const STORE = "@store";

// Screen
const CLEAR_W = ">clearw";
const CLEAR_B = ">clearb";
const PIX_ON_F = ">pixon_f";
const PIX_OFF_F = ">pixoff_f";
const PIX_ON_M = ">pixon_m";
const PIX_OFF_M = ">pixoff_m";
const SHOW = ">show";

// Game
const WAIT = "wait";
const RECV = "recv";
const END = "end";

const UNRESERVED_TYPES = [_][]const u8{ U8U, I8U, U16U, I16U };
const TWO_OPERAND_INSTRUCTIONS = [_][]const u8{ PIX_ON_F, PIX_OFF_F, PIX_ON_M, PIX_OFF_M };
const ONE_OPERAND_INSTRUCTIONS = [_][]const u8{ U8R, U8U, I8U, I8R, U16R, U16U, I16U, I16R, ADD, SUB, MPL, DIV, JMP, JMP_N, JMP_NZ, JMP_P, JMP_Z, CALL, RET, SP_ADD, SP_SUB, LOAD_C, LOAD_S16, LOAD_S8, LOAD_U16, LOAD_U8, GET_DIR, GET_VAL, STORE, WAIT, RECV };
const ZERO_OPERAND_INSTRUCTIONS = [_][]const u8{ PRIORITY_ON, PRIORITY_OFF, CLEAR_W, CLEAR_B, SHOW, END };

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
};

pub fn syntax_analysis(tokens: std.ArrayList(la.Token), imports: *std.ArrayList([]const u8), functions: *std.ArrayList([]const u8), constants: *std.ArrayList(Constant), gpa: std.mem.Allocator) !void {
    var expecting_id = false;
    var expecting_value = false;
    var expecting_section = false;
    var expecting_operands: u8 = 0;

    var section: Section = Section.NoSection;
    var tmp_const: Constant = undefined;

    for (tokens.items) |token| {
        const line = token.line;
        const content = token.content;

        if (std.mem.eql(u8, content, ENDSECTION[0..])) {
            section = Section.NoSection;
            continue;
        }

        switch (section) {
            Section.NoSection => {
                // Expect section
                if (!expecting_section) {
                    if (std.mem.eql(u8, content, SECTION[0..])) {
                        expecting_section = true;
                    } else {
                        std.log.err("Trying to create instructions before defining section at line {d}: {s}", .{ line, content });
                        std.process.exit(1);
                    }
                } else {
                    // Get section
                    section = if (std.mem.eql(u8, content, IMPORTS[0..])) Section.Imports else if (std.mem.eql(u8, content, DATA[0..])) Section.Data else if (std.mem.eql(u8, content, TEXT[0..])) Section.Text else {
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
                    const import_copy = try gpa.dupe(u8, token.content);
                    try imports.append(gpa, import_copy);
                }
            },

            Section.Data => {
                if (!expecting_id and !expecting_value) {
                    var found = false;
                    for (0..UNRESERVED_TYPES.len) |i| {
                        if (std.mem.eql(u8, content, UNRESERVED_TYPES[i][0..])) {
                            expecting_id = true;
                            found = true;
                            tmp_const.datatype = content;
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
                    tmp_const.id = content;
                    expecting_value = true;
                    expecting_id = false;
                } else if (expecting_value) {
                    tmp_const.value = content;
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
                    try functions.append(gpa, content[0 .. content.len - 1]);
                    continue;
                }

                // Is instruction
                if (expecting_operands == 0) {
                    var found = false;

                    // Two operand instructions
                    for (0..TWO_OPERAND_INSTRUCTIONS.len) |i| {
                        if (std.mem.eql(u8, content, TWO_OPERAND_INSTRUCTIONS[i][0..])) {
                            expecting_operands = 2;
                            found = true;
                            break;
                        }
                    }

                    if (!found) {
                        for (0..ONE_OPERAND_INSTRUCTIONS.len) |i| {
                            if (std.mem.eql(u8, content, ONE_OPERAND_INSTRUCTIONS[i][0..])) {
                                expecting_operands = 1;
                                found = true;
                                break;
                            }
                        }
                    }

                    if (!found) {
                        for (0..ZERO_OPERAND_INSTRUCTIONS.len) |i| {
                            if (std.mem.eql(u8, content, ZERO_OPERAND_INSTRUCTIONS[i][0..])) {
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
            },
        }
    }
}
