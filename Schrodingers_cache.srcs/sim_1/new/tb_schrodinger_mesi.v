`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 20:04:52
// Design Name: 
// Module Name: tb_schrodinger_mesi
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
// tb_schrodinger_mesi.v
// Testbench: tell the story step by step.
// =======================================================
`timescale 1ns / 1ps

module tb_schrodinger_mesi;

    reg clk;
    reg reset;

    // Core A interface
    reg        coreA_read;
    reg        coreA_write;
    reg [7:0]  coreA_write_data;
    wire [7:0] coreA_read_data;
    wire       coreA_ready;

    // Core B interface
    reg        coreB_read;
    reg        coreB_write;
    reg [7:0]  coreB_write_data;
    wire [7:0] coreB_read_data;
    wire       coreB_ready;

    // Story signals: opening the boxes
    reg open_box_A;
    reg open_box_B;

    // DUT
    schrodinger_mesi_system dut (
        .clk              (clk),
        .reset            (reset),
        .coreA_read       (coreA_read),
        .coreA_write      (coreA_write),
        .coreA_write_data (coreA_write_data),
        .coreA_read_data  (coreA_read_data),
        .coreA_ready      (coreA_ready),
        .coreB_read       (coreB_read),
        .coreB_write      (coreB_write),
        .coreB_write_data (coreB_write_data),
        .coreB_read_data  (coreB_read_data),
        .coreB_ready      (coreB_ready),
        .open_box_A       (open_box_A),
        .open_box_B       (open_box_B)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    // Story
    initial begin
        // Initial conditions
        reset           = 1;
        coreA_read      = 0;
        coreA_write     = 0;
        coreA_write_data= 8'h00;
        coreB_read      = 0;
        coreB_write     = 0;
        coreB_write_data= 8'h00;
        open_box_A      = 0;
        open_box_B      = 0;

        #20;
        reset = 0;

        // Step 1: Core A writes a new cat into its box.
        $display("t=%0t : Core A writes the first cat into its box.", $time);
        coreA_write      = 1;
        coreA_write_data = 8'hCA;
        #10;
        coreA_write      = 0;

        // Step 2: Cat is inside the box, entangled. Nobody has observed it.
        $display("t=%0t : The cat in A's box is now in a Schrödinger state (data + quantum).", $time);

        // Step 3: Core B tries to read. This triggers coherence.
        #20;
        $display("t=%0t : Core B wants to know about the cat. It issues a read.", $time);
        coreB_read = 1;
        #10;
        coreB_read = 0;

        // Step 4: Still, as long as boxes stay closed, cores do not see decoded data.
        #20;
        $display("t=%0t : Boxes are still closed. Cores don't see the true 8-bit cat yet.", $time);
        $display("t=%0t : coreA_read_data=%h ready=%b, coreB_read_data=%h ready=%b",
                 $time, coreA_read_data, coreA_ready, coreB_read_data, coreB_ready);

        // Step 5: Core A opens its box (measures its quantum_state).
        #20;
        $display("t=%0t : Core A decides to open its box and observe the cat.", $time);
        open_box_A = 1;
        #10;
        open_box_A = 0;

        // Step 6: Core A reads again, now it should see a definite decoded cat.
        #20;
        coreA_read = 1;
        #10;
        coreA_read = 0;
        #10;
        $display("t=%0t : After observation, Core A sees cat=%h, ready=%b",
                 $time, coreA_read_data, coreA_ready);

        // Step 7: Core B now opens its own box (its view of the shared cat).
        #20;
        $display("t=%0t : Core B opens its box to see the same cat (coherent shared state).", $time);
        open_box_B = 1;
        #10;
        open_box_B = 0;

        // Step 8: Core B reads after opening the box.
        #20;
        coreB_read = 1;
        #10;
        coreB_read = 0;
        #10;
        $display("t=%0t : Core B now sees cat=%h, ready=%b",
                 $time, coreB_read_data, coreB_ready);

        // Step 9: Core B writes a new cat; this should invalidate A's cat.
        #20;
        $display("t=%0t : Core B writes a new cat, forcing A's box state to Invalid (MESI).", $time);
        coreB_write      = 1;
        coreB_write_data = 8'hBE;
        #10;
        coreB_write      = 0;

        // Step 10: Core A tries to read again; system fetches new cat and entangles it.
        #20;
        coreA_read = 1;
        #10;
        coreA_read = 0;
        #10;
        $display("t=%0t : Core A asked again; a new cat is now in its box, but unobserved.",
                 $time);

        // Finish
        #50;
        $display("t=%0t : Story ends. All boxes closed.", $time);
        $finish;
    end

endmodule
