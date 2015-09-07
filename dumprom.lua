f = io.open("c:\\demons\\charrom.bin", "rb")
local data = f:read(4096)
f:close()

f = io.open("c:\\demons\\charrom_set1.asm", "wb")
for i=0,255 do
	local t = "\t.byte "
	for j=0,7 do
		local b = data:byte(i*8+j+1)
		if j > 0 then t = t.."," end
		t = t..string.format("$%02x", b)
	end
	t = t..string.format("\t; %d\n", i)
	f:write(t)	
end
f:close()

f = io.open("c:\\demons\\charrom_set2.asm", "wb")
for i=0,255 do
	local t = "\t.byte "
	for j=0,7 do
		local b = data:byte(i*8+j+2049)
		if j > 0 then t = t.."," end
		t = t..string.format("$%02x", b)
	end
	t = t..string.format("\t; %d\n", i)
	f:write(t)	
end
f:close()

