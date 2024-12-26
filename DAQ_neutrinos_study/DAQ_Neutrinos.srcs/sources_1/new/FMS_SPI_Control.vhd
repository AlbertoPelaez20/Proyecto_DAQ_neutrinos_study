-- ===================================================================================
  -- Proceso: maquina de estados para el control de los modulos SPI
  -- ===================================================================================
 --  Este bloque contioene la maquina de estados encargada del proceso de habilitacion, 
 --  inicio y stop de los modulos SPI, tambien se encarga de almacennar las mediciones 
 --  obtenidas por los 8 ADCs en registros auxiliares para su posterior grabacion en 
 --  en la memoria buffer
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
entity FMS_SPI_Control is
   Port ( ONN                : in std_logic;
          RESET             : in std_logic;
          muestra_lista     : out std_logic; 
          clk_FMS           : in std_logic;       
          CS,CS2,CS3,CS4    : in std_logic; 
          STOP_SPI          : in std_logic_vector   ( 3 downto 0);
          RST_timers        : out std_logic_vector  ( 3 downto 0);
          EN_timers         : out std_logic_vector  ( 3 downto 0);
          EN_SPIs           : out std_logic_vector  ( 3 downto 0);
          R01,R02,R03,R04   : out std_logic_vector  (14 downto 0);
          R05,R06,R07,R08   : out std_logic_vector  (14 downto 0);
          spi_rx,spi2_rx    : in std_logic_vector   (14 downto 0);
          spi3_rx,spi4_rx   : in std_logic_vector   (14 downto 0)
          );
end FMS_SPI_Control;

architecture Behavioral of FMS_SPI_Control is


    -- Declaración de señales internas
  signal t_cnt : unsigned(7 downto 0) := (others => '0'); -- Contador
  signal num_iteracion : std_logic_vector(7 downto 0) := (others => '0');
  signal Reset_num_iteracion, incrementa_iteraciones : std_logic := '0';
  signal ESTADO : std_logic_vector(3 downto 0):= "0000";
  
  
  signal Load_R : std_logic_vector(7 downto 0);      
  signal Load_R_prev : std_logic_vector(7 downto 0) := (others => '0');
  
  signal Load_R1,Load_R2,Load_R3,Load_R4: std_logic:='0';
  signal Load_R5,Load_R6,Load_R7,Load_R8: std_logic:='0';
   
type state_type is (
    IDLE,           -- Espera inicial
    INICIAR_SP1,    -- habilita timer1 
    WAIT_TIMER1,    -- espera la cuenta del timer1
    INICIAR_SP2,    -- inicia SPI1 Y habilita timer2
    WAIT_TIMER2,    -- espera la cuenta del timer2
    INICIAR_SP3,    -- inicia SPI2 Y habilita timer3
    WAIT_TIMER3,    -- espera la cuenta del timer3
    INICIAR_SP4,    -- inicia SPI3 Y habilita timer4
    WAIT_TIMER4,    -- espera la cuenta del timer4
    ALL_CS_LOW,     -- inicia SPI4 y espera que que todos los CS suban
    COMPLETE_RESET  -- resetea timers y vuelve al estado IDLE
  );
  signal PS, NS : state_type;
begin
   -- =============================================
   -- Proceso síncrono: Máquina de estados
   -- =============================================
   sync_proc: process(clk_FMS, RESET)
    begin
        if (RESET = '1') then
            PS <= IDLE;
        elsif (rising_edge(clk_FMS)) then
            PS <= NS;
        end if;
    end process sync_proc;

   -- ====================================================
   -- Proceso combinacional: Lógica de la máquina de estados
   -- ====================================================
    comb_proc: process(PS, ONN,CS,CS2,CS3,CS4,STOP_SPI,num_iteracion)
    begin
        -- Reset de señales de salida
        EN_SPIs     <= "0000";
        RST_timers  <= "0000";
        EN_timers   <= "0000"; 
       -- BUS_LOAD_REGISTERS <= x"00";
        Reset_num_iteracion <= '0';
        ESTADO   <= x"0";
        case PS is
            -- Estado inicial: Espera de señal de activación            
            when IDLE =>
                ESTADO   <= x"1";
                EN_SPIs     <= "0000";
                RST_timers  <= "0000";
                EN_timers   <= "0000";
                if ONN = '1' then
                   NS  <= INICIAR_SP1;
                else   
                   NS  <= IDLE;  
                end if;                   
            -- habilita timer1 
            when INICIAR_SP1 =>   
                ESTADO   <= x"2";  
                if num_iteracion = x"02" then
                    Reset_num_iteracion <= '1';
                end if;
                RST_timers  <= "0000";
                EN_timers   <= "0001";   
                EN_SPIs     <= "0000";            
                NS          <= WAIT_TIMER1;
           -- espera la cuenta del timer1
            when WAIT_TIMER1 =>
                ESTADO      <= x"3"; 
                RST_timers  <= "0000";
                EN_timers   <= "0001"; 
                EN_SPIs     <= "0000";                  
                if CS = '0' then
                   NS  <= INICIAR_SP2;
                else   
                   NS  <=  WAIT_TIMER1;  
                end if;    
            -- inicia SPI1 Y habilita timer2            
            when INICIAR_SP2 =>
               ESTADO       <= x"4"; 
               EN_SPIs      <= '0'&'0'&'0'&CS; 
               RST_timers   <= "0000";
               EN_timers    <= "0011"; 
               NS           <= WAIT_TIMER2;
            -- espera la cuenta del timer2  
              when WAIT_TIMER2 =>
               ESTADO       <= x"5"; 
               EN_SPIs      <= '0'&'0'&'0'&CS; 
               RST_timers   <= "0000";
               EN_timers    <= "0011"; 
            -- inicia SPI2 Y habilita timer3 
               if CS2 = '0' then
                   NS  <= INICIAR_SP3;
                 else   
                   NS  <=  WAIT_TIMER2;  
                end if;           
             -- espera la cuenta del timer3   
              when INICIAR_SP3 =>               
               ESTADO       <= x"6"; 
               EN_SPIs      <= '0'&'0'&CS2&CS; 
               RST_timers   <= "0000";
               EN_timers    <= "0111";                      
               NS           <= WAIT_TIMER3;
             -- espera la cuenta del timer3  
              when WAIT_TIMER3 =>              
               ESTADO       <= x"7"; 
               EN_SPIs      <= '0'&'0'&CS2&CS; 
               RST_timers   <= "0000";
               EN_timers    <= "0111";  
                 if CS3 = '0' then
                   NS  <= INICIAR_SP4;
                 else   
                   NS  <=  WAIT_TIMER3;  
                end if;     
              --inicia SPI3 Y habilita timer4         
              when INICIAR_SP4 =>
               ESTADO       <= x"8"; 
               EN_SPIs      <= '0'&CS3&CS2&CS; 
               RST_timers   <= "0000";
               EN_timers    <= "1111";            
               NS           <= WAIT_TIMER4;  
             --espera la cuenta del timer4              
              when  WAIT_TIMER4 =>             
               ESTADO       <= x"9";  
               EN_SPIs      <= '0'&CS3&CS2&CS;  
               RST_timers   <= "0000";
               EN_timers    <= "1111";     
               if CS4 = '0' then
                  NS  <= ALL_CS_LOW;
               else   
                   NS  <=  WAIT_TIMER4;  
               end if; 
            -- inicia SPI4 y espera que que todos los CS suban             
             when ALL_CS_LOW =>
               ESTADO   <= x"A";                
               EN_SPIs<= CS4&CS3&CS2&CS;   
               RST_timers <= "0000";
               EN_timers   <= "1111";              
               if (STOP_SPI = "1111") then
                   incrementa_iteraciones  <= '1';
                   NS  <= COMPLETE_RESET;
               else   
                   NS  <=  ALL_CS_LOW;  
               end if;               
             -- resetea timers y vuelve al estado IDLE         
             when  COMPLETE_RESET =>            
               ESTADO   <= x"B";  
               incrementa_iteraciones  <= '0';
               RST_timers <= "1111";
               EN_timers  <= "0000";
               EN_SPIs    <= "0000";   
               NS  <=IDLE; 
           -- otros casos                   
            when others =>            
               ESTADO   <= x"F"; 
               NS  <= IDLE;               
        end case;
    end process;

    -- Señales para guardar datos obtenidos de los ADCs
    
    Load_R1 <= '1' WHEN ( num_iteracion = x"01" AND CS4=  '1'  )ELSE '0';
    Load_R5 <= '1' WHEN ( num_iteracion = x"02" AND CS4=  '1'  )ELSE '0';
    Load_R2 <= '1' WHEN ( num_iteracion = x"01" AND CS4=  '1' )ELSE '0';
    Load_R6 <= '1' WHEN ( num_iteracion = x"02" AND CS4=  '1'  )ELSE '0';
    Load_R3 <= '1' WHEN ( num_iteracion = x"01" AND CS4=  '1'  )ELSE '0';
    Load_R7 <= '1' WHEN ( num_iteracion = x"02" AND CS4=  '1'  )ELSE '0';
    Load_R4 <= '1' WHEN ( num_iteracion = x"01" AND CS4=  '1'  )ELSE '0';
    Load_R8 <= '1' WHEN ( num_iteracion = x"02" AND CS4=  '1'  )ELSE '0';

    Load_R <= Load_R8 & Load_R7 & Load_R6 & Load_R5 & Load_R4 & Load_R3 & Load_R2 & Load_R1;

    muestra_lista  <=  Load_R8; -- señal para avisar que ya se an tomado 8 muestras consecutivas

    -- Proceso para almacenar los datos de los ADCs en registros auxiliares R01 hasta R08
    save_proces:process(clk_FMS,Load_R,Load_R_prev)
    begin
        if rising_edge(clk_FMS) then
        
            for i in 0 to 7 loop
             if (Load_R(i) = '1' and Load_R_prev(i) = '0') then
                 case i is
                        when 0 => R01 <= spi_rx;
                        when 1 => R02 <= spi2_rx;
                        when 2 => R03 <= spi3_rx;
                        when 3 => R04 <= spi4_rx;
                        when 4 => R05 <= spi_rx;
                        when 5 => R06 <= spi2_rx;
                        when 6 => R07 <= spi3_rx;
                        when 7 => R08 <= spi4_rx;
                        when others => null;
                    end case;
                end if;
            end loop;

            -- Actualizar el estado previo
            Load_R_prev <= Load_R;
        end if;
    end process;

   -- ===========================================================================
   -- Proceso: incremento del numero de iteraciones de lectura de 4 ADCs
   -- ===========================================================================
    counter_increment_proc:process (incrementa_iteraciones ,  Reset_num_iteracion)
    begin
        if ( Reset_num_iteracion = '1') then
            t_cnt <= (others => '0'); -- Reinicio asíncrono
        elsif rising_edge(incrementa_iteraciones ) then
            t_cnt <= t_cnt + 1; -- Incremento en cada flanco de subida 2 DIRECIONES
        end if;
    end process;
    
    num_iteracion <= std_logic_vector(t_cnt);
     
end Behavioral;
