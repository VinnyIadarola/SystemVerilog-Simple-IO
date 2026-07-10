/**********************************************************
***                 Custom Signal References            ***
**********************************************************/
parameter int MAX_W = 1024;
typedef logic [MAX_W-1:0] logic_max_t;

/** Instantiate each DUT in/out as a sig_interface type
  * These will be used to communicate between the SV and IO
  * Needed to we can create a array of signals to reference
*/
interface sig_interface #(int unsigned W = 1);
    logic [W-1:0] value;
endinterface



virtual class sig_ref_base;
    pure virtual function int unsigned width();
    pure virtual function logic_max_t get();
    pure virtual function void put(logic_max_t value);
endclass


/** You can either make the sig ref on its own using new or use the make call 
  * While adding the ref to simplify creating more redudant sig names.
  * 
  * Interface manually with the references using put for inputs and get for outputs
*/
class sig_ref #(int unsigned W = 1) extends sig_ref_base;

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




/**********************************************************
***                Verif Helper Functions               ***
**********************************************************/
//to make portable between CLI and MoDELSIm
string COMM_DIR_ABS_PATH = "ERR pls fill out";


function automatic int findChar(string s, byte c);
    for (int i = 0; i < s.len(); i++) begin
        if (s.getc(i) == c)
            return i;
    end
    return -1;
endfunction


function automatic int pollFile(string file, string mode);
    int fd;
    while (fd == 0)
        fd = $fopen(file, mode);
    return fd;
endfunction


function automatic void deleteOldFile(string file);
    int status;
    `ifdef WINDOWS
        status = $system($sformatf("del /Q \"%s%s\"", COMM_DIR_ABS_PATH, file));
    `else
        status = $system($sformatf("rm -f \"%s%s\"", COMM_DIR_ABS_PATH, file));
    `endif
    if (status != 0)
        $warning("Could not delete %s", file);
endfunction


/**********************************************************
***                Verif Comm Controller                ***
**********************************************************/
class sv_comm;
    typedef sig_ref_base ref_map_t[string];

    ref_map_t in_refs;
    ref_map_t out_refs;

    function void add_in(string name, sig_ref_base signal_ref);
        in_refs[name] = signal_ref;
    endfunction

    function void add_out(string name, sig_ref_base signal_ref);
        out_refs[name] = signal_ref;
    endfunction

    function void grabCommVals(
        int clk_cycle,
        bit delete_read_file
    );
        string read_file;
        string line;
        string value_str;
        string key;
        int fd;
        int idx;
        logic_max_t value;

    
        read_file = $sformatf(
            "%s/IO_comm_cyc_%0d.txt",
            COMM_DIR_ABS_PATH,
            clk_cycle
        );
        fd = pollFile(read_file, "r");

        while ($fgets(line, fd) != 0) begin
            idx = findChar(line, ":");
            if (idx == -1) begin
                $display("Skipping bad line with no colon: %s", line);
                continue;
            end 

            key = line.substr(0, idx - 1);
            value_str = line.substr(idx + 1, line.len() - 1);
            value = value_str.atohex();
            if (in_refs.exists(key))
                in_refs[key].put(value);
            else
                $warning("Ignoring unknown input signal '%s'", key);
        end

        $fclose(fd);

        if (delete_read_file)
            deleteOldFile(read_file);
    endfunction




    function void writeCommVals(int clk_cycle);
        string write_file;
        int fd;

        write_file = $sformatf(
            "%s/sv_comm_cyc_%0d.txt",
            COMM_DIR_ABS_PATH, 
            clk_cycle
        );

        fd = pollFile(write_file, "w");
        foreach (out_refs[key])
            $fdisplay(fd, "%s:%0h", key, out_refs[key].get());
        $fclose(fd);
    endfunction

endclass
