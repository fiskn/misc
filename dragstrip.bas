SYMBOL lStage = b.4
SYMBOL rStage = c.5
SYMBOL Yellow1 = b.3
SYMBOL Yellow2 = c.2
SYMBOL Yellow3 = c.3
SYMBOL Green = b.6
SYMBOL rCheat = b.2
SYMBOL lCheat = c.4
SYMBOL soundchip = b.7
SYMBOL soundpin = b.5
SYMBOL lpaddle = pinc.6
SYMBOL rpaddle = pinc.7


#no_data
#no_table

start:
b1=0
b2=0
tmr3setup %10000001
sertxd (0,0,0,0)
'pause 1000
'low soundchip
'pause 100
'high soundchip
'pause 20000
'goto start

staging:
if lpaddle=1 and b10=0 then
  high lStage
  sound soundpin,(50,20)
  b10=1
endif

if rpaddle=1 and b11=0 then
  high rStage
  sound soundpin,(50,20)
  b11=1
endif

if lpaddle=0 and b10=1 then
  low lStage
  sound soundpin,(50,20,20,60)
  b10=0
endif

if rpaddle=0 and b11=1 then
  low rStage
  sound soundpin,(50,20,20,60)
  b11=0
endif

if b10=1 and b11=1 then
  readadc 9,b0
  if b0=129 then
    goto startrace
  endif
endif 

goto staging

startrace:

pause 1000
low soundchip
pause 100
high soundchip
b0=0
racestartloop:
if lpaddle=0 or rpaddle=0 then
  low soundchip
  pause 100
  high soundchip
  goto cheat
endif

'pause 3750
if b0=37 then
  high Yellow1
  sound soundpin,(100,20)
endif

'pause 500
if b0=42 then
  high Yellow2
  sound soundpin,(100,20)
endif

'pause 500
if b0=47 then
  high Yellow3
  sound soundpin,(100,20)
endif

'pause 500
if b0=52 then
  high Green
  timer3=0
  'sound soundpin,(110,120)
  goto race
endif
b0=b0+1
pause 100
goto racestartloop

race:
b1=0
b2=0
'low lstage
'low rstage
low yellow1
low yellow2
low yellow3
reacttime:
readadc 9,b0

if b0=233 then 
  goto actualreset
endif
'sertxd(#timer3,cr,lf)
sound soundpin,(110,20)
if lpaddle=0 and b1=0 then
  b1=1
  w20=timer3*32/10
  low lstage
endif
if rpaddle=0 and b2=0 then
  b2=1
  w21=timer3*32/10
  low rstage
endif
if b1=1 and b2=1 then
  sertxd (b40,b41,b42,b43)
  goto raceloop
endif
goto reacttime
raceloop:
readadc 9,b0
if b0=233 then 
  goto actualreset
endif
'w22=timer3*32*10
'serout a.0,(0,w22)
'pause 500
if pinb.0=1 and b1=1 then
  if b2=1 then
    high lstage
  endif
  'goto waitreset
  b1=2
  w20=timer3*32/10
  high lcheat
end if
if pinb.1=1 and b2=1 then
  if b1=1 then
    high rstage
  endif
  'goto waitreset
  high rcheat
  b2=2
  w21=timer3*32/10
endif
if b1=2 and b2=2 then
  sertxd (b40,b41,b42,b43)
  goto waitreset
endif
goto raceloop

cheat:
sound soundpin,(30,100)
if lpaddle=0 then
  high lcheat
  low lstage
else
  high rcheat
  low rstage
endif
goto waitreset

waitreset:
readadc 9,b0

if b0=233 then 
  actualreset:
  b10=0
  b11=0 
  b1=0
  b0=0
  low lstage
  low rstage
  low yellow1
  low yellow2
  low yellow3 
  low green
  low lcheat
  low rcheat
  goto start
endif
goto waitreset

pause 500
for b0=0 to 25
pulsout b.2,1000
pulsout c.4,1000
pause 100
next
pause 2000
low c.3
low c.2
low b.3
low c.5
low b.4
low green
pause 5000
goto start