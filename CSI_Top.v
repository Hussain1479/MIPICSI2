module CSI_Top(
input [7:0] data_in,
input reset,clk,Tready,
output   Tvalid_out,Tuser,Tlast,
output  [31:0] Tdata);


 wire [1:0] vc;
 wire[15:0] wc;
 wire crc_detect, error;
 wire [7:0] data_out, id;
 wire [31:0] dout;

 wire we;
 wire line_select;
 wire [7:0] dinrm;
 wire transmit;
 wire frame_start;
 wire frame_end;
 wire data_valid;


STRIPPER X(.data_in(data_in),.reset(reset),.clk(clk),.id(id),.enable(enable),
.vc(vc),.wc(wc),.crc_detect(crc_detect),.error(error),.error2(error2),.data_out(data_out));


BYTETOPIXEL Y(
.reset(reset),.clk(clk),
 .vc(vc),
 .wc(wc),
.crc_detect(crc_detect),.ecc_error2(error||error2),.data_valid(~error2&&~crc_detect&&enable),
.data_in_llp(data_out),.id(id),
.we(we),
.line_select(line_select),
.dinrm(dinrm),
.transmit(transmit),
.frame_start(frame_start), .frame_end(frame_end),.data_valid_o(data_valid_o)
);

reg [15:0] read_addr;
always@(posedge clk or negedge reset) begin
if(~reset)
read_addr=16'h00;
else
if(data_valid_o&&Tready&&transmit)
read_addr=read_addr+1;
end

 Arraycheck Z(
     .clk(clk),.reset(reset),
     .we(we),             // Write Enable, asserted on Valid data
     .line_select(line_select),    // 0 or 1, select which line
     .din(dinrm),      // Data input
     .read_addr(read_addr),
     .dout(dout) // Data output
);









AXI4STREAM W(
.clk(clk),.reset(reset),.Tvalid(data_valid_o),.Tready(Tready),.Tuser_in(frame_end),.Tlast_in(frame_end),
 .Tdata_in(dout),
.Tvalid_out(Tvalid_out),.Tuser(Tuser),.Tlast(Tlast),
 .Tdata(Tdata)
);






















endmodule 





