-- mysql-compat.lua
-- Create compatibility layer for older MySQL syntax

-- Create MySQL namespace if it doesn't exist
if not MySQL then
    MySQL = {}
end

-- Create Sync and Async namespaces
MySQL.Sync = {}
MySQL.Async = {}

-- Create Sync methods that use the new exports
MySQL.Sync.fetchAll = function(query, params)
    return exports.oxmysql:query_sync(query, params)
end

MySQL.Sync.fetchScalar = function(query, params)
    return exports.oxmysql:scalar_sync(query, params)
end

MySQL.Sync.execute = function(query, params)
    return exports.oxmysql:execute_sync(query, params)
end

MySQL.Sync.insert = function(query, params)
    return exports.oxmysql:insert_sync(query, params)
end

-- Create Async methods that use the new exports
MySQL.Async.fetchAll = function(query, params, callback)
    exports.oxmysql:query(query, params, callback)
end

MySQL.Async.fetchScalar = function(query, params, callback)
    exports.oxmysql:scalar(query, params, callback)
end

MySQL.Async.execute = function(query, params, callback)
    exports.oxmysql:execute(query, params, callback)
end

MySQL.Async.insert = function(query, params, callback)
    exports.oxmysql:insert(query, params, callback)
end

-- Add single method for convenience
MySQL.single = function(query, params, callback)
    if callback then
        exports.oxmysql:single(query, params, callback)
    else
        return exports.oxmysql:single_sync(query, params)
    end
end

-- Add error handling for invalid queries
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    if MySQL and MySQL.Sync and MySQL.Async then
        -- Store original functions
        local originalSyncFetchAll = MySQL.Sync.fetchAll
        local originalAsyncExecute = MySQL.Async.execute
        local originalSyncExecute = MySQL.Sync.execute
        local originalAsyncFetchAll = MySQL.Async.fetchAll
        local originalSingle = MySQL.single
        
        -- Override MySQL.Sync.fetchAll with protection
        MySQL.Sync.fetchAll = function(query, params)
            if type(query) ~= 'string' then
                print("^1[MYSQL ERROR PREVENTED] Invalid query type: " .. type(query) .. "^7")
                print("^1[MYSQL ERROR PREVENTED] Value: " .. tostring(query) .. "^7")
                return {} -- Return empty result instead of crashing
            end
            return originalSyncFetchAll(query, params)
        end
        
        -- Override MySQL.Async.execute with protection
        MySQL.Async.execute = function(query, params, cb)
            if type(query) ~= 'string' then
                print("^1[MYSQL ERROR PREVENTED] Invalid query type: " .. type(query) .. "^7")
                print("^1[MYSQL ERROR PREVENTED] Value: " .. tostring(query) .. "^7")
                if cb then cb(0) end
                return
            end
            return originalAsyncExecute(query, params, cb)
        end
        
        -- Override MySQL.Sync.execute with protection
        MySQL.Sync.execute = function(query, params)
            if type(query) ~= 'string' then
                print("^1[MYSQL ERROR PREVENTED] Invalid query type: " .. type(query) .. "^7")
                print("^1[MYSQL ERROR PREVENTED] Value: " .. tostring(query) .. "^7")
                return 0 -- Return 0 affected rows instead of crashing
            end
            return originalSyncExecute(query, params)
        end
        
        -- Override MySQL.Async.fetchAll with protection
        MySQL.Async.fetchAll = function(query, params, cb)
            if type(query) ~= 'string' then
                print("^1[MYSQL ERROR PREVENTED] Invalid query type: " .. type(query) .. "^7")
                print("^1[MYSQL ERROR PREVENTED] Value: " .. tostring(query) .. "^7")
                if cb then cb({}) end
                return
            end
            return originalAsyncFetchAll(query, params, cb)
        end
        
        -- Override MySQL.single with protection
        MySQL.single = function(query, params, cb)
            if type(query) ~= 'string' then
                print("^1[MYSQL ERROR PREVENTED] Invalid query type: " .. type(query) .. "^7")
                print("^1[MYSQL ERROR PREVENTED] Value: " .. tostring(query) .. "^7")
                if cb then cb({}) end
                return {}
            end
            return originalSingle(query, params, cb)
        end
        
        print("^2[MySQL Compatibility] Applied global MySQL error prevention^7")
    end
end)

print("^2[MySQL Compatibility] Created compatibility layer for older MySQL syntax^7")
