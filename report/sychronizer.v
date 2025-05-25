module sychronizer(clk, sync_in, sync_out);

input clk;
input sync_in;
output sync_out;

reg sync_out;
reg mid_ff;

always@(posedge clk)
    begin
        mid_ff<=sync_in;
        sync_out<=mid_ff;
    end 
    
endmodule