-- ========================================================
-- TESTBENCH DE PRUEDA DEL MODULO I2C
-- ========================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_Interface_DAC is
--  Port ( );
end tb_Interface_DAC;

architecture Behavioral of tb_Interface_DAC is
component Interface_DAC is
  Port ( ONN,RESET: in std_logic;
          CLK: in std_logic;
          SW: in std_logic_vector(11 downto 0);
          SDA1: INOUT  STD_LOGIC; 
          SCL1: INOUT  STD_LOGIC     );
end component;
signal on_s, clk_s, reset_s,SDA1,SCL1: std_logic;
begin
en0: Interface_DAC   
port map ( ONN      => on_s,
           RESET    => reset_s,
           CLK      => clk_s,
           SW       => "100100001111",
           SDA1     => SDA1,
           SCL1     =>  SCL1
           );
process
begin
  clk_s <= '0';
  wait for 5ns ;
  clk_s <= '1';
  wait for 5ns ;
end process;      
Control : process
  begin
 on_s     <= '0';
 reset_s  <= '0';
 wait for 10ns ;
 on_s     <='1';
 reset_s  <='0';
 wait for 550ns ;
 on_s     <='0';
 reset_s  <='0'; 
 wait for 9000000ns ;             
end process;
end Behavioral;
