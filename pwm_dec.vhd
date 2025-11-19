----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.10.2025 10:29:13
-- Design Name: 
-- Module Name: pwm_dec - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm_dec is
  Port (
p_clk 								: in 	STD_LOGIC;
p_pwm 								: in 	STD_LOGIC;
p_cpwm 								: in 	STD_LOGIC;
p_high_low 							: in 	STD_LOGIC;
p_low_high 							: in 	STD_LOGIC;
p_fr_rev 							: out 	STD_LOGIC;
p_en                                : in    STD_LOGIC;
p_frq_det 							: out 	STD_LOGIC_VECTOR (19 downto 0);
p_duty_cyc_det 						: out 	STD_LOGIC_VECTOR (31 downto 0);
p_smp_frq                           : in 	STD_LOGIC_VECTOR (31 downto 0);
p_dir_det                           : out   std_logic_vector (1 downto 0)
   );
end pwm_dec;

architecture Behavioral of pwm_dec is
signal s_prd_cnt                        : natural ;
signal s_on_prd_cnt                     : natural ;             
signal s_off_prd_cnt                    : natural ;  
signal s_pwm                            : std_logic := '0';
signal s_cpwm                           : std_logic := '0';
signal s_high_low                       : std_logic := '0';
signal s_low_high                       : std_logic := '0';
signal pul_cntr                         : natural;    
signal s_pwm_pul_state                  : std_logic := '0';

signal s_dead_on_cnt                    : natural;
signal s_dead_off_cnt                   : natural;  
signal s_dead_cntr                      : natural := 0;  
signal s_dead_pul_state                 : std_logic := '1';

signal s_dec_pwm                        : std_logic := '0';
signal s_dec_dead_pul                   : std_logic := '0';

signal s_frd_pul_det                    : std_logic := '0';
signal s_rev_pul_det                    : std_logic := '0';
signal s_frd_on_cnt                     : natural := 1;
signal s_frd_cntr                       : natural := 1;
signal s_frd_freq                       : natural := 1;
signal s_frd_off_cnt                    : natural := 1;
signal s_frd_state                      : std_logic := '0';
signal s_rev_state                      : std_logic := '0';
signal s_rev_on_cnt                     : natural :=1 ;
signal s_rev_cntr                       : natural := 1;
signal s_rev_freq                       : natural := 1;
signal s_rev_off_cnt                    : natural := 1;
signal s_direction                      : std_logic_vector (1 downto 0);
signal s_f_direction_state              : std_logic;
signal s_r_direction_state              : std_logic; 
signal s_duty_cyc_det                   : natural := 1;
begin

--process(bram_clk_a)
--begin
--    if(rising_edge(bram_clk_a))then
--        if(bram_wea = "0000" and bram_ena = '1' and bram_addr = x"0000_0004")then
--            freq <= bram_data;
--        end if;
--    end if
--end process;

--bram_rd_data <= freq when bram_wea = "0000" and bram_addr = x"0000_0004" else 

--generating decoded PWM Frequency--
process(p_en,s_dec_pwm,s_pwm,s_cpwm,s_high_low,s_low_high,s_dec_dead_pul,s_frd_pul_det,
p_high_low,p_low_high,p_pwm,p_cpwm,s_frd_freq,s_frd_on_cnt,s_frd_off_cnt,p_smp_frq,s_rev_freq)
begin
if(p_en = '1') then
s_dec_pwm <= (s_pwm and (not s_cpwm)) and (s_high_low and (not s_low_high));
s_dec_dead_pul <= not (s_pwm or s_cpwm);
s_frd_pul_det <= (p_high_low and (not p_low_high)) and (p_pwm and (not p_cpwm));
s_rev_pul_det <= (p_cpwm and (not p_pwm)) and (p_low_high and (not p_high_low));
s_frd_freq <= (TO_INTEGER(UNSIGNED(p_smp_frq))/(s_frd_on_cnt+s_frd_off_cnt));
s_rev_freq <= (TO_INTEGER(UNSIGNED(p_smp_frq))/(s_rev_on_cnt+s_rev_off_cnt));
end if;
end process;

--generating frd, reverse states--
process(p_en, s_frd_pul_det,s_rev_pul_det,p_clk)
begin

---- Forward state detector ----
if(falling_edge(s_frd_pul_det))then
    if(s_frd_pul_det = '0')then
        s_frd_state <= '0';
        s_frd_on_cnt <= s_frd_cntr;
        s_rev_on_cnt <= 1;
        s_frd_cntr <= 0;
    end if;
end if;

if(rising_edge(s_frd_pul_det))then
    if(p_en = '1') then
        s_frd_state <= '1';
        s_frd_off_cnt <= s_frd_cntr;
        s_rev_off_cnt <= 1;
        s_frd_cntr <= 0;
    end if;
end if;
    
---- reverse state detector ----
if(falling_edge(s_rev_pul_det))then
    if(p_en = '1') then
        s_rev_state <= '0';   
        s_rev_on_cnt <= s_rev_cntr;
        s_frd_on_cnt <= 1;
        s_rev_cntr <= 0;
    end if;
end if;

if(rising_edge(s_rev_pul_det))then
    if(p_en = '1') then
        s_rev_state <= '1';
        s_rev_off_cnt <= s_rev_cntr;
        s_frd_off_cnt <= 1;
        s_rev_cntr <= 0;
    end if;
end if;


--- FRD and reverse pulse counter ---
if(falling_edge(p_clk)) then
---- Forward ON/OFF counter ----
if(s_frd_state = '0')then
    s_frd_cntr <= s_frd_cntr+1;
elsif(s_frd_state = '1')then
    s_frd_cntr <= s_frd_cntr+1;
end if;
    
---- Reverse ON/OFF counter ----
if(s_rev_state = '0')then
    s_rev_cntr <= s_rev_cntr+1;
elsif(s_rev_state = '1')then
    s_rev_cntr <= s_rev_cntr+1;
end if;     
end if;
end process;


dir_det : process(p_clk)
begin
if(rising_edge(p_clk)) then
if(p_en = '1')then
    if(s_rev_on_cnt = 1 and s_rev_off_cnt = 1) then
        s_direction  <= "00"; 
        p_frq_det <= std_logic_vector(TO_UNSIGNED(s_frd_freq,20));
        s_duty_cyc_det <= (1/((s_frd_on_cnt+s_frd_off_cnt)/s_frd_on_cnt))*100;
        p_duty_cyc_det <= std_logic_vector(TO_UNSIGNED(((1/((s_frd_on_cnt+s_frd_off_cnt)/s_frd_on_cnt))*100),32));
        p_fr_rev <= '1';
    elsif (s_frd_on_cnt = 1 and s_frd_off_cnt = 1) then
        s_direction  <= "01";
        p_frq_det <= std_logic_vector(TO_UNSIGNED(s_rev_freq,20));
        s_duty_cyc_det <= (1/((s_rev_on_cnt+s_rev_off_cnt)/s_rev_on_cnt))*100;
        p_duty_cyc_det <= std_logic_vector(TO_UNSIGNED(((1/((s_rev_on_cnt+s_rev_off_cnt)/s_rev_on_cnt))*100),32));
        p_fr_rev <= '0'; 
    else
        s_direction  <= "10";
    end if;
end if;
end if;

p_dir_det <= s_direction;
end process;
end Behavioral;
