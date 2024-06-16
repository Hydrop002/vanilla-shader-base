# scoreboard players add global timer 1

execute store result score global count if entity @e[tag=uniform,tag=p1]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p1]
execute store result score global count if entity @e[tag=uniform,tag=p2]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p2]
execute store result score global count if entity @e[tag=uniform,tag=p3]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p3]
execute store result score global count if entity @e[tag=uniform,tag=p4]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p4]
execute store result score global count if entity @e[tag=uniform,tag=p5]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p5]
execute store result score global count if entity @e[tag=uniform,tag=p6]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p6]
execute store result score global count if entity @e[tag=uniform,tag=p7]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p7]
execute store result score global count if entity @e[tag=uniform,tag=p8]
execute unless score global count matches 1 run kill @e[tag=uniform,tag=p8]
execute unless entity @e[tag=uniform,tag=p1] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p1]}
execute unless entity @e[tag=uniform,tag=p2] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p2]}
execute unless entity @e[tag=uniform,tag=p3] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p3]}
execute unless entity @e[tag=uniform,tag=p4] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p4]}
execute unless entity @e[tag=uniform,tag=p5] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p5]}
execute unless entity @e[tag=uniform,tag=p6] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p6]}
execute unless entity @e[tag=uniform,tag=p7] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p7]}
execute unless entity @e[tag=uniform,tag=p8] at @p run summon minecraft:text_display ~ ~ ~ {view_range:999999.0f,see_through:true,billboard:center,transformation:[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0],Tags:[uniform,p8]}

execute as @e[tag=uniform] at @s run function vsb:uniform
