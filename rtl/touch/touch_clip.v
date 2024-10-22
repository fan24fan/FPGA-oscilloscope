//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           touch_clip
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        LCD触摸裁剪模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module touch_clip(
    input                clk,            //时钟
    input                rst_n,          //复位，低电平有效
    
    input      [15:0]    lcd_id,         //LCD屏ID
    input      [2:0]     tp_num,
    input      [31:0]    tp1_xy,
	//Avalon-ST接口		     	
    input      [2:0]     avl_address,    //地址
    input                avl_write,      //写请求
    input      [31:0]    avl_writedata,  //写数据
    input                avl_read,       //读请求
    output reg [31:0]    avl_readdata    //读数据
    );

//reg define
reg  [15:0]  clip_tp_x ;
reg  [15:0]  clip_tp_y ;
    
//*****************************************************
//**                    main code
//*****************************************************    

//avalon 端口读操作
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        avl_readdata <= 32'd0;
	else begin
        if(avl_read) begin    //读操作
            case(avl_address)
                3'd0: avl_readdata <= {29'd0,tp_num};
                3'd1: avl_readdata <= {clip_tp_x,clip_tp_y};
                default:;
            endcase
        end
	end
end  

//触摸点坐标裁剪(使其输出坐标范围是480*272)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clip_tp_x <= 1'b0;
        clip_tp_y <= 1'b0;
    end
    else begin
        case(lcd_id)
            16'h4342 : begin
//                if(tp1_xy[31:16] <= 11'd480 && tp1_xy[15:0] <= 11'd272) begin
//                    clip_tp_x <= tp1_xy[31:16];
//                    clip_tp_y <= tp1_xy[15:0];
//                end
                if(tp1_xy[31:16] >= 11'd160 && tp1_xy[31:16] < 11'd640 
                   && tp1_xy[15:0] >= 11'd104 && tp1_xy[15:0] < 11'd376) begin
                    clip_tp_x <= tp1_xy[31:16] - 11'd160;
                    clip_tp_y <= tp1_xy[15:0] - 11'd104;
                end   
            end    
            16'h4384,16'h7084 : begin//16'h4384
                if(tp1_xy[31:16] >= 11'd160 && tp1_xy[31:16] < 11'd640 
                   && tp1_xy[15:0] >= 11'd104 && tp1_xy[15:0] < 11'd376) begin
                    clip_tp_x <= tp1_xy[31:16] - 11'd160;
                    clip_tp_y <= tp1_xy[15:0] - 11'd104;
                end   
            end            
            16'h7016 : begin
                if(tp1_xy[31:16] >= 11'd272 && tp1_xy[31:16] < 11'd752
                   && tp1_xy[15:0] >= 11'd164 && tp1_xy[15:0] < 11'd436) begin
                    clip_tp_x <= tp1_xy[31:16] - 11'd272;
                    clip_tp_y <= tp1_xy[15:0] - 11'd164;
                end   
            end      
            default : begin
                clip_tp_x <= 1'b0;
                clip_tp_y <= 1'b0;
            end            
        endcase            
    end
end

endmodule
