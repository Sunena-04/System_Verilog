module testbench;

  logic PCLK, PRESETn;
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end
  initial begin
    PRESETn = 0;
    #12 PRESETn = 1;
  end

  apb_if if0 (.*);
  apb_slave dut (if0);

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end

  initial begin
    @(posedge PRESETn);
    #100;

    // ---------- WRITE ----------
    @(posedge PCLK);
    if0.PSEL    = 1'b1;
    if0.PENABLE = 1'b0;
    if0.PADDR   = 32'h04;
    if0.PWRITE  = 1'b1;
    if0.PWDATA  = 32'h1234_5678;

    @(posedge PCLK);
    if0.PENABLE = 1'b1;

    @(posedge PCLK);
    @(posedge PCLK);    // wait for PREADY
    if0.PSEL    = 1'b0;
    if0.PENABLE = 1'b0;

    // ---------- READ ----------
    @(posedge PCLK);
    if0.PSEL    = 1'b1;
    if0.PENABLE = 1'b0;
    if0.PADDR   = 32'h04;
    if0.PWRITE  = 1'b0;

    @(posedge PCLK);
    if0.PENABLE = 1'b1;

    @(posedge PCLK);   // extra cycle to let slave drive PRDATA
    @(posedge PCLK);   // sample on the next edge
    $display("Read data = 0x%h", if0.PRDATA);
    if (if0.PRDATA === 32'h1234_5678)
      $display("Test PASSED");
    else
      $display("Test FAILED");

    @(posedge PCLK);
    if0.PSEL    = 1'b0;
    if0.PENABLE = 1'b0;

    #100;
    $finish;
  end

endmodule