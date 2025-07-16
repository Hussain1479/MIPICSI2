module BYTETOPIXEL (
    input reset, clk,
    input [1:0] vc,
    input [15:0] wc,
    input crc_detect, ecc_error2, data_valid,
    input [7:0] data_in_llp, id, // llp = low level protocol
    output reg we,
    output reg line_select,
    output reg [7:0] dinrm,
    output reg transmit,
    output reg frame_start,
    output reg frame_end,
    output reg data_valid_o1
);

reg [7:0] din1, byte_1, byte_2, byte_3, byte_4, byte_5;
reg [39:0] raw_10_data;
reg raw_10, raw_8, data_valid_o;
reg [7:0] id1, id2;
reg [2:0] vc1;
reg [2:0] counter;
reg [16:0] wc_count;
reg [2:0] ps, ns;

always @(posedge clk) begin
    data_valid_o <= (~ecc_error2 && ~crc_detect && data_valid);
end

always @(posedge clk) begin
    data_valid_o1 <= data_valid_o;
end

always @(posedge clk or negedge reset) begin
    if (~reset) begin
        frame_start = 1'b0;
        frame_end = 1'b0;
    end else if (id == 8'h00) begin
        frame_start = 1'b1;
    end else if (id == 8'h01) begin
        frame_end = 1'b1;
    end
end

always @(posedge clk) begin
    if (wc_count == 4)
        transmit = 1'b1;
    // else transmit = 1'b0; // Optional as per your comment
end

always @(posedge clk or negedge reset) begin
    if (~reset) begin
        wc_count = 16'h0000;
        line_select = 1'b0;
    end else if ((id == 8'h2A || id == 8'h2B) && data_valid) begin
        wc_count = wc_count + 1;
        if (wc_count == 64)
            line_select = 1;
    end
end

always @(posedge clk or negedge reset) begin
    if (~reset)
        id1 <= 8'hxx;
    else begin
        id1 <= id;
        vc1 = vc;
    end
end

always @(posedge clk or negedge reset) begin
    if (~reset)
        id2 <= 8'hxx;
    else
        id2 <= id1;
end

always @(posedge clk) begin
    if (data_valid) begin
        if (vc1 == 0) begin
            if (id2 == 8'h2A || id2 == 8'h2B) begin
                case (id2)
                    8'h2A: begin
                        din1 <= data_in_llp;
                        raw_8 = 1'b1;
                        raw_10 = 1'b0;
                    end
                    8'h2B: begin
                        byte_1 <= data_in_llp;
                        byte_2 <= byte_1;
                        byte_3 <= byte_2;
                        byte_4 <= byte_3;
                        byte_5 <= byte_4;
                        counter <= counter + 1;
                        if (counter == 5) begin
                            raw_10_data[9:2]   <= byte_5;
                            raw_10_data[19:12] <= byte_4;
                            raw_10_data[29:22] <= byte_3;
                            raw_10_data[39:32] <= byte_2;
                            raw_10_data[1:0]   <= byte_1[1:0];
                            raw_10_data[11:10] <= byte_1[3:2];
                            raw_10_data[21:20] <= byte_1[5:4];
                            raw_10_data[31:30] <= byte_1[7:6];
                            raw_10 = 1'b1;
                            raw_8  = 1'b0;
                        end
                    end
                    default: begin
                        raw_8 = 0;
                        raw_10 = 0;
                    end
                endcase
            end
        end
    end
end

always @(posedge clk) begin
    case (ps)
        3'b000: begin
            we = 1'b0;
            if (id == 8'h2A)
                ns = 3'b001;
            else if (raw_10)
                ns = 3'b010;
            else
                ns = 3'b000;
        end
        3'b001: begin
            if (raw_8) begin
                ns = 3'b001;
                dinrm = din1;
                if (data_valid_o1)
                    we = 1'b1;
                else
                    we = 1'b0;
            end else if (raw_10)
                ns = 3'b010;
            else
                ns = 3'b000;
        end
        3'b010: begin
            we = 1'b1;
            dinrm = raw_10_data[7:0];
            ns = 3'b011;
        end
        3'b011: begin
            dinrm = raw_10_data[15:8];
            ns = 3'b100;
        end
        3'b100: begin
            dinrm = raw_10_data[23:16];
            ns = 3'b101;
        end
        3'b101: begin
            dinrm = raw_10_data[31:24];
            ns = 3'b110;
        end
        3'b110: begin
            dinrm = raw_10_data[39:32];
            ns = 3'b000;
        end
        default: ;
    endcase
end

always @(posedge clk or negedge reset) begin
    if (~reset)
        ps <= 3'b000;
    else
        ps <= ns;
end

endmodule
