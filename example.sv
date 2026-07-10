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

        comm.grabCommVals(cycle, delete_read_file);
        comm.writeCommVals(cycle);
        cycle++;


        #10 // wait will IO generates next cycles txt file (since its example we just wait but function polls)
        comm.grabCommVals(cycle, delete_read_file);
        #10; // Allow results to propagate (replace time units with repeat @(posedge clk) or what not) 
        comm.writeCommVals(cycle);
        cycle++;


        fork : POLLING_EXAMPLE 
            begin 
                comm.grabCommVals(cycle, delete_read_file);
            end
            begin
                // showing that we will just wait till next text file is seen which wont happen as we are missing cyc_2
                #50; 
            end
        join_any
        disable POLLING_EXAMPLE;

        cycle++;

        // IO dictates end of communication through
        #10; 
        comm.grabCommVals(cycle, delete_read_file);




    end
endmodule
