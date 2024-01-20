setfreq m8
do
'high 2 
'pwmout 2,25,53
b0=0
pwmout 2, 51, 105


 
for b1=1 to 2
 if pin0=1 then
   b0=1
   'goto test
 endif
next b1
test:
if b0=1 then
high 3

high 2

b2=100
else
low 3
endif

if b2>0 then
  b2=b2-1

else
  low 2

endif

pwmout 2,off
'sertxd (#b3,",",#b0,",",#b5,cr,lf)

pause 14
loop

