module grayscale (
    input [7:0] r, g, b,
    output [7:0] gray
);
    // Fixed-point weights: 0.299R + 0.587G + 0.114B (scaled by 1024)
    wire [17:0] weighted_sum = (r * 306) + (g * 601) + (b * 117); // 0.299*1024≈306, 0.587*1024≈601, 0.114*1024≈117
    assign gray = weighted_sum[17:10]; // Divide by 1024 (shift right by 10)
endmodule