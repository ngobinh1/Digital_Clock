//convert 6 bits binary -> 4 bits tens + 4 bits units
//su dung thuat toan double dabble va add3 de tach bit
module extract_bits(numb_i, tens_o, units_o);
    input [5:0] numb_i;
    output [3:0] tens_o;
    output [3:0] units_o;

    wire [3:0] d1, d2, d3;
    wire [3:0] c1, c2, c3;

    assign d1 = {1'b0, numb_i[5:3]};
    assign d2 = {c1[2:0], numb_i[2]};
    assign d3 = {c2[2:0], numb_i[1]};

    add3 add3_1( .in(d1), .out(c1));
    add3 add3_2( .in(d2), .out(c2));
    add3 add3_3( .in(d3), .out(c3));

    assign tens_o = {1'b0, c1[3], c2[3], c3[3]};
    assign units_o = {c3[2:0], numb_i[0]};
endmodule