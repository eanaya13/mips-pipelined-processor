`timescale 1ns / 1ps

module EX_pipe_stage( 
    input [31:0] id_ex_instr,
    input [31:0] reg1, reg2,
    input [31:0] id_ex_imm_value,
    input [31:0] ex_mem_alu_result,
    input [31:0] mem_wb_write_back_result,
    input id_ex_alu_src,
    input [1:0] id_ex_alu_op,
    input [1:0] Forward_A, Forward_B,
    output [31:0] alu_in2_out,
    output [31:0] alu_result
    );
    
    // Write your code here
    // Internal wires
    wire [31:0] ALUwire1;
    wire [31:0] ALUwire2;
    wire [31:0] alu_input2_temp; 
    wire [3:0] ALU_Control;
    wire zero;

    // Multiplexer for ALU input 1 (Forwarding logic)
    mux4 #(.mux_width(32)) m1 (
        .a(reg1),
        .b(mem_wb_write_back_result),
        .c(ex_mem_alu_result),
        .d(0),
        .sel(Forward_A),
        .y(ALUwire1)
    );

    // Multiplexer for ALU input 2 (Forwarding logic)
    mux4 #(.mux_width(32)) m2 (
        .a(reg2),
        .b(mem_wb_write_back_result),
        .c(ex_mem_alu_result),
        .d(0),
        .sel(Forward_B),
        .y(alu_input2_temp) 
    );

    // ALU input multiplexer (Immediate or forwarded data)
    mux2 #(.mux_width(32)) m3 (
        .a(alu_input2_temp), 
        .b(id_ex_imm_value),
        .sel(id_ex_alu_src),
        .y(ALUwire2)
    );

    // ALU computation
    ALU alu (
        .a(ALUwire1),
        .b(ALUwire2),
        .alu_control(ALU_Control),
        .zero(zero),
        .alu_result(alu_result)
    );

    // ALU Control logic
    ALUControl ALUcontroller (
        .ALUOp(id_ex_alu_op),
        .Function(id_ex_instr[5:0]),
        .ALU_Control(ALU_Control)
    );

    // Assign ALU input 2 for pipeline
    assign alu_in2_out = alu_input2_temp;
    
endmodule
