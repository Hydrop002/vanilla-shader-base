tp @s @p
execute store result score @s pos_y run data get entity @s Pos[1]
scoreboard players operation @s pos_y /= 16 math
scoreboard players add @s pos_y 8388608
scoreboard players add @s pos_y 33554432

execute store result storage vsb:uniform chunkpos_y int 1 run scoreboard players get @s pos_y
data modify entity @s background set from storage vsb:uniform chunkpos_y