# Video Frame Processor

This project implements a hardware-based video processing system in Verilog that performs real-time operations on video frames.

## Features

- **Grayscale Conversion**: Convert RGB to grayscale using proper luminance weights (0.299R + 0.587G + 0.114B)
- **Image Negative**: Create inverted color version of each frame
- **Thresholding**: Binary black/white conversion with configurable threshold
- **Complete Pipeline**: Automatic processing from video files to final outputs

## Requirements

- Icarus Verilog (iverilog) for simulation
- Python 3 with PIL/Pillow, numpy, opencv library
- GTKWave (optional, for viewing waveforms)
- Make (for build automation)

## Quick Start

### Basic Workflow

1. Place an input image as `input.mp4` (will be resized to 128×128)
2. Run the full processing pipeline:
```bash
make
```
### Output Videos
- **gray_output.mp4**:	Grayscale version
- **negative_output.mp4**:	Color-inverted image
- **binary_output.mp4**:	Black/white thresholded

### Makefile Targets
```bash
make           # Full processing pipeline
make extract   # Extract frames only
make simulate  # Run Verilog simulation
make clean     # Remove generated files
```