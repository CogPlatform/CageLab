import numpy as np
import matplotlib.pyplot as plt
import random
import colorsys
import argparse
import os

def deflect_midpoint(fract_x, fract_y, GA):
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
    angles = np.linspace(0, 2 * np.pi, num_edges + 1)
    fract_x = edge_size * np.cos(angles)[:-1]
    fract_y = edge_size * np.sin(angles)[:-1]

    for _ in range(depth):
        fract_x, fract_y = deflect_midpoint(fract_x, fract_y, GA)

    return fract_x, fract_y

def rotate_fractal(fract_x, fract_y, angle):
    theta = np.radians(angle)
    cos_theta = np.cos(theta)
    sin_theta = np.sin(theta)

    rotated_x = fract_x * cos_theta - fract_y * sin_theta
    rotated_y = fract_x * sin_theta + fract_y * cos_theta

    return rotated_x, rotated_y

def scale_fractal(fract_x, fract_y, scale_factor):
    return fract_x * scale_factor, fract_y * scale_factor

def plot_fractal(fract_x, fract_y, hue, alpha):
    # Convert HSL to RGB
    saturation = 0.8  # Fixed saturation
    lightness = 0.5   # Fixed lightness
    rgb = colorsys.hls_to_rgb(hue, lightness, saturation)
    plt.fill(fract_x, fract_y, color=rgb, alpha=alpha)
    plt.axis('equal')
    plt.axis('off')

def parse_range(value):
    if len(value) == 1:
        return value[0]  # Single value, return as is
    elif len(value) == 2:
        return tuple(value)  # Two values, treat as a range
    else:
        raise argparse.ArgumentTypeError(f"Invalid range format: {value}. Expected a single value or a tuple of two values.")

def generate_and_save_fractal(output_dir, num_patterns, num_overlays, shape_seed, hue_seed, rotation_seed,
                             num_edges, edge_size, depth, GA, alpha, rotation_angle, scale):
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
