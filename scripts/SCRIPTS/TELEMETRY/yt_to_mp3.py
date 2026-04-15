#!/usr/bin/env python3
import sys
import re
import subprocess
import os

def parse_time_to_seconds(time_str):
    """
    Converts time strings like '1h2m3s', '1m3s', '3s' to total seconds.
    Returns None if time_str is None.
    """
    if time_str is None:
        return None
    
    pattern = r'(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?'
    match = re.match(pattern, time_str)
    if not match or time_str == "":
        return None
    
    hours, minutes, seconds = match.groups()
    total = 0
    if hours:
        total += int(hours) * 3600
    if minutes:
        total += int(minutes) * 60
    if seconds:
        total += int(seconds)
    
    return total

def format_seconds_to_timestamp(seconds):
    """Converts seconds to HH:MM:SS format for yt-dlp."""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    return f"{h:02d}:{m:02d}:{s:02d}"

def get_video_duration(url):
    """Fetches the duration of the YouTube video in seconds."""
    try:
        result = subprocess.run(
            ['yt-dlp', '--get-duration', url],
            capture_output=True, text=True, check=True
        )
        # yt-dlp returns duration in format [HH:MM:SS.mmm] or just seconds
        duration_str = result.stdout.strip()
        if ':' in duration_str:
            parts = duration_str.split(':')
            h = int(parts[0])
            m = int(parts[1])
            s = float(parts[2])
            return h * 3600 + m * 60 + s
        else:
            return float(duration_str)
    except Exception as e:
        print(f"Error fetching video duration: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 yt_to_mp3.py <url> [start_time] [end_time]")
        print("Example: python3 yt_to_mp3.py https://youtube.com/... 1m3s 2m10s")
        sys.exit(1)

    url = sys.argv[1]
    start_time_str = sys.argv[2] if len(sys.argv) > 2 else None
    end_time_str = sys.argv[3] if len(sys.argv) > 3 else None

    start_sec = parse_time_to_seconds(start_time_str)
    end_sec = parse_time_to_seconds(end_time_str)

    # Validate non-negative
    if (start_sec is not None and start_sec < 0) or (end_sec is not None and end_sec < 0):
        print("Error: Time values cannot be negative.")
        sys.exit(1)

    duration = get_video_duration(url)

    # Resolve defaults
    if start_sec is None:
        start_sec = 0.0
    if end_sec is None:
        end_sec = duration

    # Validation: boundaries
    if start_sec > duration:
        print(f"Error: Start time ({start_sec}s) cannot be greater than clip length ({duration}s).")
        sys.exit(1)
    if end_sec > duration:
        print(f"Error: End time ({end_sec}s) cannot be greater than clip length ({duration}s).")
        sys.exit(1)
    
    # Validation: logic
    if end_sec < start_sec:
        print("Error: End time cannot be smaller than start time.")
        sys.exit(1)
    
    if (end_sec - start_sec) < 5:
        print("Error: The difference between start and end time must be at least 5 seconds.")
        sys.exit(1)

    # Output directory (where the script is located)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_template = os.path.join(script_dir, "%(title)s.%(ext)s")

    # Construct yt-dlp command
    # -x: extract audio
    # --audio-format mp3: convert to mp3
    # --audio-quality 0: best quality (VBR 0)
    # --download-sections: trim the clip (requires ffmpeg)
    
    start_ts = format_seconds_to_timestamp(start_sec)
    end_ts = format_seconds_to_timestamp(end_sec)
    section = f"*{start_ts}-{end_ts}"

    cmd = [
        'yt-dlp',
        '-x',
        '--audio-format', 'mp3',
        '--audio-quality', '0',
        '--download-sections', section,
        '-o', output_template,
        url
    ]

    print(f"Downloading and converting from {start_ts} to {end_ts}...")
    try:
        subprocess.run(cmd, check=True)
        print("\nSuccessfully converted to MP3!")
    except subprocess.CalledProcessError as e:
        print(f"\nAn error occurred during conversion: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
