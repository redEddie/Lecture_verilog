// 원래 i/o 없다.
module tb;

// assign 으로 ref처럼 A를 고정할 수 도 있다.
// assign A = 4'b1111;
reg [3:0] A;
reg [3:0] B;
wire [3:0] SUM;
wire COUT;
// 받을 때는 wire, 내줄 때는 reg
// 쉽게 이해하기 tb 안에 main이 있다고 생각하면 main의 입력은 tb가 넣어줘야(출력) 되고, main의 출력은 tb가 받아줘야 한다.

adder dut1(
    // i/o를 지정할 때
    // input, output을 각각 지정해도 되고,
    // .a(A) 와 같이 지정해도 된다.
    .a(A),
    .b(B),
    .cout(COUT), //출력이니 wire
    .sum(SUM)
);

// initial 로 풀어헤치는 방법, always로 ...
// 둘 다 내부는 reg만 와야 한다.
initial begin // start from #0

    #100
    A = 4'b0001; // 4'h1
    B = 4'b0010; // 4'h2

    #100
    // 입력 변환에 if()도 가능하다.
    // if()
    A = 4'b0000;
    B = 4'b0000;
end

// 어느 initial이든 동시에 출발한다. from #0.\
// 이렇게 하는 이유는 신호를 쪼개서 넣으면 너무 복잡하기 때문에 시나리오를 나누는거다.
initial begin
    #150;
    A = 4'b0101;
    B = 4'b1010;
end

initial begin
    $monitor($time, A, B); // 굳이 gui로 보지 않아도, 변화가 감지되어 text로 변화가 출력된다.
    // $display 도 있다. display는 text출력의 포맷을 커스텀기능이 있다.
    $display("tick:%0d A : %b B : %b",$time, A, B);
    #500;
    $strobe($time, A, B); 
    $finish;
end

initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,dut1);
end

endmodule
