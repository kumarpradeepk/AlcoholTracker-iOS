import SwiftUI

// GENERATED — do not edit by hand. Regenerate with `scratchpad/gen_icons.py`.
//
// The canvas's icon set: 24x24 stroked line icons, drawn on a shared grid so
// they read as one family. Every path is normalised to absolute M/L/C/Z at
// generation time, so this file needs only a four-command reader rather than a
// general SVG parser, and both platforms consume identical geometry.

struct IconSpec {
    let name: String
    /// Stroke width in the 24x24 viewport; 0 means the icon is filled.
    let strokeWidth: CGFloat
    let filled: Bool
    /// Sub-paths, kept separate so a draw-on can stagger across them.
    let paths: [String]
}

enum AppIcons {
    static let viewport: CGFloat = 24

    static let chevronLeft = IconSpec(
        name: "ChevronLeft", strokeWidth: 2.2, filled: false,
        paths: [
            "M15 5L8 12L15 19"
        ]
    )
    static let chevronRight = IconSpec(
        name: "ChevronRight", strokeWidth: 2.2, filled: false,
        paths: [
            "M9 5L16 12L9 19"
        ]
    )
    static let lock = IconSpec(
        name: "Lock", strokeWidth: 2, filled: false,
        paths: [
            "M7.5 11L16.5 11C17.881 11 19 12.119 19 13.5L19 17.5C19 18.881 17.881 20 16.5 20L7.5 20C6.119 20 5 18.881 5 17.5L5 13.5C5 12.119 6.119 11 7.5 11Z",
            "M8 11L8 8C8 6.953 8.431 5.912 9.172 5.172C9.912 4.431 10.953 4 12 4C13.047 4 14.088 4.431 14.828 5.172C15.569 5.912 16 6.953 16 8L16 11"
        ]
    )
    static let check = IconSpec(
        name: "Check", strokeWidth: 2.6, filled: false,
        paths: [
            "M5 12.5L9.5 17L19 7.5"
        ]
    )
    static let checkBold = IconSpec(
        name: "CheckBold", strokeWidth: 2.8, filled: false,
        paths: [
            "M5 12.5L9.5 17L19 7.5"
        ]
    )
    static let calendar = IconSpec(
        name: "Calendar", strokeWidth: 2, filled: false,
        paths: [
            "M7 5L17 5C18.933 5 20.5 6.567 20.5 8.5L20.5 17C20.5 18.933 18.933 20.5 17 20.5L7 20.5C5.067 20.5 3.5 18.933 3.5 17L3.5 8.5C3.5 6.567 5.067 5 7 5Z",
            "M3.5 9.5L20.5 9.5",
            "M8.5 3L8.5 7",
            "M15.5 3L15.5 7"
        ]
    )
    static let droplet = IconSpec(
        name: "Droplet", strokeWidth: 1.8, filled: false,
        paths: [
            "M12 4.2C14.9 7.7 17 10.3 17 12.5C17 13.809 16.461 15.11 15.536 16.036C14.61 16.961 13.309 17.5 12 17.5C10.691 17.5 9.39 16.961 8.464 16.036C7.539 15.11 7 13.809 7 12.5C7 10.3 9.1 7.7 12 4.2L12 4.2Z"
        ]
    )
    static let dropletFill = IconSpec(
        name: "DropletFill", strokeWidth: 0, filled: true,
        paths: [
            "M12 3C15.5 7.2 18 10.3 18 13C18 14.571 17.353 16.132 16.243 17.243C15.132 18.353 13.571 19 12 19C10.429 19 8.868 18.353 7.757 17.243C6.647 16.132 6 14.571 6 13C6 10.3 8.5 7.2 12 3Z"
        ]
    )
    static let export = IconSpec(
        name: "Export", strokeWidth: 2, filled: false,
        paths: [
            "M12 15L12 4",
            "M8 8L12 4L16 8",
            "M5 15L5 18.5C5 18.827 5.065 19.154 5.19 19.457C5.316 19.759 5.501 20.036 5.732 20.268C5.964 20.499 6.241 20.684 6.543 20.81C6.846 20.935 7.173 21 7.5 21L16.5 21C16.827 21 17.154 20.935 17.457 20.81C17.759 20.684 18.036 20.499 18.268 20.268C18.499 20.036 18.684 19.759 18.81 19.457C18.935 19.154 19 18.827 19 18.5L19 15"
        ]
    )
    static let close = IconSpec(
        name: "Close", strokeWidth: 2.4, filled: false,
        paths: [
            "M6 6L18 18",
            "M18 6L6 18"
        ]
    )
    static let highball = IconSpec(
        name: "Highball", strokeWidth: 1.8, filled: false,
        paths: [
            "M7.5 4L16.5 4L15.4 20L8.6 20L7.5 4Z",
            "M8 8.5L16.2 8.5"
        ]
    )
    static let wine = IconSpec(
        name: "Wine", strokeWidth: 1.8, filled: false,
        paths: [
            "M7.5 3.5L16.5 3.5C16.5 8.1 14.7 10.5 12 10.5C9.3 10.5 7.5 8.1 7.5 3.5Z",
            "M12 10.5L12 19",
            "M8.5 19L15.5 19"
        ]
    )
    static let pint = IconSpec(
        name: "Pint", strokeWidth: 1.8, filled: false,
        paths: [
            "M6.5 5L17.5 5L16.6 19L7.4 19L6.5 5Z",
            "M7.8 12.5L16.2 12.5"
        ]
    )
    static let martini = IconSpec(
        name: "Martini", strokeWidth: 1.8, filled: false,
        paths: [
            "M5.5 4.5L18.5 4.5L12 12L5.5 4.5Z",
            "M12 12L12 19",
            "M8.5 19L15.5 19"
        ]
    )
    static let person = IconSpec(
        name: "Person", strokeWidth: 2, filled: false,
        paths: [
            "M8.5 8C8.5 6.067 10.067 4.5 12 4.5C13.933 4.5 15.5 6.067 15.5 8C15.5 9.933 13.933 11.5 12 11.5C10.067 11.5 8.5 9.933 8.5 8Z",
            "M5 20C6 16.5 8.8 15 12 15C15.2 15 18 16.5 19 20"
        ]
    )
    static let bottle = IconSpec(
        name: "Bottle", strokeWidth: 2, filled: false,
        paths: [
            "M6.5 3.5L17.5 3.5C17.753 3.498 18.007 3.551 18.238 3.653C18.47 3.756 18.68 3.908 18.849 4.096C19.018 4.284 19.148 4.508 19.225 4.75C19.302 4.991 19.328 5.248 19.3 5.5L17.8 22.5C17.775 22.797 17.694 23.089 17.563 23.357C17.432 23.625 17.25 23.868 17.03 24.069C16.81 24.271 16.553 24.431 16.275 24.538C15.996 24.646 15.698 24.701 15.4 24.7L8.6 24.7C8.302 24.701 8.004 24.646 7.725 24.538C7.447 24.431 7.19 24.271 6.97 24.069C6.75 23.868 6.568 23.625 6.437 23.357C6.306 23.089 6.225 22.797 6.2 22.5L4.7 5.5C4.672 5.248 4.698 4.991 4.775 4.75C4.852 4.508 4.982 4.284 5.151 4.096C5.32 3.908 5.53 3.756 5.762 3.653C5.993 3.551 6.247 3.498 6.5 3.5L6.5 3.5Z"
        ]
    )
    static let barChart = IconSpec(
        name: "BarChart", strokeWidth: 2, filled: false,
        paths: [
            "M5 20L5 12",
            "M12 20L12 5",
            "M19 20L19 9"
        ]
    )
    static let home = IconSpec(
        name: "Home", strokeWidth: 2.1, filled: false,
        paths: [
            "M4 11.2L12 4.6L20 11.2L20 20L4 20L4 11.2Z",
            "M9.5 20L9.5 14.5L14.5 14.5L14.5 20"
        ]
    )
    static let sliders = IconSpec(
        name: "Sliders", strokeWidth: 2.1, filled: false,
        paths: [
            "M4 7.5L13 7.5",
            "M17.5 7.5L20 7.5",
            "M4 16.5L7 16.5",
            "M11.5 16.5L20 16.5",
            "M12.8 7.5C12.8 6.285 13.785 5.3 15 5.3C16.215 5.3 17.2 6.285 17.2 7.5C17.2 8.715 16.215 9.7 15 9.7C13.785 9.7 12.8 8.715 12.8 7.5Z",
            "M6.8 16.5C6.8 15.285 7.785 14.3 9 14.3C10.215 14.3 11.2 15.285 11.2 16.5C11.2 17.715 10.215 18.7 9 18.7C7.785 18.7 6.8 17.715 6.8 16.5Z"
        ]
    )
    static let plus = IconSpec(
        name: "Plus", strokeWidth: 2.2, filled: false,
        paths: [
            "M12 5L12 19",
            "M5 12L19 12"
        ]
    )
    static let search = IconSpec(
        name: "Search", strokeWidth: 2.2, filled: false,
        paths: [
            "M4.5 11C4.5 7.41 7.41 4.5 11 4.5C14.59 4.5 17.5 7.41 17.5 11C17.5 14.59 14.59 17.5 11 17.5C7.41 17.5 4.5 14.59 4.5 11Z",
            "M16 16L20.5 20.5"
        ]
    )
    static let trash = IconSpec(
        name: "Trash", strokeWidth: 2, filled: false,
        paths: [
            "M4 7L20 7",
            "M9 7L9 5C9 4.804 9.039 4.607 9.114 4.426C9.189 4.245 9.3 4.078 9.439 3.939C9.578 3.8 9.745 3.689 9.926 3.614C10.107 3.539 10.304 3.5 10.5 3.5L13.5 3.5C13.696 3.5 13.893 3.539 14.074 3.614C14.255 3.689 14.422 3.8 14.561 3.939C14.7 4.078 14.811 4.245 14.886 4.426C14.961 4.607 15 4.804 15 5L15 7",
            "M6.5 7L7.5 19.2C7.525 19.445 7.595 19.685 7.706 19.904C7.817 20.124 7.969 20.322 8.152 20.487C8.335 20.651 8.548 20.782 8.778 20.869C9.008 20.957 9.254 21.001 9.5 21L14.5 21C14.746 21.001 14.992 20.957 15.222 20.869C15.452 20.782 15.665 20.651 15.848 20.487C16.031 20.322 16.183 20.124 16.294 19.904C16.405 19.685 16.475 19.445 16.5 19.2L17.5 7"
        ]
    )

    /// Every icon, for previews and tests.
    static let all: [IconSpec] = [chevronLeft, chevronRight, lock, check, checkBold, calendar, droplet, dropletFill, export, close, highball, wine, pint, martini, person, bottle, barChart, home, sliders, plus, search, trash]
}
