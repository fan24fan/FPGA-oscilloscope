//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           data_store
// Last modified Date:  2019/3/10 13:26:27
// Last Version:        V1.0
// Descriptions:        波形数据存储模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/10 11:33:57
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module data_store(
    input               rst_n,      // 复位信号

    input       [7:0]   trig_level, // 触发电平
    input               trig_edge,  // 触发边沿
    input               wave_run,   // 波形采集启动/停止
    input       [9:0]   h_shift,    // 波形水平偏移量

    input               ad_clk,     // AD时钟
    input       [7:0]   ad_data,    // AD输入数据
    input               deci_valid, // 抽样有效信号
    
    input               lcd_clk,
    input               lcd_wr_over,
    input               wave_data_req,
    input       [8:0]   wave_rd_addr,
    output      [7:0]   wave_rd_data,
    output reg          outrange    //水平偏移超出范围
);

//reg define
reg [8:0] wr_addr;      //RAM写地址
reg       ram_aclr;     //RAM清除

reg       trig_flag;    //触发标志 
reg       trig_en;      //触发使能
reg [8:0] trig_addr;    //触发地址

reg [7:0] pre_data;
reg [7:0] pre_data1;
reg [7:0] pre_data2;
reg [8:0] data_cnt;

//wire define
wire       wr_en;       //RAM写使能
wire [9:0] rd_addr;     //RAM地址
wire [9:0] rel_addr;    //相对触发地址
wire [9:0] shift_addr;  //偏移后的地址
wire       trig_pulse;  //满足触发条件时产生脉冲
wire [7:0] rd_ram_data;

//*****************************************************
//**                    main code
//*****************************************************
assign wr_en    = deci_valid && (data_cnt <= 299) && wave_run;

//计算波形水平偏移后的RAM数据地址
assign shift_addr = h_shift[9] ? (wave_rd_addr-h_shift[8:0]) : //右移
                    (wave_rd_addr+h_shift[8:0]);               //左移

//根据触发地址，计算像素横坐标所映射的RAM地址
assign rel_addr = trig_addr + shift_addr;
assign rd_addr = (rel_addr<150) ? (rel_addr+150) : 
                    (rel_addr>449) ? (rel_addr-450) :
                        (rel_addr-150);

//满足触发条件时输出脉冲信号
assign trig_pulse = trig_edge ? 
                    ((pre_data2<trig_level) && (pre_data1<trig_level) 
                        && (pre_data>=trig_level) && (ad_data>trig_level)) :
                    ((pre_data2>trig_level) && (pre_data1>trig_level) 
                        && (pre_data<=trig_level) && (ad_data<trig_level));        

//读出的数据为255时超出波形显示范围
assign wave_rd_data = outrange ? 8'd255 : (8'd255 - rd_ram_data); 

//判断水平偏移后地址范围
always @(posedge lcd_clk or negedge rst_n)begin
    if(!rst_n)
        outrange <= 1'b0;
    else                                        //右移时判断左边界
        if(h_shift[9] && (wave_rd_addr<h_shift[8:0]))    
            outrange <= 1'b1;
                                                //左移时判断右边界
        else if((~h_shift[9]) && (wave_rd_addr+h_shift[8:0]>299))
            outrange <= 1'b1;
        else
            outrange <= 1'b0;
end

//写RAM地址累加
always @(posedge ad_clk or negedge rst_n)begin
    if(!rst_n)
        wr_addr  <= 9'd0;
    else if(deci_valid) begin
        if(wr_addr < 9'd299) 
            wr_addr <= wr_addr + 1'b1;
        else 
            wr_addr  <= 9'd0;
    end
end

//触发使能
always @(posedge ad_clk or negedge rst_n)begin
    if(!rst_n) begin
        data_cnt <= 9'd0;
        trig_en  <= 1'b0;
    end
    else begin
        if(deci_valid) begin
            if(data_cnt < 149) begin    //触发前至少接收150个数据
                data_cnt <= data_cnt + 1'b1;
                trig_en  <= 1'b0;
            end
            else begin
                trig_en <= 1'b1;        //打开触发使能
                if(trig_flag) begin     //检测到触发信号
                    trig_en <= 1'b0;
                    if(data_cnt < 300)  //继续接收150个数据
                        data_cnt <= data_cnt + 1'b1;
                end
            end

        end
                                        //波形绘制完成后重新计数
        if((data_cnt == 300) && lcd_wr_over & wave_run)
            data_cnt <= 9'd0;
    end
end

//寄存AD数据，用于判断触发条件
always @(posedge ad_clk or negedge rst_n)begin
    if(!rst_n) begin
        pre_data  <= 8'd0;
        pre_data1 <= 8'd0;
        pre_data2 <= 8'd0;
    end
    else if(deci_valid) begin
        pre_data  <= ad_data;
        pre_data1 <= pre_data;
        pre_data2 <= pre_data1;
    end
end

//触发检测
always @(posedge ad_clk or negedge rst_n)begin
    if(!rst_n) begin
        trig_addr <= 9'd0;
        trig_flag <= 1'b0;
    end
    else begin
        if(deci_valid && trig_en && trig_pulse) begin       
            trig_flag <= 1'b1;
            trig_addr <= wr_addr + 2;
        end
        if(trig_flag && (data_cnt == 300) 
            && lcd_wr_over && wave_run)
            trig_flag <= 1'b0;
    end
end

//例化双口RAM
ram_2port u_ram_2port (
	.wrclock    (ad_clk),
	.wraddress  (wr_addr),
	.data       (ad_data),
	.wren       (wr_en),
    
	.rdclock    (lcd_clk),
	.rd_aclr    (1'b0),
	.rdaddress  (rd_addr), 
    .rden       (wave_data_req),
	.q          (rd_ram_data)
	);

endmodule 