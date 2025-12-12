`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 20:03:56
// Design Name: 
// Module Name: schrodinger_mesi_system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// =======================================================
// schrodinger_mesi_system.v
// Two caches sharing a tiny MESI-like story bus.
// =======================================================
module schrodinger_mesi_system (
    input  wire clk,
    input  wire reset,

    // core A
    input  wire        coreA_read,
    input  wire        coreA_write,
    input  wire [7:0]  coreA_write_data,
    output wire [7:0]  coreA_read_data,
    output wire        coreA_ready,

    // core B
    input  wire        coreB_read,
    input  wire        coreB_write,
    input  wire [7:0]  coreB_write_data,
    output wire [7:0]  coreB_read_data,
    output wire        coreB_ready,

    // story: both cores can decide to open their box
    input  wire        open_box_A,
    input  wire        open_box_B
);

    // Simple shared bus signals.
    wire cacheA_bus_has_copy;
    wire cacheA_bus_write_intent;
    wire cacheB_bus_has_copy;
    wire cacheB_bus_write_intent;

    // Derive snoop inputs:
    wire bus_read_from_other_A  = coreB_read;
    wire bus_write_from_other_A = cacheB_bus_write_intent;

    wire bus_read_from_other_B  = coreA_read;
    wire bus_write_from_other_B = cacheA_bus_write_intent;

    schrodinger_cache cache_A (
        .clk               (clk),
        .reset             (reset),
        .core_read         (coreA_read),
        .core_write        (coreA_write),
        .core_write_data   (coreA_write_data),
        .core_read_data    (coreA_read_data),
        .core_ready        (coreA_ready),
        .bus_read_from_other (bus_read_from_other_A),
        .bus_write_from_other(bus_write_from_other_A),
        .bus_has_copy      (cacheA_bus_has_copy),
        .bus_write_intent  (cacheA_bus_write_intent),
        .open_the_box      (open_box_A)
    );

    schrodinger_cache cache_B (
        .clk               (clk),
        .reset             (reset),
        .core_read         (coreB_read),
        .core_write        (coreB_write),
        .core_write_data   (coreB_write_data),
        .core_read_data    (coreB_read_data),
        .core_ready        (coreB_ready),
        .bus_read_from_other (bus_read_from_other_B),
        .bus_write_from_other(bus_write_from_other_B),
        .bus_has_copy      (cacheB_bus_has_copy),
        .bus_write_intent  (cacheB_bus_write_intent),
        .open_the_box      (open_box_B)
    );

endmodule
