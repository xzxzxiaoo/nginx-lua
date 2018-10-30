local get_headers = ngx.req.get_headers
local ua = ngx.var.http_user_agent
local uri = ngx.var.request_uri
local url = ngx.var.host .. uri
local method = ngx.var.request_method
local redis = require 'redis'
local red = redis.new()
local RedisIP = '192.168.20.210'
local RedisPORT = 6379
local CCcount = 40
local CCseconds = 60
local blackseconds = 600
local CCcount_2 = 0
local CCseconds_2 = 0
local blackseconds_2 = 0
local whitelist=io.input("/home/nginx/conf/lua/conf/white.conf")
---Unlimited
local largeinterfacelist=io.input("/home/nginx/conf/lua/conf/large_interference.conf")
---Special Circumstances
local restrictinterfacelist=io.input("/home/nginx/conf/lua/conf/restrict_interference.conf")

function getClientIp()
    IP = ngx.req.get_headers()["x_forwarded_for"]
    if IP == nil then
        IP =  "unknown"
    end
    return IP
end

function uriMatch(uri_match)
    geturi=string.match(uri_match,uri_match.."*")
    if geturi == uri_match then
       return true
    else
       return false
    end
end


for line in whitelist:lines() do
  if getClientIp() == line
    then
       return
  end
end



if "OPTIONS" == method then
    return
end

for interface_line in largeinterfacelist:lines() do
  if uriMatch(interface_line)
    then
       CCcount=100
       CCseconds=20
       blackseconds=5
       break
   else
       for interface_restrictinter_line in restrictinterfacelist:lines() do
         if uriMatch(interface_restrictinter_line) == true
           then
              CCcount=113
              CCseconds=20
              blackseconds=21600
              CCcount_2=50
              CCseconds_2=86400
              blackseconds_2=172800
              break
         end
       end
   end
end

red:set_timeout(100)
local ok, err = red.connect(red, RedisIP, RedisPORT)

if ok then
    red.connect(red, RedisIP, RedisPORT)

    if ua == nil then
        ua = "unknown"
    end

    local token = getClientIp() .. "." .. ngx.md5(url .. ua)
    local req = red:exists(token)
    if req == 0 then
        red:incr(token)
        red:expire(token,CCseconds)
    else
        local times = tonumber(red:get(token))
        if times >= CCcount then
            local blackReq = red:exists("black." .. token)
            ngx.header['Access-Control-Allow-Origin'] = '*'
            ngx.header['Access-Control-Allow-Methods'] = 'GET,POST'
            ngx.header['Access-Control-Allow-Credentials'] = 'true'
            ngx.header['Content-Type'] = 'application/json; charset=utf-8'
            if (blackReq == 0) then
                red:set("black." .. token,1)
                red:expire("black." .. token,blackseconds)
                red:expire(token,blackseconds)
                ngx.say([[{"code": 401, "msg": "操作太频繁，请稍候重试!"}]])
                ngx.exit(200)
            else
                red:expire("black." .. token,blackseconds)
                red:expire(token,blackseconds)
                ngx.say([[{"code": 401, "msg": "操作太频繁，请稍候重试!"}]])
                ngx.exit(200)
            end
            return
        else
            red:incr(token)
        end
    end

    if CCcount_2 ~= 0 then
        local token_2 = getClientIp() .. "." .. ngx.md5(url .. ua) .. "_2"
        local req_2 = red:exists(token_2)
        if req_2 == 0 then
            red:incr(token_2)
            red:expire(token_2,CCseconds_2)
        else
            local times_2 = tonumber(red:get(token_2))
            if times_2 >= CCcount_2 then
                local blackReq_2 = red:exists("black." .. token_2)
                ngx.header['Access-Control-Allow-Origin'] = '*'
                ngx.header['Access-Control-Allow-Methods'] = 'GET,POST'
                ngx.header['Access-Control-Allow-Credentials'] = 'true'
                ngx.header['Content-Type'] = 'application/json; charset=utf-8'
                if (blackReq_2 == 0) then
                    red:set("black." .. token_2,1)
                    red:expire("black." .. token_2,blackseconds_2)
                    red:expire(token_2,blackseconds_2)
                    ngx.say([[{"code": 401, "msg": "操作太频繁，请稍候重试!"}]])
                    ngx.exit(200)
                else
                    red:expire("black." .. token_2,blackseconds_2)
                    red:expire(token_2,blackseconds_2)
                    ngx.say([[{"code": 401, "msg": "操作太频繁，请稍候重试!"}]])
                    ngx.exit(200)
                end
                return
            else
                red:incr(token_2)
            end
        end
    end 
    return
end

