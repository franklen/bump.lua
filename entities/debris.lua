local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'

local Debris = class('Debris', Entity)

local minSize = 5
local maxSize = 10
local minVel = -100
local maxVel = -1 * minVel
local bounciness = 0.01

local debrisFilter = function(other)
  return other.class.name == 'Block' or other.class.name == 'Guardian'
end

function Debris:initialize(world, x, y)
  Entity.initialize(self,
    world,
    x, y,
    math.random(minSize, maxSize),
    math.random(minSize, maxSize)
  )

  self.lifeTime = 1 + 2 * math.random()
  self.lived = 0
  self.vx = math.random(minVel, maxVel)
  self.vy = math.random(minVel, maxVel)
end

function Debris:collide(dt)
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local cols, len = world:check(self, future_l, future_t, debrisFilter)
  if len == 0 then
    self.l, self.t = future_l, future_t
    world:move(self, future_l, future_t)
  else
    local col, tl, tt, nx, ny, bl, bt
    local visited = {}
    while len > 0 do
      col = cols[1]
      tl,tt,nx,ny,sl,st = col:getBounce()

      self:changeVelocityByCollisionNormal(nx, ny, bounciness)

      self.l, self.t = tl, tt
      world:move(self, tl, tt)

      if visited[col.other] then return end -- stop iterating when we collide with the same item twice
      visited[col.other] = true

      cols, len = world:check(self, sl, st, debrisFilter)
      if len == 0 then
        self.l, self.t = sl, st
        world:move(self, sl, st)
      end
    end
  end
end

function Debris:update(dt)
  self.lived = self.lived + dt

  if self.lived >= self.lifeTime  then
    self:destroy()
  else
    self:changeVelocityByGravity(dt)
    self:collide(dt)
  end
end

function Debris:draw()
  local r,g,b = 220, 150, 150
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, r,g,b)
end

return Debris
