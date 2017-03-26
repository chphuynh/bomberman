pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
local character = {}
local bombs = {}
local fires = {}
character.__index = character
local menu = 1
local in_game =2 
local ty =3
local p = 1

function character:new(sprite, player_number)
    local self = setmetatable({},character)
    self.sprite = sprite
    self.player_number = player_number
    self.state = 'standing'
    self.direction = 'down'
    self.frame = 0
    self.frame_speed = 0.2
    self.move_speed = 1
    self.is_dead = false
    self.atk = 2
    self.x = 0
    self.y = 0
    self.cell_x = 0
    self.cell_y = 0
    return self
end

function character:set_location(x, y)
    self.x = x
    self.y = y
end

function character:draw()
    if not self.is_dead then
        local sprite_number = 0
        local flip = false
        local moving = 0
        if(self.state == 'moveing') then moving = 1 end   
        if(self.sprite == 1) then
            palt(0, false)
            palt(11, true)
            if (self.direction == 'down') sprite_number = 33 + flr(self.frame) + moving
            if (self.direction == 'up') sprite_number = 1 + flr(self.frame) + moving
            if (self.direction == 'left') then 
                sprite_number = 4 + flr(self.frame) + moving
                flip = true
            end
            if (self.direction == 'right') sprite_number = 4 + flr(self.frame) + moving
            palt(3, true)
            palt(0, false)
            spr(sprite_number, self.x, self.y-3, 1, 2,flip,false)
            palt()
        end
    end
end

function character:update()
    self:update_cell()
    local check1 = 0 
    local check2 = 0 
    if(btn(0)) then
    				sfx(60)
        self.state = 'moveing'
        self.direction = 'left'
        self.frame = (self.frame + self.frame_speed) % 2
        check1 = coord_to_cell(self.x, self.y+2)
        check2 = coord_to_cell(self.x, self.y+7)
        if((not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) or (fget(mget(check1.x, check1.y),3) and fget(mget(check2.x, check2.y),3))) self.x -= self.move_speed
    elseif(btn(1)) then
    				sfx(60)
        self.state = 'moveing'
        self.direction = 'right'
        self.frame = (self.frame + self.frame_speed) % 2        
        check1 = coord_to_cell(self.x+7, self.y + 2)
        check2 = coord_to_cell(self.x+7, self.y + 7)
        if((not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) or (fget(mget(check1.x, check1.y),3) and fget(mget(check2.x, check2.y),3))) self.x += self.move_speed
    elseif(btn(2)) then
    				sfx(60)
        self.state = 'moveing'
        self.direction = 'up'
        self.frame = (self.frame + self.frame_speed) % 2
        check1 = coord_to_cell(self.x+1, self.y+1)
        check2 = coord_to_cell(self.x + 6, self.y+1)
        if((not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) or (fget(mget(check1.x, check1.y),3) and fget(mget(check2.x, check2.y),3))) self.y -= self.move_speed
    elseif(btn(3)) then
    				sfx(60)
        self.state = 'moveing'
        self.direction = 'down'
        self.frame = (self.frame + self.frame_speed) % 2
        check1 = coord_to_cell(self.x+1, self.y+8)
        check2 = coord_to_cell(self.x + 6, self.y+8)
        if((not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) or (fget(mget(check1.x, check1.y),3) and fget(mget(check2.x, check2.y),3))) self.y += self.move_speed
    else
        self.state = 'standing'
        self.frame = 0
    end
    
    if fget(mget(self.cell_x, self.cell_y), 2) then
        self.is_dead = true
    end
    
    self:update_cell()
end

function character:update_cell()
    fset(mget(self.cell_x, self.cell_y), 7, false)
    local temp = coord_to_cell(self.x+4, self.y+4)
    self.cell_x = temp.x
    self.cell_y = temp.y
    fset(mget(self.cell_x, self.cell_y), 7, true)
end

function coord_to_cell(x,y)
    return {x = flr((x+map_offset.x)/cell_size.width), y = flr((y-map_offset.y)/cell_size.height)+1}
end

--things to remember:
--players need to have current bomb length
--implement if danger map is up to date


danger_map = {}

safe_danger_value = 5000

function reset_danger_map()
    for i=1,15 do
        danger_map[i] = {}
        for j=1,11 do
            if fget(mget(i,j),0) then
                danger_map[i][j] = 0
            else
                danger_map[i][j] = safe_danger_value
            end
        end
    end
end

reset_danger_map()

function update_danger_map()
    reset_danger_map()
    
    foreach(bombs, function(bomb)
        danger_map[bomb.x][bomb.y] = min(danger_map[bomb.x][bomb.y],bomb.fuse)
        --{up, right, down, left}
        local position = {{bomb.x, bomb.y-1},{bomb.x+1,bomb.y},{bomb.x,bomb.y+1},{bomb.x-1,bomb.y}}
        local flame_stop = {false, false, false, false}
        local tile_increment = {{0,-1},{1,0},{0,1},{-1,0}}
        
        for i=1,2 do --hard coded bomb range
            for direction=1,4 do
                if not flame_stop[direction] then
                    if not fget(mget(position[direction][1],position[direction][2]),0) or tile_within_map() then
                        flame_stop[direction] = true
                    else
                        danger_map[position[direction][1]][position[direction][2]] = min(danger_map[position[direction][1]][position[direction][2]], bomb.fuse)
                        
                        position[direction][1] += tile_increment[direction][1]
                        
                        position[direction][2] += tile_increment[direction][2]
                    end --if
                end --if
            end --for
        end --for
    end) --foreach
end

function tile_within_map(x,y)
    return not (x < 1 or x > 15 or y < 1 or y > 11)
end

function get_danger_value(x,y)
    if not tile_within_map(x,y) then return 0 end
    
    return danger_map[x][y]
end

local bot = {}
bot.__index = bot

function bot:new()
    local self = setmetatable({},bot)
    self.x = 0 
    self.y = 0
    self.old_x = 0
    self.old_y = 0
    self.repeat_actions = {0,200}
    self.recompute_actions = 0
    self.move = 0
    self.cell_x = 0
    self.cell_y = 0
    self.outputs = {}
    self.sprite = {}
    self.sprite['up'] = 65
    self.sprite['right'] = 68
    self.sprite['down'] = 97
    self.sprite['left'] = 68
    self.direction = 'down'
    self.current_move_target = nil
    self.didnt_move_since = 0
    self.flame_length = 2
    self.bombs_left = 1
    self.bomb_refresh = 40
    self.frame = 0
    self.state = 'standing'
    self.direction = 'down'
    self.is_dead = false
    return self
end

function bot:draw()
    if not self.is_dead then
        local sprite_number = 0
        local flip = false
        local moveing = 0
        if(self.state == 'moveing') then moving = 1 end
        sprite_number = self.sprite[self.direction] + flr(self.frame) + moveing
        if self.direction == 'left' then flip = true end
        palt(0, false)
        palt(3, true)
        spr(sprite_number,self.x, self.y-3,1,2,flip,false)
        palt()
    end
end

function bot:force_move()
    if self.move >= 15 then
        self.x += -1*flr(rnd(1)) + flr(rnd(2))
        self.y += -1*flr(rnd(1)) + flr(rnd(2))
        self.move = 0
    end
    
    if self.x == self.old_x and self.y == self.old_y then
        self.move += 1
    end
    
    self.old_x = self.x
    self.old_y = self.y
end

function bot:update()
    local old_cellx = self.cell_x
    local old_celly = self.cell_y
    self:update_cell()
    local ouputs = {}
    if old_cellx == self.cell_x and old_celly == self.cell_y and self.state == 'moveing' then
        outputs = self.outputs
    else    
        outputs = self:play()
    end
    
    if outputs == {} then
        self.state = 'standing'
    end
    
    foreach(outputs, function(action)
        if action == 'up' then
            self.state = 'moveing'
            self.direction = action
            check1 = coord_to_cell(self.x, self.y+1)
            check2 = coord_to_cell(self.x + 7, self.y+2)
            if(not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) then self.y -= 1 else
            self.state = 'standing' end
        elseif action == 'down' then
            self.state = 'moveing'
            self.direction = action
            check1 = coord_to_cell(self.x, self.y+8)
            check2 = coord_to_cell(self.x + 7, self.y+8)
            if(not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) then self.y += 1 else
            self.state = 'standing' end
        elseif action == 'right' then
            self.state = 'moveing'
            self.direction = action
            check1 = coord_to_cell(self.x+7, self.y + 2)
            check2 = coord_to_cell(self.x+7, self.y + 7)
            if(not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) then self.x += 1 else
            self.state = 'standing' end
        elseif action == 'left' then
            self.state = 'moveing'
            self.direction = action
            check1 = coord_to_cell(self.x, self.y+2)
            check2 = coord_to_cell(self.x, self.y+7)
            if(not fget(mget(check1.x, check1.y),0) and not fget(mget(check2.x, check2.y),0)) then self.x -= 1 else
            self.state = 'standing' end
        elseif action == 'bomb' then
            if self.bombs_left > 0 then
            make_bomb(flr((self.x)/8)*8+4,flr((self.y)/8)*8+7)
            self.bombs_left -= 1
            end
        end
    end)
    
    if self.bombs_left == 0 then
        self.bomb_refresh -= 1
    end
    
    if self.bomb_refresh == 0 then
        self.bombs_left = 1
        self.bomb_refresh = 40
    end
    
    if fget(mget(self.cell_x, self.cell_y), 2) then
        self.is_dead = true
    end
    
    --self:force_move()
end

function bot:update_cell()
    local base = coord_to_cell(self.x+1,self.y+2)
    --if base == coord_to_cell(self.x+6,self.y+2) and base == coord_to_cell(self.x+1,self.y+7) and coord_to_cell(self.x+6,self.y+7) then
        self.cell_x = base.x
        self.cell_y = base.y
    --end
end

function bot:tile_escapable(x,y)
    return not fget(mget(x,y),0) --need to insert code here for flame
end

--returns tuple indicating rough general direction of other player
--prevents walking off map
function bot:decide_gen_direction()
    --need to implement player list
    --uses player 1 for now
    local dx = player.cell_x - self.cell_x
    local dy = player.cell_y - self.cell_y
    
    return {min(max(-1,dx),1), min(max(-1,dy),1)}
end

--rates each direction for how many clear tiles there are to escape
--returns tuple with number of safe tiles {up, right, down, left}
function bot:rate_bomb_escape_dir(x,y)
    --{up, right, down, left}
    local axis_dir = {{0,-1},{1,0},{0,1},{-1,0}}
    local perp_dir = {{1,0}, {0,1}, {1,0}, {0,1}}
    
    local res = {0,0,0,0}
    
    for direction=1,4 do
        for i=1,4 do --hard coded range, supposed to be self bomb range + 2
            local axis_tile = {x + i * axis_dir[direction][1], y + i * axis_dir[direction][2]}
            
            if not self:tile_escapable(axis_tile[1],axis_tile[2]) then
                break
            end
            
            perp_tile1 = {axis_tile[1] + perp_dir[direction][1], axis_tile[2] + perp_dir[direction][2]}
            
            perp_tile2 = {axis_tile[1] - perp_dir[direction][1], axis_tile[2] - perp_dir[direction][2]}
            
            if i > 4 and not fget(mget(axis_tile[1],axis_tile[2]),2) then --if tile is not fire/ temp flag 2 = 2
                res[direction] += 1
            end
            
            if self:tile_escapable(perp_tile1[1],perp_tile1[2]) and not fget(mget(perp_tile1[1],perp_tile1[2]),4) then
                res[direction] += 1
            end
            
            if self:tile_escapable(perp_tile2[1],perp_tile2[2]) and not fget(mget(perp_tile2[1],perp_tile2[2]),4) then
                res[direction] += 1
            end
        end
    end
    
    return res
end

function bot:rate_tile(x,y)
    local danger = get_danger_value(x,y)
    
    if danger == 0 then return 0 end
    
    local score = 0
    
    if danger < 10 then
        score = 20
    elseif danger < 30 then
        score = 40
    else 
        score = 60
    end
    
    --implement addition to score if tile has item
    --if tile has item and is not poison add 20
    --if tile has item and is poison subtract 10
    
    return score
end

function bot:is_trapped()
    --{up,right,down,left}
    local adj_tiles = {{self.cell_x,self.cell_y-1},{self.cell_x+1,self.cell_y},{self.cell_x, self.cell_y+1},{self.cell_x-1,self.cell_y}}
    
    local trapped = true
    
    for direction=1,4 do
        if not fget(mget(adj_tiles[direction][1],adj_tiles[direction][2]),0) then
            trapped = false
            break
        end
    end
    
    return trapped
end

function ceil(num)
  return flr(num+0x0.ffff)
end

function bot:play()
    if self.is_dead then return {} end
    
    if game_time < self.recompute_actions then
        return self.outputs
    end
    
    self.outputs = {}
    
    escape_ratings = self:rate_bomb_escape_dir(self.cell_x, self.cell_y)
    
    local chosen_movement = nil
    
    if self:is_trapped() then
        local dir = {'up','right','down', 'left'}
        chosen_movement = dir[0]
    elseif fget(mget(self.cell_x,self.cell_y),4) then --hardcode flag 3 for bomb tile = 4
        local best_rating = escape_ratings[1]
        local best_action = 'up'

        if escape_ratings[2] > best_rating then
            best_rating = escape_ratings[2]
            best_action = 'right'
        end
        
        if escape_ratings[3] > best_rating then
            best_rating = escape_ratings[3]
            best_action = 'down'
        end
        
        if escape_ratings[4] > best_rating then
            best_rating = escape_ratings[4]
            best_action = 'left'
        end
        
        chosen_movement = best_action
    else --not standing on bomb and not trapped
        --not move?
        local max_score = self:rate_tile(self.cell_x,self.cell_y)
        local best_direction_actions = {nil}
        local num_actions = 1
        
        local general_direction = self:decide_gen_direction()
        local tile_increment = {{0,-1},{1,0},{0,1},{-1,0}}
        local action = {'up','right','down','left'}
        
        --move in what direction?
        for direction=1,4 do
            local score = self:rate_tile(self.cell_x + tile_increment[direction][1], self.cell_y + tile_increment[direction][2])
            
            local extra_score = 0
            
            if tile_increment[direction][1] == general_direction[1] then
                extra_score += 10
            end
            
            if tile_increment[direction][2] == general_direction[2] then
                extra_score += 10
            end
            
            score += extra_score
            
            if score > max_score then
                max_score = score
                best_direction_actions = {action[direction]}
                num_actions = 1
            elseif score == max_score then
                add(best_direction_actions,action[direction])
                num_actions += 1
            end
        end
        
        chosen_movement = best_direction_actions[0] --ceil(rnd(num_actions))
    end
   
    if chosen_movement != nil then
         --implement flip directions if poisoned here
         
        add(self.outputs, chosen_movement)
        
        self.didnt_move_since = game_time
    end
    
    --force move if havent move in 10 seconds
    if game_time - self.didnt_move_since > 300 then
      local action = {'up','right','down','left'}
      add(self.outputs, action[ceil(rnd(4))])
    end
    
    --place bomb decision 
    local bomb_laid = false
    
    if not fget(mget(self.cell_x,self.cell_y),8) and self.bombs_left > 0 and get_danger_value(self.cell_x,self.cell_y) > 60 and (escape_ratings[1] > 0 or escape_ratings[2] > 0 or escape_ratings[3] > 0 or escape_ratings[4] > 0) then --if tile has no bomb, bot has bombs and can escape
        local chance_to_put_bomb = 100 --1/100 chance to place bomb
        
        local players_near = self:players_nearby()
        
        if players_near > 0 then --enemy nearby
            chance_to_put_bomb = 5
        else
            --make ai place bomb more often if less blocks
        end
    end
    
    num_block_neighbors = self:num_blocks_near_tile(self.cell_x,self.cell_y)
    
    if num_block_neighbors == 1 then
        chance_to_put_bomb = 3
    elseif num_block_neighbors == 2 or num_block_neighbors == 3 then
        chance_to_put_bomb = 2
    end
    
    if flr(rnd(chance_to_put_bomb)) == 0 then     
        bomb_laid = true
        add(self.outputs, 'bomb')
    end
    
    if bomb_laid then
        self.recompute_compute_actions_on = game_time + 10
    else
        self.recompute_actions = game_time + self.repeat_actions[ceil(rnd(2))]
    end
    
    return self.outputs
end

--return number of destroyable blocks nearby
function bot:num_blocks_near_tile(x,y)
    local count_block = 0
    local tile_increment = {{0,-1},{1,0},{0,1},{-1,0}}
    
    for direction=1,4 do
        if fget(mget(x + tile_increment[direction][1], y + tile_increment[direction][2]),1) then
            count_block += 1
        end
    end
    
    return count_block
end

--returns number of players nearby
function bot:players_nearby()
    local enemies = 0
    foreach(all_players, function(enemy)
        if not(enemy.is_dead or enemy == self) then
            if(abs(self.cell_x - enemy.cell_x) <= 1 and abs(self.cell_y - enemy.cell_y) <= 1) then
                enemies += 1
            end
        end
    end)
    return enemies
end

local block  = {}
block.__index = block

function block:new()
    local self = setmetatable({},block)
    self.sprite = 44
    self.x = 0
    self.y = 0
    return self
end

function block:draw()
    mset(self.x,self.y,self.sprite)
end

function block:set_coord(x,y)
    self.x = x
    self.y = y
end

num_blocks = 0

function generate_blocks()
    for i = 1,150 do
        local coord = generate_coordinates()
        local bl = block.new()
        bl:set_coord(coord.x, coord.y)
        add(blocks, bl)
        num_blocks += 1
        filter_blocks(num_blocks)
    end
    
    filter_blocks(num_blocks)
end

function filter_blocks(size)
    if(size == 1) return
    local dup_blocks = {}
    for i=1,size do
        for j=i+1,size do
            if ((blocks[i].x == blocks[j].x) and blocks[i].y == blocks[j].y) add(dup_blocks, blocks[i])
            break
        end
    end
    
    foreach(dup_blocks, function(obj) del(blocks,obj) num_blocks -= 1 end)
end

function generate_coordinates()
    local coord = {x = flr(rnd(13)+2), y = flr(rnd(9)+2)}
    if((coord.x == 3 or coord.x == 5 or coord.x == 7 or coord.x == 9 or coord.x == 11 or coord.x == 13)
            and (coord.y == 3 or coord.y == 5 or coord.y == 7 or coord.y == 9) 
        or ((coord.x == 2 or coord.x == 3 or coord.x == 13 or coord.x == 14)
            and (coord.y == 2 or coord.y == 3 or coord.y == 9 or coord.y == 10))) then
       return generate_coordinates() 
    end
    return coord
end

function make_bomb(x,y)
    b = {}
    b.x = x
    b.y = y
    b.spr = 42
    b.fuse = 45
    add(bombs,b)
    return b
end

function make_fire(x,y,sn)
    f = {}
    f.x = x
    f.y = y
    f.spr = sn
    f.timer = 17
    add(fires,f)
    return f
end

function spawn_bomb()
    if btnp(4) then
        make_bomb(flr((player.x)/8)*8+4,flr((player.y)/8)*8+7)
    end
end

function draw_bombs()
    for i,b in pairs(bombs) do
        --spr(b.spr,b.x,b.y)
        local tile = coord_to_cell(b.x, b.y)
        mset(tile.x,tile.y,b.spr)
    end
end

function bomb_timer()
    for i,b in pairs(bombs) do
        b.fuse -= 1
        if b.fuse <= 0 then
            explode(b)
        end
    end
end

function breakable(x,y)
    if fget(mget(x,y),1) then
        return true
    end
    return false
end

function is_wall(x,y)
    if fget(mget(x,y),0) then
        return true
    end
    return false
end

function break_block(x,y)
    del(blocks, get_block(x,y))
    mset(x,y,11)
end

function get_block(x,y)
    for i,b in pairs(blocks) do
        if(x == b.x and y == b.y) then
            --sfx(60)
            return b
        end
    end
end

function explode(b)
    sfx(62)
    b_x = b.x
    b_y = b.y
    del(bombs,b) --remove bomb from table
    make_fire(b_x,b_y,108) --center explosion
    local check = 0
    --left explosion
    for i=1,2 do --hard-coded range
        check = coord_to_cell(b_x-(8*i),b_y)
        if fget(mget(check.x,check.y),3) then
            sfx(61)
        elseif breakable(check.x,check.y) then
            break_block(check.x,check.y)
            break --this should be in above mentioned method
        elseif is_wall(check.x,check.y) then
            break
        else
            if i == 1 then --draws explosion body
                make_fire(b_x-(8*i),b_y,109)
            else --draws explosion tail
                make_fire(b_x-(8*i),b_y,107)
            end
        end
    end
    --right explosion
    for i=1,2 do
        check = coord_to_cell(b_x+(8*i),b_y)
        if breakable(check.x,check.y) then
            break_block(check.x,check.y)
            break
        --check if block to left has flag 0
        elseif is_wall(check.x,check.y) then
            break
        else
            if i == 1 then
                make_fire(b_x+(8*i),b_y,109)
            else
                make_fire(b_x+(8*i),b_y,111)
            end
        end
    end
    --down explosion
    for i=1,2 do
        check = coord_to_cell(b_x,b_y+(8*i))
        if breakable(check.x,check.y) then
            break_block(check.x,check.y)
            break
        --check if block to left has flag 0
        elseif is_wall(check.x,check.y) then
            break
        else
            if i == 1 then
                make_fire(b_x,b_y+(8*i),110)
            else
                make_fire(b_x,b_y+(8*i),124)
            end
        end
    end
    --up explosion
    for i=1,2 do
        check = coord_to_cell(b_x,b_y-(8*i))
        if breakable(check.x,check.y) then
            break_block(check.x,check.y)
            break
        --check if block to left has flag 0
        elseif is_wall(check.x,check.y) then
            break
        else
            if i == 1 then
                make_fire(b_x,b_y-(8*i),110)
            else
                make_fire(b_x,b_y-(8*i),92)
            end
        end
    end
end


function draw_fires()
    for i,f in pairs(fires) do
        --spr(f.spr,f.x,f.y)
        local tile = coord_to_cell(f.x,f.y)
        mset(tile.x,tile.y,f.spr)
    end
end

function update_fires()
    for i,f in pairs(fires) do
        f.timer -= 1
        if f.timer <= 0 then
            local tile = coord_to_cell(f.x,f.y)
            mset(tile.x, tile.y, 9)
            del(fires,f)
        end
    end
end

function menu_functions()
	if btnp(5) then
		if p==menu then
			p=in_game		
		elseif p==in_game then
		 p=ty
	 elseif p==ty then
		 p = menu
		end
	end
end

function update_bombs_functions()
    spawn_bomb()
    bomb_timer()
    update_fires()
end

function debug_bombs()
    print("#bombs "..#bombs)
    for i,b in pairs(bombs) do
        print(b.x..", "..b.y,0,18)
        rect(b.x,b.y,b.x+8,b.y+8)
    end
end

function draw_menu_sprite_logic()
	local a={0,8,16,24,32,40,48,56}
 local i = 200
 local j = 216
	if p== menu then
		print("press x to start",5,20)	
		for item in all(a) do
			spr(i,item,0) 
			spr(j,item,8)
			j+=1
			i+=1
	 end
	end	
end

function hud()
--print("hi")
	local a={6,30,54,76}
	local l = 88
	 for item in all (a) do
		spr(l,item,29)
				l+=1
 	end
end
 
function _init()
    music(1)
    cell_size = {width = 8, height = 8}
    map_offset = {x = 4, y = 39}
    player = character.new(1,1,0)
    player:set_location(map_offset.x+8,map_offset.y+72)
    ai = bot.new()
    ai.x = map_offset.x + 8*13
    ai.y = map_offset.y + 8*1
    all_players = {}
    game_time = 5400 --3:00 game timer
    blocks = {}
    generate_blocks()
    foreach(blocks, function(obj) obj:draw() end)
end

function _draw()
    cls()
    rectfill(0,0,128,128,2)
	   rectfill(map_offset.x-1,map_offset.y-1,124,127,7)
	  	palt(0,false)
	   map(1,1,map_offset.x,map_offset.y,15,11)
	   draw_bombs()
    player:draw()
    draw_fires()
    color(12)
    ai:draw()
    --print(count)
    --print(p)
    if p==menu then
    	draw_menu_sprite_logic()
    elseif p==in_game then
    	hud()
    end
    --print(ai.cell_x)
    --print(ai.cell_y)
    --print(fget(mget(ai.cell_x,ai.cell_y),2))
    --print(ai.move)
    --debug_bombs()
    --for i,j in pairs(player) do print(i.." "..j) end
    --print((mget(player.cell_x,player.cell_y),0))
    --print(mget(player.cell_x,player.cell_y))
    --rect(player.x+1,player.y+2,player.x+6,player.y+7)
end


function _update()
			menu_functions()
			if	p==in_game then
 			cell_size = {width = 8, height = 8}
				player:update()
                game_time -=1
                ai:update()
				update_bombs_functions()
			end
		--elseif(p==3)	
  --foreach(blocks, function(obj) obj:draw() end)
end
__gfx__
eeeeeeee333003333330033333300333333003333330033333300333333333333333333333333333888888883333333388888888333333331000000133333333
eeeeeeee3008e0033008e0033008e0033008e0033008e0033008e0033333333333333333333333338889a9a83333333388888887333333330777777033333333
eeeeeeee080e8080080e8080080e8080080e8080080e8080080e808033333333333333333333333388aaaaa83333333388551578333333330755557033333333
eeeeeeee80888808808888088088880880888a8080888a8080888a803333330003333333333333338a2a2aa833333333857d5108333333330756667033333333
eeeeeeee8088880880888808808888088084a8a18084a8a18084a8a13333307e70333333333333338a2a2aa83333333385d55118333333330777777033333333
eeeeeeee808888088088880880888808804f0f0f804f0f0f804f0f0f3333000000033333333333338a2a2aa83333333385551618333333330666666033333333
eeeeeeee808888088088880880888808804f0f0f804f0f0f804f0f0f3330777777703333333333338aa8aa983333333381116d18333333330666666033333333
eeeeeeee08888880088888800888888008848880088488800884888033077777777703333333333388aaa9883333333388111188333333330111111033333333
33333333008888000088880000888800008888000088880000888800330777777777033333333333888888883333333388888888333333330111111033333333
333333330e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e0330777777777033333333333333333333333333333333333333333333333333333333333
33333333308008033080000330000803308008033000080330800003330740444047033333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333307f0fff0f7033333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333307f0fff0f7033333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333330740fff047033333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333330077444770033333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333330707777707033333333333333333333333333333333333333333333333333333333333
33333333333003333330033333300333000000000000000033333333307700000007703333333333333333373333333379999994333333333333333333333333
333333333008e0033008e0033008e0030000000000000000333333330e7001ccc100e7033333333333338a833333333344244442333333333333333333333333
33333333080e8080080e8080080e80800000000000000000333333330e70100a0010e703333333333111aaa33333333379499994333333333333333333333333
33333333808aa808808aa808808aa8080000000000000000333333333000011c110000333333333317d18a833333333344244420333333333b3bb3b333333333
3333333380a88a0880a88a0880a88a080000000000000000333333333307700000770333333333331d1111333333333379999942333333333bbbbbb333333333
333333330f0ff0f00f0ff0f00f0ff0f0000000000000000033333333307ee77077ee7033333333331112913333333333444444203333333333bbbb3333333333
333333330f0ff0f00f0ff0f00f0ff0f00000000000000000333333333077e70007e7703333333333111621533333333342222200333333333333333333333333
33333333088888800888888008888880000000000000000033333333330000000000033333333333511115533333333320000000333333333333333333333333
33333333008888000088880000888800000000000000000033333333333333333333333333333333555555533333333342022220333333333333333333333333
333333330e4aa4e00e4aa4e00e4aa4e0000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333308008033080000330000803000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333000000000000000033333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333000000333333333300000333333333
333333333330033333300333333003333330033333300333333003333333333333333333333333333333333333333333330888c0333333330066660033333333
333333333008e0033008e0033008e0033008e0033008e0033008e0033333333333333333333333333333333333333333330cc7c0333333330666666033333333
33333333070e8070070e8070070e8070070e8070070e8070070e8070333333333333333333333333333333333333333300c888c033333333c006600c33333333
3333333370777707707777077077770770777a7070777a7070777a7033333333333333333333333333333333333333330ccc77c033333333ca066a0c33333333
333333337077770770777707707777077074a7a17074a7a17074a7a133333333333333333333333333333333333333330cc0cc0033333333066aa66033333333
33333333707777077077770770777707704f0f0f704f0f0f704f0f0f3333333333333333333333333333333333333333000a00a0333333333060060333333333
33333333707777077077770770777707704f0f0f704f0f0f704f0f0f333333333333333333333333333333333333333333303303333333333060060333333333
333333330777777007777770077777700774777007747770077477703333333377700777ccc00ccc88800888bbb00bbb33888833333333333333333333333333
33333333007777000077770000777700007777000077770000777700333333337008e007c008e00c8008e008b00be00b33899833333333333333333333333333
333333330e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e033333333070e80700c0e80c0080e80800b0eb0b038899883333333333333333333333333
3333333330700703307000033000070330700703300007033070000333333333707aa707c0caac0c808aa808b0baab0b389aa983333333333333333333333333
333333333333333333333333333333333333333333333333333333333333333370a77a07c0acca0c80a88a08b0abba0b389aa983333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333330f0ff0f00f0ff0f00f0ff0f00f0ff0f0889aa988333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333330f0ff0f00f0ff0f00f0ff0f00f0ff0f0899aa998333333333333333333333333
333333333333333333333333333333333333333333333333333333333333333377777777cccccccc88888888bbbbbbbb89a77a98333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333888889a77a988888888889a77a9888833333
33333333333003333330033333300333333333333333333333333333333333333333333333333333333333333888899999a77a999999999989a77a9899888833
333333333008e0033008e0033008e00333333333333333333333333333333333333333333333333333333333889999aaaaa77aaaaaaaaaaa89a77a98a9999888
33333333070e8070070e8070070e80703333333333333333333333333333333333333333333333333333333389aaaaa7777777777777777789a77a987aaaa998
33333333707aa707707aa707707aa7073333333333333333333333333333333333333333333333333333333389aaaaa7777777777777777789a77a987aaaa998
3333333370a77a0770a77a0770a77a0733333333333333333333333333333333333333333333333333333333889999aaaaa77aaaaaaaaaaa89a77a98a9999888
333333330f0ff0f00f0ff0f00f0ff0f0333333333333333333333333333333333333333333333333333333333888899999a77a999999999989a77a9899888833
333333330f0ff0f00f0ff0f00f0ff0f0333333333333333333333333333333333333333333333333333333333333888889a77a988888888889a77a9888833333
33333333077777700777777007777770333333333333333333333333333333333333333333333333333333333333333389a77a98333333333333333333333333
333333330077770000777700007777003333333333333333333333333333333333333333333333333333333333333333899aa998333333333333333333333333
333333330e4aa4e00e4aa4e00e4aa4e03333333333333333333333333333333333333333333333333333333333333333889aa988333333333333333333333333
333333333070070330700003300007033333333333333333333333333333333333333333333333333333333333333333389aa983333333333333333333333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333389aa983333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333338899883333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333899833333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333888833333333333333333333333333
33333333333003333330033333300333333003333330033333300333333333333333333333333333655065505555550500000000015555555555551011111111
333333333008e0033008e0033008e0033008e0033008e0033008e003333333333333333333333333000065501111110555555055101111111111110111111111
333333330b0e80b00b0e80b00b0e80b00b0e80b00b0e80b00b0e80b0333333333333333333333333665065501111110155555065110111111111101111333333
33333333b0bbbb0bb0bbbb0bb0bbbb0bb0bbbab0b0bbbab0b0bbbab0333333333333333333333333655065500000000066666066511000000000011511333333
33333333b0bbbb0bb0bbbb0bb0bbbb0bb0b4aba1b0b4aba1b0b4aba1333333333333333333333333655000005550555500000000511001555510011511333333
33333333b0bbbb0bb0bbbb0bb0bbbb0bb04f0f0fb04f0f0fb04f0f0f333333333333333333333333655066501110511155055555511010111101011511333333
33333333b0bbbb0bb0bbbb0bb0bbbb0bb04f0f0fb04f0f0fb04f0f0f333333333333333333333333655065501110111155065555651051011011015611333333
333333330bbbbbb00bbbbbb00bbbbbb00bb4bbb00bb4bbb00bb4bbb0333333333333333333333333655065500000000066066666651065100115055611333333
3333333300bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb00333333333333333333333333055605566550651001560556113333331111111133333311
333333330e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e0333333333333333333333333055605566550610110160556113333331111111133333311
3333333330b00b0330b0000330000b0330b00b0330000b0330b00003333333333333333333333333000005566550101551010556113333333333333333333311
33333333333333333333333333333333333333333333333333333333333333333333333333333333056605566550016666100556113333333333333333333311
33333333333333333333333333333333333333333333333333333333333333333333333333333333055605566510000000000156113333333333333333333311
33333333333333333333333333333333333333333333333333333333333333333333333333333333055600006101555555551016113333333333333333333311
33333333333333333333333333333333333333333333333333333333333333333333333333333333055605661015555555555101113333333333333333333311
33333333333333333333333333333333333333333333333333333333333333333333333333333333055605560166666666666610113333333333333333333311
33333333333003333330033333300333333333333333333333333333333333333333333333333333333333331111111113333333420222203333333333333333
333333333008e0033008e0033008e003333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
333333330b0e80b00b0e80b00b0e80b0333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
33333333b0baab0bb0baab0bb0baab0b333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
33333333b0abba0bb0abba0bb0abba0b333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
333333330f0ff0f00f0ff0f00f0ff0f0333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
333333330f0ff0f00f0ff0f00f0ff0f0333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
333333330bbbbbb00bbbbbb00bbbbbb0333333333333333333333333333333333333333333333333133333333333333333333333113333333333333333333333
3333333300bbbb0000bbbb0000bbbb00333333333333333333333333333333333333333333333333311111111111111133333333420222203333333333333333
333333330e4aa4e00e4aa4e00e4aa4e0333333333333333333333333333333333333333333333333133333331111111133333333133333333333333333333333
3333333330b00b0330b0000330000b03333333333333333333333333333333333333333333333333133333331333333333333333133333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333133333331333333333333333133333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333133333331333333333333333133333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333133333331333333333333333133333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333133333331333333333333333133333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333133333331333333333333333133333333333333333333333
33333333333003333330033333300333333003333330033333300333333333333333333333333333333333333333333333333333333333333333333333333333
333333333008e0033008e0033008e0033008e0033008e0033008e0033333333333333333a3a33333333333333333333333333333333333333333333333333333
333333330c0e80c00c0e80c00c0e80c00c0e80c00c0e80c00c0e80c0333333333333333338333333333333333333333333333333333333333333333333333333
33333333c0cccc0cc0cccc0cc0cccc0cc0cccac0c0cccac0c0cccac0333333333333333387a33333333333333333333333333333333333333333333333333333
33333333c0cccc0cc0cccc0cc0cccc0cc0c4aca1c0c4aca1c0c4aca13333333339993336666339333939993399993999339333933993393393933a3333333333
33333333c0cccc0cc0cccc0cc0cccc0cc04f0f0fc04f0f0fc04f0f0f333333333933936776613999993933939333393393999993933939339393a3a333333333
33333333c0cccc0cc0cccc0cc0cccc0cc04f0f0fc04f0f0fc04f0f0f33333333399933676611393939399933999339993393939399993993939a333a33333333
333333330cccccc00cccccc00cccccc00cc4ccc00cc4ccc00cc4ccc0333333333933936661113933393933939333393933933393933939399393a3a333333333
3333333300cccc0000cccc0000cccc0000cccc0000cccc0000cccc00333333333999333111133933393999339999393393933393933939339333333333333333
333333330e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e00e1aa1e0333333333333773333333333333333333333333333333333333333333393333333333333
3333333330c00c0330c0000330000c0330c00c0330000c0330c000033333333333333777733333333333c3cccc3ccc3ccc3cccc3ccc333ccc333333333333333
333333333333333333333333333333333333333333333333333333333333333333333337333333773333c3c33333c333c33c3333c33c3c333333333333333333
333333333333333333333333333333333333333333333333333333333333333333333377777733733333c3ccc333c333c33ccc33ccc333cc3333333333333333
333333333333333333333333333333333333333333333333333333333333333333333337337337773c33c3c33333c333c33c3333c3c33333c333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333777773333cc33cccc33c333c33cccc3c33c3ccc3333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333337333333333333333333333333333333333333333333333333333
33333333333003333330033333300333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333008e0033008e0033008e003333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333330c0e80c00c0e80c00c0e80c0333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333c0caac0cc0caac0cc0caac0c333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333c0acca0cc0acca0cc0acca0c333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333330f0ff0f00f0ff0f00f0ff0f0333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333330f0ff0f00f0ff0f00f0ff0f0333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333330cccccc00cccccc00cccccc0333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333300cccc0000cccc0000cccc00333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333330e4aa4e00e4aa4e00e4aa4e0333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333330c00c0330c0000330000c03333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333

__gff__
0000000000000000000000800000010000000000000000000000000000000000000000000000000000000900030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000040404040400000000000000000000000004000000
0000000000000000000001010101010000000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000
__map__
2424242424242424242424242424352424242424242424242424242424252525252525252525252525252525252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248d8b8b8b8b8b8b8b8b8b8b8b8b8b8e25252424242424242424242424242525252525242524252525242524250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090909090909090909090909099a25252424242424242424242424343525253435343534353435343534350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090e090e090e090e090e090e099a25252424242424242424242424343535352425242524252425242524252425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090909090909090909090909099a25252424242424242424242424343534353435343534353435343534353435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090e090e090e090e090e090e099a25252424242424242424242424242524252425242524252425242524252425242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090909090909090909090909099a25252424242424242424242424243534353435343534353435343534353435343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090e090e090e090e090e090e099a25252424242424242424242424242524252425242524252425242524252425242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090909090909090909090909099a25252424242424242424242424243534353435343534353435343534353435343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090e090e090e090e090e090e099a25252424242424242424242424252524252425242524252425242524252425242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
248a090909090909090909090909099a25252424242424242424242424253534353435343534353435343534353435343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
249b8c8c8c8c8c8c8c8c8c8c8c8c8c9c25252424242424242424242424252524252425242524252425242524252425242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3434343434343434343434343434343425343424242424242424242424242434353435343534353435343534353435343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3434343434343434343434343434343434343424343424242424242424252524252425242524252425242524252425242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024250000003434343434000000000000000000000000242424252425242534353435343534353435343534353435343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0034350000000000000000000000000000000000000000343534353435343524252425242524252425242500002425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0034350000000000000000000000000000000000000000003435343534353534353435343534353435343500003435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024252425000000000000000000000000000000000000000000000000242524252425242524250000242524250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0034353435000000000000000000000000000000000000000000000000343534353435343534350000343534350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2524252425000000000000000000000000000000000000000000000000000024252425242524252425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3534353435000000000000000000000000000000000000000000000000000034353435343534353435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2524250000000000000000000000000000000000000000000000000000000024252425242524252425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3534350000000000000000000000000000000000000000000000000000000034353435343534353435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024250000000000000000000000002425000000002425000000000000242524252425242524252425242500000000242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0034350000000000000000000000003435000000003435000000000000343534353435343534353435343500000000343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000024252425000000002425242524250000242524252425242524252425242524250000000000000000242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000034353435000000003435343534350000343534353435343534353435343534350000000000000000343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000002425000024250000242524252425242524252425000024252425000024250000242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000003435000034350000343534353435343534353435000034353435000034350000343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222102221000000000002e2102e2102e2102e2102c2102c2100000000000
0109000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e1102e11000000000003a1103a1103a1103a11038110381100000000000
01090000080100801008010080150801008010080100801508010080100a0100a0100c0100c0100a0100a0150a0100a0100a0100a0150a0100a0100a0100a0150a0100a0100a0100a0150a0100a0100a0100a010
010900002b2102b2102b2102b2102c2102c2102b2102b210000000000027210272100000000000242102421027210272100000000000000000000027210272102621026210272102721029210292102621026210
010900002241022410224102241022410224102241022410224102241022410224102241022410224102241024410244102441024410244102441024410244102441024410244102441024410244102441024410
0109000007010070100701007015070100701007010070100c0100c01007010070100a0100a0100c0100c0150c0100c0100c0100c0150c0100c0100c0100c0150c0100c0100c0100c0150c0100c0100c0100c010
010900000000000000000000000022210222100000000000222102221000000000001f2101f21022210222102221022210222102221000000000000000000000000000000000000000001f2101f2101f2101f210
010900002241022410224102241022410224102241022410224102241022410224101f4101f4101f4101f41524410244102441024410000000000022410224100000000000000000000022410224100000000000
01090000050100501005010050150501005010050100501006010060100701007010080100801007010070150701007010070100701507010070100701007010080100801009010090100a0100a0100b0100b010
010900002021020210202102021027210272102721027210000000000000000000002621026210262102621000000000000000000000232102321000000000002321023210242102421026210262102921029210
010900002441024410244102441024410244102441024410244102441024410244100000000000000000000026410264102641026410264102641026410264102641026410264102641000000000000000000000
010900000c0100c0100c0100c0150c0100c0100c0100c0100d0100d0100e0100e0100f0100f0100c0100c01001010010100101001010030100301003010030100501005010050100501007010070100701007010
0109000000000000000000000000272102721000000000002721027210292102921000000292102b2102b21000000000000000000000222102221000000000002e2102e2102e2102e2102c2102c2100000000000
0109000029410294102941029410294102941029410294102941029410264102641000000000002b4102b4102b4102b4102b4102b4102b4102b4102b4102b4100000000000000000000000000000000000000000
010900002b2102b2102b2102b2102c2102c2102b2102b210000000000027210272100000000000242102421027210272100000000000000000000027210272102621026210272102721029210292103021030210
010900002441024410244102441024410244102441024410244102441024410244102441024410244102441522410224102241022410224102241524410244102441024410274102741027410274102741027410
01090000000000000000000000002e2102e21000000000002e2102e2102b2102b21000000000002e2103221033210332103321033210332103321033210332100000000000272102721029210292100000000000
010900001f4101f4101f4101f4101f41000000244102441024410000001f4101f4101f4101f4101f4101f41027410274102741027410274100000027410274102741000000244102441024410244102441024415
01090000050100501005010050100801008010080100801508010080100801008010090100901009010090100a0100a0100a0100a0150a0100a0100a0100a0150a0100a0100a0100a0100c0100c0100e0100e010
010900002c2102c21000000000002b2102b2100000000000272102721000000000002421024210000000000027210272100000000000262102621000000000002621026210272102721029210292102921029215
010900002241022410000000000026410264100000000000274102741000000000002441024410000000000022410224102241022410224102241022410224102241022410224102241022410224102241022410
010900000f0100f0100f0100f0101b0101b0101b0101b0100f0100f01013010130101601016010140101401013010130101301013015130101301013010130100f0100f0100f0100f0150f0100f0100f0100f010
010900002921029210292102921027210272102721027210272102721027210272100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002441024410244102441024410244102441024410244102441024410244100000000000000000000022410224102241022410224102241022410224102041020410204102041020410204102041020410
010900000801008010080100801508010080100000000000000000000008010080100a0100a0100c0100c01007010070100701007015070100701007010070100801008010080100801015010150101601016010
010900001b3101b310000000000000000000000000000000000000000018310183101a3101a3101b3101b3101a3101a3101a3101a310173101731000000000001d3101d3101d3101d3101b3101b3101b3101b310
01090000184101841018410184100000000000000000000000000000001841018410000000000000000000001a4101a4100000000000000000000000000000001d4101d410000000000000000000000000000000
01090000180101801000000000000c0100c0100c0100c010000000000000000000000c0100c0100f0100f0100a0100a0100a0100a0150a0100a0100a0100a0100f0100f010000100000011010110101201012010
010900000000000000000000000000000000000000000000000000000018310183101a3101a3101b3101b3101d3101d3101b3101b3101d3101d3101f3101f3102031020310213102131022310223102331023310
010900001b4101b4101b4101b4100000000000000000000000000000001f4101f410000000000000000000001b4101b4100000000000000000000000000000002041020410000000000000000000000000000000
010900001401014010000000000008010080100801008010000000000014010140101301013010110101101007010070100701007015070100701007010070100b0100b0100b0100b0100e0100e0100e0100e010
0109000024310243100000020310223102231020310203101f3101f31020310203101f3101f3101d3101d3101f3101f31017310173101a3101a3101b3101b3101d3101d31020310203101f3101f3101d3101d310
010900001f4101f4101f4101f41000000000000000000000000000000000000000001b4101b4101b4101b4101b4101b4100000000000000000000000000000002041020410000000000000000000000000000000
010900000c0100c0100c0100c0150c0100c0100c0100c010000000000000000000000c0100c0100f0100f0100d0100d0100d0100d0150d0100d0100d0100d0100f0100f0100f0100f01011010110101301013010
010900001f3101f31018310183101a3101a3101b3101b31000000000001a3101a3101b3101b3101d3101d3101f3101f3102031020310223102231024310243102731027310253102531024310243102231022310
010900001f4101f41000000000000000000000000000000000000000000000000000000000000000000000001b4101b4100000000000000000000000000000002041020410000000000000000000000000000000
010900001401014010140101401514010140101401014015140101401014010140101301013010140101401016010160101601016015160101601016010160151601016010160101601516010160101301013015
0109000024310243101f3101f3102031020310223102231024310243102731027310263102631025310253102631026310243102431022310223101f3101f3101d3101d3101f3101f31022310223102031020310
010900001f4101f4101f4101f4100000000000000000000000000000000000000000000000000000000000001d4101d4101d4101d410000000000000000000000000000000000000000000000000000000000000
01090000130101301013010130151301013010130101301513010130101301013015130101301016010160101801018010180101801518010180101601016010130101301000000000000c0100c0100000000000
01090000223102231022310223101f3101f310223102231022310223101f3101f310223102231026310263102431024310263102631024310243101f3101f31020310203101f3101f3101b3101b3101d3101d310
010900001d4101d4101d4101d4100000000000000000000000000000000000000000000000000000000000001d4101d4101d4101d410000000000000000000000000000000000000000000000000000000000000
01090000110101101011010110151101011010110101101511010110101101011015110101101011010110100b0100b0100b0100b0150b0100b0100b0100b0100a0100a0100a0100a0150a0100a0100a0100a010
010900001f3101f31020310203101d3101d31018310183101b3101b310183101831000000000001f3101f3101a3101a3101a3101a310173101731017310173101a3101a3101f3101f3101f3101f3101f3101f310
010900001b4101b4101b4101b4100000000000000000000000000000000000000000000000000000000000001f4101f4101f4101f410000000000000000000000000000000000000000000000000000000000000
010900000f0100f01000000000000f0100f010120101201013010130100000000000130101301011010110100d0100d01000000000000d0100d01011010110100f0100f0100f0100f0100d0100d0100d0100d010
010900001b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b3101b310000000000000000000000000000000000000000000000000000000000000
010900001b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b4101b410
01150000140001400014000090100901509015090100401006010090100601009010090150901509010040100601009010060100901009010090150901008010090150901008010090100b0150b0150b0150b015
011500001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001b4001640016400164002d1102d1152d1152d1152d1152d1152d1152d1102f1152f110311102f1102f115
0115000000000000001a00026210262152621025215252152521026215262152621026215262102521525210262102521023210212152121019000252102c10023210252102b1002321029100291002521029100
01150000130001300021000213102131521315213152131521315213152131521310213152131521315213101e3101c3101a310193151931018300213101f3002031021310183002031018300183002131018000
011500000b0150b0100d0100e0100e0150e0150e0150e0150e0100d0100b01009010090150901509015090101501013010100100901009010090150901008010090150901008010090100b0150b0150b0150b015
011500002f11031110321103211532115321153211532110311102f1102d1102d1102d1102d1102d1102d1102d1102d1102d1102d1152d1152d1152d1152d1152d1152d1102f1152f110311102f1102f1152f110
01150000232102521018400232101840018400212101840021210202101e2101c2101840028215282152821026210252102321021215212101640025210164002321025210164002321016400164002521016400
0115000020310213102e1002031000000000001e3102e1051e3101c3101a31019310193002131521315213101e3101c3101a31019315193102c100213102c10020310213102b1002031029100291002131029100
011500000b0150b0100d0100e0100e0150e0150e0150e0150e0100d0100b010090100901509015090150901015010130101001018005180001800018000180001600016000160001600516000160001600016010
0115000031110321103211532115321153211532110311102f1102d1102d1102d1102d1102d1102d1102d1102d110331003310033100331003310033100331003310033100331003310000000000000000000000
0115000023210252101d20023210212001d200212101d20021210202101e2101c2101d20028215282152821526210252102321018400184001840018400184001840018400184001840018400184001840018400
01150100203102131000000203102c1002c1001e310000001e3101c3101a31019310003002131521315213101e3101c3101a3102710027100271002710027100000000000000000000002b1002b1002b1002b100
010100002471024000240102400011000110001100011000110001100011000110001100011000110001100014000140001400014000140001400014000140001400014000140001400014000140001400024000
010900001807017050150501305011050100500e0500c0501800017000150001300011000100000e0000c0001d4001d4001d4001d4001d4001d4001d4001d4001d4001d4001d4001d4001d4001d4001d4001d400
01010000076700a6700e670126700c660076600266010660166500e6500b65015650126400a040096400f640116401363011630156300f630126301463011620066200d620126201362010610056100f61010610
01090000180001800018000180001b0001b0001b0001b000000000000000000000001100011000140001500016000160000000000000140001400013000130000f0000f0000f0000f0000c0000c0000c0000c000
__music__
01 00014344
00 02020304
00 05050607
00 0808090a
00 0b0b0c0d
00 02020e0f
00 05051011
00 12121314
00 15151617
00 1818191a
00 1b1b1c1d
00 1e1e1f20
00 21212223
00 24242526
00 27272829
00 2a2a2b2c
00 2d2d2e2f
00 30313233
00 34343536
02 3738393a
00 78787479
00 70707177
00 73737a7b
00 7c7c7d7e
00 7f7f4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

