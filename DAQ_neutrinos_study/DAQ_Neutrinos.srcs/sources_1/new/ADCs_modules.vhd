-- =========================================================================================
-- ADCs_modules: Bloque para el control y muestreo de los 8 ADCs ADS7046 de 12-Bit
-- =========================================================================================
-- Este bloque controla 4 modulos SPI, 2 multiplexores y 8 ADCs para el muestreo de 
-- señales. Tiene 2 maquinas de estados, una para mantener la sincronizacion de los modulos SPI 
-- y habilitarlos de manera secuencial. La otra maquina de estados es para iniciar el proceso de
-- grabacion o almacenamiento de los datos muestreados en una memoria buffer.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ADCs_modules is
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
end ADCs_modules;
architecture Behavioral of ADCs_modules is

-- =============================================
-- Declaración de componentes
-- =============================================
   
COMPONENT  SingleShotPulse  is
    Port (
        clk       : in  std_logic;  -- Reloj del sistema
        reset     : in  std_logic;  -- Señal de reinicio
        pulse_in  : in  std_logic;  -- Pulso de entrada
        sample_en : out std_logic   -- Habilitación mientras dure el pulso
    );
end  COMPONENT ;

component Interface_SPI is
        generic (
            data_length : INTEGER := 15  -- longitud de datos en bits
        );
        port (
            clk     : in  std_logic;         -- reloj del sistema
            reset_n : in  std_logic;         -- reinicio asíncrono activo en bajo
            stop    : IN  STD_LOGIC;         -- detener el módulo SPI
            enable  : in  std_logic;         -- iniciar comunicación
            cpol    : in  std_logic;         -- modo de polaridad del reloj
            cpha    : in  std_logic;         -- modo de fase del reloj
            miso    : in  std_logic;         -- maestro a esclavo (entrada del esclavo)
            sclk    : out std_logic;         -- reloj SPI
            ss_n    : out std_logic;         -- selección del esclavo           
            mosi    : out std_logic;         -- maestro a esclavo (salida del maestro)
            busy    : out std_logic;         -- señal de ocupado del maestro
            tx      : in  std_logic_vector (data_length-1 downto 0);  -- datos a transmitir
            rx      : out std_logic_vector (data_length-1 downto 0)   -- datos recibidos
        );
    end component;
component clk_wiz_0  
        port
        (   clk_in1           : in     std_logic;            
            clk_out1,clk_out2,clk_out3,clk_out4: out    std_logic;
            reset             : in std_logic );
 end component;   

component FMS_SPI_Control is
   Port ( ONN : in std_logic;
          RESET : in std_logic;
          clk_FMS : in std_logic;
          muestra_lista                     : out std_logic; 
          CS,CS2,CS3,CS4                    : in std_logic;           
          STOP_SPI                          : in std_logic_vector (3 downto 0);
          RST_timers,EN_timers,EN_SPIs      : out std_logic_vector (3 downto 0);
          R01,R02,R03,R04,R05,R06,R07,R08   : out std_logic_vector ( 14 downto 0);
          spi_rx,spi2_rx,spi3_rx,spi4_rx    : in std_logic_vector ( 14 downto 0)             
           );
end component;

component FMS_ADCs_Readings is
 Port (  ONN                    : in std_logic;
         CLK                    : in std_logic;
         RESET                  : in std_logic;        
         GUARDAR,RESET_CONT     : out std_logic;        
         CUENTA                 : in std_logic_vector(1 downto 0)
      );
end component;

COMPONENT timer is
  Port ( CLK,RESET, ENABLE: in std_logic;
         set : std_logic_vector (7 downto 0);
         READY: out std_logic );
end COMPONENT;

-- =============================================
-- Declaración de señales internas
-- =============================================

signal clk_SPIs, clk_shoot,clk_FMS,clk_Registers,clk_TIMERS: std_logic:='0';

signal spi_busy,  CS,   SCL,  SDO  : std_logic := '0';
signal spi_busy2, CS2, SCL2, SDO2 : std_logic := '0';
signal spi_busy3, CS3, SCL3, SDO3 : std_logic := '0';
signal spi_busy4, CS4, SCL4, SDO4 : std_logic := '0';
signal clk_me: std_logic := '0';

signal  spi_rx, spi_tx: std_logic_vector ( 14 downto 0);
signal spi2_rx,spi2_tx: std_logic_vector ( 14 downto 0);
signal spi3_rx,spi3_tx: std_logic_vector ( 14 downto 0);
signal spi4_rx,spi4_tx: std_logic_vector ( 14 downto 0);

signal R01,R02,R03,R04,R05,R06,R07,R08: std_logic_vector ( 14 downto 0);

signal EN_timers    : std_logic_vector (3 downto 0):= "0000";
signal READY_timers : std_logic_vector (3 downto 0):= "0000";
signal EN_SPIs      : std_logic_vector (3 downto 0):= "0000";
signal STOP_SPI     : std_logic_vector (3 downto 0):= "0000";
signal RST_timers   : std_logic_vector (3 downto 0):= "0000";

signal contador_4CS     : unsigned(2 downto 0) := (others => '0'); -- Contador
signal reset_contador : std_logic := '0';
signal reset_grabacion : std_logic := '0';

signal CS_1,CS_2,CS_3,CS_4: std_logic_vector ( 1 downto 0):="11";
signal BUS_MULTIPLEX: std_logic_vector ( 3 downto 0):= "0000";

signal led_s: std_logic_vector ( 14 downto 0);
signal seleccionador : std_logic_vector ( 2 downto 0);

signal Shoot_trigger, Grabar_en_memoria: std_logic:='0';


signal muestra_ready    : unsigned(1 downto 0) := (others => '0'); -- Contador
signal n_muestra        :  std_logic_vector(1 downto 0) := (others => '0'); -- Contador

signal sample_ok: std_logic := '0';


begin

-- Señal que indica que el bloque esta en la espera del disparo
READY <= NOT Shoot_trigger;

-- ===================================================================================
-- PLL para generar frecuencias variadas
-- ===================================================================================
--  Este bloque permite generar señales de reloj d edifertente frecuencia, en este caso
--  la usamos para los bloques SPI, para las maquinas de estado, para el circuito de disparo uni
--  y para el delay generado por los TIMERs
 
clk01: clk_wiz_0  
     Port map
        (   clk_in1           => CLK,
            clk_out1          => clk_SPIs,
            clk_out2          => clk_shoot,
            clk_out3          => clk_FMS,
            clk_out4          => clk_TIMERS,
            reset             => '0');   
-- ===================================================================================
-- Proceso: maquina de estados para el control de los modulos SPI
-- ===================================================================================
--  Este bloque contioene la maquina de estados encargada del proceso de habilitacion, 
--  inicio y stop de los modulos SPI, tambien se encarga de almacennar las mediciones 
--  obtenidas por los 8 ADCs en registros auxiliares para su posterior grabacion en 
--  en la memoria buffer
FMS00: FMS_SPI_Control 
     Port map
        (   ONN             => ONN,
            RESET           => '0',
            clk_FMS         => clk_FMS,
            CS              => CS,
            CS2             => CS2,
            CS3             => CS3,
            CS4             => CS4,
            muestra_lista   => sample_ok,
            STOP_SPI        => STOP_SPI,
            RST_timers      => RST_timers,
            EN_timers       => EN_timers,
            EN_SPIs         => EN_SPIs,
            R01             => R01,
            R02             => R02,
            R03             => R03,
            R04             => R04,
            R05             => R05,
            R06             => R06,
            R07             => R07,
            R08             => R08,
            spi_rx          => spi_rx,
            spi2_rx         => spi2_rx,
            spi3_rx         => spi3_rx,
            spi4_rx         => spi4_rx     
            );   


-- ===================================================================================
-- Señales de STOP controladas por la maquina de estados FMS_SPI_Control  
-- ===================================================================================
-- Estas señales detienen momentaneamente los modulos SPI una vez que se an tomado la muestra,
-- de esta forma, ninguno inicia denuevo hasta que el ultimo ADC tome su respectiva muestra.
-- este tiempo es necesario para la conmutacion de los CHIP SELECT y la señal de habilitacion de los 
-- multiplexores 
  
STOP_SPI(0) <= (NOT READY_timers(0)) OR EN_SPIs(0);
STOP_SPI(1) <= (NOT READY_timers(1)) OR EN_SPIs(1);
STOP_SPI(2) <= (NOT READY_timers(2)) OR EN_SPIs(2);
STOP_SPI(3) <= (NOT READY_timers(3)) OR EN_SPIs(3);

-- ===================================================================================
-- Debouncer para el basys3
-- ===================================================================================
-- btns resetea SingleShotPulse para seguir tomando muestras

     

-- ===================================================================================
-- Proceso:  Dectector de unico disparo de trigger
-- ===================================================================================
-- este bloque es opcional, debido a que se esta probando con una señal continua
-- se utiliza este circuito para evitar que se tomen varias muestras seguidas,
-- detecta un pulso de disparo y el el circuito bloquea la señal para evitar tomar muestras 
-- de forma indefinida solo hasta que se resete 

pulse01:  SingleShotPulse 
    Port map (
        clk       =>  clk_shoot,
        reset     =>  RESET,
        pulse_in  => ONN2,
        sample_en => Shoot_trigger );

-- ===================================================================================
-- Proceso: maquina de estados para el proceso de grabacion de datos muestreados
-- ===================================================================================
-- FMS01:FMS_ADCs_Readings
--  Este bloque contioene una maquina de estados encargada del proceso de grabacion 
-- en la memoria buffer de los datos muestreados SOLO el tiempo que dure el disparo
 
FMS01: FMS_ADCs_Readings
  Port map  ( ONN           =>  Shoot_trigger,            
              RESET_CONT    => reset_grabacion,            
              GUARDAR       => Grabar_en_memoria,          
              CLK           => clk_FMS,
              RESET         => RESET,
              CUENTA        => n_muestra     
         );
-- solo guarda en memoria el tiempo que dure el disparo del trigger          
GUARDAR <= Grabar_en_memoria and (Shoot_trigger) ;
-- mantiene el puntero para la grabacion de la memoria buffer en cero mientras no suceda el disparo
puntero_reset <= NOT Shoot_trigger ;

-- ========================================
-- TIMERS OFF DELAY: Bloques para agregar delays
-- =========================================
-- estos timers se usan para agregar tiempo de espera  entre la activacion o 
-- inicio de medicion de cada ADC de forma secuencial, el TIMER1 habilita al 
-- modulo SPI 1 para iniciar el muestreo de los ADC 1 y 5, al mismo tiempo, 
-- cuando se habilite este modulo, se inicia la activacion del siguiente TIMER
-- para habilitar el sioguiente modulo SPI, todo esto se hace de forma secuencial 
-- y controlada por la maquina de estados FMS00:FMS_SPI_Control
TIMER1: timer -- agrega delay para medicion de ADC 1 y 5
  PORT MAP ( CLK    => clk_TIMERS,  -- modificar este clock si se queire modificar el tiempo de muestreo
             RESET  => RST_timers(0),
             ENABLE => EN_timers(0),          
             set    => x"10",
             ready  => READY_timers(0));  -- seteado para contar 16 pulsos de reloj y activar la señal ready
TIMER2: timer -- agrega delay para medicion de ADC 2 y 6
   PORT MAP ( CLK    => clk_TIMERS,
             RESET  => RST_timers(1),
             ENABLE => EN_timers(1),          
             set    => x"10",
             ready  => READY_timers(1));  -- seteado para contar 16 pulsos de reloj y activar la señal ready
TIMER3: timer -- agrega delay para medicion de ADC 3 y 7
   PORT MAP ( CLK    => clk_TIMERS,
             RESET  => RST_timers(2),
             ENABLE => EN_timers(2),          
             set    => x"10",
             ready  => READY_timers(2)); -- seteado para contar 16 pulsos de reloj y activar la señal ready
TIMER4: timer -- agrega delay para medicion de ADC 4 y 8
   PORT MAP ( CLK    => clk_TIMERS,
             RESET  => RST_timers(3),
             ENABLE => EN_timers(3),          
             set    => x"10",
             ready  => READY_timers(3)); -- seteado para contar 16 pulsos de reloj y activar la señal ready

-- =======================================
-- MODULO SPI 1: controla el ADC 1 y 5
-- ======================================
  SPI_Instance1 : Interface_SPI
    GENERIC MAP ( data_length => 15  )
    PORT MAP (
      clk       => clk_SPIs,
      reset_n   => '1',
      stop      => STOP_SPI(0),
      enable    => '1',
      cpol      => '0',
      cpha      => '1',
      miso      => SDO_1,
      sclk      => SCLK_1,
      ss_n      => CS,   
      mosi      => OPEN,
      busy      => spi_busy,
      tx        => (others => '0'),
      rx        => spi_rx );  


-- =======================================
-- MODULO SPI 2: controla el ADC 2 y 6
-- ======================================
  SPI_Instance2 : Interface_SPI
    GENERIC MAP (  data_length => 15   )
    PORT MAP (
      clk     => clk_SPIs,
      reset_n => '1',
      enable  => '1',
      stop    => STOP_SPI(1),
      cpol    => '0',
      cpha    => '1',
      miso    => SDO_2,
      sclk    => SCLK_2,
      ss_n    => CS2,
      mosi    => OPEN,
      busy    => spi_busy2,
      tx      => (others => '0'),
      rx      => spi2_rx );  

-- =======================================
-- MODULOS SPI 3: controla el ADC 3 y 7
-- ======================================
  SPI_Instance3 : Interface_SPI
    GENERIC MAP (
      data_length => 15     
    )
    PORT MAP (
      clk       => clk_SPIs,
      reset_n   => '1',
      enable    => '1',
      stop      => STOP_SPI(2),
      cpol      => '0',
      cpha      => '1',
      miso      => SDO_3,      
      sclk      => SCLK_3,
      ss_n      => CS3,
      mosi      => OPEN,
      busy      => spi_busy3,
      tx        => (others => '0'),
      rx        => spi3_rx
    );  

  

-- =======================================
-- MODULOS SPI 4: controla el ADC 4 y 8
-- ======================================
  SPI_Instance4 : Interface_SPI
    GENERIC MAP ( data_length => 15   )
    PORT MAP (
      clk       => clk_SPIs,
      reset_n   =>'1',
      enable    => '1',
      stop      => STOP_SPI(3),
      cpol      => '0',
      cpha      => '1',
      miso      => SDO_4,     
      sclk      => SCLK_4,
      ss_n      => CS4,
      mosi      => OPEN,
      busy      => spi_busy4,
      tx        => (others => '0'),
      rx        => spi4_rx   );   

-- ===================================================================================
-- Proceso: Conmutacion de los 8 CHIP SELECT
-- ===================================================================================
-- 4CS es el CHIP SELECT del 4to modulo SPI que controla los ADC 4 y 8
-- se cuenta los flancos de subida de este CS para determinar que grupo de 4 ADCs 
-- estan trabajando y direccionar los CS ya que entre los dos grupos de 4 cada ADC 
-- comparte una misma salida CS por los multiplexores y porque se usa 5 modulos SPI  
Conmutacion_CS:process (contador_4CS(0), CS, CS2, CS3, CS4)
begin
    -- Inicializa todas las salidas a '1'
    CS_1 <= (others => '1');
    CS_2 <= (others => '1');
    CS_3 <= (others => '1');
    CS_4 <= (others => '1');

    -- Control de las salidas basado en contador_4CS(0)
    case contador_4CS(0) is
        when '0' =>
            CS_1(0) <= CS;
            CS_2(0) <= CS2;
            CS_3(0) <= CS3;
            CS_4(0) <= CS4;
        when '1' =>
            CS_1(1) <= CS;
            CS_2(1) <= CS2;
            CS_3(1) <= CS3;
            CS_4(1) <= CS4;
        when others =>
            -- No hacer nada, las salidas ya están inicializadas a '1'
            null;
    end case;
end process;

BUS_CS <= CS_4&CS_3&CS_2&CS_1;



-- ===================================================================================
-- Proceso: contador para el control del selector de los MULTIPLEXORES 74CBTLV3257-Q100 
-- ===================================================================================
-- 4CS es el CHIP SELECT del 4to modulo SPI que controla los ADC 4 y 8, su paso de 0 a 1
-- indica que se estan trabajando con 4 ADCs (del 1 al 4 para un valor 4CS = '0'
--  y del 5 al 8 para un valor de 4CS = '1'),  el selector en ambos multiplexores 
-- van conectados a BUS_MULTIPLEX(1) y BUS_MULTIPLEX(3) y los enable de ambos 
-- siempre estan activados (BUS_MULTIPLEX(0) y BUS_MULTIPLEX(2) a CERO)   
-- BUS_MUL va conectado a S2 & E2 & S1 & E1 de los multiplexores
    counter_4CS_proc:process (CS4,reset_contador)
    begin
        if ( reset_contador = '1') then
            contador_4CS  <= (others => '0'); -- Reinicio asíncrono
    elsif rising_edge(CS4) then         
            contador_4CS  <=contador_4CS  + 1; -- Incremento en cada flanco de subida 2 DIRECIONES
        end if;
    end process;

reset_contador  <= '1' when ( contador_4CS  = 2 )  else '0';

BUS_MULTIPLEX(0)  <= '0'; 
BUS_MULTIPLEX(2)  <= '0'; 
BUS_MULTIPLEX(1)  <=contador_4CS(0);              
BUS_MULTIPLEX(3)  <= contador_4CS(0); 
BUS_MUL <= BUS_MULTIPLEX;


-- ===================================================================================
-- Proceso: contador para el proceso de grabacion de datos en memorias 
-- ===================================================================================
-- La cuenta se incrementa cuando se han tomado 8 muestras
-- cuando llega a 1 se inicia el proceso de grabacion en la memoria
-- la memoria detecta que n_muestra  se incrementoi a 1 e iinicia el proceso de grabacion
-- de las 8 muestras, luego resetea el contador para volver a hacer lo mismo 
-- cuando se vuelva a tomar las 8 muestras continuas
-- este proceso se incia unicamente cuadno se a detectado que el trigger se a disparado

    counter_grabacion_proc:process (sample_ok,reset_grabacion,Shoot_trigger)
    begin
        if ( reset_grabacion = '1'  ) then
            muestra_ready  <=  (others => '0'); -- Reinicio asíncrono
    elsif rising_edge(sample_ok ) then         
               if Shoot_trigger = '1' then
                muestra_ready <= muestra_ready +1;
            end if;
            end if;
    end process;

n_muestra  <= std_logic_vector(muestra_ready);

-- ===================================================================================
--  Visualizacion de muestras tomadas por los 8 ADCs
-- ===================================================================================
-- Esta parte es opcional, se utiliza solo para comprobar viualmente que 
-- estan tomando datos, los valores se ven en los 16 leds de la basys3, con el selector
-- se puede conmutar entr los 8 valores de los ADCs tomados

seleccionador <= SELEC;
led_s <=  R01 when ( seleccionador = "000" ) else
          R02 when ( seleccionador = "001" ) else
          R03 when ( seleccionador = "010" ) else
          R04 when ( seleccionador = "011" ) else
          R05 when ( seleccionador = "100" ) else
          R06 when ( seleccionador = "101" ) else
          R07 when ( seleccionador = "110" ) else
          R08;       
             
  led <=  '0'&led_s;
  
  -- ===================================================================================
 --  Envio de muestras tomadas  para el buffer
 -- ===================================================================================
  --  cada muestra obtenida por los 8 ADC es enviada al buffer y espera el momento 
  --  del disparo del trigger para ser grabadas
  
  sample_ADC1 <= R01;  
  sample_ADC2 <= R02; 
  sample_ADC3 <= R03; 
  sample_ADC4 <= R04; 
  sample_ADC5 <= R05;  
  sample_ADC6 <= R06; 
  sample_ADC7 <= R07; 
  sample_ADC8 <= R08; 
  
end Behavioral;