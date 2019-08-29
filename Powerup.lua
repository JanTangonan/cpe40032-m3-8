Powerup = Class{}

math.randomseed( os.time() ) 

function Powerup:init()
    self.x = math.random(20, VIRTUAL_WIDTH - 20)
    self.y = 0        -- so that the power up will always drop from the top

    self.type = 0     -- the type or the kind of sprite power up, there are 10 kinds of sprite, 0 is for none 
    self.inPlay = false -- at first it is false, but when played it will be true
    self.speed = 50
    self.width = 16
    self.height = 16
    self.timer = 0  -- eto ay counter
    self.spawnTime = .5 -- seconds
    
end

function Powerup:collides(target) 
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end                                                 -- just a formula to check collision

    self:reset()

    return true
end

function Powerup:reset()
    self.inPlay = false
    self.timer = 0
    self.x = math.random(20, VIRTUAL_WIDTH - 20)
    self.y = 0                                          -- reseter to spawn more and different power up

end

function Powerup:update(dt)
    -- update position
    self.y = self.y + self.speed*dt

    if self.y > VIRTUAL_HEIGHT then
        self:reset()
    end
end

function Powerup:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type], self.x, self.y)
    end
end