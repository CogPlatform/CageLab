"""
fractals.py

A command-line tool for generating and saving images of recursively deflected fractal polygons
with customizable parameters. Each image can contain multiple overlays (fractal units), each with
randomized or fixed number of edges, scale, rotation, color, and transparency. Inspired by 
Miyashita, Y., Higuchi, S.-I., Sakai, K., & Masui, N. (1991). Generation of fractal patterns 
for probing the visual memory. Neuroscience Research, 12(1), 307–311. 
https://doi.org/10.1016/0168-0102(91)90121-e

Features:
- Generates images of fractal polygons with recursive edge deflection.
- Supports both fixed and random number of edges, edge size, depth, GA, alpha, and rotation per overlay.
- Customizable color (HLS), transparency, and scale for overlays.
- Optionally sets random seeds for reproducibility.
- Saves each pattern as a PNG with a transparent background.

Usage Examples:
    # Generate 9 patterns with default settings
    python fractals.py

    # Generate 5 patterns, each with 3 overlays, random edge count between 3 and 8
    python fractals.py --num_patterns 5 --num_overlays 3 --num_edges 3 8

    # Use fixed seeds for reproducibility
    python fractals.py --shape_seed 42 --hue_seed 123 --rotation_seed 7

    # Specify ranges for edge size, depth, GA, alpha, and rotation
    python fractals.py --edge_size 0.5 1.0 --depth 2 5 --GA 0.1 0.3 --alpha 0.3 0.7 --rotation_angle 0 360

Arguments:
    --output_dir       Output directory for saved patterns (default: fractal_patterns)
    --num_patterns     Number of fractal patterns to generate (default: 9)
    --num_overlays     Number of fractal overlays per pattern (default: 3)
    --shape_seed       Fixed seed for shape randomization (optional)
    --hue_seed         Fixed seed for hue randomization (optional)
    --rotation_seed    Fixed seed for rotation randomization (optional)
    --num_edges        Fixed number of edges or range (e.g., 3 8) (default: 2 6)
    --edge_size        Fixed edge size or range (e.g., 0.5 1.0) (default: 0.5 1.0)
    --depth            Fixed depth or range (e.g., 2 5) (default: 2 5)
    --GA               Fixed GA value or range (e.g., 0.1 0.3) (default: 0.1 0.3)
    --alpha            Fixed alpha or range (e.g., 0.3 0.7) (default: 0.3 0.7)
    --rotation_angle   Fixed rotation angle or range (e.g., 0 360) (default: None for equidistant)
    --scale            Scale factor for successive overlays (default: 0.2)

Dependencies:
    pip install numpy matplotlib

Author: CageLab
"""

import numpy as np
import matplotlib.pyplot as plt
import random
import colorsys
import argparse
import os

def deflect_midpoint(fract_x, fract_y, GA):
    """
    Deflects the midpoint of each edge of a polygon by a fixed amount GA,
    creating a more complex, fractal-like shape.

    Args:
        fract_x (np.ndarray): x-coordinates of the polygon vertices.
        fract_y (np.ndarray): y-coordinates of the polygon vertices.
        GA (float): Deflection amplitude.

    Returns:
        tuple: (new_fract_x, new_fract_y) with doubled number of points.
    """
    n = len(fract_x)
    new_fract_x = np.zeros(2 * n)
    new_fract_y = np.zeros(2 * n)

    for i in range(n):
        new_fract_x[2 * i] = fract_x[i]
        new_fract_y[2 * i] = fract_y[i]

        mx = (fract_x[i] + fract_x[(i + 1) % n]) / 2
        my = (fract_y[i] + fract_y[(i + 1) % n]) / 2
        dx = fract_x[(i + 1) % n] - fract_x[i]
        dy = fract_y[(i + 1) % n] - fract_y[i]
        theta = np.arctan2(dy, dx)

        new_fract_x[2 * i + 1] = mx + GA * np.sin(theta)
        new_fract_y[2 * i + 1] = my - GA * np.cos(theta)

    return new_fract_x, new_fract_y

def generate_fractal(num_edges, edge_size, depth, GA):
    """
    Generates a fractal polygon by recursively deflecting the midpoints of its edges.

    Args:
        num_edges (int): Number of edges for the base polygon.
        edge_size (float): Radius of the base polygon.
        depth (int): Number of recursive deflection steps.
        GA (float): Deflection amplitude.

    Returns:
        tuple: (fract_x, fract_y) coordinates of the fractal polygon.
    """
    angles = np.linspace(0, 2 * np.pi, num_edges + 1)
    fract_x = edge_size * np.cos(angles)[:-1]
    fract_y = edge_size * np.sin(angles)[:-1]

    for _ in range(depth):
        fract_x, fract_y = deflect_midpoint(fract_x, fract_y, GA)

    return fract_x, fract_y

def rotate_fractal(fract_x, fract_y, angle):
    """
    Rotates the fractal polygon by a given angle.

    Args:
        fract_x (np.ndarray): x-coordinates of the polygon.
        fract_y (np.ndarray): y-coordinates of the polygon.
        angle (float): Rotation angle in degrees.

    Returns:
        tuple: (rotated_x, rotated_y) coordinates after rotation.
    """
    theta = np.radians(angle)
    cos_theta = np.cos(theta)
    sin_theta = np.sin(theta)

    rotated_x = fract_x * cos_theta - fract_y * sin_theta
    rotated_y = fract_x * sin_theta + fract_y * cos_theta

    return rotated_x, rotated_y

def scale_fractal(fract_x, fract_y, scale_factor):
    """
    Scales the fractal polygon by a given factor.

    Args:
        fract_x (np.ndarray): x-coordinates of the polygon.
        fract_y (np.ndarray): y-coordinates of the polygon.
        scale_factor (float): Scaling factor.

    Returns:
        tuple: (scaled_x, scaled_y) coordinates after scaling.
    """
    return fract_x * scale_factor, fract_y * scale_factor

def plot_fractal(fract_x, fract_y, hue, alpha):
    """
    Plots a single fractal polygon with the specified color and transparency.

    Args:
        fract_x (np.ndarray): x-coordinates of the polygon.
        fract_y (np.ndarray): y-coordinates of the polygon.
        hue (float): Hue value for color (0-1).
        alpha (float): Transparency (0-1).
    """
    saturation = 0.8  # Fixed saturation
    lightness = 0.5   # Fixed lightness
    rgb = colorsys.hls_to_rgb(hue, lightness, saturation)
    plt.fill(fract_x, fract_y, color=rgb, alpha=alpha)
    plt.axis('equal')
    plt.axis('off')

def parse_range(value):
    """
    Helper for argparse: parse a single value or a range (tuple of two values).

    Args:
        value (list): List of one or two values from argparse.

    Returns:
        int, float, or tuple: Single value or (min, max) tuple.
    """
    if len(value) == 1:
        return value[0]  # Single value, return as is
    elif len(value) == 2:
        return tuple(value)  # Two values, treat as a range
    else:
        raise argparse.ArgumentTypeError(f"Invalid range format: {value}. Expected a single value or a tuple of two values.")

def generate_and_save_fractal(output_dir, num_patterns, num_overlays, shape_seed, hue_seed, rotation_seed,
                             num_edges, edge_size, depth, GA, alpha, rotation_angle, scale):
    """
    Generates and saves multiple fractal patterns, each with multiple overlays.

    Args:
        output_dir (str): Directory to save images.
        num_patterns (int): Number of images to generate.
        num_overlays (int): Number of overlays per image.
        shape_seed (int or None): Seed for shape randomization.
        hue_seed (int or None): Seed for hue randomization.
        rotation_seed (int or None): Seed for rotation randomization.
        num_edges, edge_size, depth, GA, alpha, rotation_angle: Fixed or range for each parameter.
        scale (float): Scale factor for successive overlays.
    """
    os.makedirs(output_dir, exist_ok=True)

    for i in range(num_patterns):
        # Initialize random seeds for each pattern
        if shape_seed is not None:
            shape_random = random.Random(shape_seed)
        else:
            shape_random = random

        if hue_seed is not None:
            hue_random = random.Random(hue_seed)
        else:
            hue_random = random

        if rotation_seed is not None:
            rotation_random = random.Random(rotation_seed)
        else:
            rotation_random = random

        plt.figure(figsize=(4, 4), dpi=300)
        for j in range(num_overlays):
            # Randomize or fix parameters for each overlay
            if isinstance(num_edges, tuple):
                num_edges_val = shape_random.randint(*num_edges)
            else:
                num_edges_val = int(num_edges)

            if isinstance(edge_size, tuple):
                edge_size_val = shape_random.uniform(*edge_size)
            else:
                edge_size_val = edge_size

            if isinstance(depth, tuple):
                depth_val = shape_random.randint(*depth)
            else:
                depth_val = int(depth)

            if isinstance(GA, tuple):
                GA_val = shape_random.uniform(*GA)
            else:
                GA_val = GA

            if isinstance(alpha, tuple):
                alpha_val = hue_random.uniform(*alpha)
            else:
                alpha_val = alpha

            if rotation_angle is None:
                rotation_angle_val = (360 / num_overlays * j)/2
            elif isinstance(rotation_angle, tuple):
                rotation_angle_val = rotation_random.uniform(*rotation_angle)
            else:
                rotation_angle_val = rotation_angle

            hue = hue_random.uniform(0, 1)  # Random hue

            fract_x, fract_y = generate_fractal(num_edges_val, edge_size_val, depth_val, GA_val)
            fract_x, fract_y = rotate_fractal(fract_x, fract_y, rotation_angle_val)
            fract_x, fract_y = scale_fractal(fract_x, fract_y, (1 - scale * j))
            plot_fractal(fract_x, fract_y, hue, alpha_val)

        # Save the plot as a PNG file with a transparent background
        filename = (f"pattern_{i+1}_edges-{num_edges_val}_edgesize-{edge_size_val:.2f}_"
                    f"depth-{depth_val}_GA-{GA_val:.2f}_hue-{hue:.2f}_alpha-{alpha_val:.2f}_"
                    f"rotation-{rotation_angle_val:.2f}_"
                    f"_hueseed-{hue_seed}_shapeseed-{shape_seed}.png")
        filepath = os.path.join(output_dir, filename)
        plt.savefig(filepath, transparent=True, bbox_inches='tight', pad_inches=0)
        plt.close()

def main():
    """
    Main entry point for the CLI tool.
    Parses arguments, generates fractal patterns, and saves images.
    """
    parser = argparse.ArgumentParser(description="Generate and save fractal patterns.")
    parser.add_argument("--output_dir", type=str, default="fractal_patterns", help="Output directory for saved patterns.")
    parser.add_argument("--num_patterns", type=int, default=9, help="Number of fractal patterns to generate.")
    parser.add_argument("--num_overlays", type=int, default=3, help="Number of fractal patterns to overlay.")
    parser.add_argument("--shape_seed", type=int, help="Fixed seed for shape randomization.")
    parser.add_argument("--hue_seed", type=int, help="Fixed seed for hue randomization.")
    parser.add_argument("--rotation_seed", type=int, help="Fixed seed for rotation randomization.")
    parser.add_argument("--num_edges", type=int, nargs='*', default=[2, 6], help="Fixed number of edges or range (e.g., 2 8) for the fractal pattern.")
    parser.add_argument("--edge_size", type=float, nargs='*', default=[0.5, 1.0], help="Fixed edge size or range (e.g., 0.5 1.0) for the fractal pattern.")
    parser.add_argument("--depth", type=int, nargs='*', default=[2, 5], help="Fixed depth or range (e.g., 2 5) for the fractal pattern.")
    parser.add_argument("--GA", type=float, nargs='*', default=[0.1, 0.3], help="Fixed GA value or range (e.g., 0.1 0.3) for the fractal pattern.")
    parser.add_argument("--alpha", type=float, nargs='*', default=[0.3, 0.7], help="Fixed alpha value or range (e.g., 0.3 0.7) for the fractal pattern.")
    parser.add_argument("--rotation_angle", type=float, nargs='*', default=None, help="Fixed rotation angle or range (e.g., 0 360) for the fractal pattern. Use 'None' for equidistant rotations.")
    parser.add_argument("--scale", type=float, default=0.2, help="Scale factor for successive overlays.")

    args = parser.parse_args()

    # Parse the range values
    num_edges = parse_range(args.num_edges)
    edge_size = parse_range(args.edge_size)
    depth = parse_range(args.depth)
    GA = parse_range(args.GA)
    alpha = parse_range(args.alpha)
    rotation_angle = parse_range(args.rotation_angle) if args.rotation_angle is not None else None

    generate_and_save_fractal(args.output_dir, args.num_patterns, args.num_overlays, args.shape_seed, args.hue_seed, args.rotation_seed,
                             num_edges, edge_size, depth, GA, alpha, rotation_angle, args.scale)

if __name__ == "__main__":
    main()
