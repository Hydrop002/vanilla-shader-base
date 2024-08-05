tp @s @p
execute store result score @s pos_x run data get entity @s Pos[0]
scoreboard players operation @s pos_x /= 16 math
scoreboard players add @s pos_x 8388608
scoreboard players add @s pos_x 16777216

execute store result storage vsb:uniform chunkpos_x int 1 run scoreboard players get @s pos_x
data modify entity @s background set from storage vsb:uniform chunkpos_x