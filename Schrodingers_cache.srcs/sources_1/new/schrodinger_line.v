`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 20:02:19
// Design Name: 
// Module Name: schrodinger_line
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
// schrodinger_line.v
// One cache line: the cat (data) and its quantum box.
// =======================================================
module schrodinger_line (
    input  wire        clk,
    input  wire        reset,

    // story inputs
    input  wire        put_cat_in_box,    // write new cat_data + quantum_state
    input  wire [7:0]  new_cat_data,
    input  wire [1:0]  new_quantum_state,

    input  wire        observe_cat,       // "open the box", measure quantum_state
    output reg  [7:0]  decoded_cat_data,  // usable data after measurement
    output reg         cat_is_alive       // 1 = valid decoded data

    // note: quantum_state itself is not directly visible outside
);

    // The hidden quantum_state that decides the cat's fate.
    reg [1:0] quantum_state;     // 2 bits like your idea (small quantum particle)
    reg [7:0] cat_data;          // the raw scrambled data in the box
    reg       entangled;         // 1 means cat_data is still entangled with quantum_state

    // Simple "decoder" depending on quantum_state.
    // In a real design this would be more complex or cryptographic.
    function [7:0] decode_with_quantum;
        input [7:0] in_cat;
        input [1:0] q;
        begin
            case (q)
                2'b00: decode_with_quantum = in_cat;                // no change
                2'b01: decode_with_quantum = {in_cat[3:0], in_cat[7:4]}; // nibble swap
                2'b10: decode_with_quantum = ~in_cat;               // bitwise invert
                2'b11: decode_with_quantum = in_cat ^ 8'hA5;        // xor mask
                default: decode_with_quantum = in_cat;
            endcase
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quantum_state     <= 2'b00;
            cat_data          <= 8'h00;
            entangled         <= 1'b0;
            decoded_cat_data  <= 8'h00;
            cat_is_alive      <= 1'b0;
        end else begin
            // Put a new cat in the box, entangled with a fresh quantum_state.
            if (put_cat_in_box) begin
                cat_data      <= new_cat_data;
                quantum_state <= new_quantum_state;
                entangled     <= 1'b1;    // new superposed state
                cat_is_alive  <= 1'b0;    // not yet observed
            end

            // Observation collapses the state: we "open the box".
            if (observe_cat && entangled) begin
                decoded_cat_data <= decode_with_quantum(cat_data, quantum_state);
                cat_is_alive     <= 1'b1;   // we now have a definite value
                entangled        <= 1'b0;   // collapse: no longer in superposition
            end
        end
    end

endmodule
