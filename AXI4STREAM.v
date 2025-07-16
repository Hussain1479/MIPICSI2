// Code your design here
module AXI4STREAM(
input clk,reset,Tvalid,Tready,Tuser_in,Tlast_in,
input [31:0] Tdata_in,
output  reg Tvalid_out,Tuser,Tlast,
output reg [31:0] Tdata
);

always@(*)begin
Tvalid_out=Tvalid;
Tuser=Tuser_in;
Tlast=Tlast_in;
end

always @(posedge clk or negedge reset) begin
    if (!reset)
        Tdata <= 32'b0;
    else if (Tvalid && Tready)
        Tdata <= Tdata_in;
end

endmodule
  
  
  
  
  
  
  
  
 