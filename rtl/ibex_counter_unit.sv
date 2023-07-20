module ibex_counter_unit (
    // Clock and Reset
    input   logic        clk_i,
    input   logic        rst_ni,

    /// Counter interface
    output  logic        counter_req_o,
    input   logic        counter_gnt_i,
    input   logic        counter_rvalid_i,
    output  logic        counter_we_o,
    output  logic [31:0] counter_addr_o,
    output  logic [31:0] counter_wdata_o,
    input   logic [31:0] counter_rdata_i,
    input   logic        counter_err_i,

    /// signals from ID stage
    input   logic        counter_unit_req_i,        // request to the counter unit
    input   logic        counter_unit_we_i,         // 1 when writing to a counter, 0 when reading
    input   logic [31:0] adder_result_ex_i,         // address computed in ALU -> from ID/EX
    input   logic [31:0] counter_unit_wdata_i,
    output  logic        counter_unit_resp_valid_o,  // Counter Unit has response from transaction -> to ID/EX

    /// signals to WB stage (WriteBack=0)
    output  logic [31:0] counter_unit_rdata_o,       // requested data
    output  logic        counter_unit_rdata_valid_o // if rdata is valid, write it to RF
);

logic ctrl_update;
logic counter_we_q;
logic [31:0] counter_addr;

typedef enum logic [1:0] {
    IDLE, WAIT_GNT
} counter_fsm_e;

counter_fsm_e counter_fsm_cs, counter_fsm_ns;

assign counter_addr = adder_result_ex_i;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        counter_we_q <= 1'b0;
    end else if (ctrl_update) begin
        counter_we_q <= counter_unit_we_i;
    end
end

always_comb begin
    counter_fsm_ns  = counter_fsm_cs; 
    counter_req_o   = 1'b0;

    ctrl_update     = 1'b0;

    // if a req is sent to the counter memory interface 
    // then we go back to idle state, the id stage is responsible for
    // waiting until the request is served
    unique case (counter_fsm_cs)
        IDLE: begin
            if (counter_unit_req_i) begin
                ctrl_update     = 1'b1;
                counter_req_o   = 1'b1;
                if (counter_gnt_i) begin
                    counter_fsm_ns = IDLE;
                end else begin
                    counter_fsm_ns = WAIT_GNT;
                end
            end
        end

        WAIT_GNT: begin
            if (counter_gnt_i) begin
                counter_req_o   = 1'b1;
                counter_fsm_ns  = IDLE;
            end
        end
    endcase
end

    // registers for FSM
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter_fsm_cs      <= IDLE;
        end else begin
            counter_fsm_cs      <= counter_fsm_ns;
        end
    end

    /////////////
    // Outputs //
    /////////////
    assign counter_unit_rdata_valid_o  = counter_rvalid_i &             // rf write enable
                                         (counter_fsm_cs == IDLE) &
                                         ~counter_we_q;

    assign counter_unit_resp_valid_o   = counter_rvalid_i & 
                                         (counter_fsm_cs == IDLE);

    // output to register file
    assign counter_unit_rdata_o        = counter_rdata_i;

    // ouptut to data interface
    assign counter_addr_o              = counter_addr;
    assign counter_we_o                = counter_unit_we_i;

    assign counter_wdata_o             = counter_unit_wdata_i;

endmodule
    