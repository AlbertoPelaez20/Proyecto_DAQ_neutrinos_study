
# DAQ-VHDL

**Implementación en VHDL de un sistema de aquisicion de datos** 

En este repositorio se encuentra la implementacion en VHDL de un sistema de aquisicion de datos digital (DAQ) basado en el control en cascada de 8 ADCs, dos multiplexores  y un DAC . Este sistema debera ser capaz de muestrear señales variando el tiempo de muestreo de los ADCs y la comumnutacion de los multiplexores. 




## Indice del proyecto

- Objetivo
- Diseño del sistema
- Diagrama de bloques
- Etapas de control
- Hardware 
- Pruebas


## Caracteristicas

- **Diseño del sistema**: El cuncionamiento de DAQ esta basado en el control en cascada de 8 ADCs de la marca Texas Instruments modelo **ADS7046** de 12-Bit, dos multiplexores **74CBTLV3257-Q100** y un DAC **MCP4725**. Los ADCs usan protocolo SPI mientras el DAC I2C. 

El diseño en VHDL debe considerar  el siguiente diagrama de bloques: 

![App Screenshot](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/Diagrama_de_bloques1.jpg?raw=true)

- **Diseño del sistema**: El cuncionamiento de DAQ esta basado en el control en cascada de 8 ADCs de la marca Texas Instruments modelo **ADS7046** de 12-Bit, dos multiplexores **74CBTLV3257-Q100** y un DAC **MCP4725**. Los ADCs usan protocolo SPI mientras el DAC I2C. 





El control de que se plantea es uno en cascada donde cada ADC comienza el muestreo y conversion de datos de forma secuencial, es decir, el inicio del primero desencadena despues de un un lapso de tiempo pequeño, el muestreo del siguiente, y asi sucesivamente hasta que los 8 ADCs completen una medicion. Luego el proceso se volvera a realizar desde el primero ADC de forma indefinida hasta que la señal de disparo determine el fin del muestreo. 





- Diagramas de bloques
- Pruebas simuladas (testbench)
- Pruebas reales


## Screenshots


![DIAGRAMA2](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/blob/main/imagenes/Diagrama4.jpg?raw=true)


## Tech Stack

**Programming Languages:** VHDL, MATLAB, C/C++

**Protocols:** SPI, I2C


## Documentation

[Documentation](https://github.com/AlbertoPelaez20/Proyecto_DAQ_neutrinos_study/tree/main/Datasheeds)
