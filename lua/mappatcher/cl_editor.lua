local luabsp = MapPatcher.Libs.luabsp
local quickhull = MapPatcher.Libs.quickhull
local BufferInterface = MapPatcher.Libs.BufferInterface

MapPatcher.Editor = MapPatcher.Editor or {}
local Editor = MapPatcher.Editor
Editor.GridSize = 16

Editor.Tools = {
  "custom",
  "playerclip",
  "propclip",
  "bulletclip",
  "clip",
  "forcefield",
  "hurt",
  "kill",
  "remove",
  "teleport",
  "tp_target",
  "x3m4k_push",
  "x3m4k_kill",
  "x3m4k_clip",
}

Editor.ToolsBase = {
  ["custom"] = "brush",
  ["playerclip"] = "brush",
  ["propclip"] = "brush",
  ["bulletclip"] = "brush",
  ["clip"] = "brush",
  ["forcefield"] = "brush",
  ["hurt"] = "brush",
  ["kill"] = "brush",
  ["remove"] = "brush",
  ["teleport"] = "brush",
  ["tp_target"] = "point",
  ["x3m4k_push"] = "brush",
  ["x3m4k_kill"] = "brush",
  ["x3m4k_clip"] = "brush",
}

-- see https://wiki.facepunch.com/gmod/Silkicons
Editor.ToolsIcons16 = {
  ["custom"] = "application_edit",
  ["playerclip"] = "user_delete",
  ["propclip"] = "box",
  ["bulletclip"] = "shading",
  ["clip"] = "stop",
  ["forcefield"] = "exclamation",
  ["hurt"] = "bomb",
  ["kill"] = "bomb",
  ["remove"] = "delete",
  ["teleport"] = "transmit_go",
  ["tp_target"] = "house_go",
  ["x3m4k_push"] = "arrow_right",
  ["x3m4k_kill"] = "bomb",
  ["x3m4k_clip"] = "stop",
}

function Editor.Start()
  if xgui then
    xgui.hide()
  end -- Hide ULX XGUI
  if gui.IsGameUIVisible() then
    gui.HideGameUI()
  end
  Editor.Enabled = true
  Editor.StartUI()
  Editor.LoadMapClipBrushes()
  if not Editor.Object then
    Editor.SetTool(Editor.Tools[1])
  end
  Editor.UpdateMenu()

  Editor.PVS = Editor.Screen:GetViewPos()
end

function Editor.Stop()
  Editor.Enabled = false
  Editor.StopUI()

  net.Start("mappatcher_editor_pvs")
  net.WriteBool(false)
  net.SendToServer()
end

function Editor.LeftClick(pos, ang)
  Editor.Object:LeftClick(pos, ang)
end

function Editor.RightClick(tr)
  if IsValid(tr.Entity) and tr.Entity.MapPatcherObject then
    Editor.SelectObject(tr.Entity.object)
  else
    for k, object in pairs(MapPatcher.Objects) do
      if not object:IsDerivedFrom("base_point") then
        continue
      end
      if object:GetOrigin():DistToSqr(tr.HitPos) < 1000 then
        Editor.SelectObject(object)
        return
      end
    end
    Editor.ResetTool()
  end
end

function Editor.x3m4k_BrushOptions(obj)
  if IsValid(Editor.BrushOptionsPanel) then
    Editor.BrushOptionsPanel:Remove()
    Editor.BrushOptionsPanel = nil
  end

  Editor.BrushOptionsPanel = vgui.Create("DFrame", Editor.Screen)
  local window = Editor.BrushOptionsPanel
  window:SetDraggable(false)
  window:ShowCloseButton(false)
  window:SetDrawOnTop(true)
  window:SetBackgroundBlur(true)

  window.Paint = MapPatcher.GetWindowPaint(title)

  local contents = vgui.Create("DPanel", window)
  contents:Center()

  function contents:Paint(w, h)
    surface.SetDrawColor(Color(0, 255, 0, 255))
    surface.DrawRect(0, 0, w, h)
  end
end

function Editor.SubmitObject(obj, focus_type)
  -- focus_type
  -- 0 - none
  -- 1 - select object in menu
  -- 2 - select object in menu + camera focus
  local object = obj or Editor.Object

  if object.Base == "base_brush" and #object.points <= 3 then
    MapPatcher.Message("#mappatcher.error.object_points_min_4", "OK", "#mappatcher.error")
    return
  end

  net.Start("mappatcher_submit")
  net.WriteUInt(object.ID, 16)
  net.WriteString(object.ClassName)

  if not focus_type and focus_type ~= 0 then
    focus_type = 1
  end

  net.WriteUInt(focus_type, 2)
  object:WriteToBuffer(BufferInterface("net"))
  net.SendToServer()

  Editor.ResetTool()
end

function Editor.RemoveObject(obj)
  local object = obj or Editor.Object
  local object_id = object.ID

  if object_id > 0 then
    net.Start("mappatcher_submit")
    net.WriteUInt(object_id, 16)
    net.WriteString("null")
    net.SendToServer()
  end

  Editor.ResetTool()
end

function Editor.ResetTool()
  Editor.Object:ToolSwitchTo(nil)
  Editor.Object = nil
  Editor.SetTool()
end

function Editor.SetTool(tool, no_object)
  tool = tool or Editor.Tool
  Editor.Tool = tool

  if not no_object then
    local new_object = MapPatcher.NewToolObject(tool)

    local object = Editor.Object
    if IsValid(object) then
      new_object:ToolSwitchFrom(object)
      object:ToolSwitchTo(new_object)
    end

    Editor.Object = new_object
  end

  Editor.UpdateMenu()
end

function Editor.SelectObject(object, look)
  Editor.Object:ToolSwitchTo(object)
  if (IsValid(Editor.Object) and Editor.Object.ID ~= 0) or object:IsDerivedFrom("x3m4k_push") then
    object:ToolSwitchFrom(Editor.Object)
  end

  Editor.Object = object:GetCopy()
  Editor.SetTool(object.ClassName, true)

  if look then
    Editor.Screen:LookAt(object:GetOrigin())
  end
end

function Editor.CloseContextMenu()
  if IsValid(Editor.CurrentContext) then
    Editor.CurrentContext:Remove()
  end
  Editor.CurrentContext = nil
end

function Editor.ContextMenu(object)
  Editor.CloseContextMenu() -- will close old menu (if it is existing)

  --Editor.SelectObject(object)

  local menu = DermaMenu()

  if object.Base == "base_brush" then
    -- < Insert inside >
    local subMenuInsert, parentMenuInsert = menu:AddSubMenu("#mappatcher.context.insert_inside")
    parentMenuInsert:SetImage("icon16/shape_move_forwards.png")

    local function insert_here(tool_name)
      local new_object = MapPatcher.NewToolObject(tool_name)
      new_object.ID = 0
      new_object.points = object.points

      Editor.SubmitObject(new_object, 2)
    end

    for i, tool_name in ipairs(Editor.Tools) do
      if Editor.ToolsBase[tool_name] == "brush" then
        local opt = subMenuInsert:AddOption(tool_name, function()
          insert_here(tool_name)
        end)
        opt:SetImage(string.format("icon16/%s.png", Editor.ToolsIcons16[tool_name] or "bullet_black"))
      end
    end

    -- - Insert inside -

    -- < Change class >

    local subMenuChangeClass, parentMenuChangeClass = menu:AddSubMenu("#mappatcher.context.change_class")
    parentMenuChangeClass:SetImage("icon16/pencil.png")

    local function change_class(tool_name)
      local new_object = MapPatcher.NewToolObject(tool_name)
      new_object.ID = 0
      new_object.points = object.points

      Editor.RemoveObject(object)
      Editor.SubmitObject(new_object, 2)
    end

    for i, tool_name in ipairs(Editor.Tools) do
      if Editor.ToolsBase[tool_name] == "brush" then
        local opt = subMenuChangeClass:AddOption(tool_name, function()
          change_class(tool_name)
        end)
        opt:SetImage(string.format("icon16/%s.png", Editor.ToolsIcons16[tool_name] or "bullet_black"))
      end
    end

    -- - Change class -
  end

  if menu:ChildCount() == 0 then
    return
  end

  Editor.CurrentContext = menu

  menu:Open()
end

function Editor.UpdateMenu()
  Editor.Screen:UpdateMenu()
end

function Editor.LoadMapClipBrushes(force)
  if not force and Editor.MapClipBrushes then
    return
  end
  Editor.MapClipBrushes = nil

  local bsp = luabsp.LoadMap(game.GetMap())
  if bsp then
    if MapPatcher.Config.MapClipBrushesAsSingleObject then
      Editor.MapClipBrushes = {bsp:GetClipBrushes(true)}
    else
      Editor.MapClipBrushes = bsp:GetClipBrushes(false)
    end
  end
end

function MapPatcher.DeleteMesh()
  if MapPatcher.EditMesh.id > 0 then
    MapPatcher.EditMesh.points = {}
    MapPatcher.SubmitMesh()
  end

  MapPatcher.CreateEditMesh()
end

function MapPatcher.ReloadEntities()
  net.Start("mappatcher_reload_entities")
  net.SendToServer()
end

do
  local mappatcher_tool_font = "mappatcher_tool_font_" .. os.time()
  surface.CreateFont(mappatcher_tool_font, {
    font = "Consolas",
    size = 40,
    weight = 800,
  })

  local tool_mats_queue = {}
  hook.Add("DrawMonitors", "MapPatcher_MaterialGenerator", function()
    for k, data in pairs(tool_mats_queue) do
      local mat = data.mat
      local mat_name = data.mat_name
      local color = data.color
      local text = data.text
      local rt_tex = GetRenderTarget(mat_name, 256, 256, true)
      mat:SetTexture("$basetexture", rt_tex)

      render.PushRenderTarget(rt_tex)

      render.SetViewPort(0, 0, 256, 256)
      render.OverrideAlphaWriteEnable(true, true)
      cam.Start2D()
      render.Clear(color.r, color.g, color.b, color.a)
      surface.SetFont(mappatcher_tool_font)
      surface.SetTextColor(255, 255, 255, 255)
      local txt_w, txt_h = surface.GetTextSize(text)
      surface.SetTextPos(128 - txt_w / 2, 128 - txt_h / 2)
      surface.DrawText(text)

      surface.SetDrawColor(255, 255, 255)
      surface.DrawOutlinedRect(10, 10, 256 - 10, 256 - 10)
      cam.End2D()

      render.OverrideAlphaWriteEnable(false)
      render.PopRenderTarget()
    end
    tool_mats_queue = {}
  end)

  function Editor.GenerateToolMaterial(mat_name, color, text)
    local mat = CreateMaterial(mat_name, "UnlitGeneric", {["$vertexalpha"] = 1})
    tool_mats_queue[#tool_mats_queue + 1] = {mat_name = mat_name, color = color, text = text, mat = mat}
    return mat
  end
end
local dev_test = os.time()

local material_error = Editor.GenerateToolMaterial("mappatcher_error", Color(255, 0, 0, 255), "ERROR")
function MapPatcher.GetToolMaterial(tool_type, noalpha)
  local tool_class = MapPatcher.Tools[tool_type]
  if not tool_class then
    return material_error
  end
  if noalpha then
    if tool_class.EditorMaterial then
      return tool_class.EditorMaterial
    end
    local texture_color = table.Copy(tool_class.TextureColor)
    texture_color.a = 255
    tool_class.EditorMaterial =
    Editor.GenerateToolMaterial("mappatcher_" .. tool_type, texture_color, tool_class.TextureText)
    return tool_class.EditorMaterial
  else
    if tool_class.EditorMaterialAlpha then
      return tool_class.EditorMaterialAlpha
    end

    tool_class.EditorMaterialAlpha = Editor.GenerateToolMaterial(
      "mappatcher_" .. tool_type .. "_alpha",
      tool_class.TextureColor,
      tool_class.TextureText
    )
    return tool_class.EditorMaterialAlpha
  end
  return material_error
end

local function insert_pq(tbl, priority, element)
  local insert_pos = 1
  for k, v in ipairs(tbl) do
    if v[1] < priority then
      insert_pos = k
      table.insert(tbl, k, {priority, element})
      return
    end
  end
  tbl[#tbl + 1] = {priority, element}
end

-- the offset that the user made by placing the first point.
function Editor.getGridUserOffset(currentPos)
  local currentX, currentY, currentZ = currentPos:Unpack()
  local offsetX, offsetY, offsetZ = 0, 0, 0

  if Editor.Tool ~= nil and Editor.ToolsBase[Editor.Tool] == "brush" and Editor.Object ~= nil and Editor.Object.points ~= nil and Editor.Object.points[1] ~= nil then
    local offsetPointX, offsetPointY, offsetPointZ = Editor.Object.points[1]:Unpack()
    offsetX = offsetPointX - math.floor(offsetPointX / Editor.GridSize) * Editor.GridSize
    offsetY = offsetPointY - math.floor(offsetPointY / Editor.GridSize) * Editor.GridSize
    offsetZ = offsetPointZ - math.floor(offsetPointZ / Editor.GridSize) * Editor.GridSize
  end

  local x, y, z
  x = offsetX + math.floor(currentX / Editor.GridSize) * Editor.GridSize
  y = offsetY + math.floor(currentY / Editor.GridSize) * Editor.GridSize
  z = offsetZ + math.floor(currentZ / Editor.GridSize) * Editor.GridSize

  return Vector(x + 0.01, y + 0.01, z + 0.01)

end

local point_pos = Vector()
local material_hammer_playerclip =
Editor.GenerateToolMaterial("mappatcher_hammer_playerclip", Color(255, 0, 255, 200), "Player Clip")
hook.Add("PostDrawOpaqueRenderables", "MapPatcherEditor", function(bDrawingDepth, bDrawingSkybox)
  if not MapPatcher.CVarDraw:GetBool() and not Editor.Enabled then
    return
  end
  render.OverrideDepthEnable(true, true)

  if Editor.Enabled then
    -- Draw main cursor point
    -- print(Editor.Screen:GetPointPos().x, Editor.Screen:GetPointPos().y, Editor.Screen:GetPointPos().z)
    render.SetColorMaterial()

    local v = Editor.Screen:GetPointPos()

    if Editor.EnabledGrid then
      v = Editor.getGridUserOffset(v)
      Editor.Screen:GetPointPos():Set(v) -- replace vector for editor too
    end

    render.DrawSphere(v, 4, 8, 8, Color(255, 255, 0, 200))
  end

  local render_pq = {}

  local view_pos = EyePos()
  local editor_object_id = 0
  if Editor.Object and IsValid(Editor.Object) then
    insert_pq(render_pq, Editor.Object:GetOrigin():DistToSqr(view_pos), Editor.Object)
    editor_object_id = Editor.Object.ID
  end
  for object_id, object in pairs(MapPatcher.Objects) do
    if object_id == editor_object_id then
      continue
    end
    insert_pq(render_pq, object:GetOrigin():DistToSqr(view_pos), object)
  end

  for k, v in pairs(render_pq) do
    local object = v[2]
    object:EditorRender(object.ID == editor_object_id)
  end

  if Editor.MapClipBrushes then
    render.SetMaterial(material_hammer_playerclip)
    for _, mesh in pairs(Editor.MapClipBrushes) do
      mesh:Draw() -- Draw the mesh
    end
  end

  render.OverrideDepthEnable(false)
end)

net.Receive("mappatcher_editmode_start", function(len)
  Editor.Start()
end)

net.Receive("mappatcher_focus", function(len)
  Editor.SelectObject(MapPatcher.Objects[net.ReadUInt(16)], net.ReadBool())
end)

function Editor.StartUI()
  if not Editor.Screen then
    Editor.Screen = vgui.Create("MapPatcherEditorScreen")
  end
  Editor.Screen:Open()
end

function Editor.StopUI()
  if not Editor.Screen then
    return
  end

  Editor.CloseContextMenu()

  Editor.Screen:Remove()
  Editor.Screen = nil
end

local hud_allow = {
  CHudChat = true,
  CHudGMod = true,
  CHudMenu = true,
  NetGraph = true,
}

hook.Add("HUDShouldDraw", "MapPatcherEditModeUI", function(name)
  if not Editor.Screen then
    return
  end
  if not Editor.Screen:IsVisible() then
    return
  end
  if hud_allow[name] then
    return
  end
  return false
end)

hook.Add("CalcView", "MapPatcherEditor", function(ply, pos, angles, fov)
  if not Editor.Screen or not Editor.Screen:IsVisible() then
    return
  end

  local view = {}

  view.origin = Editor.Screen:GetViewPos()
  view.angles = Editor.Screen:GetViewAngles()
  view.fov = fov
  view.drawviewer = true

  return view
end)

hook.Add("Think", "MapPatcherEditor", function()
  if not Editor.Screen or not Editor.Screen:IsVisible() then
    return
  end

  if Editor.PVS:DistToSqr(Editor.Screen:GetViewPos()) > 1000 then
    Editor.PVS = Editor.Screen:GetViewPos()

    net.Start("mappatcher_editor_pvs")
    net.WriteBool(true)
    net.WriteVector(Editor.PVS)
    net.SendToServer()
  end
end)
