`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 07:50:59 PM
// Design Name: 
// Module Name: lane_management
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lane_management 	(	
input clk_i,
input reset_i,
input [(4-1):0]bytes_valid_i,
input [((8*4)-1):0]byte_i,
output reg [((8*4)-1):0]lane_byte_o,
output reg lane_valid_o
);


		
localparam [3:0]ALIGN_DEPTH = 4'h3; //how many byte misalignment is allowed, whole packet length must be also longer than this 
localparam [2:0]LANES = 3'h4;		//mipi csi have 2 or 4 lanes 




reg [(8*LANES)-1:0]last_bytes[(ALIGN_DEPTH-1):0];
reg [(LANES-1):0]last_bytes_valid;
reg [3:0]sync_byte_index[(LANES-1):0];
reg lane_valid_reg;

reg [3:0]i;
reg [3:0]last_sync; //which lane was delayed most , which received sync byte at last 



always @(posedge clk_i) 
begin
	if (reset_i || (!lane_valid_o && (!(|bytes_valid_i))))
	begin
		lane_valid_o <= 1'h0;
		last_bytes_valid <= 0;

		for (i= 4'h0; i < ALIGN_DEPTH; i = i + 1'h1)
		begin
			last_bytes[i] <= 8'h0;
		end
		
		for (i= 4'h0; i <LANES; i = i + 1'h1)
		begin
			sync_byte_index[i] = 0;
		end
		
		lane_byte_o <= 0;
		lane_valid_reg <= 1'h0;
		last_sync <=0;
	end
	else
	begin

		
		last_bytes[0] <= byte_i;
		
		for (i= 4'h1; i < ALIGN_DEPTH; i = i + 1'h1)
		begin
			last_bytes[i] <= last_bytes[i-1'h1];
		end

		last_bytes_valid <= bytes_valid_i;
		lane_valid_o <= last_bytes_valid[last_sync]; //one clock delay to the last packet
		
		if ((!lane_valid_o) && (|bytes_valid_i))
		begin
			for (i= 4'h0; i < LANES; i = i + 1'h1)			
			begin
				if (!bytes_valid_i[i])
				begin
					last_sync = i;	//which lane was last 
					sync_byte_index[i] <= sync_byte_index[i] + 1'b1; //count delay of each sync, first one will be 0 delay last will max
				end
			end
		end
			
		
		lane_byte_o <= {last_bytes[sync_byte_index[last_sync] - sync_byte_index[3]][31:24],
						last_bytes[sync_byte_index[last_sync] - sync_byte_index[2]][23:16],
						last_bytes[sync_byte_index[last_sync] - sync_byte_index[1]][15:8],
						last_bytes[sync_byte_index[last_sync] - sync_byte_index[0]][7:0]};			
	end
end

endmodule
