wprintf(" script_name =~C0A %s~C07, _G.c =~C0F %s~C07", script_name(), type(_G.c))

if _G.c == nil then
   _G.c = {} 
end
_G.BAD_OBJ_ID = 65535
c.spawn_test = false
c.spawn_item = "explosive_barrel"
c.last_pos = vector()
c.last_vid = 0
                                                                
function front_cam (dist)
 local a = vector() 
 local apos = device().cam_pos
 local dir = device().cam_dir
  
 a.y = apos.y + 1.3
 if dist then
    dist = tonumber(dist)
 else
    dist = 2
 end
 
 -- дистанцирование на 3 метра вперед относительно каморы
 a.x = apos.x + dir.x * dist
 a.z = apos.z + dir.z * dist
 
 return a

end
c.front_cam = front_cam
------------------------------------------------------------------------------------------------------------------------------------------------------------
function spawn_at (obj_name, parent, v, force)
 local obj, xobj, n
 local lvid, gvid
 local exist = -1

 -- проверка уровня
 if not level.present() then
   return 0
 end
 if not v then
   wprintf ("[~T].~C0C #ERROR(spawn_at): position argument not set")
   return
 end
 
 -- exist = CheckInList("$game_data$/nlc6/entities.ltx", "%all", "%all", obj_name)
 local ini = system_ini()
 if ini:section_exist(obj_name) then 
    exist = 1
 end 

 if (not force) and (exist < 0) then
  ODS("[~T].~C0C #ERROR(spawn_at): Section ~C0A "..obj_name.."~C0C isn't found. ~C07");
  return 0
 end;
 
 if parent == nil then
    parent = BAD_OBJ_ID
 end
  
 parent = tonumber(parent)
 
 if (parent == 1) then
   abort("trying spawn into object 1")
 end
  
 
 lvid  = db.actor:level_vertex_id()
 gvid  = db.actor:game_vertex_id()
 if type(v) == "string" then -- используется маркер
  local pos, gv, lv
  pos, gv, lv = d.readpos(v)
  if gv and lv then else
     wprintf("~C0C #ERROR~C07: invalid position marker~C0A %s~C07", v)
     return
  end
  v = pos
  gvid = gv
  lvid = lv
 elseif type(v) == "userdata" and v.x then
  local tvid = 0
  lvid, gvid, tvid = misc.nearest_vertex_info(v)
 end

 obj = g_sim:create(obj_name, v, lvid, gvid, parent)
 if obj ~= nil then
  ODS(string.format("[~T]. #DBG: Spawned object at lvid = %d, gvid = %d, id =~C0D %d~C07",  lvid, gvid, obj.id))
  xobj = client_obj(obj.id)
  
  if xobj and (xobj.can_switch_online ~= nil) and ( xobj:can_switch_online() ) then
    ODS ( " trying to switch online...")
    switch_online ( tonumber(obj.id), true )
  end
  
  return obj.id
 end
 
 return 0
end
c.spawn_at = spawn_at
------------------------------------------------------------------------------------------------------------------------------------------------------------

function spawn_obj (obj_name, parent, force, dist)  
 local a = c.front_cam(dist)
 return c.spawn_at (obj_name, parent, a, force)
end -- spawn_obj
c.spawn_obj = spawn_obj
spawn_obj("myaso")

------------------------------------------------------------------------------------------------------------------------------------------------------------
function spawn_heli ()
 local pos = front_cam(dist)
 local lvid  = db.actor:level_vertex_id()
 local gvid = db.actor:game_vertex_id()  
 local sobj = alife():create("helicopter", pos, lvid, gvid)
 if sobj == nil then
    return 
 end
 
 local id = sobj.id
 
 ODS( string.format("[~T]. #DBG: spawned helicopter id = %d ", id))
 amk_mod.spawn_military_tech_pack(sobj, "helicopter", 1)  
end
c.spawn_heli = spawn_heli

function spawn_lamp()
 local id = spawn_obj('lights_hanging_lamp')
 schedule.add('link_lamp', sprintf('linker.link_obj(%d, 0.3)', id), 500)
 d.lamp_id = id  
end

c.spawn_lamp = spawn_lamp
------------------------------------------------------------------------------------------------------------------------------------------------------------
function  obj_dist_2d (aobj, bobj)
  return heli_func.distance_2d( aobj:position(), bobj:position() )
end
c.obj_dist_2d = obj_dist_2d
------------------------------------------------------------------------------------------------------------------------------------------------------------

function do_test()
 if not spawn_test then return end
 local pos = db.actor:position()
 local dist = pos:distance_to_xz(last_pos)
 local lvid = db.actor:level_vertex_id()

 if (dist > 100) or (last_vid == 0) then
    last_vid = lvid
    last_pos:set(pos)
    return
 end

 if last_vid ~= lvid  then
    spawn_at(spawn_item, BAD_OBJ_ID, last_pos)
    last_pos:set(pos)
    last_vid = lvid
 end
end -- do_test
------------------------------------------------------------------------------------------------------------------------------------------------------------

function spawn_ds()

end
------------------------------------------------------------------------------------------------------------------------------------------------------------
function run_test(item)
  if item ~= nil then spawn_item = item end
  spawn_test = true
end
function stop_test() spawn_test = false end
------------------------------------------------------------------------------------------------------------------------------------------------------------
function spawn_fire()
 spawn_obj("zone_flame_candle_self")
 registry.update_reg()
end
c.spawn_fire = spawn_fire
------------------------------------------------------------------------------------------------------------------------------------------------------------
function sr()
 spawn_obj("rykzack_feik", 0)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function spawn_at_pos (obj_name, marker, add)
 local v = vector()
 
 v = d.readpos(marker)  
 if add ~= nil then
   v.y = v.y + tonumber(add)
 end
 
 if v ~= nil then
    spawn_at(obj_name, nil, v)
 end     
end
c.spawn_at_pos = spawn_at_pos 
------------------------------------------------------------------------------------------------------------------------------------------------------------

function c.spawn_eat(parent)
 spawn_obj("kolbasa", parent)
 spawn_obj("conserva", parent)
 spawn_obj("bread", parent)
 spawn_obj("vodka", parent)
 spawn_obj("antirad", parent)
 spawn_obj("energy_drink", parent)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------
function c.spawn_multi(obj_name, count, parent)
 count = tonumber(count)
 if count <= 1 then 
    count = 2
 end   
 
 if count > 100 then
    count = 100
 end
 
 for i=1,count do
   spawn_obj(obj_name,parent)
 end 
end
c.spawn_multi = spawn_multi 
------------------------------------------------------------------------------------------------------------------------------------------------------------
if _G.c.spawn_obj ~= nil then
   wprintf(" cheat-module 'c' registered ")
end

--- ISUBM3Q
-- flush !c.spawn_multi ammo_5.56x45_ap 3 0

function sp( obj_name, count, parent )
  spawn_multi( obj_name, count, parent )
end
c.sp = sp