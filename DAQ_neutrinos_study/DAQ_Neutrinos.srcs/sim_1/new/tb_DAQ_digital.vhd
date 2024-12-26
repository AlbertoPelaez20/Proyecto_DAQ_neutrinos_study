

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_DAQ_digital is
--  Port ( );
end tb_DAQ_digital;

architecture Behavioral of tb_DAQ_digital is

component DAQ_digital is
    Port (
        -- Botones de entrada de la basys3 para interacción del usuario (opcional)
        BTN_L    : in std_logic;               -- Botón izquierdo
        BTN_C    : in std_logic;               -- Botón central
        BTN_D    : in std_logic;               -- Botón hacia abajo
        BTN_R    : in std_logic;               -- Botón derecho
        BTN_U    : in std_logic;               -- Botón hacia arriba

        -- Señal de reloj de entrada
        CLK      : in std_logic;               -- Reloj del sistema

        -- Valores para configurar el DAC  (datos de 12 bits opcional)
        set_DAC  : in std_logic_vector(11 downto 0);  -- Entrada de configuración de 12 bits para el DAC

        -- Líneas de comunicación I2C (bidireccionales)
        I2C      : inout std_logic_vector(1 downto 0); -- SDA y SCL de I2C

        -- Señal de inicio para la adquisición de datos
        START    : in std_logic;               -- Señal de inicio para disparar la adquisición de datos

        -- Señal de interruptor para selección de modo (opcional)
        SWICHT   : in std_logic;               -- Entrada de interruptor para cambiar el modo de operación

        -- Selector para configuraciones o modos (control de 3 bits)
        SELEC    : in std_logic_vector(2 downto 0);  -- Entrada de selector de 3 bits

        -- Señales de control para el bus (salidas de 8 bits)
        CSadc    : out std_logic_vector(7 downto 0);  -- Selección de chip para comunicación con el bus
        ENmux    : out std_logic_vector(1 downto 0);  -- Salida para los multiplexores  (enable)
        SEmux    : out std_logic_vector(1 downto 0);  -- Salida para los multiplexores (selector)
      

        -- BUS de salida de señales de reloj SPI 
        SCLKm    : out std_logic_vector(3 downto 0);   -- Salida para los multiplexores (selector)

        -- Bus de entrada de señales de datos SPI (MISO)
        SDOm     : in std_logic_vector(3 downto 0);   -- Salida para los multiplexores (selector)
        
        -- Comunicación UART (recepción y transmisión datos muestreados para verificar funcionamiento)
        UART1_RX    : in std_logic;            -- Señal de recepción UART 1
        UART1_TX    : out std_logic;           -- Señal de transmisión UART 1
        UART2_TX    : out std_logic;           -- Señal de transmisión UART 2

        -- Salidas de LEDs de la basys3 para verificar funcionamiento de los modulos SPI (OPCIONAL)
        led      : out std_logic_vector(15 downto 0)  -- Salida de 16 bits para indicación de estado con LEDs
    );
end component;
signal SWICHT_s,CLK_s,START_s,BTN_L_s,BTN_R_s,BTN_U_s,BTN_D_s,BTN_C_s: std_logic := '0';

begin

DAQ0: DAQ_digital
        port map (
            SWICHT      => SWICHT_s,
            set_DAC     => x"010",
            CLK         => CLK_s,
            I2C         => open,
            SDOm        => "1111",
            SELEC       => "000",
            START       => START_s,
            BTN_L       => BTN_L_s,
            BTN_R       => BTN_R_s,
            BTN_U       => BTN_U_s,
            BTN_D       => BTN_D_s,
            BTN_C       => BTN_C_s,
            UART1_RX    => '1'
        );

clock_generate: process
    begin
        CLK_s <= '0';
        wait for 5ns ;
        CLK_s <= '1';
    wait for 5ns ;
end process;     

Control : process
    begin
        SWICHT_s       <=  '1';
        START_s        <=  '0';
        BTN_L_s        <=  '0';
        BTN_R_s        <=  '0';
        BTN_U_s        <=  '0';
        BTN_D_s        <=  '0';
        BTN_C_s        <=  '0';
    wait for 10ns ;
        SWICHT_s       <=  '1';
        START_s        <=  '1';
        BTN_L_s        <=  '0';
        BTN_R_s        <=  '0';
        BTN_U_s        <=  '0';
        BTN_D_s        <=  '0';
        BTN_C_s        <=  '0';
    wait for 550ns ;
        SWICHT_s       <=  '1';
        START_s        <=  '0';
        BTN_L_s        <=  '0';
        BTN_R_s        <=  '0';
        BTN_U_s        <=  '0';
        BTN_D_s        <=  '0';
        BTN_C_s        <=  '0';
    wait for 9000000ns ;             
end process; 

end Behavioral;
