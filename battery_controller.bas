


#no_table
setfreq m8

        SYMBOL  RS        = 2         ; 0 = Command   1 = Data
        SYMBOL  E         = 3         ; 0 = Idle      1 = Active
        SYMBOL  DB4       = 4         ; LCD Data Line 4
        SYMBOL  DB5       = 5         ; LCD Data Line 5
        SYMBOL  DB6       = 6         ; LCD Data Line 6
        SYMBOL  DB7       = 7         ; LCD Data Line 7

        SYMBOL  RSCMDmask = %00000000 ; Select Command register
        SYMBOL  RSDATmask = %00000100 ; Select Data register
        
        SYMBOL sendbyte = b20
        SYMBOL counter  = b21
        SYMBOL  rsbit     	= b19

	SYMBOL BattV = 0
	SYMBOL LoadA = 2
	SYMBOL PanelA = 1
	SYMBOL PanelV = 3

	SYMBOL BattVR = w0 	'b0 b1
	SYMBOL LoadAR = w1 	'b2 b3
	SYMBOL PanelAR = w2 	'b4 b5
	SYMBOL PanelVR = w3 	' b6 b7
	SYMBOL LoadAH = w4 	'b8 b9
	SYMBOL PanelAH = w5 	'b10 b11
	SYMBOL LoadAHtemp = w6	'b12 b13
	SYMBOL PanelAHtemp = w7 	'b14 b15

	SYMBOL DisplaySwitch = b18
	SYMBOL LoadInd = b17
	SYMBOL PanelInd = b21
	SYMBOL IntFlag = b22

	SYMBOL Load = 4
	SYMBOL Panel = 5
        
              'Store Data in EEPROM
      
        ' Nibble commands - To initialise 4-bit mode on LCD

      EEPROM 0,( $33 )    ; %0011---- %0011----   8-bit / 8-bit
      EEPROM 1,( $32 )    ; %0011---- %0010----   8-bit / 4-bit

         'Byte commands - To configure the LCD

      EEPROM 2,( $28 )    ; %00101000 %001LNF00   Display Format
      EEPROM 3,( $0C )    ; %00001100 %00001DCB   Display On
      EEPROM 4,( $06 )    ; %00000110 %000001IS   Cursor Move

                            ; L : 0 = 4-bit Mode    1 = 8-bit Mode
                            ; N : 0 = 1 Line        1 = 2 Lines
                            ; F : 0 = 5x7 Pixels    1 = N/A
                            ; D : 0 = Display Off   1 = Display On
                            ; C : 0 = Cursor Off    1 = Cursor On
                            ; B : 0 = Cursor Steady 1 = Cursor Flash
                            ; I : 0 = Dec Cursor    1 = Inc Cursor
                            ; S : 0 = Cursor Move   1 = Display Shift

      EEPROM 5,( $01 )    ; Clear Screen
      EEPROM 10,("Toggle Switch To Reset")
      EEPROM 40,("Reset")
 
gosub InitialiseLcd
pause 100


low portc load

low portc panel
if portc pin6 = 1 then
  b0=1
endif
FOR counter = 10 TO 22
  READ counter,sendbyte
  GOSUB SendDataByte
NEXT
sendbyte=$c0
GOSUB SendCmdByte
FOR counter = 24 TO 31
  READ counter,sendbyte
  GOSUB SendDataByte
NEXT
pause 6000
if portc pin6=1 then
  b1=1
endif
if b0!=b1 then
  write 100,0
  write 101,0
  sendbyte=$01
  GOSUB SendCmdByte
  FOR counter = 40 TO 44
    READ counter,sendbyte
    GOSUB SendDataByte
  NEXT
endif

read 100,LoadAH
read 101,PanelAH
pause 1000
sendbyte=$01
GOSUB SendCmdByte
symbol EVENTS_PER_SEC = 2 ' set to twice the required PWM frequency (actually, slightly higher because of interrupt overhead)

symbol DUMMY_VAL = 65536 - t1s_8
symbol TIMER_PRELOAD_VAL_DIFF = DUMMY_VAL / EVENTS_PER_SEC
symbol TIMER_PRELOAD_VAL = 65536 - TIMER_PRELOAD_VAL_DIFF
settimer TIMER_PRELOAD_VAL
gosub timer_setup

readadc10 PanelV,PanelVR
PanelVR=PanelVR*50/102*57/10+10
if PanelVR>1500 then
high portc Panel
PanelInd = 1
endif

start:

readadc10 BattV,BattVR

readadc10 LoadA,LoadAR

readadc10 PanelA,PanelAR
'w4=w4-1
'w4=w4*50
'w4=w4/13
'w4=w4-3
LoadAR=LoadAR*50/13
'w3=526-w2
'w3=w3*50
'w3=w3/58
PanelAR=527-PanelAR*50/58
'w3=w3/10
'w3=w3-452

BattVR=BattVR*50/102*57/10+10
if BattVR>1440 then 'Battery is charged, turn off solar panels
  if BattVR>1460 then 'Over voltage, emergancy power off load
    low portc Load
    LoadInd=0
  endif
  low portc Panel
  PanelInd=0
else 
  if BattVR<1280 then 'Battery needs charging, turn on solar panels
    high portc Panel
    PanelInd=1
  endif
endif







if BattVR<1120 then ' Battery is flat turn off load
  low portc Load
  LoadInd=0
  b16=20
endif

if BattVR>1180 and b16=0 then 'Battery has enough power, turn on load
  if portc pin6 = 1 then ' Only if switch is on
    high portc Load
    LoadInd=1
  else
    low portc Load
    LoadInd=0
  endif
endif

inc DisplaySwitch 

if IntFlag=1 then
  IntFlag=0
  if b16>0 then
    dec b16
  endif
  LoadAHtemp=LoadAHtemp+LoadAR
  PanelAHtemp=PanelAHtemp+PanelAR
  if LoadAHtemp>7200 then
    inc LoadAH
    LoadAHtemp=LoadAHtemp-7200
    b25=LoadAH//10
    if b25=0 then
      write 100,LoadAH
      write 101,PanelAH
    endif
  endif
  if PanelAHtemp>7200 then
    inc PanelAH
    PanelAHtemp=PanelAHtemp-7200
    b25=PanelAH//10
    if b25=0 then
      write 100,LoadAH
      write 101,PanelAH
    endif
  endif
  if PanelAR<2 then
    low portc Panel
    PanelInd=0
  endif
  readadc10 PanelV,PanelVR
  PanelVR=PanelVR*50/102*57/10+10
  if PanelVR>1700 AND PanelInd=0 AND BattVR<1440 then
    high portc Panel
    PanelInd=1
  endif

bintoascii BattVR,b23,b24,b25,b26,b27
sendbyte=$80
gosub sendcmdbyte
sendbyte=b24
GOSUB SendDataByte
sendbyte=b25
GOSUB SendDataByte
sendbyte="."
GOSUB SendDataByte
sendbyte=b26
GOSUB SendDataByte
sendbyte=b27
GOSUB SendDataByte
sendbyte="v"
GOSUB SendDataByte

if DisplaySwitch<128 then
  bintoascii LoadAH,b23,b24,b25,b26,b27

else
  bintoascii PanelAH,b23,b24,b25,b26,b27
endif
  sendbyte=$87
  gosub sendcmdbyte
  sendbyte=b24
  GOSUB SendDataByte
  sendbyte=b25
  GOSUB SendDataByte
  sendbyte="."
  GOSUB SendDataByte
  sendbyte=b26
  GOSUB SendDataByte
  sendbyte=b27
  GOSUB SendDataByte
  sendbyte="A"
  GOSUB SendDataByte
  sendbyte="H"
  GOSUB SendDataByte
  sendbyte="-"
  GOSUB SendDataByte
if DisplaySwitch<128 then
  sendbyte="L"
  GOSUB SendDataByte
else
  sendbyte="P"
  GOSUB SendDataByte
endif

bintoascii LoadAR,b23,b24,b25,b26,b27
sendbyte=$c0
gosub sendcmdbyte
sendbyte=b24
GOSUB SendDataByte
sendbyte=b25
GOSUB SendDataByte
sendbyte="."
GOSUB SendDataByte
sendbyte=b26
GOSUB SendDataByte
sendbyte=b27
GOSUB SendDataByte
sendbyte="A"
GOSUB SendDataByte

bintoascii PanelAR,b23,b24,b25,b26,b27
sendbyte=$c8
gosub sendcmdbyte
sendbyte=b25
GOSUB SendDataByte
sendbyte="."
GOSUB SendDataByte
sendbyte=b26
GOSUB SendDataByte
sendbyte=b27
GOSUB SendDataByte
sendbyte="A"
GOSUB SendDataByte

sendbyte=$cf
gosub sendcmdbyte
if LoadInd=1 then
  sendbyte="*"
else
  sendbyte=" "
endif
GOSUB SendDataByte
sendbyte=$ce
gosub sendcmdbyte
if PanelInd=1 then
  sendbyte="S"
else
  sendbyte=" "
endif
GOSUB SendDataByte
endif
'sertxd (#w2,",",#w0,",",#w4,",",#w3,cr,lf)
'pause 250
goto start

'LCD Routines
InitialiseLcd:
      FOR counter = 0 TO 5
      	READ counter,sendbyte
      	GOSUB SendInitCmdByte
      NEXT
      RETURN

SendInitCmdByte:

      PAUSE 10                        ; Delay 15mS

SendCmdByte:

      'rsbit = RSCMDmask               ; Send to Command register
      rsbit = outpins
      rsbit = rsbit & %11 
      goto sendCmdOrDataByte

SendDataByte:
	rsbit = outpins
      rsbit = rsbit & %11 | RSDATmask               ; Send to Data register next
	
SendCmdOrDataByte:
      pins = sendbyte & %11110000 | rsbit ; Put MSB out first
      PULSOUT E,1                     ; Give a 10uS pulse on E
      pins = sendbyte * %00010000 | rsbit ; Put LSB out second
      PULSOUT E,1
      RETURN                     ; Give a 10uS pulse on E

interrupt:
IntFlag=1

gosub timer_setup
return

timer_setup:
    timer = 0xffff ' generate interrupt at next overflow
    toflag = 0 ' clear timer overflow flag
    setintflags %10000000,%10000000 ' interrupt on timer overflow
return
