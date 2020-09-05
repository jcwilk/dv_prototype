pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

colors = {
  {8,2},//red,purp
  {12,1},//blue,dkblue
  {11,3},//green,dkgreen
  {9,4},//orange,brown
  {14,2}//pink,purple
}

colia=1
colib=3
function set_colors(a,b)
 cola1=colors[a][1]
 cola2=colors[a][2]
 colb1=colors[b][1]
 colb2=colors[b][2]
end
set_colors(colia,colib)

function make_tile(x,y)
 local tile = {
  x=x,
  y=y,
  col_amount = rnd(1),
  col = 0 // 0 means no color
 }

 if rnd(1) < .4 then
  if rnd(1) < .5 then
   tile.col = cola1
  else
   tile.col = colb1
  end
 end

 return tile
end

tiles = {}
tiles.all = {}
tiles.by_coord = {}

for x=0,15 do
 tiles.by_coord[x] = {}
end
for y=0,150 do
 for x=0,15 do
  local tile = make_tile(x,y)
  tiles.by_coord[x][y] = tile
  add(tiles.all, tile)
 end
end

function _init()
 highlight_moves()
 select_player_tile()
 init_mobs()
 cls()
end

function _update60()
 if #anims.all>0 then
  anims.tick()
  return
 end

 if(btnp(4)) then
  choose_move()
 end
 if(btnp(0)) then
  press_with(find_left_move)
 end
 if(btnp(1)) then
  press_with(find_right_move)
 end
 if(btnp(2)) then
  press_with(find_higher_move)
 end
 if(btnp(3)) then
  press_with(find_lower_move)
 end
end

function press_with(fn)
 local i=fn()
 if i!=selected_index then
  sfx(2)
  select_move(i)
 else
  sfx(3)
 end
end

cam={x=0,y=0}
function _draw()
 while (player.y*8 - cam.y) > 90 do
  cam.y+=1
 end
 while (player.y*8 - cam.y) < 38 do
  cam.y-=1
 end
 camera(cam.x,cam.y)

 foreach(tiles.all,function(t)
  pal()
  if t.col > 0 then
   pal(5,t.col)
   if t.col == cola1 then
    pal(1,cola2)
   else
    pal(1,colb2)
   end
  end
  spr(1, t.x*8, t.y*8)
 end)

 pal()
 if player.col != 0 then
  pal(15,player.col)
  if player.col == cola1 then
   pal(7,cola2)
  else
   pal(7,colb2)
  end
 else
  pal(15,6)
 end
 spr(2, player.x*8, player.y*8)

	pal()
 mobs.draw()

 foreach(tiles.all,function(t)
  if t.highlighted then
   pal()
   spr(4, t.x*8, t.y*8)
   if t.selected then
    spr(5, t.x*8, t.y*8)
   end
  end
 end)
 pal()
end
-->8
player = {
 x=0,
 y=0,
 col=0
}

selected_move=nil
selected_index=1
function select_move(index)
 if(selected_move) then
  tiles.by_coord[selected_move[1]][selected_move[2]].selected=false
 end

 while(index < 1) do
  index += #highlighted_moves
 end
 while(index > #highlighted_moves) do
  index -= #highlighted_moves
 end

 selected_index = index
 selected_move = highlighted_moves[index]
 tiles.by_coord[selected_move[1]][selected_move[2]].selected=true
end

highlighted_moves={}
function highlight_moves()
 local max_path=2
 if player.col!=0 then
  max_path=4
 end
 highlighted_moves=get_path_moves(player,mobs.get_all_coords(),max_path)
 foreach(highlighted_moves,function(move)
  local tile = tiles.by_coord[move[1]][move[2]]
  tile.highlighted = true
 end)
end

function dehighlight_moves()
 foreach(highlighted_moves,function(move)
  local tile = tiles.by_coord[move[1]][move[2]]
  tile.highlighted = false
 end)
end

function is_valid_move(x,y,entity)
 return (is_on_map(x,y) and is_color_compat(x,y,entity))
end

function is_on_map(x,y)
 //return (x >= 1 and x <= 10 and y >= 1 and y <= 10)
 return (x >= 0 and x <= 15 and y >= 0 and y <= 150)
end

function is_color_compat(x,y,entity)
 local tile = tiles.by_coord[x][y]
 globalx=x
 globaly=y
 globalentity=entity
 return(tile.col == 0 or entity.col == 0 or tile.col == entity.col)
end

function get_moves()
 local moves = {}
 for y=player.y-3,player.y+3 do
  for x=player.x-3,player.x+3 do
   if is_valid_move(x,y,player) then
    add(moves,{x,y})
   end
  end
 end
 return moves
end

function find_left_move()
 if selected_index!=1 then
  if highlighted_moves[selected_index-1][2] == selected_move[2] then
   return selected_index-1
  end
 end
 return selected_index
end

function find_right_move()
 if selected_index!=#highlighted_moves then
  if highlighted_moves[selected_index+1][2] == selected_move[2] then
   return selected_index+1
  end
 end
 return selected_index
end

function find_lower_move()
 local found=nil
 for i=selected_index,#highlighted_moves do
  local move = highlighted_moves[i]
  if move[2] > selected_move[2] and move[1] == selected_move[1] then
   return i
  end
 end
 return selected_index
end

function find_higher_move()
 local found=nil
 for i=selected_index,1,-1 do
  local move = highlighted_moves[i]
  if move[2] < selected_move[2] and move[1] == selected_move[1] then
   return i
  end
 end
 return selected_index
end

function select_player_tile()
 for i=1,#highlighted_moves do
  local move=highlighted_moves[i]
  if move[1] == player.x and move[2] == player.y then
   select_move(i)
   return
  end
 end
 error_no_move_found()
end

function choose_move()
 dehighlight_moves()
 if player.x == selected_move[1] and player.y == selected_move[2] then
  exchange_color()
  anims.after(function()
   //dupt
	  highlight_moves()
	  select_player_tile()
	 end)
 else
  //player.x=selected_move[1]
  //player.y=selected_move[2]
  //make_tween2(player,"x","y",selected_move[1],selected_move[2],6)
  make_path_tween(player,selected_move,6).after=function()
   exchange_color()
   anims.after(function()
 			mobs.move()
    anims.after(function()
     //dupt
 		  highlight_moves()
 		  select_player_tile()
 		 end)
 		end)
  end
 end
end
-->8
function exchange_color()
 local tile = tiles.by_coord[player.x][player.y]

 if tile.col == 0 and player.col == 0 then
  return
 end

 if player.col == 0 then
  sfx(0)
  player.col = tile.col
  tile.col = 0
  local spawn_col=cola1
  if player.col == cola1 then
   spawn_col=colb1
  end
  spawn_around(player.x,player.y,spawn_col)
  return
 end

 if tile.col == 0 then
  sfx(1)
  tile.col = player.col
  player.col = 0
  spawn_around(player.x,player.y,tile.col)
  return
 end
end

function spawn_around(x,y,col)
 local spots = {
  {x-1,y},
  {x+1,y},
  {x,y-1},
  {x,y+1}
 }
 local shuffled = {}
 local spot
 while #spots > 0 do
  spot = rnd(spots)
  del(spots,spot)
  add(shuffled,spot)
 end
 local spawn_left=1
 local shuffled2={}
 local mob
 for i=1,#shuffled do
  spot=shuffled[i]
  mob=false
  gspot=spot
  if is_on_map(spot[1],spot[2]) then
   mob=mobs.by_coord[spot[1]][spot[2]]
  end
  if mob and mob.col != col then
   if spawn_mob(spot[1],spot[2],col) then
    spawn_left-=1
    if spawn_left<1 then
     return
    end
   else
    add(shuffled2,spot)
   end
  else
   add(shuffled2,spot)
  end
 end
 for i=1,#shuffled2 do
  if spawn_mob(shuffled2[i][1],shuffled2[i][2],col) then
   spawn_left-=1
   if spawn_left<1 then
    return
   end
  end
 end
end
-->8
function get_path_moves(entity,obstacles,max_path)
 if not obstacles then
  obstacles={}
 end
 local seen={}
 for x=entity.x-max_path,entity.x+max_path do
  seen[x]={}
  for y=entity.y-max_path,entity.y+max_path do
   seen[x][y]=false
  end
 end

 local moves={}

 local function expand(x,y,steps)
  local step = #steps
  if step > max_path or (seen[x][y] and seen[x][y] <= step) then
   return
  end

  local add_it=true
  if seen[x][y] then
   //add_it=false
   local i=1
   while i<#moves do
    if moves[i][1]==x and moves[i][2]==y then
     deli(moves,i)
    else
     i+=1
    end
   end
  end
  seen[x][y] = step

  if is_valid_move(x,y,entity) then
   for i=1,#obstacles do
    if x==obstacles[i][1] and y==obstacles[i][2] then
     return
    end
   end

   if add_it then
    add(moves, {x,y,steps})
   end

   local next_steps = {}
   foreach(steps,function(s)
    add(next_steps,s)
   end)
   add(next_steps,{x,y})

   expand(x-1,y,next_steps)
   expand(x+1,y,next_steps)
   expand(x,y-1,next_steps)
   expand(x,y+1,next_steps)
   //for ix=x-1,x+1 do
   // for iy=y-1,y+1 do
   //  expand(ix,iy,step+1)
   // end
   //end
  end
 end

 expand(entity.x,entity.y,{})

 sort(moves,function(a,b)
  return a[2]>b[2] or (a[2]==b[2] and a[1]>b[1])
 end)

 return moves
end
-->8
//thanks! https://www.lexaloffle.com/bbs/?tid=2477
function sort(a,cmp)
  for i=1,#a do
    local j = i
    while j > 1 and cmp(a[j-1],a[j]) do
        a[j],a[j-1] = a[j-1],a[j]
    j = j - 1
    end
  end
end
-->8
mob_spd=8
mob_max_path=4
mobs = {
 all={},
 by_coord={},
 get_all_coords=function()
  local coords={}
  foreach(mobs.all,function(mob)
   add(coords,{mob.x,mob.y})
  end)
  return coords
 end,
 move=function()
  //local mobsall=mobs.all
  //local mobsby_coord=mobs.by_coord
  //mobs.all={}
  //mobs.by_coord={}
  local checking={}
  local moving={}
  foreach(mobs.all,function(mob)
   add(checking,mob)
   add(moving,mob)
  end)
  local mob,fn
  while #checking>0 do
   mob=deli(checking,1)

   fn=function(mob)
    local check
    local anim
    local found

    for i=1,#checking do
     check=checking[i]
     found=false
     if check.col != mob.col then
	     if check.x == mob.x then
	      if check.y == mob.y-1 or check.y == mob.y+1 then
	       found=true
	      end
	     elseif check.y == mob.y then
	      if check.x == mob.x-1 or check.x == mob.x+1 then
	       found=true
	      end
	     end
     end
     local a,b
     if found then
      found=false
      if tiles.by_coord[mob.x][mob.y].col == 0 then
       found=true
       a=check
       b=mob
      elseif tiles.by_coord[check.x][check.y].col == 0 then
       found=true
       a=mob
       b=check
      end
     end
     if found then
      mob.cancel_out(check)
      
      deli(checking,i)
      del(moving,check)
      del(moving,mob)
      return
     end
    end
   end
   fn(mob)
  end
  foreach(moving,function(mob)
   if player.col == mob.col then
    return
   end
   local cart_dist=abs(mob.x-player.x)+abs(mob.y-player.y)
   if cart_dist<=1 or cart_dist>mob_max_path then
    return
   end

   local moves=get_path_moves(mob,{{player.x,player.y},selected_move},mob_max_path)
   local filtered={}
   foreach(moves,function(move)
    if not mobs.by_coord[move[1]][move[2]] then
     add(filtered,move)
    end
   end)

   sort(filtered,function(a,b)
    return (abs(a[1]-player.x)+abs(a[2]-player.y) > abs(b[1]-player.x)+abs(b[2]-player.y))
   end)

   if #filtered > 0 then
    mob.move_to(filtered[1])
   end
  end)
 end,
 draw=function()
  foreach(mobs.all,function(mob)
   pal()
   if mob.col == cola1 then
    pal(11,cola1)
    pal(3,cola2)
   else
    pal(11,colb1)
    pal(3,colb2)
   end
   spr(3,mob.x*8,mob.y*8)
  end)
 end
}
foreach(tiles.all,function(tile)
 if not mobs.by_coord[tile.x] then
  mobs.by_coord[tile.x]={}
 end
 mobs.by_coord[tile.x][tile.y]=false
end)

function spawn_mob(x,y,col,skip_tween)
 local mob = {
  x=player.x,
  y=player.y,
  col=col
 }
 if skip_tween then
  mob.x=x
  mob.y=y
 end
 mob.move_to=function(move)
  mobs.by_coord[mob.x][mob.y]=false
  //make_tween2(mob,"x","y",x,y,6)
  make_path_tween(mob,move,8)
  //mob.x=x
  //mob.y=y
  mobs.by_coord[move[1]][move[2]]=mob
 end
 mob.cancel_out=function(target)
  make_tween2(mob,"x","y",target.x,target.y,mob_spd).after=function()
			del(mobs.all,mob)
			del(mobs.all,target)
			mobs.by_coord[mob.x][mob.y]=false
			mobs.by_coord[target.x][target.y]=false
			sfx(4)
  end
 end
 if is_valid_move(x,y,mob) then
  if not mobs.by_coord[x][y] then
   add(mobs.all,mob)
   mobs.by_coord[x][y]=mob
   make_tween2(mob,"x","y",x,y,mob_spd)
   return mob
  elseif mobs.by_coord[x][y].col != mob.col then
   add(mobs.all,mob)
   mob.cancel_out(mobs.by_coord[x][y])
   return mob
  end
 end
 return false
end

function init_mobs()
 for i=1,300 do
  local spawned=false
  local tile, mob, col
  while not spawned do
   tile=rnd(tiles.all)
   mob=mobs.by_coord[tile.x][tile.y]
   if not mob then
    spawned=true
    col=tile.col
    if col == 0 then
     if rnd() < 0.5 then
      col=cola1
     else
      col=colb1
     end
    end
    spawn_mob(tile.x,tile.y,col,true)
   end
  end
 end
end
-->8
anims={
 all={},
 after_all={},
 tick=function()
  local next_anims=anims.all
  anims.all={}
  local anim
  for i=1,#next_anims do
   anim=next_anims[i]
   anim.t+=1
   if anim.t<=anim.max then
    anim.call(anim.t)
    if anim.t<anim.max then
     add(anims.all,anim)
    elseif anim.after then
     anim.after()
    end
   elseif anim.after then
    anim.after()
   end
  end
//  anims.all=next_anims
  if #anims.all == 0 then
   while #anims.after_all>0 do
    local afters=anims.after_all
    anims.after_all={}
    for i=1,#afters do
     afters[i]()
    end
    if #anims.all>0 then
     return
    end
   end
  end
 end,
 after=function(cb)
  if #anims.all>0 then
   add(anims.after_all,cb)
  else
   cb()
  end
 end
}

function make_tween2(obj,attr1,attr2,final1,final2,t_max)
 local container={}
 local call2=call_x(2,function()
  if container.after then
   container.after()
  end
 end)
 make_tween(obj,attr1,final1,t_max).after=call2
 make_tween(obj,attr2,final2,t_max).after=call2
 return container
end

function make_tween(obj,attr,final,t_max)
 local start=obj[attr]
 local dt=final-start
 local anim={
  t=0,
  max=t_max,
  call=function(t_curr)
   obj[attr]=start+(t_curr/t_max)^2*dt
   if t_curr>=t_max then
    obj[attr]=final
   end
  end
 }
 add(anims.all,anim)
 return anim
end

function make_path_tween(obj,move,t_each)
 local moves={}
 for i=2,#move[3] do
  add(moves,move[3][i])
 end
 add(moves,move)
 //debug_moves=moves
 //dsfgs●()

 if #moves > 0 then
  local cb_container={}
  local next_cb=function()
   if cb_container.after then
    cb_container.after()
   end
  end
  for i=#moves,1,-1 do
   (function(move)
    local cb=next_cb
    next_cb=function()
     local tw=make_tween2(obj,"x","y",move[1],move[2],t_each)
     tw.after=cb
     sfx(5)
    end
  	end)(moves[i])
  end
  next_cb()
  return cb_container
 end
end

function call_x(cnt,fn)
 return function(arg)
  cnt-=1
  if cnt<=0 then
   fn(arg)
  end
 end
end
__gfx__
000000005d5d5d5d0000000000000000070707770000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000015555555006666000000000077000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005555555d06777760000130000000000700c00c0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700015555555067ff760001b130070000000cc0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770005555555d067ff760001bb300000000070c0000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001555555506777760000130007000000700c00c0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005555555d006666000000000070000007000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000015151515000000000000000070707770000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000057575757575757575757575757575757b7b7b7b75757575787878787b6b6b6b656565656b6b6b6b60000000000000000000000000000000000000000
00000000755555557555555575555555755555557bbbbbbb75555555788888881bbbbbbb155555551bbbbbbb0000000000000000000000000000000000000000
0000000055555557555555575555555755555557bbbbbbb75555555788888887bbbbbbb655555556bbbbbbb60000000000000000000000000000000000000000
00000000755555557555555575555555755555557bbbbbbb75555555788888881bbbbbbb155555551bbbbbbb0000000000000000000000000000000000000000
0000000055555557555555575555555755555557bbbbbbb75555555788888887bbbbbbb655555556bbbbbbb60000000000000000000000000000000000000000
00000000755555557555555575555555755555557bbbbbbb75555555788888881bbbbbbb155555551bbbbbbb0000000000000000000000000000000000000000
0000000055555557555555575555555755555557bbbbbbb75555555788888887bbbbbbb655555556bbbbbbb60000000000000000000000000000000000000000
00000000757575757575757575757575757575757b7b7b7b75757575787878781b1b1b1b151515151b1b1b1b0000000000000000000000000000000000000000
000000005757575757575757b7b7b7b7b7b7b7b757575757b7b7b7b7575757575656565656565656565656560000000000000000000000000000000000000000
0000000075555555755555557bbbbbbb7bbbbbbb755555557bbbbbbb755555551555555515555555155555550000000000000000000000000000000000000000
000000005555555755555557bbbbbbb7bbbbbbb755555557bbbbbbb7555555575555555655555556555555560000000000000000000000000000000000000000
0000000075555555755555557bbbbbbb7bbbbbbb755555557bbbbbbb755555551555555515555555155555550000000000000000000000000000000000000000
000000005555555755555557bbbbbbb7bbbbbbb755555557bbbbbbb7555555575555555655555556555555560000000000000000000000000000000000000000
0000000075555555755555557bbbbbbb7bbbbbbb755555557bbbbbbb755555551555555515555555155555550000000000000000000000000000000000000000
000000005555555755555557bbbbbbb7bbbbbbb755555557bbbbbbb7555555575555555655555556555555560000000000000000000000000000000000000000
0000000075757575757575757b7b7b7b7b7b7b7b757575757b7b7b7b757575751515151515151515151515150000000000000000000000000000000000000000
00000000b7b7b7b787878787b7b7b7b75757575757575757575757575757575786868686b6b6b6b6b6b6b6b60000000000000000000000000000000000000000
000000007bbbbbbb788888887bbbbbbb75555555755555557555555575555555188888881bbbbbbb1bbbbbbb0000000000000000000000000000000000000000
00000000bbbbbbb788888887bbbbbbb75555555755555557555555575555555788888886bbbbbbb6bbbbbbb60000000000000000000000000000000000000000
000000007bbbbbbb788888887bbbbbbb75555555755555557555555575555555188888881bbbbbbb1bbbbbbb0000000000000000000000000000000000000000
00000000bbbbbbb788888887bbbbbbb75555555755555557555555575555555788888886bbbbbbb6bbbbbbb60000000000000000000000000000000000000000
000000007bbbbbbb788888887bbbbbbb75555555755555557555555575555555188888881bbbbbbb1bbbbbbb0000000000000000000000000000000000000000
00000000bbbbbbb788888887bbbbbbb75555555755555557555555575555555788888886bbbbbbb6bbbbbbb60000000000000000000000000000000000000000
000000007b7b7b7b787878787b7b7b7b75757575757575757575757575757575181818181b1b1b1b1b1b1b1b0000000000000000000000000000000000000000
0000000057575757575757578787878787878787878787875757575757575757b6b6b6b686868686b6b6b6b60000000000000000000000000000000000000000
0000000075555555755555557888888878c77c887888888875555555755555551bbbbbbb188888881bbbbbbb0000000000000000000000000000000000000000
000000005555555755555557888888878c7cc7c7888888875555555755555557bbbbbbb688888886bbbbbbb60000000000000000000000000000000000000000
0000000075555555755555557888888877c77c787888888875555555755555551bbbbbbb188888881bbbbbbb0000000000000000000000000000000000000000
0000000055555557555555578888888787c77c77888888875555555755555557bbbbbbb688888886bbbbbbb60000000000000000000000000000000000000000
000000007555555575555555788888887c7cc7c87888888875555555755555551bbbbbbb188888881bbbbbbb0000000000000000000000000000000000000000
0000000055555557555555578888888788c77c87888888875555555755555557bbbbbbb688888886bbbbbbb60000000000000000000000000000000000000000
00000000757575757575757578787878787878787878787875757575757575751b1b1b1b181818181b1b1b1b0000000000000000000000000000000000000000
000000005757575757575757b7b7b7b75757575757575757b7b7b7b7b7b7b7b75656565656565656565656560000000000000000000000000000000000000000
0000000075555555755555557bbbbbbb75555555755555557bbbbbbb7bbbbbbb1555555515555555155555550000000000000000000000000000000000000000
000000005555555755555557bbbbbbb75555555755555557bbbbbbb7bbbbbbb75555555655555556555555560000000000000000000000000000000000000000
0000000075555555755555557bbbbbbb75555555755555557bbbbbbb7bbbbbbb1555555515555555155555550000000000000000000000000000000000000000
000000005555555755555557bbbbbbb75555555755555557bbbbbbb7bbbbbbb75555555655555556555555560000000000000000000000000000000000000000
0000000075555555755555557bbbbbbb75555555755555557bbbbbbb7bbbbbbb1555555515555555155555550000000000000000000000000000000000000000
000000005555555755555557bbbbbbb75555555755555557bbbbbbb7bbbbbbb75555555655555556555555560000000000000000000000000000000000000000
0000000075757575757575757b7b7b7b75757575757575757b7b7b7b7b7b7b7b1515151515151515151515150000000000000000000000000000000000000000
000000005757575787878787b7b7b7b757575757b7b7b7b7575757578c8c8c8c5656565686868686868686860000000000000000000000000000000000000000
0000000075555555788888887bbbbbbb755555557bbbbbbb75555555c88888881555555518888888188888880000000000000000000000000000000000000000
000000005555555788888887bbbbbbb755555557bbbbbbb7555555578888888c5555555688888886888888860000000000000000000000000000000000000000
0000000075555555788888887bbbbbbb755555557bbbbbbb75555555c88888881555555518888888188888880000000000000000000000000000000000000000
000000005555555788888887bbbbbbb755555557bbbbbbb7555555578888888c5555555688888886888888860000000000000000000000000000000000000000
0000000075555555788888887bbbbbbb755555557bbbbbbb75555555c88888881555555518888888188888880000000000000000000000000000000000000000
000000005555555788888887bbbbbbb755555557bbbbbbb7555555578888888c5555555688888886888888860000000000000000000000000000000000000000
0000000075757575787878787b7b7b7b757575757b7b7b7b75757575c8c8c8c81515151518181818181818180000000000000000000000000000000000000000
000000005757575757575757575757575757575757575757b7b7b7b7b7b7b7b75656565656565656868686860000000000000000000000000000000000000000
0000000075555555755555557555555575555555755555557bbbbbbb7bbbbbbb1555555515555555188888880000000000000000000000000000000000000000
000000005555555755555557555555575555555755555557bbbbbbb7bbbbbbb75555555655555556888888860000000000000000000000000000000000000000
0000000075555555755555557555555575555555755555557bbbbbbb7bbbbbbb1555555515555555188888880000000000000000000000000000000000000000
000000005555555755555557555555575555555755555557bbbbbbb7bbbbbbb75555555655555556888888860000000000000000000000000000000000000000
0000000075555555755555557555555575555555755555557bbbbbbb7bbbbbbb1555555515555555188888880000000000000000000000000000000000000000
000000005555555755555557555555575555555755555557bbbbbbb7bbbbbbb75555555655555556888888860000000000000000000000000000000000000000
0000000075757575757575757575757575757575757575757b7b7b7b7b7b7b7b1515151515151515181818180000000000000000000000000000000000000000
00000000b6b6b6b656565656b6b6b6b6565656565656565656565656565656565656565686868686565656560000000000000000000000000000000000000000
000000001bbbbbbb155555551bbbbbbb155555551555555515555555155555551555555518888888155555550000000000000000000000000000000000000000
00000000bbbbbbb655555556bbbbbbb6555555565555555655555556555555565555555688888886555555560000000000000000000000000000000000000000
000000001bbbbbbb155555551bbbbbbb155555551555555515555555155555551555555518888888155555550000000000000000000000000000000000000000
00000000bbbbbbb655555556bbbbbbb6555555565555555655555556555555565555555688888886555555560000000000000000000000000000000000000000
000000001bbbbbbb155555551bbbbbbb155555551555555515555555155555551555555518888888155555550000000000000000000000000000000000000000
00000000bbbbbbb655555556bbbbbbb6555555565555555655555556555555565555555688888886555555560000000000000000000000000000000000000000
000000001b1b1b1b151515151b1b1b1b151515151515151515151515151515151515151518181818151515150000000000000000000000000000000000000000
0000000056565656565656565656565656565656b6b6b6b656565656b6b6b6b686868686b6b6b6b6868686860000000000000000000000000000000000000000
00000000155555551555555515555555155555551bbbbbbb155555551bbbbbbb188888881bbbbbbb188888880000000000000000000000000000000000000000
0000000055555556555555565555555655555556bbbbbbb655555556bbbbbbb688888886bbbbbbb6888888860000000000000000000000000000000000000000
00000000155555551555555515555555155555551bbbbbbb155555551bbbbbbb188888881bbbbbbb188888880000000000000000000000000000000000000000
0000000055555556555555565555555655555556bbbbbbb655555556bbbbbbb688888886bbbbbbb6888888860000000000000000000000000000000000000000
00000000155555551555555515555555155555551bbbbbbb155555551bbbbbbb188888881bbbbbbb188888880000000000000000000000000000000000000000
0000000055555556555555565555555655555556bbbbbbb655555556bbbbbbb688888886bbbbbbb6888888860000000000000000000000000000000000000000
00000000151515151515151515151515151515151b1b1b1b151515151b1b1b1b181818181b1b1b1b181818180000000000000000000000000000000000000000
0000000056565656868686865656565656565656b6b6b6b6b6b6b6b6565656565656565656565656868686860000000000000000000000000000000000000000
00000000155555551888888815555555155555551bbbbbbb1bbbbbbb155555551555555515555555188888880000000000000000000000000000000000000000
0000000055555556888888865555555655555556bbbbbbb6bbbbbbb6555555565555555655555556888888860000000000000000000000000000000000000000
00000000155555551888888815555555155555551bbbbbbb1bbbbbbb155555551555555515555555188888880000000000000000000000000000000000000000
0000000055555556888888865555555655555556bbbbbbb6bbbbbbb6555555565555555655555556888888860000000000000000000000000000000000000000
00000000155555551888888815555555155555551bbbbbbb1bbbbbbb155555551555555515555555188888880000000000000000000000000000000000000000
0000000055555556888888865555555655555556bbbbbbb6bbbbbbb6555555565555555655555556888888860000000000000000000000000000000000000000
00000000151515151818181815151515151515151b1b1b1b1b1b1b1b151515151515151515151515181818180000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000011040310d03110031170411b0411c0411c0411b0411702115011110010e0010000139001250112b0212e0313003131031320413204132051320513205132001310013100131001310010000100001
000100002f0102f0202f0402e0402e0402d0402b02025010210102000020000000000000000000000000000000000000001902019030190401804018040170401604015030110301003010020140000000000000
000100003104031000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001107000000080700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002905027050250502405024050240501f0501c0502805026050240502004020040200401a04017040220401f0401d0401a0301a0301a030100200e0200d00000000000000000000000000000000000000
0002000000600236101f62024620076300d630096300763023620286101c610076000a60003600076002460029600256000060000600006000060000600006000060000600006000060000600006000060000600
