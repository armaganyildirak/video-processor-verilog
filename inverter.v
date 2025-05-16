module inverter (
    input [7:0] in_pixel,
    output [7:0] out_pixel
);
    assign out_pixel = 8'd255 - in_pixel;
endmodule