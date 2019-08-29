--[[
     CMPE40032
    Arkanoid Remake

    -- PlayState Class --

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {params.ball}
    self.level = params.level

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)

    self.powerup = Powerup()
    self.keyCatched = false
    self.recoverPoints = 50000

end
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
            gSounds['music']:resume()
            gSounds['music2']:resume()
        else                                            -- this part is the pause function just like the logic from
            return                                      -- from the last module
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        gSounds['music']:pause()
        gSounds['music2']:pause()
        return
    end
----------------------------------------------------------------------------------------------------------------------
    -- powerup spawners
                            -- these are the conditions for the spawning of the powerups

    self.powerup.timer = self.powerup.timer + dt
    if not self.powerup.inPlay and self.powerup.timer > self.powerup.spawnTime then
        if math.random(1, 100) < 50 then
            if not self.keyCatched and self:blockedBrickSpawned() then -- if the key is not yet catched and the locked bricks was spawned then
                self.powerup.type = 10                                 -- the key power up will be spawned
                self.powerup.inPlay = true
            elseif #self.balls == math.random(1,2) then -- if there is only 1 or 2 ball left in the game then
                print(#self.balls)                      -- it'll produce a power up for even more balls
                self.powerup.type = 9                  
                self.powerup.inPlay = true
            elseif self.health == math.random(1,2) then -- there is only 1 or 2 life left, then it will spawn
                self.powerup.type = 3                   -- a heart power up
                self.powerup.inPlay = true
            elseif self.paddle.size < math.random(1,3) then
                self.powerup.type = 8                   -- if the size of paddle is small, then there will be a chance that it'll spawn a 
                self.powerup.inPlay = true              -- power up that makes the paddle grow

            elseif self.paddle.size > 3 then            -- also there will be also a debuff power up, this power up will will make the
                self.powerup.type = 7                   -- paddle shrink, but it will only spawn when the paddle is already big
                self.powerup.inPlay = true

            elseif PADDLE_SPEED == 100 or PADDLE_SPEED == 200 or PADDLE_SPEED == 300 then       
                self.powerup.type = 2                   -- if the speed is 100, 200, or 300, a power up will spawn
                self.powerup.inPlay = true

            elseif PADDLE_SPEED == 400 or PADDLE_SPEED == 300 or PADDLE_SPEED == 200 then           
                self.powerup.type = 1                   -- if the speed is 400, 300, or 200, a debuff will spawn
                self.powerup.inPlay = true
            end
        end
        self.powerup.timer = 0
    end

    if self.powerup.inPlay then         -- now if state is playing, power ups will update and spawn
        self.powerup:update(dt)
    end
----------------------------------------------------------------------------------------------------------------------
    -- powerup collision
                              -- these are the results when the power ups collides with the paddle

    if self.powerup:collides(self.paddle) then
        print(self.powerup.type)
        if self.powerup.type == 9 then      -- basically this power up will spawn three more balls 
            print("more balls powerup preso (tipo 1)")
            local b = Ball(math.random(7))
            b.x = self.balls[1].x
            b.y = self.balls[1].y
            b.dx = math.random(-200, 200)   -- b is for extra ball number one
            b.dy = math.random(-50, -60)
            table.insert(self.balls, b)

            local b2 = Ball(math.random(7))
            b2.x = self.balls[1].x
            b2.y = self.balls[1].y
            b2.dx = math.random(-200, 200)  -- b2 is for extra ball number two
            b2.dy = math.random(-50, -60)
            table.insert(self.balls, b2)

            local b3 = Ball(math.random(7))
            b3.x = self.balls[1].x
            b3.y = self.balls[1].y
            b3.dx = math.random(-200, 200)  -- b3 is for extra ball number two
            b3.dy = math.random(-50, -60)
            table.insert(self.balls, b3)
            
        elseif self.powerup.type == 10 then  -- this is the power up for unlocking the locked brick
            self.keyCatched = true

        elseif self.powerup.type == 3 then      -- this power up will spawn a heart shape icon and when catched, it'll add 1 health
            self.health = math.min(3, self.health + 1)  
            gSounds['recover']:play()
        
        elseif self.powerup.type == 8 then      -- this power up will make the paddle grow larger
            self.paddle:grow()
            gSounds['recover']:play()

        elseif self.powerup.type == 7 then      -- this power up will make the paddle shrink 
            self.paddle:shrink()
            gSounds['hurt']:play()
        elseif self.powerup.type == 2 then      -- this power up will make the paddle faster
            PADDLE_SPEED = PADDLE_SPEED + 100
            gSounds['recover']:play()

        elseif self.powerup.type == 1 then      -- this power up will make the paddle slower
            PADDLE_SPEED = PADDLE_SPEED - 100
            gSounds['hurt']:play()
        end
    end
----------------------------------------------------------------------------------------------------------------------
    -- update positions based on velocity
    self.paddle:update(dt)

    for i, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
----------------------------------------------------------------------------------------------------------------------
        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                
                if self.keyCatched and brick.locked then
                    brick:hit()                             -- this part is for the locked brick
                    brick.locked = false                    -- when the key was catched then lock will be unlocked
                end
                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                brick:hit()
    ----------------------------------------------------------------------------------------------------------------------            
    ----------------------------------------------------------------------------------------------------------------------
                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)
                                                                        -- i set the recover points to be 50,000
                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end
    ----------------------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------------------
                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = Ball(math.random(7)),
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8

                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32

                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8

                -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end

        -- if ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then
            if #self.balls == 1 then 
                self.health = self.health - 1
                gSounds['hurt']:play()

                self.paddle:shrink()

                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            else
                table.remove(self.balls, i)
            end
        end
    end
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end
----------------------------------------------------------------------------------------------------------------------
function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- when key power up was catched
    if self.keyCatched then
        love.graphics.print("Locked Brick Unlocked!", 25, 200)
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.powerup:render()

    for i, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end

function PlayState:blockedBrickSpawned()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay and brick.locked then
            return true
        end
    end
    return false
end