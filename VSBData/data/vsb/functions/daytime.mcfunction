# pos
tp @s @p
execute store result score @s pos_x run data get entity @s Pos[0]
execute store result score @s pos_y run data get entity @s Pos[1]
execute store result score @s pos_z run data get entity @s Pos[2]
scoreboard players operation @s pos_x /= 16 math
scoreboard players operation @s pos_x *= 16 math
scoreboard players operation @s pos_y /= 16 math
scoreboard players operation @s pos_y *= 16 math
scoreboard players operation @s pos_z /= 16 math
scoreboard players operation @s pos_z *= 16 math
execute store result entity @s Pos[0] double 1 run scoreboard players get @s pos_x
execute store result entity @s Pos[1] double 1 run scoreboard players get @s pos_y
execute store result entity @s Pos[2] double 1 run scoreboard players get @s pos_z

# daytime
execute store result storage vsb:uniform daytime int 1 run time query daytime
data modify entity @s background set from storage vsb:uniform daytime
