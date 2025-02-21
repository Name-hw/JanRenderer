# **JanRenderer (WIP)**

Rendering engine built with Vulkan written in C++17 and Zig.

## **Features**

- Rendering engine built with Vulkan
- Written in C++17 and Zig
- Using Depth buffer
- Generate Mipmaps
- MSAA (MultiSampling Anti-Aliasing) support
- Compute Shader

## **Getting Started**

Import the built JanRenderer library and Types.zig. (see src/TestApp).

## **Build**

1. Build using zig's build system in Visual Studio Code (see shortcuts below).
2. Executable program and Library files are created in the bin folder.

### Shortcuts

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
3. Types (including classes, structs, enums, typedefs, etc): PascalCase
4. Enums: PascalCase

## **Credits**

1. [volk](https://github.com/zeux/volk)
2. [glfw](https://github.com/glfw/glfw)
3. [cglm](https://github.com/recp/cglm)
4. [stb](https://github.com/nothings/stb)
5. [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader)
