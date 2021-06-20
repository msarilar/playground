-- title:  spectre
-- author: max_
-- desc:   short description
-- script: lua

total_width=220
total_height=126

cell_size=16

offset_top=4
offset_left=8

solids={[247]=true,[248]=true,[249]=true,[250]=true,[251]=true,[252]=true,[253]=true,[254]=true,[255]=true}
win=223
deaths={}

directions={
  {-1,0}, --left
  {0,-1}, --up
  {1,0}, --right
  {0,1} --down
}

dead=false
won=false
death_counter=0

moves=0

level=0

levels=
{
  -- welcome screen:
  {
    map_x=180,
    map_y=119,
    start_x=-1000,
    start_y=-1000,
    ennemies={}
  },
  -- level 1:
  {
    map_x=0,
    map_y=0,
    start_x=0,
    start_y=4,
    ennemies={
      {logic_x=1, logic_y=5, direction=3, spin=2},
      {logic_x=3, logic_y=6, direction=1, spin=2},
      {logic_x=5, logic_y=5, direction=3, spin=2},
      {logic_x=7, logic_y=5, direction=1, spin=2},
      {logic_x=9, logic_y=7, direction=2, spin=2}}
  },
  -- level 2:
  { 
    map_x=30,
    map_y=0,
    start_x=0,
    start_y=0,
    ennemies={
      {logic_x=5,  logic_y=5, direction=0, spin=1},
      {logic_x=9,  logic_y=0, direction=3, spin=2},
      {logic_x=7,  logic_y=6, direction=2, spin=2},
      {logic_x=11, logic_y=2, direction=0, spin=1},
      {logic_x=6,  logic_y=0, direction=2, spin=1}
    }
  },
  -- win screen:
  {
    map_x=210,
    map_y=119,
    start_x=-1000,
    start_y=-1000,
    ennemies={}
  },
}

function expand_keyframes(keyframes)
  local ret={}
  for i=1, #keyframes, 2 do
    for j=1, keyframes[i] do
      table.insert(ret, keyframes[i+1])
    end
  end
  return ret
end

animations=
{
  ennemy=expand_keyframes({200,258,
                           10,290,
                           10,322,
                           10,290}),
  player_sideways=expand_keyframes({10,256,
                                    10,288,
                                    10,320,
                                    10,288}),
  player_down=expand_keyframes({10,352,
                                10,384,
                                10,416,
                                10,384}),
  player_up=expand_keyframes({10,354,
                                10,386,
                                10,418,
                                10,386}),
  player_dead=expand_keyframes({5,356,
                                5,388,
                                5,420,
                                5,388})
}

animation_resets=
{
  random_start=function(a,c) a.current_step=math.floor(math.random(1,c)) end,
  first_start=function(a) a.current_step=1 end
}

animated={}

function animate(a)
  if(a.current_step==nil) then a.after_animation(a) end
  a.spr=a.animation[a.current_step]
  a.current_step=a.current_step+1
  if(a.current_step > #a.animation-1) then
    a.after_animation(a)
  end
end

function add_ennemy(ennemy)
  local new_ennemy=
  {
    logic_x=ennemy.logic_x,
    logic_y=ennemy.logic_y,
    direction=ennemy.direction,
    spin=ennemy.spin,
    spr=258,
    background=13,
    animation=animations.ennemy,
    after_animation=function(a) animation_resets.random_start(a,animations.ennemy[1]/2) end
  }

  table.insert(ennemies, new_ennemy)
  table.insert(animated, new_ennemy)
end

function init()
  ennemies={}
  current_level=levels[level+1]
  player=
  {
    spr=256,
    logic_x=current_level.start_x,
    logic_y=current_level.start_y,
    direction=0,
    background=0,
    animation=animations.player_sideways,
    after_animation=function(a) animation_resets.first_start(a) end 
  }
  table.insert(animated,player)
  for i, ennemy in ipairs(current_level.ennemies) do
    add_ennemy(ennemy)
  end
end

function draw_entity(entity, is_death)
  spr(entity.spr, offset_left + entity.logic_x*16, offset_top + entity.logic_y*16, entity.background, 1, entity.flip or 0, entity.direction, 2, 2)
  if(is_death) then table.insert(deaths, {logic_x=entity.logic_x, logic_y=entity.logic_y}) end
end

function draw_vision(ennemy)
  local direction = directions[ennemy.direction+1]
  local vision_entity = { spr=261, logic_x=ennemy.logic_x+direction[1], logic_y=ennemy.logic_y+direction[2], direction=ennemy.direction }
  while(is_free_to_move_there(vision_entity, 0, 0)) do
    draw_entity(vision_entity, true)
    vision_entity.spr=260
    vision_entity.logic_x=vision_entity.logic_x+direction[1]
    vision_entity.logic_y=vision_entity.logic_y+direction[2]
  end
end

function draw_debug()
  for i=0, total_width//cell_size do
    for j=0, total_height//cell_size do
      print(i.."|"..j, offset_left + i*16, offset_top + j*16+(i%2)*10, 0, true, 1, true)
    end
  end
end

function is_free_to_move_there(entity, offset_x, offset_y)
  if((won or dead) and entity==player) then return true end

  local next_x = entity.logic_x + offset_x
  local next_y = entity.logic_y + offset_y
  -- edges:
  if(next_y < 0 or next_x < 0 or next_y > total_height//cell_size or next_x > total_width//cell_size) then return false end
  -- walls:
  if(solids[mget(current_level.map_x + next_x*2, current_level.map_y + next_y*2)]) then return false end
  return true
end

function is_player_dead()
  for i, death in ipairs(deaths) do
    if(death.logic_x == player.logic_x and death.logic_y == player.logic_y) then return true end
  end

  return false
end

function has_player_won()
  return mget(current_level.map_x + player.logic_x*2, current_level.map_y + player.logic_y*2)==win
end

function move_player()
  local index = -1
  if (btnp(2)) then -- left
    index=0
    player.animation=animations.player_sideways
    player.flip=1
  end
  if (btnp(0)) then
    index=1
    player.animation=animations.player_up
    player.flip=0
  end
  if (btnp(3)) then -- right
    index=2
    player.animation=animations.player_sideways
    player.flip=0
  end
  if (btnp(1)) then -- down
    index=3
    player.animation=animations.player_down
    player.flip=0
  end
  
  local current_direction=directions[index+1]
  if(current_direction ~= nil) then
    if(is_free_to_move_there(player, current_direction[1], current_direction[2])) then
      player.logic_x = player.logic_x + current_direction[1]
      player.logic_y = player.logic_y + current_direction[2]
      return true
    end
  end

  return false
end

function move_ennemy(ennemy)
  local current_direction=directions[ennemy.direction+1]
  if(is_free_to_move_there(ennemy, current_direction[1], current_direction[2])) then
    ennemy.logic_x = ennemy.logic_x + current_direction[1]
    ennemy.logic_y = ennemy.logic_y + current_direction[2]
  else
    ennemy.direction = (ennemy.direction + ennemy.spin) % 4
  end
end

function remap(tile, x, y)
  if(tile==win) then
    tile=221+(tick/4%3)
  end

  return tile, 0, 0
end

function draw_map()
  map(current_level.map_x, current_level.map_y, 30, 17, offset_left, offset_top, 0, 1, remap)
end

init()
tick=0
function TIC()
  tick = tick + 1
  cls(0)
  draw_map()
  if(level == 0) then
    print("escape the maze without being spotted!", 18,90)
    print("press any direction to start", 75, 120, tick/4 % 15, false, 1,true)
    if (btnp(2) or btnp(0) or btnp(1) or btnp(3)) then
      level = level+1
      init()
    end
  elseif(level + 1 == #levels) then
    print("CONGRATULATIONS, YOU MANAGED TO ESCAPE!", 13, 20)
    print("you moved "..moves.." times", 70, 50, 6)
    if(death_counter > 1) then
      print("you got spotted "..death_counter.." times", 55, 80, 6)
    elseif(death_counter == 0) then
      print("you never got spotted!", 60, 80, math.random(15))
    else
      print("you got spotted once!", 63, 80, 14)
    end
    print("press any direction to start again", 60, 120, tick/4 % 15, false, 1,true)
    if (btnp(2) or btnp(0) or btnp(1) or btnp(3)) then
      level = 1
      death_counter=0
      init()
    end
  else

    for i, a in ipairs(animated) do
      animate(a)
    end

    deaths={}
    if(move_player()) then
      if(dead) then
        death_counter=death_counter+1
        dead=false
        init()
      elseif(won) then
        won=false
        level=level+1
        init()
      else
        moves=moves+1
        for i, ennemy in ipairs(ennemies) do
          move_ennemy(ennemy)
        end
      end
    elseif(won) then
      player.direction = (player.direction + 1)%4
    end

    for i, ennemy in ipairs(ennemies) do
      draw_vision(ennemy)
    end

    for i, ennemy in ipairs(ennemies) do
      draw_entity(ennemy, true)
    end

    draw_entity(player, false)
    
    if(is_player_dead()) then
      dead=true
      player.animation=animations.player_dead
    elseif(has_player_won()) then
      won=true
    end
  end
end

-- <TILES>
-- 015:3333333333333333333333333333333333333333333333333333333333333333
-- 031:1111111111111111111111111111111111111111111111111111111111111111
-- 221:9999999996666669969999699699996996999969969999699666666999999999
-- 222:9999999999999999996666999969969999699699996666999999999999999999
-- 223:6666666669999996699999966996699669966996699999966999999666666666
-- 239:0000000000000000000100000011100000010000000000000000000000000000
-- 243:1111111111111111111111111110000011100000111003331110033311100333
-- 244:1110033311100333111003331110000011100000111111111111111111111111
-- 245:3330011133300111333001110000011100000111111111111111111111111111
-- 246:1111111111111111111111110000011100000111333001113330011133300111
-- 247:1111111111111111111111110000000000000000333333333333333333333333
-- 248:1110033311100333111003331110033311100333111003331110033311100333
-- 249:3333333333333333333333330000000000000000111111111111111111111111
-- 250:3330011133300111333001113330011133300111333001113330011133300111
-- 251:3330011133300111333001113330000033300000333333333333333333333333
-- 252:1110033311100333111003330000033300000333333333333333333333333333
-- 253:3333333333333333333333330000033300000333111003331110033311100333
-- 254:3333333333333333333333333330000033300000333001113330011133300111
-- 255:1111111111111111111111111111111111111111111111111111111111111111
-- </TILES>

-- <SPRITES>
-- 000:000000000000000d000000dd00000ddd00000dff0000ddf00000ddf00000dddd
-- 001:00000000ddd00000dddd0000ddddd000ddffd000ddf0d000ddf0d000ddddd000
-- 002:ddddddd6dddddd66ddddddf6dddddfffddddffffddddf0ffdddff0ffddff000f
-- 003:dddddddd6ddddddd66dddddd666dddddf666ddddff666dddfff666ddffff6666
-- 004:000000000000000000000000eefeefeefeefeefeefeefeefeefeefeefeefeefe
-- 005:000000000000000000000000feefeefeefeefeefeefeefeefeefeefeefeefeef
-- 006:000000000000000000000000e0000000eef00000feefe000efeefee0eefeefee
-- 016:000ddddd000ddddd000ddddd000ddddd000ddddd00dddddd0ddddddd000dddd0
-- 017:dddd0000dddd0000ddddd000ddddd000dddddd00dddddd00dddddd0000000000
-- 018:ddff000fdddff0ffddddf0ffddddffffdddddfffddddddf6dddddd66ddddddd6
-- 019:ffff6666fff666ddff666dddf666dddd666ddddd66dddddd6ddddddddddddddd
-- 020:efeefeefeefeefeefeefeefeefeefeefeefeefee000000000000000000000000
-- 021:eefeefeefeefeefeefeefeefeefeefeefeefeefe000000000000000000000000
-- 022:feefeefeefeefee0eefee000fee00000e0000000000000000000000000000000
-- 032:00000000000000000000000d000000dd00000ddd00000ddd00000df00000ddf0
-- 033:0000000000000000ddd00000dddd0000ddddd000ddddd000ddf0d000ddf0d000
-- 034:ddddddd6dddddd66dddddd66ddddd666dddd6666ddddf0ffdddff0ffddff000f
-- 035:dddddddd6ddddddd66dddddd666ddddd6666dddd66666dddf66666ddff666666
-- 048:0000dddd0000dddd000ddddd000ddddd000ddddd00dddddd000ddddd00000ddd
-- 049:dddd0000dddd0000ddddd000ddddd000dddddd00dddddd00dd000000dd000000
-- 050:ddff000fdddff0ffddddf0ffdddd6666ddddd666dddddd66dddddd66ddddddd6
-- 051:ff666666f66666dd66666ddd6666dddd666ddddd66dddddd6ddddddddddddddd
-- 064:00000000000000000000000d000000dd00000ddd0000dddd0000dddd000dddf0
-- 065:0000000000000000ddd00000dddd0000ddddd000ddddd000ddddd000ddf0d000
-- 066:ddddddd6dddddd66dddddd66ddddd666dddd6666dddd6666ddd66666ddff0006
-- 067:dddddddd6ddddddd66dddddd666ddddd6666dddd66666ddd666666dd66666666
-- 080:000ddddd00dddddd00dddddd0ddddddd0ddddddd0ddddddd000ddddd00000ddd
-- 081:dddd0000ddddd000dddddd00dddddd00dddddd00dddddd00ddddd000dd000000
-- 082:ddff0006ddd66666dddd6666dddd6666ddddd666dddddd66dddddd66ddddddd6
-- 083:66666666666666dd66666ddd6666dddd666ddddd66dddddd6ddddddddddddddd
-- 096:00000000000000000000000d000000dd00000ddd00000ddd0000ddff0000df0f
-- 097:0000000000000000dd000000ddd00000dddd0000dddd0000dffdd000df0fd000
-- 098:00000000000000000000000d000000dd00000ddd00000ddd0000dddd0000dddd
-- 099:0000000000000000dd000000ddd00000dddd0000dddd0000ddddd000ddddd000
-- 100:000000000000000300000031000003110000311100003111000311ff00031fff
-- 101:0000000033000000113000001113000011113000111130001ff113001fff1300
-- 112:0000df0f000ddddd000ddddd000ddddd00dddddd00dddddd0ddddddd0ddddddd
-- 113:df0fd000ddddd000ddddd000dddddd00dddddd00dddddd00ddddddd0ddddddd0
-- 114:0000dddd000ddddd000ddddd000ddddd00dddddd00dddddd0ddddddd0ddddddd
-- 115:ddddd000ddddd000ddddd000dddddd00dddddd00dddddd00ddddddd0ddddddd0
-- 116:00031fff00311111003111110031111100311111000333330000000000000000
-- 117:1fff130011111300111113001111113011111130111333003330000000000000
-- 128:00000000000000000000000d000000dd00000ddd0000dddd000ddddd000ddffd
-- 129:0000000000000000d0000000dd000000ddd00000dddd0000ddddd000dffdd000
-- 130:00000000000000000000000d000000dd00000ddd0000dddd000ddddd000ddddd
-- 131:0000000000000000d0000000dd000000ddd00000dddd0000ddddd000ddddd000
-- 132:000000000000000000000000000000330000031100003111000311ff00031fff
-- 133:0000000000000000300000001333000011113000111130001ff113001fff1300
-- 144:00ddd0fd00ddf0fd00dddddd00dddddd00dddddd0ddddddd0ddddddd0ddddddd
-- 145:df0ddd00df0fdd00dddddd00dddddd00dddddd00ddddddd0ddddddd0ddddddd0
-- 146:00dddddd00dddddd00dddddd00dddddd00dddddd0ddddddd0ddddddd0ddddddd
-- 147:dddddd00dddddd00dddddd00dddddd00dddddd00ddddddd0ddddddd0ddddddd0
-- 148:00031fff00311111003111110031111100031111000033330000000000000000
-- 149:1fff130011111300111113001111130011113000113300003300000000000000
-- 160:0000000000000000000000000000000000000ddd0000dddd000ddddd000ddddd
-- 161:00000000000000000000000000000000ddd00000dddd0000ddddd000ddddd000
-- 162:0000000000000000000000000000000000000ddd0000dddd000ddddd000ddddd
-- 163:00000000000000000000000000000000ddd00000dddd0000ddddd000ddddd000
-- 164:000000000000000000000000000000000000033300003311000311ff00031fff
-- 165:0000000000000000000000000000000033330000111130001ff113001fff1300
-- 176:000dd0fd000df0fd000ddddd00dddddd0ddddddd0ddddddddddddddddddddddd
-- 177:df0dd000df0fd000ddddd000dddddd00ddddddd0ddddddd0dddddddddddddddd
-- 178:000ddddd000ddddd000ddddd00dddddd0ddddddd0ddddddddddddddddddddddd
-- 179:ddddd000ddddd000ddddd000dddddd00ddddddd0ddddddd0dddddddddddddddd
-- 180:00031fff00003111000033330000000000000000000000000000000000000000
-- 181:1fff130011111300333330000000000000000000000000000000000000000000
-- </SPRITES>

-- <MAP>
-- 000:ffffffffffffffffffffffffffffffffff8ffefefefefefeaf8ffdfd0000fefeaf8ffefefefefefefefefefefefeaf8ffefefefefefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:ffffffffffffffffffffffffffffffffff8ffefefefefefeaf8ffdfd0000fefeaf8ffefefefefefefefefefefefeaf8ffefefefefefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:ffffffffffffffffffffffffffffffffff8ffefeefdffefeaf8ffefe0000fefeaf8ffefeef9f9f9f9f9f9fdffefeaf8ffefeef9f9fdffefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:ff3f7f7f6f3f7f7f6f3f7f7f6f3f7f7f6f8ffefeaf8ffefeaf8ffefe0000fefeaf8ffefeaf3f7f7f7f7f7fcffefeaf8ffefebf7f7fcffefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:ff8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefe0000fefeaf8ffefeaf8ffefefefefefefefeaf8ffefefefefefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:ff8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefe0000fefebfcffefeaf8ffefefefefefefefeaf8ffefefefefefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:ff8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefeaf8ffefe0000fefefefefefeaf8ffefefefeefdffefeaf8ffefeefdffefeef9f5fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:7fcffefebfcffefebfcffefebfcffefebfcffefeaf8ffefeaf8ffefe0000fefefefefefeaf8ffefefefeaf8ffefebfcffefeaf8ffefebf7f7f7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:fefefefefefefefefefefefefefefefefefefefeaf8ffefeaf8ffefe0000fefefefefefeaf8ffefefefeaf8ffefefefefefeaf8ffefefefefdfd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:fefefefefefefefefefefefefefefefefefefefeaf8ffefeaf8ffefe0000fefefefefefebfcffefefefeaf8ffefefefefefeaf8ffefefefefdfd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:9fdffefeefdffefeefdffefeefdffefeef9f9f9f5f8ffefeaf8ffefe0000fefeefdffefefefefefefefeaf8ffefeef9f9f9f5f8ffefeef9f9f9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:ff8ffefeaf8ffefeaf8ffefeaf8ffefeaf3f7f7f7fcffefeaf8ffefe0000fefeaf8ffefefefefefefefeaf8ffefebf7f7f7f7fcffefebf7f6fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:ff8ffefeaf8ffefeaf8ffefeaf4f9f9f5f8ffefefefefefeaf8ffefe0000fefeaf8ffefeef9f9f9f9f9fff8ffefefefefefefefefefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:ff8ffefeaf8ffefeaf8ffefeafffff3f7fcffefefefefefebfcffefe0000fefeaf8ffefebf7f7f7f7f7f7fcffefefefefefefefefefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:ff4f9f9f5f4f9f9f5f4f9f9f5fffff8ffefefefefefefefefefefefe00009f9f5f8ffefefefefefefefefefefefeef9f9f9f9fdffefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:ffffffffffffffffffffffffffffff8ffefefefefefefefefefefefe0000ffffff8ffefefefefefefefefefefefeafffffffff8ffefefefeafff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 119:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f1f1f1f1f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 120:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f1f0f0f0f0f1f1f1f1f2f1f1f1f2f1f1f1f0f1f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 121:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f1f0f1f1f1f1f0f0f0f1f0f0f0f1f0f0f1f0f0f1f1f1f1f2f1f1f1f2f2000000000000000000000000000000000000000000000000000000000000
-- 122:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f1f0f0f0f1f1f0f1f0f1f0f1f0f1f0f1f1f0f1f1f0f0f0f1f0f0f0f1f2000000000000000000000000000000000000000000000000000000000000
-- 123:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f1f1f1f0f0f1f0f0f0f1f0f0f1f1f0f1f1f0f1f1f0f1f0f1f0f1f0f1f2000000000000000000000000000000000000000000000000000000000000
-- 124:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f1f0f0f0f0f1f1f0f1f1f1f1f0f0f1f0f0f1f1f0f1f0f0f1f1f0f0f0f1f2000000000000000000000000000000000000000000000000000000000000
-- 125:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f1f1f1f1f2f1f0f1f2f2f1f1f1f2f1f1f2f2f1f1f0f1f0f1f0f1f1f1f2000000000000000000000000000000000000000000000000000000000000
-- 126:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f1f2f2f2f2f2f2f2f2f2f2f2f2f2f1f1f1f2f1f0f1f2f2000000000000000000000000000000000000000000000000000000000000
-- 127:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f1f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 128:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 129:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 130:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 131:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 132:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 133:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- 135:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <PALETTE>
-- 000:0000001d2b537e255383769cab5236008751ff004d5f574fff77a8ffa300c2c3c700e436ffccaa29adffffec27fff1e8
-- </PALETTE>

-- <COVER>
-- 000:dba000007494648393160f00880077000012ffb0e45445353414055423e2033010000000129f40402000ff00c2000000000f0088007841c0c10343d695d7ecd62cacedee6d57171600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080ff001080c1840b0a1c388031a2c58c0b1a3c780132a4c9841b2a5cb88133a6cd8c1b3a7cf80234a8c1942b4a9c398235aac5961308bc7903366001043b6adcb98337ad499c3b7afcf90438a0d1a44b8a1d3a84d722c2aa3b9a3db9943aa4d9a45baa5d9ab498e3ddad4faa7dfa063ca85e9957827d3b057caad5bc6bd6fc2b241dac510e6beaddbb651e60d9b861fafdfb08f7ae50ac7fc60e3c88dfe0ef9589b62e7c095de2e99937085ebc8933b6edc89b1f6de9e9b628e0d2083bec8c9472be4eccab57662dd5972ce1d1ad47e44d84557567dcbd63c6c94bd370f6ceb3d2ee2aab176fe5efaf73079d4a7871e2eb3f832f382d9623fde30c9f37993b1a7dffedc7ada31d4e739b337fe6c366870f4a9ab863f341dbd45fbc9d7578f1a3bfc59f431d75f1672e5a78f1f6afdc7cf907502174edd6206056f5d400ef670676bbd58dd568dbda6be5284753858db540e287fd3890a6869978a12b8d127880288ef9c542a14ef5580b9a8b1a27a2ab8132f89f9c8222f553614732a8af9e8e32e7b46b6d42b60268862e8846598ee1c879549a4269aed3951e6715ec8d755963e095a129ced6904e58e52a941e7890a896819964a99836c7d3279cd5b9a91f9dc5c9662d847214746f902aa9606b8a7e7907ae727a3638e04582b98613a68ea98126a95ae927dd9a9679b863a63d48ad5e97695af762a9ae9879aaa99275e9abffac468a142e44ae99a8e9ae669ada2babaeb9db20bfba351bafa70af9f3ed47b22ab51aafaa1bb9e7ab3acab265abb635cca0b7c6e4bca9a0be5bec64b4de4b0d65bab60b4ca7b5eee9cda590312bea57a0eecb8e2ea3cadbfce355ca6b3ba4b066bb56e49cb25a7eedb1ea9b3ee392f6db0fa394beb86babbf253c05a5b5fe1c4e2fb80fabb0fdb4136cff64c10f593e5da3e68c72f5ba0b5ce137ae2b4bb2b8c57a0cff98aa13bbefaacf2f7bc0fecc1bfc73be47b67c9ceab82b1da33ccc27eb9ee5c4fa1c7de0db47cbf071d73feb3033d8d62d9030d95b8bf3bcc4860a35b3c93b9c847fca471ca57ccd5fadf6b2b21bb493adcf538a767bc0773bc578ffd17bfd087d4253bd457ed65fdd5131eb1bebd770de53eb06b3e26b4a46b2e987ac86f5dd832e4474ed434de478e7f224f1bddb5bade9d1da93ae1832e8534e87bcd6059e99f7ed63e95b3ce793fd2af1e7a31c2b7144b34cc3bed9ab9eaabdee9beefa76b4319e557fb5cfde5231f96b1fda33fb9b6f9b34f68b4fcb36f3d12f6abbd7d35f89b5f28f143cbfe6eb779c37f2e37e1df2eac7ce3a2bf5f3ec3df2f577ee1fb7f9be6b7ec31087f2d7bd2bc9698c79b310acf0d77eb2c50f6c643b7f09cef6a0a8b447a27de9db49d2364fbdb516607c02a9558892b1ca0248cc2f1470ebe486373ac00ac487d2416f7838bf1d0a20f17f2408dcce28ce99496dffc6852402e358881e3da16c06342c6c801797844a29a0fb3a3cef9df477e049b4315a864c0167090392ce26c6858b3411a71b13b54229d9a68a5903ebb6c4464b22801b8f83d26c03c4b6ca75415d835cf2236a58c3cde1c07461992f4480f261c73a915a41399c026c09784bb422726f8b2215015309c84ab562947ba464a4026d9c4a629d2c9491260304f94004827583ac6b492d18694ac1e6449dac1bcb2d3923174e168695bc0bcd27191b405e17879dbcfacf2f49c84898e2b89ccc34213359dcc866f2f999bc81a43fa93c465a48ca98dce6e368a9d84e6a737c908107a235c94ec47a425b904956aa3fd94a467a060d90fca7af25e9a41a7ad37f9fff81772f3ff9781f720470a87118214f0ad613822471a26158234f1a7517824472a25198254f2a641b826473abd424274f3a515d728474a9f4f8294f4a241d82a414aa2d59274b5af5120010e522354c4d4300735c9ec4b82935894f4562f3d0b4f438a04d992151a9f3199ee457a7355aee4d9ac4d5aa25b8a3558aab46aa139a9a45baa655caaf496ae358aa5599a75d7a64579a56dc9a753dab554b2d49baa6d6aa85bba175daab5b4af3c2aae49ca9650bee5b9af7dbb6c5faa18dcaa85bcaf654cef4d8a83ddba36d1b6453b206f1b1652cad5b0bd8d7aab5dba08d9ce057baf755ced5389aa4f9ca59cac951da56f8a38dcc21591bc858c6b5972e4d8cff226f6b6b57d21692b9857d286b3b36d0b6e678b7bd2e6a697bd1dcb2559daf659bad5bead31eaee6f4b99d6c645fcad753c26615b665eba77fbb7ddcee56dab5c56e687fbbc957e63737b9cdb4285e8ae250a0575fa981896c792a6fdbf2443fbaf5682f7bfb80dff20890a20e10304b0c606e722831c6fc503381e9e0e70ba332c21627258b2cedcb03681b9a1ed0b43b3ce1e6628834c5cc11398b6962e31f8235ca2e842b8b5c11a713c89e323e91b57a6c636cd0e837c199d13d7a0010002b0548c24ef9419d8c04932b62d7c84920419d9ce218270998cf46a274938c03192749dac35e92f199bcb56227c40ace4602b699cca5e52b84323666c2f59d78cc06ed2369bdcf4e93bb9decf5e733e93bca7693f595ec97641fa912347e79c991cc58644fe9dfc18e44fd9ddcd6634b8971df7e65239f8225ef23c9dfc166b375abbc196647d972d1aef3b6a9fc56e74baaf097963a829ba2fa6217ba97c189953daff26beb571470dabe176eab7d579f530b31acbe16f5358d6c69c41b39d22e5633bb89101000b3
-- </COVER>
