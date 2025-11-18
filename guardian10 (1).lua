--@hybernation
--@@@@
--@#ten ten fifty five// / 

local clipboard = require("gamesense/clipboard")
local pui = require("gamesense/pui")
local base64 = require("gamesense/base64")
local weapons = require("gamesense/csgo_weapons")
local inspect = require ("gamesense/inspect")
local vector = require ("vector")
local ffi = require("ffi")
local http = require("gamesense/http")

local infos = {
    username = panorama.open().MyPersonaAPI.GetName(),
    build = "Alpha"
}

local groups = {
    angles = pui.group("AA", "Anti-aimbot angles"),
    fakelag = pui.group("AA", "Fake lag"),
    other = pui.group("AA", "Other")
}

local refs = {
    aa = {
        angles = {
            enable = pui.reference("AA", "Anti-Aimbot angles", "Enabled"),
            pitch = { pui.reference("AA", "Anti-Aimbot angles", "Pitch") },
            yaw = { pui.reference("AA", "Anti-Aimbot angles", "Yaw") },
            base = pui.reference("AA", "Anti-Aimbot angles", "Yaw base"),
            jitter = { pui.reference("AA", "Anti-Aimbot angles", "Yaw jitter") },
            body = { pui.reference("AA", "Anti-Aimbot angles", "Body yaw") },
            edge = pui.reference("AA", "Anti-Aimbot angles", "Edge yaw"),
            fs_body = pui.reference("AA", "Anti-Aimbot angles", "Freestanding body yaw"),
            freestand = pui.reference("AA", "Anti-Aimbot angles", "Freestanding"),
            roll = pui.reference("AA", "Anti-Aimbot angles", "Roll"),
        },
        fakelag = {
            enable = pui.reference("AA", "Fake lag", "Enabled"),
            amount = pui.reference("AA", "Fake lag", "Amount"),
            variance = pui.reference("AA", "Fake lag", "Variance"),
            limit = pui.reference("AA", "Fake lag", "Limit"),

        },
        aimbot = {
            dt = { pui.reference("Rage", "Aimbot", "Double tap") },
            dt_fakelag = pui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
            rage_enable = { pui.reference("RAGE", "Aimbot", "Enabled") },
            fakeduck = pui.reference("RAGE", "Other", "Duck peek assist"),
            prefersafe = pui.reference('RAGE', 'Aimbot', 'Prefer safe point'),
            forcesafe = pui.reference('RAGE', 'Aimbot', 'Force safe point')
        },
        other = {
            slowmo = pui.reference("AA", "Other", "Slow motion"),
            legs = pui.reference("AA", "Other", "Leg movement"),
            hs = pui.reference("AA", "Other", "On shot anti-aim"),
            fp = pui.reference("AA", "Other", "Fake peek"),
        }
    }
}

local launch_count = 0

local function hide_refs(val)
    refs.aa.angles.enable:set_visible(false)
    refs.aa.angles.pitch[1]:set_visible(false)
    refs.aa.angles.pitch[2]:set_visible(false)
    refs.aa.angles.yaw[1]:set_visible(false)
    refs.aa.angles.yaw[2]:set_visible(false)
    refs.aa.angles.base:set_visible(false)
    refs.aa.angles.freestand:set_visible(false)
    refs.aa.angles.jitter[1]:set_visible(false)
    refs.aa.angles.jitter[2]:set_visible(false)
    refs.aa.angles.body[1]:set_visible(false)
    refs.aa.angles.body[2]:set_visible(false)
    refs.aa.angles.edge:set_visible(false)
    refs.aa.angles.fs_body:set_visible(false)
    refs.aa.angles.freestand.hotkey:set_visible(false)
    refs.aa.angles.roll:set_visible(false)
    refs.aa.fakelag.enable:set_visible(false)
    refs.aa.fakelag.enable.hotkey:set_visible(false)
    refs.aa.fakelag.limit:set_visible(false)
    refs.aa.fakelag.amount:set_visible(false)
    refs.aa.fakelag.variance:set_visible(false)
    refs.aa.other.hs:set_visible(false)
    refs.aa.other.hs.hotkey:set_visible(false)
    refs.aa.other.legs:set_visible(false)
    refs.aa.other.fp:set_visible(false)
    refs.aa.other.fp.hotkey:set_visible(false)
    refs.aa.other.slowmo:set_visible(false)
    refs.aa.other.slowmo.hotkey:set_visible(false)
end

client.set_event_callback('paint_ui', function()
    hide_refs(true)
end) 

local function get_steam_name()
    local success, result = pcall(function()
        return infos.username
    end)
    
    if success and result and result ~= "" then
        return result
    end
    
    return "Error, launch steam"
end

local notifications = {}

local stack_spacing = 5   
local anim_speed = 6      
local duration = 4.0      
local slide_distance = 50  
local FONT_FLAG = ""       
local padding_x = 8        
local padding_y = 4

local function push_notification(format_string, ...)
    local formatted_text
    
    if select('#', ...) > 0 then
        formatted_text = string.format(format_string, ...)
    else
        formatted_text = format_string
    end

    local new_log = {
        text = formatted_text,
        active_until = globals.realtime() + duration,
        progress = 0.0,
    }

    table.insert(notifications, 1, new_log)
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local FONT_FLAG = "" 
local padding_x = 8
local padding_y = 4
local anim_speed = 6 

client.set_event_callback("paint", function()
    local ft = globals.frametime()
    local screen_w, screen_h = client.screen_size()
    
    local base_y = screen_h - 150 
    
    local stack_y_offset = 0

    for i, notif in ipairs(notifications) do
        local is_active = globals.realtime() < notif.active_until

        if is_active then
            notif.progress = clamp(notif.progress + ft * anim_speed, 0, 1)
        else
            notif.progress = clamp(notif.progress - ft * anim_speed, 0, 1)
        end
        
        if notif.progress <= 0 then
            goto continue
        end
        
        local text_w, text_h = renderer.measure_text(FONT_FLAG, notif.text)
        local notify_w = text_w + (padding_x * 2)
        local notify_h = text_h + padding_y

        local alpha = math.floor(notif.progress * 255)
        local slide_offset = (1 - notif.progress) * slide_distance 

        local x = (screen_w / 2) - (notify_w / 2)
        
        local y = base_y - stack_y_offset + slide_offset
        
        local bg_alpha = math.floor(200 * notif.progress)
        renderer.rectangle(x, y, notify_w, notify_h, 16, 16, 16, bg_alpha)
        renderer.rectangle(x, y, notify_w, 2, 150, 200, 60, alpha)
        renderer.text(x + padding_x, y + (padding_y / 2), 255, 255, 255, alpha, FONT_FLAG, 0, notif.text)

        stack_y_offset = stack_y_offset + notify_h + stack_spacing
        
        ::continue::
    end

    for i = #notifications, 1, -1 do
        if notifications[i].progress <= 0 then
            table.remove(notifications, i)
        end
    end
end)

local counter_notif = 1

local okoshko = groups.fakelag:combobox("\n", {"Home", "Anti-aimbot angles", "Misc & Visuals"})
local tab_label = groups.fakelag:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾")
local switch_home = groups.angles:combobox("\n", {"Information", "Config", "Change log"})
switch_home:depend({okoshko, "Home"})
local info_start_user = groups.fakelag:label("Your load: " .. launch_count)
info_start_user:depend({okoshko, "Home"}, {switch_home, "Information"})
local info_start_online = groups.fakelag:label("Users load: " .. launch_count)
info_start_online:depend({okoshko, "Home"}, {switch_home, "Information"})
local list = groups.angles:listbox("Configs", {})
list:depend({okoshko, "Home"}, {switch_home, "Config"})
local textbox_configs = groups.other:textbox("\n")
textbox_configs:depend({okoshko, "Home"}, {switch_home, "Config"})
local create_butt = groups.other:button("\v • Create")
create_butt:depend({okoshko, "Home"}, {switch_home, "Config"})
local load = groups.angles:button("\v • Load")
load:depend({okoshko, "Home"}, {switch_home, "Config"})
local save = groups.angles:button("\v • Save")
save:depend({okoshko, "Home"}, {switch_home, "Config"})
local export = groups.angles:button("\v • Export")
export:depend({okoshko, "Home"}, {switch_home, "Config"})
local import = groups.angles:button("\v • Import")
import:depend({okoshko, "Home"}, {switch_home, "Config"})
local delete = groups.angles:button("• \aD95148FFDelete")
delete:depend({okoshko, "Home"}, {switch_home, "Config"})
local mva_select = groups.fakelag:slider("\n\n\n", 1, 3, 1, true, "", 1, {"Miscellaneous", "Visuals", "Aimbot"})
mva_select:depend({okoshko, "Misc & Visuals"})
local fast_ladder = groups.angles:checkbox("\v • \rFast ladder")
fast_ladder:depend({okoshko, "Misc & Visuals"}, {mva_select, 1})
local aspect_r = groups.angles:checkbox("\v • \rAspect ratio")
aspect_r:depend({okoshko, "Misc & Visuals"}, {mva_select, 2})
local aspect_slider = groups.angles:slider("\n\n", 100, 200, 100, true, "%")
aspect_slider:depend({okoshko, "Misc & Visuals"}, {mva_select, 2}):depend(aspect_r)
local lcbox = groups.angles:checkbox("\v • \rLagcompbox")
lcbox:depend({okoshko, "Misc & Visuals"}, {mva_select, 1})
local console_filter = groups.angles:checkbox("\v • \rConsole Filter")
console_filter:depend({okoshko, "Misc & Visuals"}, {mva_select, 1})
local killsay = groups.angles:checkbox("\v • \rTrashtalk")
killsay:depend({okoshko, "Misc & Visuals"}, {mva_select, 1})
local logs = groups.other:checkbox("\v • \rAimbot Logs")
logs:depend({okoshko, "Misc & Visuals"}, {mva_select, 1})
local log_variance = groups.other:multiselect("Log variance", "Screen", "Console")
log_variance:depend({okoshko, "Misc & Visuals"}, {mva_select, 1}):depend(logs)
local anims = groups.angles:checkbox("\v • \rAnimBreakers")
anims:depend({okoshko, "Misc & Visuals"}, {mva_select, 1})
local anim_ground = groups.angles:combobox("Ground", "None", "Jitter", "Walking", "Static")
anim_ground:depend({okoshko, "Misc & Visuals"}, {mva_select, 1}):depend(anims)
local anim_air = groups.angles:combobox("Aero", "None", "Walking", "Static")
anim_air:depend({okoshko, "Misc & Visuals"}, {mva_select, 1}):depend(anims)
local animations = groups.angles:multiselect("\aA83030FFAdditions", {"Pitch on land", "Kangaroo", "Blinded", "Earthquake"})
animations:depend({okoshko, "Misc & Visuals"}, {mva_select, 1}):depend(anims)
local vgui_color = groups.angles:checkbox("\v • \rVGUI Color", {128, 128, 128})
vgui_color:depend({okoshko, "Misc & Visuals"}, {mva_select, 2})
local slow_ind = groups.angles:checkbox("\v • \rSlow-down Indicator", {161, 92, 191})
slow_ind:depend({okoshko, "Misc & Visuals"}, {mva_select, 2})
local viewmodel = groups.angles:checkbox("\v • \rCustom viewmodels (xyz)")
viewmodel:depend({okoshko, "Misc & Visuals"}, {mva_select, 2})
local view_x = groups.angles:slider("X", -15000, 15000, 0, true, 'X', 0.01)
view_x:depend({okoshko, "Misc & Visuals"}, {mva_select, 2}):depend(viewmodel)
local view_y = groups.angles:slider("Y", -15000, 15000, 0, true, 'Y', 0.01)
view_y:depend({okoshko, "Misc & Visuals"}, {mva_select, 2}):depend(viewmodel)
local view_z = groups.angles:slider("Z", -15000, 15000, 0, true, 'Z', 0.01)
view_z:depend({okoshko, "Misc & Visuals"}, {mva_select, 2}):depend(viewmodel)
local custom_scope = groups.angles:checkbox("\v • \rCustom scope overlay")
custom_scope:depend({okoshko, "Misc & Visuals"}, {mva_select, 2})
local labelnew2 = groups.angles:label("\a373737FF                 Aimbot tab")
labelnew2:depend({okoshko, "Misc & Visuals"}, {mva_select, 3})
local hide_check = groups.other:checkbox("\v • \rAuto hideshots")
hide_check:depend({okoshko, "Misc & Visuals"}, {mva_select, 3})
local stattttes = groups.other:multiselect('\nStates', {'Stand', 'Run', 'Walk', 'Crouch', 'Sneak'})
stattttes:depend({okoshko, "Misc & Visuals"}, {mva_select, 3}):depend(hide_check)
local avoid_guns = groups.other:multiselect('Avoid', {'Pistols', 'Desert Eagle', 'Auto Snipers', 'Desert Eagle + Crouch'})
avoid_guns:depend({okoshko, "Misc & Visuals"}, {mva_select, 3}):depend(hide_check)
local selection = groups.fakelag:slider("\n\n", 1, 4, 1, true, "", 1, {"Builder","Defensive","Hotkeys","Tweaks"})
selection:depend({okoshko, "Anti-aimbot angles"})
ext_states =  {"Shared", "Stand", "Running", "Slow-walk", "Aero", "Aero+", "Duck", "Duck+", "On use", "Freestand"}
defensive_state = {"Stand", "Running", "Slow-walk", "Aero", "Aero+", "Duck", "Duck+"}
local state_selector = groups.angles:combobox("\n", ext_states)
state_selector:depend({okoshko, "Anti-aimbot angles"}, {selection, 1})
local defensive_selector = groups.angles:combobox("\n", defensive_state)
defensive_selector:depend({okoshko, "Anti-aimbot angles"}, {selection, 2})
local fs_bind = groups.angles:hotkey("Freestanding")
fs_bind:depend({okoshko, "Anti-aimbot angles"}, {selection, 3})
local edge_bind = groups.angles:hotkey("\v • \rEdge Yaw")
edge_bind:depend({okoshko, "Anti-aimbot angles"}, {selection, 3})
local manuals = groups.angles:checkbox("\v • \rManuals")
manuals:depend({okoshko, "Anti-aimbot angles"}, {selection, 3})
local manual_type = groups.angles:combobox("\v • \rManual Type", "None", "Jitter", "Opposite", "Static")
manual_type:depend({okoshko, "Anti-aimbot angles"}, {selection, 3}):depend(manuals)
local manual_left = groups.angles:hotkey("\v • \rManual Left")
manual_left:depend({okoshko, "Anti-aimbot angles"}, {selection, 3}):depend(manuals)
local manual_right = groups.angles:hotkey("\v • \rManual Right")
manual_right:depend({okoshko, "Anti-aimbot angles"}, {selection, 3}):depend(manuals)
local slomotion = groups.other:checkbox("\v • \rSlow Motion", 0x00)
slomotion:depend({okoshko, "Anti-aimbot angles"}, {selection, 3})
local legs_move = groups.other:combobox("Leg movement", "Off", "Always slide", "Never slide")
legs_move:depend({okoshko, "Anti-aimbot angles"}, {selection, 3})
local osaa_hot = groups.other:checkbox("\v • \rOn Shot Anti-Aim", 0x00)
osaa_hot:depend({okoshko, "Anti-aimbot angles"}, {selection, 3})
local shizo_aa = groups.angles:checkbox("\v • \rWarmup")
shizo_aa:depend({okoshko, "Anti-aimbot angles"}, {selection, 4})
local shizo_slider = groups.angles:slider("\n\n", 1, 3, 1, true, "", 1, {"Off", "Variables", "Disablers"})
shizo_slider:depend({okoshko, "Anti-aimbot angles"}, {selection, 4}):depend(shizo_aa)
local warmups = groups.angles:multiselect("\n\n", "Warmup", "Round end")
warmups:depend({okoshko, "Anti-aimbot angles"}, {selection, 4}):depend(shizo_aa):depend({shizo_slider, 2})
local warmup_speed = groups.angles:slider("\n", 5, 80, 5, true, "", 1)
warmup_speed:depend({okoshko, "Anti-aimbot angles"}, {selection, 4}):depend(shizo_aa):depend({shizo_slider, 2}, {warmups, "Warmup", "Round end"})
local disablers = groups.angles:multiselect("\n\n", "Warmup", "Round end")
disablers:depend({okoshko, "Anti-aimbot angles"}, {selection, 4}):depend(shizo_aa):depend({shizo_slider, 3})
local backstab = groups.angles:checkbox("\v • \rAnti-Backstab")
backstab:depend({okoshko, "Anti-aimbot angles"}, {selection, 4})
local safe_head = groups.angles:checkbox("\v • \rSafe Head")
safe_head:depend({okoshko, "Anti-aimbot angles"}, {selection, 4})
local safe_options = groups.angles:multiselect("\n\n", {'Knife', 'Taser'})
safe_options:depend({okoshko, "Anti-aimbot angles"}, {selection, 4}):depend(safe_head)

client.set_event_callback("shutdown", function()
        hide_refs(false)
end)

local function on_response(success, response)
    if success and response.status == 200 then
        local data = json.parse(response.body)
        
        if data and data.success then
            launch_count = data.launches
            
            info_start_online:override(string.format("Users load: " .. launch_count))

            if data.user_launches then
                info_start_user:override(string.format("Your load: " .. data.user_launches))
            end
        end
    else
        local error_msg = response and response.status_message or "Error ethernet"
        client.error_log("Server error: " .. error_msg)
    end
end

local function send_launch_request()
    local steam_name = get_steam_name()
    
    http.get("https://mateuszkulisz.fun/api.php", {
        params = {
            action = "launch",
            user = steam_name
        },
        network_timeout = 5,
        absolute_timeout = 10
    }, on_response)
end

client.delay_call(0.5, send_launch_request)

local builder = {}
local steps = {"2 step", "3 step", "4 step", "5 step", "6 step", "7 step", "8 step", "9 step", "10 step", "11 step", "12 step"}

for _, state in ipairs(ext_states) do
    local ctx = {}
ctx.enable = groups.angles:checkbox("\a373737FFBuild")
ctx.enable:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1})

probel_two = groups.angles:label("\a373737FF                 ")
probel_two:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable)

ctx.enable_lr = groups.angles:combobox("\n", {"\aFFFF00331 - Way", "\a00FF00332 - Way"})
ctx.enable_lr:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable)

probel_three = groups.angles:label("\a373737FF                 ")
probel_three:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable)

do_probela = groups.angles:label("\aFFFF0033              Warning this mode old")
do_probela:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\aFFFF00331 - Way"}, ctx.enable)

probel = groups.angles:label("\a373737FF                 ")
probel:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\aFFFF00331 - Way"}, ctx.enable)

ctx.one_way = groups.angles:slider("\n", -180, 180, 0, true)
ctx.one_way:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\aFFFF00331 - Way"}, ctx.enable)

ctx.left_angle = groups.angles:slider("\n", -90, 90, 0, true, "º")
ctx.left_angle:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.random_left = groups.angles:slider("\n", 0, 100, 0, true, "%")
ctx.random_left:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

probel_four = groups.angles:label("\a373737FF                 ")
probel_four:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.right_angle = groups.angles:slider("\n", -90, 90, 0, true, "º")
ctx.right_angle:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.random_right = groups.angles:slider("\n", 0, 100, 0, true, "%")
ctx.random_right:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

probel_six = groups.angles:label("\a373737FF                 ")
probel_six:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.modes_jitter = groups.angles:combobox('\n', {"Off", "Random"})
ctx.modes_jitter:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.modes_jitter_slid = groups.angles:slider('\n', -180, 180, 0, true)
ctx.modes_jitter_slid:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable, {ctx.modes_jitter, "Random"})

ctx.modes_jitter_slid2 = groups.angles:slider('\n', -180, 180, 0, true)
ctx.modes_jitter_slid2:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable, {ctx.modes_jitter, "Random"})

probel_five = groups.angles:label("\a373737FF                 ")
probel_five:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.delay_mode = groups.angles:slider("\n", 1, 3, 1, true, "", 1, {"Default", "Randomize", "Step"})
ctx.delay_mode:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\a00FF00332 - Way"}) 

probel_five = groups.angles:label("\a373737FF                 ")
probel_five:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

ctx.delay_mode_tickes = groups.angles:slider("\n", 1, 4, 1, true, "", 1, {"Default", "Ticked", "Time", "Angle"})
ctx.delay_mode_tickes:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\a00FF00332 - Way"}) 

ctx.step_slider = groups.angles:slider("\n", 1, 11, 1, true, "", 1, step_names)
ctx.step_slider:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode, 3})

ctx.delay_time = groups.angles:slider("\n", 1, 24, 1, true, "t", 1, {"Off"})
ctx.delay_time:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode, 1})

ctx.delay_1 = groups.angles:slider("\n", 1, 24, 1, true, "t", 1, {"Off"})
ctx.delay_1:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode, 2})

ctx.delay_2 = groups.angles:slider("\n", 1, 24, 1, true, "t", 1, {"Off"})
ctx.delay_2:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, ctx.enable, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode, 2})

probel_five = groups.angles:label("\a373737FF                 ")
probel_five:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable)

line_prob = groups.angles:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾")
line_prob:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, ctx.enable, {ctx.delay_mode_tickes, 2, 3})

ctx.delay_ticked = groups.angles:slider("\n", 1, 4, 1, true, "t")
ctx.delay_ticked:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, ctx.enable, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode_tickes, 2})

ctx.delay_time_modes = groups.angles:slider("\n", 10, 250, 10, true, "ms")
ctx.delay_time_modes:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, ctx.enable, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode_tickes, 3})

ctx.delay_angle_modes = groups.angles:slider("\n", 1, 24, 1, true, "t",1, {"Off"})
ctx.delay_angle_modes:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, ctx.enable, {selection, 1}, {ctx.enable_lr, "\a00FF00332 - Way"}, {ctx.delay_mode_tickes, 4})

ctx.combo1 = groups.angles:combobox("\n", {"Off", "Center", "Offset", "Random", "Skitter"})
ctx.combo1:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\aFFFF00331 - Way"})

ctx.yawjit = groups.angles:slider("\n", -180, 180, 0, true)
ctx.yawjit:depend({state_selector, state}, {okoshko, "Anti-aimbot angles"}, {selection, 1}, ctx.enable, {ctx.enable_lr, "\aFFFF00331 - Way"}, {ctx.combo1, "Center", "Offset", "Random", "Skitter"})

ctx.enable_defensive = groups.angles:checkbox(state .. " \v{ • } \r Build defensive")
ctx.enable_defensive:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2})

labelnew988 = groups.angles:label("\a373737FF                 ")
labelnew988:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive)

labelnew344 = groups.angles:label("\a373737FF              Pitch section")
labelnew344:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive)

labelnew444 = groups.angles:label("\a373737FF                 ")
labelnew444:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive)    
    
ctx.pitch_defensive = groups.angles:combobox("\n", {"Off", "Custom", "Sway", "Switch", "All angle", "Random", "Random switch"})
ctx.pitch_defensive:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive)      

ctx.custom_slider = groups.angles:slider("\n", -89, 89, 0, true)
ctx.custom_slider:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Custom"})

ctx.sway_slider1 = groups.angles:slider("\n", -89, 89, 0, true, "")
ctx.sway_slider1:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Sway"})

ctx.sway_slider2 = groups.angles:slider("\n", -89, 89, 0, true, "")
ctx.sway_slider2:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Sway"})

ctx.sway_slider3 = groups.angles:slider("\n", 1, 30, 1, true, "")
ctx.sway_slider3:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Sway"})

ctx.switch_slider = groups.angles:slider("\n", -89, 89, 0, true, "")
ctx.switch_slider:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Switch"})

ctx.switch_slider2 = groups.angles:slider("\n", -89, 89, 0, true, "")
ctx.switch_slider2:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Switch"})

ctx.random_slider = groups.angles:slider("\n", -89, 89, 0, true, "")
ctx.random_slider:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Random"})

ctx.random_slider2 = groups.angles:slider("\n", -89, 89, 0, true, "")
ctx.random_slider2:depend({okoshko, "Anti-aimbot angles"}, {defensive_selector, state}, {selection, 2}, ctx.enable_defensive, {ctx.pitch_defensive, "Random"})

builder [state] = ctx
end

local function get_local_state()
    local me = entity.get_local_player()

    if not me then
        return "Unknown"
    end

    local vx, vy = entity.get_prop(me, "m_vecVelocity")
    local speed = math.sqrt(vx^2 + vy^2)
    local on_ground = bit.band(entity.get_prop(me, "m_fFlags"), 1) == 1
    local duck_amount = entity.get_prop(me, 'm_flDuckAmount') > 0.5

    if not on_ground then
    if duck_amount then
        return "Aero+"
    else
        return "Aero"
    end

elseif duck_amount then
        if speed > 10 then
            return "Duck+"
        else
            return "Duck"
        end
    elseif speed < 3 then
        return "Stand"
    elseif speed > 10 then
        return "Running"
    end


    return "Shared"
end

local sended = 0
local switch = false

local function warmup_antiaim()
   gamerulesproxy = entity.get_all('CCSGameRulesProxy')[1]
   warmup = entity.get_prop(gamerulesproxy,'m_bWarmupPeriod')
   speed_warmup_aa = warmup_speed:get()

    if warmup == 1 and warmups:get("Warmup") and shizo_aa:get() then
    refs.aa.angles.pitch[1]:override("Custom")
    refs.aa.angles.pitch[2]:override(0)
    refs.aa.angles.enable:override(true)
    refs.aa.angles.yaw[1]:override("Spin")
    refs.aa.angles.body[1]:override("Off")
    refs.aa.angles.yaw[2]:override(speed_warmup_aa)
    end
end

local function builder_aa(cmd)
     state = get_local_state()
     me = entity.get_local_player()
     gamerulesproxy = entity.get_all('CCSGameRulesProxy')[1]
     warmup = entity.get_prop(gamerulesproxy,'m_bWarmupPeriod')

    local ctx = builder[builder[state].enable:get() and state or "Shared"]

    if warmups:get("Warmup") and shizo_aa:get() and not ctx.enable:get() then return end

    refs.aa.angles.pitch[1]:override("Custom")
    refs.aa.angles.pitch[2]:override(89)
    refs.aa.angles.yaw[1]:override("180")
    refs.aa.angles.roll:override(0)
    refs.aa.angles.base:override("At targets")
    refs.aa.angles.enable:override(true)

    jit_value = ctx.modes_jitter_slid:get()
    jit_value2 = ctx.modes_jitter_slid2:get()
    current_delay = ctx.delay_time:get()
    mode = ctx.delay_mode:get()

    if mode == 2 then
        min_delay = ctx.delay_1:get()
        max_delay = ctx.delay_2:get()
        current_delay = math.random(min_delay, max_delay + min_delay)
    end

    if globals.chokedcommands() == 0 then
        sended = sended + 1
        if sended % current_delay == 0 then
            switch = not switch
        end
    end

    left_value = ctx.left_angle:get()
    right_value = ctx.right_angle:get()
    random_left_pct = ctx.random_left:get()
    random_right_pct = ctx.random_right:get()

    main_offset = switch and randomized_left or randomized_right
    left_variation = left_value * (random_left_pct / 100)
    right_variation = right_value * (random_right_pct / 100)
    randomized_left = left_value + math.random(-left_variation, left_variation)
    randomized_right = right_value + math.random(-right_variation, right_variation)

   refs.aa.angles.yaw[2]:override(main_offset)
   refs.aa.angles.body[1]:override("Static")
   refs.aa.angles.body[2]:override(switch and 120 or -120)
end

local function cust_random()
    state = get_local_state()
    me = entity.get_local_player()
    gamerulesproxy = entity.get_all('CCSGameRulesProxy')[1]
    warmup = entity.get_prop(gamerulesproxy,'m_bWarmupPeriod')

    local ctx = builder[builder[state].enable:get() and state or "Shared"]

    if warmups:get("Warmup") and shizo_aa:get() and not ctx.enable:get() then return end

    min_jit = math.min(ctx.modes_jitter_slid:get(), ctx.modes_jitter_slid2:get())
    max_jit = math.max(ctx.modes_jitter_slid:get(), ctx.modes_jitter_slid2:get())
    random_jitter = math.random(min_jit, max_jit)

    if ctx.modes_jitter:get("Random") then
        refs.aa.angles.yaw[2]:override(random_jitter)
        end
    end

    local function safe_knife()
        local me = entity.get_local_player()
        if not me then return end
    
        local weapon = entity.get_player_weapon(me)
        if not weapon then return end
    
        local class = entity.get_classname(weapon)
        local state = get_local_state()
    
        if not safe_head:get() or not safe_options:get("Knife") then
            return
        end
    
        local lp_x, lp_y, lp_z = entity.get_origin(me)
        if not lp_x then return end
    
        local enemies = entity.get_players(true)
        local closest_enemy = nil
        local closest_dist = math.huge
    
        for i = 1, #enemies do
            local enemy = enemies[i]
            local ex, ey, ez = entity.get_origin(enemy)
            if ex then
                local dx = ex - lp_x
                local dy = ey - lp_y
                local dz = ez - lp_z
                local dist2 = dx*dx + dy*dy + dz*dz
                if dist2 < closest_dist then
                    closest_dist = dist2
                    closest_enemy = enemy
                end
            end
        end

        local is_safe_head = true
    
        if closest_enemy then
            local _, _, enemy_z = entity.get_origin(closest_enemy)
            if enemy_z and lp_z then
                if enemy_z > lp_z then
                    is_safe_head = false
                else
                    is_safe_head = true
                end
            end
        end

        if class == "CKnife" and safe_head:get() and safe_options:get("Knife") and state == "Aero+" and is_safe_head then
            refs.aa.angles.yaw[1]:override("180")
            refs.aa.angles.yaw[2]:override("0")
            refs.aa.angles.pitch[1]:override("Custom")
            refs.aa.angles.pitch[2]:override(89)
            refs.aa.angles.body[1]:override("Off")
        end
    end
    

local function anti_stab()
    if not backstab:get() then return end
    local lp = entity.get_local_player()
    if not lp then return end
    local lp_origin = vector(entity.get_origin(lp))
    local enemies = entity.get_players(true)
    for i = 1, #enemies do
        local enemy = enemies[i]
        local enemy_weapon = entity.get_player_weapon(enemy)
        if enemy_weapon and entity.get_classname(enemy_weapon) == "CKnife" then
            if vector(entity.get_origin(enemy)):dist2d(lp_origin) < 180 then
                refs.aa.angles.yaw[1]:override("180")
                refs.aa.angles.yaw[2]:override("180")
                refs.aa.angles.body[1]:override("Off")
                return
            end
        end
    end
end

local function one_way_antiaim()
    state = get_local_state()
    local ctx = builder[builder[state].enable:get() and state or "Shared"]
    mode_one_way = ctx.enable_lr:get("\a00FF00332 - Way")
    value_slider_one = ctx.yawjit:get()
    mode_one_way_sett = ctx.combo1:get()

    if ctx.enable_lr:get("\a00FF00332 - Way") and not ctx.enable:get() then return end

    refs.aa.angles.jitter[1]:override(mode_one_way_sett)
    refs.aa.angles.yaw[1]:override("180")
    refs.aa.angles.jitter[2]:override(value_slider_one)
end

client.set_event_callback('round_end', function()
    gamerulesproxy = entity.get_all('CCSGameRulesProxy')[1]
    warmup = entity.get_prop(gamerulesproxy,'m_bWarmupPeriod')
    speed_shizo = warmup_speed:get()

    if warmup == 1 and warmups:get("Round end") and shizo_aa:get() then
    refs.aa.angles.pitch[1]:override("Custom")
    refs.aa.angles.pitch[2]:override(0)
    refs.aa.angles.enable:override(true)
    refs.aa.angles.yaw[1]:override("Spin")
    refs.aa.angles.body[1]:override("Off")
    refs.aa.angles.yaw[2]:override(speed_shizo)
    end
end)

local aspect_ratio_handler do
local function set_aspect_ratio(aspect_ratio_multiplier)
	local screen_width, screen_height = client.screen_size()
	local aspectratio_value = (screen_width*aspect_ratio_multiplier)/screen_height

	if aspect_ratio_multiplier == 1 then
		aspectratio_value = 0
	end
	client.set_cvar("r_aspectratio", tonumber(aspectratio_value))
end

local function noop()
end

local function gcd(m, n)
	while m ~= 0 do
		m, n = math.fmod(n, m), m
	end

	return n
end

local screen_width, screen_height, aspect_ratio_reference

local function on_aspect_ratio_changed()
	local aspect_ratio = aspect_slider:get()*0.01
	aspect_ratio = 2 - aspect_ratio
	set_aspect_ratio(aspect_ratio)
end

local multiplier = 0.01
local steps = 200

local function setup(screen_width_temp, screen_height_temp)
	screen_width, screen_height = screen_width_temp, screen_height_temp
	local aspect_ratio_table = {}

	for i=1, steps do
		local i2=(steps-i)*multiplier
		local divisor = gcd(screen_width*i2, screen_height)
		if screen_width*i2/divisor < 100 or i2 == 1 then
			aspect_ratio_table[i] = screen_width*i2/divisor .. ":" .. screen_height/divisor
		end
	end

	aspect_slider:set_callback(on_aspect_ratio_changed)
end
setup(client.screen_size())

local function on_paint(ctx)
	local screen_width_temp, screen_height_temp = client.screen_size()
	if screen_width_temp ~= screen_width or screen_height_temp ~= screen_height then
		setup(screen_width_temp, screen_height_temp)
	end
end
client.set_event_callback("paint", on_paint)
end

refs.aa.angles.pitch[1]:override("Custom")
refs.aa.angles.pitch[2]:override(89)
refs.aa.angles.yaw[1]:override("180")
refs.aa.angles.yaw[2]:override(0)
refs.aa.angles.jitter[1]:override("Off")
refs.aa.angles.roll:override(0)
refs.aa.angles.base:override("At targets")
refs.aa.angles.enable:override(true)
refs.aa.angles.fs_body:override(false)
cvar.con_filter_text:set_string("cool text")
cvar.con_filter_enable:set_int(1)

client.set_event_callback('setup_command', function(cmd)
    if fast_ladder:get() then
        local lp = entity.get_local_player()
        if lp == nil then
            return
        end

        if entity.get_prop(lp, 'm_MoveType') ~= 9 then
            return
        end

        local weapon = entity.get_player_weapon(lp)
        if weapon == nil then
            return
        end
        local throw_time = entity.get_prop(weapon, 'm_fThrowTime')
        if throw_time ~= nil and throw_time ~= 0 then
            return
        end

        if cmd.forwardmove > 0 then
            if cmd.pitch < 45 then
                cmd.pitch = 89
                cmd.in_moveright = 1
                cmd.in_moveleft = 0
                cmd.in_forward = 0
                cmd.in_back = 1

                if cmd.sidemove == 0 then
                    cmd.yaw = cmd.yaw + 90
                end
                if cmd.sidemove < 0 then
                    cmd.yaw = cmd.yaw + 150
                end
                if cmd.sidemove > 0 then
                    cmd.yaw = cmd.yaw + 30
                end
            end
        elseif cmd.forwardmove < 0 then
            cmd.pitch = 89
            cmd.in_moveleft = 1
            cmd.in_moveright = 0
            cmd.in_forward = 1
            cmd.in_back = 0

            if cmd.sidemove == 0 then
                cmd.yaw = cmd.yaw + 90
            end
            if cmd.sidemove > 0 then
                cmd.yaw = cmd.yaw + 150
            end

            if cmd.sidemove < 0 then
                cmd.yaw = cmd.yaw + 30
            end
        end  
    else
        return
    end 
end)

client.set_event_callback("setup_command", function()
builder_aa()
safe_knife()
anti_stab()
one_way_antiaim()

local is_active_fs = { fs_bind:get_hotkey() }

if is_active_fs then
    refs.aa.angles.freestand:override(true)
    refs.aa.angles.freestand.hotkey:override("Always on")
else
    refs.aa.angles.freestand:override(false)
    refs.aa.angles.freestand.hotkey:override("On hotkey")
end
print(is_active_fs)
end)

ffi.cdef [[
	typedef int(__thiscall* get_clipboard_text_count)(void*);
	typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
	typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
    typedef bool(__thiscall* console_is_visible)(void*);
]]

local VGUI_System010 =  client.create_interface("vgui2.dll", "VGUI_System010") or print( "Error finding VGUI_System010")
local VGUI_System = ffi.cast(ffi.typeof('void***'), VGUI_System010 )
local VGUI_System010 =  client.create_interface("vgui2.dll", "VGUI_System010") or print( "Error finding VGUI_System010")
local VGUI_System = ffi.cast(ffi.typeof('void***'), VGUI_System010 )
local get_clipboard_text_count = ffi.cast("get_clipboard_text_count", VGUI_System[ 0 ][ 7 ] ) or print( "get_clipboard_text_count Invalid")
local set_clipboard_text = ffi.cast( "set_clipboard_text", VGUI_System[ 0 ][ 9 ] ) or print( "set_clipboard_text Invalid")
local get_clipboard_text = ffi.cast( "get_clipboard_text", VGUI_System[ 0 ][ 11 ] ) or print( "get_clipboard_text Invalid")

local engine_client = ffi.cast(ffi.typeof("void***"), client.create_interface("engine.dll", "VEngineClient014"))
local console_is_visible = ffi.cast("console_is_visible", engine_client[0][11])
local materials = { "vgui_white", "vgui/hud/800corner1", "vgui/hud/800corner2", "vgui/hud/800corner3", "vgui/hud/800corner4" }
local vgui_color = function()
    if not entity.get_local_player() then return end
    if (console_is_visible(engine_client)) then
        local r, g, b, a = 255, 255, 255, 255
        if vgui_color:get() then
            r, g, b, a = vgui_color:get_color()
        end
        for i=1, #materials do 
            local mat = materials[i]
            materialsystem.find_material(mat):alpha_modulate(a)
            materialsystem.find_material(mat):color_modulate(r, g, b)
        end
    else
        for i=1, #materials do 
            local mat = materials[i]
            materialsystem.find_material(mat):alpha_modulate(255)
            materialsystem.find_material(mat):color_modulate(255, 255, 255)
        end
    end
end

client.set_event_callback("paint_ui", function()
    vgui_color()
end)

client.set_event_callback("setup_command", function(cmd)
   warmup_antiaim()
end)

--

local viewmodel_main do
local get_cvar, vo_hand, vfov, vo_x, vo_y, vo_z = client.get_cvar, cvar.cl_righthand, cvar.viewmodel_fov, cvar.viewmodel_offset_x, cvar.viewmodel_offset_y, cvar.viewmodel_offset_z

local ffi, bit = require 'ffi', require 'bit'
local ffi_to = {
    classptr = ffi.typeof('void***'), 
    client_entity = ffi.typeof('void*(__thiscall*)(void*, int)'),
    
    set_angles = (function()
        ffi.cdef('typedef struct { float x; float y; float z; } vmodel_vec3_t;')

        return ffi.typeof('void(__thiscall*)(void*, const vmodel_vec3_t&)')
    end)()
}

local rawelist = client.create_interface('client_panorama.dll', 'VClientEntityList003') or error('VClientEntityList003 is nil', 2)
local ientitylist = ffi.cast(ffi_to.classptr, rawelist) or error('ientitylist is nil', 2)
local get_client_entity = ffi.cast(ffi_to.client_entity, ientitylist[0][3]) or error('get_client_entity is nil', 2)

local set_angles = client.find_signature('client_panorama.dll', '\x55\x8B\xEC\x83\xE4\xF8\x83\xEC\x64\x53\x56\x57\x8B\xF1') or error('Couldn\'t find set_angles signature!')
local set_angles_fn = ffi.cast(ffi_to.set_angles, set_angles) or error('Couldn\'t cast set_angles_fn')

local get_original = function()
    return {
        view_fov2 = get_cvar('viewmodel_fov'),
        view_x2 = get_cvar('viewmodel_offset_x'),
        view_y2 = get_cvar('viewmodel_offset_y'),
        view_z2 = get_cvar('viewmodel_offset_z')
    }
end

client.set_event_callback("setup_command", function()
if viewmodel:get() then
local g_handler = function(...)
    local shutdown = #({...}) > 0

    local multiplier = shutdown and 0 or 0.0025
    local original, data = get_original(), 
    {
        x = view_x:get() * multiplier,
        y = view_y:get() * multiplier,
        z = view_z:get() * multiplier
    }
    vo_x:set_raw_float(original.view_x2 + data.x)
    vo_y:set_raw_float(original.view_y2 + data.y)
    vo_z:set_raw_float(original.view_z2 + data.z)
end

local g_override_view = function()
    local me = entity.get_local_player()
    local viewmodel = entity.get_prop(me, 'm_hViewModel[0]')

    if me == nil or viewmodel == nil then
        return
    end

    local viewmodel_ent = get_client_entity(ientitylist, viewmodel)

    if viewmodel_ent == nil then
        return
    end

    local camera_angles = { client.camera_angles() }
    local angles = ffi.cast('vmodel_vec3_t*', ffi.new('char[?]', ffi.sizeof('vmodel_vec3_t')))

    angles.x, angles.y, angles.z = 
        camera_angles[1], camera_angles[2], camera_angles[3]
end

client.set_event_callback('pre_render', g_handler)
client.set_event_callback('override_view', g_override_view)
client.set_event_callback('shutdown', function() g_handler(true) end)
end
end)
end

prefersafe = pui.reference('RAGE', 'Aimbot', 'Prefer safe point')
forcesafe = pui.reference('RAGE', 'Aimbot', 'Force safe point')

local num_format = function(b) local c=b%10;if c==1 and b~=11 then return b..'st'elseif c==2 and b~=12 then return b..'nd'elseif c==3 and b~=13 then return b..'rd'else return b..'th'end end
local hitgroup_names = { 'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear' }
local weapon_to_verb = { knife = 'Knifed', hegrenade = 'Naded', inferno = 'Burned' }

local classes = {
    net_channel = function()
        local this = { }

        local class_ptr = ffi.typeof('void***')
        local engine_client = ffi.cast(class_ptr, client.create_interface("engine.dll", "VEngineClient014"))
        local get_channel = ffi.cast("void*(__thiscall*)(void*)", engine_client[0][78])

        local netc_bool = ffi.typeof("bool(__thiscall*)(void*)")
        local netc_bool2 = ffi.typeof("bool(__thiscall*)(void*, int, int)")
        local netc_float = ffi.typeof("float(__thiscall*)(void*, int)")
        local netc_int = ffi.typeof("int(__thiscall*)(void*, int)")
        local net_fr_to = ffi.typeof("void(__thiscall*)(void*, float*, float*, float*)")

        client.set_event_callback('net_update_start', function()
            local ncu_info = ffi.cast(class_ptr, get_channel(engine_client)) or error("net_channel:update:info is nil")
            local seqNr_out = ffi.cast(netc_int, ncu_info[0][17])(ncu_info, 1)
        
            for name, value in pairs({
                seqNr_out = seqNr_out,
        
                is_loopback = ffi.cast(netc_bool, ncu_info[0][6])(ncu_info),
                is_timing_out = ffi.cast(netc_bool, ncu_info[0][7])(ncu_info),
        
                latency = {
                    crn = function(flow) return ffi.cast(netc_float, ncu_info[0][9])(ncu_info, flow) end,
                    average = function(flow) return ffi.cast(netc_float, ncu_info[0][10])(ncu_info, flow) end,
                },
        
                loss = ffi.cast(netc_float, ncu_info[0][11])(ncu_info, 1),
                choke = ffi.cast(netc_float, ncu_info[0][12])(ncu_info, 1),
                got_bytes = ffi.cast(netc_float, ncu_info[0][13])(ncu_info, 1),
                sent_bytes = ffi.cast(netc_float, ncu_info[0][13])(ncu_info, 0),
        
                is_valid_packet = ffi.cast(netc_bool2, ncu_info[0][18])(ncu_info, 1, seqNr_out-1),
            }) do
                this[name] = value
            end
        end)

        function this:get()
            return (this.seqNr_out ~= nil and this or nil)
        end

        return this
    end,

    aimbot = function(net_channel)
        local this = { }
        local aim_data = { }
        local bullet_impacts = { }

        local generate_flags = function(pre_data)
            return {
                pre_data.self_choke > 1 and 1 or 0,
                pre_data.velocity_modifier < 1.00 and 1 or 0,
                pre_data.flags.boosted and 1 or 0
            }
        end

        local get_safety = function(aim_data, target)
            has_been_boosted = aim_data.boosted
            plist_safety = plist.get(target, 'Override safe point')
            ui_safety = {prefersafe:get(), forcesafe:get() or plist_safety == 'On' }
    
            if not has_been_boosted then
                return -1
            end
    
            if plist_safety == 'Off' or not (ui_safety[1] or ui_safety[2]) then
                return 0
            end
    
            return ui_safety[2] and 2 or (ui_safety[1] and 1 or 0)
        end

        local get_inaccuracy_tick = function(pre_data, tick)
            local spread_angle = -1
            for k, impact in pairs(bullet_impacts) do
                if impactick == tick then
                    local aim, shot = 
                        (pre_data.eye-pre_data.shot_pos):angles(),
                        (pre_data.eye-impacshot):angles()
        
                        spread_angle = vector(aim-shot):length2d()
                    break
                end
            end

            return spread_angle
        end

local function ticks_to_time_ms(ticks)
    return math.floor(ticks * globals.tickinterval() * 1000 + 0.5)
end
        
        this.fired = function(e)
            local this = { }
            local p_ent = e.target
            local me = entity.get_local_player()
        
            aim_data[e.id] = {
                original = e,
                dropped_packets = { },
        
                handle_time = globals.realtime(),
                self_choke = globals.chokedcommands(),
        
                flags = {
                    boosted = e.boosted
                },

                safety = get_safety(e, p_ent),
                correction = plist.get(p_ent, 'Correction active'),
        
                shot_pos = vector(e.x, e.y, e.z),
                eye = vector(client.eye_position()),
                view = vector(client.camera_angles()),
        
                velocity_modifier = entity.get_prop(me, 'm_flVelocityModifier'),
                total_hits = entity.get_prop(me, 'm_totalHitsOnServer'),
                history = globals.tickcount() - e.tick
            }
        end

        this.missed = function(e)
            if aim_data[e.id] == nil then
                return
            end
        
            local pre_data = aim_data[e.id]
            local shot_id = num_format((e.id % 15) + 1)
            
            local net_data = net_channel:get()
        
            local ping, avg_ping = 
                net_data.latency.crn(0)*1000, 
                net_data.latency.average(0)*1000
        
            local net_state = string.format(
                'delay: %d:%.2f | dropped: %d', 
                avg_ping, math.abs(avg_ping-ping), #pre_data.dropped_packets
            )
        
            local uflags = {
                math.abs(avg_ping-ping) < 1 and 0 or 1,
                cvar.cl_clock_correction:get_int() == 1 and 0 or 1,
                cvar.cl_clock_correction_force_server_tick:get_int() == 999 and 0 or 1
            }
        
            local spread_angle = get_inaccuracy_tick( pre_data, globals.tickcount() )

            -- smol stuff
            local me = entity.get_local_player()
            local hgroup = hitgroup_names[e.hitgroup + 1] or '?'
            local target_name = string.lower(entity.get_player_name(e.target))
            local hit_chance = math.floor(pre_data.original.hit_chance + 0.5)
            local pflags = generate_flags(pre_data)
            time_ms = ticks_to_time_ms(pre_data.history)

            local reasons = {
                ['event_timeout'] = function()
                    print(string.format(
                        '[-] Missed %s shot due to event timeout [%s] [%s]', 
                        shot_id, target_name, net_state
                    ))
                end,

                ['death'] = function()
                    client.color_log(161, 117, 117, (string.format(
                        '[-] Missed %s shot at %s\'s %s(%s%%) due to death [dropped: %d | flags: %s | error: %s]', 
                        shot_id, target_name, hgroup, hit_chance, #pre_data.dropped_packets, table.concat(pflags), table.concat(uflags)
                    )))
                end,
        
                ['prediction_error'] = function(type)
                    local type = type == 'unregistered shot' and (' [' .. type .. ']') or ''
                    client.color_log(161, 117, 117, (string.format(
                        '[-] Missed %s shot at %s\'s %s(%s%%) due to prediction error%s [%s] [vel_modifier: %.1f | history(Δ): %d | error: %s]', 
                        shot_id, target_name, hgroup, hit_chance, type, net_state, entity.get_prop(me, 'm_flVelocityModifier'), pre_data.history, table.concat(uflags)
                    )))
                end,
        
                ['spread'] = function()
                    client.color_log(161, 117, 117, (string.format(
                        '[-] Missed %s group: %s ~ reason: spread (damage: %d hp) (hc: %s%%) bt: %d [%d ms] ',
                        target_name, hgroup, 
                        pre_data.original.damage, hit_chance, pre_data.history, time_ms
                    )))
                end,
        
                ['unknown'] = function(type)
                    local _type = {
                        ['damage_rejected'] = 'damage register',
                        ['unknown'] = string.format('correction')
                    }

                    client.color_log(161, 117, 117, (string.format(
                        '[-] Missed %s ~ group: %s ~ reason: %s (damage: %d hp) (hc: %s%%) bt: %d [%d ms]',
                        target_name, hgroup, _type[type or 'unknown'],
                        pre_data.original.damage, hit_chance, pre_data.history, time_ms
                    )))
                    push_notification("Missed %s group: %s ~ reason: %s (damage: %d hp) bt: %d [%d ms]", target_name, hgroup, _type[type or 'unknown'], pre_data.original.damage, pre_data.history, time_ms)
                end
            }
        
            local post_data = {
                event_timeout = (globals.realtime() - pre_data.handle_time) >= 0.5,
                damage_rejected = e.reason == '?' and pre_data.total_hits ~= entity.get_prop(me, 'm_totalHitsOnServer'),
                prediction_error = e.reason == 'prediction error' or e.reason == 'unregistered shot'
            }
        
            if post_data.event_timeout then 
                reasons.event_timeout()
            elseif post_data.prediction_error then 
                reasons.prediction_error(e.reason)
            elseif e.reason == 'spread' then
                reasons.spread()
            elseif e.reason == '?' then
                reasons.unknown(post_data.damage_rejected and 'damage_rejected' or 'unknown')
            elseif e.reason == 'death' then
                reasons.death()
            end
        
            aim_data[e.id] = nil
        end
        
        this.hit = function(e)
            if aim_data[e.id] == nil then
                return
            end
        
            local p_ent = e.target

            local pre_data = aim_data[e.id]
            local shot_id = num_format((e.id % 15) + 1)

            local me = entity.get_local_player()
            local hgroup = hitgroup_names[e.hitgroup + 1] or '?'
            local aimed_hgroup = hitgroup_names[pre_data.original.hitgroup + 1] or '?'

            local target_name = string.lower(entity.get_player_name(e.target))
            local hit_chance = math.floor(pre_data.original.hit_chance + 0.5)
            local pflags = generate_flags(pre_data)

            local spread_angle = get_inaccuracy_tick( pre_data, globals.tickcount() )
            time_ms = ticks_to_time_ms(pre_data.history)
            local _verification = function()
                local text = ''

                local hg_diff = hgroup ~= aimed_hgroup
                local dmg_diff = e.damage ~= pre_data.original.damage

                if hg_diff or dmg_diff then
                    text = string.format(
                        ' | mismatch: [ %s ]', (function()
                            local addr = ''

                            if dmg_diff then addr = 'damage: ' .. pre_data.original.damage .. (hg_diff and ' | ' or '') end
                            if hg_diff then addr = addr .. (hg_diff and 'group: ' .. aimed_hgroup or '') end

                            return addr
                        end)()
                    )
                end

                return text
            end

            client.color_log(161, 117, 117, string.format(
                '[+] Registered shot %s group: %s ~ (damage: %d hp) (hc: %d%%) bt: %d [%d ms]',
                target_name, hgroup, e.damage,
                hit_chance, pre_data.history, time_ms, _verification()
            ))
            push_notification("Hit %s group: %s ~ (damage: %d hp) bt: %d [%d ms]", target_name, hgroup, e.damage, pre_data.history, time_ms)
            counter_notif = counter_notif + 1
        end
        
        this.bullet_impact = function(e)
            local tick = globals.tickcount()
            local me = entity.get_local_player()
            local user = client.userid_to_entindex(e.userid)
            
            if user ~= me then
                return
            end
        
            if #bullet_impacts > 150 then
                bullet_impacts = { }
            end
        
            bullet_impacts[#bullet_impacts+1] = {
                tick = tick,
                eye = vector(client.eye_position()),
                shot = vector(e.x, e.y, e.z)
            }
        end
        
        this.net_listener = function()
            local net_data = net_channel:get()
        
            if net_data == nil then
                return
            end

            if not net_channel.is_valid_packet then
                for id in pairs(aim_data) do
                    table.insert(aim_data[id].dropped_packets, net_channel.seqNr_out)
                end
            end
        end

        return this
    end
}

local net_channel = classes.net_channel()
local aimbot = classes.aimbot(net_channel)

local g_player_hurt = function(e)
    local attacker_id = client.userid_to_entindex(e.attacker)
	
    if attacker_id == nil or attacker_id ~= entity.get_local_player() then
        return
    end

    local group = hitgroup_names[e.hitgroup + 1] or "?"
	
    if group == "generic" and weapon_to_verb[e.weapon] ~= nil then
        local target_id = client.userid_to_entindex(e.userid)
		local target_name = entity.get_player_name(target_id)

		print(string.format("%s %s damage: %i hp", weapon_to_verb[e.weapon], string.lower(target_name), e.dmg_health))
	end
end
    client.set_event_callback("setup_command", function()
        if log_variance:get("Console") then
    client.set_event_callback('aim_fire', aimbot.fired)
    client.set_event_callback('aim_miss', aimbot.missed)
    client.set_event_callback('aim_hit', aimbot.hit)
    client.set_event_callback('bullet_impact', aimbot.bullet_impact)
    client.set_event_callback('net_update_start', aimbot.net_listener)
    client.set_event_callback('player_hurt', g_player_hurt)
        end
    end)

config_listbox = list
config_name_textbox = textbox_configs

local function setup_default_config(base64_cfg)
    local ok, decrypted_data = pcall(base64.decode, base64_cfg)
    if not ok then 
        return false
    end
    local ok2, cfg = pcall(json.parse, decrypted_data)
    if not ok2 or type(cfg) ~= "table" then 
        return false
    end
    cfg.config_name = "Default"
    return cfg
end

local function initialize_configs()
    if database.read("russia_1995") == nil then
        database.write("russia_1995", {})
    end
    if database.read("russia_1995") == nil then
        database.write("russia_1995", {})
    end
    local configs = database.read("russia_1995")
    local names = database.read("russia_1995")
    local has_default = false
    for i = 1, #names do
        if names[i] == "Default" then
            has_default = true
            break
        end
    end
    if not has_default then
        local default_cfg = setup_default_config(default_config)
        if default_cfg then
            table.insert(names, "Default")
            configs["Default"] = default_cfg
            database.write("russia_1995", configs)
            database.write("russia_1995", names)
            database.flush()
        end
    end
end

local function get_config_names_list()
    initialize_configs()
    local configs = database.read("russia_1995") or {}
    local names_list = {}
    
    for name, _ in pairs(configs) do
        table.insert(names_list, name)
    end
    
    return names_list, configs
end

local function refresh_config_list()
    local names, _ = get_config_names_list()
    config_listbox:update(names)
end

client.delay_call(0.1, refresh_config_list)

local function get_config_names()
    initialize_configs()
    local names = database.read("russia_1995")
    local options = {}
    for i = 1, #names do
        options[i] = names[i]
    end
    if #options == 0 then
        options[1] = "Please create a config"
    end
    return options
end

local config_names = get_config_names()

local function create_button_func()
    local name = config_name_textbox:get()
    if name == nil or name == "" then
        print("Please enter a config name")
        return
    end
    if string.len(name) > 32 then
        print("Config name too long")
        return
    end
    initialize_configs()
    local configs = database.read("russia_1995")
    local names = database.read("russia_1995")
    for i = 1, #names do
        if names[i] == name then
            print("Config '" .. name .. "' already exists")
            return
        end
    end
    local cfg = {}
    cfg.state = state_selector:get()
    cfg.aa = {}
    for state, elems in pairs(builder) do
        cfg.aa[state] = {}
        for key, widget in pairs(elems) do
            cfg.aa[state][key] = widget:get()
        end
    end
    cfg.backstab = backstab:get()
    cfg.aspect_r = aspect_r:get()
    cfg.aspect_slider = aspect_slider:get()
    table.insert(names, name)
    configs[name] = cfg
    database.write("russia_1995", configs)
    database.write("russia_1995", names)
    database.flush()
    refresh_config_list()
    --config_listbox:update(names)
    print("Config '" .. name .. "' created")
end

create_butt:set_callback(create_button_func)

local function save_button_func()
    initialize_configs()
    local names = database.read("russia_1995")
    local configs = database.read("russia_1995")
    if #names == 0 then
        print("No configs to save to")
        return
    end
    local selected_index = config_listbox:get() + 1
    if selected_index > #names then
        print("Invalid config selected")
        return
    end
    local selected_name = names[selected_index]
    if selected_name == "Default" then
        print("Cannot save to Default config")
        return
    end
    local cfg = {}
    cfg.state = state_selector:get()
    cfg.aa = {}
    for state, elems in pairs(builder) do
        cfg.aa[state] = {}
        for key, widget in pairs(elems) do
            cfg.aa[state][key] = widget:get()
        end
    end
    cfg.backstab = backstab:get()
    cfg.aspect_r = aspect_r:get()
    cfg.aspect_slider = aspect_slider:get()
    configs[selected_name] = cfg
    database.write("russia_1995", configs)
    database.flush()
    print("Config '" .. selected_name .. "' saved")
end

save:set_callback(save_button_func)

local function load_button_func()
    initialize_configs()
    local names = database.read("russia_1995")
    local configs = database.read("russia_1995")
    if #names == 0 then
        print("No configs to load")
        return
    end
    local selected_index = config_listbox:get() + 1
    if selected_index > #names then
        print("Invalid config selected")
        return
    end
    local selected_name = names[selected_index]
    local cfg = configs[selected_name]
    if not cfg then
        print("Config data not found")
        return
    end
    if cfg.state ~= nil then state_selector:override(cfg.state) end
    if cfg.aa ~= nil then
        for state, elems in pairs(builder) do
            if cfg.aa[state] ~= nil then
                for key, widget in pairs(elems) do
                    local v = cfg.aa[state][key]
                    if v ~= nil then
                        widget:override(v)
                    end
                end
            end
        end
    end
    if cfg.backstab ~= nil then backstab:override(cfg.backstab) end
    if cfg.aspect_r ~= nil then aspect_r:override(cfg.aspect_r) end
    if cfg.aspect_slider ~= nil then aspect_slider:override(cfg.aspect_slider) end
    print("Config '" .. selected_name .. "' loaded")
end

load:set_callback(load_button_func)

local function delete_button_func()
    initialize_configs()
    local names = database.read("russia_1995")
    local configs = database.read("russia_1995")
    if #names == 0 then
        print("No configs to delete")
        return
    end
    local selected_index = config_listbox:get() + 1
    if selected_index > #names then
        print("Invalid config selected")
        return
    end
    local selected_name = names[selected_index]
    if selected_name == "Default" then
        print("Cannot delete Default config")
        return
    end
    table.remove(names, selected_index)
    configs[selected_name] = nil
    database.write("russia_1995", configs)
    database.write("russia_1995", names)
    database.flush()
    refresh_config_list()
    --config_listbox:update(names)
    print("Config '" .. selected_name .. "' deleted")
end

delete:set_callback(delete_button_func)

--@defensive
last_commandnumber = 0
static = {
    tickbase_max = 0, 
    diff = 0,         
    defensive = false,
}

player = {
    shifting = 0,
    _shifting_enough = nil,
    choked = 0,
}

player.get_dt = function()
    return player._shifting_enough
end

local function toticks(t)
    return math.floor(0.5 + (t / globals.tickinterval()))
end

local lp = entity.get_local_player
local m_nTickBase = entity.get_prop(lp, 'm_nTickBase') or 0
local client_latency = client.latency()

player.run_command = function(cmd)
    local lp = entity.get_local_player
    if lp then
        local shift = math.floor(m_nTickBase - globals.tickcount() - 3 - toticks(client_latency) * 0.88 * (client_latency * 10))
        if math.abs(shift - (-1)) < math.abs(shift - (-15)) then
            shift = -1
        else
            shift = -15
        end
        local wanted = -14 + refs.aa.aimbot.dt_fakelag:get() - 1 + 3
        player.shifting = shift
        player._shifting_enough = shift <= wanted
    end
end

function update_defensive(cmd)
	local me = entity.get_local_player()
	local valid_entity = me and entity.is_alive(me)
	if not valid_entity then return end
    local can_exploit = refs.aa.aimbot.dt[1]:get() or refs.aa.other.hs:get() and not refs.aa.aimbot.fake_duck:get() and player.get_dt()
    if not can_exploit then static.defensive = false end
	local tickbase = entity.get_prop(me, "m_nTickBase") or 0
	if last_commandnumber == cmd.command_number then
		static.diff = tickbase - static.tickbase_max
		static.defensive = static.diff < -3
		if math.abs(static.diff) > 64 then
			static.tickbase_max = 0
		end
		static.tickbase_max = math.max(tickbase, static.tickbase_max or 0)
	end
	return static.defensive
end

function on_finish_command(cmd)
    local lp = entity.get_local_player()
	local valid_entity = lp and entity.is_alive(lp)
	if valid_entity then
        last_commandnumber = cmd.command_number
    end
end

local state = get_local_state()

local is_lcshka_slomana = static.defensive

client.set_event_callback("setup_command", function(cmd)
    ctx = builder[builder[state].enable_defensive:get() and state or "Shared"]
    pitch_mode = ctx.pitch_defensive:get()
    state = get_local_state()

    if ctx.enable_defensive:get() then
        refs.aa.angles.pitch[1]:override("Custom")
        if pitch_mode == "Custom" then
            refs.aa.angles.pitch[2]:override(ctx.custom_slider:get())
        elseif pitch_mode == "Sway" then
            local t = globals.curtime() * (ctx.sway_slider3:get() or 1)
            local val1 = ctx.sway_slider1:get()
            local val2 = ctx.sway_slider2:get()
            local sway = val1 + (val2 - val1) * (0.5 + 0.5 * math.sin(t))
            refs.aa.angles.pitch[2]:override(sway)
        elseif pitch_mode == "Switch" then
            local tick = globals.tickcount()
            local switch_val = (tick % 5 < 2) and ctx.switch_slider:get() or ctx.switch_slider2:get()
            refs.aa.angles.pitch[2]:override(switch_val)
        elseif pitch_mode == "All angle" then
            refs.aa.angles.pitch[2]:override(math.random(-89, 89))
        elseif pitch_mode == "Random" then
            refs.aa.angles.pitch[2]:override(math.random(ctx.random_slider:get(), ctx.random_slider2:get()))
        elseif pitch_mode == "Random switch" then
            local tick = globals.tickcount()
            local val = (tick % 20 < 10) and ctx.random_slider:get() or ctx.random_slider2:get()
            refs.aa.angles.pitch[2]:override(val)
        end
    end
end)

client.set_event_callback("setup_command", function(cmd)
if player.get_dt() and ctx.enable_defensive:get() then
     cmd.force_defensive = true
end
end)

client.set_event_callback('predict_command', function(cmd)
    update_defensive(cmd)
end)

client.set_event_callback("run_command", function(cmd)
    player.run_command(cmd)
end)