-- slap this into some ball instance
-- very simple spring thing
--[[
sources used:

https://physics.stackexchange.com/questions/445650/collision-response-with-spring-physics-in-rk4
https://gafferongames.com/post/spring_physics/
https://devforum.roblox.com/t/how-many-studs-is-there-in-a-meter/103417/25
https://devforum.roblox.com/t/generating-equidistant-points-on-a-sphere/874144

--]]
local part = script.Parent

local stud_metre_conversion = 14/50
local ball_diameter = 4
local ball_radius = ball_diameter*0.5
local goldenRatio = 1 + math.sqrt(5) / 4
local angleIncrement = math.pi * 2 * goldenRatio
local multiplier = ball_radius
local ray_points = 120
local dampening = 9
local equilibirium_extension = 6
local mass = 5
local spring_constant = 21
local from = part.Position - Vector3.new(0,equilibirium_extension,0)

local a0 = Instance.new("Attachment")
local a1 = Instance.new("Attachment")
local from_part = Instance.new("Part")
from_part.Position = from
from_part.Transparency = 1
from_part.Anchored = true
from_part.CanCollide = false
local SphereHandle = Instance.new("SphereHandleAdornment")
SphereHandle.Adornee = from_part
SphereHandle.Parent = from_part
a0.Parent = from_part
a1.Parent = part
local Beam = Instance.new("Beam")
Beam.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0)}
Beam.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(13, 105, 172)),ColorSequenceKeypoint.new(1,Color3.fromRGB(13, 105, 172))}
Beam.FaceCamera = true
Beam.Segments = 2
Beam.Width0 = 0.05
Beam.Width1 = 0.05
Beam.Attachment0 = a0
Beam.Attachment1 = a1
Beam.Parent = from_part
from_part.Parent = part

local RunService = game:GetService("RunService")
part.Size = Vector3.new(ball_diameter,ball_diameter,ball_diameter)

local velocity = {
	0,--y
	0,--x
	0,--z
}

local function calculate_spring_force(x,dir)
	return x*spring_constant - dampening*velocity[dir] -- F = kx - bv
end
local function calculate_acceleration(force)
	return force/mass -- F = ma
end
local function update_velocity(dir, axis, acceleration, delta) -- velocity will be aligned to one axis only (relative to part)
	local acceleration = acceleration*delta
	velocity[dir] += acceleration
	part.Position -= axis*velocity[dir]
end
local function ray_cast_collision(vecConstruct, rayOrigin, rayDirection, raycastParams)
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	local collison_force = Vector3.new(0,0,0)

	if raycastResult then
		-- if no ray then thats due to the rayDirection being wrong.
		-- F = nkd - bn(n.v)
		local relative_velocity = vecConstruct - raycastResult.Instance.Velocity
		local ray_length = stud_metre_conversion*math.abs((rayOrigin - raycastResult.Position).magnitude-ball_radius)

		collison_force += raycastResult.Normal*spring_constant*ray_length -dampening*raycastResult.Normal*(relative_velocity)
	end
	return collison_force
end

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {part}
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

RunService.Stepped:Connect(function(t, dt)
	local cframe = part.CFrame
	
	local collison_force = Vector3.new(0,0,0)
	local vecConstruct = Vector3.new(velocity[1],velocity[2],velocity[3])
	
	-- generate equidistant points
	for i = 0, ray_points do
		local distance = i / ray_points
		local incline = math.acos(1 - 2 * distance)
		local azimuth = angleIncrement * i

		local x = math.sin(incline) * math.cos(azimuth) * multiplier
		local y = math.sin(incline) * math.sin(azimuth) * multiplier
		local z = math.cos(incline) * multiplier
		
		collison_force += ray_cast_collision(vecConstruct, cframe.p, (cframe.p-(cframe.p+Vector3.new(x,y,z))).Unit*ball_radius, raycastParams)
	end
	
	local extension_y = stud_metre_conversion*(part.Position.Y-from.Y-equilibirium_extension)
	local extension_x = stud_metre_conversion*(part.Position.X-from.X)
	local extension_z = stud_metre_conversion*(part.Position.Z-from.Z)
	local force_y = calculate_spring_force(extension_y,1)-collison_force.Y
	local force_x = calculate_spring_force(extension_x,2)-collison_force.X
	local force_z = calculate_spring_force(extension_z,3)-collison_force.Z
	local acceleration_y = calculate_acceleration(force_y)
	local acceleration_x = calculate_acceleration(force_x)
	local acceleration_z = calculate_acceleration(force_z)
	
	update_velocity(1,cframe.UpVector.Unit, acceleration_y, dt)
	update_velocity(2,cframe.RightVector.Unit, acceleration_x, dt)
	update_velocity(3,-cframe.LookVector.Unit, acceleration_z, dt)
end)
