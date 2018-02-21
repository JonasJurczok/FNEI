local RecipeController = {
  classname = "FNRecipeController"
}

local RecipeGui = require "unsort/recipe_gui"
local queue = Queue:new("recipe_queue")
local pages = "recipe-pages"

function RecipeController.init_events()
  pages = Page:new(pages, RecipeController.get_name(), 1, RecipeController.change_page_event, RecipeController.change_page_event)
  RecipeGui.init_events()

  Events.add_custom_event(RecipeGui.name, "choose-elem-button", "fluid", RecipeController.open_fluid_recipe_event)
  Events.add_custom_event(RecipeGui.name, "choose-elem-button", "item", RecipeController.open_item_recipe_event)
  Events.add_custom_event(RecipeGui.name, "sprite-button", "tech", RecipeController.open_tech_event)
end

function RecipeController.exit()
  out("Recipe exit")
  RecipeGui.close_window()
end

function RecipeController.open()
  out("Recipe open")

  local gui = RecipeGui.open_window()

  RecipeController.open_new_recipes()

  return gui
end

function RecipeController.open_new_recipes()
  RecipeController.set_page_list()
  RecipeController.change_page_event()
end

function RecipeController.back_key()
  queue:remove()
  pages:set_cur_page(1)
  RecipeController.open_new_recipes()
  return queue:is_empty()
end

function RecipeController.can_open_gui()
  return not queue:is_empty()
end

function RecipeController.get_name()
  return RecipeGui.name
end

function RecipeController.open_item_recipe_event(event, elem_name)
  if elem_name == "item" then
    local _,pos =  string.find(event.element.name, "item%_")

    if pos then
      elem_name = string.sub(event.element.name, pos + 1)
    end

    if event.button == defines.mouse_button_type.right then
      RecipeController.add_element("usage", "item", elem_name)
      RecipeController.open_new_recipes()
    else
      RecipeController.add_element("craft", "item", elem_name)
      RecipeController.open_new_recipes()
    end
  end
end

function RecipeController.open_fluid_recipe_event(event, elem_name)
  if elem_name == "fluid" then
    local _,pos =  string.find(event.element.name, "fluid%_")

    if pos then
      elem_name = string.sub(event.element.name, pos + 1)
    end

    if event.button == defines.mouse_button_type.right then
      RecipeController.add_element("usage", "fluid", elem_name)
      RecipeController.open_new_recipes()
    else
      RecipeController.add_element("craft", "fluid", elem_name)
      RecipeController.open_new_recipes()
    end
  end
end

function RecipeController.open_tech_event(event, elem_name, split_names)
  if Settings.get_val("open-techs") then
    if is_attainable_tech(get_tech_list()[split_names[4]]) or Settings.get_val("open-unavailable-techs") then
      TechHook.show_tech(split_names[4])
    end
  else
    Player.print({"fnei.info-open-techs", {"fnei.open-techs"}})
  end
end

--------------------------------------------------------------------------


function RecipeController.add_element_in_new_queue(action_type, prot_type, prot_name)
  queue:clear()
  RecipeController.add_element(action_type, prot_type, prot_name)
end

function RecipeController.add_element(action_type, prot_type, prot_name)
  local last_elem = queue:get()

  if last_elem == nil or (prot_name ~= last_elem.name or prot_type ~= last_elem.type or action_type ~= last_elem.action_type) then
    local recipe_list = RecipeController.get_recipe_list(action_type, prot_type, prot_name)

    if recipe_list and #recipe_list > 0 then
      queue:add({ type = prot_type, name = prot_name, action_type = action_type })
      pages:set_cur_page(1)
    end
  end
end

function RecipeController.set_page_list()
  local last_prot = queue.get()

  if last_prot then
    pages:set_page_list(RecipeController.get_recipe_list(last_prot.action_type, last_prot.type, last_prot.name))
  end
end

function RecipeController.draw_recipe()
  local recipe = pages:get_list_for_tab(pages:get_cur_page())

  if recipe and recipe[1] then
    recipe = recipe[1]
  else
    return
  end

  RecipeGui.set_recipe_name(recipe.localised_name or recipe.name)
  RecipeGui.set_recipe_icon(recipe)
  RecipeGui.set_ingredients(recipe.ingredients)
  RecipeGui.set_recipe_time(recipe.energy)
  RecipeGui.set_products(recipe.products)
  RecipeGui.set_made_in_list(recipe)
  RecipeGui.set_techs(recipe)
end

function RecipeController.draw_paging()
  RecipeGui.draw_paging(pages)
end

function RecipeController.set_crafting_type()
  local cur_prot = queue.get() or {}
  RecipeGui.set_crafting_type(cur_prot.action_type)
end

function RecipeController.draw_cur_prot()
  local cur_prot = queue.get() or {}
  RecipeGui.draw_cur_prot(cur_prot.type, cur_prot.name)
end


function RecipeController.add_prot_event(event, name)
  -- body
end

function RecipeController.change_page_event()
  RecipeController.draw_paging()
  RecipeController.draw_recipe()
  RecipeController.set_crafting_type()
  RecipeController.draw_cur_prot()
end

--------------------------------------------------------------------------------------

function RecipeController.get_recipe_list(action_type, type, prot)
  local recipe_list = {}
  if action_type == "craft" then
    recipe_list = RecipeController.get_caraft_recipe_list(prot, type)
  elseif action_type == "usage" then
    recipe_list = RecipeController.get_usage_recipe_list(prot, type)
  else
    Debug:error("Error in function RecipeController.get_recipe_list: unknown craft type: ", action_type, "")
  end

  return get_filtred_recipe_list(recipe_list)
end

function RecipeController.get_caraft_recipe_list(element, el_type)
  local recipes = get_recipe_list()
  local ret_tb = {}

  for _,recipe in pairs(recipes) do
    for _,product in pairs(recipe.products) do
      if product.name == element and product.type == el_type then
        table.insert(ret_tb, recipe)
      end
    end
  end

  return ret_tb
end

function RecipeController.get_usage_recipe_list(element, el_type)
  local recipes = get_recipe_list()
  local ret_tb = {}

  for _,recipe in pairs(recipes) do
    for _,ingredient in pairs(recipe.ingredients) do
      if ingredient.name == element and ingredient.type == el_type then
        table.insert(ret_tb, recipe)
      end
    end
  end

  return ret_tb
end

--------------------------------------------------------------------------------------

return RecipeController
