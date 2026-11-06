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
    var inside_func = false;

    var section: Section = undefined;

    for (tokens.items) |token| {
        const line = token.line;
        const content = token.content;

        // Expect section
        if (content == SECTION) {
            expecting_section = true;
            continue;
        }

        // Get section
        if (expecting_section) {
            section = switch (content) {
                IMPORTS => Section.Imports,
                DATA => Section.Data,
                TEXT => Section.Text,
            };
            expecting_section = false;
            continue;
        }

        switch (section) {
            IMPORTS => imports.append(gpa, content),
            DATA => {
                if (!expecting_id and !expecting_value) {
                    expecting_id = switch (content) {
                        U8U, I8U, U16U, I16U => true,
                        else => {
                            std.log.err("Invalid data '{s}' type at line {d}.", .{ content, line });
                            std.process.exit(1);
                        },
                    };
                } else if (expecting_id) {
                    expecting_value = true;
                    expecting_id = false;
                } else if (expecting_value) expecting_value = false;
            },
            TEXT => {},
        }
    }
}
