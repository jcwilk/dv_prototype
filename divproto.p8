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
  col_amount=rnd(1),
  col=0, // 0 means no color
  count=1
 }

 if rnd(1) < .4 then
  if rnd(1) < .5 then
   tile.col = cola1
  else
   tile.col = colb1
  end
 end
 
 as_emitter(tile)

 return tile
end

tiles = {}
tiles.all = {}
tiles.by_coord = {}
tiles.update = function()
 local t
 local starti=min_visible_tile_y()*16+1
 local endi=max_visible_tile_y()*16+16
 endi=min(endi,#tiles.all)
 for i=starti,endi do
  tiles.all[i].update()
 end
end

function min_visible_tile_y()
 return max(flr(cam.y/8),0)
end

function max_visible_tile_y()
 return min(flr((cam.y+127)/8),ceil(#tiles.all/16))
end

function opposite_color(col)
 if col == cola1 then
  return colb1
 elseif col == colb1 then
  return cola1
 else
  non_pri=col
  non_primary_color()
 end
end

function init_tiles()
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
 tiles.by_coord[init_player_x][init_player_y].col = 0
end

function _init()
 init_tiles()
 init_player()
 init_mobs()
 highlight_moves()
 select_player_tile()
 cls()
end

function _update60()
 tiles.update()
 player.update()
 particles.update()
 
 if player.y*8 < 60 then
  cam.y=0
 else
  cam.y=player.y*8 - 60
 end
 
 if dead and btnp(4) then
  extcmd "reset"
 end
 
 if #anims.all>0 then
  anims.tick()
  return
 end
 
 if dead or check_dead(player.x,player.y) then
  dead=true
  mobs.move()
 end
 
 if(btnp(4)) then
  choose_move()
 elseif(btnp(5)) then
  rotate_attack()
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

function check_dead()
 return (player.col == 0 and #highlighted_moves == 0)
end

function press_with(fn)
 local move=fn()
 if move!=selected_move then
  sfx(2)
  select_move(move)
 else
  sfx(3)
 end
end

cam={x=0,y=0}
function _draw()
 camera(cam.x,cam.y)

 local t
 local starti=min_visible_tile_y()*16+1
 local endi=max_visible_tile_y()*16+16
 endi=min(endi,#tiles.all)
 for i=starti,endi do
  t=tiles.all[i]

  pal()
  if t.col > 0 then
   pal(5,t.col)
   if t.col == cola1 then
    pal(1,cola2)
    pal(13,14)
   else
    pal(1,colb2)
    pal(13,7)
   end
  end
  spr(1, t.x*8, t.y*8)
 end

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
 pal()
 particles.draw()
 
 if(selected_move) then
	 foreach(highlighted_moves,function(move)
	  pal()
	  spr(4, move[1]*8, move[2]*8)
	 end)
	 
  pal()
  if #sorted_attacks == 0 then
   spr(5, selected_move[1]*8, selected_move[2]*8)
  end

  local atkflp
  
  foreach(sorted_attacks,function(attack)
   atkflp = attack_flip[attack[4]]
   spr(atkflp[1]+2,selected_move[1]*8,selected_move[2]*8,1,1,atkflp[2],atkflp[2])
  end)
  
  local attack
  
  //for i=1,#attacks do
  if attack_index then
   attack=attacks[attack_index]
   if attack then
    atkflp=attack_flip[attack_index]
    pal()
    
    if attack[3] == cola1 then
     pal(11,cola1)
     pal(3,cola2)
    else
     pal(11,colb1)
     pal(3,colb2)
    end
    spr(atkflp[1], attack[1]*8, attack[2]*8, 1, 1, atkflp[2], atkflp[2])
   end
  end
 end
 
 pal()
 //rectfill(0,0,23,11,0)
 //print(stat(7),0,0,6)
 //print(stat(1),0,6,6)
 //print(stat(32),0,0,6)
 //print(stat(34),0,6,6)
 //dead=true
 if dead then
  rectfill(27,55+cam.y,101,70+cam.y,0)
  rect(27,55+cam.y,101,70+cam.y,1)
  print("dead",56,57+cam.y,8)
  print("click to try again",29,64+cam.y,7)
 end
end
-->8
player_max_path_col=4
player_max_path=2
init_player_x=2
init_player_y=2

function init_player()
 player = {
  x=init_player_x,
  y=init_player_y,
  col=0,
  count=0,
  is_player=true
 }
 as_emitter(player)
 //player.emit(10,player.col)
end

selected_move=nil
attacks={}
function select_move(move)
 selected_move = move
 sorted_attacks = sorted_attacks_for_tile(move[1],move[2])
 attacks={false,false,false,false}
 foreach(sorted_attacks,function(atk)
  attacks[atk[4]] = atk
 end)
 attack_index = false
 if #sorted_attacks > 0 then
  if selected_attack_index and attacks[selected_attack_index] then
   attack_index = selected_attack_index
  else
   attack_index = sorted_attacks[1][4]
  end
 end
end

highlighted_moves={}
function highlight_moves()
 local max_path=player_max_path
 if player.col!=0 then
  max_path=max(0,player_max_path_col+1-player.count)
 end

 local obstacles
 if player.col == 0 then
  obstacles=mobs.get_all_coords()
 else
  obstacles=mobs.get_all_coords(opposite_color(player.col))
 end
 gobs=obstacles
 unfiltered=get_path_moves(player,obstacles,max_path)
 highlighted_moves={}
 
 foreach(unfiltered,function(move)
  if player.col == 0 or any_attacks_at(move[1],move[2]) then
   if not mobs.by_coord[move[1]][move[2]] then
    add(highlighted_moves,move)
   end
  end
 end)
 
 if #highlighted_moves == 1 and player.col==0 then
  highlighted_moves={}
 end
end

function is_valid_move(x,y,col)
 return (is_on_map(x,y) and is_color_compat(x,y,col))
end

function is_on_map(x,y)
 //return (x >= 1 and x <= 10 and y >= 1 and y <= 10)
 return (x >= 0 and x <= 15 and y >= 0 and y <= 150)
end

function is_color_compat(x,y,col)
 local tile = tiles.by_coord[x][y]
 return(tile.col == 0 or col == 0 or tile.col == col)
end

function get_moves()
 local moves = {}
 for y=player.y-3,player.y+3 do
  for x=player.x-3,player.x+3 do
   if is_valid_move(x,y,player.col) then
    add(moves,{x,y})
   end
  end
 end
 return moves
end

function same_but_less(dim,move,is_less)
 local best,curr
 local other=3-dim //if 2 then 1 etc
 local val=move[dim]
 local other_val=move[other]
 
 for i=1,#highlighted_moves do
  curr=highlighted_moves[i]
  if curr[other]==other_val then
   if is_less then
    if curr[dim]<val and ((not best) or best[dim]<curr[dim]) then
     best=curr
    end
   else
    if curr[dim]>val and ((not best) or best[dim]>curr[dim]) then
     best=curr
    end
   end
  end
 end
 
 return best
end

function any_but_less(dim,move,is_less)
 local best,curr
 local other=3-dim //if 2 then 1 etc
 local val=move[dim]
 local other_val=move[other]
 
 for i=1,#highlighted_moves do
  curr=highlighted_moves[i]

  if is_less then
   if curr[dim]<val and ((not best) or (best[dim]<curr[dim] or (best[dim]==curr[dim] and abs(best[other]-other_val)>abs(curr[other]-other_val)))) then
    best=curr
   end
  else
   if curr[dim]>val and ((not best) or (best[dim]>curr[dim] or (best[dim]==curr[dim] and abs(best[other]-other_val)>abs(curr[other]-other_val)))) then
    best=curr
   end
  end
 end
  
 return best
end

function find_left_move()
 local best=same_but_less(1,selected_move,true)
 if not best then
  best=any_but_less(1,selected_move,true)
 end
 if best then
  return best
 else
  return selected_move
 end
end

function find_right_move()
 local best=same_but_less(1,selected_move,false)
 if not best then
  best=any_but_less(1,selected_move,false)
 end
 if best then
  return best
 else
  return selected_move
 end
end

function find_lower_move()
 local best=same_but_less(2,selected_move,false)
 if not best then
  best=any_but_less(2,selected_move,false)
 end
 if best then
  return best
 else
  return selected_move
 end
end

function find_higher_move()
 local best=same_but_less(2,selected_move,true)
 if not best then
  best=any_but_less(2,selected_move,true)
 end
 if best then
  return best
 else
  return selected_move
 end
end

function select_player_tile()
 for i=1,#highlighted_moves do
  local move=highlighted_moves[i]
  if move[1] == player.x and move[2] == player.y then
   select_move(move)
   return
  end
 end
 error_no_move_found()
end

function choose_move()
 local exchange = player.col != 0 or selected_move[1] != player.x or selected_move[2] != player.y
 
 make_path_tween(player,selected_move,6).after=function()
  if exchange then
   exchange_color()
  end
  anims.after(function()
   mobs.move()
   anims.after(function()
    //dupt
    highlight_moves()
    if #highlighted_moves>0 then
     select_player_tile()
    end
   end)
  end)
 end
 
 selected_move=nil
 selected_attack_index=nil
end

function rotate_attack()
 if not attack_index then
  return
 end
 
 attack_index+=1
 if attack_index > 4 then
  attack_index = 1
 end
 
 while not attacks[attack_index] do
  attack_index+=1
  if attack_index > 4 then
   attack_index = 1
  end
 end
 selected_attack_index = attack_index
end
-->8
local attack_dirs = {
 {0,-1}, //north
 {1,0}, //east
 {0,1}, //south
 {-1,0} //west
}

attack_flip = {
 {11,false},
 {10,false},
 {11,true},
 {10,true}
}

function attacks_for_tile(tile_x,tile_y)
 local source_tile=tiles.by_coord[tile_x][tile_y]
 local ret={false,false,false,false}
 local shoot_col
 
 if player.col == 0 then
  if source_tile.col != 0 then
   // shooting opposite color
   shoot_col=opposite_color(source_tile.col)
  else
   // shooting nothing
  end
 elseif player.col == source_tile.col then
  // shooting opposite color
  shoot_col=opposite_color(player.col)
 elseif source_tile.col == 0 then
  // shooting player.col
  shoot_col=player.col
 else
  // opposite colors, can't move here
 end
 
 if not shoot_col then
  return ret
 end

 local x,y,mob
 for i=1,4 do
  x=tile_x+attack_dirs[i][1]
  y=tile_y+attack_dirs[i][2]
  if is_valid_move(x,y,shoot_col) then
   mob = mobs.by_coord[x][y]
   if (not mob) or mob.col != shoot_col then
	   ret[i]={x,y,shoot_col,i}
	  end
  end
 end
 
 return ret
end

function sorted_attacks_for_tile(tile_x,tile_y)
 local raw = attacks_for_tile(tile_x,tile_y)

	local sorted={}
 for i=1,4 do
  if raw[i] then
   add(sorted,raw[i])
  end
 end
 
 local moba,mobb
 sort(sorted,function(a,b)
  moba=mobs.by_coord[a[1]][a[2]]
  mobb=mobs.by_coord[b[1]][b[2]]
  
  if (not moba) and (not mobb) then
   return false
  end
  if moba and mobb then
   return moba.count > mobb.count
  end
  return not moba
 end)
 
 return sorted
end

function any_attacks_at(x,y)
 return (#sorted_attacks_for_tile(x,y) > 0)
end

function exchange_color()
 local tile = tiles.by_coord[player.x][player.y]

 if tile.col == 0 and player.col == 0 then
  return
 end

 if tile.col == 0 then
  sfx(1)
  
  spawn_around(player.x,player.y,player.col,1)
  
  player.count-= 1
  if player.count < 1 then
   player.count = 1
   player.col = 0
   player.disable_emitter()
 	end
 	
  return
 end

 local spawn_amt = tile.count
 if player.col == 0 then
  player.col = tile.col
  player.count = tile.count
 else
  player.count+= tile.count
 end
 
 if player.count > 1 then
  player.emit(20/player.count,player.col)
 end
 
 sfx(0)
 tile.col = 0
 tile.count = 1
 tile.disable_emitter()
 local spawn_col=cola1
 if player.col == cola1 then
  spawn_col=colb1
 end
 spawn_around(player.x,player.y,spawn_col,spawn_amt)
end

function spawn_around(x,y,col,amount)
 if not attack_index then
  return
 end
 
 local attack = attacks[attack_index]
 
	spawn_mob(attack[1],attack[2],col,amount)
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


  if seen[x][y] then
   // can only get in here if this path is shorter than the last one
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

  if is_valid_move(x,y,entity.col) then
   for i=1,#obstacles do
    if x==obstacles[i][1] and y==obstacles[i][2] then
     return
    end
   end

   add(moves, {x,y,steps})

   // if they just stepped onto a color edge then don't go further
   if entity.col == 0 and tiles.by_coord[x][y].col != 0 then
    return
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

particles={
 all={},
 make=function(x,y,dx,dy,max_t,col)
  add(particles.all,{
   x=x,
   y=y,
   dx=dx,
   dy=dy,
   max_t=max_t,
   col=col,
   t=0
  })
 end,
 update=function()
  local i=1
  local p
  while i <= #particles.all do
   p=particles.all[i]
   p.x+=p.dx
   p.y+=p.dy
   p.t+=1
   if p.t <= p.max_t then
    i+=1
   else
    deli(particles.all,i)
   end
  end
 end,
 draw=function()
  local p
  for i=1,#particles.all do
   p=particles.all[i]
   pset(p.x,p.y,p.col)
  end
 end
}

function as_emitter(obj)
 local old_update=obj.update
 
 local next_in=0
 local delay=10
 local col
 local make_particle=function()
  particles.make(obj.x*8+4,obj.y*8+4,0.1-rnd(0.2),-0.1-rnd(0.1),50+rnd(10),col)
 end
 
 obj.update=function()
  if next_in > 0 then
   next_in-= 1
   while next_in <= 0 do
    next_in+= delay
    make_particle()
   end
  end
  if old_update then
   old_update()
  end
 end
 
 obj.emit=function(new_delay,new_col)
  delay=new_delay
  col=new_col
  //make_particle()
  next_in=delay
 end
 
 obj.disable_emitter=function()
  next_in=0
 end
end

-->8
mob_spd=8
mob_max_path=2
mob_max_sight=4
mob_amt=150
mobs = {
 all={},
 by_coord={},
 get_all_visible_mobs=function(col)
  local vis={}
  local miny=min_visible_tile_y()
  local maxy=max_visible_tile_y()
  local mob
  for i=1,#mobs.all do
   mob=mobs.all[i]
   if (not col or mob.col == col) and mob.y >= miny and mob.y <= maxy then
    add(vis,mob)
   end
  end
  return vis
 end,
 get_all_coords=function(col)
  local vis=mobs.get_all_visible_mobs(col)
  local coords={}
  for i=1,#vis do
   add(coords,{vis[i].x,vis[i].y})
  end
  return coords
 end,
 move=function()
  local moving={}
  local mob
  local all_visible=mobs.get_all_visible_mobs()
    
  local enemy_map={}
  enemy_map[cola1]={}
  enemy_map[colb1]={}
  
  if player.col != cola1 then
   add(enemy_map[cola1], player)
  end
  if player.col != colb1 then
   add(enemy_map[colb1], player)
  end
   
  foreach(all_visible,function(mob)
   if mob.col == cola1 then
    add(enemy_map[colb1], mob)
   elseif mob.col == colb1 then
    add(enemy_map[cola1], mob)
			else
			 error_invalid_color()
			end
  end)
  
  foreach(all_visible,function(mob)
   if not mob.col then
    error_mob_missing_color()
   end
   
   local max_path=mob_max_path+mob.count-1
   local max_sight=mob_max_sight+mob.count-1
   
   local nearby_enemies={}
   local enemy_dist
   local next_to_enemy=false
   local enemies=enemy_map[mob.col]
   local e=0
   local enemy
   
   while e<#enemies and not next_to_enemy do
    e+=1
    enemy=enemies[e]
    enemy_dist=abs(enemy.x-mob.x)+abs(enemy.y-mob.y)
   
    if enemy.is_player or enemy.count > mob.count then
     if enemy_dist <= 1 then
      next_to_enemy=true
     end
     if enemy_dist <= max_sight then
      add(nearby_enemies,enemy)
     end
    end
   end
   
   printh(mob.col.."mobx"..mob.count.."@"..mob.x..","..mob.y)
   printh("collected "..#nearby_enemies.." nearby enemies")
   
   local nearby_friends={}
   local next_to_friend=false
   
   if #nearby_enemies == 0 then
    local friend_dist
	   local friends=enemy_map[opposite_color(mob.col)]
	   local f=0
	   local friend
	   while f<#friends and not next_to_friend do
	    f+=1
	    friend=friends[f]
	    if friend != mob then
		    friend_dist=abs(friend.x-mob.x)+abs(friend.y-mob.y)
		    if friend.count > mob.count then
		     if friend_dist <= 1 then
		      next_to_friend=true
		     end
		     if friend_dist <= max_sight then
		      add(nearby_friends,friend)
		     end
		    end
		   end
	   end
	   
	   printh("collected "..#nearby_friends.." nearby friends")
   end
   
   local cart_dist=abs(mob.x-player.x)+abs(mob.y-player.y)

			local targets = {}
			
			// order of priorities:
			// x enemy/gray player
			// bigger enemy
			// x bigger friend player
			// bigger friend


			// bigger enemy or enemy/gray player
			if #targets == 0 and #nearby_enemies > 0 then
			 if next_to_enemy then
			  return
			 else
			  printh("targetting enemies")
			  targets = nearby_enemies
			 end
			end
			
			// bigger friend
			if #targets == 0 and #nearby_friends != 0 then
			 if next_to_friend then
			  return
			 else
			  printh("targetting friends")
			  targets = nearby_friends
			 end
			end
			
			// nothing to chase
			if #targets == 0 then
			 // uncomment to disable wandering
			 //return
			end
			
			printh("doing pathfinding")

			// todo - optimize this to reuse enemy stuff
   local obstacles=mobs.get_all_coords(opposite_color(mob.col))
   add(obstacles,{player.x,player.y})
   add(obstacles,selected_move)
   
   local moves=get_path_moves(mob,obstacles,max_path)
   local filtered={}
   foreach(moves,function(move)
    if not mobs.by_coord[move[1]][move[2]] then
     add(filtered,move)
    end
   end)
   
   printh("filtered "..#filtered.." moves")
   
   sortables={}
   local min_d,move
   for i=1,#filtered do
    move=filtered[i]
    min_d = 100
    for j=1,#targets do
     min_d = min(min_d,abs(move[1]-targets[j].x)+abs(move[2]-targets[j].y))
    end
    add(sortables,{
     move=filtered[i],
     min_d=min_d
    })
   end
   
   printh("sorted "..#sortables.." moves")

			local min_d
   sort(sortables,function(a,b)
    if a.min_d == b.min_d then
     return #a.move[3] > #b.move[3]
    else
     return a.min_d > b.min_d
    end
   end)

   if #sortables > 0 then
    mob.move_to(sortables[1].move)
   end
  end)
 end,
 draw=function()
  local mobspr
  foreach(mobs.all,function(mob)
   pal()
   if mob.col == cola1 then
    pal(11,cola1)
    pal(3,cola2)
   else
    pal(11,colb1)
    pal(3,colb2)
   end
   mobspr=3
   if mob.count==2 then
    mobspr=7
   elseif mob.count==3 then
    mobspr=8
   elseif mob.count==4 then
    mobspr=9
   end
   spr(mobspr,mob.x*8,mob.y*8)
  end)
 end
}

function spawn_mob(x,y,col,cnt,skip_tween)
 local mob = {
  x=player.x,
  y=player.y,
  col=col,
  count=cnt
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
   mob_count=mob.count-target.count
   target_count=target.count-mob.count
   mob.count=mob_count
   target.count=target_count
      
   if target.count >= 1 then
    del(mobs.all,mob)
    mobs.by_coord[mob.x][mob.y]=false
    mobs.by_coord[target.x][target.y]=target
   elseif mob.count >= 1 then
    del(mobs.all,target)
    mobs.by_coord[target.x][target.y]=false
    mobs.by_coord[mob.x][mob.y]=mob
   else
    del(mobs.all,target)
    del(mobs.all,mob)
    mobs.by_coord[target.x][target.y]=false
    mobs.by_coord[mob.x][mob.y]=false
   end
    
   sfx(4)
  end
 end
 if is_valid_move(x,y,mob.col) then
  if not mobs.by_coord[x][y] then
   add(mobs.all,mob)
   mobs.by_coord[x][y]=mob
   make_tween2(mob,"x","y",x,y,mob_spd)
   return mob
  elseif mobs.by_coord[x][y].col != mob.col then
   add(mobs.all,mob)
   mob.cancel_out(mobs.by_coord[x][y])
   mobs.by_coord[x][y]=mob
   return mob
  end
 end
 return false
end

function init_mobs()
 foreach(tiles.all,function(tile)
  if not mobs.by_coord[tile.x] then
   mobs.by_coord[tile.x]={}
  end
  mobs.by_coord[tile.x][tile.y]=false
 end)
 
 // spawn_mob(8,5,cola1,2,true)
 // spawn_mob(9,5,cola1,1,true)
 
 for i=1,mob_amt do
  local spawned=false
  local tile, mob, col
  while not spawned do
   tile=rnd(tiles.all)
   mob=mobs.by_coord[tile.x][tile.y]
   if (not mob) and player.x != tile.x and player.y != tile.y then
    spawned=true
    col=tile.col
    if col == 0 then
     if rnd() < 0.5 then
      col=cola1
     else
      col=colb1
     end
    end
    spawn_mob(tile.x,tile.y,col,flr(rnd(4))+1,true)
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
000000005d5d5d5d0000000000000000070707770000c000600000000000000000000000000330000000000000000000000000000000c0000000000000000000
0000000015555555006666000000000077000000000cc000760000000001300003130000001bb100000000000000000000000000000cc0000000000000000000
007007005555555d06777760000130000000000700c00c0077600000001b130003b3000003bbbb30030000000000000000000c0000c00c000000000000000000
0007700015555555067ff760001b130070000000cc0000c077000000001b130003b3113003bbbb303b30000000000000000000c0000000000000000000000000
000770005555555d067ff760001bb300000000070c0000cc60700000001bb30001b31b3001b33b10bbb1000000001000000000cc000000000000000000000000
007007001555555506777760000130007000000700c00c0000000000001bb30001bbbb3001b11b101b1000000003b10000000c00000000000000000000000000
000000005555555d006666000000000070000007000cc0000000000000013000001113000010010001000000003bbb1000000000000000000000000000000000
0000000015151515000000000000000070707770000c000000000000000000000000000000000000000000000003b10000000000000000000000000000000000
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
