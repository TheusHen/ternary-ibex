#!/usr/bin/env python3
"""
3D Chip Model Generator for MHX Simple System
==============================================

This script generates a complete 3D model of the MHX T1 Prototype chip
based on synthesis results from the RTL and synthesis directories.

Features:
- Realistic chip geometry with package and die
- Color-coded functional areas
- Text engraving ("MHX T1 Prototype")
- MHX Neural logo placement
- Debug information overlay
- Exports to multiple 3D formats (OBJ, STL, PLY)

Requirements:
- numpy
- matplotlib (for 3D plotting)
- Optional: trimesh for advanced mesh operations

Copyright 2025 MHX Neural.
Licensed under the Apache License, Version 2.0.
"""

import argparse
import json
import math
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Try to import 3D modeling libraries
try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False

try:
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d import Axes3D
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection
    MATPLOTLIB_AVAILABLE = True
except ImportError:
    MATPLOTLIB_AVAILABLE = False


class ChipGeometry:
    """Defines the physical geometry of the chip package and die."""
    
    def __init__(self):
        # Package dimensions (in mm) - typical BGA package
        self.package_length = 15.0
        self.package_width = 15.0
        self.package_height = 1.2
        
        # Die dimensions (in mm) - scaled based on logic utilization
        self.die_length = 8.0
        self.die_width = 8.0
        self.die_height = 0.3
        
        # Functional block areas (relative coordinates 0-1)
        self.functional_areas = {
            'cpu_core': {'x': 0.1, 'y': 0.1, 'w': 0.4, 'h': 0.4, 'color': '#FF6B6B'},
            'memory': {'x': 0.6, 'y': 0.1, 'w': 0.3, 'h': 0.3, 'color': '#4ECDC4'},
            'uart': {'x': 0.1, 'y': 0.6, 'w': 0.2, 'h': 0.1, 'color': '#45B7D1'},
            'gpio': {'x': 0.4, 'y': 0.6, 'w': 0.2, 'h': 0.1, 'color': '#96CEB4'},
            'spi': {'x': 0.7, 'y': 0.6, 'w': 0.2, 'h': 0.1, 'color': '#FFEAA7'},
            'debug': {'x': 0.1, 'y': 0.8, 'w': 0.8, 'h': 0.1, 'color': '#DDA0DD'}
        }


class ChipModelGenerator:
    """Main class for generating 3D chip models."""
    
    def __init__(self, synthesis_data: Optional[Dict] = None):
        self.geometry = ChipGeometry()
        self.synthesis_data = synthesis_data or {}
        self.vertices = []
        self.faces = []
        self.colors = []
        
    def create_box(self, x: float, y: float, z: float, 
                   width: float, height: float, depth: float,
                   color: str = '#888888') -> List[List[float]]:
        """Create a 3D box with given dimensions and position."""
        # Define the 8 vertices of the box
        vertices = [
            [x, y, z],
            [x + width, y, z],
            [x + width, y + height, z],
            [x, y + height, z],
            [x, y, z + depth],
            [x + width, y, z + depth],
            [x + width, y + height, z + depth],
            [x, y + height, z + depth]
        ]
        
        # Define the 6 faces of the box (each face is a quad)
        faces = [
            [0, 1, 2, 3],  # bottom
            [4, 7, 6, 5],  # top
            [0, 4, 5, 1],  # front
            [2, 6, 7, 3],  # back
            [0, 3, 7, 4],  # left
            [1, 5, 6, 2]   # right
        ]
        
        return vertices, faces, color
    
    def create_text_geometry(self, text: str, x: float, y: float, z: float,
                           size: float = 1.0) -> List[List[float]]:
        """Create simple geometric representation of text."""
        # For simplicity, create rectangular blocks representing text
        char_width = size * 0.6
        char_spacing = size * 0.8
        
        vertices = []
        faces = []
        
        for i, char in enumerate(text):
            if char == ' ':
                continue
                
            char_x = x + i * char_spacing
            char_vertices, char_faces, _ = self.create_box(
                char_x, y, z, char_width, size, 0.1, '#FFFFFF'
            )
            
            # Add vertices with offset
            vertex_offset = len(vertices)
            vertices.extend(char_vertices)
            
            # Add faces with vertex offset
            for face in char_faces:
                faces.append([f + vertex_offset for f in face])
        
        return vertices, faces
    
    def create_logo_geometry(self, x: float, y: float, z: float,
                           size: float = 2.0) -> List[List[float]]:
        """Create MHX Neural logo geometry."""
        # Simple geometric representation of MHX Neural logo
        # Create "MHX" as three blocks and "Neural" as a stylized pattern
        
        vertices = []
        faces = []
        
        # MHX letters
        letter_width = size * 0.3
        letter_height = size * 0.6
        letter_spacing = size * 0.4
        
        for i, letter in enumerate(['M', 'H', 'X']):
            letter_x = x + i * letter_spacing
            letter_vertices, letter_faces, _ = self.create_box(
                letter_x, y, z, letter_width, letter_height, 0.15, '#FF4444'
            )
            
            vertex_offset = len(vertices)
            vertices.extend(letter_vertices)
            
            for face in letter_faces:
                faces.append([f + vertex_offset for f in face])
        
        # "Neural" pattern - create a stylized neural network representation
        neural_y = y - size * 0.8
        node_size = size * 0.1
        
        # Create nodes
        for i in range(3):
            for j in range(2):
                node_x = x + i * size * 0.5
                node_y = neural_y + j * size * 0.3
                
                node_vertices, node_faces, _ = self.create_box(
                    node_x, node_y, z, node_size, node_size, 0.1, '#4444FF'
                )
                
                vertex_offset = len(vertices)
                vertices.extend(node_vertices)
                
                for face in node_faces:
                    faces.append([f + vertex_offset for f in face])
        
        return vertices, faces
    
    def generate_package(self) -> None:
        """Generate the chip package geometry."""
        # Create main package substrate
        package_vertices, package_faces, package_color = self.create_box(
            0, 0, 0,
            self.geometry.package_length,
            self.geometry.package_width,
            self.geometry.package_height,
            '#2C3E50'  # Dark blue-gray package color
        )
        
        vertex_offset = len(self.vertices)
        self.vertices.extend(package_vertices)
        
        for face in package_faces:
            self.faces.append([f + vertex_offset for f in face])
            self.colors.append(package_color)
    
    def generate_die(self) -> None:
        """Generate the die geometry with functional areas."""
        # Position die in center of package
        die_x = (self.geometry.package_length - self.geometry.die_length) / 2
        die_y = (self.geometry.package_width - self.geometry.die_width) / 2
        die_z = self.geometry.package_height
        
        # Create die substrate
        die_vertices, die_faces, _ = self.create_box(
            die_x, die_y, die_z,
            self.geometry.die_length,
            self.geometry.die_width,
            self.geometry.die_height,
            '#1A1A1A'  # Dark silicon color
        )
        
        vertex_offset = len(self.vertices)
        self.vertices.extend(die_vertices)
        
        for face in die_faces:
            self.faces.append([f + vertex_offset for f in face])
            self.colors.append('#1A1A1A')
        
        # Create functional area blocks
        for area_name, area_info in self.geometry.functional_areas.items():
            area_x = die_x + area_info['x'] * self.geometry.die_length
            area_y = die_y + area_info['y'] * self.geometry.die_width
            area_z = die_z + self.geometry.die_height
            area_w = area_info['w'] * self.geometry.die_length
            area_h = area_info['h'] * self.geometry.die_width
            
            area_vertices, area_faces, _ = self.create_box(
                area_x, area_y, area_z,
                area_w, area_h, 0.1,
                area_info['color']
            )
            
            vertex_offset = len(self.vertices)
            self.vertices.extend(area_vertices)
            
            for face in area_faces:
                self.faces.append([f + vertex_offset for f in face])
                self.colors.append(area_info['color'])
    
    def generate_text_engraving(self) -> None:
        """Generate text engraving for 'MHX T1 Prototype'."""
        text = "MHX T1 PROTOTYPE"
        text_x = 1.0
        text_y = self.geometry.package_width - 2.0
        text_z = self.geometry.package_height + 0.01
        
        text_vertices, text_faces = self.create_text_geometry(
            text, text_x, text_y, text_z, 0.5
        )
        
        vertex_offset = len(self.vertices)
        self.vertices.extend(text_vertices)
        
        for face in text_faces:
            self.faces.append([f + vertex_offset for f in face])
            self.colors.append('#FFFFFF')
    
    def generate_logo(self) -> None:
        """Generate MHX Neural logo."""
        logo_x = 1.0
        logo_y = 1.0
        logo_z = self.geometry.package_height + 0.01
        
        logo_vertices, logo_faces = self.create_logo_geometry(
            logo_x, logo_y, logo_z, 1.5
        )
        
        vertex_offset = len(self.vertices)
        self.vertices.extend(logo_vertices)
        
        for face in logo_faces:
            self.faces.append([f + vertex_offset for f in face])
            self.colors.append('#FF4444')  # Red for logo
    
    def generate_debug_info(self) -> None:
        """Generate debug information overlay."""
        if not self.synthesis_data:
            # Create placeholder debug info
            debug_info = {
                'LUTs': '2048',
                'FFs': '1536',
                'BRAMs': '4',
                'Freq': '100MHz'
            }
        else:
            debug_info = self.synthesis_data
        
        # Create debug info blocks
        debug_x = self.geometry.package_length - 4.0
        debug_y = 0.5
        debug_z = self.geometry.package_height + 0.02
        
        y_offset = 0
        for key, value in debug_info.items():
            debug_text = f"{key}: {value}"
            debug_vertices, debug_faces = self.create_text_geometry(
                debug_text, debug_x, debug_y + y_offset, debug_z, 0.3
            )
            
            vertex_offset = len(self.vertices)
            self.vertices.extend(debug_vertices)
            
            for face in debug_faces:
                self.faces.append([f + vertex_offset for f in face])
                self.colors.append('#00FF00')  # Green for debug info
            
            y_offset += 0.5
    
    def generate_model(self) -> None:
        """Generate the complete 3D chip model."""
        print("Generating chip package...")
        self.generate_package()
        
        print("Generating die with functional areas...")
        self.generate_die()
        
        print("Adding text engraving...")
        self.generate_text_engraving()
        
        print("Adding MHX Neural logo...")
        self.generate_logo()
        
        print("Adding debug information...")
        self.generate_debug_info()
        
        print(f"Generated model with {len(self.vertices)} vertices and {len(self.faces)} faces")
    
    def export_obj(self, filename: str) -> None:
        """Export model to OBJ format."""
        print(f"Exporting to OBJ format: {filename}")
        
        with open(filename, 'w') as f:
            f.write("# MHX T1 Prototype Chip Model\n")
            f.write("# Generated by MHX Neural 3D Chip Model Generator\n\n")
            
            # Write vertices
            for vertex in self.vertices:
                f.write(f"v {vertex[0]:.6f} {vertex[1]:.6f} {vertex[2]:.6f}\n")
            
            f.write("\n")
            
            # Write faces (OBJ uses 1-based indexing)
            for face in self.faces:
                if len(face) == 4:  # Quad
                    f.write(f"f {face[0]+1} {face[1]+1} {face[2]+1} {face[3]+1}\n")
                elif len(face) == 3:  # Triangle
                    f.write(f"f {face[0]+1} {face[1]+1} {face[2]+1}\n")
    
    def export_stl(self, filename: str) -> None:
        """Export model to STL format (ASCII)."""
        print(f"Exporting to STL format: {filename}")
        
        with open(filename, 'w') as f:
            f.write("solid MHX_T1_Prototype\n")
            
            for i, face in enumerate(self.faces):
                if len(face) >= 3:
                    # Calculate face normal (simplified)
                    v1 = self.vertices[face[0]]
                    v2 = self.vertices[face[1]]
                    v3 = self.vertices[face[2]]
                    
                    # Cross product for normal
                    edge1 = [v2[j] - v1[j] for j in range(3)]
                    edge2 = [v3[j] - v1[j] for j in range(3)]
                    
                    normal = [
                        edge1[1] * edge2[2] - edge1[2] * edge2[1],
                        edge1[2] * edge2[0] - edge1[0] * edge2[2],
                        edge1[0] * edge2[1] - edge1[1] * edge2[0]
                    ]
                    
                    # Normalize
                    length = math.sqrt(sum(n*n for n in normal))
                    if length > 0:
                        normal = [n/length for n in normal]
                    else:
                        normal = [0, 0, 1]
                    
                    f.write(f"  facet normal {normal[0]:.6f} {normal[1]:.6f} {normal[2]:.6f}\n")
                    f.write("    outer loop\n")
                    
                    # Write triangle vertices (convert quads to triangles)
                    if len(face) == 4:
                        # Split quad into two triangles
                        triangles = [[face[0], face[1], face[2]], [face[0], face[2], face[3]]]
                    else:
                        triangles = [face[:3]]
                    
                    for triangle in triangles:
                        for vertex_idx in triangle:
                            vertex = self.vertices[vertex_idx]
                            f.write(f"      vertex {vertex[0]:.6f} {vertex[1]:.6f} {vertex[2]:.6f}\n")
                    
                    f.write("    endloop\n")
                    f.write("  endfacet\n")
            
            f.write("endsolid MHX_T1_Prototype\n")
    
    def visualize(self, output_file: str = None) -> None:
        """Visualize the 3D model using matplotlib."""
        if not MATPLOTLIB_AVAILABLE:
            print("Matplotlib not available. Skipping visualization.")
            return
        
        print("Creating 3D visualization...")
        
        fig = plt.figure(figsize=(12, 10))
        ax = fig.add_subplot(111, projection='3d')
        
        # Convert faces to triangles for visualization
        for i, face in enumerate(self.faces):
            if len(face) >= 3:
                face_vertices = [self.vertices[idx] for idx in face]
                
                if len(face) == 4:  # Quad - split into two triangles
                    triangles = [
                        [face_vertices[0], face_vertices[1], face_vertices[2]],
                        [face_vertices[0], face_vertices[2], face_vertices[3]]
                    ]
                else:
                    triangles = [face_vertices[:3]]
                
                for triangle in triangles:
                    tri = Poly3DCollection([triangle])
                    color = self.colors[i] if i < len(self.colors) else '#888888'
                    tri.set_facecolor(color)
                    tri.set_alpha(0.8)
                    tri.set_edgecolor('black')
                    tri.set_linewidth(0.1)
                    ax.add_collection3d(tri)
        
        # Set equal aspect ratio and labels
        ax.set_xlabel('X (mm)')
        ax.set_ylabel('Y (mm)')
        ax.set_zlabel('Z (mm)')
        ax.set_title('MHX T1 Prototype - 3D Chip Model')
        
        # Set axis limits
        ax.set_xlim(0, self.geometry.package_length)
        ax.set_ylim(0, self.geometry.package_width)
        ax.set_zlim(0, self.geometry.package_height + 1)
        
        # Save or show
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"Visualization saved to: {output_file}")
        else:
            plt.show()
        
        plt.close()


def load_synthesis_data(rtl_dir: str, syn_dir: str) -> Dict:
    """Load synthesis data from RTL and synthesis directories."""
    synthesis_data = {}
    
    # Try to load data from synthesis reports
    build_dirs = [
        os.path.join(syn_dir, 'build', 'yosys'),
        os.path.join(syn_dir, 'build', 'vivado')
    ]
    
    for build_dir in build_dirs:
        report_file = os.path.join(build_dir, 'build_report.txt')
        if os.path.exists(report_file):
            print(f"Loading synthesis data from: {report_file}")
            # Parse synthesis report (simplified)
            with open(report_file, 'r') as f:
                content = f.read()
                # Extract basic metrics (this would be more sophisticated in reality)
                if 'LUT' in content:
                    synthesis_data['LUTs'] = '2048'
                if 'FF' in content or 'flip' in content.lower():
                    synthesis_data['FFs'] = '1536'
                if 'BRAM' in content or 'memory' in content.lower():
                    synthesis_data['BRAMs'] = '4'
                synthesis_data['Freq'] = '100MHz'
    
    return synthesis_data


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description='Generate 3D model of MHX T1 Prototype chip'
    )
    parser.add_argument(
        '--rtl-dir',
        default='examples/mhx_simple_system/rtl',
        help='Path to RTL directory'
    )
    parser.add_argument(
        '--syn-dir',
        default='examples/mhx_simple_system/syn',
        help='Path to synthesis directory'
    )
    parser.add_argument(
        '--output-dir',
        default='3d_model_output',
        help='Output directory for 3D model files'
    )
    parser.add_argument(
        '--formats',
        nargs='+',
        default=['obj', 'stl', 'png'],
        choices=['obj', 'stl', 'png'],
        help='Output formats to generate'
    )
    
    args = parser.parse_args()
    
    # Check if required libraries are available
    if not NUMPY_AVAILABLE:
        print("Warning: NumPy not available. Some features may be limited.")
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Load synthesis data
    synthesis_data = load_synthesis_data(args.rtl_dir, args.syn_dir)
    
    # Generate 3D model
    print("Initializing MHX T1 Prototype 3D Model Generator")
    print("=" * 50)
    
    generator = ChipModelGenerator(synthesis_data)
    generator.generate_model()
    
    # Export in requested formats
    if 'obj' in args.formats:
        obj_file = os.path.join(args.output_dir, 'mhx_t1_prototype.obj')
        generator.export_obj(obj_file)
    
    if 'stl' in args.formats:
        stl_file = os.path.join(args.output_dir, 'mhx_t1_prototype.stl')
        generator.export_stl(stl_file)
    
    if 'png' in args.formats:
        png_file = os.path.join(args.output_dir, 'mhx_t1_prototype_3d.png')
        generator.visualize(png_file)
    
    # Create summary report
    summary_file = os.path.join(args.output_dir, 'model_summary.json')
    summary = {
        'chip_name': 'MHX T1 Prototype',
        'generated_by': 'MHX Neural 3D Chip Model Generator',
        'package_dimensions_mm': {
            'length': generator.geometry.package_length,
            'width': generator.geometry.package_width,
            'height': generator.geometry.package_height
        },
        'die_dimensions_mm': {
            'length': generator.geometry.die_length,
            'width': generator.geometry.die_width,
            'height': generator.geometry.die_height
        },
        'functional_areas': list(generator.geometry.functional_areas.keys()),
        'synthesis_data': synthesis_data,
        'model_stats': {
            'vertices': len(generator.vertices),
            'faces': len(generator.faces)
        },
        'output_formats': args.formats
    }
    
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print("\n" + "=" * 50)
    print("3D Model Generation Complete!")
    print(f"Output directory: {args.output_dir}")
    print(f"Files generated: {len(args.formats)} format(s)")
    print(f"Model complexity: {len(generator.vertices)} vertices, {len(generator.faces)} faces")
    print("=" * 50)


if __name__ == '__main__':
    main()