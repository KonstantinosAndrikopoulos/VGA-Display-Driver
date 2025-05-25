module write_vram(clk, reset, write_address, data_to_write);
input clk, reset;
input [13:0] write_address;
input [15:0] data_to_write;

reg currentState, nextState;

parameter ENABLE_WRITE=1'b0,
            WRITE_FRAME=1'b1;

always @(posedge clk or posedge reset)
    begin
        if(reset)
            currentState<=OFF;
        else
            currentState<=nextState; 
    end

always@(currentState)
    begin
        case(currentState)
            ENABLE_WRITE: begin
                enable_write=1'b1;
            end

            WRITE_FRAME: begin
                enable_write=1'b1;


            end



        endcase
    end



endmodule