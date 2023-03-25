// 원래 i/o 없다.
module tb;

reg A, B, SEL;
wire OUT;

adder dut1(
    .a(A),
    .b(B),
    .sel(SEL),
    .out(OUT)
);

initial begin

    #100
    A = 1'b1;
    B = 1'b0;
    SEL = 1'b0; //select a

    #100
    SEL = 1'b1; //select b
    
    #100
    A = 1'b0; 
    SEL = 1'b0;
    
    #20
    A = 1'b0; //continuously affect to a node
    
    #100
    $finish;
end

initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,dut1);
end

endmodule