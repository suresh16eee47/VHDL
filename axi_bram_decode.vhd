----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.11.2025 08:04:35
-- Design Name: 
-- Module Name: axi_bram_decode - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axi_bram_decode is
    generic (
    p_frq_bits : INTEGER := 19;
    p_duty_cyc_bits : integer := 31;
    p_smp_frq_bits : INTEGER := 31
    );
    
    Port ( 
    p_clk                                         : in    STD_LOGIC;
    p_addr_in                                     : in    std_logic_vector (12 downto 0);
    p_data_in                                     : in    std_logic_vector (31 downto 0);
    p_data_out                                    : out   std_logic_vector (31 downto 0);
    p_en_in                                       : in    STD_LOGIC;
    p_rst_in                                      : in    STD_LOGIC;
    p_wea_in                                      : in    std_logic_vector (3 downto 0);
    
    p_fr_rev                                    : out   STD_LOGIC;
    pwm_gen_p_en                                : out   STD_LOGIC;
    pwm_gen_p_frq 								: out 	STD_LOGIC_VECTOR (p_frq_bits downto 0);
    pwm_gen_p_duty_cyc 							: out 	STD_LOGIC_VECTOR (p_duty_cyc_bits downto 0);
    pwm_gen_p_smp_frq                           : out 	STD_LOGIC_VECTOR (p_smp_frq_bits downto 0);
    
    pwm_dec_p_smp_frq                           : out 	STD_LOGIC_VECTOR (31 downto 0);
    pwm_dec_p_en                                : out    STD_LOGIC;
    pwm_dec_p_frq_det 							: in 	STD_LOGIC_VECTOR (19 downto 0);
    pwm_dec_p_duty_cyc_det 						: in 	STD_LOGIC_VECTOR (31 downto 0);
    pwm_dec_p_dir_det                           : in   std_logic_vector (1 downto 0);
    
--    LED EN
    p_led_en                                    : OUT std_logic
    );
end axi_bram_decode;

architecture Behavioral of axi_bram_decode is
signal s_p_addr_in : std_logic_vector (31 downto 0);
signal zero_pad : std_logic_vector (18 downto 0) := (others => '0');
signal base_addr_pwm_gen : std_logic_vector (
begin
s_p_addr_in <= zero_pad & p_addr_in;

process (p_wea_in,p_clk,p_en_in)
variable v_pwm_gen_p_smp_frq : std_logic_vector (31 downto 0) := (others => '0');
variable v_pwm_gen_p_duty_cyc : std_logic_vector (31 downto 0) :=(others => '0');
variable v_pwm_gen_p_frq : std_logic_vector (31 downto 0) := (others => '0');
variable v_pwm_dec_p_smp_frq : std_logic_vector (31 downto 0) := (others => '0');
variable v_pwm_dev_p_en : std_logic_vector (31 downto 0) := (others => '0');
variable v_p_led_en : std_logic_vector (31 downto 0) := (others => '0');


begin 
if (p_en_in = '1') then
    if(p_wea_in = x"F") then 
--    PWM_GEN input address mapping base 0x00
        if (s_p_addr_in = x"0000_0000") then
            pwm_gen_p_smp_frq <= p_data_in;
            v_pwm_gen_p_smp_frq := p_data_in;
        elsif(s_p_addr_in = x"0000_0004") then
            pwm_gen_p_duty_cyc <= p_data_in;
            v_pwm_gen_p_duty_cyc := p_data_in;
        elsif (s_p_addr_in = x"0000_0008") then
            pwm_gen_p_frq <= p_data_in(31 downto 12);
            pwm_gen_p_en <= p_data_in(10);
            p_fr_rev <= p_data_in(9);
            v_pwm_gen_p_frq := p_data_in;
            
--    PWM_GEN input address mapping 0xC 
        elsif(s_p_addr_in = x"0000_000C") then 
            pwm_dec_p_smp_frq <= p_data_in;
            v_pwm_dec_p_smp_frq := p_data_in;
            
        elsif(s_p_addr_in = x"0000_0010") then
            pwm_dec_p_en <= p_data_in(31);  
            v_pwm_dev_p_en := p_data_in;
            
--        Debug LED
        elsif(s_p_addr_in = x"0000_1FFC") then
            p_led_en <= p_data_in(0); 
            v_p_led_en :=  p_data_in;
        else   
            
        end if;
        
--        Read DATA 
--    PWM_GEN read data
     elsif (p_wea_in = x"0") then 
        if (s_p_addr_in = x"0000_0000") then
            p_data_out <= v_pwm_gen_p_smp_frq;
        elsif(s_p_addr_in = x"0000_0004") then
            p_data_out <= v_pwm_gen_p_duty_cyc;
        elsif (s_p_addr_in = x"0000_0008") then
            p_data_out <= v_pwm_gen_p_frq;
            
--    PWM_DEC read data            
        elsif (s_p_addr_in = x"0000_000C") then
            p_data_out <= v_pwm_dec_p_smp_frq;
        elsif (s_p_addr_in = x"0000_0010") then
            p_data_out <= v_pwm_dev_p_en;
        elsif (s_p_addr_in = x"0000_0014") then
                p_data_out <= pwm_dec_p_duty_cyc_det;
        elsif (s_p_addr_in = x"0000_0018") then
            p_data_out <=  pwm_dec_p_frq_det & pwm_dec_p_dir_det & "00" & x"00";
           
        
--        DEBUG LED 
        elsif (s_p_addr_in = x"0000_1FFC") then
            p_data_out <=  v_p_led_en;
--        Invalid Address            
        else
            p_data_out <= x"0000_2301";
     end if; 
    end if;   
end if;    
end process;
end Behavioral;
