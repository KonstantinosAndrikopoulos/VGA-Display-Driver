module vsync(
    clk,
    reset,
    vPixel,
    display_active,
    vsync,
    front_porch_count
);

input clk, reset;
output display_active;
output vsync;
output [6:0] vPixel;
output [3:0] front_porch_count;

reg display_active;
reg vsync;
reg [6:0] vPixel;

reg [2:0] currentState, nextState;

reg [21:0] state_counter;
reg reset_state_counter;

reg [14:0] pixel_counter;
reg pixel_enable;

reg [3:0] front_porch_count;

parameter OFF=3'b000,
          VSYNC_PULSE_WIDTH=3'b001,
          BACK_PORCH=3'b010,
          ACTIVE_VIDEO=3'b011,
          FRONT_PORCH=3'b100;

parameter VSYNC_PULSE_WIDTH_TIME=6400,
          BACK_PORCH_TIME=92800,
          ACTIVE_VIDEO_TIME=1536000,
          FRONT_PORCH_TIME=32000;

/*always for the state counter*/
always@(posedge clk or posedge reset)
    begin
        if(reset)
            state_counter<=21'b0;
        else if(reset_state_counter)
            state_counter<=21'b0;
        else
            state_counter=state_counter+1;
    end

always@(posedge clk or posedge reset)
    begin
        if(reset)
            pixel_counter<=4'b0000;
         else begin
            
         
        if(pixel_enable) begin
            pixel_counter<=pixel_counter+1;
            if(pixel_counter==15999) begin
                vPixel<=vPixel+1;
                pixel_counter<=4'b0000;
            end
        end
        else begin
            pixel_counter<=4'b0000;
            vPixel<=1'b0;
        end
        end

    end

/*always that changes the state*/
always@(posedge clk or posedge reset)
    begin
        if(reset)
            currentState<=OFF;
        else
            currentState<=nextState;
    end

always@(currentState or state_counter)
    begin
        nextState=currentState;
        display_active=1'b0;
        vsync=1'b0;
        reset_state_counter=1'b0;
        pixel_enable=1'b0;

        case(currentState)
            OFF: begin
                display_active=1'b0;
                vsync=1'b0;
                reset_state_counter=1'b1;
                pixel_enable=1'b0;
                front_porch_count=4'b0000;

                nextState=VSYNC_PULSE_WIDTH;
            end

            VSYNC_PULSE_WIDTH: begin
                display_active=1'b0;
                vsync=1'b0;
                reset_state_counter=1'b0;
                pixel_enable=1'b0;
                front_porch_count=4'b0000;

                if(state_counter==VSYNC_PULSE_WIDTH-1)
                    nextState=BACK_PORCH;
                else
                    nextState=VSYNC_PULSE_WIDTH;
            end

            BACK_PORCH: begin
                display_active=1'b0;
                vsync=1'b1;
                reset_state_counter=1'b0;
                pixel_enable=1'b0;

                if(state_counter==VSYNC_PULSE_WIDTH_TIME+BACK_PORCH_TIME-1)
                    nextState=ACTIVE_VIDEO;
                else
                    nextState=BACK_PORCH;
            end

            ACTIVE_VIDEO: begin
                display_active=1'b1;
                vsync=1'b1;
                reset_state_counter=1'b0;
                pixel_enable=1'b1;

                if(state_counter==VSYNC_PULSE_WIDTH_TIME+BACK_PORCH_TIME+ACTIVE_VIDEO_TIME-1)
                    nextState=FRONT_PORCH;
                else
                    nextState=ACTIVE_VIDEO;
            end

            FRONT_PORCH: begin
                display_active=1'b0;
                vsync=1'b1;
                reset_state_counter=1'b0;
                pixel_enable=1'b0;

                if(state_counter==VSYNC_PULSE_WIDTH_TIME+BACK_PORCH_TIME+ACTIVE_VIDEO_TIME+FRONT_PORCH_TIME-1) begin
                    nextState=VSYNC_PULSE_WIDTH;
                    reset_state_counter=1'b1;
                    front_porch_count=front_porch_count+1;
                end
                else
                    nextState=FRONT_PORCH;
            end
        endcase
    end
endmodule