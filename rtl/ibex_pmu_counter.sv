module ibex_pmu_counter (
    input   logic        clk_i,
    input   logic        rst_ni,

    // counter interface 
    output  logic        counter_req_o,
    input   logic        counter_gnt_i,
    input   logic        counter_rvalid_i,
    input   logic        counter_err_i,
    
    output  logic [31:0] counter_addr_o,
    output  logic [31:0] counter_we_o,
    output  logic [31:0] counter_wdata_o,
    input   logic [31:0] counter_rdata_i,

    // signals to/from ID/EX stage
    input   logic        pmc_we_i,          // write enable
    input   logic [31:0] pmc_wdata_i,       // data to write to counter

    output  logic [31:0] pmc_rdata_o,       // requested data
    output  logic        pmc_rdata_valid_o,
    input   logic        pmc_req_i,         // counter request
    input   logic [31:0] adder_result_ex_i, // address computed in ALU

    output  logic        pmc_resp_valid_o     // Counter Unit has response from transaction
);

    typedef enum logic [2:0]  {
    IDLE, PMC_REQ
    } pmc_fsm_e;

    pmc_fsm_e pmc_fsm_cs, pmc_fsm_ns;

    logic ctrl_update;
    logic counter_we_q;
    
    // Is the current data request a read or write?
    // Needed when the PMU responds in the next clock cycle
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            counter_we_q <= 1'b0;
        end else if (ctrl_update) begin
            counter_we_q <= pmc_we_i;
        end
    end


    /////////////
    // PMC FSM //
    /////////////

    always_comb begin
        pmc_fsm_ns      = pmc_fsm_cs;

        counter_req_o   = 1'b0;
        ctrl_update     = 1'b0;

        unique case (pmc_fsm_cs)

            IDLE: begin
                if (pmc_req_i) begin
                    counter_req_o   = 1'b1;

                    ctrl_update     = 1'b1;
                    pmc_fsm_ns      = PMC_REQ;
                end
            end

            PMC_REQ: begin
                if (counter_rvalid_i) begin
                    pmc_fsm_ns      = IDLE;
                end
            end

        endcase
    end


    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            pmc_fsm_cs <= IDLE;
        end else begin
            pmc_fsm_cs <= pmc_fsm_ns;
        end
    end

    /////////////
    // Outputs //
    /////////////

    // To the decoder stage, this signal un-stalls the core
    assign pmc_resp_valid_o     = (pmc_fsm_cs == PMC_REQ) &
                                  counter_rvalid_i;

    assign pmc_rdata_valid_o    = (pmc_fsm_cs == PMC_REQ) & 
                                   counter_rvalid_i & 
                                   ~counter_we_q;

    // output to register file
    assign pmc_rdata_o          = counter_rdata_i;

    // output to counter interface
    assign counter_addr_o       = adder_result_ex_i;
    assign counter_wdata_o      = pmc_wdata_i;
    assign counter_we_o = pmc_we_i;

endmodule