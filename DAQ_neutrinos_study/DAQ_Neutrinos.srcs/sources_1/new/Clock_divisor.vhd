-- ===================
-- Clock divider 
-- ===================
--  Para obtener una frecuencia de 1 Hz de salida a partir de una entrada de 100 MHz,
--  el valor de set debería ser 49,999,999. 
--  El calculo se hace de esta forma:
--  frecuencia de entrada  = clk_in
--  frecuencia de salida  =  clk_out
--  clk_out = (clk_in/(2*(set))) ; 1Hz = 100Mz/(2*49999999)
--  modificar para obterner la frecuencia deseada
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity Clock_divisor is
Port (
        clk_in : in  STD_LOGIC;        -- Entrada de reloj de 100 MHz
        clk_out: out STD_LOGIC;        -- Salida de reloj de 1 Hz
        set    : in natural range 0 to 89999999  -- Valor para ajustar la frecuencia
    );
end Clock_divisor;
architecture Behavioral of Clock_divisor is
 signal temp: STD_LOGIC := '0';    -- Señal interna para la salida de reloj
 signal counter : integer range 0 to 89999999 := 0; -- Contador interno
begin
    frequency_divider: process (clk_in, set)
    begin
        if (clk_in'event and clk_in = '1') then
            counter <= counter + 1;   -- Incrementar el contador en cada flanco de subida del reloj
            if (counter = set) then  -- Cuando el contador llega al valor de ajuste
                temp <= NOT(temp);    -- Cambiar el estado de la señal de salida
                counter <= 0;         -- Reiniciar el contador
            end if;
        end if;
    end process;    
    clk_out <= temp;  -- Asignar el valor de la señal interna a la salida
end Behavioral;
