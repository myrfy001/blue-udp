

module XdmaUdpIpArpEthCmacRxTxWrapper#(
    parameter PCIE_GT_LANE_WIDTH = 16,
    parameter CMAC_GT_LANE_WIDTH = 4
)(
    input pcie_clk_n,
    input pcie_clk_p,
    input pcie_rst_n,

    output [PCIE_GT_LANE_WIDTH - 1 : 0] pci_exp_txn,
    output [PCIE_GT_LANE_WIDTH - 1 : 0] pci_exp_txp,
    input  [PCIE_GT_LANE_WIDTH - 1 : 0] pci_exp_rxn,
    input  [PCIE_GT_LANE_WIDTH - 1 : 0] pci_exp_rxp,

    output user_lnk_up,

    input qsfp1_ref_clk_p,
    input qsfp1_ref_clk_n,

    input qsfp2_ref_clk_p,
    input qsfp2_ref_clk_n,

    input  [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp1_rxn_in,
    input  [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp1_rxp_in,
    output [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp1_txn_out,
    output [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp1_txp_out,

    input  [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp2_rxn_in,
    input  [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp2_rxp_in,
    output [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp2_txn_out,
    output [CMAC_GT_LANE_WIDTH - 1 : 0] qsfp2_txp_out
);

    localparam XDMA_AXIS_TDATA_WIDTH = 512;
    localparam XDMA_AXIS_TKEEP_WIDTH = 64;
    localparam XDMA_AXIS_TUSER_WIDTH = 1;

    wire xdma_sys_clk, xdma_sys_clk_gt;
    wire xdma_sys_rst_n;

    wire xdma_axi_aclk;
    wire xdma_axi_aresetn;
    wire clk_wiz_locked;

    wire udp_clk, udp_reset;

    wire cmac_init_clk, cmac_sys_reset;

    wire xdma_c2h_axis_tready;
    wire xdma_c2h_axis_tvalid;
    wire xdma_c2h_axis_tlast;
    wire [XDMA_AXIS_TDATA_WIDTH - 1 : 0] xdma_c2h_axis_tdata;
    wire [XDMA_AXIS_TKEEP_WIDTH - 1 : 0] xdma_c2h_axis_tkeep;

    wire xdma_h2c_axis_tvalid;
    wire xdma_h2c_axis_tready;
    wire xdma_h2c_axis_tlast;
    wire [XDMA_AXIS_TDATA_WIDTH - 1 : 0] xdma_h2c_axis_tdata;
    wire [XDMA_AXIS_TKEEP_WIDTH - 1 : 0] xdma_h2c_axis_tkeep;

    wire xdma_rx_axis_tready;
    wire xdma_rx_axis_tvalid;
    wire xdma_rx_axis_tlast;
    wire [XDMA_AXIS_TDATA_WIDTH - 1 : 0] xdma_rx_axis_tdata;
    wire [XDMA_AXIS_TKEEP_WIDTH - 1 : 0] xdma_rx_axis_tkeep;
    wire [XDMA_AXIS_TUSER_WIDTH - 1 : 0] xdma_rx_axis_tuser;

    wire xdma_tx_axis_tvalid;
    wire xdma_tx_axis_tready;
    wire xdma_tx_axis_tlast;
    wire [XDMA_AXIS_TDATA_WIDTH - 1 : 0] xdma_tx_axis_tdata;
    wire [XDMA_AXIS_TKEEP_WIDTH - 1 : 0] xdma_tx_axis_tkeep;
    wire [XDMA_AXIS_TUSER_WIDTH - 1 : 0] xdma_tx_axis_tuser;

    // PCIe Clock buffer
    IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(xdma_sys_clk_gt), .ODIV2(xdma_sys_clk), .I(pcie_clk_p), .CEB(1'b0), .IB(pcie_clk_n));
    // PCIe Reset buffer
    IBUF   sys_reset_n_ibuf (.O(xdma_sys_rst_n), .I(pcie_rst_n));
    xdma_0 xdma_inst (
        .sys_clk    (xdma_sys_clk),                  // input wire sys_clk
        .sys_clk_gt (xdma_sys_clk_gt),               // input wire sys_clk_gt
        .sys_rst_n  (xdma_sys_rst_n),                // input wire sys_rst_n
        .user_lnk_up(user_lnk_up),                   // output wire user_lnk_up
        .pci_exp_txp(pci_exp_txp),                   // output wire [15 : 0] pci_exp_txp
        .pci_exp_txn(pci_exp_txn),                   // output wire [15 : 0] pci_exp_txn
        .pci_exp_rxp(pci_exp_rxp),                   // input wire [15 : 0] pci_exp_rxp
        .pci_exp_rxn(pci_exp_rxn),                   // input wire [15 : 0] pci_exp_rxn
        
        .axi_aclk   (xdma_axi_aclk),                 // output wire axi_aclk
        .axi_aresetn(xdma_axi_aresetn),              // output wire axi_aresetn
        .usr_irq_req(0),                             // input wire [0 : 0] usr_irq_req
        .usr_irq_ack(),                              // output wire [0 : 0] usr_irq_ack
        
        .s_axis_c2h_tdata_0 (xdma_c2h_axis_tdata),   // input wire [511 : 0] s_axis_c2h_tdata_0
        .s_axis_c2h_tlast_0 (xdma_c2h_axis_tlast),   // input wire s_axis_c2h_tlast_0
        .s_axis_c2h_tvalid_0(xdma_c2h_axis_tvalid),  // input wire s_axis_c2h_tvalid_0
        .s_axis_c2h_tready_0(xdma_c2h_axis_tready),  // output wire s_axis_c2h_tready_0
        .s_axis_c2h_tkeep_0 (xdma_c2h_axis_tkeep),   // input wire [63 : 0] s_axis_c2h_tkeep_0
        
        .m_axis_h2c_tdata_0 (xdma_h2c_axis_tdata),   // output wire [511 : 0] m_axis_h2c_tdata_0
        .m_axis_h2c_tlast_0 (xdma_h2c_axis_tlast),   // output wire m_axis_h2c_tlast_0
        .m_axis_h2c_tvalid_0(xdma_h2c_axis_tvalid),  // output wire m_axis_h2c_tvalid_0
        .m_axis_h2c_tready_0(xdma_h2c_axis_tready),  // input wire m_axis_h2c_tready_0
        .m_axis_h2c_tkeep_0 (xdma_h2c_axis_tkeep)    // output wire [63 : 0] m_axis_h2c_tkeep_0
    );

    clk_wiz_0 clk_wiz_inst (
        // Clock out ports
        .clk_out1(udp_clk),           // output clk_out1
        .clk_out2(cmac_init_clk),     // output clk_out2
        // Status and control signals
        .resetn(xdma_axi_aresetn),    // input resetn
        .locked(clk_wiz_locked),      // output locked
        // Clock in ports
        .clk_in1(xdma_axi_aclk)       // input clk_in1
    );
    assign udp_reset = ~ clk_wiz_locked;
    assign cmac_sys_reset = ~ clk_wiz_locked;

    axis_data_fifo_0 tx_axis_sync_fifo (
        .s_axis_aresetn(xdma_axi_aclk   ),      // input wire s_axis_aresetn
        .s_axis_aclk   (xdma_axi_aresetn),      // input wire s_axis_aclk
        
        .s_axis_tvalid(xdma_h2c_axis_tvalid),   // input wire s_axis_tvalid
        .s_axis_tready(xdma_h2c_axis_tready),   // output wire s_axis_tready
        .s_axis_tdata (xdma_h2c_axis_tdata ),   // input wire [511 : 0] s_axis_tdata
        .s_axis_tkeep (xdma_h2c_axis_tkeep ),   // input wire [63 : 0] s_axis_tkeep
        .s_axis_tlast (xdma_h2c_axis_tlast ),   // input wire s_axis_tlast
        .s_axis_tuser (1'b0                ),   // input wire [0 : 0] s_axis_tuser
        
        .m_axis_aclk  (udp_clk),                // input wire m_axis_aclk
        .m_axis_tvalid(xdma_tx_axis_tvalid),    // output wire m_axis_tvalid
        .m_axis_tready(xdma_tx_axis_tready),    // input wire m_axis_tready
        .m_axis_tdata (xdma_tx_axis_tdata),     // output wire [511 : 0] m_axis_tdata
        .m_axis_tkeep (xdma_tx_axis_tkeep),     // output wire [63 : 0] m_axis_tkeep
        .m_axis_tlast (xdma_tx_axis_tlast),     // output wire m_axis_tlast
        .m_axis_tuser (xdma_tx_axis_tuser)      // output wire [0 : 0] m_axis_tuser
    );

    axis_data_fifo_0 rx_axis_sync_fifo (
        .s_axis_aresetn(udp_clk),               // input wire s_axis_aresetn
        .s_axis_aclk   (clk_wiz_locked),        // input wire s_axis_aclk
        
        .s_axis_tvalid(xdma_rx_axis_tvalid),    // input wire s_axis_tvalid
        .s_axis_tready(xdma_rx_axis_tready),    // output wire s_axis_tready
        .s_axis_tdata (xdma_rx_axis_tdata),     // input wire [511 : 0] s_axis_tdata
        .s_axis_tkeep (xdma_rx_axis_tkeep),     // input wire [63 : 0] s_axis_tkeep
        .s_axis_tlast (xdma_rx_axis_tlast),     // input wire s_axis_tlast
        .s_axis_tuser (xdma_rx_axis_tuser),     // input wire [0 : 0] s_axis_tuser
        
        .m_axis_aclk  (xdma_axi_aclk),          // input wire m_axis_aclk
        .m_axis_tvalid(xdma_c2h_axis_tvalid),   // output wire m_axis_tvalid
        .m_axis_tready(xdma_c2h_axis_tready),   // input wire m_axis_tready
        .m_axis_tdata (xdma_c2h_axis_tdata),    // output wire [511 : 0] m_axis_tdata
        .m_axis_tkeep (xdma_c2h_axis_tkeep),    // output wire [63 : 0] m_axis_tkeep
        .m_axis_tlast (xdma_c2h_axis_tlast),    // output wire m_axis_tlast
        .m_axis_tuser ()     // output wire [0 : 0] m_axis_tuser
    );


    UdpIpArpEthCmacRxTxWrapper#(
        CMAC_GT_LANE_WIDTH,
        XDMA_AXIS_TDATA_WIDTH,
        XDMA_AXIS_TKEEP_WIDTH,
        XDMA_AXIS_TUSER_WIDTH
    ) udpIpArpEthCmacRxTxWrapperInst(

        .udp_clk  (udp_clk  ),
        .udp_reset(udp_reset),

        .gt1_ref_clk_p(qsfp1_ref_clk_p   ),
        .gt1_ref_clk_n(qsfp1_ref_clk_n   ),
        .gt1_init_clk (cmac_init_clk     ),
        .gt1_sys_reset(cmac_sys_reset    ),

        .gt2_ref_clk_p(qsfp2_ref_clk_p   ),
        .gt2_ref_clk_n(qsfp2_ref_clk_n   ),
        .gt2_init_clk (cmac_init_clk     ),
        .gt2_sys_reset(cmac_sys_reset    ),

        .xdma_rx_axis_tready(xdma_rx_axis_tready),
        .xdma_rx_axis_tvalid(xdma_rx_axis_tvalid),
        .xdma_rx_axis_tlast (xdma_rx_axis_tlast),
        .xdma_rx_axis_tdata (xdma_rx_axis_tdata),
        .xdma_rx_axis_tkeep (xdma_rx_axis_tkeep),
        .xdma_rx_axis_tuser (xdma_rx_axis_tuser),

        .xdma_tx_axis_tvalid(xdma_tx_axis_tvalid),
        .xdma_tx_axis_tready(xdma_tx_axis_tready),
        .xdma_tx_axis_tlast (xdma_tx_axis_tlast),
        .xdma_tx_axis_tdata (xdma_tx_axis_tdata),
        .xdma_tx_axis_tkeep (xdma_tx_axis_tkeep),
        .xdma_tx_axis_tuser (xdma_tx_axis_tuser),

        // CMAC GT
        .gt1_rxn_in (qsfp1_rxn_in),
        .gt1_rxp_in (qsfp1_rxp_in),
        .gt1_txn_out(qsfp1_txn_out),
        .gt1_txp_out(qsfp1_txp_out),
        
        .gt2_rxn_in (qsfp2_rxn_in),
        .gt2_rxp_in (qsfp2_rxp_in),
        .gt2_txn_out(qsfp2_txn_out),
        .gt2_txp_out(qsfp2_txp_out)
    );

endmodule