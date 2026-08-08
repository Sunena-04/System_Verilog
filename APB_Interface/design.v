// ================================================================
// APB Interface with modports defined (for documentation & role-specific access)
// ================================================================
interface apb_if (
  input logic PCLK,
  input logic PRESETn
);

  logic [31:0] PADDR;
  logic        PWRITE;
  logic        PSEL;
  logic        PENABLE;
  logic [31:0] PWDATA;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  // Modports for master and slave (not used in connection, but present per lab requirement)
  modport master (
    output PADDR, PWRITE, PSEL, PENABLE, PWDATA,
    input  PRDATA, PREADY, PSLVERR
  );

  modport slave (
    input  PADDR, PWRITE, PSEL, PENABLE, PWDATA,
    output PRDATA, PREADY, PSLVERR
  );

endinterface


// ================================================================
// APB Slave DUT – 16-word memory (port uses raw interface, not a Smodport)
// ================================================================
module apb_slave (
  apb_if s   // note: no .slave modport – we use the whole interface
);

  logic [31:0] mem [0:15];

  always_ff @(posedge s.PCLK or negedge s.PRESETn) begin
    if (!s.PRESETn) begin
      for (int i = 0; i < 16; i++) mem[i] <= '0;
      s.PREADY  <= 1'b0;
      s.PSLVERR <= 1'b0;
      s.PRDATA  <= '0;
    end else begin
      s.PREADY  <= 1'b1;          // zero‑wait‑state slave
      s.PSLVERR <= 1'b0;

      if (s.PSEL && s.PENABLE) begin
        if (s.PWRITE) begin
          if (s.PADDR[3:0] < 16)
            mem[s.PADDR[3:0]] <= s.PWDATA;
          else
            s.PSLVERR <= 1'b1;    // out‑of‑range address
        end else begin
          if (s.PADDR[3:0] < 16)
            s.PRDATA <= mem[s.PADDR[3:0]];
          else begin
            s.PRDATA  <= 'x;
            s.PSLVERR <= 1'b1;
          end
        end
      end
    end
  end

endmodule