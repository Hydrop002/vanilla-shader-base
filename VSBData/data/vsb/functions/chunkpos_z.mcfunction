tp @s @p
execute store result score @s pos_z run data get entity @s Pos[2]
scoreboard players operation @s pos_z /= 16 math
scoreboard players add @s pos_z 8388608
scoreboard players add @s pos_z 50331648

execute store result storage vsb:uniform chunkpos_z int 1 run scoreboard players get @s pos_z
data modify entity @s background set from storage vsb:uniform chunkpos_z