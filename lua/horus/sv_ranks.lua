local config = horus.config.database
horus.ranks = horus.ranks or {}

-- Make sure that the 'user' and 'root' ranks always exist
horus.ranks['user'] = {isadmin = false, issuper = false}
horus.ranks['root'] = {isadmin = true, issuper = true}

-- Given a player or rank, check if the target has the given permission
-- This is a recursive function pls be careful
function horus:permission(target, perm)
    if type(target) == 'Player' then
        -- Get the rank of the player and check with that
        local rank = target:GetUserGroup()
        return horus:permission(rank, perm)
    elseif type(target) == 'string' then
        if target == 'root' then
            return true -- Root always has permission
        elseif !horus.ranks[target] then
            ErrorNoHalt('Invalid target in Horus permission check')
            return false
        else
            -- Check if the rank has permission for this
            if horus.ranks[target].perms then
                if horus.ranks[target].perms[perm] then return true end
            end

            -- Check rank inheritance
            if horus.ranks[horus.ranks[target].inherits] and target != 'user' then
                return horus:permission(horus.ranks[target].inherits, perm)
            end

            -- Doesn't have the permission and does not inherit any furhter
            return false
        end
    else
        ErrorNoHalt('Invalid target in Horus permission check')
        return false
    end
end

function horus:cantarget(caller, target)
    if type(target) == 'Player' then
        -- Use the rank of the target
        target = target:GetUserGroup()
    end

    if type(caller) == 'Player' then
        -- Run the function with the rank of the player
        local rank = caller:GetUserGroup()
        return horus:cantarget(rank, target)
    elseif type(target) == 'string' then
        if caller == 'root' then
            return true
        elseif !horus.ranks[target] or !horus.ranks[caller] then
            ErrorNoHalt('Invalid target in Horus permission check')
            return false
        else
            if caller == target then return true end    -- Players of the same rank can target each other
            if target == 'root' then return false end   -- Root cannot be targeted
            if caller == 'user' then return false end   -- Users are the bottom of the food chain

            -- Check down the hierarchy
            if horus.ranks[call].inherits == target then
                return true
            else
                return horus:cantarget(horus.ranks[caller].inherits, target)
            end
        end
    end
end

-- Return a table with every permission a given target has
-- This goes through inherited ranks
function horus:allperms(target)
    if type(target) == 'Player' then
        local rank = target:GetUsergroup()
        return horus:allperms(rank)
    elseif type(target) == 'string' then
        if target == 'root' then
            -- Root has all permissions
            return table.GetKeys(horus.commands)
        elseif !horus.ranks[target] then
            ErrorNoHalt('Invalid target in Horus permission check')
            return {}
        else
            -- Loop through this rank and all inherits to build the table
            if horus.ranks[horus.ranks[target].inherits] then
                return table.Add(horus.ranks[target].perms, horus:allperms(horus.ranks[target].inherits))
            else
                return horus.ranks[target].perms
            end
        end
    else
        ErrorNoHalt('Invalid target in Horus permission check')
        return {}
    end
end

-- Update the rank of a player
function horus:setrank(ply, rank)
    if !horus.ranks[rank] then return end
    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end

    -- TODO: Database sync

    ply:SetUserGroup(rank)
    horus:sendperms(ply, rank)
end

-- Send permissions info to clients
function horus:sendperms(ply, rank, isadmin, issuper)
    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end
    if ply:IsBot() then return end

    -- hi my name is Robert and I love edge cases
    local rank_table = {}
    if type(rank) == 'string' then
        rank_table = horus:allperms(rank)
    elseif type(rank) == 'table' then
        rank_table = rank
    end

    -- Not sure why these parameters are important
    if !isadmin or !issuper then
        isadmin = horus.ranks[rank].isadmin
        issuper = horus.ranks[rank].issuper
    end

    -- Build client ranks table if it doesn't already exist
    -- This is basically the server ranks table but with stripped out permissions
    -- The user knows their own permissions - they don't need to know other details
    local client_ranks = {}
    for k,v in pairs(horus.ranks) do
        client_ranks[k] = {}
        client_ranks[k].inherits = v.inherits or nil
        client_ranks[k].isadmin = v.isadmin or false
        client_ranks[k].issuper = v.issuper or false
    end

    -- Send all this information to the client
    net.Start('horus_sendperms')
        net.WriteTable(rank_table)
        net.WriteTable(client_ranks)
        net.WriteBool(isadmin)
        net.WriteBool(issuper)
    net.Send(ply)
end

-- Load ranks on player connection
hook.Add('PlayerInitialSpawn', 'Horus_SendRank', function(ply)
    if ply:IsListenServerHost() then
        ply:SetUserGroup('root')
        horus:sendperms(ply, 'root')
    else
        -- TODO: Database
        ply:SetUserGroup('user')
        horus:sendperms(ply, 'user')
    end
end)

-- On database connection, load all the rank data locally
hook.Add('HorusPostTables', 'Horus_LoadRanks', function()
    -- TODO: Database
end)

-- Remove default stuff
hook.Remove('PlayerInitialSpawn', 'PlayerAuthSpawn')