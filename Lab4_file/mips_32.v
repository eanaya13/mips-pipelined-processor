`timescale 1ns / 1ps

module mips_32(
    input clk, reset,  
    output [31:0] result
    );
     
    // Hazard and Writeback Wires
    wire [4:0] mem_wb_reg_addr;
    wire [31:0] mem_wb_write_data;
    wire data_hazard_flag;
    wire control_hazard_flag;
    
    // Registers and Immediate Values
    wire [31:0] reg1_data;
    wire [31:0] reg2_data;
    wire [31:0] immediate_val;
    
    // Control Signal Wires
    wire [4:0] dest_reg_addr;
    wire mem_to_reg_ctrl;
    wire [1:0] alu_op_ctrl;
    wire mem_read_ctrl;
    wire mem_write_ctrl;
    wire alu_src_ctrl;
    wire reg_write_ctrl;
    
    
    // Control Signals
    wire [9:0] branch_addr;
    wire [9:0] jump_addr;
    wire branch_taken, jump_signal;
    wire [9:0] pc_plus4_out;
    wire [31:0] instruction_out;
    
    // ID/EX Pipeline Registers
    wire [31:0] id_ex_instr_out;
    wire [31:0] id_ex_reg1_data;
    wire [31:0] id_ex_reg2_data;
    wire [31:0] id_ex_imm_val;
    wire [4:0] id_ex_dest_reg;
    wire id_ex_mem_to_reg;
    wire [1:0] id_ex_alu_op;
    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire id_ex_alu_src;
    wire id_ex_reg_write;
    
    // IF/ID Pipeline Registers
    wire [9:0] if_id_pc_plus4_out;
    wire [31:0] if_id_instr_out;
    
    // ALU and Forwarding Wires
    wire [31:0] mem_wb_write_result;
    wire [1:0] forward_a_ctrl;
    wire [1:0] forward_b_ctrl;
    wire [31:0] alu_input2;
    wire [31:0] alu_result_out;
    
    // EX/MEM Pipeline Registers
    wire [31:0] ex_mem_instr_out;
    wire [4:0] ex_mem_dest_reg;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_alu_input2;
    wire ex_mem_mem_to_reg;
    wire ex_mem_mem_read;
    wire ex_mem_mem_write;
    wire ex_mem_reg_write;
    
    // Data Memory and Writeback Wires
    wire [31:0] mem_read_out;
    
    // MEM/WB Pipeline Registers
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_read_out;
    wire mem_wb_mem_to_reg;
    wire mem_wb_reg_write;
    wire [4:0] mem_wb_dest_reg;
    
    // Final Writeback Data
    wire [31:0] write_back_data_out;
    
    ///////////////////////////// Instruction Fetch    
        IF_pipe_stage IF_unit(
            .clk(clk),
            .reset(reset),
            .en(data_hazard_flag),
            .branch_address(branch_addr),
            .jump_address(jump_addr),
            .branch_taken(branch_taken),
            .jump(jump_signal),
            .pc_plus4(pc_plus4_out),
            .instr(instruction_out)
        );
            
    ///////////////////////////// IF/ID registers
        pipe_reg_en #(10) IF_ID_1(
            .clk(clk),
            .reset(reset),
            .en(data_hazard_flag),
            .flush(control_hazard_flag),
            .d(pc_plus4_out),
            .q(if_id_pc_plus4_out)
        );
    
        pipe_reg_en #(32) IF_ID_2(
            .clk(clk),
            .reset(reset),
            .en(data_hazard_flag),
            .flush(control_hazard_flag),
            .d(instruction_out),
            .q(if_id_instr_out)
        );
        
    ///////////////////////////// Instruction Decode 
        ID_pipe_stage ID(
            .clk(clk),
            .reset(reset),
            .pc_plus4(if_id_pc_plus4_out),
            .instr(if_id_instr_out),
            .mem_wb_reg_write(mem_wb_reg_write),
            .mem_wb_write_reg_addr(mem_wb_dest_reg),
            .mem_wb_write_back_data(write_back_data_out),
            .Data_Hazard(data_hazard_flag),
            .Control_Hazard(control_hazard_flag),
            .reg1(reg1_data),
            .reg2(reg2_data),
            .imm_value(immediate_val),
            .branch_address(branch_addr),
            .jump_address(jump_addr),
            .branch_taken(branch_taken),
            .destination_reg(dest_reg_addr),
            .mem_to_reg(mem_to_reg_ctrl),
            .alu_op(alu_op_ctrl),
            .mem_read(mem_read_ctrl),
            .mem_write(mem_write_ctrl),
            .alu_src(alu_src_ctrl),
            .reg_write(reg_write_ctrl),
            .jump(jump_signal)
        );
                 
    ///////////////////////////// ID/EX registers 
        pipe_reg #(1) ID_EX_11(
            .clk(clk),
            .reset(reset),
            .d(reg_write_ctrl),
            .q(id_ex_reg_write)
        );

        pipe_reg #(1) ID_EX_10(
            .clk(clk),
            .reset(reset),
            .d(alu_src_ctrl),
            .q(id_ex_alu_src)
        );

        pipe_reg #(2) ID_EX_7(
            .clk(clk),
            .reset(reset),
            .d(alu_op_ctrl),
            .q(id_ex_alu_op)
        );

        pipe_reg #(1) ID_EX_6(
            .clk(clk),
            .reset(reset),
            .d(mem_to_reg_ctrl),
            .q(id_ex_mem_to_reg)
        );

        pipe_reg #(1) ID_EX_9(
            .clk(clk),
            .reset(reset),
            .d(mem_write_ctrl),
            .q(id_ex_mem_write)
        );

        pipe_reg #(1) ID_EX_8(
            .clk(clk),
            .reset(reset),
            .d(mem_read_ctrl),
            .q(id_ex_mem_read)
        );

        pipe_reg #(32) ID_EX_4(
            .clk(clk),
            .reset(reset),
            .d(immediate_val),
            .q(id_ex_imm_val)
        );

        pipe_reg #(32) ID_EX_3(
            .clk(clk),
            .reset(reset),
            .d(reg2_data),
            .q(id_ex_reg2_data)
        );

        pipe_reg #(32) ID_EX_2(
            .clk(clk),
            .reset(reset),
            .d(reg1_data),
            .q(id_ex_reg1_data)
        );

        pipe_reg #(5) ID_EX_5(
            .clk(clk),
            .reset(reset),
            .d(dest_reg_addr),
            .q(id_ex_dest_reg)
        );

        pipe_reg #(32) ID_EX_1(
            .clk(clk),
            .reset(reset),
            .d(if_id_instr_out),
            .q(id_ex_instr_out)
        );

    ///////////////////////////// Hazard_detection unit
        Hazard_detection HD(
            .id_ex_mem_read(id_ex_mem_read),
            .id_ex_destination_reg(id_ex_dest_reg),
            .if_id_rs(if_id_instr_out[25:21]),
            .if_id_rt(if_id_instr_out[20:16]),
            .branch_taken(branch_taken),
            .jump(jump_signal),
            .Data_Hazard(data_hazard_flag),
            .IF_Flush(control_hazard_flag)
        );
               
    ///////////////////////////// Execution    
        EX_pipe_stage EX(
            .id_ex_instr(id_ex_instr_out),
            .reg1(id_ex_reg1_data),
            .reg2(id_ex_reg2_data),
            .id_ex_imm_value(id_ex_imm_val),
            .ex_mem_alu_result(ex_mem_alu_result),
            .mem_wb_write_back_result(write_back_data_out),
            .id_ex_alu_src(id_ex_alu_src),
            .id_ex_alu_op(id_ex_alu_op),
            .Forward_A(forward_a_ctrl),
            .Forward_B(forward_b_ctrl),
            .alu_in2_out(alu_input2),
            .alu_result(alu_result_out)
        );    
            
    ///////////////////////////// Forwarding unit
        EX_Forwarding_unit EXFU(
            .ex_mem_reg_write(ex_mem_reg_write),
            .ex_mem_write_reg_addr(ex_mem_dest_reg),
            .id_ex_instr_rs(id_ex_instr_out[25:21]),
            .id_ex_instr_rt(id_ex_instr_out[20:16]),
            .mem_wb_reg_write(mem_wb_reg_write),
            .mem_wb_write_reg_addr(mem_wb_dest_reg),
            .Forward_A(forward_a_ctrl),
            .Forward_B(forward_b_ctrl)
        );
         
    ///////////////////////////// EX/MEM registers
                pipe_reg #(32) EX_MEM_3(
            .clk(clk),
            .reset(reset),
            .d(alu_result_out),
            .q(ex_mem_alu_result)
        );

        pipe_reg #(32) EX_MEM_4(
            .clk(clk),
            .reset(reset),
            .d(alu_input2),
            .q(ex_mem_alu_input2)
        );

        pipe_reg #(1) EX_MEM_6(
            .clk(clk),
            .reset(reset),
            .d(id_ex_mem_read),
            .q(ex_mem_mem_read)
        );

        pipe_reg #(1) EX_MEM_7(
            .clk(clk),
            .reset(reset),
            .d(id_ex_mem_write),
            .q(ex_mem_mem_write)
        );

        pipe_reg #(1) EX_MEM_5(
            .clk(clk),
            .reset(reset),
            .d(id_ex_mem_to_reg),
            .q(ex_mem_mem_to_reg)
        );

        pipe_reg #(1) EX_MEM_8(
            .clk(clk),
            .reset(reset),
            .d(id_ex_reg_write),
            .q(ex_mem_reg_write)
        );

        pipe_reg #(5) EX_MEM_2(
            .clk(clk),
            .reset(reset),
            .d(id_ex_dest_reg),
            .q(ex_mem_dest_reg)
        );

        pipe_reg #(32) EX_MEM_1(
            .clk(clk),
            .reset(reset),
            .d(id_ex_instr_out),
            .q(ex_mem_instr_out)
        );
        
    ///////////////////////////// memory    
        data_memory data_mem(
            .clk(clk),
            .mem_access_addr(ex_mem_alu_result),
            .mem_write_data(ex_mem_alu_input2),
            .mem_write_en(ex_mem_mem_write),
            .mem_read_en(ex_mem_mem_read),
            .mem_read_data(mem_read_out)
        );
    
        ///////////////////////////// MEM/WB registers  
        pipe_reg #(1) MEM_WB_4(
            .clk(clk),
            .reset(reset),
            .d(ex_mem_reg_write),
            .q(mem_wb_reg_write)
        );

        pipe_reg #(5) MEM_WB_5(
            .clk(clk),
            .reset(reset),
            .d(ex_mem_dest_reg),
            .q(mem_wb_dest_reg)
        );

        pipe_reg #(1) MEM_WB_3(
            .clk(clk),
            .reset(reset),
            .d(ex_mem_mem_to_reg),
            .q(mem_wb_mem_to_reg)
        );

        pipe_reg #(32) MEM_WB_1(
            .clk(clk),
            .reset(reset),
            .d(ex_mem_alu_result),
            .q(mem_wb_alu_result)
        );

        pipe_reg #(32) MEM_WB_2(
            .clk(clk),
            .reset(reset),
            .d(mem_read_out),
            .q(mem_wb_mem_read_out)
        );
    
    ///////////////////////////// writeback    
        mux2 #(.mux_width(32)) WB(
            .a(mem_wb_alu_result),
            .b(mem_wb_mem_read_out),
            .sel(mem_wb_mem_to_reg),
            .y(write_back_data_out)        
        );
    
    assign result = write_back_data_out;
        
endmodule
