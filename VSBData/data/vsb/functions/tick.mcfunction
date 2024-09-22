execute store result score global count if entity @e[tag=daytime]
execute unless score global count matches 1 run kill @e[tag=daytime]
execute store result score global count if entity @e[tag=chunkpos_x]
execute unless score global count matches 1 run kill @e[tag=chunkpos_x]
execute store result score global count if entity @e[tag=chunkpos_y]
execute unless score global count matches 1 run kill @e[tag=chunkpos_y]
execute store result score global count if entity @e[tag=chunkpos_z]
execute unless score global count matches 1 run kill @e[tag=chunkpos_z]
# execute store result score global count if entity @e[tag=dimension]
# execute unless score global count matches 1 run kill @e[tag=dimension]
# execute store result score global count if entity @e[tag=biome]
# execute unless score global count matches 1 run kill @e[tag=biome]

execute store result storage vsb:uniform gametime int 1 run time query gametime
function vsb:set_time with storage vsb:uniform

execute unless entity @e[tag=daytime] at @p run summon minecraft:text_display ~ ~ ~ {text:"daytime",see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[daytime]}
execute unless entity @e[tag=chunkpos_x] at @p run summon minecraft:text_display ~ ~ ~ {text:"chunkpos_x",see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[chunkpos_x]}
execute unless entity @e[tag=chunkpos_y] at @p run summon minecraft:text_display ~ ~ ~ {text:"chunkpos_y",see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[chunkpos_y]}
execute unless entity @e[tag=chunkpos_z] at @p run summon minecraft:text_display ~ ~ ~ {text:"chunkpos_z",see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[chunkpos_z]}
# execute unless entity @e[tag=dimension] at @p run summon minecraft:text_display ~ ~ ~ {text:"dimension",see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[dimension]}
# execute unless entity @e[tag=biome] at @p run summon minecraft:text_display ~ ~ ~ {text:"biome",see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[biome]}

execute as @e[tag=daytime] run function vsb:daytime
execute as @e[tag=chunkpos_x] run function vsb:chunkpos_x
execute as @e[tag=chunkpos_y] run function vsb:chunkpos_y
execute as @e[tag=chunkpos_z] run function vsb:chunkpos_z
# execute as @e[tag=dimension] run function vsb:dimension
# execute as @e[tag=biome] run function vsb:biome
