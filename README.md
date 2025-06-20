# **JanRenderer (WIP)**

[![.github/workflows/CI.yml](https://github.com/Name-hw/JanRenderer/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Name-hw/JanRenderer/actions/workflows/CI.yml)

Rendering engine built with Vulkan written in C++17 and Zig.

## **Features**

- Rendering engine built with Vulkan
- Written in C++17 and Zig
- Using Depth buffer
- Generate Mipmaps
- MSAA (MultiSampling Anti-Aliasing) support
- Compute Shader

## **Getting Started**

1. Link the JanRenderer, zglfw, zgui library (see [this](https://github.com/Name-hw/JanRenderer/blob/09737e3dbf671c098cf2e8e6a234f6afa62bbfa3/build.zig#L268)).
2. Import JanRenderer.zig. (see [this](https://github.com/Name-hw/JanRenderer/blob/main/src/TestApp/main.zig)).

## **Build**

1. First, install [vcpkg](https://vcpkg.io/) and run 'vcpkg install'.
2. Build using zig's build system in Visual Studio Code (Check detailed build steps with `zig build -h`).
3. Executable program and Library files are created.

### Shortcuts (for Vscode users)

- build: Ctrl+Shift+B
- debug: F5
- run: Ctrl+F5

### Vscode extensions

1. <https://marketplace.visualstudio.com/items?itemName=ziglang.vscode-zig>
2. <https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools>
3. <https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.lldb-dap>

### Libraries

Install the library via vcpkg or zig's build system (see build.zig, build.zig.zon).

### Namings

1. Variables: camelCase
2. Functions: camelCase
3. Types (including objects, structs, enums, typedefs, etc): PascalCase
4. Enums: PascalCase
5. Views (texts displayed in GUI): Title Case
6. ViewModels: PascalCase
7. Initials: UPPERCASE

## **Dependencies**

### Vcpkg

- [volk](https://github.com/zeux/volk)
- [cglm](https://github.com/recp/cglm)
- [stb](https://github.com/nothings/stb)
- [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader)

### Zig build system

- [zmath](https://github.com/zig-gamedev/zmath)
- [zglfw](https://github.com/zig-gamedev/zglfw)
- [zgui](https://github.com/zig-gamedev/zgui)
