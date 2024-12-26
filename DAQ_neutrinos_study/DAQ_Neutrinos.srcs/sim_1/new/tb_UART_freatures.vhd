-- ========================================================
-- TESTBENCH DE PRUEDA DEL MODULO UART_features 
-- ========================================================
-- prueba del modulo de envio de caracteristicas por UART

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_UART_freatures is
--  Port ( );
end tb_UART_freatures;

architecture Behavioral of tb_UART_freatures is

-- modulo uart para el envio de voltaje Pico y # de muestra
  component UART_features is
    Port ( SEND_1, CLK        : in  std_logic;
           NH_ADC, NL_ADC     : in  std_logic_vector(7 downto 0);
           numero_de_muestra  : in  std_logic_vector(7 downto 0);
           UART_TX_o_1        : out std_logic);
  end component;
  signal btn_UART2,clk_s,UART2_TX: std_logic := '0';
begin

 -- Instanciación del segundo transmisor UART
  UART02 : UART_features
    port map (
      SEND_1              => btn_UART2,
      CLK                 => clk_s,
      NH_ADC              => x"01",
      NL_ADC              => x"FF",
      numero_de_muestra   => x"A0",
      UART_TX_o_1         => UART2_TX
    );
    
clock_generate: process
    begin
        clk_s <= '0';
        wait for 5ns ;
        clk_s <= '1';
    wait for 5ns ;
end process;     

Control : process
  begin
 btn_UART2  <= '0';
 wait for 10ns ;
 btn_UART2     <='1';
 wait for 550ns ;
 btn_UART2     <='0';
 wait for 9000000ns ;             
end process; 

end Behavioral;
