`include "vram.v"
`include "memory_rgb.v"

module memory_management(
    clk,
    reset,
    read_address,
    rgb,
    front_porch_count
);

input clk, reset;
input [13:0] read_address;
input [3:0] front_porch_count;
output [2:0] rgb;

reg [1:0] currentState, nextState;

wire [2:0] rgb_vram1, rgb_vram2;

reg select_ram;

reg VRAM1_read_enable, VRAM2_read_enable;
reg [3:0] VRAM1_write_enable, VRAM2_write_enable;
reg frame_done;

reg [23:0] clock_counter;

reg [31:0] R_write_data, G_write_data, B_write_data;

wire [15:0] R_write_data_low, R_write_data_upper;
wire [15:0] G_write_data_low, G_write_data_upper;
wire [15:0] B_write_data_low, B_write_data_upper;

reg [13:0] write_address;

reg prev_write_enable_VRAM1, prev_write_enable_VRAM2;

reg [3:0] frame_counter;

wire [255:0] ROM_RED_DATA, ROM_GREEN_DATA, ROM_BLUE_DATA;
reg [3:0] read_rom_address;
reg [2:0] rom_row;

reg [16:0] max_address;

wire read_from_rom;

parameter MAX_FRAMES=2,
          CLOCK_COUNTER_FRAME_RATE=16667200,
          FRONT_PORCH_COUNTS=1;

parameter OFF=2'b00,
          VRAM1_READING_VRAM2_WRITING=2'b01,
          VRAM1_WRITING_VRAM2_READING=2'b10;

always@(posedge clk or posedge reset)
    begin
        if(reset)
            currentState<=OFF;
        else
            currentState<=nextState;
    end

always @(posedge clk or posedge reset)
begin
    if (reset)
        clock_counter <= 24'b0;  // Reset the counter on reset
    else if (clock_counter == (CLOCK_COUNTER_FRAME_RATE-1))
        clock_counter <= 24'b0;  // Reset the counter when it reaches the threshold
    else
        clock_counter <= clock_counter + 1;  // Increment the counter otherwise
end

always @(posedge clk or posedge reset)
begin
    if (reset)
        frame_counter <= 0;  // Reset the counter on reset
    else if (frame_done)
        frame_counter<=frame_counter+1;
    else if(frame_counter==MAX_FRAMES)
        frame_counter<=0;
end

// Always block to update frame_done based on clock_counter
always @(posedge clk or posedge reset)
begin
    if (reset)
        frame_done <= 1'b0;  // Reset frame_done on reset
    else if (front_porch_count==FRONT_PORCH_COUNTS)
        frame_done <= 1'b1;  // Set frame_done when the counter reaches the threshold
    else
        frame_done <= 1'b0;  // Reset frame_done if not yet reached the threshold
end

always@(currentState or frame_done)
    begin
        case(currentState)
        OFF: begin
            VRAM1_read_enable=1'b0;
            VRAM1_write_enable=4'b0;
            VRAM2_read_enable=1'b0;
            VRAM2_write_enable=4'b0;

            nextState=VRAM1_READING_VRAM2_WRITING;
        end

        VRAM1_READING_VRAM2_WRITING: begin
            VRAM1_read_enable=1'b1;
            VRAM1_write_enable=4'b0;
            VRAM2_read_enable=1'b0;
            VRAM2_write_enable=4'b1111;

            if(frame_done)
                nextState=VRAM1_WRITING_VRAM2_READING;
            else
                nextState=VRAM1_READING_VRAM2_WRITING;
        end

        VRAM1_WRITING_VRAM2_READING: begin
            VRAM1_read_enable=1'b0;
            VRAM1_write_enable=4'b1111;
            VRAM2_read_enable=1'b1;
            VRAM2_write_enable=4'b0;

            if(frame_done)
                nextState=VRAM1_READING_VRAM2_WRITING;
            else
                nextState=VRAM1_WRITING_VRAM2_READING;
        end
        endcase
    end

always@(posedge clk or posedge reset)
    begin
        if(reset)
            write_address<=0;
        else if(!prev_write_enable_VRAM1 && VRAM1_write_enable)
            write_address<=0;
        else if(!prev_write_enable_VRAM2 && VRAM2_write_enable)
            write_address<=0;
        else if((write_address!=4096)&&(rom_row<7))
            write_address<=write_address + 32;
            
        prev_write_enable_VRAM1=VRAM1_write_enable;
        prev_write_enable_VRAM2=VRAM2_write_enable;
    end

// rgb_memory memory(.address(write_address), .frame_select(frame_counter), .data_red(R_write_data), .data_green(G_write_data), .data_blue(B_write_data));
// ROM_RED memory_red(.a(read_rom_address), .spo(ROM_RED_DATA));
// ROM_GREEN memory_green(.a(read_rom_address), .spo(ROM_GREEN_DATA));
// ROM_BLUE memory_blue(.a(read_rom_address), .spo(ROM_BLUE_DATA));

memory_rgb ROM(.address(read_rom_address), .output_red(ROM_RED_DATA), .output_green(ROM_GREEN_DATA), .output_blue(ROM_BLUE_DATA), .frame_select(frame_counter));

assign read_from_rom = (write_address!=4096) ? 1'b1 : 1'b0;

always@(posedge clk or posedge reset)
    begin
        
        if(reset) begin
            read_rom_address<=0;
            rom_row<=0;
            // max_address<=48;
        end

        if(read_from_rom)
            begin
                if((rom_row==7)&&(read_rom_address!=16))
                    begin
                        read_rom_address<=read_rom_address+1;
                    end
                else if(rom_row==7)
                        rom_row<=0;
                else
                    rom_row<=rom_row+1;


                if(write_address==4095)
                    begin
                        rom_row<=0;
                        read_rom_address<=0;
                    end
            end



        case(rom_row)
            0: begin
                R_write_data<=ROM_RED_DATA[31:0];
                G_write_data<=ROM_GREEN_DATA[31:0];
                B_write_data<=ROM_BLUE_DATA[31:0];
            end

            1: begin
                R_write_data<=ROM_RED_DATA[63:32];
                G_write_data<=ROM_GREEN_DATA[63:32];
                B_write_data<=ROM_BLUE_DATA[63:32];
            end

            2: begin
                R_write_data<=ROM_RED_DATA[95:64];
                G_write_data<=ROM_GREEN_DATA[95:64];
                B_write_data<=ROM_BLUE_DATA[95:64];
            end

            3: begin
                R_write_data<=ROM_RED_DATA[127:96];
                G_write_data<=ROM_GREEN_DATA[127:96];
                B_write_data<=ROM_BLUE_DATA[127:96];
            end

            4: begin
                R_write_data<=ROM_RED_DATA[159:128];
                G_write_data<=ROM_GREEN_DATA[159:128];
                B_write_data<=ROM_BLUE_DATA[159:128];
            end

            5: begin
                R_write_data<=ROM_RED_DATA[191:160];
                G_write_data<=ROM_GREEN_DATA[191:160];
                B_write_data<=ROM_BLUE_DATA[191:160];
            end

            6: begin
                R_write_data<=ROM_RED_DATA[223:192];
                G_write_data<=ROM_GREEN_DATA[223:192];
                B_write_data<=ROM_BLUE_DATA[223:192];
            end

            7: begin
                R_write_data<=ROM_RED_DATA[255:224];
                G_write_data<=ROM_GREEN_DATA[255:224];
                B_write_data<=ROM_BLUE_DATA[255:224];
            end
        endcase


    end

assign R_write_data_upper=R_write_data[31:16];
assign R_write_data_low=R_write_data[15:0];
assign G_write_data_upper=G_write_data[31:16];
assign G_write_data_low=G_write_data[15:0];
assign B_write_data_upper=B_write_data[31:16];
assign B_write_data_low=B_write_data[15:0];

assign rgb = (VRAM1_read_enable) ? rgb_vram1 : 
             (VRAM2_read_enable) ? rgb_vram2 : 3'b000; // Default value if no read enable

VRAM VRAM1(
    .clk(clk),
    .reset(reset),
    .read_address(read_address),
    .read_enable(VRAM1_read_enable),
    .rgb(rgb_vram1),
    .write_enable(VRAM1_write_enable),
    .R_write_data_low(R_write_data_low),
    .R_write_data_upper(R_write_data_upper),
    .G_write_data_low(G_write_data_low),
    .G_write_data_upper(G_write_data_upper),
    .B_write_data_low(B_write_data_low),
    .B_write_data_upper(B_write_data_upper),
    .write_address(write_address)
);

VRAM VRAM2(
    .clk(clk),
    .reset(reset),
    .read_address(read_address),
    .read_enable(VRAM2_read_enable),
    .rgb(rgb_vram2),
    .write_enable(VRAM2_write_enable),
    .R_write_data_low(R_write_data_low),
    .R_write_data_upper(R_write_data_upper),
    .G_write_data_low(G_write_data_low),
    .G_write_data_upper(G_write_data_upper),
    .B_write_data_low(B_write_data_low),
    .B_write_data_upper(B_write_data_upper),
    .write_address(write_address)
);

endmodule