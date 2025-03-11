--[[
    Vignetter - Ein professioneller OBS-Lua-Script für Vignette-Effekte
    Entwickelt von TheGeekFreaks 2025
    
    Dieses Plugin bietet umfangreiche Anpassungsmöglichkeiten für Vignette-Effekte in OBS Studio:
    - Hochgradig anpassbarer Vignette-Effekt mit Steuerung von Intensität, Rundheit und Position
    - Mehrere Vignette-Formen (Oval, Rechteck, Diamant, Stern) mit anpassbaren Optionen
    - Farbsteuerung und verschiedene Überblendungsmodi (Normal, Multiply, Screen, Overlay)
    - Professionelle Voreinstellungen für verschiedene Stimmungen und kreative Effekte
    - Rotation und Formstärke-Einstellungen für kreative Effekte
    - Mehrsprachige Unterstützung (Deutsch, Englisch)
    
    Vereinfachte Version für bessere Kompatibilität mit der OBS-Lua-API
    
    Bei Problemen mit os_enumerate_files wurden bekannte Lokalisierungsdateien manuell geladen.
]]

obs = obslua
local bit = require("bit")
local description = "Vignetter fügt einen professionellen Vignette-Effekt zu OBS Studio hinzu mit umfangreichen Anpassungsoptionen, mehreren Formen und vordefinierten Voreinstellungen für kreative Effekte."

-- Eingebetteter HLSL-Shader-Code
local effect_code = [[
// Vignetter Effekt für OBS Studio
// Erstellt mit Cascade

uniform float inner_radius = 0.9;
uniform float outer_radius = 1.5;
uniform float opacity = 0.8;
uniform float3 vignette_color = { 0.0, 0.0, 0.0 };
uniform bool use_color = false;
uniform float center_x = 0.5;
uniform float center_y = 0.5;
uniform float aspect_ratio = 1.0;
uniform int blend_mode = 0;
uniform int shape_type = 0;
uniform float shape_strength = 1.0;
uniform float rotation = 0.0;

uniform float4x4 ViewProj;
uniform texture2d image;

sampler_state textureSampler {
    Filter    = Linear;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

struct VertDataIn {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};

struct VertDataOut {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};

VertDataOut VSDefault(VertDataIn v_in)
{
    VertDataOut vert_out;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    vert_out.uv  = v_in.uv;
    return vert_out;
}

// Hilfsfunktion für Rotation der UV-Koordinaten
float2 rotate_uv(float2 uv, float2 center, float angle)
{
    float2 centered_uv = uv - center;
    float s = sin(angle);
    float c = cos(angle);
    float2x2 rot_matrix = float2x2(c, -s, s, c);
    float2 rotated_uv = mul(centered_uv, rot_matrix);
    return rotated_uv + center;
}

// Berechnung der Form-spezifischen Distanz
float calculate_shape_distance(float2 uv, float2 center, float aspect, int shape, float angle)
{
    // Rotieren der UV-Koordinaten wenn nötig
    float2 rotated_uv = rotate_uv(uv, center, angle);
    
    // Skalieren der Koordinaten basierend auf dem Seitenverhältnis
    float2 scaled_uv = rotated_uv;
    scaled_uv.x = (rotated_uv.x - center.x) * aspect + center.x;
    
    // Normalisierte Koordinaten für die Distanzberechnung
    float xTrans = (scaled_uv.x - center.x) * 2.0;
    float yTrans = (center.y - scaled_uv.y) * 2.0;
    
    // Distanz berechnen basierend auf der Form
    float dist = 0.0;
    
    if (shape == 0) { // Oval
        // Einfache euklidische Distanz für Oval
        dist = sqrt(pow(xTrans, 2) + pow(yTrans, 2));
    }
    else if (shape == 1) { // Rechteck
        // Für Rechteck verwenden wir den max-Wert der Distanz in jeder Dimension
        float2 delta = abs(float2(xTrans, yTrans));
        dist = max(delta.x, delta.y) * shape_strength;
    }
    else if (shape == 2) { // Diamant
        // Für Diamant verwenden wir die Manhattan-Distanz
        float2 delta = abs(float2(xTrans, yTrans));
        dist = (delta.x + delta.y) * 0.7 * shape_strength; // Faktor 0.7 für bessere Kalibrierung
    }
    else if (shape == 3) { // Stern
        // Für Stern verwenden wir eine modifizierte Distanz
        float2 delta = abs(float2(xTrans, yTrans));
        float a = atan2(delta.y, delta.x) * 5.0; // 5 Zacken
        float r = length(delta);
        dist = r * (0.8 + 0.2 * sin(a)) * shape_strength; // Modulierte Distanz
    }
    
    return dist;
}

float4 PSVignette(VertDataOut v_in) : TARGET
{
    float4 c0 = image.Sample(textureSampler, v_in.uv);
    float2 center = float2(center_x, center_y);
    
    // Berechne die Form-spezifische Distanz
    float radius = calculate_shape_distance(v_in.uv, center, aspect_ratio, shape_type, rotation);
    
    // Vignette-Maske basierend auf dem Radius
    float subtraction = max(0, radius - inner_radius) / max((outer_radius - inner_radius), 0.01);
    float factor = 1.0 - subtraction;
    factor = clamp(factor, 0.0, 1.0);
    
    // Vertikale Dimension für optischen Effekt
    float PI = 3.1415926535897932384626433832795;
    float verticalDim = 0.5 + sin(v_in.uv.y * PI) * 0.9;
    
    // Ergebnis-Farbe
    float4 result;
    
    if (use_color) {
        // Vignette-Farbe
        float4 vignette_color4 = float4(vignette_color, 1.0);
        
        // Übergang zwischen Originalfarbe und Vignettenfarbe basierend auf dem Faktor
        float vignette_opacity = (1.0 - factor) * opacity;
        
        // Verschiedene Mischungsmodi
        if (blend_mode == 0) { // Normal
            result = lerp(c0, vignette_color4, vignette_opacity);
        } 
        else if (blend_mode == 1) { // Multiply
            float4 blend_color = lerp(float4(1.0, 1.0, 1.0, 1.0), vignette_color4, vignette_opacity);
            result = c0 * blend_color;
        }
        else if (blend_mode == 2) { // Screen
            float4 blend_color = lerp(float4(0.0, 0.0, 0.0, 0.0), vignette_color4, vignette_opacity);
            result = 1.0 - (1.0 - c0) * (1.0 - blend_color);
        }
        else if (blend_mode == 3) { // Overlay
            float4 blend_color = lerp(float4(0.5, 0.5, 0.5, 0.5), vignette_color4, vignette_opacity);
            result = c0 < 0.5 ? 2.0 * c0 * blend_color : 1.0 - 2.0 * (1.0 - c0) * (1.0 - blend_color);
        }
    } else {
        // Originale Verdunkelungsvignette
        float4 vignetColor = c0 * factor;
        vignetColor *= verticalDim;
        
        vignetColor *= opacity;
        float4 originalWithOpacity = c0 * (1.0 - opacity);
        
        result = originalWithOpacity + vignetColor;
    }
    
    return result;
}

technique Draw
{
    pass
    {
        vertex_shader = VSDefault(v_in);
        pixel_shader  = PSVignette(v_in);
    }
}
]]

-- Unterstützte Sprachen / Supported languages
local LANG_EN = 1
local LANG_DE = 2

-- Aktuelle Sprache / Current language
local current_lang = LANG_DE

-- Übersetzungen / Translations
local translations = {
    -- Deutsch
    [LANG_DE] = {
        script_description = "Fügt einen Vignette-Effekt-Filter hinzu",
        filter_name = "Vignetter",
        
        -- Parameter
        inner_radius = "Innerer Radius",
        inner_radius_desc = "Innerer Radius des Vignetteneffekts",
        outer_radius = "Äußerer Radius",
        outer_radius_desc = "Äußerer Radius des Vignetteneffekts (Bestimmt das Abfallen des Effekts)",
        opacity = "Deckkraft",
        opacity_desc = "Bestimmt die Intensität des Vignetteneffekts",
        
        -- Position
        position = "Position",
        center_x = "Zentrum X",
        center_y = "Zentrum Y",
        
        -- Form
        form = "Form",
        shape_type = "Form-Typ",
        shape_oval = "Oval",
        shape_rectangle = "Rechteck",
        shape_diamond = "Diamant",
        shape_star = "Stern",
        shape_strength = "Form-Stärke",
        rotation = "Rotation",
        aspect_ratio = "Seitenverhältnis",
        
        -- Farben
        vignette_color = "Vignettenfarbe",
        use_color = "Eigene Farbe verwenden",
        color_red = "Rot",
        color_green = "Grün",
        color_blue = "Blau",
        
        -- Mischungsmodus
        blend_mode = "Mischungsmodus",
        blend_normal = "Normal",
        blend_multiply = "Multiplizieren",
        blend_screen = "Screen",
        blend_overlay = "Overlay",
        
        -- Presets
        presets = "Voreinstellungen",
        preset_cinematic = "Kinematischer Look",
        preset_sepia = "Sepia-Ton",
        preset_oval = "Ovale Vignette",
        preset_dramatic = "Dramatischer Kontrast",
        preset_vintage = "Vintage Look",
        preset_horror = "Horror/Mystery",
        preset_dream = "Traum-Sequenz",
        preset_focus = "Fokus-Vignette",
        preset_glowing = "Leuchtende Ränder",
        preset_cyberpunk = "Cyberpunk",
        preset_split = "Split-Toning",
        preset_retro = "Retro-Gaming",
        preset_oldfilm = "Alter Film",
        preset_sunset = "Sonnenuntergang",
        preset_duotone = "Duotone",
        preset_neon = "Neon-Lichter",
        
        -- Info
        info = "Innerer Radius wird immer angezeigt, äußerer Radius bestimmt den Übergang",
        preview_texture_free = "Preview Texture freigeben, falls vorhanden",
        minimum_size_preview = "Mindestgröße für Vorschau setzen, falls Quelle keine Größe hat",
        
        -- Fehlermeldungen
        error_loading_effect = "Konnte Vignetter-Effekt nicht laden: ",
        
        -- Button zum Anwenden der Voreinstellung
        apply_preset = "Voreinstellung anwenden",
    },
    
    -- Englisch
    [LANG_EN] = {
        script_description = "Vignetter adds a professional vignette effect filter to OBS Studio with extensive customization options, multiple shapes and predefined presets for creative effects. This plugin offers a wide range of vignette effects with controls for intensity, roundness, position, color, and blend modes to enhance your streams and recordings.",
        filter_name = "Vignetter",
        
        -- Parameters
        inner_radius = "Inner Radius",
        inner_radius_desc = "Inner radius of the vignette effect",
        outer_radius = "Outer Radius",
        outer_radius_desc = "Outer radius of the vignette effect (determines the falloff)",
        opacity = "Opacity",
        opacity_desc = "Determines the intensity of the vignette effect",
        
        -- Position
        position = "Position",
        center_x = "Center X",
        center_y = "Center Y",
        
        -- Form
        form = "Shape",
        shape_type = "Shape Type",
        shape_oval = "Oval",
        shape_rectangle = "Rectangle",
        shape_diamond = "Diamond",
        shape_star = "Star",
        shape_strength = "Shape Strength",
        rotation = "Rotation",
        aspect_ratio = "Aspect Ratio",
        
        -- Colors
        vignette_color = "Vignette Color",
        use_color = "Use Custom Color",
        color_red = "Red",
        color_green = "Green",
        color_blue = "Blue",
        
        -- Blend Mode
        blend_mode = "Blend Mode",
        blend_normal = "Normal",
        blend_multiply = "Multiply",
        blend_screen = "Screen",
        blend_overlay = "Overlay",
        
        -- Presets
        presets = "Presets",
        preset_cinematic = "Cinematic Look",
        preset_sepia = "Sepia Tone",
        preset_oval = "Oval Vignette",
        preset_dramatic = "Dramatic Contrast",
        preset_vintage = "Vintage Look",
        preset_horror = "Horror/Mystery",
        preset_dream = "Dream Sequence",
        preset_focus = "Focus Vignette",
        preset_glowing = "Glowing Borders",
        preset_cyberpunk = "Cyberpunk",
        preset_split = "Split-Toning",
        preset_retro = "Retro Gaming",
        preset_oldfilm = "Old Film",
        preset_sunset = "Sunset",
        preset_duotone = "Duotone",
        preset_neon = "Neon Lights",
        
        -- Info
        info = "Inner radius is always visible, outer radius determines the transition",
        preview_texture_free = "Release preview texture if available",
        minimum_size_preview = "Set minimum preview size if source has no dimensions",
        
        -- Error messages
        error_loading_effect = "Could not load vignette effect: ",
        
        -- Button to apply preset
        apply_preset = "Apply Preset",
    }
}

-- Hilfsfunktion zum Abrufen von Übersetzungen / Helper function for retrieving translations
local function _(key)
    if translations[current_lang] and translations[current_lang][key] then
        return translations[current_lang][key]
    elseif translations[LANG_EN] and translations[LANG_EN][key] then
        -- Fallback auf Englisch / Fallback to English
        return translations[LANG_EN][key]
    else
        -- Wenn kein Eintrag gefunden, Key zurückgeben / If no entry found, return key
        return key
    end
end

-- Sprache erkennen / Detect language
local function detect_language()
    -- Standardmäßig Deutsch / Default to German
    current_lang = LANG_DE
    
    -- Versuche global_locale von OBS zu bekommen / Try to get global_locale from OBS
    local locale = obs.obs_get_locale()
    
    if locale then
        -- Englisch-sprechende Länder
        if locale:match("^en") then
            current_lang = LANG_EN
        -- Deutsch-sprechende Länder / German-speaking countries
        elseif locale:match("^de") then
            current_lang = LANG_DE
        end
    end
    
    -- Log-Ausgabe der erkannten Sprache / Log the detected language
    obs.blog(obs.LOG_INFO, "Detected language: " .. (current_lang == LANG_EN and "English" or "Deutsch"))
end

function script_description()
    return _("script_description")
end

function script_properties()
    -- Diese Funktion wird gelöscht und stattdessen durch den Code in source_info.get_properties ersetzt
    local props = obs.obs_properties_create()
    return props
end

function script_update(settings)
    -- Wird nicht benötigt
end

function script_defaults(settings)
    -- Wird nicht benötigt
end

function script_load(settings)
    -- Sprache erkennen / Detect language
    detect_language()
    
    -- Filter registrieren
    local source_info = {}
    source_info.id = "vignetter_filter"
    source_info.type = obs.OBS_SOURCE_TYPE_FILTER
    source_info.output_flags = bit.bor(
        obs.OBS_SOURCE_VIDEO,
        obs.OBS_SOURCE_CUSTOM_DRAW
    )

    source_info.get_name = function()
        return _("filter_name")
    end

    source_info.create = function(settings, source)
        local data = {}
        data.source = source
        data.effect = nil
        
        -- Standard-Größe setzen
        data.width = 0
        data.height = 0
        
        -- Parameter aus Einstellungen laden
        data.inner_radius = 0.9
        data.outer_radius = 1.5
        data.opacity = 0.8
        data.vignette_color_r = 0.0
        data.vignette_color_g = 0.0
        data.vignette_color_b = 0.0
        data.use_color = false
        data.center_x = 0.5
        data.center_y = 0.5
        data.aspect_ratio = 1.0
        data.blend_mode = 0
        data.shape_type = 0
        data.shape_strength = 1.0
        data.rotation = 0.0
        
        -- Größen für Vorschau und Rendering
        data.width = 0
        data.height = 0
        
        -- Effekt laden - jetzt direkt aus dem eingebetteten Code
        obs.obs_enter_graphics()
        data.effect = obs.gs_effect_create(effect_code, "vignetter_shader", nil)
        if data.effect == nil then
            obs.blog(obs.LOG_ERROR, _("error_loading_effect") .. "eingebetteter Shader-Code")
        end
        obs.obs_leave_graphics()
        
        -- Parameter laden
        if data.effect ~= nil then
            data.params = {}
            data.params.inner_radius = obs.gs_effect_get_param_by_name(data.effect, "inner_radius")
            data.params.outer_radius = obs.gs_effect_get_param_by_name(data.effect, "outer_radius")
            data.params.opacity = obs.gs_effect_get_param_by_name(data.effect, "opacity")
            data.params.vignette_color = obs.gs_effect_get_param_by_name(data.effect, "vignette_color")
            data.params.use_color = obs.gs_effect_get_param_by_name(data.effect, "use_color")
            data.params.center_x = obs.gs_effect_get_param_by_name(data.effect, "center_x")
            data.params.center_y = obs.gs_effect_get_param_by_name(data.effect, "center_y")
            data.params.aspect_ratio = obs.gs_effect_get_param_by_name(data.effect, "aspect_ratio")
            data.params.blend_mode = obs.gs_effect_get_param_by_name(data.effect, "blend_mode")
            data.params.shape_type = obs.gs_effect_get_param_by_name(data.effect, "shape_type")
            data.params.shape_strength = obs.gs_effect_get_param_by_name(data.effect, "shape_strength")
            data.params.rotation = obs.gs_effect_get_param_by_name(data.effect, "rotation")
            data.params.image = obs.gs_effect_get_param_by_name(data.effect, "image")
        end
        
        -- Einstellungen aktualisieren
        source_info.update(data, settings)
        
        return data
    end

    source_info.destroy = function(data)
        if data.effect ~= nil then
            obs.obs_enter_graphics()
            obs.gs_effect_destroy(data.effect)
            
            -- Preview Texture freigeben, falls vorhanden
            if data.preview_texture then
                obs.gs_texture_destroy(data.preview_texture)
                data.preview_texture = nil
            end
            
            obs.obs_leave_graphics()
            data.effect = nil
        end
    end

    -- Helper-Funktion für die Größenanpassung
    local function set_render_size(data)
        local target = obs.obs_filter_get_target(data.source)
        if target == nil then
            data.width, data.height = 0, 0
        else
            data.width = obs.obs_source_get_base_width(target)
            data.height = obs.obs_source_get_base_height(target)
        end
        
        -- Mindestgröße für Vorschau setzen, falls Quelle keine Größe hat
        if data.width == 0 or data.height == 0 then
            data.width = 200
            data.height = 200
        end
    end

    source_info.get_width = function(data)
        return data.width
    end

    source_info.get_height = function(data)
        return data.height
    end

    source_info.get_defaults = function(settings)
        obs.obs_data_set_default_double(settings, "inner_radius", 0.9)
        obs.obs_data_set_default_double(settings, "outer_radius", 1.5)
        obs.obs_data_set_default_double(settings, "opacity", 0.8)
        obs.obs_data_set_default_double(settings, "vignette_color_r", 0.0)
        obs.obs_data_set_default_double(settings, "vignette_color_g", 0.0)
        obs.obs_data_set_default_double(settings, "vignette_color_b", 0.0)
        obs.obs_data_set_default_bool(settings, "use_color", false)
        obs.obs_data_set_default_double(settings, "center_x", 0.5)
        obs.obs_data_set_default_double(settings, "center_y", 0.5)
        obs.obs_data_set_default_double(settings, "aspect_ratio", 1.0)
        obs.obs_data_set_default_int(settings, "blend_mode", 0)
        obs.obs_data_set_default_int(settings, "shape_type", 0)
        obs.obs_data_set_default_double(settings, "shape_strength", 1.0)
        obs.obs_data_set_default_double(settings, "rotation", 0.0)
    end

    source_info.update = function(data, settings)
        data.inner_radius = obs.obs_data_get_double(settings, "inner_radius")
        data.outer_radius = obs.obs_data_get_double(settings, "outer_radius")
        data.opacity = obs.obs_data_get_double(settings, "opacity")
        data.vignette_color_r = obs.obs_data_get_double(settings, "vignette_color_r")
        data.vignette_color_g = obs.obs_data_get_double(settings, "vignette_color_g")
        data.vignette_color_b = obs.obs_data_get_double(settings, "vignette_color_b")
        data.use_color = obs.obs_data_get_bool(settings, "use_color")
        data.center_x = obs.obs_data_get_double(settings, "center_x")
        data.center_y = obs.obs_data_get_double(settings, "center_y")
        data.aspect_ratio = obs.obs_data_get_double(settings, "aspect_ratio")
        data.blend_mode = obs.obs_data_get_int(settings, "blend_mode")
        data.shape_type = obs.obs_data_get_int(settings, "shape_type")
        data.shape_strength = obs.obs_data_get_double(settings, "shape_strength")
        data.rotation = obs.obs_data_get_double(settings, "rotation") * (3.14159265 / 180.0) -- Umrechnung von Grad in Radiant
        
        -- Größe aktualisieren
        set_render_size(data)
    end

    -- Funktion für Voreinstellungen
    local function apply_preset(data, preset_type)
        local settings = obs.obs_data_create()
        
        -- Je nach ausgewählter Voreinstellung die Parameter setzen
        if preset_type == "cinematic" then
            -- Kinematischer Look mit breiter Vignette
            obs.obs_data_set_double(settings, "inner_radius", 0.75)
            obs.obs_data_set_double(settings, "outer_radius", 1.8)
            obs.obs_data_set_double(settings, "opacity", 0.85)
            obs.obs_data_set_bool(settings, "use_color", false)
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "aspect_ratio", 1.3) -- Leicht breiteres Oval
            obs.obs_data_set_double(settings, "shape_strength", 1.0)
        
        elseif preset_type == "sepia" then
            -- Sepia-Ton
            obs.obs_data_set_double(settings, "inner_radius", 0.8)
            obs.obs_data_set_double(settings, "outer_radius", 2.0)
            obs.obs_data_set_double(settings, "opacity", 0.7)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.5)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.35)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.2)
            obs.obs_data_set_int(settings, "blend_mode", 1) -- Multiply
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
        
        elseif preset_type == "oval" then
            -- Ovales Format
            obs.obs_data_set_double(settings, "inner_radius", 0.85)
            obs.obs_data_set_double(settings, "outer_radius", 1.6)
            obs.obs_data_set_double(settings, "opacity", 0.75)
            obs.obs_data_set_double(settings, "aspect_ratio", 1.6) -- Starke Oval-Form
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
        
        -- Neue Presets
        elseif preset_type == "dramatic" then
            -- Dramatischer Kontrast - Starke Vignette mit hohem Kontrast
            obs.obs_data_set_double(settings, "inner_radius", 0.65)
            obs.obs_data_set_double(settings, "outer_radius", 1.3)
            obs.obs_data_set_double(settings, "opacity", 0.95)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.0)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.0)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.02) -- Leicht bläulich
            obs.obs_data_set_int(settings, "blend_mode", 1) -- Multiply
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 1.2) -- Etwas stärkere Form
        
        elseif preset_type == "vintage" then
            -- Vintage Look - Leicht abgeschwächte Farben mit subtiler Sepia-Vignette
            obs.obs_data_set_double(settings, "inner_radius", 0.8)
            obs.obs_data_set_double(settings, "outer_radius", 2.2)
            obs.obs_data_set_double(settings, "opacity", 0.65)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.4)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.25)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.1)
            obs.obs_data_set_int(settings, "blend_mode", 3) -- Overlay
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 0.9) -- Leicht weichere Form
        
        elseif preset_type == "horror" then
            -- Horror/Mystery - Dunkle, starke Vignette mit einem leichten Blaustich
            obs.obs_data_set_double(settings, "inner_radius", 0.6)
            obs.obs_data_set_double(settings, "outer_radius", 1.4)
            obs.obs_data_set_double(settings, "opacity", 0.9)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.02)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.05)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.15)
            obs.obs_data_set_int(settings, "blend_mode", 1) -- Multiply
            obs.obs_data_set_int(settings, "shape_type", 1) -- Rechteck
            obs.obs_data_set_double(settings, "shape_strength", 1.3) -- Stärkere Form
        
        elseif preset_type == "dream" then
            -- Traum-Sequenz - Weiche Vignette mit leichtem Weißstich
            obs.obs_data_set_double(settings, "inner_radius", 0.7)
            obs.obs_data_set_double(settings, "outer_radius", 2.5)
            obs.obs_data_set_double(settings, "opacity", 0.5)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.9)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.9)
            obs.obs_data_set_double(settings, "vignette_color_b", 1.0)
            obs.obs_data_set_int(settings, "blend_mode", 2) -- Screen
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 0.8) -- Sehr weiche Form
        
        elseif preset_type == "focus" then
            -- Fokus-Vignette - Sehr enger innerer Radius für Fokussierung
            obs.obs_data_set_double(settings, "inner_radius", 0.3)
            obs.obs_data_set_double(settings, "outer_radius", 0.8)
            obs.obs_data_set_double(settings, "opacity", 0.85)
            obs.obs_data_set_bool(settings, "use_color", false)
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 1.5) -- Sehr scharfer Übergang
        
        -- Kreative Presets
        elseif preset_type == "glowing" then
            -- Leuchtende Ränder - Inverser Vignette-Effekt mit leuchtenden Farben
            obs.obs_data_set_double(settings, "inner_radius", 0.6)
            obs.obs_data_set_double(settings, "outer_radius", 1.5)
            obs.obs_data_set_double(settings, "opacity", 0.7)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.9)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.7)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.3)
            obs.obs_data_set_int(settings, "blend_mode", 2) -- Screen
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 1.2)
            obs.obs_data_set_double(settings, "aspect_ratio", 1.0)
        
        elseif preset_type == "cyberpunk" then
            -- Cyberpunk - Futuristischer Look mit intensiven Blautönen
            obs.obs_data_set_double(settings, "inner_radius", 0.5)
            obs.obs_data_set_double(settings, "outer_radius", 1.8)
            obs.obs_data_set_double(settings, "opacity", 0.8)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.0)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.5)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.9)
            obs.obs_data_set_int(settings, "blend_mode", 3) -- Overlay
            obs.obs_data_set_int(settings, "shape_type", 1) -- Rechteck
            obs.obs_data_set_double(settings, "shape_strength", 1.5)
            obs.obs_data_set_double(settings, "rotation", 30.0) -- Leichte Rotation
            obs.obs_data_set_double(settings, "aspect_ratio", 1.2)
        
        elseif preset_type == "split" then
            -- Split-Toning - Effekt mit Farbverlauf für kreative Stimmung
            obs.obs_data_set_double(settings, "inner_radius", 0.1)
            obs.obs_data_set_double(settings, "outer_radius", 1.2)
            obs.obs_data_set_double(settings, "opacity", 0.6)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.8)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.3)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.1)
            obs.obs_data_set_int(settings, "blend_mode", 2) -- Screen
            obs.obs_data_set_int(settings, "shape_type", 2) -- Diamant
            obs.obs_data_set_double(settings, "shape_strength", 1.7)
            obs.obs_data_set_double(settings, "rotation", 45.0) -- Diagonale Ausrichtung
            obs.obs_data_set_double(settings, "aspect_ratio", 1.0)
        
        elseif preset_type == "retro" then
            -- Retro-Gaming - Pixeliger Look mit Stern-Form
            obs.obs_data_set_double(settings, "inner_radius", 0.6)
            obs.obs_data_set_double(settings, "outer_radius", 1.0)
            obs.obs_data_set_double(settings, "opacity", 0.75)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.4)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.0)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.4)
            obs.obs_data_set_int(settings, "blend_mode", 1) -- Multiply
            obs.obs_data_set_int(settings, "shape_type", 3) -- Stern
            obs.obs_data_set_double(settings, "shape_strength", 1.8)
            obs.obs_data_set_double(settings, "rotation", 15.0)
            obs.obs_data_set_double(settings, "aspect_ratio", 1.05)
            
        elseif preset_type == "oldfilm" then
            -- Alter Film - Vintage-Filmlook mit starker Randabdunklung
            obs.obs_data_set_double(settings, "inner_radius", 0.4)
            obs.obs_data_set_double(settings, "outer_radius", 1.5)
            obs.obs_data_set_double(settings, "opacity", 0.9)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.1)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.08)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.05)
            obs.obs_data_set_int(settings, "blend_mode", 1) -- Multiply
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 1.0)
            obs.obs_data_set_double(settings, "aspect_ratio", 0.9) -- Leicht gestreckt
            
        elseif preset_type == "sunset" then
            -- Sonnenuntergang - Warme Töne mit sanftem Übergang
            obs.obs_data_set_double(settings, "inner_radius", 0.8)
            obs.obs_data_set_double(settings, "outer_radius", 2.0)
            obs.obs_data_set_double(settings, "opacity", 0.65)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.95)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.5)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.2)
            obs.obs_data_set_int(settings, "blend_mode", 2) -- Screen
            obs.obs_data_set_int(settings, "shape_type", 0) -- Oval
            obs.obs_data_set_double(settings, "shape_strength", 1.2)
            obs.obs_data_set_double(settings, "aspect_ratio", 1.6) -- Sehr breit für Sonnenuntergangseffekt
            
        elseif preset_type == "duotone" then
            -- Duotone - Zweifarbiger Effekt mit starkem Kontrast
            obs.obs_data_set_double(settings, "inner_radius", 0.2)
            obs.obs_data_set_double(settings, "outer_radius", 1.0)
            obs.obs_data_set_double(settings, "opacity", 0.8)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.1)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.5)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.7)
            obs.obs_data_set_int(settings, "blend_mode", 3) -- Overlay
            obs.obs_data_set_int(settings, "shape_type", 2) -- Diamant
            obs.obs_data_set_double(settings, "shape_strength", 1.4)
            obs.obs_data_set_double(settings, "rotation", 0.0)
            obs.obs_data_set_double(settings, "aspect_ratio", 1.0)
            
        elseif preset_type == "neon" then
            -- Neon-Lichter - Lebendige, leuchtende Farben für einen Club-Look
            obs.obs_data_set_double(settings, "inner_radius", 0.5)
            obs.obs_data_set_double(settings, "outer_radius", 1.2)
            obs.obs_data_set_double(settings, "opacity", 0.7)
            obs.obs_data_set_bool(settings, "use_color", true)
            obs.obs_data_set_double(settings, "vignette_color_r", 0.9)
            obs.obs_data_set_double(settings, "vignette_color_g", 0.1)
            obs.obs_data_set_double(settings, "vignette_color_b", 0.9)
            obs.obs_data_set_int(settings, "blend_mode", 2) -- Screen
            obs.obs_data_set_int(settings, "shape_type", 1) -- Rechteck
            obs.obs_data_set_double(settings, "shape_strength", 1.6)
            obs.obs_data_set_double(settings, "rotation", 45.0) -- Diagonale Ausrichtung
            obs.obs_data_set_double(settings, "aspect_ratio", 1.0)
        end
        
        -- Einstellungen aktualisieren
        source_info.update(data, settings)
        obs.obs_source_update(data.source, settings)
        obs.obs_data_release(settings)
        return true
    end

    source_info.get_properties = function(data)
        local props = obs.obs_properties_create()
        
        -- Dropdown-Menü für Presets mit automatischer Anwendung
        local preset_list = obs.obs_properties_add_list(props, "preset_selection", _("presets"), 
                                         obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
                                         
        -- Füge alle Presets zum Dropdown hinzu
        obs.obs_property_list_add_string(preset_list, _("preset_cinematic"), "cinematic")
        obs.obs_property_list_add_string(preset_list, _("preset_sepia"), "sepia")
        obs.obs_property_list_add_string(preset_list, _("preset_oval"), "oval")
        obs.obs_property_list_add_string(preset_list, _("preset_dramatic"), "dramatic")
        obs.obs_property_list_add_string(preset_list, _("preset_vintage"), "vintage")
        obs.obs_property_list_add_string(preset_list, _("preset_horror"), "horror")
        obs.obs_property_list_add_string(preset_list, _("preset_dream"), "dream")
        obs.obs_property_list_add_string(preset_list, _("preset_focus"), "focus")
        obs.obs_property_list_add_string(preset_list, _("preset_glowing"), "glowing")
        obs.obs_property_list_add_string(preset_list, _("preset_cyberpunk"), "cyberpunk")
        obs.obs_property_list_add_string(preset_list, _("preset_split"), "split")
        obs.obs_property_list_add_string(preset_list, _("preset_retro"), "retro")
        obs.obs_property_list_add_string(preset_list, _("preset_oldfilm"), "oldfilm")
        obs.obs_property_list_add_string(preset_list, _("preset_sunset"), "sunset")
        obs.obs_property_list_add_string(preset_list, _("preset_duotone"), "duotone")
        obs.obs_property_list_add_string(preset_list, _("preset_neon"), "neon")
        
        -- Setze einen Callback für die Dropdown-Liste, um Presets automatisch anzuwenden
        obs.obs_property_set_modified_callback(preset_list, function(props, property, settings)
            local preset = obs.obs_data_get_string(settings, "preset_selection")
            apply_preset(data, preset)
            return true
        end)
        
        -- Grundlegende Parameter
        local p = obs.obs_properties_add_float_slider(props, "inner_radius", _("inner_radius"), 0.0, 5.0, 0.001)
        obs.obs_property_set_long_description(p, _("inner_radius_desc"))

        p = obs.obs_properties_add_float_slider(props, "outer_radius", _("outer_radius"), 0.0, 5.0, 0.001)
        obs.obs_property_set_long_description(p, _("outer_radius_desc"))

        p = obs.obs_properties_add_float_slider(props, "opacity", _("opacity"), 0.0, 1.0, 0.001)
        obs.obs_property_set_long_description(p, _("opacity_desc"))
        
        -- Position der Vignette
        local position_group = obs.obs_properties_create()
        obs.obs_properties_add_float_slider(position_group, "center_x", _("center_x"), 0.0, 1.0, 0.01)
        obs.obs_properties_add_float_slider(position_group, "center_y", _("center_y"), 0.0, 1.0, 0.01)
        obs.obs_properties_add_group(props, "position_group", _("position"), obs.OBS_GROUP_NORMAL, position_group)
        
        -- Form der Vignette
        local shape_group = obs.obs_properties_create()
        local p = obs.obs_properties_add_list(shape_group, "shape_type", _("shape_type"), obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
        obs.obs_property_list_add_int(p, _("shape_oval"), 0)
        obs.obs_property_list_add_int(p, _("shape_rectangle"), 1)
        obs.obs_property_list_add_int(p, _("shape_diamond"), 2)
        obs.obs_property_list_add_int(p, _("shape_star"), 3)
        
        obs.obs_properties_add_float_slider(shape_group, "shape_strength", _("shape_strength"), 0.5, 2.0, 0.01)
        obs.obs_properties_add_float_slider(shape_group, "rotation", _("rotation"), 0.0, 360.0, 1.0)
        obs.obs_properties_add_float_slider(shape_group, "aspect_ratio", _("aspect_ratio"), 0.5, 2.0, 0.01)
        obs.obs_properties_add_group(props, "shape_group", _("form"), obs.OBS_GROUP_NORMAL, shape_group)
        
        -- Farb-Parameter
        local color_group = obs.obs_properties_create()
        obs.obs_properties_add_bool(color_group, "use_color", _("use_color"))
        obs.obs_properties_add_float_slider(color_group, "vignette_color_r", _("color_red"), 0.0, 1.0, 0.01)
        obs.obs_properties_add_float_slider(color_group, "vignette_color_g", _("color_green"), 0.0, 1.0, 0.01)
        obs.obs_properties_add_float_slider(color_group, "vignette_color_b", _("color_blue"), 0.0, 1.0, 0.01)
        obs.obs_properties_add_group(props, "color_group", _("vignette_color"), obs.OBS_GROUP_NORMAL, color_group)
        
        -- Mischungsmodus
        local p = obs.obs_properties_add_list(props, "blend_mode", _("blend_mode"), obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
        obs.obs_property_list_add_int(p, _("blend_normal"), 0)
        obs.obs_property_list_add_int(p, _("blend_multiply"), 1)
        obs.obs_property_list_add_int(p, _("blend_screen"), 2)
        obs.obs_property_list_add_int(p, _("blend_overlay"), 3)

        -- Info-Text
        p = obs.obs_properties_add_text(props, "info", _("info"), obs.OBS_TEXT_INFO)
        
        return props
    end

    -- Shader-Parameter setzen
    local function set_shader_params(data)
        if data.params.inner_radius then
            obs.gs_effect_set_float(data.params.inner_radius, data.inner_radius)
        end
        if data.params.outer_radius then
            obs.gs_effect_set_float(data.params.outer_radius, data.outer_radius)
        end
        if data.params.opacity then
            obs.gs_effect_set_float(data.params.opacity, data.opacity)
        end
        if data.params.vignette_color then
            local vec3 = obs.vec3()
            vec3.x = data.vignette_color_r
            vec3.y = data.vignette_color_g
            vec3.z = data.vignette_color_b
            obs.gs_effect_set_vec3(data.params.vignette_color, vec3)
        end
        if data.params.use_color then
            obs.gs_effect_set_bool(data.params.use_color, data.use_color)
        end
        if data.params.center_x then
            obs.gs_effect_set_float(data.params.center_x, data.center_x)
        end
        if data.params.center_y then
            obs.gs_effect_set_float(data.params.center_y, data.center_y)
        end
        if data.params.aspect_ratio then
            obs.gs_effect_set_float(data.params.aspect_ratio, data.aspect_ratio)
        end
        if data.params.blend_mode then
            obs.gs_effect_set_int(data.params.blend_mode, data.blend_mode)
        end
        if data.params.shape_type then
            obs.gs_effect_set_int(data.params.shape_type, data.shape_type)
        end
        if data.params.shape_strength then
            obs.gs_effect_set_float(data.params.shape_strength, data.shape_strength)
        end
        if data.params.rotation then
            obs.gs_effect_set_float(data.params.rotation, data.rotation)
        end
    end

    source_info.video_render = function(data, effect)
        if not data.effect then
            return
        end
        
        local parent = obs.obs_filter_get_parent(data.source)
        if not parent then
            return
        end
        
        -- Die Textur des darunterliegenden Source holen
        local target = obs.obs_filter_get_target(data.source)
        local target_width = obs.obs_source_get_base_width(target)
        local target_height = obs.obs_source_get_base_height(target)
        
        if target_width == 0 or target_height == 0 then
            return
        end
        
        -- GPU-Kontext betreten
        obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
        
        -- Parameter an den Shader übergeben
        set_shader_params(data)
        
        -- Effekt anwenden
        obs.obs_source_process_filter_end(data.source, data.effect, target_width, target_height)
    end

    source_info.video_tick = function(data, seconds)
        -- Aktualisiere die Größe des Filters
        set_render_size(data)
    end
    
    source_info.video_render_preview = function(data)
        -- Überprüfe, ob die Daten richtig sind
        if not data.effect then
            return
        end
        
        local width, height = data.width, data.height
        if width == 0 or height == 0 then
            width, height = 200, 200
        end
        
        -- Für die Vorschau werden wir direkt zeichnen
        local tech = obs.gs_effect_get_technique(data.effect, "Draw")
        if not tech then
            return
        end
        
        -- Schwarzer Hintergrund für die Vorschau
        obs.gs_clear(obs.GS_CLEAR_COLOR, obs.vec4_from_rgba(0, 0, 0, 255), 1.0, 0)
        
        -- Erstelle eine temporäre Vorschau-Textur, wenn nötig
        if not data.preview_texture then
            obs.obs_enter_graphics()
            data.preview_texture = obs.gs_texture_create(width, height, obs.GS_RGBA, 1, nil, obs.GS_TEXTURE_2D)
            obs.obs_leave_graphics()
        end
        
        -- Setze alle Shader-Parameter
        set_shader_params(data)
        
        -- Setze die Textur, falls vorhanden
        if data.params.image and data.preview_texture then
            obs.gs_effect_set_texture(data.params.image, data.preview_texture)
        end
        
        -- Zeichne die Vorschau
        obs.gs_technique_begin(tech)
        obs.gs_technique_begin_pass(tech, 0)
        
        obs.gs_draw_sprite(nil, 0, width, height)
        
        obs.gs_technique_end_pass(tech)
        obs.gs_technique_end(tech)
    end

    obs.obs_register_source(source_info)
end

function script_unload()
    -- Nichts zu tun
end
