scrcodes = {
	["%"] = 37,
}

function convert_text(t)
	for i=1,#t,2 do
		local label = t[i]
		local text = t[i+1]
		local line = string.format("%-8s.byte ", label)
		for j=1,#text do
			local scr = scrcodes[text:sub(j, j)] or (bit.band(text:byte(j), 0xff-64) + 0x80)
			line = line..string.format("$%02x,", scr)
		end
		line = line.."$00"
		local tabs = math.floor((88-#line+7)/8)
		line = line..string.rep("\t", tabs).."; "..text
		print(line)
	end
end

convert_text{
	"descend:",	"DESCENDING",
	"youhit:",	"YOU HIT THE %!",
	"youmiss:",	"YOU MISS.",
	"youdie", 	"YOU DIE! SCORE:",
	"monhit:",	"% HITS YOU!",
	"monmiss:",	"% MISSES!",
	"mondies:",	"% DIES!",
	"monwoun:",	"% IS WOUNDED!",
	"opened:",	"OPENED.",
	"block:",	"BLOCKED.",
	"found:",	"FOUND %.",
	"outof:",	"NO %S.",
	"useitem:",	"USE %",
	"usepot:",	"HEALED!",
	"usegem:",	"A VISION!",
	"usescr:",	"TURNED INVISIBLE!",
	"useskul:",	"CHAOS!",
	"youwin:",	"YOU WIN! SCORE:",
	"levelup:",	"LEVEL UP!",
}

print("---")

convert_text{
	"_potion:",	"POTION",
	"_gem:",	"GEM",
	"_scroll:",	"SCROLL",
	"_ankh:",	"ANKH",
	"_gold:",	"GOLD",
	"_bat:",	"BAT",
	"_rat:",	"RAT",
	"_worm:",	"WORM",
	"_snake:",	"SNAKE",
	"_orc:",	"ORC",
	"_undead:",	"UNDEAD",
	"_stalke:",	"STALKER",
	"_slime:",	"SLIME",
	"_wizard:",	"WIZARD",
	"_demon:",	"DEMON",
}
