#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_fractals.py

A command-line tool for generating images of recursively deflected fractal polygons
with customizable parameters. Each image can contain multiple fractal units, each with
randomized or fixed number of edges, scale, rotation, color, and transparency.

Features:
- Generates images of fractal polygons with recursive edge deflection.
- Supports both fixed and random number of edges per fractal unit.
- Customizable color (HLS), transparency, and size variation.
- Optionally sorts hues for more visually pleasing color order.
- Optionally outputs a sidecar JSON file with metadata for each image.
- Supports transparent or solid backgrounds.

Usage:
    # Generate 10 images with default settings
    python generate_fractals.py

    # Generate 5 images, each with 7-12 edges per unit, random seeds, and transparent background
    python generate_fractals.py --count 5 --n_edges 7 12 --transparent --base_shape_seed None --base_color_seed None

    # Generate images with fixed number of edges and save metadata
    python generate_fractals.py --n_edges 6 --sidecar

    # Disable random rotation and hue sorting
    python generate_fractals.py --no_random_rotation --no_sort_hues

Arguments:
    --count            Number of images to generate (default: 10)
    --output_dir       Directory to save images (default: output)
    --base_shape_seed  Base seed for shape randomization ('None' for random)
    --base_color_seed  Base seed for color randomization ('None' for random)
    --increment_seeds  Increment seeds for each image (default: False)
    --num_figures      Number of fractal units per image (default: 5)
    --n_edges          Number of edges (one value for fixed, two for range)
    --radius           Base radius for the fractal shape (default: 1.0)
    --depth            Recursion depth for edge deflection (default: 4)
    --amplitude        Amplitude of edge deflection (default: 0.3)
    --size_variation   Min and max scale for fractal units (default: 0.05 1)
    --alpha_range      Min and max alpha for fractal units (default: 0.7 0.7)
    --saturation       HLS saturation (default: 0.8)
    --lightness        HLS lightness (default: 0.5)
    --transparent      Use transparent background (default: False)
    --no_random_rotation  Disable random rotation (default: False)
    --no_sort_hues     Disable sorting of hues (default: False)
    --sidecar          Write sidecar JSON with metadata (default: False)

Dependencies:
    pip install numpy matplotlib

Author: CageLab
"""

import numpy as np
import matplotlib.pyplot as plt
import argparse
import os
import colorsys

def regular_polygon(n_edges, radius):
    """
    Generate the vertices of a regular polygon.

    Args:
        n_edges (int): Number of edges (vertices).
        radius (float): Radius of the polygon.

    Returns:
        np.ndarray: Array of shape (n_edges, 2) with (x, y) coordinates.
    """
    angles = np.linspace(0, 2 * np.pi, n_edges, endpoint=False)
    x = radius * np.cos(angles)
    y = radius * np.sin(angles)
    return np.column_stack((x, y))

def deflect_edges(points, amplitude, rng):
    """
    Deflect the edges of a polygon by adding a random offset to the midpoint
    of each edge, perpendicular to the edge.

    Args:
        points (np.ndarray): Polygon vertices, shape (N, 2).
        amplitude (float): Maximum deflection distance.
        rng (np.random.RandomState): Random number generator.

    Returns:
        np.ndarray: New set of points with deflected edges.
    """
    new_pts = []
    N = len(points)
    for i in range(N):
        p1 = points[i]
        p2 = points[(i + 1) % N]
        new_pts.append(p1.copy())
        mid = (p1 + p2) / 2.0
        dx, dy = p2 - p1
        length = np.hypot(dx, dy)
        normal = np.array([dy, -dx]) / length if length != 0 else np.array([0.0, 0.0])
        A = rng.uniform(-amplitude, amplitude)
        deflected = mid + A * normal
        new_pts.append(deflected)
    return np.array(new_pts)

def recursive_fractal(n_edges, radius, depth, amplitude, rng):
    """
    Recursively deflect the edges of a regular polygon.

    Args:
        n_edges (int): Number of edges for the base polygon.
        radius (float): Radius of the base polygon.
        depth (int): Number of recursive deflection steps.
        amplitude (float): Maximum deflection amplitude.
        rng (np.random.RandomState): Random number generator.

    Returns:
        np.ndarray: Array of points representing the fractal polygon.
    """
    pts = regular_polygon(n_edges, radius)
    for _ in range(depth):
        pts = deflect_edges(pts, amplitude, rng)
    return pts

def plot_fractals(num_figures=3, 
                  n_edges_fixed=None, n_edges_range=None, radius=1.0, depth=4, amplitude=0.2, 
                  shape_seed=None, color_seed=None,
                  random_rotation=False, save_path=None,
                  size_variation=(1.0, 1.0), alpha_range=1.0,
                  saturation=0.8, lightness=0.5,
                  transparent_bg=False, sort_hues=True):
    """
    Generate and plot multiple fractal polygons in a single image.

    Args:
        num_figures (int): Number of fractal units to draw.
        n_edges_fixed (int or None): Fixed number of edges, or None to use range.
        n_edges_range (tuple or None): (min, max) edges if using a range.
        radius (float): Base radius for polygons.
        depth (int): Recursion depth.
        amplitude (float): Deflection amplitude.
        shape_seed (int or None): Seed for shape RNG.
        color_seed (int or None): Seed for color RNG.
        random_rotation (bool): Whether to randomly rotate each unit.
        save_path (str or None): Path to save the image.
        size_variation (tuple): (min, max) scale for units.
        alpha_range (tuple): (min, max) alpha for units.
        saturation (float): HLS saturation.
        lightness (float): HLS lightness.
        transparent_bg (bool): Use transparent background.
        sort_hues (bool): Sort hues for color order.
    """
    shape_rng = np.random.RandomState(shape_seed)
    color_rng = np.random.RandomState(color_seed)

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.set_aspect('equal')
    ax.axis('off')

    bg_color = (0, 0, 0, 0) if transparent_bg else 'black'
    fig.patch.set_facecolor(bg_color)
    ax.set_facecolor(bg_color)

    # Generate figures with shape parameters first
    figures = []
    for _ in range(num_figures):
        scale = shape_rng.uniform(*size_variation) if isinstance(size_variation, tuple) else size_variation
        angle = shape_rng.uniform(0, 2 * np.pi) if random_rotation else (2 * np.pi)/num_figures * _
        alpha = color_rng.uniform(*alpha_range) if isinstance(alpha_range, tuple) else alpha_range
        figures.append({'scale': scale, 'angle': angle, 'alpha': alpha})

    # Sort by scale descending
    figures.sort(key=lambda f: -f['scale'])

    # Assign hues after sorting so hue order matches drawing order
    hues = [color_rng.uniform(0.0, 1.0) for _ in range(num_figures)]
    if sort_hues:
        hues.sort()

    for fig_data, h in zip(figures, hues):
        fig_data['h'] = h
        fig_data['s'] = saturation
        fig_data['l'] = lightness

    all_polygons = []

    for idx, f in enumerate(figures):
        # Choose n_edges for this fractal unit
        if n_edges_fixed is not None:
            n_edges_unit = n_edges_fixed
        else:
            n_edges_unit = shape_rng.randint(n_edges_range[0], n_edges_range[1] + 1)
        pts = recursive_fractal(n_edges_unit, radius * f['scale'], depth, amplitude, shape_rng)
        poly = np.vstack([pts, pts[0]])

        R = np.array([[np.cos(f['angle']), -np.sin(f['angle'])],
                        [np.sin(f['angle']),  np.cos(f['angle'])]])
        poly = poly @ R.T

        color = colorsys.hls_to_rgb(f['h'], f['l'], f['s'])
        ax.fill(poly[:, 0], poly[:, 1], color=color, alpha=f['alpha'], linewidth=0)
        all_polygons.append(poly)

    if all_polygons:
        all_pts = np.vstack(all_polygons)
        max_scale = max(f['scale'] for f in figures)
        margin = radius * max_scale * 0.2
        min_x, max_x = all_pts[:, 0].min() - margin, all_pts[:, 0].max() + margin
        min_y, max_y = all_pts[:, 1].min() - margin, all_pts[:, 1].max() + margin
        ax.set_xlim(min_x, max_x)
        ax.set_ylim(min_y, max_y)

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, facecolor=fig.get_facecolor(), dpi=300, transparent=transparent_bg)
    plt.close(fig)

def none_or_int(value):
    """
    Helper for argparse: parse int or None from string.
    """
    return None if value == "None" else int(value)

def main():
    """
    Main entry point for the CLI tool.
    Parses arguments, generates images, and optionally saves metadata.
    """
    parser = argparse.ArgumentParser(description="Generate fractal images with recursive edge deflection.")
    parser.add_argument("--count", type=int, default=10, help="Number of images to generate")
    parser.add_argument("--output_dir", type=str, default="output", help="Directory to save images")
    parser.add_argument("--base_shape_seed", type=none_or_int, default=None, help="Base seed for shapes ('None' for random)")
    parser.add_argument("--base_color_seed", type=none_or_int, default=20, help="Base seed for colors ('None' for random)")
    parser.add_argument("--increment_seeds", action="store_true", help="Vary seeds per image")
    parser.add_argument("--num_figures", type=int, default=5, help="Number of fractal units per image")
    parser.add_argument("--n_edges", type=int, nargs='+', default=[5], help="Number of edges for the fractal shape. Provide one value for fixed, or two values for a range (min max).")
    parser.add_argument("--radius", type=float, default=1.0, help="Base radius for the fractal shape")
    parser.add_argument("--depth", type=int, default=4, help="Recursion depth for the fractal shape")
    parser.add_argument("--amplitude", type=float, default=0.3, help="Amplitude of deflection for the fractal shape")
    parser.add_argument("--size_variation", type=float, nargs=2, default=[0.05, 1], help="Min and max scale for fractal units")
    parser.add_argument("--alpha_range", type=float, nargs=2, default=[0.7, 0.7], help="Min and max alpha for fractal units")
    parser.add_argument("--saturation", type=float, default=0.8, help="HLS saturation")
    parser.add_argument("--lightness", type=float, default=0.5, help="HLS lightness")
    parser.add_argument("--transparent", action="store_true", help="Use transparent background")
    parser.add_argument("--no_random_rotation", action="store_true", help="Disable random rotation")
    parser.add_argument("--no_sort_hues", action="store_true", help="Disable sorting of hues")
    parser.add_argument("--sidecar", action="store_true", help="Write sidecar JSON with metadata")

    args = parser.parse_args()

    if len(args.n_edges) == 1:
        n_edges_fixed = args.n_edges[0]
        n_edges_range = None
    elif len(args.n_edges) == 2:
        n_edges_fixed = None
        n_edges_range = (args.n_edges[0], args.n_edges[1])
    else:
        raise ValueError("--n_edges must be one value or two values (min max)")

    os.makedirs(args.output_dir, exist_ok=True)

    for i in range(args.count):
        shape_seed = args.base_shape_seed + i if (args.increment_seeds and args.base_shape_seed is not None) else args.base_shape_seed
        color_seed = args.base_color_seed + i if (args.increment_seeds and args.base_color_seed is not None) else args.base_color_seed

        # Determine n_edges for this image (for filename only; actual per-unit n_edges is randomized if using a range)
        if n_edges_fixed is not None:
            n_edges = n_edges_fixed
        else:
            n_edges = "varied"

        filename = os.path.join(
            args.output_dir,
            f"fractal_{i:04d}_edges{n_edges}_r{args.radius}_d{args.depth}_a{args.amplitude}"
            f"_ss{shape_seed}_cs{color_seed}_s{args.saturation}_l{args.lightness}"
            f"_sorted{'1' if not args.no_sort_hues else '0'}.png"
        )

        plot_fractals(
            num_figures=args.num_figures,
            n_edges_fixed=n_edges_fixed,
            n_edges_range=n_edges_range,
            radius=args.radius,
            depth=args.depth,
            amplitude=args.amplitude,
            shape_seed=shape_seed,
            color_seed=color_seed,
            random_rotation=not args.no_random_rotation,
            save_path=filename,
            size_variation=tuple(args.size_variation),
            alpha_range=tuple(args.alpha_range),
            saturation=args.saturation,
            lightness=args.lightness,
            transparent_bg=args.transparent,
            sort_hues=not args.no_sort_hues
        )

        # Write sidecar JSON with metadata
        metadata = {
            "index": i,
            "n_edges": n_edges,
            "radius": args.radius,
            "depth": args.depth,
            "amplitude": args.amplitude,
            "shape_seed": shape_seed,
            "color_seed": color_seed,
            "saturation": args.saturation,
            "lightness": args.lightness,
            "sort_hues": not args.no_sort_hues,
            "transparent": args.transparent,
            "num_figures": args.num_figures,
            "size_variation": args.size_variation,
            "alpha_range": args.alpha_range,
            "rotation_enabled": not args.no_random_rotation
        }
        if args.sidecar:
            # Save metadata to a JSON file
            json_path = filename.replace('.png', '.json')
            with open(json_path, 'w') as jf:
                import json
                json.dump(metadata, jf, indent=2)

            print(f"Saved: {filename} and {json_path}")
        else:
            print(f"Saved: {filename}")

if __name__ == "__main__":
    main()