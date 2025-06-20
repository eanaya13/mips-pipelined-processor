`timescale 1ns / 1ps

module IF_pipe_stage(
    input clk, reset,
    input en,
    input [9:0] branch_address,
    input [9:0] jump_address,
    input branch_taken,
    input jump, 
    output [9:0] pc_plus4,
    output [31:0] instr
);

    // Internal signals
    reg [9:0] program_counter;
    wire [9:0] branch_mux_out;
    wire [9:0] jump_mux_out;

    // Program counter update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            program_counter = 10'b0;
        end else if (en) begin
            program_counter = jump_mux_out;
        end
    end

    // Compute PC + 4
    assign pc_plus4 = program_counter + 10'd4;

    // Instruction memory
    instruction_mem instruction_memory (
        .read_addr(program_counter),
        .data(instr)
    );

    // Branch address multiplexer
    mux2 #(.mux_width(10)) branch_mux (
        .a(pc_plus4),
        .b(branch_address),
        .sel(branch_taken),
        .y(branch_mux_out)
    );

    // Jump address multiplexer
    mux2 #(.mux_width(10)) jump_mux (
        .a(branch_mux_out),
        .b(jump_address),
        .sel(jump),
        .y(jump_mux_out)
    );

endmodule
