module led7_segs
(    input en,
    input clk,
    input rst,
    input [3:0] inp_i,
    output reg [6:0] out_o
);

    wire	[6:0]	led;
	wire	a,b,c,d;

	assign {d,c,b,a} = inp_i;

	assign led[6] = ((~a)&(~c)) | (a&c) | b | d;
	assign led[5] = (~c) | (a&b) | ((~a)&(~b));
	assign led[4] = a | (~b) | c;
	assign led[3] = ((~a)&(~c)) | (b&(~c)) | d | ((~a)&b) | (a&(~b)&c);
	assign led[2] = ((~a)&(~c)) | ((~a)&b);
	assign led[1] = d | ((~a)&c) | ((~a)&(~b)) | ((~b)&c);
	assign led[0] = ((~a)&b) | ((~b)&c) | d | (b&(~c));

always @ (posedge clk or posedge rst)
	begin
		if(rst)begin
			out_o <= 7'b1111111;
		end
		else begin 
			if(en) out_o <= led;
			else out_o <= 7'b0000000;
		end 
	end
endmodule

