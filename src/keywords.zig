// Sections
pub const SECTION = "section";
pub const IMPORTS = ".imports";
pub const DATA = ".data";
pub const TEXT = ".text";
pub const ENDSECTION = "endsection";

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
const PRIORITY_ON = "@prioron";
const PRIORITY_OFF = "@prioroff";

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
const CLEAR_W = "clearw";
const CLEAR_B = "clearb";
const PIX_ON_F = "pixon_f";
const PIX_OFF_F = "pixoff_f";
const PIX_ON_M = "pixon_m";
const PIX_OFF_M = "pixoff_m";
const SHOW = "show";

// Game
const WAIT = "wait";
const RECV = "recv";
const END = "end";

pub const UNRESERVED_TYPES = [_][]const u8{ U8U, I8U, U16U, I16U };
pub const RESERVED_TYPES = [_][]const u8{ U8R, I8R, U16R, I16R };

pub const DATATYPES = [_][]const u8{ U8U, I8U, U16U, I16U, U8R, I8R, U16R, I16R };
pub const FUNC_OPERANDS = [_][]const u8{ CALL, JMP, JMP_P, JMP_N, JMP_Z, JMP_NZ };
pub const LOAD_OPERANDS = [_][]const u8{ LOAD_U8, LOAD_S8, LOAD_U16, LOAD_S16, STORE, GET_DIR, GET_VAL, ADD, SUB, MPL, DIV };

pub const TWO_OPERAND_INSTRUCTIONS = [_][]const u8{ PIX_ON_F, PIX_OFF_F, PIX_ON_M, PIX_OFF_M };
pub const ONE_OPERAND_INSTRUCTIONS = [_][]const u8{ U8U, I8U, U16U, I16U, U8R, I8R, U16R, I16R, ADD, SUB, MPL, DIV, CALL, JMP, JMP_P, JMP_N, JMP_Z, JMP_NZ, RET, SP_ADD, SP_SUB, LOAD_C, LOAD_S16, LOAD_S8, LOAD_U16, LOAD_U8, GET_DIR, GET_VAL, STORE, WAIT, RECV };
pub const ZERO_OPERAND_INSTRUCTIONS = [_][]const u8{ PRIORITY_ON, PRIORITY_OFF, CLEAR_W, CLEAR_B, SHOW, END };
