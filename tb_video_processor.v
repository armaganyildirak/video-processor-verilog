`timescale 1ns/1ps
module tb_video_processor;
    parameter FRAME_WIDTH = 128;
    parameter FRAME_HEIGHT = 128;
    parameter TOTAL_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;
    
    reg clk = 0;
    always #5 clk = ~clk; // 100MHz clock
    
    reg [7:0] r, g, b;
    reg [7:0] threshold_val = 100;
    wire [7:0] gray, negative;
    wire binary;
    
    integer infile, outfile_gray, outfile_neg, outfile_bin;
    integer frame_count = 0;
    integer pixel_count = 0;
    integer r_val, g_val, b_val;
    integer scan_result;
    integer more_frames = 1;
    
    // Frame metadata file (to track frame boundaries)
    integer frame_meta;
    
    // File path variables
    reg [100*8:1] input_pattern;
    reg [100*8:1] output_gray_pattern;
    reg [100*8:1] output_neg_pattern;
    reg [100*8:1] output_bin_pattern;
    
    image_processor dut (
        .clk(clk),
        .r(r), .g(g), .b(b),
        .threshold_val(threshold_val),
        .gray(gray),
        .negative(negative),
        .binary(binary)
    );
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_video_processor);
        
        // Create frame metadata file
        frame_meta = $fopen("frame_metadata.txt", "w");
        
        // Initialize input
        r = 0; g = 0; b = 0;
                
        // Process all available frames
        while (more_frames) begin
            // Generate filenames for this frame
            $sformat(input_pattern, "frames/input_frame_%0d.txt", frame_count);
            $sformat(output_gray_pattern, "output_gray_%0d.txt", frame_count);
            $sformat(output_neg_pattern, "output_neg_%0d.txt", frame_count);
            $sformat(output_bin_pattern, "output_bin_%0d.txt", frame_count);
            
            // Open files for this frame
            infile = $fopen(input_pattern, "r");
            if (infile == 0) begin
                $display("No more frames found, ending simulation");
                more_frames = 0; // Exit loop
            end
            else begin
                outfile_gray = $fopen(output_gray_pattern, "w");
                outfile_neg = $fopen(output_neg_pattern, "w");
                outfile_bin = $fopen(output_bin_pattern, "w");
                
                // Write frame boundary to metadata
                $fwrite(frame_meta, "Frame %0d starts at position %0d\n", frame_count, frame_count * TOTAL_PIXELS);
                
                // Process entire frame
                pixel_count = 0;
                while (pixel_count < TOTAL_PIXELS) begin
                    scan_result = $fscanf(infile, "%d %d %d\n", r_val, g_val, b_val);
                    
                    if (scan_result != 3) begin
                        $display("End of file or error reading pixel %0d in frame %0d", pixel_count, frame_count);
                        pixel_count = TOTAL_PIXELS; // Exit loop
                    end
                    else begin
                        r = r_val;
                        g = g_val;
                        b = b_val;
                        
                        #10; // Process for 1 clock cycle
                        
                        // Write output pixels
                        $fwrite(outfile_gray, "%d\n", gray);
                        $fwrite(outfile_neg, "%d\n", negative);
                        $fwrite(outfile_bin, "%d\n", binary ? 1 : 0);
                        
                        pixel_count = pixel_count + 1;
                    end
                end
                
                // Close files for this frame
                $fclose(infile);
                $fclose(outfile_gray);
                $fclose(outfile_neg);
                $fclose(outfile_bin);
                
                $display("Processed frame %0d", frame_count);
                frame_count = frame_count + 1;
            end
        end
        
        $fclose(frame_meta);
        $display("Video processing complete. %0d frames processed.", frame_count);
        $finish;
    end
endmodule