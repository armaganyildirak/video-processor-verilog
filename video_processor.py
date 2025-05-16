from PIL import Image
import numpy as np
import os
import cv2
import argparse
import subprocess

def create_directory_if_not_exists(directory):
    """Create directory if it doesn't exist"""
    if not os.path.exists(directory):
        os.makedirs(directory)
        print(f"Created directory: {directory}")

def video_to_frames(video_path, width=128, height=128):
    """
    Extract frames from video and convert to text files
    Returns the number of frames extracted
    """
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video file not found: {video_path}")
    
    # Create frame directory
    frames_dir = "frames"
    create_directory_if_not_exists(frames_dir)
    
    # Open video
    video = cv2.VideoCapture(video_path)
    if not video.isOpened():
        raise ValueError(f"Could not open video: {video_path}")
    
    frame_count = int(video.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = video.get(cv2.CAP_PROP_FPS)
    
    print(f"Processing video: {video_path}")
    print(f"Total frames: {frame_count}, FPS: {fps}")
    
    # Extract frames and save as text files
    frame_index = 0
    while True:
        ret, frame = video.read()
        if not ret:
            break
            
        # Resize frame
        frame = cv2.resize(frame, (width, height))
        
        # Convert BGR to RGB (OpenCV uses BGR)
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Flatten to pixel list
        pixels = frame_rgb.reshape(-1, 3)
        
        # Write to text file
        frame_file = os.path.join(frames_dir, f"input_frame_{frame_index}.txt")
        with open(frame_file, "w") as f:
            for r, g, b in pixels:
                f.write(f"{r} {g} {b}\n")
        
        frame_index += 1
        if frame_index % 10 == 0:
            print(f"Processed {frame_index} frames...")
    
    video.release()
    print(f"Extracted {frame_index} frames from video")
    return frame_index

def frames_to_video(width=128, height=128, fps=30.0):
    """
    Convert processed frame text files back to video
    Creates separate videos for each processing type (gray, negative, binary)
    """
    # Create output directory
    output_dir = "output_videos"
    create_directory_if_not_exists(output_dir)
    
    # Look for processed frame files in current directory
    current_dir = os.getcwd()
    gray_files = sorted([f for f in os.listdir(current_dir) if f.startswith("output_gray_")])
    
    if not gray_files:
        print("No processed frames found!")
        return
    
    total_frames = len(gray_files)
    
    print(f"Creating videos from {total_frames} frames")
    
    # Create video writers
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    gray_video = cv2.VideoWriter(os.path.join(output_dir, 'gray_output.mp4'), 
                                 fourcc, fps, (width, height), isColor=False)
    negative_video = cv2.VideoWriter(os.path.join(output_dir, 'negative_output.mp4'), 
                                    fourcc, fps, (width, height), isColor=False)
    binary_video = cv2.VideoWriter(os.path.join(output_dir, 'binary_output.mp4'), 
                                  fourcc, fps, (width, height), isColor=False)
    
    # Process each frame
    for frame_idx in range(total_frames):
        # Read grayscale output
        gray_path = f"output_gray_{frame_idx}.txt"
        neg_path = f"output_neg_{frame_idx}.txt"
        bin_path = f"output_bin_{frame_idx}.txt"
        
        if not os.path.exists(gray_path):
            print(f"Frame {frame_idx} not found, stopping video creation")
            break
            
        # Process grayscale
        gray_data = np.loadtxt(gray_path, dtype=np.uint8)
        gray_frame = gray_data.reshape((height, width))
        gray_video.write(gray_frame)
        
        # Process negative
        neg_data = np.loadtxt(neg_path, dtype=np.uint8)
        neg_frame = neg_data.reshape((height, width))
        negative_video.write(neg_frame)
        
        # Process binary
        bin_data = np.loadtxt(bin_path, dtype=np.uint8)
        bin_frame = (bin_data.reshape((height, width)) * 255).astype(np.uint8)
        binary_video.write(bin_frame)
        
        if frame_idx % 10 == 0:
            print(f"Added frame {frame_idx} to videos...")
    
    # Release video writers
    gray_video.release()
    negative_video.release()
    binary_video.release()
    
    print(f"Successfully created videos in {output_dir}/")

def run_verilog_simulation():
    """Run the actual Verilog simulation using Icarus Verilog"""
    print("Running Verilog simulation with Icarus Verilog...")
    
    # Step 1: Compile the Verilog code
    compile_cmd = [
        "iverilog",
        "-o", "video_processor_tb",
        "grayscale.v",
        "threshold.v",
        "inverter.v",
        "image_processor.v",
        "tb_video_processor.v"
    ]
    
    try:
        subprocess.run(compile_cmd, check=True)
        print("Verilog compilation successful")
    except subprocess.CalledProcessError as e:
        print(f"Verilog compilation failed: {e}")
        return
    
    # Step 2: Run the simulation
    run_cmd = [
        "vvp",
        "video_processor_tb"
    ]
    
    try:
        subprocess.run(run_cmd, check=True)
        print("Verilog simulation completed successfully")
    except subprocess.CalledProcessError as e:
        print(f"Verilog simulation failed: {e}")
        return
    
    # Verify output files were created
    if os.path.exists("output_gray_0.txt"):
        print("Verilog processing outputs detected")
    else:
        print("Warning: No output files found after Verilog simulation")

def main():
    parser = argparse.ArgumentParser(description="Video Processing with Verilog")
    parser.add_argument("--video", type=str, help="Path to input video file")
    parser.add_argument("--width", type=int, default=128, help="Frame width (default: 128)")
    parser.add_argument("--height", type=int, default=128, help="Frame height (default: 128)")
    parser.add_argument("--fps", type=float, default=30.0, help="Output video FPS (default: 30.0)")
    parser.add_argument("--skip-extraction", action="store_true", help="Skip frame extraction")
    parser.add_argument("--skip-simulation", action="store_true", help="Skip Verilog simulation")
    parser.add_argument("--skip-video-creation", action="store_true", help="Skip output video creation")
    
    args = parser.parse_args()
    
    # Extract frames from video
    if not args.skip_extraction:
        if not args.video:
            parser.error("--video is required unless --skip-extraction is specified")
        num_frames = video_to_frames(args.video, args.width, args.height)
    else:
        print("Skipping frame extraction...")
        # Count existing frames
        frame_files = sorted([f for f in os.listdir("frames") if f.startswith("input_frame_")])
        num_frames = len(frame_files)
        print(f"Found {num_frames} existing frames")
    
    # Run Verilog simulation
    if not args.skip_simulation:
        run_verilog_simulation()
    else:
        print("Skipping Verilog simulation...")
    
    # Create output videos
    if not args.skip_video_creation:
        frames_to_video(args.width, args.height, args.fps)
    else:
        print("Skipping output video creation...")
    
    print("Process complete!")

if __name__ == "__main__":
    main()