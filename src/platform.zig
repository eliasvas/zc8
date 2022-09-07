const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const time = @import("time");
const emu = @import("c8emu.zig");


const W = 640;
const H = 320;

var screen: *c.SDL_Window =undefined;
var surface: *c.SDL_Surface =undefined;
var renderer: *c.SDL_Renderer=undefined;
var fbo_tex: ?*c.SDL_Texture =undefined;
var wav_spec: c.SDL_AudioSpec = undefined;
var wav_length: u32 = undefined; // length of our sample
var wav_buffer: [*c]u8 = undefined;
var audio_len: u32 = undefined; // length of our sample
var audio_pos: [*c]u8 = undefined;


var audio_data: [1000]u8 = undefined;
fn c8_audio_cb(userdata: ?*anyopaque,stream: [*c]u8,len: c_int) callconv(.C) void{
//fn c8_audio_cb(userdata: [*c]u8, stream: [*c]u32, len: u32) void {

    _ = userdata;
    if (audio_len ==0){print("No audio to play\n",.{});return;}
    var len2: u32= if (len > audio_len) audio_len else @intCast(u32,len);
    c.SDL_MixAudio(stream, audio_pos, len2, c.SDL_MIX_MAXVOLUME);// mix from one buffer into another
    audio_pos += len2;
    audio_len -= len2;
}

pub fn init() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    

    screen = c.SDL_CreateWindow("CHIP-8", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, W, H, c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE) orelse
        {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    

    renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    //surface = c.SDL_CreateRGBSurfaceWithFormat(c.SDL_SWSURFACE,W, H, 1, c.SDL_PIXELFORMAT_INDEX1MSB);
    //var colors: [8]u8= [_]u8{0, 0, 0, 255,255, 255, 255, 255};
    //_ = c.SDL_SetPaletteColors(surface.format.*.palette, @ptrCast([*c]c.struct_SDL_Color,&colors), 0, 2);

    // Create texture that stores frame buffer
    fbo_tex = c.SDL_CreateTexture(renderer,
            c.SDL_PIXELFORMAT_RGBA32,
            c.SDL_TEXTUREACCESS_STREAMING,
            64, 32);
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);


    //const wavname = "c8.wav";
    //if( c.SDL_LoadWAV(wavname, &wav_spec, @ptrCast([*c][*c]u8,&wav_buffer), &wav_length) == 0 ){c.SDL_Log("Unable to create audio: %s", c.SDL_GetError());}
    //wav_spec.callback = c8_audio_cb;
    //wav_spec.userdata = null;
    // set our global static variables
    //audio_pos = wav_buffer; // copy sound buffer
    //audio_len = wav_length; // copy file length

    //if ( c.SDL_OpenAudio(&wav_spec, null) < 0 ){
    //    c.SDL_Log("Unable to open audio: %s", c.SDL_GetError());
    //}
    

}

var render_data: [64*32*4]u8=undefined;

var color_index: u2 = 0; 
fn setPixel(x: u32, y: u32)void{
    render_data[(x + y * 64)*4 + @intCast(u32, color_index)] = 0xFF;
}

pub fn update(state: *emu.Chip8State) bool {
    
    for (render_data) |*d|{
        d.* = 0;
    }    
    var start_addr: [*]u8 = @ptrCast([*]u8,&state.screen);

    var i: u32 = 0;
    var y: u32 = 0;
    var pixels_written: u32 = 0;
    while (i < 64*32/8): (i += 1){
        var byte: u8 = start_addr[i];
        var mask: u8 = 8;
        while (mask > 0):(mask-=1){
            var x: u32 = pixels_written % 64;
            if ((byte >> @intCast(u3,mask-1)) & 0x1 > 0) setPixel(x,y);
            pixels_written+=1;
            if (pixels_written % 64 == 0)y+=1;
            
        }
    }

    
    _ = c.SDL_UpdateTexture(fbo_tex, 0, &render_data, 64 * 4);
    // Clear screen and render
    _ = c.SDL_RenderClear(renderer);
    _ = c.SDL_RenderCopy(renderer, fbo_tex, 0, 0);
    _ = c.SDL_RenderPresent(renderer);
    
    
    
    var e: c.SDL_Event= undefined;
    //print("{}{}{}{}{}{}{}{}{}{}\n",.{state.ks[0],
    //state.ks[1],state.ks[2],state.ks[3],state.ks[4],state.ks[5],state.ks[6],state.ks[7],state.ks[8],state.ks[9]});
    const key_maps = [_]u8 {'1','2','3','4','q','w','e','r','a','s','d','f','z','x','c'};
    while (c.SDL_PollEvent(&e) > 0){
        if (e.type == c.SDL_QUIT){return false;}
        if (e.type == c.SDL_KEYDOWN or e.type == c.SDL_KEYUP){
            for (key_maps) |km,index|{
                if (e.key.keysym.sym == km){
                    state.ks[index] = if (e.type == c.SDL_KEYDOWN) 1 else 0;
                }
            } 
            if  (e.key.keysym.sym == ' ' and e.type == c.SDL_KEYUP){
                color_index = color_index+%1;
                if (color_index == 3)color_index = color_index +% 1;
            } 
        }
    }
    if (state.sound > 0)state.audio_this_frame = true;

    if (state.delay > 0)state.delay-=1;
    if (state.sound > 0)state.sound-=1;

    //print("{}\n", .{state.sound});
    //if (state.sound > 0)c.SDL_PauseAudio(0) else c.SDL_PauseAudio(1);
    
    //c.SDL_Delay(1);
    return true;
}

pub fn delay(milli: u32) void {
    c.SDL_Delay(milli);
}

pub fn deinit() void {
    defer c.SDL_Quit();
    defer c.SDL_DestroyWindow(screen);
    defer c.SDL_DestroyRenderer(renderer);
}

