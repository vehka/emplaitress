local music = require("musicutil")
local mod = require 'core/mods'
local status, matrix = pcall(require, 'matrix/lib/matrix')
if not status then
    matrix = nil
end

local models = { "classic analog", "waveshaping", "fm", "formant", "harmonic", "wavetable", "chord", "speech", "swarm",
    "noise", "particle", "string", "modal", "kick", "snare", "hat" }

local style_opts = { "perc", "poly", "mono" }

local scale = music.generate_scale(12, "Major", 8)

local plaits_note = {}

local scale_names = {}
for i = 1, #music.SCALES do
    table.insert(scale_names, music.SCALES[i].name)
end

local function n(i, s)
    return "plaits_" .. s .. "_" .. i
end

local function add_plaits_params(i)
    params:add_group(n("group", i), "emplait voice " .. i, 24)
    params:hide(n("group", i))
    params:add_option(n(i, "style"), "style", style_opts, 1)
    params:set_action(n(i, "style"), function(s)
        if s == 1 then
            params:show(n(i, "trigger"))
            params:hide(n(i, "gate"))
            params:hide(n(i, "a"))
            params:hide(n(i, "d"))
            params:hide(n(i, "s"))
            params:hide(n(i, "r"))
            params:show(n(i, "decay"))
        elseif s == 2 or s == 3 then
            params:hide(n(i, "trigger"))
            params:show(n(i, "gate"))
            params:show(n(i, "a"))
            params:show(n(i, "d"))
            params:show(n(i, "s"))
            params:show(n(i, "r"))
            params:hide(n(i, "decay"))
        end
        if s == 3 then
            params:show(n(i, "slew"))
        else
            params:hide(n(i, "slew"))
        end
        _menu.rebuild_params()
        osc.send({ "localhost", 57120 }, "/emplaitress/stop_all", {})
    end)
    if matrix then
        matrix:defer_bang(n(i, "style"))
    end
    params:add_trigger(n(i, "trigger"), "trigger")
    params:add_binary(n(i, "gate"), "gate", "momentary", 0)
    params:add_number(n(i, "note"), "note", 12, 127, 36, function(p)
        return music.note_num_to_name(p:get(), true)
    end)

    params:add_option(n(i, "model"), "model", models, 14)
    params:add_control(n(i, "decay"), "decay", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "a"), "attack", controlspec.new(0.01, 5, "exp", 0, 0.05))
    params:add_control(n(i, "d"), "decay", controlspec.new(0.05, 5, "exp", 0, 0.5))
    params:add_control(n(i, "s"), "sustain", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "r"), "release", controlspec.new(0.01, 5, "exp", 0, 0.5))

    params:add_control(n(i, "harmonics"), "harmonics", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "timbre"), "timbre", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "morph"), "morph", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "amp"), "amp", controlspec.new(0, 1, "lin", 0, 0.2))
    params:add_control(n(i, "aux"), "aux mix", controlspec.new(0, 1, "lin", 0, 0))

    params:add_control(n(i, "fm_mod"), "fm env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "timb_mod"), "timbre env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "morph_mod"), "morph env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "lpg_color"), "lpg color", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "gain"), "gain", controlspec.new(0, 3, "lin", 0, 1))
    params:add_control(n(i, "pan"), "pan", controlspec.new(-1, 1, "lin", 0, 0))
    params:add_control(n(i, "slew"), "slew", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "send_a"), "send a", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "send_b"), "send b", controlspec.new(0, 1, "lin", 0, 0))


    params:set_action(n(i, "trigger"), function()
        local hz = music.note_num_to_freq(params:get(n(i, "note")))
        osc.send({ "localhost", 57120 }, "/emplaitress/perc", {
            music.freq_to_note_num(hz), --pitch
            params:get(n(i, "model")) - 1, --engine
            params:get(n(i, "harmonics")), --harm
            params:get(n(i, "timbre")), --timbre
            params:get(n(i, "morph")), --morph
            params:get(n(i, "fm_mod")), --fm_mod
            params:get(n(i, "timb_mod")), -- timb mod
            params:get(n(i, "morph_mod")), --morph mod
            params:get(n(i, "decay")), --decay
            params:get(n(i, "lpg_color")), --lpg_color
            params:get(n(i, "amp")), --mul
            params:get(n(i, "aux")), --aux_mix
            params:get(n(i, "gain")), -- post-plaits gain
            params:get(n(i, "pan")), -- pan
            params:get(n(i, "send_a")),
            params:get(n(i, "send_b"))
        })
    end)
    params:set_action(n(i, "gate"), function(g)
        local hz = music.note_num_to_freq(params:get(n(i, "note")))
        if g > 0 then
            if plaits_note[i] then
                osc.send({ "localhost", 57120 }, "/emplaitress/note_off", {
                    i - 1,
                    plaits_note[i],
                });
            end
            plaits_note[i] = params:get(n(i, "note"))
            osc.send({ "localhost", 57120 }, "/emplaitress/note_on", {
                i - 1, -- voice
                params:get(n(i, "note")), -- note
                music.freq_to_note_num(hz), --pitch
                params:get(n(i, "model")) - 1, --engine
                params:get(n(i, "harmonics")), --harm
                params:get(n(i, "timbre")), --timbre
                params:get(n(i, "morph")), --morph
                params:get(n(i, "fm_mod")), --fm_mod
                params:get(n(i, "timb_mod")), -- timb mod
                params:get(n(i, "morph_mod")), --morph mod
                params:get(n(i, "a")),
                params:get(n(i, "d")), --decay
                params:get(n(i, "s")),
                params:get(n(i, "r")),
                params:get(n(i, "lpg_color")), --lpg_color
                params:get(n(i, "amp")), --mul
                params:get(n(i, "aux")), --aux_mix
                params:get(n(i, "gain")), -- post-plaits gain
                params:get(n(i, "pan")), -- pan
                params:get(n(i, "send_a")),
                params:get(n(i, "send_b"))
            })
        else
            -- off
            if plaits_note[i] then
                osc.send({ "localhost", 57120 }, "/emplaitress/note_off", {
                    i - 1,
                    plaits_note[i],
                });
            end
        end
    end)
end

local function remap_note(note)
    local upper = music.note_num_to_freq(math.ceil(note%128))
    local lower = music.note_num_to_freq(math.floor(note%128))
    local portion = note % 1
    return (1 - portion) * lower + portion * upper
end

function add_plaits_player(i)
    local player = {
        timbre_modulation = 0,
    }

    function player:active()
        if self.name ~= nil then
            params:show(n("group", i))
            _menu.rebuild_params()
        end
    end

    function player:inactive()
        if self.name ~= nil then
            params:hide(n("group", i))
            _menu.rebuild_params()
        end
    end

    function player:stop_all()
        osc.send({ "localhost", 57120 }, "/emplaitress/stop_all", {})
    end

    function player:modulate(val)
        self.timbre_modulation = val
    end

    function player:set_slew(s)
        params:set(n(i, "slew"), s)
    end

    function player:describe()
        return {
            name = "emplait " .. i,
            supports_bend = false,
            supports_slew = (params:get(n(i, "style")) == 3),
            modulate_description = "timbre",
            note_mod_targets = { "amp", "timbre", "morph", "harmonics" }
        }
    end

    function player:pitch_bend(note, amount)
        if params:get(n(i, "style")) == 2 or (params:get(n(i, "style")) == 3
            and note == self.current_note) then
            osc.send({ "localhost", 57120 }, "/emplaitress/note_simple_mod", {
                i - 1,
                note,
                'pitch',
                note + amount, --pitch. Round trip through music lib for tuning mod support.
            })
        end
    end

    function player:modulate_note(note, key, value)
        if params:get(n(i, "style")) == 2 or (params:get(n(i, "style")) == 3
            and note == self.current_note) then
            local v = value
            if key == "harmonics" or key == "timbre" or key == "morph" then
                v = value + params:get(n(i, key))
                if key == "harmonics" then
                    key = "harm"
                end
            elseif key == "amp" then
                v = util.clamp(value^(3/2) * params:get(n(i, key)), 0.003, 1)
                key = "mul"
            end

            osc.send({ "localhost", 57120 }, "/emplaitress/note_simple_mod", {
                i - 1,
                note,
                key,
                v,
            })
        end
    end

    function player:note_on(note, vel, properties)
        if properties == nil then
            properties = {}
        end
        if params:get(n(i, "style")) == 1 then
            local prop_timbre = properties.timbre or 0
            local prop_morph = properties.morph or 0
            local prop_harmonics = properties.harmonics or 0
            osc.send({ "localhost", 57120 }, "/emplaitress/perc", {
                music.freq_to_note_num(music.note_num_to_freq(note%128)), --pitch. Round trip through music lib for tuning mod support.
                params:get(n(i, "model")) - 1, --engine
                params:get(n(i, "harmonics")) + prop_harmonics, --harm
                params:get(n(i, "timbre")) + self.timbre_modulation / 2 + prop_timbre, --timbre
                params:get(n(i, "morph")) + prop_morph, --morph
                params:get(n(i, "fm_mod")), --fm_mod
                params:get(n(i, "timb_mod")), -- timb mod
                params:get(n(i, "morph_mod")), --morph mod
                params:get(n(i, "decay")), --decay
                params:get(n(i, "lpg_color")), --lpg_color
                params:get(n(i, "amp")) * vel * vel, --mul
                params:get(n(i, "aux")), --aux_mix
                params:get(n(i, "gain")), -- post-plaits gain
                params:get(n(i, "pan")), -- pan
                params:get(n(i, "send_a")),
                params:get(n(i, "send_b"))
            })
        elseif params:get(n(i, "style")) == 2 then
            osc.send({ "localhost", 57120 }, "/emplaitress/note_on", {
                i - 1,
                note,
                music.freq_to_note_num(music.note_num_to_freq(note)), --pitch. Round trip through music lib for tuning mod support.
                params:get(n(i, "model")) - 1, --engine
                params:get(n(i, "harmonics")), --harm
                params:get(n(i, "timbre")) + self.timbre_modulation / 2, --timbre
                params:get(n(i, "morph")), --morph
                params:get(n(i, "fm_mod")), --fm_mod
                params:get(n(i, "timb_mod")), -- timb mod
                params:get(n(i, "morph_mod")), --morph mod
                params:get(n(i, "a")), --attack
                params:get(n(i, "d")), --decay
                params:get(n(i, "s")), --sustain
                params:get(n(i, "r")), --release
                params:get(n(i, "lpg_color")), --lpg_color
                params:get(n(i, "amp")) * vel * vel, --mul
                params:get(n(i, "aux")), --aux_mix
                params:get(n(i, "gain")), -- post-plaits gain
                params:get(n(i, "pan")), -- pan
                params:get(n(i, "send_a")),
                params:get(n(i, "send_b"))
            })
        elseif params:get(n(i, "style")) == 3 then
            if self.current_note then
                osc.send({ "localhost", 57120 }, "/emplaitress/note_mod", {
                    i - 1,
                    self.current_note,
                    note,
                    music.freq_to_note_num(music.note_num_to_freq(note%128)), --pitch. Round trip through music lib for tuning mod support.
                    params:get(n(i, "model")) - 1, --engine
                    params:get(n(i, "harmonics")), --harm
                    params:get(n(i, "timbre")) + self.timbre_modulation / 2, --timbre
                    params:get(n(i, "morph")), --morph
                    params:get(n(i, "fm_mod")), --fm_mod
                    params:get(n(i, "timb_mod")), -- timb mod
                    params:get(n(i, "morph_mod")), --morph mod
                    params:get(n(i, "a")), --attack
                    params:get(n(i, "d")), --decay
                    params:get(n(i, "s")), --sustain
                    params:get(n(i, "r")), --release
                    params:get(n(i, "lpg_color")), --lpg_color
                    params:get(n(i, "amp")) * vel * vel, --mul
                    params:get(n(i, "aux")), --aux_mix
                    params:get(n(i, "gain")), -- post-plaits gain
                    params:get(n(i, "pan")), -- pan
                    params:get(n(i, "slew")), -- pitch_lag
                    params:get(n(i, "send_a")),
                    params:get(n(i, "send_b"))
                })
                self.current_note = note
            else
                osc.send({ "localhost", 57120 }, "/emplaitress/note_on", {
                    i - 1,
                    note,
                    music.freq_to_note_num(music.note_num_to_freq(note%128)), --pitch. Round trip through music lib for tuning mod support.
                    params:get(n(i, "model")) - 1, --engine
                    params:get(n(i, "harmonics")), --harm
                    params:get(n(i, "timbre")) + self.timbre_modulation / 2, --timbre
                    params:get(n(i, "morph")), --morph
                    params:get(n(i, "fm_mod")), --fm_mod
                    params:get(n(i, "timb_mod")), -- timb mod
                    params:get(n(i, "morph_mod")), --morph mod
                    params:get(n(i, "a")), --attack
                    params:get(n(i, "d")), --decay
                    params:get(n(i, "s")), --sustain
                    params:get(n(i, "r")), --release
                    params:get(n(i, "lpg_color")), --lpg_color
                    params:get(n(i, "amp")) * vel * vel, --mul
                    params:get(n(i, "aux")), --aux_mix
                    params:get(n(i, "gain")), -- post-plaits gain
                    params:get(n(i, "pan")), -- pan
                    params:get(n(i, "slew")), -- pitch_lag
                    params:get(n(i, "send_a")),
                    params:get(n(i, "send_b"))
                })
                self.current_note = note
            end
        end
    end

    function player:note_off(note)
        -- pass, for perc.
        -- print("off", note)
        osc.send({ "localhost", 57120 }, "/emplaitress/note_off", { i - 1, note });
    end

    function player:add_params()
        add_plaits_params(i)
    end

    if note_players == nil then
        note_players = {}
    end
    note_players["emplait " .. i] = player
end

function pre_init()
    for v = 1, 4 do
        add_plaits_player(v)
    end
end

mod.hook.register("script_pre_init", "emplaitress pre init", pre_init)

mod.hook.register("script_post_cleanup", "emplaitress post cleanup", function()
    if not note_players then return end -- no script has run yet
    for v = 1,4 do
        local p = note_players["emplait " .. v]
        if p then
            p.stop_all()
        end
    end
end)

-- The Mutable Instruments UGens come from a tarball. sclang only sees new
-- classes and plugins when it starts, so a fresh install needs one more
-- restart; the installer screen offers it.
local MI_UGENS_URL = "https://github.com/schollz/oomph/releases/download/prereqs/"
    .. "mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz"

-- Everywhere else the plugin is built on the machine, against the installed
-- SuperCollider headers. Pinned, so everyone builds the same source.
local MI_UGENS_REPO = "https://github.com/v7b1/mi-UGens"
local MI_UGENS_REV = "10f6824f68ad63475f67dfe3fe5016e2d2634f84"

local function sc_include_dirs()
    local dirs = {}
    local prefix = os.getenv("PREFIX") -- termux
    if prefix and prefix ~= "" then
        dirs[#dirs + 1] = prefix .. "/include/SuperCollider"
    end
    dirs[#dirs + 1] = "/usr/local/include/SuperCollider"
    dirs[#dirs + 1] = "/usr/include/SuperCollider"
    return dirs
end

local function have_sc_headers()
    for _, dir in ipairs(sc_include_dirs()) do
        local f = io.open(dir .. "/plugin_interface/SC_PlugIn.h", "r")
        if f then
            f:close()
            return true
        end
    end
    return false
end

-- Only MiPlaits is built. The work folder is outside dust, where sclang would
-- compile the class files of the checkout as well. mi-UGens wants a
-- SuperCollider source tree; the installed headers under an `include` link
-- look the same to it.
local BUILD_MI_PLAITS = [[
set -e
work="$HOME/.cache/emplaitress"
src="$work/mi-UGens"
ext="$HOME/.local/share/SuperCollider/Extensions/mi-UGens"
inc=
for d in ]] .. table.concat(sc_include_dirs(), " ") .. [[; do
    if [ -f "$d/plugin_interface/SC_PlugIn.h" ]; then inc=$d; break; fi
done
if [ -z "$inc" ]; then echo "SuperCollider headers not found"; exit 1; fi
rm -rf "$work"
mkdir -p "$src" "$work/sc" "$work/wrap"
echo "fetching mi-UGens"
git init -q "$src"
git -C "$src" fetch -q --depth 1 ]] .. MI_UGENS_REPO .. " " .. MI_UGENS_REV .. [[

git -C "$src" checkout -q FETCH_HEAD
ln -s "$inc" "$work/sc/include"
{
    echo "cmake_minimum_required(VERSION 3.10)"
    echo "project(emplaitress_ugens CXX)"
    echo "set(CMAKE_CXX_STANDARD 17)"
    echo "set(CMAKE_CXX_STANDARD_REQUIRED ON)"
    echo "add_subdirectory($src/projects/MiPlaits MiPlaits)"
} > "$work/wrap/CMakeLists.txt"
cmake -S "$work/wrap" -B "$work/build" -DSC_PATH="$work/sc" -DCMAKE_BUILD_TYPE=Release
cmake --build "$work/build" -j "$(nproc 2>/dev/null || echo 2)"
mkdir -p "$ext/Classes"
cp "$work/build/MiPlaits/MiPlaits.so" "$ext/"
cp "$src/sc/Classes/MiPlaits.sc" "$ext/Classes/"
rm -rf "$work"
echo "installed in $ext"
]]

local deps = dofile(_path.code .. mod.this_name .. "/lib/deps.lua")
local mod_deps = deps.new { name = "emplaitress", dir = _path.data .. "emplaitress/deps" }
mod_deps:add {
    id = "build-tools",
    label = "build tools",
    why = "to build the Mutable UGens",
    check = { "git", "cmake", "make", "c++" },
    pkg = {
        apt = "git cmake make g++",
        pacman = "git cmake make gcc",
        dnf = "git cmake make gcc-c++",
        termux = "git cmake make clang",
    },
}
mod_deps:add {
    id = "sc-headers",
    label = "SuperCollider headers",
    why = "to build the Mutable UGens",
    check_fn = have_sc_headers,
    pkg = {
        apt = "supercollider-dev",
        pacman = "supercollider",
        dnf = "supercollider-devel",
        termux = "supercollider",
    },
}
mod_deps:add {
    id = "mi-ugens",
    label = "Mutable UGens",
    why = "Plaits synth engines",
    size = "3 MB",
    check_ugens = { "MiPlaits.sc" },
    restart = true,
    manual = "Build mi-UGens (github.com/v7b1/mi-UGens) into "
        .. "~/.local/share/SuperCollider/Extensions",
    install = {
        -- the prebuilt binaries are 32-bit ARM, i.e. norns and shields
        { when = { arch = "armv7l" }, steps = { {
            url = MI_UGENS_URL,
            sha256 = "9412622a99d703a4c5803c1568ca174d2607d60390c9313ad2762445051708ce",
            extract = "~/.local/share/SuperCollider/Extensions",
        } } },
        { needs = { "build-tools", "sc-headers" }, steps = { {
            cmd = BUILD_MI_PLAITS,
            step_label = "build MiPlaits (a few minutes)",
        } } },
    },
}

-- Once per boot: offer the install, or the restart if one is still pending.
local deps_checked = false
local function offer_deps()
    if deps_checked then return end
    deps_checked = true
    if #mod_deps:missing({ "mi-ugens" }) > 0 or mod_deps:restart_pending() then
        mod_deps:ensure({ "mi-ugens" })
    end
end

-- Normally after the first script has started (loading a script resets the
-- key/enc/redraw handlers, so the screen can't be taken earlier).
mod.hook.register("script_post_init", "emplaitress deps", offer_deps)

-- Other classes that need the same UGens (fx_grains uses MiClouds) can make
-- sclang fail to start. Then no script ever loads and norns calls
-- startup_status.timeout instead; this is the only place to show the installer.
local startup_timeout = _norns.startup_status.timeout
_norns.startup_status.timeout = function(...)
    startup_timeout(...)
    offer_deps()
end
