-- ===================================================================================
-- TIMER OFF DELAY
-- ===================================================================================
-- Este bloque contiene un timer off delay para la activación retardada de los módulos SPI.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity timer is
    Port (
        CLK, RESET, ENABLE : in std_logic;
        set                : in std_logic_vector(7 downto 0);
        READY              : out std_logic
    );
end timer;

architecture Behavioral of timer is
    -- Declaración del componente contador1
    component contador1 is
        port (
            RESET, CLK, LD, UP, ENABLE : in std_logic;
            DIN                        : in std_logic_vector(7 downto 0);
            COUNT                      : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Señales internas
    signal stop, clk_s : std_logic;
    signal contador    : std_logic_vector(7 downto 0);

begin
    -- Instancia del componente contador1
    Count0: contador1
        port map (
            CLK    => clk_s,
            RESET  => RESET,
            ENABLE => ENABLE,
            LD     => '0',
            UP     => '1',
            DIN    => "00000000",
            COUNT  => contador
        );

    -- Lógica de las señales internas
    stop <= '1' when (contador < set) else '0';
    clk_s <= stop and CLK;
    READY <= '1' when (stop = '0' and ENABLE = '1') else '0';

end Behavioral;
