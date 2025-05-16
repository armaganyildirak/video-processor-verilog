module threshold (
    input [7:0] in_pixel,
    input [7:0] threshold,
    output out_pixel
);
    assign out_pixel = (in_pixel > threshold) ? 1'b1 : 1'b0;
endmodule