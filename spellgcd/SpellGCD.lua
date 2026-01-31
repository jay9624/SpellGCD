addon.name      = 'SpellGCD';
addon.author    = 'Jayy';
addon.version   = '1';
addon.desc      = 'Displays information about the players spell recast time.';

local imgui    = require('imgui');
local settings = require('settings');

-- Default settings
local default_settings = T{
    is_locked = true,
    setup_mode = true,
};
local aftercast_settings = settings.load(default_settings);

-- State variables
local is_active = false;
local start_time = 0;
local duration = 2.5;

ashita.events.register('unload', 'unload_cb', function ()
    settings.save();
end);

-- Action Packet Listener
ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x28) then
        local player = GetPlayerEntity();
        local userId = struct.unpack('I', e.data, 0x05 + 1);
        
        if (userId == player.ServerId) then
            local category = ashita.bits.unpack_be(e.data_raw, 82, 4);
            if (category == 4) then
                is_active = true;
                start_time = os.clock();
            end
        end
    end
end);

-- Render UI
ashita.events.register('d3d_present', 'present_cb', function ()
    if not is_active and not aftercast_settings.setup_mode then return end

    local progress = 1.0;
    if is_active then
        local elapsed = os.clock() - start_time;
        progress = elapsed / duration;
        if progress >= 1.0 then
            is_active = false;
            if not aftercast_settings.setup_mode then return end
        end
    end

    -- Flags for the cleanest look possible
    local flags = ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoBackground + ImGuiWindowFlags_NoDecoration;
    
    -- If NOT in setup mode, also disable mouse interaction and movement
    if not aftercast_settings.setup_mode then
        flags = flags + ImGuiWindowFlags_NoInputs + ImGuiWindowFlags_NoMove;
    end

    -- Strip all padding and borders
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 0, 0 });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0);

    if (imgui.Begin('RecastBar', true, flags)) then
        if aftercast_settings.setup_mode then
            imgui.TextColored({ 1.0, 0.5, 0.0, 1.0 }, 'DRAG ME - Setup Mode');
        end
        
        -- Customizing the bar: {Width, Height}
        imgui.ProgressBar(progress, { 200, 15 }, "");
        imgui.End();
    end
    
    imgui.PopStyleVar(2);
end);

-- Commands
ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args > 0 and args[1]:lower() == '/spellgcd') then
        if (#args > 1 and args[2]:lower() == 'setup') then
            aftercast_settings.setup_mode = not aftercast_settings.setup_mode;
            print('[AfterCast] Setup mode: ' .. tostring(aftercast_settings.setup_mode));
            return true;
        end
    end
    return false;
end);