local Lang = {}

function LoadLocale(lang)
    local file = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. lang .. '.json')
    if file then
        Lang = json.decode(file)
        print("^2[INFO] Archivo de idioma cargado: locales/" .. lang .. ".json^0")
    else
        print("^1[ERROR] Archivo de idioma no encontrado: locales/" .. lang .. ".json^0")
    end
end

function _U(key, params)
    local text = Lang[key] or key
    if params then
        for k, v in pairs(params) do
            text = text:gsub('{' .. k .. '}', v)
        end
    end
    return text
end

return {
    LoadLocale = LoadLocale,
    _U = _U
}
