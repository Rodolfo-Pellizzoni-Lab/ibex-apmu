module ibex_counter_unit (
    // Clock and Reset
    input   logic        clk_i,
    input   logic        rst_ni,

    /// Counter interface
    output  logic        counter_req_o,
    input   logic        counter_rvalid_i,
    output  logic        counter_we_o,
    output  logic [31:0] counter_addr_o,
    output  logic [31:0] counter_wdata_o,
    input   logic [31:0] counter_rdata_i,
    input   logic        counter_err_i    

    /// signals from ID stage
    input   logic        counter_req_i,         // request to the counter unit
    input   logic        counter_we_i,          // 1 when writing to a counter, 0 when reading
    input   logic [31:0] counter_wdata_i,
    input   logic [31:0] adder_result_ex_i,     // address computed in ALU

    /// signals to writeback stage (WriteBack=0)
    output  logic [31:0] counter_rdata_o,       // requested data
    output  logic        counter_rdata_valid_o, // if rdata is valid, write it to RF
);

endmodule
    