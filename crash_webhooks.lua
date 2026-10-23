-- Adapted from ivy real_niacat's code

CrashHooks = SMODS.current_mod or {}

--#region So people can copy this file into their mod mostly unaltered, if they want to do that. (Not recommended, seems more likely to be kind of annoying than provide any kind of benefits over just running this mod in your dev environment. But I would like it to work if someone wants to try it.)
--If you do want to get rid of this, you should have like, 102 level understanding of global tables in Lua at minimum.
local this_mod = CrashHooks --Change CrashHooks here to your mod's global table if you're copying the file.
this_mod = this_mod or SMODS.current_mod --Fallback for people who can't read the comment above this one.
local say = this_mod.say or function (msg)
    print(msg)
end
--#endregion

say("Loading crash messages...", "TRACE")

local http = require("SMODS.https")
local json = require("json")

this_mod.config.modder_names = this_mod.config.modder_names or {}

local excluded = {

}
--Automatically writes webhook file names to .git/info/exclude; probably not actually needed rn since the files end up going in the %appdata% folder, but I might make them go a less silly place in future.
local function write_exclude_entry(mod_id)
    mod_id = mod_id or this_mod.id
    local gitfolder = SMODS.Mods[mod_id].path..".git/" --Change this if your git folder is in a weird place
    local exclude_file_path = gitfolder.."info/exclude"
    local exclude_entry = "*webhooks.txt"
    local gitfolderdata = NFS.getDirectoryItems(gitfolder)
    if gitfolderdata and next(gitfolderdata) then
        for line in NFS.lines(exclude_file_path) do
            if line == exclude_entry then
                excluded[mod_id] = true
                break
            end
        end
        if not excluded[mod_id] then
            NFS.write(exclude_file_path, NFS.read(exclude_file_path).."\n"..exclude_entry)
            excluded[mod_id] = true
        end
    else
        print".git folder isn't in the expected area, you're on your own."
    end
end


this_mod.add_modder_names = function (mod)
    if not (mod and SMODS.Mods[mod]) then
        print"Pass a valid mod ID!"
        return
    end

    for i, v in ipairs(SMODS.Mods[mod].author) do
        this_mod.config.modder_names[v] = true
    end
    SMODS.save_all_config()
end
this_mod.reset_modder_names = function ()
    this_mod.config.modder_names = {}
    SMODS.save_all_config()
end
this_mod.set_default_author= function (name)
    if not name then print"Pass your name as the argument!";return end
    this_mod.config.default_author = name
    SMODS.save_all_config()
end

local function send_that_webhook(msg, target) --Designed for Discord webhooks. If you know what you're doing, you can edit this to interact with other webhooks instead.
    local data = {
        method = "POST",
        data = json.encode{content = msg},
        headers = {
            ["Content-Type"] = "application/json"
        }
    }
    if http then
        return http.request(target, data)
    else
        print("Oops! No HTTP! Don't worry, your good old buddy print has this covered:")
        print(msg)
        return
    end
end

function this_mod.webhook_test(mod, msg)
    mod = mod or "testmod"
    msg = msg or "Testing that webhook!"
    local webhook_list = this_mod.read_hook_file(mod)
    if webhook_list then
        for url, datamsg in pairs(webhook_list) do
            print("Found: ", url, datamsg)
            print(send_that_webhook(msg, url))
        end
    end
end

--Don't edit this text here. To be clear. Create the file, then edit the text in the file.
local unedited_text = "After creating the webhook file, replace this text inside it with a return-separated list of webhook URLs.\nThey may (optionally) be followed by a pipe symbol | and a custom message.\nUse #modname# to substitute in the mod's name, #errmsg# for the error that crashed the game, and #crashcount# for the number of times crashed so far."

function this_mod.creat_hook_file(modname)
    NFS.write(modname.."_webhooks.txt", unedited_text)
end

local default_msg = "Looks like #modname# crashed again! This makes #crashcount# times since we started tracking!"

function this_mod.read_hook_file(modname)
    local data = NFS.read(modname.."_webhooks.txt")
    local all_webhooks = {}
    if data and data ~= unedited_text then
        for line in NFS.lines(modname.."_webhooks.txt") do
            local url, msg
            local parts = {}
            for part in string.gmatch(line, "[^|]+") do
                local realpart = part
                while realpart:sub(1,1):find("%s") do
                    realpart = realpart:sub(2)
                end
                while realpart:sub(#realpart):find("%s") do
                    realpart = realpart:sub(1, #realpart-1)
                end

                parts[#parts+1] = realpart
            end
            if #parts == 2 then
                url, msg = parts[1], parts[2]
            else
                url = line
                msg = default_msg
            end
            all_webhooks[url] = msg
        end
    else
        local errmsg = "Nope!" .. (data == unedited_text and " You gotta put the URLS in the file first!" or "")
        say(errmsg, "WARN ")
        return
    end
    return all_webhooks
end

local default_author = this_mod.config.default_author

function this_mod.creat_all_hook_files(author)
    author = author or default_author

    for k,v in pairs(SMODS.Mods) do
        local is_for_me = false
        for _,modder in ipairs(v.author or {}) do
            if modder == author then
                is_for_me = true
                break
            end
        end

        if is_for_me and not NFS.read(k.."_webhooks.txt") then
            print("Creating webhook file for mod "..k)
            write_exclude_entry(k)
            if not excluded[k] then
                print"!!!"
                print"!!!"
                print"!!!"
                print("CAUTION! Unable to find or create an entry in .git/info/exclude for mod "..k.."!\nPlease ensure, by whichever means you have available, that you don't make this file public by mistake.")
                print"!!!"
                print"!!!"
                print"!!!"
            end
            this_mod.creat_hook_file(k)
        end
    end
end

local loveerrorhandler = love.errorhandler
love.errorhandler = function (msg)
    --print("Value passed to love error handler is: ", msg)

    --Todo, get mod id out of msg and do something with it? They come in the form "[SMODS testmod "main.lua"]:93: Yeah, lemme just check if I'm playing the deck that crashes the game when you start it - aw, fuck."
    --Ideally, figure out if specifically the mod that crashed has a webhook, instead of iterating through all of them? Currently this isn't 100% reliable though, crashes from using vanilla or SMODS functions wrong will often be blamed on vanilla or SMODS instead of the mod that did it.
    for k,v in pairs(SMODS.Mods) do
        local is_for_me = false
        local modname = v.name or k
        for _,modder in ipairs(v.author or {}) do
            if this_mod.config.modder_names[modder] then
                is_for_me = true
                break
            end
        end

        if v.can_load and is_for_me and love.filesystem.exists(k.."_webhooks.txt") then
            local webhook_list = this_mod.read_hook_file(k)
            if webhook_list then
                local crashcount_filename = k.."_crashes.txt"
                local crash_count = tonumber(love.filesystem.read(crashcount_filename) or 0)
                crash_count = crash_count + 1
                love.filesystem.write(crashcount_filename, tostring(crash_count))

                for url,webmsg in pairs(webhook_list) do
                    webmsg = webmsg:gsub("#modname#", modname):gsub("#crashcount#", crash_count):gsub("#errmsg#", msg)

                    send_that_webhook(webmsg, url)
                end
            end
        end
    end

    return loveerrorhandler(msg)
end

SMODS.Back{
    key = "crashonpurpose",
    loc_txt = {
        name = "Crashing Deck",
        text = {
            "Deck that crashes the",
            "game when you start it"
        }
    },
    apply = function (self, back)
        error("Yeah, lemme just check if I'm playing the deck that crashes the game when you start it - aw, fuck.")
    end
}