#!/usr/bin/env python3
"""
ssim.py

A command-line tool for comparing image similarity using SSIM (Structural Similarity Index)
and histogram correlation. Supports comparing two images, all pairs in a directory, or all
pairs between two directories. Outputs results to the console and a CSV file.

Features:
- Computes SSIM and histogram correlation for each image pair.
- Parses image filenames for metadata fields (edges, r, d, a, ss, cs, s, l).
- Outputs composite columns for each metadata field (e.g., cs1cs2, edges1edges2, etc.).
- Saves results to 'ssim_pairwise.csv' in the working directory.

Usage:
    # Compare two images
    python ssim.py image1.png image2.png

    # Compare all pairs in the current directory
    python ssim.py

    # Compare all pairs between two directories
    python ssim.py dir1 dir2

    # Use grayscale comparison
    python ssim.py image1.png image2.png --grayscale

CSV Output Columns:
    image1, image2, ssim, hist_corr,
    edges1, r1, d1, a1, ss1, cs1, s1, l1,
    edges2, r2, d2, a2, ss2, cs2, s2, l2,
    edges1edges2, r1r2, d1d2, a1a2, ss1ss2, cs1cs2, s1s2, l1l2

Dependencies:
    pip install opencv-python scikit-image

Author: CageLab
"""

import argparse
import cv2
from skimage import metrics
import sys
import os
import glob
import csv
from itertools import combinations
import re

def compute_ssim(img1_path, img2_path, grayscale):
    """
    Compute the Structural Similarity Index (SSIM) between two images.

    Args:
        img1_path (str): Path to the first image.
        img2_path (str): Path to the second image.
        grayscale (bool): Whether to convert images to grayscale before comparison.

    Returns:
        float: SSIM score, or None if images could not be loaded.
    """
    img1 = cv2.imread(img1_path)
    img2 = cv2.imread(img2_path)
    if img1 is None or img2 is None:
        print(f"Error: Could not load {img1_path} or {img2_path}.", file=sys.stderr)
        return None

    img2 = cv2.resize(img2, (img1.shape[1], img1.shape[0]), interpolation=cv2.INTER_AREA)

    if grayscale:
        img1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        img2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        min_side = min(img1.shape[0], img1.shape[1])
        win_size = min(7, min_side) if min_side >= 3 else 3
        if win_size % 2 == 0:
            win_size -= 1
        ssim_score, _ = metrics.structural_similarity(img1, img2, full=True, win_size=win_size)
    else:
        img1_rgb = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)
        img2_rgb = cv2.cvtColor(img2, cv2.COLOR_BGR2RGB)
        min_side = min(img1_rgb.shape[0], img1_rgb.shape[1])
        win_size = min(7, min_side) if min_side >= 3 else 3
        if win_size % 2 == 0:
            win_size -= 1
        ssim_score, _ = metrics.structural_similarity(
            img1_rgb, img2_rgb, channel_axis=-1, full=True, win_size=win_size
        )
    return ssim_score

def compute_histogram_correlation(img1_path, img2_path, grayscale):
    """
    Compute the histogram correlation between two images.

    Args:
        img1_path (str): Path to the first image.
        img2_path (str): Path to the second image.
        grayscale (bool): Whether to convert images to grayscale before comparison.

    Returns:
        float: Histogram correlation score, or None if images could not be loaded.
    """
    img1 = cv2.imread(img1_path)
    img2 = cv2.imread(img2_path)
    if img1 is None or img2 is None:
        return None
    img2 = cv2.resize(img2, (img1.shape[1], img1.shape[0]), interpolation=cv2.INTER_AREA)
    if grayscale:
        img1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        img2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        hist_img1 = cv2.calcHist([img1], [0], None, [256], [0, 256])
        hist_img2 = cv2.calcHist([img2], [0], None, [256], [0, 256])
    else:
        hist_img1 = cv2.calcHist([img1], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
        hist_img2 = cv2.calcHist([img2], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
    cv2.normalize(hist_img1, hist_img1, alpha=0, beta=1, norm_type=cv2.NORM_MINMAX)
    cv2.normalize(hist_img2, hist_img2, alpha=0, beta=1, norm_type=cv2.NORM_MINMAX)
    metric_val = cv2.compareHist(hist_img1, hist_img2, cv2.HISTCMP_CORREL)
    return metric_val

def parse_filename_fields(filename):
    """
    Extracts fields like edges, r, d, a, ss, cs, s, l from the filename.
    Returns a dict with those keys if found, else empty strings.

    Args:
        filename (str): The filename to parse.

    Returns:
        dict: Dictionary of extracted fields.
    """
    pattern = (
        r"edges(?P<edges>\d+)_r(?P<r>[\d\.]+)_d(?P<d>\d+)_a(?P<a>[\d\.]+)"
        r"_ss(?P<ss>[^_]+)_cs(?P<cs>[^_]+)_s(?P<s>[\d\.]+)_l(?P<l>[\d\.]+)"
    )
    match = re.search(pattern, filename)
    if match:
        return match.groupdict()
    else:
        return {
            "edges": "", "r": "", "d": "", "a": "",
            "ss": "", "cs": "", "s": "", "l": ""
        }

def main():
    """
    Main entry point for the CLI tool.
    Parses arguments, computes similarity metrics, and outputs results.
    """
    parser = argparse.ArgumentParser(
        description="Compute SSIM and histogram correlation between two images, all pairs in a directory, or all pairs between two directories."
    )
    parser.add_argument("image1", nargs='?', help="First image file or directory")
    parser.add_argument("image2", nargs='?', help="Second image file or directory")
    parser.add_argument("--grayscale", action="store_true", help="Convert images to grayscale before comparison")
    args = parser.parse_args()

    extra_fields = ["edges", "r", "d", "a", "ss", "cs", "s", "l"]
    composite_keys = ["edges", "r", "d", "a", "ss", "cs", "s", "l"]

    def composite_val(val1, val2):
        """
        Create a composite value by sorting and concatenating two values.
        Numeric values are sorted numerically, strings lexicographically.
        """
        try:
            v1 = float(val1)
            v2 = float(val2)
            v1s = str(int(v1)) if v1.is_integer() else str(v1)
            v2s = str(int(v2)) if v2.is_integer() else str(v2)
        except Exception:
            v1s, v2s = str(val1), str(val2)
        return "".join(sorted([v1s, v2s]))

    def get_images_from_dir(directory):
        """
        Get all image files in a directory with supported extensions.
        """
        exts = ('*.png', '*.jpg', '*.jpeg', '*.bmp', '*.tif', '*.tiff')
        files = []
        for ext in exts:
            files.extend(glob.glob(os.path.join(directory, ext)))
        return sorted(set(files))

    # Directory vs Directory mode
    if args.image1 and args.image2 and os.path.isdir(args.image1) and os.path.isdir(args.image2):
        files1 = get_images_from_dir(args.image1)
        files2 = get_images_from_dir(args.image2)
        if not files1 or not files2:
            print("One or both directories contain no images.", file=sys.stderr)
            sys.exit(1)
        results = []
        for img1 in files1:
            for img2 in files2:
                ssim_score = compute_ssim(img1, img2, args.grayscale)
                hist_corr = compute_histogram_correlation(img1, img2, args.grayscale)
                if ssim_score is not None and hist_corr is not None:
                    fields1 = parse_filename_fields(os.path.basename(img1))
                    fields2 = parse_filename_fields(os.path.basename(img2))
                    composites = {f"{k}1{k}2": composite_val(fields1.get(k, ""), fields2.get(k, "")) for k in composite_keys}
                    print(f"{img1},{img2},{ssim_score:.4f},{hist_corr:.4f}," +
                          ",".join(fields1.get(f, "") for f in extra_fields) + "," +
                          ",".join(fields2.get(f, "") for f in extra_fields) + "," +
                          ",".join(composites[k] for k in composites))
                    results.append((img1, img2, ssim_score, hist_corr, fields1, fields2, composites))
        # Write to CSV
        csv_path = os.path.join(os.getcwd(), "ssim_pairwise.csv")
        with open(csv_path, "w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(
                ["image1", "image2", "ssim", "hist_corr"] +
                [f"{f}1" for f in extra_fields] +
                [f"{f}2" for f in extra_fields] +
                [f"{k}1{k}2" for k in composite_keys]
            )
            for row in results:
                img1, img2, ssim_score, hist_corr, fields1, fields2, composites = row
                writer.writerow(
                    [img1, img2, f"{ssim_score:.4f}", f"{hist_corr:.4f}"] +
                    [fields1.get(f, "") for f in extra_fields] +
                    [fields2.get(f, "") for f in extra_fields] +
                    [composites[f"{k}1{k}2"] for k in composite_keys]
                )
        print(f"\nPairwise results saved to {csv_path}")

    # File vs File mode
    elif args.image1 and args.image2 and os.path.isfile(args.image1) and os.path.isfile(args.image2):
        ssim_score = compute_ssim(args.image1, args.image2, args.grayscale)
        hist_corr = compute_histogram_correlation(args.image1, args.image2, args.grayscale)
        if ssim_score is not None and hist_corr is not None:
            fields1 = parse_filename_fields(os.path.basename(args.image1))
            fields2 = parse_filename_fields(os.path.basename(args.image2))
            composites = {f"{k}1{k}2": composite_val(fields1.get(k, ""), fields2.get(k, "")) for k in composite_keys}
            print(f"SSIM Score ({args.image1}, {args.image2}): {ssim_score:.4f}")
            print(f"Histogram Correlation ({args.image1}, {args.image2}): {hist_corr:.4f}")
            print(f"{args.image1},{args.image2},{ssim_score:.4f},{hist_corr:.4f}," +
                  ",".join(fields1.get(f, "") for f in extra_fields) + "," +
                  ",".join(fields2.get(f, "") for f in extra_fields) + "," +
                  ",".join(composites[k] for k in composites))

    # Default: all pairs in current directory
    else:
        exts = ('*.png', '*.jpg', '*.jpeg', '*.bmp', '*.tif', '*.tiff')
        files = []
        for ext in exts:
            files.extend(glob.glob(ext))
        files = sorted(set(files))
        if len(files) < 2:
            print("Not enough images in the current directory for pairwise comparison.", file=sys.stderr)
            sys.exit(1)

        results = []
        for img1, img2 in combinations(files, 2):
            ssim_score = compute_ssim(img1, img2, args.grayscale)
            hist_corr = compute_histogram_correlation(img1, img2, args.grayscale)
            if ssim_score is not None and hist_corr is not None:
                fields1 = parse_filename_fields(os.path.basename(img1))
                fields2 = parse_filename_fields(os.path.basename(img2))
                composites = {f"{k}1{k}2": composite_val(fields1.get(k, ""), fields2.get(k, "")) for k in composite_keys}
                print(f"{img1},{img2},{ssim_score:.4f},{hist_corr:.4f}," +
                      ",".join(fields1.get(f, "") for f in extra_fields) + "," +
                      ",".join(fields2.get(f, "") for f in extra_fields) + "," +
                      ",".join(composites[k] for k in composites))
                results.append((img1, img2, ssim_score, hist_corr, fields1, fields2, composites))

        # Write to CSV
        csv_path = os.path.join(os.getcwd(), "ssim_pairwise.csv")
        with open(csv_path, "w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            # Header
            writer.writerow(
                ["image1", "image2", "ssim", "hist_corr"] +
                [f"{f}1" for f in extra_fields] +
                [f"{f}2" for f in extra_fields] +
                [f"{k}1{k}2" for k in composite_keys]
            )
            for row in results:
                img1, img2, ssim_score, hist_corr, fields1, fields2, composites = row
                writer.writerow(
                    [img1, img2, f"{ssim_score:.4f}", f"{hist_corr:.4f}"] +
                    [fields1.get(f, "") for f in extra_fields] +
                    [fields2.get(f, "") for f in extra_fields] +
                    [composites[f"{k}1{k}2"] for k in composite_keys]
                )
        print(f"\nPairwise results saved to {csv_path}")

if __name__ == "__main__":
    main()