# Tools
IVERILOG := iverilog
VVP := vvp
PYTHON := python3

# Configuration
INPUT_VIDEO ?= input.mp4
FRAME_WIDTH ?= 128
FRAME_HEIGHT ?= 128

# Verilog source files
VSRC = grayscale.v threshold.v inverter.v image_processor.v tb_video_processor.v

# Python script
PYSCRIPT = video_processor.py

# Default target
all: process

# Compile Verilog
compile:
	@echo "Compiling Verilog..."
	$(IVERILOG) -o video_processor_tb $(VSRC)

# Extract frames from video
extract:
	@echo "Extracting frames from video..."
	$(PYTHON) $(PYSCRIPT) --video $(INPUT_VIDEO) --width $(FRAME_WIDTH) --height $(FRAME_HEIGHT) --skip-simulation --skip-video-creation

# Run simulation (requires extracted frames)
simulate: extract compile
	@echo "Running simulation..."
	$(VVP) video_processor_tb

# Create output videos from processed frames
create-videos:
	@echo "Creating output videos..."
	$(PYTHON) $(PYSCRIPT) --width $(FRAME_WIDTH) --height $(FRAME_HEIGHT) --skip-extraction --skip-simulation

# Process video (complete pipeline)
process: simulate create-videos

clean:
	@echo "Cleaning up..."
	rm -f video_processor_tb
	rm -f waveform.vcd
	rm -f frame_metadata.txt
	rm -f output_gray_*.txt
	rm -f output_neg_*.txt
	rm -f output_bin_*.txt
	rm -rf frames
	rm -rf output_videos

help:
	@echo "Available targets:"
	@echo "  all          - Default target, runs complete pipeline (process)"
	@echo "  compile      - Compile Verilog source files"
	@echo "  extract      - Extract frames from input video"
	@echo "  simulate     - Run Verilog simulation (includes extract and compile)"
	@echo "  create-videos - Create output videos from processed frames"
	@echo "  process      - Full processing pipeline (extract + simulate + create videos)"
	@echo "  clean        - Remove all generated files"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Configuration variables:"
	@echo "  INPUT_VIDEO  - Input video file (default: input.mp4)"
	@echo "  FRAME_WIDTH  - Frame width in pixels (default: 128)"
	@echo "  FRAME_HEIGHT - Frame height in pixels (default: 128)"

.PHONY: all compile extract simulate create-videos process clean help