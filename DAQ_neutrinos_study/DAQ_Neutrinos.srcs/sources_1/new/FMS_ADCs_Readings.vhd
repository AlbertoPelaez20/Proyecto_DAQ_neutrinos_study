-- ===================================================================================
-- Maquina de estados para el proceso de grabacion de datos muestreados
-- ===================================================================================
--  Este bloque contioene una maquina de estados encargada del proceso de grabacion 
-- en la memoria buffer de los datos muestreados SOLO el tiempo que dure el disparo

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity FMS_ADCs_Readings is

 Port (     ONN       : in std_logic;
            CLK       : in std_logic;
            RESET     : in std_logic;        
            GUARDAR,RESET_CONT   : out std_logic;        
            CUENTA    : in std_logic_vector(1 downto 0)
        );
end FMS_ADCs_Readings;

architecture Behavioral of FMS_ADCs_Readings is
    type state_type is (stand_by,muestreo,grabar);
    signal PS,NS : state_type;
    begin
   
        sync_proc: process(CLK,NS,RESET)
            begin
            if (RESET = '1') then PS <= stand_by;
            elsif (rising_edge(CLK)) then PS <= NS;
            end if;
        end process sync_proc;
        
        comb_proc: process(PS,ONN,CUENTA)
        begin
        case PS is
            when stand_by => 
                  GUARDAR  <= '0';
                  RESET_CONT <= '0';
               if ( ONN = '1'  ) then NS <= muestreo; 
                  else NS <= stand_by; 
                  end if;              
            when muestreo => 
               if ( ONN = '0'  ) then NS <= stand_by; 
                 elsif (("01" = CUENTA ) )then NS <= grabar ; 
                else NS <=  muestreo;                        
               end if;
         when grabar =>            
             GUARDAR      <= '1';
             RESET_CONT   <= '1';
              NS <=  stand_by ;
          when others => -- the catch all condition
            NS <= stand_by;
            end case;
        end process comb_proc;
end Behavioral;
