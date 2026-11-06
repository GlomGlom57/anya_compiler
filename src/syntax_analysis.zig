const std = @import("std");
const la = @import("lexical_analysis.zig");

// Sections
const SECTION = "section";
const IMPORTS = ".imports";
const DATA = ".data";
const TEXT = ".text";

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
const PIX_F = ">pixelf";
const PIX_M = ">pixelm";
const SHOW = ">show";

// Game
const WAIT = "wait";
const RECV = "recv";
const END = "end";

const Section = enum {
    Imports,
    Data,
    Text,
};

pub fn syntax_analysis(tokens: std.ArrayList(la.Token), imports: *std.ArrayList([]u8), gpa: std.mem.Allocator) !void {
    var expecting_id = false;
    var expecting_value = false;
    var expecting_section = false;
    var expecting_operands: u8 = 0;

    var section: Section = undefined;

    for (tokens.items) |token| {
        const line = token.line;
        const content = token.content;

        // Expect section
        if (!expecting_section) {
            if (std.mem.eql(u8, content, SECTION[0..])) {
                expecting_section = true;
                continue;
            } else {
                std.log.err("Trying to create instructions before defining section at line {d}: {s}", .{ line, content });
                std.process.exit(1);
            }
        }

        // Get section
        if (expecting_section) {
            section = if (std.mem.eql(u8, content, IMPORTS[0..])) Section.Imports else if (std.mem.eql(u8, content, DATA[0..])) Section.Data else if (std.mem.eql(u8, content, TEXT[0..])) Section.Text else {
                std.log.err("Invalid section type at line {d}: {s}", .{ line, content });
                std.process.exit(1);
            };

            expecting_section = false;
            continue;
        }

        switch (section) {
            Section.Imports => imports.append(gpa, content),

            Section.Data => {
                if (!expecting_id and !expecting_value) {
                    expecting_id = switch (content) {
                        U8U, I8U, U16U, I16U => true,
                        else => {
                            std.log.err("Invalid data '{s}' type at line {d}, or trying to create reserved data when it must be unreserved.", .{ content, line });
                            std.process.exit(1);
                        },
                    };
                } else if (expecting_id) {
                    expecting_value = true;
                    expecting_id = false;
                } else if (expecting_value) expecting_value = false;
            },

            Section.Text => {
                if (expecting_operands == 0) {
                    switch (content) {
                        // Two operand instructions
                        PIX_F, PIX_M => expecting_operands = 2,

                        // One operand instructions
                        U8R, U8U, I8U, I8R, U16R, U16U, I16U, I16R, ADD, SUB, MPL, DIV, JMP, JMP_N, JMP_NZ, JMP_P, JMP_Z, CALL, RET, SP_ADD, SP_SUB, LOAD_C, LOAD_S16, LOAD_S8, LOAD_U16, LOAD_U8, GET_DIR, GET_VAL, STORE, WAIT, RECV => expecting_operands = 1,

                        // Zero operand instructions
                        PRIORITY_ON, PRIORITY_OFF, CLEAR_W, CLEAR_B, SHOW, END => {},
                        else => {
                            std.log.err("Invalid instruction at line {d}: {s}", .{ line, content });
                            std.process.exit(1);
                        },
                    }
                } else expecting_operands -= 1;
            },
        }
    }
}
