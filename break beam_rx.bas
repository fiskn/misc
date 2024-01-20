#no_data
setfreq m16
low b.6
low b.7
do
b10=0
b11=0
b12=0
b13=0
for b0=1 to 10
  if pinb.0=1 then
    b10=b10+1
  endif
  if pinb.1=1 then
    b11=b11+1
  endif
  if pinb.2=1 then
    b12=b12+1
  endif
  if pinb.3=1 then
    b13=b13+1
  endif
next
if b10>8 then
  high c.1
  high b.6

endif

if b11>8 then
  high c.6
  high b.7

endif

if b12>8 then
  high c.7
  high b.6

endif

if b13>8 then
  high c.0
  high b.7

endif
pause 100
low c.0
low c.1
low c.6
low c.7
low b.6
low b.7
loop