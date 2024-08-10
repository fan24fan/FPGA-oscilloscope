//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           avalmm_interface
// Last modified Date:  2019/3/13 13:36:35
// Last Version:        V1.0
// Descriptions:        Avalon-MM 接口模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/13 13:36:35
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module avalmm_interface(
    input               clk,
    input               rst_n,
    
    input               avalon_write,       //写指令
    input               avalon_read,        //读指令
    input  [31:0]       avalon_writedata,   //写数据
    output [31:0]       avalon_readdata,    //读数据
    input  [ 4:0]       avalon_address,     //地址线
    
    input  [19:0]       ad_freq,            //AD脉冲信号的频率
    input  [ 7:0]       ad_vpp,             //AD输入信号峰峰值
    input  [ 7:0]       ad_max,             //AD输入信号最大值
    input  [ 7:0]       ad_min,             //AD输入信号最小值
    
    output reg [9:0]    deci_rate,          //抽样率
    output reg [7:0]    trig_level,         //触发电平
    output reg [7:0]    trig_line,          //触发线位置
    output reg          trig_edge,          //触发边沿 0:下降沿 1:上升沿
    output reg          wave_run,           //波形采集运行
    output reg [9:0]    h_shift,            //波形水平偏移量，bit[9]=0/1:左移/右移 
    output reg [9:0]    v_shift,            //波形竖直偏移量，bit[9]=0/1:上移/下移 
    output reg [4:0]    v_scale             //波形竖直缩放比例，bit[4]=0/1:缩小/放大 
);

//reg define
reg [31:0] readdata_reg; // 读数据寄存器

//*****************************************************
//**                    main code
//*****************************************************

assign avalon_readdata = readdata_reg;

//avalon-mm 读端口
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        readdata_reg <= 32'd0;
    else if(avalon_read) begin
        case(avalon_address)
            5'd0:                               //地址0 读频率
                readdata_reg <= {12'd0,ad_freq};    
            5'd1:                               //地址1 读峰峰值
                readdata_reg <= {8'd0,ad_vpp,ad_max,ad_min};     
            default:
                readdata_reg <= 32'd0;
        endcase
    end
end 

//avalon-mm 写端口
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        deci_rate  <= 10'd2;    //默认抽样率为2抽1
        trig_level <= 8'd128;   //默认触发电平为128
        trig_line  <= 8'd148;   //默认触发电平为148
        trig_edge  <= 1'b0;     //默认上升沿触发
        wave_run   <= 1'b1;     //默认波形采集运行
        h_shift    <= 10'd0;    //默认水平偏移量为0
        v_shift    <= 10'd0;    //默认竖直偏移量为0
        v_scale    <= 5'd0;     //默认竖直缩放比例为0
    end
    else if(avalon_write) begin
        case(avalon_address)
            5'd2:                               //地址2 写抽样率
                deci_rate  <= avalon_writedata[9:0];    
            5'd3:                               //地址3 bit[7:0]  写触发电平
                begin                           //地址3 bit[15:8] 写触发线位置
                    trig_level <= avalon_writedata[7:0];
                    trig_line  <= avalon_writedata[15:8];
                end
            5'd4:                               //地址4 写触发边沿
                trig_edge  <= avalon_writedata[0];
            5'd5:                               //地址5 波形采集运行/停止
                wave_run   <= avalon_writedata[0];
            5'd6:                               //地址6 波形水平偏移量
                h_shift    <= avalon_writedata[9:0];
            5'd7:                               //地址7 波形竖直偏移量
                v_shift    <= avalon_writedata[9:0];
            5'd8:                               //地址8 波形竖直缩放比例
                v_scale    <= avalon_writedata[4:0];
        endcase
    end
end 

endmodule 