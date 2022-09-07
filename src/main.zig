const std = @import("std");
const plat = @import("platform.zig");
const emu = @import("c8emu.zig");
const time = std.time;
const warn = std.debug.warn;
const allocator = std.debug.global_allocator;

const print = std.debug.print;
const expect = std.testing.expect;

test "overflow" {
    var c1: u8 = 248;
    var c2: u8 = 9;
    var res: u8 = 0;
    _ = @addWithOverflow(u8, c1,c2, &res);
    try expect(res == 1);
}




const rom_filename = "Maze.ch8";

pub fn main() !void {
    const args = std.os.argv;
    var j: u32 = 0;
    if (args.len > 1){
        
        while (std.os.argv[1][j] != 0)j+=1;
    }



    try plat.init();
    defer plat.deinit();

    var c8: emu.Chip8State = undefined;
    emu.initC8(&c8);
    
    var rom_bytes_read: u32 = try emu.loadRomData(if (std.os.argv.len == 1)rom_filename else (std.os.argv[1])[0..j], @ptrCast([*]u8,&c8.memory));
    _ = rom_bytes_read;

    var start_timer: i64 = time.milliTimestamp();
    var end_timer: i64 = time.milliTimestamp();
    while (plat.update(&c8)){
        end_timer = time.milliTimestamp();
        if(end_timer - start_timer < 2)
            plat.delay(1);
        start_timer = time.milliTimestamp();    
        //emu.printC8State(&c8);
        //emu.disasmChip8Op(&c8.memory, c8.PC);
        //emu.printC8Screen(&c8);
        emu.emuC8Op(&c8);
        //print("\n", .{});
        

    }
}
