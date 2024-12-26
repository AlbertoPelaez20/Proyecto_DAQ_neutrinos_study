-- =============================================
-- M�dulo UART para el env�o de datos almacenados en la memoria
-- =============================================
-- bloque para el envio de 254 bytes obtenidos del muestreo 
-- de los ADCs. Se envia por protocolo UART al MATLAB 
-- para su analisis y simulacion

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity UART_MATLAB is
     Port ( SEND_1            : in  STD_LOGIC;                       -- Se�al para iniciar la transmisi�n
            DATA_1            : in  STD_LOGIC_VECTOR (7 downto 0);   -- Dato de entrada a transmitir
            DIRECCION         : out STD_LOGIC_VECTOR (7 downto 0);   -- Direcci�n de memoria
            CLK_1             : in  STD_LOGIC;                       -- Reloj principal
            UART_TX_o_1       : out STD_LOGIC);                      -- Salida UART
end UART_MATLAB;

architecture Behavioral of UART_MATLAB is

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
    
    signal DIR          : std_logic_vector(7 downto 0) := (others => '0'); -- Direcci�n de memoria
    signal dato_a_enviar: std_logic_vector(7 downto 0) := (others => '0'); -- Dato actual a enviar por UART
    signal CUENTA2      : std_logic_vector(7 downto 0) := (others => '0'); -- Contador de datos enviados
    signal clk_s        : std_logic := '0';                                -- Reloj interno
    signal READY_S      : std_logic := '0';                                -- Se�al de listo del UART
    signal HABILITADOR  : std_logic := '0';                                -- Se�al para habilitar env�o
    signal TX           : std_logic := '0';                                -- Salida UART

    -- =============================================
    -- Constantes
    -- =============================================
    constant NUM_DATOS : std_logic_vector(7 downto 0) := x"FE";           -- N�mero de datos a enviar

    -- =============================================
    -- Declaraci�n de tipo y se�al para la m�quina de estados
    -- =============================================
    type state_type is (IDLE, LOAD_DATA, SEND_DATA, WAIT_START, WAIT_READY);
    signal state : state_type := IDLE;

begin

    -- =============================================
    -- Asignaciones iniciales
    -- =============================================
    clk_s <= CLK_1;                                  -- Asignaci�n del reloj principal a una se�al interna
    DIRECCION <= DIR;                                -- Asignaci�n de direcci�n de memoria a la salida
    UART_TX_o_1 <= TX;                               -- Asignaci�n de salida UART

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

       -- =============================================
    -- M�quina de estados para controlar la transmisi�n UART
    -- =============================================
    next_txState_process: process (clk_s, SEND_1, CUENTA2)
    begin
        if rising_edge(clk_s) then
            case state is

                -- Estado de espera inicial
                when IDLE =>
                    if SEND_1 = '1' then
                        DIR <= (others => '0');       -- Direcci�n inicial
                        CUENTA2 <= x"00";             -- Reiniciar contador de datos
                        state <= LOAD_DATA;           -- Pasar al siguiente estado
                    end if;

                -- Cargar datos desde la memoria
                when LOAD_DATA =>
                    if CUENTA2 < NUM_DATOS then
                        dato_a_enviar <= DATA_1;      -- Leer dato desde la memoria
                        HABILITADOR <= '1';           -- Habilitar env�o
                        state <= SEND_DATA;           -- Pasar al estado de env�o
                    else
                        state <= IDLE;                -- Regresar al estado inicial
                    end if;

                -- Enviar dato por UART
                when SEND_DATA =>
                    if READY_S = '1' then
                        HABILITADOR <= '0';           -- Deshabilitar env�o
                        state <= WAIT_START;          -- Pasar al estado de espera inicial
                    end if;

                -- Esperar a que la l�nea UART est� lista
                when WAIT_START =>
                    if TX = '0' then
                        DIR <= DIR + 1;               -- Incrementar direcci�n de memoria
                        state <= WAIT_READY;          -- Pasar al estado de espera de listo
                    end if;

                -- Esperar que UART indique listo para enviar
                when WAIT_READY =>
                    if READY_S = '1' then
                        CUENTA2 <= CUENTA2 + 1;       -- Incrementar contador de datos enviados
                        state <= LOAD_DATA;           -- Cargar siguiente dato
                    end if;

                -- Estado por defecto
                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;
end Behavioral;
