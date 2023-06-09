module tb#(
    parameter TARGETALTITUDE = 188, // 원랜 188인데 도달하기 불가능
    parameter SCALE = 1000,
    parameter PERIOD = 10,
    parameter N = 64,
    parameter GRAVITY = 9_799,
    parameter SF = 10.0**-3.0,
    parameter ISF = 10.0**3.0,
    parameter SPECIFICIMPULSE_1 = 263,
    parameter SPECIFICIMPULSE_2 = 421,
    parameter SPECIFICIMPULSE_3 = 421,
    parameter WEIGHT_PROPELLANT_1 = 2077000,
    parameter WEIGHT_PROPELLANT_2 = 456100,
    parameter WEIGHT_PROPELLANT_3 = 39136, // 3단은 두번에 나눠 점화한다 => state 3, 4로 나눔.
    parameter WEIGHT_PROPELLANT_4 = 83864,
    parameter BURNTIME_1 = 168,
    parameter BURNTIME_2 = 360,
    parameter BURNTIME_3 = 165,
    parameter BURNTIME_4 = 335,
    parameter WEIGHT_STAGE_1 = 137000,
    parameter WEIGHT_STAGE_2 = 40100,
    parameter WEIGHT_STAGE_3 = 15200,
    parameter LM = 15103,
    parameter CMSM = 11900 // command module and service module
);

wire [63:0] AFTERWEIGHT;
wire DELIVER_IGNITION_END;
reg IGNITION_END;
always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        IGNITION_END <= 0;
    end
    else
        IGNITION_END <= DELIVER_IGNITION_END;
end
reg BACKWARD;
reg [63:0] SPECIFICIMPULSE;
reg [63:0] INITIALWEIGHT;
reg [63:0] WEIGHT_PROPELLANT;
reg [63:0] BURNTIME;
reg STAGEMANAGER;
reg [3:0] STAGESTATE;

wire [N-1:0] WEIGHTFORSTAGE1;
assign WEIGHTFORSTAGE1 = WEIGHT_PROPELLANT_1 + WEIGHT_PROPELLANT_2 + WEIGHT_PROPELLANT_3 + WEIGHT_PROPELLANT_4 + WEIGHT_STAGE_1 + WEIGHT_STAGE_2 + WEIGHT_STAGE_3 + LM + CMSM;
wire [N-1:0] WEIGHTFORSTAGE2;
assign WEIGHTFORSTAGE2 = WEIGHT_PROPELLANT_2 + WEIGHT_PROPELLANT_3 + WEIGHT_PROPELLANT_4 + WEIGHT_STAGE_2 + WEIGHT_STAGE_3 + LM + CMSM;
wire [N-1:0] WEIGHTFORSTAGE3;
assign WEIGHTFORSTAGE3 = WEIGHT_PROPELLANT_3 + WEIGHT_PROPELLANT_4+ WEIGHT_STAGE_3 + LM + CMSM;
wire [N-1:0] WEIGHTFORSTAGE4;
assign WEIGHTFORSTAGE4 = WEIGHT_PROPELLANT_4 + WEIGHT_STAGE_3 + LM + CMSM;

always @(posedge CLK or negedge RESETB) begin
    if ((~RESETB) || (IGNITION_END)) begin
        STAGEMANAGER <= 1;
    end
    else if (STAGEMANAGER == 1) begin
        STAGEMANAGER <= 0;
    end
    else
        STAGEMANAGER <= STAGEMANAGER;
end

always @(negedge STAGEMANAGER) begin
    if (~RESETB) begin
        STAGESTATE <= 0;
        $display("");
        $display("!!! ignition and liftoff !!!");
        $display("");
    end
    else begin
        STAGESTATE <= STAGESTATE+1;
    end
end

/*
always @(posedge CLK or negedge RESETB) begin
    if ((~RESETB) || (STAGEMANAGER)) begin
        IGNITION_END <= 0;
    end
end
*/
always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        SPECIFICIMPULSE <= 0;
    end
    else if (STAGESTATE == 1) begin
        SPECIFICIMPULSE <= SPECIFICIMPULSE_1;
    end
    else if (STAGESTATE == 2) begin
        SPECIFICIMPULSE <= SPECIFICIMPULSE_2;
    end
    else if (STAGESTATE == 3) begin
        SPECIFICIMPULSE <= SPECIFICIMPULSE_3;
    end
    else if (STAGESTATE == 4) begin
        SPECIFICIMPULSE <= SPECIFICIMPULSE_3;
    end
    else
        SPECIFICIMPULSE <= SPECIFICIMPULSE;
end
always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        INITIALWEIGHT <= 0;
    end
    else if (STAGESTATE == 1) begin
        INITIALWEIGHT <= WEIGHTFORSTAGE1;
    end
    else if (STAGESTATE == 2) begin
        INITIALWEIGHT <= WEIGHTFORSTAGE2;
    end
    else if (STAGESTATE == 3) begin
        INITIALWEIGHT <= WEIGHTFORSTAGE3;
    end
    else if (STAGESTATE == 4) begin
        INITIALWEIGHT <= WEIGHTFORSTAGE4;
    end
    else
        INITIALWEIGHT <= INITIALWEIGHT;
end
always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        BURNTIME <= 1;
    end
    else if (STAGESTATE == 1) begin
        BURNTIME <= BURNTIME_1;
    end
    else if (STAGESTATE == 2) begin
        BURNTIME <= BURNTIME_2;
    end
    else if (STAGESTATE == 3) begin
        BURNTIME <= BURNTIME_3;
    end
    else if (STAGESTATE == 4) begin
        BURNTIME <= BURNTIME_4;
    end
    else
        BURNTIME <= BURNTIME;
end

always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        WEIGHT_PROPELLANT <= 0;
    end
    else if (STAGESTATE == 1) begin
        WEIGHT_PROPELLANT <= WEIGHT_PROPELLANT_1;
    end
    else if (STAGESTATE == 2) begin
        WEIGHT_PROPELLANT <= WEIGHT_PROPELLANT_2;
    end
    else if (STAGESTATE == 3) begin
        WEIGHT_PROPELLANT <= WEIGHT_PROPELLANT_3;
    end
    else if (STAGESTATE == 4) begin
        WEIGHT_PROPELLANT <= WEIGHT_PROPELLANT_4;
    end
    else
        WEIGHT_PROPELLANT <= WEIGHT_PROPELLANT;
end

getVelocity getVelocity_1(
    .specificImpulse(SPECIFICIMPULSE),   // 바뀌는 것
    .initialWeight(INITIALWEIGHT),  // 바뀌는 것
    .propellantWeight(WEIGHT_PROPELLANT), // 바뀌는 것
    .burntime(BURNTIME),    // 바뀌는 것
    .clk(CLK),
    .resetb(~STAGEMANAGER),
    .backward(BACKWARD),

    .afterWeight(AFTERWEIGHT),
    .velocity(VELOCITY), // m/s로 소수 9자리
    .ignition_end(DELIVER_IGNITION_END)
);
wire [N-1:0] VELOCITY;

numericalIntegral height_calculator(
    .clk(CLK),
    .resetb(RESETB),
    .signal_input(VELOCITY),
    .start_integration(START_INTEGRATION),

    .integral_result(HEIGHT)              // m단위로 소수 9자리
);
reg START_INTEGRATION;

wire [N-1:0] HEIGHT;

gimbal30km gimbal_1(
    .clk(CLK),
    .resetb(RESETB),
    .velocity(VELOCITY),
    .height(HEIGHT),
    .current_Altitude(CURRENT_ALTITUDE),

    .angularVelocity(ANGULER_VELOCITY),
    .noairAltitude(NOAIR_ALTITUDE),
    .noairDistance(NOAIR_DISTANCE),
    .gimbalEnable(GIMBALENABLE)
);
wire GIMBALENABLE;
wire [N-1:0] NOAIR_ALTITUDE;
wire [N-1:0] NOAIR_DISTANCE;
wire [N-1:0] ANGULER_VELOCITY;


altitudeCalculator altitude_1(
    .fraction_Altitude(FRACTION_ALTITUDE),
    .fraction_Distance(FRACTION_DISTANCE),
    
    .clk(CLK),
    .resetb(RESETB),
    .noairAltitude(NOAIR_ALTITUDE),
    .noairDistance(NOAIR_DISTANCE),

    .velocity(VELOCITY),
    .angularVelocity(ANGULER_VELOCITY),
    .height(HEIGHT),
    .current_Altitude(CURRENT_ALTITUDE)
);
wire [N-1:0] FRACTION_ALTITUDE;
wire [N-1:0] FRACTION_DISTANCE;
numericalIntegral cal_alt(
    .clk(CLK),
    .resetb(RESETB),
    .signal_input(FRACTION_ALTITUDE), // 64비트 크기로 줘야한다. 
    .start_integration(~PRINT188KM),

    .integral_result(ALTITUDE_GIMBAL) // 얘도 64비트로 받아야 한다.
);

numericalIntegral cal_dist(
    .clk(CLK),
    .resetb(RESETB),
    .signal_input(FRACTION_DISTANCE), // 64비트 크기로 줘야한다. 
    .start_integration(~PRINT188KM),

    .integral_result(DISTNACE_GIMBAL) // 얘도 64비트로 받아야 한다.
);
wire [N-1:0] ALTITUDE_GIMBAL;
wire [N-1:0] DISTNACE_GIMBAL;


reg [N-1:0] CURRENT_ALTITUDE;
always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        CURRENT_ALTITUDE <= 0;
    end
    else if (NOAIR_ALTITUDE == 0) begin
        CURRENT_ALTITUDE <= HEIGHT;
    end
    else if((NOAIR_ALTITUDE > 0)&&(~PRINT188KM)) begin
        CURRENT_ALTITUDE <= NOAIR_ALTITUDE + ALTITUDE_GIMBAL;
    end
        // noair altitude 는 소수 9자리다
        // altitude gimbal 도 소수 9자린데 뭐가 문제지
end

reg [N-1:0] CURRENTDISTANCE;
reg [N-1:0] HEIGHT188;
always @(posedge PRINT188KM)begin
    HEIGHT188 <= HEIGHT;
end
always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        CURRENTDISTANCE <= 0;
    end
    else if ((NOAIR_ALTITUDE > 0)&&(~PRINT188KM)) begin
        CURRENTDISTANCE <= DISTNACE_GIMBAL;
    end
    else if (PRINT188KM) 
        CURRENTDISTANCE <= DISTNACE_GIMBAL + HEIGHT - HEIGHT188;
end


reg CLK;
reg RESETB;
// 
reg PRINT30KM;
reg PRINT188KM;
reg STAGESEPARATE_1;
reg STAGESEPARATE_2;
reg STAGESEPARATE_3;
reg STAGESEPARATE_4;

always @(posedge CLK or negedge RESETB) begin
    if (~RESETB) begin
        PRINT188KM <= 0;
        PRINT30KM <= 0;
        STAGESEPARATE_1 <= 0;
        STAGESEPARATE_2 <= 0;
        STAGESEPARATE_3 <= 0;
        STAGESEPARATE_4 <= 0;
    end
    else if ((CURRENT_ALTITUDE > TARGETALTITUDE*ISF*ISF*ISF*ISF)&&(~PRINT188KM)) begin
        $display("saturn V reached 188km height... @ %04ds", $time/SCALE); 
        $display(">>> current altitude : %f km", CURRENT_ALTITUDE*SF*SF*SF*SF);
        $display(">>> current distance : %f km", CURRENTDISTANCE*SF*SF*SF*SF);
        $display(">>> current velocity : %f km/s", VELOCITY*SF*SF*SF*SF);
        $display("");
        PRINT188KM <= 1;
        #1_000;
    end
    /*
    else if ((~GIMBALENABLE) && (STAGESTATE == 4'd1)) begin
        $display("시간 : %04ds", $time/SCALE);
        #1_000; 
    end */
    else if ((~PRINT30KM) && (NOAIR_ALTITUDE > 5)) begin
        $display("saturn V reached 30km height... @ %04ds", $time/SCALE); 
        $display(">>> gimbal start...");
        $display(">>> current altitude : %f km", CURRENT_ALTITUDE*SF*SF*SF*SF);
        $display(">>> current distance : %f km", CURRENTDISTANCE*SF*SF*SF*SF);
        $display(">>> current velocity : %f km/s", VELOCITY*SF*SF*SF*SF);
        $display("");
        PRINT30KM <= 1;
        #1_000;
    end

    // 와... 이거 초랑 같이 나타내는거 어렵네 안 해야지
    else if ( (~STAGESEPARATE_1) && (STAGESTATE == 4'd1) && (IGNITION_END) ) begin
        $display("1st stage about to detach... @ %04ds", $time/SCALE);
        $display(">>> detachment start...");
        $display(">>> current altitude : %f km", CURRENT_ALTITUDE*SF*SF*SF*SF);
        $display(">>> current distance : %f km", CURRENTDISTANCE*SF*SF*SF*SF);
        $display(">>> current velocity : %f km/s", VELOCITY*SF*SF*SF*SF);
        STAGESEPARATE_1 <= 1;
        $display("");

    end
    else if ( (~STAGESEPARATE_2) && (STAGESTATE == 4'd2) && (IGNITION_END) ) begin
        $display("2nd stage about to detach... @ %04ds", $time/SCALE);
        $display(">>> detachment start...");
        $display(">>> current altitude : %f km", CURRENT_ALTITUDE*SF*SF*SF*SF);
        $display(">>> current distance : %f km", CURRENTDISTANCE*SF*SF*SF*SF);
        $display(">>> current velocity : %f km/s", VELOCITY*SF*SF*SF*SF);
        STAGESEPARATE_2 <= 1;
        $display("");

    end
    else if ( (~STAGESEPARATE_3) && (STAGESTATE == 4'd3) && (IGNITION_END) ) begin
        $display("reached at LEO... @ %04ds", $time/SCALE);
        $display(">>> current altitude : %f km", CURRENT_ALTITUDE*SF*SF*SF*SF);
        $display(">>> current distance : %f km", CURRENTDISTANCE*SF*SF*SF*SF);
        $display(">>> current velocity : %f km/s", VELOCITY*SF*SF*SF*SF);
        STAGESEPARATE_3 <= 1;
        $display("");

    end
    else if ( (~STAGESEPARATE_4) && (STAGESTATE == 4'd4) && (IGNITION_END) ) begin
        $display("3rd stage about to detach... @ %04ds", $time/SCALE);
        $display(">>> detachment start...");
        $display(">>> current altitude : %f km", CURRENT_ALTITUDE*SF*SF*SF*SF);
        $display(">>> current distance : %f km", CURRENTDISTANCE*SF*SF*SF*SF);
        $display(">>> current velocity : %f km/s", VELOCITY*SF*SF*SF*SF);
        $display("");
        $display("trajectory length : %f km", HEIGHT*SF*SF*SF*SF);
        STAGESEPARATE_4 <= 1;
        $display("");

    end
end

initial begin
    // #10_000
    // #48_000
    #168_000 // 1st
    #360_000 // 2nd
    #165_000 // 3rd
    #335_000 // 3rd final
    #100_000
    $finish;
end

initial begin
    STAGEMANAGER = 0;
    BACKWARD = 0;

    RESETB = 0;
    CLK = 0;

    START_INTEGRATION = 0;
    HEIGHT188 = 0;
    RESETB = 0;

    #50 RESETB = 1;
        START_INTEGRATION = 1;
end

always begin
    #10 CLK <= ~CLK;
end

initial begin
    $dumpfile("output1.vcd");
    $dumpvars(0, tb);  
end

endmodule //tb