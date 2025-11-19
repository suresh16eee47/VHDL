library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;



entity pwm_gen is
generic (
    p_frq_bits : INTEGER := 19;
    p_duty_cyc_bits : integer := 31;
    p_smp_frq_bits : INTEGER := 31
    );
    
Port (
    p_clk 								: in 	STD_LOGIC;
    p_pwm 								: out 	STD_LOGIC;
    p_cpwm 								: out 	STD_LOGIC;
    p_high_low 							: out 	STD_LOGIC;
    p_low_high 							: out 	STD_LOGIC;
    p_fr_rev 							: in 	STD_LOGIC;
    p_en                                : in    STD_LOGIC;
    p_frq 								: in 	STD_LOGIC_VECTOR (p_frq_bits downto 0);
    p_duty_cyc 							: in 	STD_LOGIC_VECTOR (p_duty_cyc_bits downto 0);
    p_smp_frq                           : in 	STD_LOGIC_VECTOR (p_smp_frq_bits downto 0)
);
end pwm_gen;

architecture Behavioral of pwm_gen is
signal s_prd_cnt                        : natural ;
signal s_on_prd_cnt                     : natural ;             
signal s_off_prd_cnt                    : natural ;  

type pwm_port_sig is record
r_pwm       : std_logic ;
r_cpwm      : std_logic ;
r_high_low  : std_logic ;
r_low_high  : std_logic ;
end record;
signal s_pwm_port_sig : pwm_port_sig;


signal s_pwm                            : std_logic := '0';
signal s_cpwm                           : std_logic := '0';
signal s_high_low                       : std_logic := '0';
signal s_low_high                       : std_logic := '0';
signal pul_cntr                         : natural;    
signal s_pwm_pul_state                  : std_logic := '0';

signal s_cpwm_on_cnt                    : natural;
signal s_cpwm_cntr                      : natural := 0;  
signal s_cpwm_off_cnt                   : natural;  
signal s_dead_pul_cnt                   : natural := 200;
signal s_cpwm_ini_ctr                   : natural;
signal s_cpwm_pul_state                 : std_logic := '1';
signal s_en_status                      : std_logic := '0';
signal s_cpwm_en                        : std_logic := '0';
begin


s_pwm_port_sig <= (s_pwm, s_cpwm, s_high_low, s_low_high);


default_state : process(p_en,p_clk)
begin
if(rising_edge(p_clk)) then
    if(p_en = '1' and s_en_status = '0')then
        s_en_status <= '1';
    elsif(p_en= '0' and s_en_status = '1')then
        s_en_status <= '0';
    end if;    
end if;
end process;

process(s_en_status,p_clk)
begin
if(s_en_status = '1' and rising_edge(p_clk))then
    if(s_cpwm_en = '0')then
        if(s_cpwm_ini_ctr < s_dead_pul_cnt)then
            s_cpwm_ini_ctr <= s_cpwm_ini_ctr+1;
        else
            s_cpwm_ini_ctr <= 0;
            s_cpwm_en <= '1';
        end if;
    end if;
end if;
end process;


-- Process for generating PWM pulse with duty cycle with ON pulse count and OFF pulse count--
pwm_gen : process(p_clk)
begin
if(p_en = '1')then
--pule count of a required pwm frequency W.R.T sampling frequency (Sampling frequency/Required frequency)--- 
s_prd_cnt              <= (to_integer(UNSIGNED(p_smp_frq)))/(to_integer(UNSIGNED(p_frq)));
--pule count of ON time of the PWM signal with duty cycle ( pulse period count x duty cycle) --- 
s_on_prd_cnt           <= (s_prd_cnt*(to_integer(UNSIGNED(p_duty_cyc))))/100;
--pule count of OFF time of the PWM signal with duty cycle (pulse period count - on time count) --- 
s_off_prd_cnt          <= s_prd_cnt - s_on_prd_cnt;
--pule count of ON time of the C-PWM signal--
s_cpwm_on_cnt          <= s_off_prd_cnt - (2*s_dead_pul_cnt);
--pule count of OFF time of the C-PWM signal--
s_cpwm_off_cnt          <= s_on_prd_cnt + (2*s_dead_pul_cnt);
end if; 

if(rising_edge(p_clk) and s_en_status ='1') then

-- PWM generator--
if(s_pwm_pul_state = '0') then
if(pul_cntr < s_off_prd_cnt)then
    pul_cntr    <= pul_cntr + 1;
else 
    s_pwm_pul_state   <= '1';
    pul_cntr    <= 0;  
end if;

elsif(s_pwm_pul_state = '1') then
if(pul_cntr < s_on_prd_cnt)then
    pul_cntr    <= pul_cntr + 1;
else 
    s_pwm_pul_state   <= '0';
    pul_cntr    <= 0;  
end if;
end if;


-- C-PWM generator --
if(s_cpwm_pul_state = '1' and s_cpwm_en ='1') then
    if(s_cpwm_cntr < s_cpwm_on_cnt)then
        s_cpwm_cntr <= s_cpwm_cntr + 1;
    else
        s_cpwm_pul_state <= '0';
        s_cpwm_cntr <= 0;
    end if;
elsif(s_cpwm_pul_state = '0' and s_cpwm_en ='1') then
    if(s_cpwm_cntr < s_cpwm_off_cnt)then
        s_cpwm_cntr <= s_cpwm_cntr + 1;
    else
        s_cpwm_pul_state <= '1';
        s_cpwm_cntr <= 0;
    end if;
end if;
end if;
end process;


-- Forward reverse connection switch---
process(p_clk,s_en_status)
begin
if(s_en_status = '1' and rising_edge(p_clk))then
    if(p_fr_rev = '1') then
        s_pwm		<= s_pwm_pul_state;
        s_cpwm		<= s_cpwm_pul_state;
        s_high_low	<= '1';
        s_low_high	<= '0';
    elsif(p_fr_rev = '0') then
        s_pwm		<= '0';
        s_cpwm 		<= '1';
        s_high_low	<= s_cpwm_pul_state;
        s_low_high	<= s_pwm_pul_state;
    end if;
end if;
end process;


-- Port ti signal connection--
p_pwm <= s_pwm_port_sig.r_pwm;
p_cpwm <= s_pwm_port_sig.r_cpwm;
p_high_low <= s_pwm_port_sig.r_high_low;
p_low_high <= s_pwm_port_sig.r_low_high;

end Behavioral;
