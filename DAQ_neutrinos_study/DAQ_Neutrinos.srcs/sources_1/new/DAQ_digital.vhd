-- =======================================================================
-- DAQ_digital Proyecto Neutrinos ( probada con la tarjeta ADC_proto_v1)
-- =======================================================================
-- bloque para el control secuencial de 8 ADCs ADS7046 de 12-Bit. Los datos muestreados 
-- son enviados por UART a matlab para graficar la señal y obtener el voltaje pico y
-- el tiempo de subida. Los pulsadores sibre para: BTN_UP - iniciar proceso 
-- de busqueda de valor pico y numero de muestra, BTN_L - envio por UART1 de datos a Matlab
-- BTN_R resetar circuito SingleShotPulse, BTN_D mandar por UART2 3 bytes que contienen 
-- voltaje pico y numero de muestra y finalmente BTN_C, seteo del DAC MCP4725,
-- el seteo del valor se hace por los 12 primeros switches de la bassys 3

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

-- Definición de la entidad DAQ_digital
-- Esta entidad describe un módulo de adquisición de datos digital con varias entradas y salidas.
entity DAQ_digital is
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
end DAQ_digital;

architecture Behavioral of DAQ_digital is

  -- Componentes instanciados
  
  -- modulo uart para mandar datos a matlab graficar
  component UART_MATLAB is
    Port ( SEND_1        : in  std_logic;
           DATA_1        : in  std_logic_vector(7 downto 0);
           DIRECCION     : out std_logic_vector(7 downto 0);
           CLK_1         : in  std_logic;
           UART_TX_o_1   : out std_logic);
  end component;
  
  -- modulo DAC para setear el voltaje de disparo
  component Interface_DAC is
    Port ( ONN, RESET   : in std_logic;
           CLK         : in std_logic;
           SW          : in std_logic_vector(11 downto 0);
           SDA1        : inout std_logic;
           SCL1        : inout std_logic);
  end component;

  -- modulo uart para el envio de voltaje Pico y # de muestra
  component UART_features is
    Port ( SEND_1, CLK        : in  std_logic;
           NH_ADC, NL_ADC     : in  std_logic_vector(7 downto 0);
           numero_de_muestra  : in  std_logic_vector(7 downto 0);
           UART_TX_o_1        : out std_logic);
  end component;
 
  -- memoria de almacenamiento de los datos muestreados
  component memory_buffer is
    generic (
        DATA_WIDTH : integer := 12;
        ADDR_WIDTH : integer := 6
    );
    port (
        data1, data2, data3, data4  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data5, data6, data7, data8  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        MemWrite, MemRead, MemRead2, clk, reset : in std_logic;
        read_address, read_address2 : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        read_data, read_data2   : out std_logic_vector(7 downto 0)
    );
  end component;
  
  -- Boque para la extraccion de voltaje pico y numero de muestra
  component feature_extraction is
    Port ( ONN        : in std_logic;
           CLK        : in std_logic;
           RESET      : in std_logic;
           direccion  : out std_logic_vector(7 downto 0);
           READ       : out std_logic;
           datos      : in std_logic_vector(7 downto 0);
           PICO       : out std_logic_vector(15 downto 0);
           numero_de_muestra     : out std_logic_vector(7 downto 0));
  end component;
 
 -- Bloque para el control de los 8 ADCs
  component ADCs_modules is
    Port ( ONN, RESET, CLK, ONN2           : in std_logic;
           SELEC                             : in std_logic_vector(2 downto 0);
           GUARDAR, puntero_reset, READY          : out std_logic;
           BUS_CS                            : out std_logic_vector(7 downto 0);
           BUS_MUL                           : out std_logic_vector(3 downto 0);
           SCLK_1, SCLK_2, SCLK_3, SCLK_4   : out std_logic;
           SDO_1, SDO_2, SDO_3, SDO_4       : in std_logic;
           led                               : out std_logic_vector(15 downto 0);
           sample_ADC1, sample_ADC2, sample_ADC3, sample_ADC4 : out std_logic_vector(14 downto 0);
           sample_ADC5, sample_ADC6, sample_ADC7, sample_ADC8 : out std_logic_vector(14 downto 0));
  end component;
  
  component button_debounce
    Port ( clk        : in  std_logic;
           reset      : in  std_logic;
           button_in  : in  std_logic;
           button_out : out std_logic
           );
  end component;

  -- Señales internas
  signal clk_s, Pointer_zero, SAVE, btn2_s, MemWrite_s, MemRead_s, caracteristicas_lectura : std_logic := '0';
  signal LEDON, MAXPICO : std_logic_vector(15 downto 0) := x"0000";
  signal dato1, direccion1, direccion2, dato2 : std_logic_vector(7 downto 0);
  signal R01s, R02s, R03s, R04s, R05s, R06s, R07s, R08s : std_logic_vector(14 downto 0) := (others => '0');
  signal muestra_n : std_logic_vector(7 downto 0);
  signal habilita, listo, MemRead2_s : std_logic := '0';
  signal BUS_MUL_S :std_logic_vector(3 downto 0);
  signal SCLK_1s, SCLK_2s, SCLK_3s, SCLK_4s: std_logic := '0';
  signal btn_I2C, btn_UART1,btn_CI0,btn_CI1,btn_UART2: std_logic := '0';

begin

  -- Asignación de las salidas de los LEDs( OPCIONAL SE PUEDE QUITAR)
  led <= LEDON;

  -- Instanciación de los buffers de reloj
  CLK_buf1_inst : BUFG
    port map ( 
      I => CLK,    -- Entrada del reloj original
      O => clk_s   -- Salida del primer reloj bufferizado
    );

-- Debouncer para el basys3
Debouncer0: button_debounce
    Port map(  clk            => clk_s,
               reset          => '0',
               button_in      => BTN_C,
               button_out     => btn_I2C);       

I2C0: Interface_DAC 
   Port map 
        ( ONN   => btn_I2C,
          RESET => '0',
          CLK   => clk_s,
          SW    => set_DAC,
          SDA1  => I2C(1),
          SCL1  => I2C(0)   );   
          
 -- Debouncer para el basys3
Debouncer1: button_debounce
    Port map(  clk            => clk_s,
               reset          => '0',
               button_in      => BTN_L,
               button_out     => btn_UART1);   

  -- Instanciación del transmisor UART
  UART01 : UART_MATLAB
    port map (
      SEND_1      => btn_UART1,
      CLK_1       => clk_s,
      DIRECCION   => direccion1,
      DATA_1      => dato1,
      UART_TX_o_1 => UART1_TX
    );

  -- Instanciación de los módulos de memoria
  MemWrite_s <= SAVE;
  MemRead_s  <= NOT MemWrite_s;
  habilita   <= START and SWICHT;
  MemRead2_s <= caracteristicas_lectura  and (NOT MemWrite_s);

  MEM0 : memory_buffer
    generic map (
      DATA_WIDTH => 12, 
      ADDR_WIDTH => 8
    )
    port map (
      data1         => R01s(12 downto 1),
      data2         => R02s(12 downto 1),
      data3         => R03s(12 downto 1),
      data4         => R04s(12 downto 1),
      data5         => R05s(12 downto 1),
      data6         => R06s(12 downto 1),
      data7         => R07s(12 downto 1),
      data8         => R08s(12 downto 1),
      MemWrite      => MemWrite_s,
      MemRead       => MemRead_s,
      MemRead2      => caracteristicas_lectura ,
      clk           => clk_s,
      reset         => Pointer_zero,
      read_address  => direccion1,
      read_data     => dato1,
      read_address2 => direccion2,
      read_data2    => dato2
    );

              
  -- Instanciación del bloque de extracción de características
  CI0: feature_extraction
    port map (
      ONN                   => BTN_U,
      CLK                   => clk_s,
      RESET                 => '0',
      direccion             => direccion2,
      READ                  => caracteristicas_lectura,
      datos                 => dato2,
      PICO                  => MAXPICO,
      numero_de_muestra     => muestra_n
    );
              
  -- Instanciación del módulo ADC
  CI1 : ADCs_modules
    port map (
      ONN               => '1',
      ONN2              => habilita,
      READY             => listo,
      GUARDAR           => SAVE,
      puntero_reset     => Pointer_zero,
      RESET             => BTN_R,
      CLK               => clk_s,
      SELEC             => SELEC,
      BUS_CS            => CSadc,
      BUS_MUL           => BUS_MUL_S,
      SCLK_1            => SCLK_1s,
      SCLK_2            => SCLK_2s,
      SCLK_3            => SCLK_3s,
      SCLK_4            => SCLK_4s,
      SDO_1             => SDOm(0),
      SDO_2             => SDOm(1),
      SDO_3             => SDOm(2),
      SDO_4             => SDOm(3),
      sample_ADC1       => R01s,
      sample_ADC2       => R02s,
      sample_ADC3       => R03s,
      sample_ADC4       => R04s,
      sample_ADC5       => R05s,
      sample_ADC6       => R06s,
      sample_ADC7       => R07s,
      sample_ADC8       => R08s,
      led               => LEDON
    );

SEmux <= BUS_MUL_S(3) & BUS_MUL_S(1);
ENmux <= BUS_MUL_S(2) & BUS_MUL_S(0);

SCLKm  <= SCLK_4s & SCLK_3s & SCLK_2s & SCLK_1s;

Debouncer2: button_debounce
    Port map(  clk            => clk_s,
               reset          => '0',
               button_in      => BTN_D,
               button_out     => btn_UART2);  


  -- Instanciación del segundo transmisor UART
  UART02 : UART_features
    port map (
      SEND_1              => btn_UART2,
      CLK                 => clk_s,
      NH_ADC              => MAXPICO(15 downto 8),
      NL_ADC              => MAXPICO(7 downto 0),
      numero_de_muestra   => muestra_n,
      UART_TX_o_1         => UART2_TX
    );

end Behavioral;
