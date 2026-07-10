`include "sv_comm.sv"

module adder #(
    parameter int W = 4
) (
    input  wire [W - 1:0] a,
    input  wire [W - 1:0] b,

    output wire [W - 1:0] s,
    output wire           c
); 

    assign {c, s} = a + b; 
endmodule



module example;
    localparam int W = 4;
    sig_interface #(W) a_if();
    sig_interface #(W) b_if();
    sig_interface #(W) s_if();
    sig_interface #(1) c_if();

    sv_comm comm;
    int cycle;
    bit delete_read_file = 0;

    adder #(
        .W(W)
    ) dut (
        // Data Inputs
        .a(a_if.value),
        .b(b_if.value),

        // Data Outputs
        .s(s_if.value),
        .c(c_if.value)
    );

    initial begin
        //Instant reference holder
        comm = new();

        // Add Dut signals we want to track
        comm.add_in("a", sig_ref #(W)::make(a_if));
        comm.add_in("b", sig_ref #(W)::make(b_if));
        comm.add_out("s", sig_ref #(W)::make(s_if));
        comm.add_out("c", sig_ref #(1)::make(c_if));

        cycle = 0;
        forever begin
            grabCommVals(cycle, comm.in_refs, delete_read_file);
            writeCommVals(cycle, comm.out_refs);
            cycle++;
            #5;
        end
    end
endmodule
