module TbSTRIPPER;
 
reg [7:0] data_in;
reg reset,clk;
wire [1:0] vc;
wire [15:0] wc;
wire crc_detect, error,error2,enable;
wire[7:0] data_out,id;
reg Tready;

wire we;
wire line_select;
wire [7:0] dinrm;
wire transmit;
wire frame_start;
wire frame_end;
wire data_valid_o;
wire [31:0] dout;


STRIPPER X(.data_in(data_in),.reset(reset),.clk(clk),.id(id),
.vc(vc),.wc(wc),.crc_detect(crc_detect),
.enable(enable),.error(error),.error2(error2),.data_out(data_out));

BYTETOPIXEL Y(
.reset(reset),.clk(clk),
 .vc(vc),
 .wc(wc),
.crc_detect(crc_detect),.ecc_error2(error),.data_valid(~(error2)&&~crc_detect&&enable),
.data_in_llp(data_out),.id(id),//llp=low level protocol 
.we(we),
.line_select(line_select),
.dinrm(dinrm),
.transmit(transmit),
.frame_start(frame_start), .frame_end(frame_end),.data_valid_o1(data_valid_o)
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

wire Tvalid_out,Tuser,Tlast;
wire [31:0] Tdata;
AXI4STREAM W(
.clk(clk),.reset(reset),.Tvalid(data_valid_o),.Tready(Tready),.Tuser_in(frame_start),.Tlast_in(frame_end),
 .Tdata_in(dout),
.Tvalid_out(Tvalid_out),.Tuser(Tuser),.Tlast(Tlast),
 .Tdata(Tdata)
);














always #5 clk = ~clk;


reg [7:0] data_id;
    reg [15:0] word_count;
    reg [7:0] ecc;

    // Function declaration
    function [7:0] calculate_ecc;
        input [7:0] data_id;
        input [15:0] word_count;
        reg [23:0] ph;
        reg [7:0] parity;
        begin
            ph = {word_count, data_id};
            parity[0] = ph[0]^ph[1]^ph[2]^ph[4]^ph[5]^ph[7]^ph[10]^ph[11]^ph[13]^ph[16]^ph[20]^ph[21]^ph[22]^ph[23];
            parity[1] = ph[0]^ph[1]^ph[3]^ph[4]^ph[6]^ph[8]^ph[10]^ph[12]^ph[14]^ph[17]^ph[20]^ph[21]^ph[22]^ph[23];
            parity[2] = ph[0]^ph[2]^ph[3]^ph[5]^ph[6]^ph[9]^ph[11]^ph[12]^ph[15]^ph[18]^ph[20]^ph[21]^ph[22];
            parity[3] = ph[1]^ph[2]^ph[3]^ph[7]^ph[8]^ph[9]^ph[13]^ph[14]^ph[15]^ph[19]^ph[20]^ph[21]^ph[23];
            parity[4] = ph[4]^ph[5]^ph[6]^ph[7]^ph[8]^ph[9]^ph[16]^ph[17]^ph[18]^ph[19]^ph[20]^ph[22]^ph[23];
            parity[5] = ph[10]^ph[11]^ph[12]^ph[13]^ph[14]^ph[15]^ph[16]^ph[17]^ph[18]^ph[19]^ph[21]^ph[22]^ph[23];
            parity[6] = 1'b0;
            parity[7] = 1'b0;
            calculate_ecc = parity;
        end
    endfunction

    always @(posedge clk) ecc = calculate_ecc(data_id, word_count);








    reg [7:0] databyte;
    reg [15:0] crc;
    integer i;

    parameter word_count0 = 5;

    // Input data stream (5 bytes)
    reg [7:0] input_data [0:word_count0-1];

    // CRC-16-CCITT reversed polynomial function
    function [15:0] next_crc;
        input [15:0] crc_in;
        input [7:0]  data_byte;
        integer k;
        reg [15:0] crc_temp;
        begin
            crc_temp = crc_in;
            for (k = 0; k < 8; k = k + 1) begin
                if ((crc_temp[0] ^ data_byte[0]) == 1'b1)
                    crc_temp = (crc_temp >> 1) ^ 16'h8408;
                else
                    crc_temp = crc_temp >> 1;
                data_byte = data_byte >> 1;
            end
            next_crc = crc_temp;
        end
    endfunction

   

    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        crc = 16'hFFFF;
        #10 reset = 0;

        // Fill input data
        input_data[0] = 8'h05;
        input_data[1] = 8'h04;
        input_data[2] = 8'h03;
        input_data[3] = 8'h02;
        input_data[4] = 8'h01;

        // Feed data on each clock
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            databyte = input_data[i];
            crc = next_crc(crc, databyte);
        end 
        end

   









initial begin
data_id=8'h01;
word_count=16'h003;//WC lsb
clk=0;
#5
reset=1;
#5 reset=0;
#1 reset=1;
#2  data_in=data_id;
#10 data_in=8'h03;//lsb
#10 data_in=8'h00;//msb
#10 data_in=8'h06;//Ecc
data_id=8'h2A;word_count=16'h0005;

#10 data_in=data_id;//Ecc
#10 data_in=05;//Ecc
#10 data_in=00;//Ecc
#10 data_in=ecc;//Ecc
Tready=1'b1;

#10 data_in=8'h05;//data
#10 data_in=8'h04;
#10 data_in=8'h03;
#10 data_in=8'h02;
#10 data_in=8'h01;
#10 data_in= crc[7:0];
#10 data_in = crc[15:8];

data_id=8'h2A;word_count=16'h0005;

#10 data_in=data_id;//Ecc
#10 data_in=05;//Ecc
#10 data_in=00;//Ecc
#10 data_in=ecc;//Ecc
#10 data_in=8'h05;//data
#10 data_in=8'h04;
#10 data_in=8'h03;
#10 data_in=8'h02;
#10 data_in=8'h01;
#10 data_in= crc[7:0];
#10 data_in = crc[15:8];

end




endmodule 