
parameter int MAX_W = 1024;
typedef logic [MAX_W-1:0] logic_max_t;

virtual class sig_ref_base;
    pure virtual function int unsigned width();
    pure virtual function logic_max_t get();
    pure virtual function void put(logic_max_t value);
endclass


interface sig_interface #(int W = 1);
    logic [W-1:0] value;
endinterface

class sig_ref #(int W = 1) extends sig_ref_base;

  virtual sig_interface #(W) sig;

  function new(virtual sig_interface #(W) sig);
    this.sig = sig;
  endfunction

  static function sig_ref_base make(virtual sig_interface #(W) sig);
    sig_ref #(W) tmp;
    tmp = new(sig);
    return tmp;
  endfunction

  function int unsigned width();
    return W;
  endfunction

  function logic_max_t get();
    logic_max_t tmp;
    tmp = '0;
    tmp[W-1:0] = sig.value;
    return tmp;
  endfunction

  function void put(logic_max_t value);
    sig.value = value[W-1:0];
  endfunction

endclass



typedef sig_ref_base ref_map_t[string];

function automatic void grabCommVals(int clk_cycle, ref ref_map_t inputs);
    string read_prefix = "cpp_comm_cyc_";
    string read_suffix = ".txt";
    string read_file;
    int fd;
    string line;
    int idx;
    string value_str;
    string key;
    int value;  

    /**************************************************
    **                  Read arguments               **
    **************************************************/
    read_file = $sformatf("%s%0d%s", read_prefix, clk_cycle, read_suffix);
    fd = pollFile(read_file, "r");

    while ($fgets(line, fd) != 0) begin
        idx = findChar(line, ":");

        if (idx == -1) begin
            $display("Skipping bad line with no colon: %s", line);
        end else begin
            key = line.substr(0, idx - 1);
            value_str = line.substr(idx + 1, line.len() - 1);
            value = value_str.atohex();

            inputs[key].put(value);
        end
    end

    $fclose(fd);
    deleteOldFile(read_file);
    
endfunction

function automatic void writeCommVals(int clk_cycle, ref_map_t outs);
    string write_prefix = "sv_comm_cyc_";
    string write_suffix = ".txt";
    string write_file;

    int fd;
   

    /**************************************************
    **                  Read arguments               **
    **************************************************/
    write_file = $sformatf("%s%0d%s", write_prefix, clk_cycle, write_suffix);
    fd = pollFile(write_file, "w");

    foreach(outs[key]) 
        $fdisplay(fd, "%s:%h", key, outs[key].get());


    $fclose(fd);
    
    
endfunction


function automatic int findChar(string s, byte c);
    for (int i = 0; i < s.len(); i++) begin
        if (s.getc(i) == c)
            return i;
    end

    return -1;
endfunction


function automatic int pollFile(string file, string mode);
    int fd;
    
    while(fd == 0) 
        fd = $fopen(file, mode);

    return fd;

endfunction


function automatic void deleteOldFile(string file);
    int status;

    `ifdef WINDOWS
        status = $system("del /Q .txt");
    `else
        status = $system("rm -f temp.txt");
    `endif

    if (status != 0)
        $warning("Could not delete %s", file);

endfunction



module sv_comm;

    int clk_cycle;


    /**************************************************
    **                                               **
    **************************************************/

    sig_interface #(8)  a_if();
    sig_interface #(32) b_if();

    sig_ref_base refs[string];

    initial begin
        clk_cycle = 0;

        refs["a"] = new sig_ref #(8)::make(a_if);
        refs["b"] = new sig_ref #(32)::make(b_if);



        refs["a"].put(8'hA5);
        refs["b"].put(32'hDEADBEEF);

        $display("a = %0h", refs["a"].get());
        $display("b = %0h", refs["b"].get());
    end

endmodule

