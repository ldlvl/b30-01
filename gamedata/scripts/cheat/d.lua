if _G.d == nil then
 _G.d = {}
end

local saved_pos_list = {}
local pos_list_file = '$mod_dir$/nlc6/poslist.ini'

lamp_id = 0

pos2str = misc.pos2str

function d_regular() 
 if ( lamp_id > 0 ) and ( client_obj(lamp_id) ~= nil ) then
   lightman.set_lamp_prop(lamp_id, 'light_range', 150)
   lamp_id = 0
 end
end

function d.init_module()
 AddRegularTask("d_regular", d_regular, nil, 0, 20)
end

d.tele_object = linker.tele_object

function tele_multi(id,...)
 ODS("[~T]. #DBG(tele_multi) id first = "..id) 
 tele_object(id)
 local args = {...}
 for k,a in ipairs(args) do
   linker.tele_object (a)     
 end
end


function paddr(obj_id)
 local obj = nil
 local srv_obj = nil
 if obj_id == nil then
  obj = db.actor
 else
  obj_id = tonumber(obj_id)
  obj = client_obj(obj_id)
  srv_obj = alife():object(obj_id)
 end
 
 if obj ~= nil then 
   ODS("[~T/~L].~C0F #DBG: online object ptr = ~C0D"..FormatPtr(obj).."~C07")   
   ODS("         ~C0F #DBG: server object ptr = ~C0D"..FormatPtr(srv_obj).."~C07")
   
   
   if obj.money ~= nil then
     ODS("    #DBG: object.money func = ~C0D"..FormatPtr(obj.money).."~C07, call result = ~C0D"..obj:money().."~C07" )
   end
   if obj.give_money ~= nil then
     ODS("    #DBG: trying to give_money 100k")
     obj:give_money(100000)
   end
   if obj.id ~= nil then
     ODS("    #DBG: object id = ~C0D"..obj:id().."~C07")      
   end
 end
end


function logmsg(msg)
 if ODS ~= nil then
    ODS(tostring(msg))
 end
end

function logpos(msg, p)

 if type(p) == "string" then 
  local v = vector()
  
  if p == "actor" then
     v = db.actor:position()
  end

  logmsg(msg..pos2str(v))
 else
  logmsg("!~C0C#ERROR: param2 is not string!~C07") 
 end 
end

function d.flyto(x, y, z)

 local v = vector()
 local d = 0
 
 v.x = tonumber(x)
 v.y = tonumber(y)
 v.z = tonumber(z)
 
 db.actor:set_actor_position(v)
end

function svpos(marker)
 local v = vector()
 local p = vector()
 local a = db.actor
 local prefix = ""
 
 if xr_build_id > 5700 then
    prefix = db.actor.level_name .. ":"
 end
 
 if marker == nil then 
    marker = "default"
 end

 marker = prefix .. marker
 
 p:set( a:position() )
 WriteIni( pos_list_file, marker, 'X', string.format('%.3f', p.x) )
 WriteIni( pos_list_file, marker, 'Y', string.format('%.3f', p.y) )
 WriteIni( pos_list_file, marker, 'Z', string.format('%.3f', p.z) )
 WriteIni( pos_list_file, marker, 'gvid', tostring (a:game_vertex_id()) )
 WriteIni( pos_list_file, marker, 'lvid', tostring (a:level_vertex_id()) )

 v:set( db.actor:direction() )
 -- db.actor:get_current_direction()
 local alpha = v:getH()

 WriteIni( pos_list_file, marker, 'DIR', string.format('%.3f', alpha) )                                      
 
 
 wprintf("[~T]. #DBG: Position ~C0A%s~C0B %s~C07 saved - OK, DIR:~C0F %s~C07 getH: %.5f ", marker, pos2str(p), pos2str(v), alpha )
 
end

d.svpos = svpos

function readpos(marker)
 local v = vector()
 v:set(db.actor:position())
 v.x = tonumber ( ReadIni ( pos_list_file, marker, 'X', v.x ) )
 v.y = tonumber ( ReadIni ( pos_list_file, marker, 'Y', v.y ) )
 v.z = tonumber ( ReadIni ( pos_list_file, marker, 'Z', v.z ) )
 local gv = tonumber ( ReadIni ( pos_list_file, marker, 'gvid' ) )
 local lv = tonumber ( ReadIni ( pos_list_file, marker, 'lvid' ) ) 
 
 wprintf(" readpos~C0F %s~C07: gv =~C0D %s~C07, lv =~C0D %s~C07", marker, DumpVar(gv), DumpVar(lv)) 
 return v, gv, lv
end
-- flush !c.spawn_multi yan_zombied_respawn_3 10 
d.readpos = readpos

function rspos(marker, vadd)
 local v = vector()
 local dir
 
 if marker == nil then
    marker = 'default'
 end
 
 local prefix = ""
 
 if xr_build_id > 5700 then
    prefix = db.actor.level_name .. ":"
 end
 
 local p_marker = prefix .. marker
 dir = ReadIni ( pos_list_file, p_marker, 'DIR' )
 if dir ~= nil and #dir > 0 then
    marker = p_marker
 else
    dir = ReadIni ( pos_list_file, marker, 'DIR' ) 
 end  
 
 
 if vadd == nil then
    vadd = 0
 end
 
 vadd = tonumber (vadd)

 v = readpos(marker) 
 v.y = v.y + vadd
 
 
  
 if (v.x ~= 0) and (v.z ~= 0) and (dir ~= nil) and (#dir > 0) then
    dir = tonumber ( dir )  
    db.actor:set_actor_position(v)    
    ODS (" restoring dir = "..dir)
    db.actor:set_actor_direction(-dir)
 else
    wprintf(" marker~C0A %s~C07 not found in~C0F %s~C07", marker, pos_list_file)    
 end 

 get_console():hide()
end

function mvnpc(id, marker, vadd)
 local obj
 local v = vector()
 local dir

 obj = client_obj( tonumber(id) )
 
 if obj == nil then
    ODS ("!~C0C[~T]. #ERROR: client_obj returned nil for "..tostring(id).."~C07" );
    return
 end
 
 if (obj.set_actor_position == nil) then
    ODS("!~C0C[~T]. #ERROR: object not have method set_npc_position ~C07")
    return
 end

 if marker == nil then
    marker = 'default'
 end

 if vadd == nil then
    vadd = 0
 end

 vadd = tonumber (vadd)

 v = readpos(marker)
 v.y = v.y + vadd
 

 dir = tonumber ( ReadIni ( pos_list_file, marker, 'DIR' ) )

 if (v.x ~= 0) and (v.z ~= 0) then
    if obj.profile_name ~= nil then
       ODS("[~T]. #DBG: trying teleport ~C0A"..obj:profile_name().."~C07 to position ~C0F"..pos2str(v).."~C07")
    end

    obj:set_actor_position(v)
    obj:set_actor_direction(-dir)
 end

end

function goto_objs(id, vadd)   -- прыгнуть к серверному объекту
 local obj
 local pos
 
 if vadd == nil then
    vadd = 0.3
 end
 vadd = tonumber(vadd)

 obj = alife():object( id )

 if obj and obj.position then
    pos = obj.position
    pos.y = pos.y + vadd -- jump to head
    db.actor:set_actor_position(pos)
 end

end

function goto_objc(id, vadd)    -- прыгнуть к клиентскому объекту
 local obj
 local pos = vector()
 obj = client_obj ( tonumber(id) )
 if obj == nil then
    wprintf("~C0C #WARN(goto_objc):~C07 no client object on level with id #%s ", id) 
    return
 end                             
 
 if vadd == nil then
    vadd = 0.3
 end
 vadd = tonumber(vadd)

 if obj.position ~= nil then
    pos = obj:position()
    pos.y = pos.y + vadd -- jump to head
    db.actor:set_actor_position(pos)
 end
end

function callnpc(npc_id)

   local position = db.actor:position()        -- позиция актора в координатах уровня
   local dir = db.actor:direction()        -- куда смотрит актор сейчас
   
   -- дистанцирование на 2 метра вперед относительно актора
   position.x = position.x + dir.x * 2
   position.z = position.z + dir.z * 2

   npc_id = tonumber (npc_id)
   
   local cl_object = client_obj(npc_id)

  if cl_object then
    -- xr_effects.reset_animation(cl_object)
     if cl_object.set_npc_position then
        ODS("[~T]. #DBG: trying set_npc_position... ")
       cl_object:set_npc_position(position)
    else
         ODS("[~T]. #DBG: trying set_desired_position... ")
         utils.send_to_nearest_accessible_vertex(cl_object, cl_object:level_vertex_id())
         cl_object:set_movement_type(move.run)
         cl_object:set_body_state(move.standing)
         cl_object:set_desired_position(position)

    end
    cl_object:set_position(position)
  else
    local obj = alife():object(npc_id)
      if obj and obj.position ~= nil then
         ODS("[~T]. #DBG: trying assign obj.position... ")
         obj.position = position
         obj.m_game_vertex_id = db.actor:game_vertex_id()
         obj.m_level_vertex_id = db.actor:level_vertex_id()
      end
  end
end
function getid(story_id)
 local s, id
 id = get_story_object_id (story_id)
 
 id = tostring(id)
 
 s = "game id for ~C0A"..story_id.."~C07 = ~C0D"
 s = s..id.."~C07"
 ODS (s)
end
if _G.d.rspos ~= nil then
   wprintf(" cheat-module 'd' registered ")
end--

