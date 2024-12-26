-- =================================================
-- M�dulo UART para el env�o de datos caracteriticos
-- =================================================
-- bloque para el envio de 3 bytes obtenidos del muestreo 
-- de los ADCs. Los 2 primeros bytes representan el maximo 
-- valor de las mediciones, el segundo indica  el numero
-- de la muestra a la que pertenece el valor Pico

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity UART_features is
    Port (
        SEND_1, CLK       : in  STD_LOGIC;                     -- Se�ales de entrada: bot�n de env�o y reloj
        NH_ADC, NL_ADC    : in  STD_LOGIC_VECTOR (7 downto 0); -- Datos a enviar por UART
        numero_de_muestra : in  STD_LOGIC_VECTOR (7 downto 0); -- Datos a enviar por UART
        UART_TX_o_1       : out STD_LOGIC                      -- Salida UART
    );
end UART_features;

architecture Behavioral of UART_features is
   -- =============================================
   -- Declaraci�n de componentes
   -- =============================================
    component UART_TX is
        Port (
            SEND      : in  STD_LOGIC;
            DATA      : in  STD_LOGIC_VECTOR (7 downto 0);
            CLK       : in  STD_LOGIC;
            READY     : out STD_LOGIC;
            UART_TX_o : out STD_LOGIC
        );
    end component;

  
    -- =============================================
    -- Declaraci�n de se�ales internas
    -- =============================================
    signal dato_a_enviar : std_logic_vector(7 downto 0) := (others => '0'); -- Dato actual a enviar por UART
    signal CUENTA2       : std_logic_vector(7 downto 0) := (others => '0'); -- Contador de datos enviados
    signal clk_s         : std_logic := '0';                                -- Reloj interno
    signal READY_S       : std_logic := '0';                                -- Se�al de listo del UART
    signal HABILITADOR   : std_logic := '0';                                -- Se�al para habilitar env�o
    signal TX            : std_logic := '0';                                -- Salida UART

    -- =============================================
    -- Constantes
    -- =============================================
    constant NUM_DATOS : std_logic_vector(7 downto 0) := x"03";            -- N�mero de datos a enviar

    -- =============================================
    -- Declaraci�n de tipo y se�al para la m�quina de estados
    -- =============================================
    type state_type is (IDLE, LOAD_DATA, SEND_DATA, WAIT_START, WAIT_READY); -- Estados de la FSM
    signal state : state_type := IDLE;
    
    -- =============================================
    -- Se�ales sincronizadas con el reloj
    -- =============================================
    signal NH_ADC_s, NL_ADC_s, tiempo_s : std_logic_vector(7 downto 0);

begin

    -- =============================================
    -- Asignaciones iniciales
    -- =============================================
    clk_s <= CLK;                                     -- Asignaci�n del reloj principal 
    NH_ADC_s <= NH_ADC;                               -- Asignaci�n del nibble superior
    NL_ADC_s <= NL_ADC;                               -- Asignaci�n del nibble inferior
    tiempo_s <= numero_de_muestra;                               -- Asignaci�n del numero de muestra dle valor pico     

    -- =============================================
    -- Instancia del transmisor UART
    -- =============================================
    uart_01: UART_TX
        port map (
            SEND      => HABILITADOR,
            DATA      => dato_a_enviar,
            CLK       => clk_s,
            READY     => READY_S,
            UART_TX_o => TX
        );

    -- Asignaci�n de salida UART
    UART_TX_o_1 <= TX;

    

   -- =============================================
    -- M�quina de estados para controlar la transmisi�n UART
    -- =============================================
    next_txState_process: process (clk_s,SEND_1, CUENTA2)
    begin
        if rising_edge(clk_s) then
            case state is

                when IDLE =>
                    -- Estado de espera inicial
                    if SEND_1 = '1' then                          
                        CUENTA2 <= x"00";             -- Reiniciar contador de datos
                        state <= LOAD_DATA;           -- Pasar al siguiente estado
                    end if;

                when LOAD_DATA =>
                    -- Cargar datos desde la memoria
                    if CUENTA2 < NUM_DATOS then                        
                        HABILITADOR <= '1';           -- Habilitar env�o
                        state <= SEND_DATA;           -- Pasar al estado de env�o
                    else
                        state <= IDLE;                -- Regresar al estado inicial
                    end if;

                when SEND_DATA =>
                    -- Enviar dato por UART
                    if READY_S = '1' then
                        HABILITADOR <= '0';           -- Deshabilitar env�o
                        state <= WAIT_START;          -- Pasar al estado de espera inicial
                    end if;

                when WAIT_START =>
                    -- Esperar a que la l�nea UART est� lista
                    if TX = '0' then
                        state <= WAIT_READY;          -- Pasar al estado de espera de listo
                    end if;

                when WAIT_READY =>
                    -- Esperar que UART indique listo para enviar
                    if READY_S = '1' then
                        CUENTA2 <= CUENTA2 + 1;       -- Incrementar contador de datos enviados
                        state <= LOAD_DATA;           -- Cargar siguiente dato
                    end if;

                when others =>
                    state <= IDLE;                    -- Estado por defecto

            end case;
        end if;
    end process;

    -- ===============================================================
    -- Multiplexor para seleccionar el dato a enviar basado en el contador
    -- ===============================================================
    dato_a_enviar  <=  NH_ADC_s  when (CUENTA2 = x"00") else
                       NL_ADC_s  when (CUENTA2 = x"01") else
                       tiempo_s  when (CUENTA2 = x"02") else
                       x"20";    -- Espacio por defecto

end Behavioral;
