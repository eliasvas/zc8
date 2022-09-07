const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const FONT_BASE = 0; //base address of font glyphs in CHIP8 memory
const FONT_SIZE = 5*16;


const fnt = [_]u8{
//0
    0b01100000,
    0b10010000,
    0b10010000,
    0b10010000,
    0b01100000,

//1
    0b01100000,
    0b00100000,
    0b00100000,
    0b00100000,
    0b01110000,

//2
    0b11100000,
    0b00010000,
    0b00110000,
    0b01100000,
    0b11110000,
//3
    0b11100000,
    0b00010000,
    0b01100000,
    0b00010000,
    0b11100000,

    0b10100000,
    0b10100000,
    0b11100000,
    0b00100000,
    0b00100000,

    0b11110000,
    0b10000000,
    0b11110000,
    0b00010000,
    0b11110000,

    0b10000000,
    0b10000000,
    0b11110000,
    0b10010000,
    0b11110000,

    0b11110000,
    0b00010000,
    0b00100000,
    0b00100000,
    0b00100000,

    0b11110000,
    0b10010000,
    0b11110000,
    0b10010000,
    0b11110000,

    0b11110000,
    0b10010000,
    0b11110000,
    0b00010000,
    0b00010000,

    0b01100000,
    0b10010000,
    0b11110000,
    0b10010000,
    0b10010000,

    0b10000000,
    0b10000000,
    0b11110000,
    0b10010000,
    0b11110000,

    0b11110000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b11110000,

    0b11100000,
    0b10010000,
    0b10010000,
    0b10010000,
    0b11100000,

    0b11110000,
    0b10000000,
    0b11100000,
    0b10000000,
    0b11110000,

    0b11110000,
    0b10000000,
    0b11100000,
    0b10000000,
    0b10000000,
};


pub fn loadRomData(filename: [] const u8, dst: [*]u8) !u32 {
    
    const file = try std.fs.cwd().openFile(filename, .{});
    var bytes_read: usize= try file.readAll(dst[0x200..4096]);
    _ = file;
    print("Rom loaded: {s}, {} bytes long.\n", .{filename, bytes_read});
    //TODO close file
    return @intCast(u32,bytes_read);
}

pub fn disasmChip8Op(codebuf: [*]u8, pc: u32) void {
    var code: [*]u8 = @ptrCast([*]u8,&codebuf[pc]);

    var first_nib: u8= (code[0] >> 4);
    _ = first_nib;
    print("{x}: {x} {x} ", .{pc, code[0], code[1]});
    switch (first_nib){
        0x00 => {
            switch(code[1]){
                0xe0 => {print("| CLS",.{});},
                0xee => {print("| RTS",.{});},
                else => {print("| Unknown 0 Op", .{});},

            }
        },
        0x1 => {print("| JUMP ${x} {x}", .{code[0] & 0xf, code[1]});},
        0x2 => {print("| CALL ${x}{x}", .{code[0] & 0xf, code[1]});},
        0x3 => {print("| SKIP.EQ V{x},#${x}", .{code[0] & 0xf, code[1]});},
        0x4 => {print("| SKIP.NE V{x},#${x}", .{code[0] & 0xf, code[1]});},
        0x5 => {print("| SKIP.EQ V{x},V{x}", .{code[0] & 0xf, code[1] >> 4});},
        0x6 => {print("| MVI V{x},#${x}", .{code[0] & 0xf, code[1]});},
        0x7 => {print("| ADI V{x},#${x}", .{code[0] & 0xf, code[1]});},
        0x8 => {
            var last_nib: u8 = code[1]&0xf;
            switch(last_nib) {
                0x0 => print("| MOV. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                0x1 => print("| OR. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                0x2 => print("| AND. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                0x3 => print("| XOR. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                0x4 => print("| ADD. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                0x5 => print("| SUB. V{x},V{x},V{x}", .{code[0]&0xf,code[0]&0xf, code[1]>>4}),
                0x6 => print("| SHR. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                0x7 => print("| SUB. V{x},V{x},V{x}", .{code[0]&0xf,code[1]>>4, code[1]>>4}),
                0xe => print("| SHL. V{x},V{x}", .{code[0]&0xf, code[1]>>4}),
                else => print("| Unknown 8 Op", .{}),
            }
        },
        0x9 => {print("| SKIP.NE V{x},V{x}", .{code[0] & 0xf, code[1] >> 4});},
        0xa => {print("| MVI I,#${x}{x}", .{code[0] & 0xf, code[1]});},
        0xb => {print("| JUMP ${x}{x}(V0)", .{code[0] & 0xf, code[1]});},
        0xc => {print("| RNDMSK V{x},#${x}", .{code[0] & 0xf, code[1]});},
        0xd => {print("| SPRITE V{x},V{x},#${x}", .{code[0] & 0xf, code[1]>>4,code[1]&0xf});},
        0xe => {
            switch(code[1]) {
                0x9E => print("| SKIPKEY.Y V{x}", .{code[0]&0xf}),
                0xA1 => print("| SKIPKEY.N V{x}", .{code[0]&0xf}),
                else => print("| Unknown E Op", .{}),
            }
        },
        0xf => {
            switch(code[1]) {
                0x07 => print("| MOV V{x},DELAY", .{code[0] & 0xf}),
                0x0a => print("| KEY V{x},DELAY", .{code[0] & 0xf}),
                0x15 => print("| MOV DELAY,V{x}", .{code[0] & 0xf}),
                0x18 => print("| MOV SOUND,V{x}", .{code[0] & 0xf}),
                0x1e => print("| ADI I,V{x}", .{code[0] & 0xf}),
                0x29 => print("| SPRITECHAR I,V{x}", .{code[0] & 0xf}),
                0x33 => {print("| MOVBCD (I),V{x}", .{code[0] & 0xf});},
                0x55 => print("| MOVM (I),V0-V{x}", .{code[0] & 0xf}),
                0x65 => print("| MOVM V0-V{x},(I)", .{code[0] & 0xf}),
                else => print("| Unknown F Op", .{}),
            }
        },
        else => {print("| opcode not yet handled.", .{});},
    }
    print("\n", .{});
}

const REG_NUM = 16;

pub const Chip8State = struct {
    V: [REG_NUM]u8,
    I:   u16,
    SP:   u16,
    PC:   u16,
    delay: u8,
    sound: u8,
    memory: [4096]u8,
    screen: [64 * 32]u8, //memory[0xF00..]
    halt: bool,
    ks: [REG_NUM]u8,
    sks: [REG_NUM]u8,
    waiting_for_key: u8,
    audio_this_frame: bool,
};

pub fn printC8Screen(state: *Chip8State) void
{
    var start_addr: [*]u8 = @ptrCast([*]u8,&state.screen);
    var i: u32 = 0;
    var pixels_written: u32 = 0;
    while (i < 64*32/8): (i += 1){
        var byte: u8 = start_addr[i];
        var mask: u8 = 8;
        while (mask > 0):(mask-=1){
            pixels_written+=1;
            if ((byte >> @intCast(u3,mask-1)) & 0x1 > 0) print("0",.{}) else print("+",.{});
            if (pixels_written % 64 == 0)print("\n", .{});
        }
    }
}

pub fn printC8State(state: *Chip8State) void{
    var i: u32 = 0;
    while (i < 3): (i+=1){
        print("V{}= {}|", .{i, state.V[i]});
    }
    print("PC= {}|",.{state.PC});
    print("SP= {}|",.{state.SP});
    print("I={}\n",.{state.I});
}


fn rnd() !u8 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    return rand.int(u8);
}

pub fn initC8(state: *Chip8State) void {
    //state.screen = @ptrCast([*]u8, &state.memory[0xf00]);
    state.PC = 0x200;
    state.SP = 0xfa0;
    var i: u32 = 0;
    while (i < 16): (i += 1){
        state.V[i] = 0;
        state.ks[i] = 0;
        state.sks[i] = 0;
    }
    for (state.memory) |*byte|{
        byte.* = 0;
    }
    i = 0;
    while (i < 64 * 32/8): (i+=1){
        state.screen[i] = 0;
    }
    state.waiting_for_key = 0;
    state.delay = 0;
    i = 0;
    while (i < FONT_SIZE): (i+=1){
        state.memory[i] = fnt[i];
    }
    state.audio_this_frame = false;
    //std.mem.zeroInit(*[REG_NUM]u8, &state.ks);
}

fn noOp(state: *Chip8State) void {
    _ = state;
}

fn Op0(state: *Chip8State, code: [*]u8) void {
    switch(code[1]) {
        0xE0 => { //CLS
            //std.mem.set(u8, state.screen[0..256], 0);
            var i: u32 = 0;
            //print("CLS\n", .{});
            while (i < 64 *32/8): (i +=1){
                state.screen[i] = 0;
            }
            state.PC += 2;
        },
        0xEE => {
            var target: u16= (@intCast(u16,state.memory[state.SP]) << 8) | state.memory[state.SP + 1];
            
            target = target & 0xFFFF;
            state.SP +=2;
            state.PC = target;
            //print("0xEE executes!\n", .{});
        },
        else => {},
    }
}

fn Op1(state: *Chip8State, code: [*]u8) void {
    var target: u16= (@intCast(u16, code[0] & 0xf) << 8) | code[1];
    
    if (target == state.PC){
        print("Infinite loop detected!, halting.\n", .{});
        state.halt = true;
        //std.os.exit(0);
    }
    state.PC = target;
}

fn Op2(state: *Chip8State, code: [*]u8) void {
    state.SP -= 2; //advance stack pointer by two
    state.memory[state.SP] = @intCast(u8,@intCast(u16,((state.PC+2) & 0xFF00)) >> 8); //put RT address first byte
    state.memory[state.SP+1] = @intCast(u8,(state.PC + 2) & 0xFF); //and second
    state.PC = (@intCast(u16, code[0] & 0xf) << 8) | code[1]; //change the program counter to jump address
}

fn Op3(state: *Chip8State, code: [*]u8) void {
    if (state.V[code[0] & 0xf] == code[1]){
        state.PC += 2;
    }
    state.PC +=2;
}

fn Op4(state: *Chip8State, code: [*]u8) void {
    if (state.V[code[0] & 0xf] != code[1]){
        state.PC += 2;
    }
    state.PC +=2;
}

fn Op5(state: *Chip8State, code: [*]u8) void {
    var reg1: u8= code[0] & 0xf;
    var reg2: u8= (code[1] & 0xf0) >> 4;

    if (state.V[reg1] == state.V[reg2]){
        state.PC += 2;
    }
    state.PC +=2;
}

fn Op6(state: *Chip8State, code: [*]u8) void {
    var reg: u8= code[0] & 0xf;
    state.V[reg] = code[1];
    state.PC +=2;
}


fn Op7(state: *Chip8State, code: [*]u8) void {
    var reg: u16= code[0] & 0xf;
    //var res: u16 = (@intCast(u16,state.V[reg]) + code[1])&0xFF;
    //state.V[reg] = state.V[reg] +% code[1];
    var res: u8 = 0;
    _ = @addWithOverflow(u8, state.V[reg], code[1], &res);
    state.V[reg] = @intCast(u8,res&0xff);
    state.PC +=2;
}

fn Op8(state: *Chip8State, code: [*]u8) void {
    var last_nib: u8 = code[1] & 0xf;
    
    var X: u8 = code[0]&0xf;
    var Y: u8 = (code[1] & 0xf0) >> 4;
    switch(last_nib){    
        0x0 => {
            state.V[X] = state.V[Y]; 
        },
        0x1 => {
            state.V[X] = state.V[X] | state.V[Y]; 
        },
        0x2 => {
            state.V[X] = state.V[X] & state.V[Y]; 
        },
        0x3 => {
            state.V[X] = state.V[X] ^ state.V[Y]; 
        },
        0x4 => {
            var res: u32= @intCast(u32,state.V[X]) + @intCast(u32,state.V[Y]);
            if ((res & 0xFF00) > 0){ //overflow happened
                state.V[0xf] = 1;
            }else{
                state.V[0xf] = 0;
            }
            state.V[X] = @intCast(u8,res & 0xff);
        },
        0x5 => {
            var borrow: u8= if (state.V[X] > state.V[Y])1 else 0;
            _ = @subWithOverflow(u8, state.V[X], state.V[Y], &state.V[X]);
            //state.V[X] = state.V[X] - state.V[Y];
            state.V[0xf] = borrow;
        },
        0x6 => {
            state.V[0xf] = state.V[X] & 0x1;
            state.V[X] = state.V[X] >> 1;
        },
        0x7 => {
            var borrow: u8= if (state.V[Y] > state.V[X])1 else 0;
            //@subWithOverflow(u8, state.V[Y], state.V[X], &state.V[X]);
            state.V[X] = state.V[Y] - state.V[X];
            state.V[0xf] = borrow;
        },
        0xe => {
            state.V[X] = state.V[X] << 1;
            state.V[0xf] = if (0x80 == (state.V[X] & 0x80)) 1 else 0;
        },
        else => {},
    }
    state.PC +=2;
}

fn Op9(state: *Chip8State, code: [*]u8) void {
    var reg1: u8= code[0] & 0xf;
    var reg2: u8= (code[1] & 0xf0) >> 4;
    if (state.V[reg1] != state.V[reg2]){
        state.PC+=2;
    }
    state.PC +=2;
}

fn OpA(state: *Chip8State, code: [*]u8) void {
    var addr: u16 = (@intCast(u16,(code[0] & 0xf)) << 8) | code[1];
    state.I = addr;
    state.PC += 2;
}

fn OpB(state: *Chip8State, code: [*]u8) void {
    var addr: u16 = (@intCast(u16,(code[0] & 0xf)) << 8) | code[1];
    state.PC = addr + @intCast(u16, state.V[0]);
}

fn OpC(state: *Chip8State, code: [*]u8) void {
    state.V[code[0] & 0xf] = rnd() catch 0 & code[1];
    state.PC +=2;
}

fn OpD(state: *Chip8State, code: [*]u8) void {
    //Draw a sprite at position VX, VY with N bytes of sprite data starting at the address stored in I
    //Set VF to 01 if any set pixels are changed to unset, and 00 otherwise (DXYN)
    var lines: u32 = code[1]&0xf;


    var x: u32 = state.V[code[0]&0xf];
    var y: u32 = state.V[@intCast(u16,(code[1]&0xf0)) >> 4];
    var i: u32 = 0;
    var j: u32 = 0;

    state.V[0xf] = 0;
    while (i < lines): (i+=1){
        var sprite: [*]u8 = @ptrCast([*]u8,&state.memory[state.I + i]);
        var spritebit: i32 = 7;
        j = x;
        while (j <(x + 8) and j < 64 ) : (j+=1) {
            var jover8: u32 = j / 8;
            var jmod8: u32 = j % 8;
            var srcbit: u8= (sprite[0] >> @intCast(u3,spritebit)) & 0x1;
            
            if (srcbit > 0){ // if the bit is drawn in the bitmap, 
                //check if its drawn on the screen and draw
                var destbyte_p: *u8 = &state.screen[(i + y)*(64/8) + jover8];
                var destbyte: u8 = destbyte_p.*;
                var destmask: u8 = @intCast(u8,(@intCast(u32,0x80) >> @intCast(u3,jmod8)));
                var destbit: u8 = destbyte & destmask;

                srcbit = srcbit << @intCast(u3,(7-jmod8));
                if (srcbit  & destbit > 0){
                    state.V[0xf] = 1;
                }

                destbit ^= srcbit;
                destbyte = (destbyte & ~destmask) | destbit;
                destbyte_p.* = destbyte;
            }

            spritebit-=1;
        }
    }
    
    //printC8Screen(state);
    state.PC += 2;
}

fn OpE(state: *Chip8State, code: [*]u8) void {
    switch(code[1]){
        0x9e => {
            if (state.ks[state.V[code[0] & 0xf]] != 0)
                state.PC +=2;
        },
        0xa1 => {
            if (state.ks[state.V[code[0] & 0xf]] == 0)
                state.PC +=2;
        },
        else => {},
    }
    state.PC += 2;
}

fn OpF(state: *Chip8State, code: [*]u8) void {
    switch(code[1]){
        0x07 => {
            state.V[code[0] & 0xf] = state.delay;
        },
        0x15 => {
            state.delay = state.V[code[0] & 0xf];
        },
        0x18 => {
            state.sound = state.V[code[0] & 0xf];
        },
        0x1E => {
            state.I += state.V[code[0] & 0xf];
        },
        0x29 => {
            //print("No Font support, exiting.\n",.{});
            //std.os.exit(0);
            state.I = FONT_BASE + (state.V[code[0]&0xf] * 5);
        },
        0x33 => {
            var value: u8 = state.V[code[0] & 0xf];
            var ones: u8 = value % 10;
            value = value / 10;
            var tens: u8 = value % 10;
            var hundreds = value / 10;
            state.memory[state.I] = hundreds;
            state.memory[state.I+1] = tens;
            state.memory[state.I+2] = ones;
        },
        0x55 => {
            var i: u32 = 0;
            while (i <= (code[0] & 0xf)): (i+=1){
                state.memory[state.I+i] = state.V[i];
            }
            state.I += (code[0] & 0xf) + 1;
        },
        0x65 => {
            var i: u32 = 0;
            while (i <= (code[0] & 0xf)): (i+=1){
                state.V[i] = state.memory[state.I+i];
            }
            state.I += (code[0] & 0xf) + 1;
        },
        0x0a => {
            if (state.waiting_for_key == 0){
                //memcpy
                for (state.sks) |*sks, i|{
                    sks.* = state.ks[i];
                }
                state.waiting_for_key = 1;
                return; //don't advance PC
            }
            else {
                var i: u32 = 0;
                while (i < 16): (i+=1){
                    if ((state.sks[i] == 0) and (state.ks[i] == 1)){
                        state.waiting_for_key = 0;
                        state.V[code[0] & 0xf] = @intCast(u8,i);
                        state.PC+=2;
                    }
                    state.sks[i] = state.ks[i];
                }
            }
        },
        else => {},
    }
    state.PC += 2;
}

//More info at: https://github.com/mattmikolay/chip-8/wiki/CHIP%E2%80%908-Instruction-Set
pub fn emuC8Op(state: *Chip8State) void {
    var op: [*]u8 = @ptrCast([*]u8,&state.memory[state.PC]);
    state.audio_this_frame = false;
    //disasmChip8Op(&state.memory, state.PC);
    //print("\n", .{});
    var highnib: u32= (op[0] & 0xf0) >> 4;
    switch (highnib)
    {
        0x00 => {Op0(state, op);},
        0x01 => {Op1(state, op);},
        0x02 => {Op2(state, op);},
        0x03 => {Op3(state, op);},
        0x04 => {Op4(state, op);},
        0x05 => {Op5(state, op);},
        0x06 => {Op6(state, op);},
        0x07 => {Op7(state, op);},
        0x08 => {Op8(state, op);},
        0x09 => {Op9(state, op);},
        0x0a => {OpA(state, op);},
        0x0b => {OpB(state, op);},
        0x0c => {OpC(state, op);},
        0x0d => {OpD(state, op);},
        0x0e => {OpE(state, op);},
        0x0f => {OpF(state, op);},
        else => {state.PC +=2;print("unimplemented Op\n", .{});std.os.exit(0);},
    }
}
