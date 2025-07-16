module Arraycheck (
    input clk,reset,
    input we,             // Write Enable, asserted on Valid data
    input line_select,    // 0 or 1, select which line
    input [7:0] din,      // Data input
    input [15:0] read_addr,
    output reg [31:0] dout // Data output
);
reg [15:0] addr ;
    // Two RAM arrays
    reg [7:0] ram0 [0:64];//65535 previously
    reg [7:0] ram1 [0:64];

    always @(posedge clk or negedge reset)
    begin 
    if(~reset)
    addr=0;
    else
    if(we)
    addr=addr+1;end
    always @(posedge clk) begin
        if (we) begin
            if (line_select == 0)
                ram0[addr] <= din;
            else
                ram1[addr] <= din;
        end
    end

    always @(*) begin
        if (line_select == 0)
            dout = ram0[read_addr];
        else
            dout = ram1[read_addr];
    end

endmodule
