# pos
tp @s @p
execute store result score @s pos_x run data get entity @s Pos[0]
execute store result score @s pos_y run data get entity @s Pos[1]
execute store result score @s pos_z run data get entity @s Pos[2]
# scoreboard players add @s pos_x 64
scoreboard players operation @s pos_x /= 128 math
scoreboard players operation @s pos_x *= 128 math
scoreboard players add @s[tag=p5] pos_x 128
scoreboard players add @s[tag=p6] pos_x 128
scoreboard players add @s[tag=p7] pos_x 128
scoreboard players add @s[tag=p8] pos_x 128
# scoreboard players add @s pos_y 64
scoreboard players operation @s pos_y /= 128 math
scoreboard players operation @s pos_y *= 128 math
scoreboard players add @s[tag=p3] pos_y 128
scoreboard players add @s[tag=p4] pos_y 128
scoreboard players add @s[tag=p7] pos_y 128
scoreboard players add @s[tag=p8] pos_y 128
# scoreboard players add @s pos_z 64
scoreboard players operation @s pos_z /= 128 math
scoreboard players operation @s pos_z *= 128 math
scoreboard players add @s[tag=p2] pos_z 128
scoreboard players add @s[tag=p4] pos_z 128
scoreboard players add @s[tag=p6] pos_z 128
scoreboard players add @s[tag=p8] pos_z 128
execute store result entity @s Pos[0] double 1 run scoreboard players get @s pos_x
execute store result entity @s Pos[1] double 1 run scoreboard players get @s pos_y
execute store result entity @s Pos[2] double 1 run scoreboard players get @s pos_z

# daytime
execute store result storage vsb:time daytime int 1 run time query daytime
data modify entity @s background set from storage vsb:time daytime
