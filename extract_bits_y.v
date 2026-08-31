module extract_bits_y(numb_i, tens_o, units_o);
    input [6:0] numb_i;
    output [3:0] tens_o, units_o;

    wire [3:0] d1, d2, d3, d4, d5, d6, d7;
    wire [3:0] c1, c2, c3, c4, c5, c6, c7;

    assign d1 = 4'b0000;
    assign d2 = {c1[2:0], numb_i[6]};
    assign d3 = {c2[2:0], numb_i[5]};
    assign d4 = {c3[2:0], numb_i[4]};
    assign d5 = {c4[2:0], numb_i[3]};
    assign d6 = {c5[2:0], numb_i[2]};
    assign d7 = {c6[2:0], numb_i[1]};

    add3 add3_1( .in(d1), .out(c1));
    add3 add3_2( .in(d2), .out(c2));
    add3 add3_3( .in(d3), .out(c3));
    add3 add3_4( .in(d4), .out(c4));
    add3 add3_5( .in(d5), .out(c5));
    add3 add3_6( .in(d6), .out(c6));
    add3 add3_7( .in(d7), .out(c7));

    assign tens_o =  {c5[3], c6[3], c7[3]};
    assign units_o = {c7[2:0], numb_i[0]};
endmodule