const i8_middle = 127;
const i16_middle = 32768;

// Test
const DataType = enum {
    U8,
    I8,
    U16,
    I16,
};

const Const = struct {
    id: []u8,
    datatype: DataType,
    value: u16,
    reserve: bool,
};

const Var = struct {
    id: []u8,
    datatype: DataType,
    reserve: bool,
};

pub fn semantic_analisys() !void {}
