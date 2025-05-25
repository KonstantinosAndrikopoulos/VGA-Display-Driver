`include "hsync.v"
`include "vsync.v"
`include "sychronizer.v"
`include "debounce.v"
`include "memory_management_fancy.v"

module vgaVideoController(reset, clk, VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC);

input reset, clk;
output VGA_RED, VGA_GREEN, VGA_BLUE;
output VGA_HSYNC, VGA_VSYNC;

wire [2:0] rgb;
wire [13:0] addressVram;

wire hsync_display_active, vsync_display_active;
wire [6:0] HPIXEL, VPIXEL;

wire vga_display_active;

wire synced_reset, debounced_reset;

wire [3:0] front_porch_count;

//assign vram address
assign addressVram={VPIXEL, HPIXEL};

//check that both hsync and vsync are active
assign vga_display_active=hsync_display_active&vsync_display_active;

//assign colours
//if vsync and hsync are not active show black(rgb=000)
assign VGA_RED=(vga_display_active) ? rgb[2] : 1'b0;
assign VGA_GREEN=(vga_display_active) ? rgb[1] : 1'b0;
assign VGA_BLUE=(vga_display_active) ? rgb[0] : 1'b0;

//reset sychronizer
sychronizer sychronizer_reset(
    .clk(clk),
    .sync_in(reset),
    .sync_out(synced_reset)
);

//reset debouncer
debounce debounce_reset(
    .clock(clk),
    .reset_in(synced_reset),
    .reset_out(debounced_reset)
);


memory_management VRAM_management(
    .clk(clk),
    .reset(debounced_reset),
    .read_address(addressVram),
    .rgb(rgb),
    .front_porch_count(front_porch_count)
);

//instantiate hsync module
hsync hsync_inst(
    .clk(clk),
    .reset(debounced_reset),
    .hPixel(HPIXEL),
    .display_active(hsync_display_active),
    .hsync(VGA_HSYNC)
);

//instantiate vsync module
vsync vsync_inst(
    .clk(clk),
    .reset(debounced_reset),
    .vPixel(VPIXEL),
    .display_active(vsync_display_active),
    .vsync(VGA_VSYNC),
    .front_porch_count(front_porch_count)
);

endmodule