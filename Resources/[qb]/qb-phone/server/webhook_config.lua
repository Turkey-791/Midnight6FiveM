Config = Config or {}

-- [SECURITY] This file is a server_script only (see fxmanifest.lua). Do NOT
-- move this webhook URL into config.lua or any other shared_script/
-- client_script: those are downloaded to every connecting player's client,
-- which is what exposed the previous webhook URL and led to the 2026-08-29
-- unauthorized Discord post incident.
--
-- The old webhook has already been deleted on Discord's side. Create a new
-- one (Discord channel -> Edit Channel -> Integrations -> Webhooks) and
-- paste its URL below before the camera feature will work again.
Config.serverwebhook = "https://discord.com/api/webhooks/1543234379634057286/Vl-Ue9RQ7iy8EMuwbARkYlDhMPT9vSoTs2fU9cSWhCAPkYXItGQO5WSzo5xow2FiI9LX?wait=true"
