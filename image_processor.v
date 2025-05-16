module image_processor (
    input clk,
    input [7:0] r, g, b,
    input [7:0] threshold_val,
    output [7:0] gray,
    output [7:0] negative,
    output binary
);
    wire [7:0] gray_tmp;
    wire [7:0] neg_tmp;
    
    grayscale u_gray (.r(r), .g(g), .b(b), .gray(gray_tmp));
    inverter u_inv (.in_pixel(gray_tmp), .out_pixel(neg_tmp));
    threshold u_thresh (.in_pixel(gray_tmp), .threshold(threshold_val), .out_pixel(binary));
    
    assign gray = gray_tmp;
    assign negative = neg_tmp;
endmodule