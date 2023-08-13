<a href="https://machengine.org/pkg/mach-gpu">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://machengine.org/assets/mach/gpu-full-dark.svg">
        <img alt="mach-gpu" src="https://machengine.org/assets/mach/gpu-full-light.svg" height="150px">
    </picture>
</a>

The WebGPU interface for Zig - providing a truly cross-platform graphics API for Zig (desktop, mobile, and web) with unified low-level graphics & compute backed by Vulkan, Metal, D3D12, and OpenGL (as a best-effort fallback.)

## Features

* Desktop, Steam Deck, (soon) web, and (future) mobile support.
* A modern graphics API similar to Metal, Vulkan, and DirectX 12. 
* Cross-platform shading language
* Compute shaders
* Seamless cross-compilation & zero-fuss installation, as with all Mach libraries.

## Documentation

[machengine.org/pkg/mach-gpu](https://machengine.org/pkg/mach-gpu)

## Join the community

Join the [Mach community on Discord](https://discord.gg/XNG3NZgCqp) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Agpu).

## WebGPU version

Dawn's `webgpu.h` is the **authoritative source** for our API. You can find [the current version we use here](https://github.com/hexops/dawn/blob/generated-2023-06-30.1688174725/out/Debug/gen/include/dawn/webgpu.h).

## Development rules

The rules for translating `webgpu.h` are as follows:

* `WGPUBuffer` -> `gpu.Buffer`:
  * Opaque pointers like these become a `pub const Buffer = opaque {_}` to ensure they are still pointers compatible with the C ABI, while still allowing us to declare methods on them.
  * As a result, a `null`able `Buffer` is represented simply as `?*Buffer`, and any function that would normally take `WGPUBuffer` now takes `*Buffer` as a parameter.
* `WGPUBufferBindingType` -> `gpu.Buffer.BindingType` (purely because it's prefix matches an opaque pointer type, it thus goes into the `Buffer` opaque type.)
* Reserved Zig keywords are translated as follows:
  * `error` -> `err`
  * `type` -> `typ`
  * `opaque` -> `opaq`
* Constant names map using a few simple rules, but it's easiest to describe them with some concrete examples:
  * `RG11B10Ufloat -> rg11_b10_ufloat`
  * `Depth24PlusStencil8 -> depth24_plus_stencil8`
  * `BC5RGUnorm -> bc5_rg_unorm`
  * `BC6HRGBUfloat -> bc6_hrgb_ufloat`
  * `ASTC4x4UnormSrgb -> astc4x4_unorm_srgb`
  * `maxTextureDimension3D -> max_texture_dimension_3d`
* Sometimes an enum will begin with numbers, e.g. `WGPUTextureViewDimension_2DArray`. In this case, we add a prefix so instead of the enum field being `2d_array` it is `dimension_2d_array` (an enum field name must not start with a number in Zig.)
* Dawn extension types `WGPUDawnFoobar` are placed under `gpu.dawn.Foobar`
* Regarding _"undefined"_ terminology:
  * In Zig, _undefined_ usually means _undefined memory_, _undefined behavior_, etc.
  * In WebGPU, _undefined_ commonly refers to JS-style undefined: _an optional value that was not specified_
