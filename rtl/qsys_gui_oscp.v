//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           qsys_gui_oscp
// Last modified Date:  2021/05/21 09:38:00
// Last Version:        V1.0
// Descriptions:        Qsys示波器例程顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2021/05/21 09:38:00
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module qsys_gui_oscp(
    //时钟和复位接口
    input           sys_clk,      //时钟
    input           sys_rst_n,    //按键复位

    //SDRAM接口
    output          sdram_clk  ,  //SDRAM 时钟
    output          sdram_cke  ,  //SDRAM 时钟有效
    output          sdram_cs_n ,  //SDRAM 片选
    output          sdram_ras_n,  //SDRAM 行有效
    output          sdram_cas_n,  //SDRAM 列有效
    output          sdram_we_n ,  //SDRAM 写有效
    output   [1:0]  sdram_ba   ,  //SDRAM Bank地址
    output   [1:0]  sdram_dqm  ,  //SDRAM 数据掩码
    output   [12:0] sdram_addr ,  //SDRAM 地址
    inout    [15:0] sdram_data ,  //SDRAM 数据 
    
    output          eth_rst_n,    //以太网芯片复位信号，低电平有效
    output          ad_pulse,     //pulse_gen模块输出的脉冲信号,仅用于调试

    //AD
    output          ad_clk,       //AD(9280)驱动时钟,25Mhz 
    input  [7:0]    ad_data,      //AD输入数据
    input           ad_otr,       //AD超量程标志
    //DA  
    output          da_clk,       //DA(9708)驱动时钟,50Mhz
    output [7:0]    da_data,      //DA输出数据    
    
    //EPCS Flash 接口
    output          epcs_dclk,
    output          epcs_sce,
    output          epcs_sdo,
    input           epcs_data0,

    //RGB LCD 触摸接口
    inout           touch_sda,
    output          touch_scl,
    inout           touch_int,
    output          touch_rst,   
    
    //RGB LCD接口
    output          lcd_de,       //LCD 数据使能信号
    output          lcd_hs,       //LCD 行同步信号
    output          lcd_vs,       //LCD 场同步信号
    output          lcd_clk,      //LCD 像素时钟
    inout   [15:0]  lcd_rgb,      //LCD RGB565颜色数据
    output          lcd_rst,
    output          lcd_bl
);

//parameter define
parameter CLK_FS = 26'd50000000;    // 频率计基准时钟频率25Mhz

//wire define
wire        clk_100m_shift;
wire        clk_100m;
wire        clk_50m;
wire        clk_25m;
wire        clk_12_5m;
wire        pll_locked;
wire        rst_n;

//读写 SDRAM 桥接信号
wire        bridge_write;
wire        bridge_read;  
wire [15:0] bridge_writedata;
wire [15:0] bridge_readdata;
wire [25:0] bridge_address;
wire [ 9:0] bridge_burstcount;
wire        bridge_waitrequest;             
wire        bridge_readdatavalid;

//source_st_fifo信号
wire [9:0]  source_fifo_wrusedw;

//触摸驱动模块 avalon 总线 (touch point)
wire [ 2:0] tp_avl_address;
wire [31:0] tp_avl_writedata;
wire        tp_avl_write;
wire        tp_avl_read;
wire [31:0] tp_avl_readdata;

wire        pio_lcd_rst;    //LCD显示和触摸模块复位信号
wire        tp_interrupt;   //触摸模块输出的中断信号(touch_valid)

//fifo请求数据接口信号
wire [15:0] ui_pixel_data;
wire        ui_data_req;

wire [19:0] ad_freq;    	//AD脉冲信号的频率
wire [ 7:0] ad_vpp;     	//AD输入信号峰峰值
wire [ 7:0] ad_max;     	//AD输入信号最大值
wire [ 7:0] ad_min;     	//AD输入信号最小值

wire [9:0]  deci_rate;	    //抽样率
wire [7:0]  trig_level;     //触发电平
wire [7:0]  trig_line;      //触发线位置
wire        trig_edge;      //触发边沿
wire        wave_run;       //波形采集运行/停止
wire [9:0]  h_shift;        //波形水平偏移量
wire [9:0]  v_shift;        //波形竖直偏移量
wire [4:0]  v_scale;        //波形竖直缩放比例

wire        deci_valid; 	//抽样有效信号
wire        wave_data_req;  //波形(AD数据)请求信号 
wire [ 7:0] wave_rd_data;   //请求到的波形(AD数据)
wire [ 8:0] wave_rd_addr;   //波形(AD数据)请求地址
wire        outrange;       //水平偏移超出范围
wire        lcd_wr_over;	//LCD波形绘制完成信号

wire [15:0] lcd_id;
wire        avalon_write;    
wire        avalon_read;     
wire [31:0] avalon_writedata;
wire [31:0] avalon_readdata; 
wire [ 4:0] avalon_address;  

wire        tft_sda_i       ;
wire        tft_sda_o       ;
wire        tft_sda_t       ;

//*****************************************************
//**                    main code
//*****************************************************

assign rst_n = sys_rst_n & pll_locked ;
assign sdram_clk = clk_100m_shift;
assign ad_clk = clk_25m;
assign touch_sda = tft_sda_t  ?  tft_sda_o  :  1'bz;
assign tft_sda_i = touch_sda;
//因扩展口P7和以太网MDIO复用,因此固定对以太网进行复位,使以太网的MDIO接口不进行响应
assign eth_rst_n = 1'b0;

//例化锁相环模块
pll u_pll (
    .inclk0      (sys_clk   ),
    .areset      (~sys_rst_n),
    .c0          (clk_100m),       //QSYS 系统时钟
    .c1          (clk_100m_shift), //SDRAM 时钟
    .c2          (clk_50m),        //50Mhz 
    .c3          (clk_25m),        //25MHz
    .c4          (clk_12_5m),      //12.5Mhz
    .locked      (pll_locked)
    );

//生成波形并送到DA
da_wave_gen u_da_wave_gen(
    .sys_clk            (clk_50m), 
    .rst_n              (rst_n),
        
    .da_clk             (da_clk),  
    .da_data            (da_data)
    );    

//例化QSYS系统
qsys u_qsys(

    //时钟和复位
    .clk_clk                            (clk_100m),
    .reset_reset_n                      (rst_n),
        
    //EPCS  
    .epcs_flash_dclk                    (epcs_dclk ),
    .epcs_flash_sce                     (epcs_sce  ),
    .epcs_flash_sdo                     (epcs_sdo  ),
    .epcs_flash_data0                   (epcs_data0),
        
    //SDRAM 
    .sdram_addr                         (sdram_addr),
    .sdram_ba                           (sdram_ba),
    .sdram_cas_n                        (sdram_cas_n),
    .sdram_cke                          (sdram_cke),
    .sdram_cs_n                         (sdram_cs_n),
    .sdram_dq                           (sdram_data),
    .sdram_dqm                          (sdram_dqm),
    .sdram_ras_n                        (sdram_ras_n),
    .sdram_we_n                         (sdram_we_n),

    //读写SDRAM的桥     
    .sdram_bridge_slave_waitrequest     (bridge_waitrequest),
    .sdram_bridge_slave_readdata        (bridge_readdata),
    .sdram_bridge_slave_readdatavalid   (bridge_readdatavalid),
    .sdram_bridge_slave_burstcount      (bridge_burstcount),
    .sdram_bridge_slave_writedata       (bridge_writedata),
    .sdram_bridge_slave_address         (bridge_address),
    .sdram_bridge_slave_write           (bridge_write),
    .sdram_bridge_slave_read            (bridge_read),
    .sdram_bridge_slave_byteenable      (2'b11),
    .sdram_bridge_slave_debugaccess     (),

    .pio_lcd_rst_export                 (pio_lcd_rst),
    
    .tp_write                           (tp_avl_write),                        
    .tp_read                            (tp_avl_read),                         
    .tp_writedata                       (tp_avl_writedata),                   
    .tp_readdata                        (tp_avl_readdata),               
    .tp_address                         (tp_avl_address),     
    .tp_int_export                      (tp_interrupt),
    
    .cfg_write                          (avalon_write),                 
    .cfg_read                           (avalon_read),                 
    .cfg_writedata                      (avalon_writedata),                 
    .cfg_readdata                       (avalon_readdata),                 
    .cfg_address                        (avalon_address) 
    );
    
//读写SDRAM桥控制模块
sdram_bridge_control u_bridge_ctrl(
    .clk                                (clk_100m),
    .rst_n                              (pio_lcd_rst),
    
    .bridge_write                       (bridge_write),
    .bridge_read                        (bridge_read),
    .bridge_address                     (bridge_address),
    .bridge_burstcount                  (bridge_burstcount), 
    .bridge_waitrequest                 (bridge_waitrequest),
    .bridge_readdatavalid               (bridge_readdatavalid),
    
    .lcd_id                             (16'h4342),
    .source_fifo_wrusedw                (source_fifo_wrusedw)
 );

//FIFO：缓存SDRAM中读出的数据供LCD读取
fifo u_fifo(
    .wrclk          (clk_100m),
    .rdclk          (lcd_clk),
    
    .wrreq          (bridge_readdatavalid),
    .data           (bridge_readdata),
    .wrusedw        (source_fifo_wrusedw),
    
    .rdreq          (ui_data_req),
    .q              (ui_pixel_data),
    .rdempty        (),
    
    .aclr           (~pio_lcd_rst)
    );

//Avalon接口配置模块
avalmm_interface u_avalmm_interface(
    .clk                (clk_100m),
    .rst_n              (rst_n),
    
    .avalon_write       (avalon_write),
    .avalon_read        (avalon_read),
    .avalon_writedata   (avalon_writedata),
    .avalon_readdata    (avalon_readdata),
    .avalon_address     (avalon_address),
    
    .ad_freq            (ad_freq),
    .ad_vpp             (ad_vpp),
    .ad_max             (ad_max),
    .ad_min             (ad_min),
    
    .deci_rate          (deci_rate),
    .trig_level         (trig_level),
    .trig_edge          (trig_edge),
    .trig_line          (trig_line),
    .wave_run           (wave_run),
    .h_shift            (h_shift),
    .v_shift            (v_shift),
    .v_scale            (v_scale)
    );

//参数测量模块，测量输入波形峰峰值和频率    
param_measure #(
    .CLK_FS             (CLK_FS)        // 系统时钟频率值
) u_param_measure(
    .clk                (clk_50m),
    .rst_n              (rst_n),
    
    .trig_level         (trig_level),   //trig_level
    
    .ad_clk             (ad_clk), 
    .ad_data            (ad_data),
    .ad_pulse           (ad_pulse),    
    .ad_freq            (ad_freq),      // 频率
    .ad_vpp             (ad_vpp),       // 峰峰值
    .ad_max             (ad_max),
    .ad_min             (ad_min)
    );

//数据抽样模块
decimator u_decimator(
    .ad_clk             (ad_clk),
    .rst_n              (rst_n),
    
    .deci_rate          (deci_rate),
    .deci_valid         (deci_valid)
);
  
//波形数据存储模块  
data_store u_data_store(
    .rst_n              (rst_n),

    .trig_level         (trig_level),
    .trig_edge          (trig_edge),
    .wave_run           (wave_run),
    
    .ad_clk             (ad_clk),
    .ad_data            (ad_data),
    .deci_valid         (deci_valid),
    .h_shift            (h_shift),
        
    .lcd_clk            (lcd_clk),
    .lcd_wr_over        (lcd_wr_over),    
    .wave_data_req      (wave_data_req),
    .wave_rd_data       (wave_rd_data),
    .wave_rd_addr       (wave_rd_addr),
    .outrange           (outrange)
);

//LCD顶层模块
lcd_rgb_top  u_lcd_rgb_top(
    .clk_25m            (clk_25m),
    .clk_12_5m          (clk_12_5m),
    .rst_n              (pio_lcd_rst), 
     
    .lcd_de             (lcd_de ),
    .lcd_hs             (lcd_hs ),
    .lcd_vs             (lcd_vs ),
    .lcd_clk            (lcd_clk),
    .lcd_rgb            (lcd_rgb),
    .lcd_rst            (lcd_rst),
    .lcd_bl             (lcd_bl ),
    
    .v_shift            (v_shift      ),
    .v_scale            (v_scale      ),
    .trig_line          (trig_line    ),
    .outrange           (outrange     ),
    .ui_pixel_data      (ui_pixel_data),
    .wave_data          (wave_rd_data   ),
    .ui_data_req        (ui_data_req  ),
    .wave_addr          (wave_rd_addr  ),
    .wave_data_req      (wave_data_req),
    .wr_over            (lcd_wr_over  ),
    .lcd_id             (lcd_id       )
    );    

//触摸驱动
top_touch u_top_touch(
    .sys_clk           (clk_100m),
    .sys_rst_n         (pio_lcd_rst),       
    
    .tft_sda_i         (tft_sda_i),
    .tft_sda_o         (tft_sda_o),
    .tft_sda_t         (tft_sda_t),
    .tft_scl           (touch_scl),
    .tft_int           (touch_int),
    .tft_tcs           (touch_rst),  
  
    .lcd_id            (16'h4342),               //LCD ID  
    .touch_valid       (tp_interrupt), 
    .tp1_xy            (),
    .tp_num            (),    
    //Avalon-ST接口
    .avl_address       (tp_avl_address),
    .avl_write         (tp_avl_write),
    .avl_writedata     (tp_avl_writedata),
    .avl_read          (tp_avl_read),
    .avl_readdata      (tp_avl_readdata)
    );
 
endmodule 