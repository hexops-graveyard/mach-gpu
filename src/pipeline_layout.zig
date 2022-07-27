const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const impl = @import("interface.zig").impl;

pub const PipelineLayout = *opaque {
    pub inline fn setLabel(pipeline_layout: PipelineLayout, label: [*:0]const u8) void {
        impl.pipelineLayoutSetLabel(pipeline_layout, label);
    }

    pub inline fn reference(pipeline_layout: PipelineLayout) void {
        impl.pipelineLayoutReference(pipeline_layout);
    }

    pub inline fn release(pipeline_layout: PipelineLayout) void {
        impl.pipelineLayoutRelease(pipeline_layout);
    }
};

pub const PipelineLayoutDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    bind_group_layout_count: u32,
    bind_group_layouts: [*]const BindGroupLayout,
};
