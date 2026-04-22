#!/usr/bin/env python3
import sys
import yaml
import subprocess
from pathlib import Path

def get_yaml_path(file_path, line_num):
    """Get the YAML path for a key at the given line number."""
    with open(file_path, 'r') as f:
        lines = f.readlines()

    # Get the line and its indentation
    if line_num > len(lines):
        return None

    target_line = lines[line_num - 1]
    target_indent = len(target_line) - len(target_line.lstrip())

    # Parse to find the key at this line
    target_key = target_line.strip().rstrip(':').split(':')[0].strip()

    # Build path by walking up through parent indents
    path_parts = []
    current_indent = target_indent

    for i in range(line_num - 1, -1, -1):
        line = lines[i]
        line_indent = len(line) - len(line.lstrip())

        if line.strip() and not line.strip().startswith('#'):
            if line_indent < current_indent or (line_indent == current_indent and i == line_num - 1):
                # Extract key (handle both "key:" and "key: value" formats)
                key_part = line.strip().split(':')[0].strip()
                # Handle array indices
                if key_part.startswith('- '):
                    # Find array index
                    array_idx = 0
                    for j in range(i, -1, -1):
                        if lines[j].strip().startswith('- ') and (len(lines[j]) - len(lines[j].lstrip())) == line_indent:
                            if j == i:
                                break
                            array_idx += 1
                        elif (len(lines[j]) - len(lines[j].lstrip())) < line_indent:
                            break
                    path_parts.insert(0, f"[{array_idx}]")
                    key_part = key_part[2:].strip()  # Remove "- " prefix

                if key_part and key_part != '-':
                    path_parts.insert(0, key_part)
                current_indent = line_indent

                if line_indent == 0:
                    break

    return '.'.join(p for p in path_parts if not p.startswith('['))

def copy_to_clipboard(text):
    """Copy text to clipboard using pbcopy."""
    subprocess.run(['pbcopy'], input=text.encode('utf-8'), check=True)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: copy-yaml-path.py <file> <line_number>")
        sys.exit(1)

    file_path = sys.argv[1]
    line_num = int(sys.argv[2])

    try:
        path = get_yaml_path(file_path, line_num)
        if path:
            copy_to_clipboard(path)
            print(f"Copied to clipboard: {path}")
        else:
            print("Could not determine YAML path")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)