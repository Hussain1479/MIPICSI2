module 	STRIPPER (
input [7:0] data_in,
input reset,clk,
  output reg [1:0] vc,
output reg [15:0] wc,
output reg crc_detect, error2,error,enable,
output reg [7:0] data_out, id
);
reg tended;
reg [7:0] ecc,s,data,data_crc; // 4 registers of 8 bits each
reg [16:0] byte_counter;  // To track the number of bytes received
reg [15:0] wc1,footer,crc;
reg wc_full,packet_full,ph_done,comp_done;
reg [7:0] parity;
  reg [31:0] ph,ph1;
reg [2:0] ns,ps;
integer i,t,k;
always @(posedge clk or negedge reset) begin
    if (~reset) begin
        tended <=1'b0;
        byte_counter <= 3'b000;
        ecc<=8'h00;
        wc1<=8'h00;
        packet_full<=1'b0;
    end else 
     begin
        case (ps)
            2'b00:
            begin
             
            if((id==8'h2A || id== 8'h2B) && byte_counter<(wc)&& ~tended)
            ns=3'b100;
            else begin
            tended=1'b0; 
            ph[7:0]=data_in;
            packet_full =1'b0;
            ns=2'b01; end
            end
            2'b01:begin
            wc1[7:0]= data_in;
            packet_full =1'b0;
            ns=3'b010; end
            3'b010: 
            begin 
            wc1[15:8] = data_in;
            ph[23:8] = wc1;
            packet_full =1'b0;
            ns=3'b011;
            end
            3'b011:
            begin
            ecc  = data_in;
            ph[31:24] = data_in; 
            packet_full =1'b1; 
            if(id==8'h2A || id== 8'h2B)
            ns=3'b100;
            else
            ns=3'b000;            
              end 
            3'b100:begin 
            if((id==8'h2A || id== 8'h2B)&& byte_counter<(wc))begin
              ns=3'b100; 
             packet_full=1'b0;
             byte_counter = byte_counter + 1;          
            end else begin
            ns=3'b000;
            byte_counter=0;
            tended=1'b1;
            end
            end
        
              endcase
  end
  end
 
  always@(posedge clk or negedge reset)begin
  if(~reset)
  ps<=3'b000;
  else
  ps<=ns;
  end
  

always @(*) begin  vc=id[7:6]; end
//ECC Hamming shit
//Parity Generation
always @(posedge packet_full or negedge reset)
begin
if(~reset)
begin
parity=1'b0;
s=8'b00000000;
error =1'b1;
ph_done=1'b0;
end 
else if(packet_full==1'b1) begin
  ph1=ph;
parity[0] = ph[0]^ph[1]^ph[2]^ph[4]^ph[5]^ph[7]^ph[10]^ph[11]^ph[13]^ph[16]^ph[20]^ph[21]^ph[22]^ph[23];
parity[1] = ph[0]^ph[1]^ph[3]^ph[4]^ph[6]^ph[8]^ph[10]^ph[12]^ph[14]^ph[17]^ph[20]^ph[21]^ph[22]^ph[23];
parity[2] = ph[0]^ph[2]^ph[3]^ph[5]^ph[6]^ph[9]^ph[11]^ph[12]^ph[15]^ph[18]^ph[20]^ph[21]^ph[22];
parity[3] = ph[1]^ph[2]^ph[3]^ph[7]^ph[8]^ph[9]^ph[13]^ph[14]^ph[15]^ph[19]^ph[20]^ph[21]^ph[23];
parity[4] = ph[4]^ph[5]^ph[6]^ph[7]^ph[8]^ph[9]^ph[16]^ph[17]^ph[18]^ph[19]^ph[20]^ph[22]^ph[23];
parity[5] = ph[10]^ph[11]^ph[12]^ph[13]^ph[14]^ph[15]^ph[16]^ph[17]^ph[18]^ph[19]^ph[21]^ph[22]^ph[23];
parity[6] = 0;
parity[7] = 0;
s[0]=parity[0]^ecc[0];
s[1]=parity[1]^ecc[1];
s[2]=parity[2]^ecc[2];
s[3]=parity[3]^ecc[3];
s[4]=parity[4]^ecc[4];
s[5]=parity[5]^ecc[5];
s[6]=0;
s[7]=0;

case(s)
        8'h07: begin
        ph1[0] = ~ph[0];  
        ph_done = 1'b1;
    end  
    8'h0B: begin
        ph1[1] = ~ph[1];  
        ph_done = 1'b1;
    end  
    8'h0D: begin
      ph1[2] = ~ph[2];  
        ph_done = 1'b1;
    end  
    8'h0E: begin
        ph1[3] = ~ph[3];  
        ph_done = 1'b1;
    end  
    8'h13: begin
        ph1[4] = ~ph[4];  
        ph_done = 1'b1;
    end  
    8'h15: begin
        ph1[5] = ~ph[5];  
        ph_done = 1'b1;
    end  
    8'h16: begin
        ph1[6] = ~ph[6];  
        ph_done = 1'b1;
    end  
    8'h19: begin
        ph1[7] = ~ph[7];  
        ph_done = 1'b1;
    end  
    8'h1A: begin
        ph1[8] = ~ph[8];  
        ph_done = 1'b1;
    end  
    8'h1C: begin
        ph1[9] = ~ph[9];  
        ph_done = 1'b1;
    end  
    8'h23: begin
        ph1[10] = ~ph[10];  
        ph_done = 1'b1;
    end  
    8'h25: begin
        ph1[11] = ~ph[11];  
        ph_done = 1'b1;
    end  
    8'h26: begin
        ph1[12] = ~ph[12];  
        ph_done = 1'b1;
    end  
    8'h29: begin
        ph1[13] = ~ph[13];  
        ph_done = 1'b1;
    end  
    8'h2A: begin
        ph1[14] = ~ph[14];  
        ph_done = 1'b1;
    end  
    8'h2C: begin
        ph1[15] = ~ph[15];  
        ph_done = 1'b1;
    end  
    8'h31: begin
        ph1[16] = ~ph[16];  
        ph_done = 1'b1;
    end  
    8'h32: begin
        ph1[17] = ~ph[17];  
        ph_done = 1'b1;
    end  
    8'h34: begin
        ph1[18] = ~ph[18];  
        ph_done = 1'b1;
    end  
    8'h38: begin
        ph1[19] = ~ph[19];  
        ph_done = 1'b1;
    end  
    8'h1F: begin
        ph1[20] = ~ph[20];  
        ph_done = 1'b1;
    end  
    8'h2F: begin
        ph1[21] = ~ph[21];  
        ph_done = 1'b1;
    end  
    8'h37: begin
        ph1[22] = ~ph[22];  
        ph_done = 1'b1;
    end  
    8'h3B: begin
        ph1[23] = ~ph[23];  
        ph_done = 1'b1;
    end  
 
    default:
    ;
endcase
if(s==0) begin
       error=1'b0 ; // Handle default case if needed  
       error2=1'b0;end
       else 
       if(ph_done==1'b1)begin
       error=1'b1;error2=1'b0;end
       else
        error2=1'b1;
       
end
end


always @(posedge clk or negedge reset) begin
    if (~reset) begin
        data_out  = 8'h00;
           // Used non-blocking assignment (<=)
      //  crc       = 16'hFFFF;
        i         = -1;       // Missing identifier `i`, assuming it's a register
    end else begin 
        if ( enable && (~ error2) &&(id==8'h2A||id==8'h2B) )begin
        
                // CRC Calculation & Data Output
                if ((i < wc) && i>-1  )
                    data_out = data;//phly data tha aur ab data_in kr rha hn
                 //   data = data_in; // `data` should hold the incoming byte
                    

            i = i + 1; // Increment counter properly
   
            if (i == (wc+1 )) begin
                //enable = 1'b0;  // Disable after completion
                i=0;
            end
        end
    end
end



always @ ( posedge clk or negedge reset)   begin
       if(~reset)begin
       footer=16'h0000;
       comp_done=1'b0;
         crc_detect=1'b0;
       end
       else begin
                  comp_done=1'b0;
                   if(k<wc)
                       footer=16'h0000;
                    else begin
                    // Processing Footer
                     if (k == (wc) ) 
                        footer[7:0] = data_in;
                      else begin
      
                          if(tended) begin 
                              footer[15:8]  = data_in;
                                crc_detect    = (~(footer == crc)); // Compare footer with computed CRC
                                comp_done=1'b1;                 
                                  end
            
                                 end
                     end
       end
end






















always@(posedge clk or negedge reset)begin
if(~reset) begin
k=0;
end
else 
 
       if(enable && (~ error2) &&(id==8'h2A||id==8'h2B))
            
                                 k=k+1;
                                 
                             
         else
        
        k=0;
                      
   
 end

  
always@(*) begin
if(~reset)
enable=1'b0;
else begin
if(packet_full && (id==8'h2A || id==8'h2B) )
      enable=1'b1;    
else
 if(tended) 
   enable=1'b0;
    end
end


always @ (posedge clk or negedge reset)
begin
     if(~reset)
 	begin
 	crc=16'hffff;
	// wc=16'h0;
         data=8'hxx;
      
 	//id=8'hxx;
 	end
    else
	begin
	
	data=data_in;
	data_crc=data_in;
	if ( enable && (~ error2) &&(id==8'h2A||id==8'h2B)&& i<5   ) begin
	for ( t = 0; t < 8; t = t + 1) begin
                        if ((crc & 16'h0001) ^ (data_crc & 16'h0001)) begin
                            crc  = (crc >> 1) ^ 16'h8408;
                        end else begin
                            crc = crc >> 1;
                        end
                        data_crc = data_crc >> 1;
                    end
	
	//if(packet_full && (~error || ph_done))
	//id<=ph[7:0];
	end
	else if(comp_done)
	      crc=16'hffff;
	end
end


always@(*)begin
if(packet_full && (~error2 || ph_done))begin
	id =ph1[7:0];
	wc =ph1[23:8];end
   else begin
    if(byte_counter==wc) begin
     id =8'hxx;
     wc =16'hxxxx;
     end
    end
end



endmodule

