-- ========================================================
-- Módulo para setear el voltaje de salida del DAC MCP4725
-- ========================================================
-- Bloque para setear el voltaje del DAC que dispara el trigger 
-- para dar inicio a la medicion de voltaje

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Interface_DAC is
    Port (
        ONN, RESET : in std_logic;                      -- Entradas de control: encendido y reinicio
        CLK        : in std_logic;                      -- Reloj principal
        SW         : in std_logic_vector(11 downto 0);  -- Datos de configuración
        SDA1       : inout std_logic;                   -- Línea de datos I2C
        SCL1       : inout std_logic                    -- Línea de reloj I2C
    );
end Interface_DAC;

architecture Behavioral of Interface_DAC is

 -- Declaración de componentes utilizados en el diseño
    component SetDAC is
        Port (
            Set     : in std_logic_vector(11 downto 0); -- Entrada de configuración
            clk     : in std_logic;                     -- Reloj de entrada
            reset   : in std_logic;                     -- Señal de reinicio
            ONN     : in std_logic;                     -- Señal de encendido
            bussy   : in std_logic;                     -- Señal de ocupado
            ena     : out std_logic;                    -- Señal de habilitación
            addr    : out std_logic_vector(6 downto 0); -- Dirección del esclavo
            rw      : out std_logic;                    -- Lectura/escritura ('0' = escribir)
            data_wr : out std_logic_vector(7 downto 0)  -- Datos a escribir
        );
    end component;
    
   component Clock_divisor is
        Port (
            clk_in : in  std_logic;        -- Entrada de reloj de 100 MHz para la basys3
            clk_out: out std_logic;        
            set    : in  natural range 0 to 89999999  -- Valor para ajustar la frecuencia
        );
    end component;
      
    component  i2c_master is
        GENERIC(
            input_clk : INTEGER := 50_000_000; -- velocidad del reloj de entrada desde la lógica del usuario en Hz
            bus_clk   : INTEGER := 400_000     -- velocidad a la que funcionará el bus i2c (scl) en Hz
        ); 
    PORT(
        clk       : IN     STD_LOGIC;                    -- reloj del sistema
        reset_n   : IN     STD_LOGIC;                    -- reset activo bajo
        ena       : IN     STD_LOGIC;                    -- latch en comando
        addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); -- dirección del esclavo objetivo
        rw        : IN     STD_LOGIC;                    -- '0' es escribir, '1' es leer
        data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); -- datos a escribir en el esclavo
        busy      : OUT    STD_LOGIC;                    -- indica transacción en progreso
        data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); -- datos leídos del esclavo
        ack_error : BUFFER STD_LOGIC;                    -- bandera si hay un acuse de recibo incorrecto del esclavo
        sda       : INOUT  STD_LOGIC;                    -- salida de datos seriales del bus i2c
        scl       : INOUT  STD_LOGIC                     -- salida del reloj serial del bus i2c
        );                   
    end component;
    
    -- Declaración de señales internas
    signal en, R_W, busy_s, error, clk_s : std_logic;
    signal ADRR          : std_logic_vector(6 downto 0);
    signal data1, data2  : std_logic_vector(7 downto 0);
    signal set7          : std_logic_vector(11 downto 0);

  begin

    -- Asignación directa de los datos de entrada a la señal interna
    set7 <= SW;
   
    -- divisor de frecuencia                                           
    div0 : Clock_divisor
        port map (
            clk_in   => CLK,
            clk_out     => clk_s,
            set     => 0
        ); -- seteado a 0 la frecuencia de salida para 100 MHz es 50MHz   

   -- =============================================
   -- Instancia del maestro I2C
   -- =============================================
    i2c : i2c_master
        generic map (
            input_clk => 50_000_000,
            bus_clk   => 400_000
        )
        port map (
            clk       => clk_s,
            ena       => en,
            reset_n   => '1',
            addr      => ADRR,
            rw        => R_W,
            data_wr   => data1,
            busy      => busy_s,
            data_rd   => data2,
            ack_error => error,
            sda       => SDA1,
            scl       => SCL1
        );

   -- =============================================
   -- Instancia del controlador del DAC
   -- =============================================
    set0 : SetDAC
        port map (
            set    => set7,
            ena    => en,
            reset  => RESET,
            clk    => CLK,
            ONN    => ONN,
            addr   => ADRR,
            rw     => R_W,
            data_wr => data1,
            bussy  => busy_s
        );

end Behavioral;
