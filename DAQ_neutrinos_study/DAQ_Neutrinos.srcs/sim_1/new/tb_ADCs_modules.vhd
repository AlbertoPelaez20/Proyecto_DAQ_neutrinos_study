-- ========================================================
-- TESTBENCH DE PRUEDA DEL bloque ADCs_modules
-- ========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ADCs_modules is
--  Port ( );
end tb_ADCs_modules;

architecture Behavioral of tb_ADCs_modules is
component ADCs_modules is
     Port ( ONN,RESET,CLK,ONN2           : in std_logic;      
         SELEC                             : in std_logic_vector  (2 downto 0);       
         GUARDAR,puntero_reset,READY             : out std_logic;
         BUS_CS                            : out std_logic_vector (7 downto 0);
         BUS_MUL                           : out std_logic_vector (3 downto 0);
         SCLK_1,SCLK_2,SCLK_3,SCLK_4       : out std_logic;
         SDO_1,SDO_2,SDO_3,SDO_4           : in std_logic;
         led                               : out std_logic_vector ( 15 downto 0);
         sample_ADC1,sample_ADC2           : out std_logic_vector ( 14 downto 0);
         sample_ADC3,sample_ADC4           : out std_logic_vector ( 14 downto 0);
         sample_ADC5,sample_ADC6           : out std_logic_vector ( 14 downto 0);
         sample_ADC7,sample_ADC8           : out std_logic_vector ( 14 downto 0)
         );
end component;


signal ONN_S,RESET_S,CLK_S: std_logic;

begin

top01: ADCs_modules 
     porT map (    ONN      => '1',
                   ONN2     => ONN_S ,
                   RESET    => RESET_S,
                   SELEC    => "000", 
                   SDO_1    => '1',  
                   SDO_2    => '1',
                   SDO_3    => '1',
                   SDO_4    => '1',               
                   CLK      => CLK_S   );
process
begin
  CLK_S <= '0';
  wait for 5ns ;
  CLK_S <= '1';
  wait for 5ns ;
end process;  

Control : process
  begin
 ONN_S <='0';
 RESET_S <='0';
 wait for 20000ns ;
-- wait for 200ns ;
  ONN_S <='1';
 RESET_S <='0';

 wait for 10000ns ;

  ONN_S <='0';
 RESET_S <='0';
  wait for 10000ns ;
end process;

end Behavioral;
