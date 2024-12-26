library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity contador1 is
port    ( RESET, CLK, LD, UP, ENABLE : in std_logic;
              DIN                          : in std_logic_vector (7 downto 0);
              COUNT                        : out std_logic_vector (7 downto 0));
end contador1;

architecture Behavioral of contador1 is
 signal t_cnt : unsigned(7 downto 0) := (others => '0'); -- Señal interna del contador
begin
    process (CLK, RESET)
    begin
        if (RESET = '1') then
            t_cnt <= (others => '0'); -- Reinicio asíncrono
        elsif (rising_edge(CLK)) then
            if (ENABLE = '1') then -- Operar solo si ENABLE está activo
                if (LD = '1') then
                    t_cnt <= unsigned(DIN); -- Carga síncrona
                elsif (UP = '1') then
                        t_cnt <= t_cnt + 1; -- Incremento
                    else
                        t_cnt <= t_cnt - 1; -- Decremento                 
                end if;
            end if;
        end if;
    end process;
    
    COUNT <= std_logic_vector(t_cnt);
end Behavioral;
