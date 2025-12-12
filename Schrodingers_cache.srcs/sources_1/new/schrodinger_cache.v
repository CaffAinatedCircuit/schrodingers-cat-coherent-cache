`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 20:03:02
// Design Name: 
// Module Name: schrodinger_cache
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
// schrodinger_cache.v
// Simple 1-line cache with MESI-like states + Schrödinger line.
// =======================================================
module schrodinger_cache (
    input  wire        clk,
    input  wire        reset,

    // Core-side interface (simple, 1 address)
    input  wire        core_read,
    input  wire        core_write,
    input  wire [7:0]  core_write_data,
    output reg  [7:0]  core_read_data,
    output reg         core_ready,

    // Coherence bus (shared, very simplified)
    input  wire        bus_read_from_other,     // other cache is reading our address
    input  wire        bus_write_from_other,    // other cache is writing our address
    output reg         bus_has_copy,           // we assert if we have a shared copy
    output reg         bus_write_intent,       // we assert when we intend to own/modify

    // Story signal: measurement of cat
    input  wire        open_the_box
);

    // MESI states encoded as 2 bits.
    localparam M = 2'b00;  // Modified
    localparam E = 2'b01;  // Exclusive
    localparam S = 2'b10;  // Shared
    localparam I = 2'b11;  // Invalid

    reg [1:0] box_state;      // MESI state of "our box"
    reg       line_valid;     // do we have any cat in this box?

    // Schrödinger line instance: the cat and quantum state.
    reg        put_cat_in_box;
    reg [7:0]  new_cat_data;
    reg [1:0]  new_quantum_state;
    wire [7:0] decoded_cat_data;
    wire       cat_is_alive;

    schrodinger_line cat_box (
        .clk             (clk),
        .reset           (reset),
        .put_cat_in_box  (put_cat_in_box),
        .new_cat_data    (new_cat_data),
        .new_quantum_state(new_quantum_state),
        .observe_cat     (open_the_box),
        .decoded_cat_data(decoded_cat_data),
        .cat_is_alive    (cat_is_alive)
    );

    // For this toy, quantum_state is simple and deterministic.
    // In a real system this could come from a QPU or PRNG.
    reg [1:0] quantum_seed;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            box_state        <= I;
            line_valid       <= 1'b0;
            put_cat_in_box   <= 1'b0;
            new_cat_data     <= 8'h00;
            new_quantum_state<= 2'b00;
            core_read_data   <= 8'h00;
            core_ready       <= 1'b0;
            bus_has_copy     <= 1'b0;
            bus_write_intent <= 1'b0;
            quantum_seed     <= 2'b01;
        end else begin
            // defaults each cycle
            put_cat_in_box   <= 1'b0;
            core_ready       <= 1'b0;
            bus_has_copy     <= 1'b0;
            bus_write_intent <= 1'b0;

            // simple evolving quantum seed
            quantum_seed <= quantum_seed + 2'b01;

            // Snoop bus: if other cache writes, we invalidate our box.
            if (bus_write_from_other && line_valid) begin
                box_state  <= I;
                line_valid <= 1'b0;
            end

            // If other cache only reads and we have data, we may go to Shared.
            if (bus_read_from_other && line_valid &&
                (box_state == E || box_state == M)) begin
                box_state <= S;
            end

            // Core read/write behavior (one address, always hits when valid).
            if (core_read) begin
                // If we don't have it, pretend to fetch from memory.
                if (!line_valid || box_state == I) begin
                    // "Fetch from memory": put a new cat in the box
                    put_cat_in_box    <= 1'b1;
                    new_cat_data      <= 8'h42;       // story constant
                    new_quantum_state <= quantum_seed;
                    box_state         <= E;           // we are the only one (exclusive)
                    line_valid        <= 1'b1;
                    // no data yet until box is opened
                    core_read_data    <= 8'h00;
                    core_ready        <= 1'b0;
                end else begin
                    // We have the cat; if box is opened, give decoded data.
                    if (cat_is_alive) begin
                        core_read_data <= decoded_cat_data;
                        core_ready     <= 1'b1;
                    end else begin
                        // Cat still in superposition from core's POV.
                        core_read_data <= 8'h00;
                        core_ready     <= 1'b0;
                    end

                    // If we are exclusive and someone else may be reading,
                    // we announce we have a copy (for a real bus, this would
                    // be driven in a separate phase).
                    if (box_state == E || box_state == M || box_state == S)
                        bus_has_copy <= 1'b1;
                end
            end

            if (core_write) begin
                // On write, we intend to own/modify the box.
                bus_write_intent <= 1'b1;

                // If invalid, pretend to fetch then write.
                if (!line_valid || box_state == I) begin
                    put_cat_in_box    <= 1'b1;
                    new_cat_data      <= core_write_data;
                    new_quantum_state <= quantum_seed;
                    box_state         <= M;
                    line_valid        <= 1'b1;
                end else begin
                    // Modify existing cat in the box.
                    put_cat_in_box    <= 1'b1;
                    new_cat_data      <= core_write_data;
                    new_quantum_state <= quantum_seed;
                    box_state         <= M;
                end

                core_ready <= 1'b1;
            end
        end
    end

endmodule
