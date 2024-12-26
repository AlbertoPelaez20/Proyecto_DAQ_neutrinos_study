-- ===================================================================================
  -- Circuito para Bloqueo de Disparo del trigger
  -- ===================================================================================
 --  Este bloque es opcional, bloque la se�al cada vez que detecta un pulso
 --  para evitar que el proceso de muestreo se haga de forma constante. Las pruebas 
 -- se hacen con generadores de onda por lo que la se�al es constante  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity  SingleShotPulse  is
    Port (
        clk       : in  std_logic;  -- Reloj del sistema
        reset     : in  std_logic;  -- Se�al de reinicio
        pulse_in  : in  std_logic;  -- Pulso de entrada
        sample_en : out std_logic   -- Habilitaci�n mientras dure el pulso
    );
end  SingleShotPulse ;

architecture Behavioral of  SingleShotPulse  is
    signal pulse_detected : std_logic := '0';  -- Se�al interna: indica si el pulso ya fue procesado
    signal enable_active  : std_logic := '0';  -- Se�al interna: controla la salida sample_en
begin
    process(clk, reset)
    begin
        if reset = '1' then
            pulse_detected <= '0';    -- Reinicia el estado de detecci�n
            enable_active  <= '0';    -- Reinicia la habilitaci�n de sample_en
        elsif rising_edge(clk) then
            if pulse_in = '1' and pulse_detected = '0' then
                -- Detecta el primer pulso y habilita la salida
                pulse_detected <= '1';
                enable_active  <= '1';
            elsif pulse_in = '0' then
                -- Desactiva la salida cuando termine el pulso
                enable_active <= '0';
            end if;
        end if;
    end process;

    -- La salida sample_en sigue la se�al enable_active
    sample_en <= enable_active;

end Behavioral;