if _G.f == nil then
   _G.f = {}
end

function fly2cam()
 local pos = device().cam_pos
 local dir = device().cam_dir
 db.actor:set_actor_position(pos)
 db.actor:set_actor_direction(-dir:getH())
--sleep_manager.slip_hits()
end

f.fly2cam = fly2cam
d.fly2cam = fly2cam

function halt()
 ExitProcess("Halt!", 222)
end

function damage_npc(id, hp, src)
 id = tonumber(id)
 hp = tonumber(hp)

 if (hp == nil) or (hp <= 0) then
    hp = 0.5
 end

 local tmp = client_obj(id)

 if src == nil then
   src = tmp
 end
  

 if tmp and tmp.hit then
    wprintf(" hit with power %d, sending to object %d %s ", hp, id, tmp:name())
  local h = hit()
  h.draftsman = src
  h.type = hit.wound
  h.direction = vector():set(0, 0, 0)
  h.power = hp
  h.impulse = 1
    tmp:hit(h)

    if (hp > 200) and (tmp.kill ~= nil) then
      tmp:kill(src)
    end

 end
end

f.damage_npc = damage_npc

function hit_self(pwr)

 if pwr == nil then
    pwr = 0.11
 end
 local h = hit()
 h.draftsman = db.actor
 h.type = hit.strike
 h.direction = vector():set(0, 0, 0)
 h.power = tonumber (pwr)
 h.impulse = 1
 db.actor:hit(h)
end

                        
local mobs_group = {}
for i, cname in ipairs (class_info.mobs_classes) do
 local clid = clsid[cname]
 mobs_group [clid] = true
end                    

function is_mob(obj)
 local clid = obj:clsid()
 return mobs_group[clid]     
end

function is_live(obj)
 if is_mob(obj) and obj:alive() then
    return true
 else
    return false             
 end
end

f.is_mob = is_mob
f.is_live = is_live

function f.ecb(p1, obj, enemy)
 local near=obj:position():distance_to(enemy:position())< 50
 if not near then
  obj:enable_memory_object(enemy,false)
 end
 
 wprintf(" %s check enemy %s ", obj:name(), enemy:name())
 
 if obj:clsid() ~= CLID_TUSHKANO then
    return false
 end
 if near then
    wprintf(" %s see enemy %s ", obj:name(), enemy:name())
 end
 
 return near
end

function modified()
 ODS("22.12.2014")
end


function show_around(radius, comflt, nameflt, action)

 local apos
 local tmp
 local ncom
 local profname
 local com_pass
 local last_flt = ""
 local count_all = 0
 local show_all = false
 local show_item = false
 
 class_info.update_class_map()
 
 apos = db.actor:position()        -- позици€ актора в координатах уровн€

 -- ODS(string.format("-[~T]. #DBG: show_around radius = %s, community filter = %s", tostring(radius), tostring(comflt)))

 if comflt == nil then
    comflt = "" -- any alive
 end
 comflt = tostring(comflt)
 
 if nameflt == nil then
    nameflt = ""
 end
 

 if strpos(comflt, "all" ) then show_all = true end
 if ( comflt == "item" ) or ( comflt == "respawn" ) or ( comflt == "anomaly" ) or ( comflt == "weapon" ) then show_item = true end

 if (radius == nil) then radius = 7 end

 radius = tonumber (radius)
 -- local ids = registry.all_objects(true, 7) -- online only
 -- local cnt = table.getn(ids)
 local ci = 0
 -- ODS("[~T]. #DBG: summary object cnt = "..tostring(cnt))
 
 ElapsedTime(10)

 for i = 0,65534 do
    -- i = ids[n]
  tmp = client_obj(i)

  ncom = "monster"
  profname = "#noname#"
    if ElapsedTime(-10) > 10000 then
       wprintf("[~T]. #PERF: object dump timeout - breaking...")
       break
    end
         

  if tmp and
     (show_all or show_item or is_live(tmp)) and
        (tmp.position ~= nil) and (apos:distance_to_xz (tmp:position()) < radius)  then
     
      local npos = tmp:position()
      local spos = "?"
      local nnm = tmp:name()
      local owner_id = "none"

      if (npos.x) then spos = misc.pos2str(npos) end

      if tmp.parent then
         local p = tmp:parent()
         if p and p.name then
            owner_id = p:name()
         else
            owner_id = "no_parent"
         end
      end

      if tmp.profile_name ~= nil then  profname = " ("..tostring (tmp:profile_name())..")"  end

      ncom = misc.get_com(tmp, nnm)
      if ncom == nil then ncom = "monster" end

      comm_pass = true

      ci = 0
      if tmp.clsid then
         ci = tmp:clsid()
      end
      
      local cs = tostring ( _G.class_map[ci] or 'unknown'..tostring(ci) )

      if (ncom ~= nil) and (comflt ~= nil) and (#comflt > 1) and 
               ( strpos (ncom, comflt) == nil ) and 
               ( strpos (cs,   comflt) == nil ) then
         comm_pass = show_all         
         last_flt = sprintf("community: %s vs %s | %s", ncom, comflt, cs)
      end

      local hlth = -1
      local gw = 1
      if is_live(tmp) then
         hlth = tmp.health
         gw = tmp:goodwill(db.actor)
      end   
      
      if (hlth < 0) and (tmp.condition) then
          htlh = tmp:condition()
      end
      
      
      if tmp:is_eatable_item() and ( nameflt == "eatable" ) then
        comm_pass = true    
      elseif ( comflt == "item" ) then
        comm_pass = tmp:is_inventory_item()   
      end
      
      if (nameflt ~= "") and ( not strpos(nnm, nameflt) ) then 
        comm_pass = false
        last_flt = "by name"
      end
      

      if comm_pass then
         count_all = count_all + 1
         
         local cobj = get_CObject(i)
         local addr = FormatPtr ( cobj )
         
         if ( ( hlth < 0 ) or (hlth > 1e5) ) and ( cobj ~= nil ) then
            -- hlth = ReadDMA (cobj, -48, 'float')
         end 
         
         if ( hlth == nil ) or ( hlth < -1 ) or ( hlth > 10 ) then 
              hlth = 0
         end
                  
                  
         local s = string.format("~C0B obj~C0D #%5d~C0F is ~C0A %25s %11s~C0F, class =~C0E %-25s~C0F, clsid = %5d, com =~C0A %s~C0F, CObject* = %s \n    hlth/condition =~CD0 %.7f ~C0F ", i, nnm, profname, cs, ci, ncom, addr, hlth )
         s = s .. string.format(" section =~C0A %-25s~C07, goodwill =~C0D %d~C07", tmp:section(), gw)
         wprintf ( "%s pos =~C0A %s~C07, owner = ~C0D#%s~C07, sid =~C0D #%d~C07", s, spos, owner_id, tmp:story_id() )
           
         if action then         
            if action == "kill" then
               damage_npc(i, 300)            
            end -- if kill
            if ( action == "enemy" ) and (gw < 0) then
               damage_npc(i, 300)
            end
            
            if ( action == "relax" ) and (gw <= 0) then
               tmp:change_goodwill(5500, db.actor)
            end
            
            if action == "catch" then
               local holder = tmp:parent()
               if holder == nil then holder = tmp end
               local ii = tmp:get_inventory_item() 
               if ii and holder:id() > 0 then
                  holder:transfer_item(tmp, db.actor)
               else 
                  wprintf(" item rejected, holder.id =~C0D %d~C07, inventory_item =~C0F %s~C07", holder:id(), DumpVar(ii))   
               end   
            end
            
            if action == "prize" then
               c.spawn_obj("wpn_gauss_auto", tmp:id())
               c.spawn_obj("ammo_gauss_oboima", tmp:id())
               c.spawn_obj("dolg_black_exoskeleton", tmp:id())
               c.spawn_obj("medkit_npc", tmp:id())
               c.spawn_obj("bandage", tmp:id())
               c.spawn_obj("yad", tmp:id())
            end
                     
            if action == "remove" and owner_id ~= db.actor:id() then
               misc.release_obj(i)
            end

            if action == "stlk" then
               amk.set_npc_community(tmp, "stalker")
            end
            
            if action == "frdm" then
               amk.set_npc_community(tmp, "freedom")
            end

            if action == "invalidate" then
               local e = tmp:get_interface()
               if e and e.condition then
                  damage_npc(i, e.condition.health - 0.001)
                  e.condition.health = 0.00000001                  
               end
            end
            
            if action == "angry" and (tmp:clsid() == CLID_STALKER) then
               tmp:set_enemy_callback(f.ecb)
               wprintf(" assigned enemy callback to npc! ") 
            end

            if action == "offline" then
               misc.force_offline(tmp:id())
            end
            
            if action == "defeat" then 
               f.defeat(i)
            end
         end -- if action  
           
      end -- if comm_pass
  end -- if ...
 end -- for ...
 local stack = debug.traceback(1, '   ')
 if strpos(stack, "task") == nil then
    wprintf("[~T]. #DBG: show_around, found objects = %d, last_flt = %s, call from:\n %s", count_all, last_flt, stack)
 end   
end

f.show_around = show_around 

function kill_around(scom, npart, hp)

 local tmp
 local ncom, nnm
 local src = nil
 local name_pass

 if scom == "monster" or scom == "bandit" then
    src = db.actor
 end

 local objs = registry.online_objects(true, client_obj) 
 local count = table.getn(objs)
 if count > 0 then 
    wprintf("[~T]. #DBG: online objects in level~C0D %d~C07 ", count)
 else
    wprintf("[~T].~C0C #WTF:~C07 nothing in hell! Check registry for bugs?")
    return 
 end    
 

 for i, tmp in ipairs(objs)  do
  if tmp and is_live(tmp) then
   -------------------------------------------------------------------------
     ncom = "unknown"
      nnm = nil
      name_pass = true
      -- ODS (" checking npc ~C0D#"..i.."~C07")
      -- определение имени
      
      if tmp.profile_name ~= nil then
         nnm = tmp:profile_name()
      end
      
      if tmp.name ~= nil then
          nnm = tmp:name()
      end

      -- ODS (" name = "..nnm)
      
      if (nnm ~= nil) and (npart ~= nil) and ( string.find(nnm, npart) == nil ) then
         name_pass = false
      end
      
      -- определение группировки
      ncom = misc.get_com(tmp, nnm)
      -- ODS (" comm = "..tostring(ncom) )

      if ( ncom == scom ) and name_pass then
       ODS ( " kill npc #".. i .. ", name =~C0A "..nnm.."~C07 his community = "..ncom..",  health = "..string.format("%.3f", tmp.health)  )
         f.damage_npc(tmp:id(), hp or 155, src)
        else
         wprintf(" rejected npc %s ", nnm) 
      end
    -------------------------------------------------------------------------
   end -- if alive
 end -- for
end -- kill_around

f.kill_around = kill_around

function rich_grp(scom, item, npart)

 local tmp
 local ncom, nnm
 local src = nil
 local name_pass
 
 local npc_list = registry.stalkers(false, client_obj)
   
 local count = table.getn(npc_list)
 if count > 0 then 
    wprintf("[~T]. #DBG: online stalkers in level~C0D %d~C07 ", count)
 else
    wprintf("[~T].~C0C #WTF:~C07 nobody in hell! Check registry for bugs?")
    return 
 end    
 
 for i, tmp in ipairs(npc_list) do  
  if tmp and tmp:alive() then
   -------------------------------------------------------------------------
      ncom = "unknown"
      nnm = nil
     name_pass = true
      -- определение имени

      if tmp.profile_name ~= nil then
         nnm = tmp:profile_name()
      end

      if tmp.name ~= nil then
          nnm = tmp:name()
      end

      -- ODS (" name = "..nnm)

      if (nnm ~= nil) and (npart ~= nil) and ( string.find(nnm, npart) == nil ) then name_pass = false end
      
      ncom = misc.get_com(tmp, nnm) -- определение группировки
      if ( ncom == scom ) and name_pass then
         local id = tmp:id()
         wprintf("[~T]. #DBG: Ќаграждаетс€ непись нумер~C0D %d~C07", id)
         c.spawn_obj(item, id)
         tmp.health = 1
         tmp.power = 1
         tmp.bleeding = 1
         tmp.radiation = -1
      else
         wprintf(" rejected npc ~C0A %s~C07", nnm)   
      end
      
    -------------------------------------------------------------------------
   else
     wprintf(" rejected dead npc ~C0A %s~C07", tmp:name())
   end -- if alive
 end -- for
end -- rich_grp

f.rich_grp = rich_grp

function detach_item (item)
 ODS (" trying detach item ")
 if (item and item.parent_id) then
    ODS("  from parent #"..tostring(item.parent_id) )
    item.parent_id = BAD_OBJ_ID    
 end
end


function rich_npc(id, money)
 id = tonumber(id)
 money = tonumber(money)
 if money == 0 then
    money = 100000
 end
 
 local tmp = client_obj(id) 
 
  
 if tmp and tmp.is_live and IsStalker(tmp) then 
  tmp:give_money(money)
  -- c.spawn_obj ("wpn_fn4000", id)
  c.spawn_obj ("wpn_saiga12c", id)
  c.spawn_obj ("wpn_gauss_auto", id)
  c.spawn_obj ("wpn_eagle_m1", id)
  c.spawn_obj ("medkit_army", id)
  c.spawn_obj ("yad2", id)
  c.spawn_obj ("vodka", id)
  c.spawn_obj ("conserva", id)
  c.spawn_obj ("bandage", id)
  c.spawn_obj ("svoboda_yellow_exo_outfit_m1", id)  
 end

end

function curenpc(id)
  if id == nil then 
     id = 0
  else
     id = tonumber(id)
  end
    
  local tmp = client_obj( id )
  
  local a = db.actor 
  local r = a:character_reputation()
  
  if r < 0 then
     wprintf(" actor reputation = %.1f, will be improved.", r)
     a:change_character_reputation(2000)
  end   
  
  if tmp.health ~= nil then
     wprintf(" healing npc     ~C0A %s~C07", tmp:name())
     tmp.health = 1
     tmp.power = 1
     tmp.bleeding = 0
     tmp.radiation = -1     
  end
  
  if id == 0 then
     for i = 1,6 do
       local obj = tmp:item_in_slot(i)
       if obj and obj:section() == "stalker_outfit" then
       
       elseif obj and obj:condition() < 1 then
         wprintf(" repair object ~C0A %-25s~C07 ", obj:name())
         obj:set_condition(1)
       elseif obj then 
         wprintf(" item~C0A %-25s~C07 was not damaged", obj:name())
       else
         wprintf(" no item in slot~C0D %d~C07", i)             
       end 
     end
  end   
  
  
end
f.curenpc = curenpc

function help_npc(id)
  c.spawn_obj ("wpn_fn2000", id)
  c.spawn_obj ("military_outfit", id)
  c.spawn_obj ("detector_elite", id)
  c.spawn_obj ("medkit", id)
  curenpc(id)
end

function rob_item(id, from)

  local tmp = client_obj( tonumber(id) )
  local nnm = "obj #"..tostring (id)
  
  if from == nil then
     from = MAX_OBJ_ID
  else
     from = tonumber (from)   
  end
  

  if tmp and tmp.parent then
      local parent = tmp:parent()
      
      -- проверка наличи€ владельца, готового отдать предмет за просто так.      
      if parent and parent.id and parent.transfer_item then
      
         local parent_id = parent:id()


         if ( from == parent_id ) or ( from == MAX_OBJ_ID ) then
             
             if tmp.name then
                nnm = tmp:name()
             end
              
             if nnm ~= "bolt" then
                ODS ("[~T]. #DBG: trying rob item "..nnm)                
                parent:transfer_item(tmp, db.actor)
             end
             
        end -- if parent_id
      end -- if parent
  end -- if tmp 
 
end

function clean_inv(id)

 ODS("[~T]. #DBG: Cleaning inventory for npc/parent #"..id)

 id = tonumber(id)

 for i = 1,MAX_OBJ_ID do  
     rob_item (i, id)
 end
 
end
function rmvobj(id)
 misc.release_obj(tonumber(id))
end
function anom_off(id)
 if id ~= nil then
    ODS("[~T]. #DBG: Trying switch off anomaly #"..tostring(id))
    amk_anoms.set_online_anomaly_status(tonumber(id), "off")
 end
end

function f.defeat(id)
 id = tonumber(id)
 local obj = client_obj(id)
 if obj then
    local name = obj:name()
    if strpos(name, "zone_") and not is_live(obj) then
       SetDbgVar("disabling_anomaly", name)
       obj:disable_anomaly()
    end
 else
    wprintf("[~T]. #DBG: no client object for %d ", id)        
 end
 

 local se_obj = g_sim:object(id)
 if se_obj then
    g_sim:release(se_obj, false)
 else
    wprintf("[~T]. #DBG: no server object for %d ", id)    
 end

end

local sz_loop = 1

function f.safe_zone()
 local a = db.actor
 if a and ( a.health < 0.8 ) or ( a.radiation > 0.5 ) then    
 end 
 
 a.satiety = 1
 -- a.health = 1
 -- a.conditions.satiety = 1
 sz_loop = sz_loop + 1 
 if sz_loop % 10 == 2 then
    show_around(3, "monster", "_", "kill")
 end   
 -- kill_around("monster")
 -- kill_around("zombied") 
end

function init_module()
 ---
end

function late_init()
 -- AddRegularTask("safe_zone", "f", nil, 0, 500)  
end
 
if AddRegularTask then 
   -- late_init()
end 
 
if _G.f.show_around ~= nil then
   wprintf(" cheat-module 'f' registered ")
end
--