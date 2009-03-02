
--[[
=head1 NAME

applets.TouchSkin.TouchSkinApplet - The touch skin for the Squeezebox Touch

=head1 DESCRIPTION

This applet implements the Touch skin for the Squeezebox Touch

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. 
SqueezeboxSkin overrides the following methods:

=cut
--]]


-- stuff we use
local ipairs, pairs, setmetatable, type = ipairs, pairs, setmetatable, type

local oo                     = require("loop.simple")

local Applet                 = require("jive.Applet")
local Audio                  = require("jive.ui.Audio")
local Font                   = require("jive.ui.Font")
local Framework              = require("jive.ui.Framework")
local Icon                   = require("jive.ui.Icon")
local Label                  = require("jive.ui.Label")
local RadioButton            = require("jive.ui.RadioButton")
local RadioGroup             = require("jive.ui.RadioGroup")
local SimpleMenu             = require("jive.ui.SimpleMenu")
local Surface                = require("jive.ui.Surface")
local Textarea               = require("jive.ui.Textarea")
local Tile                   = require("jive.ui.Tile")
local Window                 = require("jive.ui.Window")

local table                  = require("jive.utils.table")
local debug                  = require("jive.utils.debug")
local autotable              = require("jive.utils.autotable")

local log = require("jive.utils.log").logger("ui")

local EVENT_ACTION           = jive.ui.EVENT_ACTION
local EVENT_CONSUME          = jive.ui.EVENT_CONSUME
local EVENT_WINDOW_POP       = jive.ui.EVENT_WINDOW_POP
local LAYER_FRAME            = jive.ui.LAYER_FRAME
local LAYER_CONTENT_ON_STAGE = jive.ui.LAYER_CONTENT_ON_STAGE

local LAYOUT_NORTH           = jive.ui.LAYOUT_NORTH
local LAYOUT_EAST            = jive.ui.LAYOUT_EAST
local LAYOUT_SOUTH           = jive.ui.LAYOUT_SOUTH
local LAYOUT_WEST            = jive.ui.LAYOUT_WEST
local LAYOUT_CENTER          = jive.ui.LAYOUT_CENTER
local LAYOUT_NONE            = jive.ui.LAYOUT_NONE

local WH_FILL                = jive.ui.WH_FILL

local jiveMain               = jiveMain
local appletManager          = appletManager


module(...)
oo.class(_M, Applet)


-- Define useful variables for this skin
local imgpath = "applets/Fab4Skin/images/"
local sndpath = "applets/Fab4Skin/sounds/"
local fontpath = "fonts/"
local FONT_NAME = "FreeSans"
local BOLD_PREFIX = "Bold"


function init(self)
	self.images = {}
end


-- reuse images instead of loading them twice
-- FIXME can be removed after Bug 10001 is fixed
local function _loadImage(self, file)
	if not self.images[file] then
		self.images[file] = Surface:loadImage(imgpath .. file)
	end

	return self.images[file]
end


-- define a local function to make it easier to create icons.
local function _icon(x, y, img)
	local var = {}
	var.x = x
	var.y = y
	var.img = _loadImage(self, img)
	var.layer = LAYER_FRAME
	var.position = LAYOUT_SOUTH

	return var
end

-- define a local function that makes it easier to set fonts
local function _font(fontSize)
	return Font:load(fontpath .. FONT_NAME .. ".ttf", fontSize)
end

-- define a local function that makes it easier to set bold fonts
local function _boldfont(fontSize)
	return Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", fontSize)
end

-- defines a new style that inherrits from an existing style
local function _uses(parent, value)
	local style = {}
	setmetatable(style, { __index = parent })

	for k,v in pairs(value or {}) do
		if type(v) == "table" and type(parent[k]) == "table" then
			-- recursively inherrit from parent style
			style[k] = _uses(parent[k], v)
		else
			style[k] = v
		end
	end

	return style
end


-- skin
-- The meta arranges for this to be called to skin Jive.
function skin(self, s)
	Framework:setVideoMode(480, 272, 0, false)

	local screenWidth, screenHeight = Framework:getScreenSize()

	--init lastInputType so selected item style is not shown on skin load
	Framework.mostRecentInputType = "mouse"

	-- Images and Tiles
	local titleBox          = Tile:loadImage( imgpath .. "Titlebar/titlebar.png" )
	local fiveItemSelectionBox      = Tile:loadImage( imgpath .. "5_line_lists/menu_sel_box_5line.png")
	local fiveItemPressedBox      = Tile:loadImage( imgpath .. "5_line_lists/menu_sel_box_5line_press.png")
	local threeItemSelectionBox = Tile:loadImage( imgpath .. "3_line_lists/menu_sel_box_3line.png")
	local threeItemPressedBox   = Tile:loadImage( imgpath .. "3_line_lists/menu_sel_box_3line_press.png")

	local backButton              = Tile:loadImage( imgpath .. "Icons/icon_back_button_tb.png")
	local helpButton              = Tile:loadImage( imgpath .. "Buttons/button_help_tb.png")
	local nowPlayingButton        = Tile:loadImage( imgpath .. "Icons/icon_nplay_button_tb.png")
	local textinputBackground     = 
		Tile:loadTiles({
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_tl.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_t.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_tr.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_r.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_br.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_b.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_bl.png",
				 imgpath .. "Text_Entry/Keyboard_Touch/text_entry_titlebar_box_l.png",
				})

	local buttonBox =
		Tile:loadTiles({
					nil, 
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_tl.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_t.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_tr.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_r.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_br.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_b.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_bl.png",
					imgpath .. "Text_Entry/Keyboard_Touch/button_qwerty_l.png",
				})

	local pressedTitlebarButtonBox =
		Tile:loadTiles({
					imgpath .. "Buttons/button_titlebar_press.png",
					imgpath .. "Buttons/button_titlebar_tl_press.png",
					imgpath .. "Buttons/button_titlebar_t_press.png",
					imgpath .. "Buttons/button_titlebar_tr_press.png",
					imgpath .. "Buttons/button_titlebar_r_press.png",
					imgpath .. "Buttons/button_titlebar_br_press.png",
					imgpath .. "Buttons/button_titlebar_b_press.png",
					imgpath .. "Buttons/button_titlebar_bl_press.png",
					imgpath .. "Buttons/button_titlebar_l_press.png",
				})

	local titlebarButtonBox =
		Tile:loadTiles({
					imgpath .. "Buttons/button_titlebar.png",
					imgpath .. "Buttons/button_titlebar_tl.png",
					imgpath .. "Buttons/button_titlebar_t.png",
					imgpath .. "Buttons/button_titlebar_tr.png",
					imgpath .. "Buttons/button_titlebar_r.png",
					imgpath .. "Buttons/button_titlebar_br.png",
					imgpath .. "Buttons/button_titlebar_b.png",
					imgpath .. "Buttons/button_titlebar_bl.png",
					imgpath .. "Buttons/button_titlebar_l.png",
				})

-- FIXME: do these need updating for Fab4Skin?
	local helpBox = 
		Tile:loadTiles({
				       imgpath .. "Popup_Menu/helpbox.png",
				       imgpath .. "Popup_Menu/helpbox_tl.png",
				       imgpath .. "Popup_Menu/helpbox_t.png",
				       imgpath .. "Popup_Menu/helpbox_tr.png",
				       imgpath .. "Popup_Menu/helpbox_r.png",
				       imgpath .. "Popup_Menu/helpbox_br.png",
				       imgpath .. "Popup_Menu/helpbox_b.png",
				       imgpath .. "Popup_Menu/helpbox_bl.png",
				       imgpath .. "Popup_Menu/helpbox_l.png",
			       })

	local scrollBackground =
		Tile:loadVTiles({
					imgpath .. "Scroll_Bar/scrollbar_bkgrd_tch_t.png",
					imgpath .. "Scroll_Bar/scrollbar_bkgrd_tch.png",
					imgpath .. "Scroll_Bar/scrollbar_bkgrd_tch_b.png",
				})

	local scrollBar = 
		Tile:loadVTiles({
					imgpath .. "Scroll_Bar/scrollbar_body_t.png",
					imgpath .. "Scroll_Bar/scrollbar_body.png",
					imgpath .. "Scroll_Bar/scrollbar_body_b.png",
			       })

	local sliderBackground = 
		Tile:loadHTiles({
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_bkgrd_l.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_bkgrd.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_bkgrd_r.png",
			       })

	local sliderBar = 
		Tile:loadHTiles({
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_fill_l.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_fill.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_fill_r.png",
			       })

	local volumeBar =
		Tile:loadHTiles({
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_fill_l.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_fill.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_fill_r.png",
			       })

	local volumeBackground =
		Tile:loadHTiles({
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_bkgrd_l.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_bkgrd.png",
					imgpath .. "Song_Progress_Bar/SP_Bar_Remote/rem_progbar_bkgrd_r.png",
				})

	local popupMask = Tile:fillColor(0x000000e5)

	local textinputCursor = Tile:loadImage(imgpath .. "Text_Entry/Keyboard_Touch/tch_cursor.png")

	local THUMB_SIZE = self:getSettings().THUMB_SIZE
	
	local TITLE_PADDING  = 0
	local CHECK_PADDING  = { 2, 0, 6, 0 }
	local CHECKBOX_RADIO_PADDING  = { 2, 8, 8, 0 }

	--FIXME: paddings here need tweaking for Fab4Skin
	local MENU_ALBUMITEM_PADDING = 0
	local MENU_ALBUMITEM_TEXT_PADDING = { 16, 6, 9, 19 }
	local MENU_PLAYLISTITEM_TEXT_PADDING = { 16, 1, 9, 1 }

	local MENU_CURRENTALBUM_TEXT_PADDING = { 6, 20, 0, 10 }
	local TEXTAREA_PADDING = { 50, 20, 50, 20 }

	local TEXT_COLOR = { 0xE7, 0xE7, 0xE7 }
	local TEXT_COLOR_BLACK = { 0x00, 0x00, 0x00 }
	local TEXT_SH_COLOR = { 0x37, 0x37, 0x37 }

	local SELECT_COLOR = { 0xE7, 0xE7, 0xE7 }
	local SELECT_SH_COLOR = { }

	local TITLE_FONT_SIZE = 20
	local ALBUMMENU_FONT_SIZE = 18
	local ALBUMMENU_SMALL_FONT_SIZE = 14
	local TEXTMENU_FONT_SIZE = 20
	local POPUP_TEXT_SIZE_1 = 34
	local POPUP_TEXT_SIZE_2 = 26
	local TRACK_FONT_SIZE = 18
	local TEXTAREA_FONT_SIZE = 18
	local CENTERED_TEXTAREA_FONT_SIZE = 28
	local TEXTINPUT_FONT_SIZE = 20
	local TEXTINPUT_SELECTED_FONT_SIZE = 28
	local HELP_FONT_SIZE = 18
	local UPDATE_SUBTEXT_SIZE = 20

	local ITEM_ICON_ALIGN   = 'center'
	local THREE_ITEM_HEIGHT = 72
	local FIVE_ITEM_HEIGHT = 45
	local TITLE_BUTTON_WIDTH = 76
	local TITLE_BUTTON_HEIGHT = 47
	local TITLE_BUTTON_PADDING = { 4, 0, 4, 0 }

	local smallSpinny = {
		img = _loadImage(self, "Alerts/wifi_connecting_sm.png"),
		frameRate = 8,
		frameWidth = 26,
		padding = { 0, 0, 8, 0 },
		h = WH_FILL,
	}
	local largeSpinny = {
		img = _loadImage(self, "Alerts/wifi_connecting.png"),
		position = LAYOUT_CENTER,
		w = WH_FILL,
		align = "center",
		frameRate = 8,
		frameWidth = 120,
		padding = { 0, 0, 0, 10 }
	}
	-- convenience method for removing a button from the window
	local noButton = { 
		img = false, 
		bgImg = false, 
		w = 0 
	}

	-- time (hidden off screen)
	s.iconTime = {}
	s.iconTime.x = screenWidth + 10
	s.iconTime.y = screenHeight + 10
	s.iconTime.h = 34
	s.iconTime.layer = LAYER_FRAME
	s.iconTime.position = LAYOUT_NONE
	s.iconTime.font = Font:load(fontpath .. "FreeSansBold.ttf", 12)
	s.iconTime.fg = TEXT_COLOR


---- enable/disable old skin code
if false then

	-- Window title, this is a Label
	s.title = {}
	s.title.h = 47
	s.title.border = 0
	s.title.position = LAYOUT_NORTH
	s.title.bgImg = titleBox
	s.title.order = { "lbutton", "text", "rbutton" }
	s.title.text = {}
        s.title.text.w = WH_FILL
	s.title.text.padding = TITLE_PADDING
	s.title.text.align = "center"
	s.title.text.font = _boldfont(TITLE_FONT_SIZE)
	s.title.text.fg = TEXT_COLOR

	s.titleNoRbutton = _uses(s.title, {
		order = { "lbutton", "text" },
		padding = { 0, 0, TITLE_BUTTON_WIDTH, 0 },
	})

	
	-- Menu with three basic styles: normal, selected and locked
	-- First define the dimesions of the menu
	s.menu = {}
	s.menu.position = LAYOUT_SOUTH
	s.menu.h = FIVE_ITEM_HEIGHT * 5
	s.menu.padding = { 0, 0, 0, 0 }
	s.menu.itemHeight = 45
	s.menu.fg = {0xbb, 0xbb, 0xbb }
	s.menu.font = _boldfont(250)

	-- menu item
	s.item = {}
	s.item.order = { "text", "arrow" }
	s.item.padding = { 4, 0, 0, 0 }
	s.item.text = {}
	s.item.text.padding = { 6, 5, 2, 5 }
	s.item.text.align = "left"
	s.item.text.w = WH_FILL
	s.item.text.font = _boldfont(TEXTMENU_FONT_SIZE)
	s.item.text.fg = TEXT_COLOR
	s.item.text.sh = TEXT_SH_COLOR
	s.item.arrow = {
	      align = ITEM_ICON_ALIGN,
	      img = _loadImage(self, "Icons/selection_right_5line.png")
	}

	-- menu item with no right icon
	s.itemNoArrow = _uses(s.item)

	-- menu items for using different selection icons
	s.itemplay = {}
	s.itemplay = _uses(s.item)
	s.itemadd  = {}
	s.itemadd = _uses(s.item)

	-- checked menu item
	s.itemChecked =
		_uses(s.item, {
			      order = { "text", "check", "arrow" },
			      check = {
					align = ITEM_ICON_ALIGN,
					padding = CHECK_PADDING,
				      img = _loadImage(self, "Icons/icon_check_5line.png")

			      }
		      })

	-- checked menu item, with no action
	s.itemCheckedNoArrow = _uses(s.itemChecked)

	-- selected menu item
	s.selected = {}
	s.selected.item = _uses(s.item, {
		bgImg = fiveItemSelectionBox,
	})

	s.selected.itemplay =
		_uses(s.selected.item, {
			      arrow = {
					--FIXME: need this image
				      img = _loadImage(self, "Icons/icon_check_5line.png")
			      }
		      })

	s.selected.itemadd =
		_uses(s.selected.item, {
			      arrow = {
					--FIXME: need this image
				      img = _loadImage(self, "Icons/icon_check_5line.png")
			      }
		      })

	s.selected.itemChecked = _uses(s.selected.item, {
			      		order = { "text", "check", "arrow" },
					arrow = {
						img = _loadImage(self, "Icons/selection_right_5line.png")
					},
					check = {
						align = ITEM_ICON_ALIGN,
						padding = CHECK_PADDING,
						img = _loadImage(self, "Icons/icon_check_5line.png")
					}
				
				})

	s.selected.itemNoArrow =
		_uses(s.itemNoArrow, {
			      text = {
				      fg = SELECT_COLOR,
				      sh = SELECT_SH_COLOR
			      },
		      })

	s.selected.itemCheckedNoArrow =
		_uses(s.itemCheckedNoArrow, {
			      text = {
				      fg = SELECT_COLOR,
				      sh = SELECT_SH_COLOR
			      },
			      check = {
					align = ITEM_ICON_ALIGN,
					img = _loadImage(self, "Icons/icon_check_5line.png")
			      }
		      })


	-- pressed menu item
	s.pressed = {}
	s.pressed.item = _uses(s.itemChecked, {
			bgImg = fiveItemPressedBox,
	})

	s.pressed.itemplay =
		_uses(s.pressed.item, {
			      arrow = {
					--FIXME: need this image
				      img = _loadImage(self, "Icons/icon_check_5line.png")
			      }
		      })

	s.pressed.itemadd =
		_uses(s.pressed.item, {
			      arrow = {
					--FIXME: need this image
				      img = _loadImage(self, "Icons/icon_check_5line.png")
			      }
		      })

	s.pressed.itemChecked = _uses(s.pressed.item, {
			      		order = { "text", "check", "arrow" },
					arrow = {
						img = _loadImage(self, "Icons/selection_right.png")
					},
					check = {
						align = ITEM_ICON_ALIGN,
						padding = CHECK_PADDING,
						img = _loadImage(self, "Icons/icon_check_5line.png")
					}

				})

	s.pressed.itemNoArrow = _uses(s.itemNoArrow, {
		      bgImg = fiveItemPressedBox,
	})

	s.pressed.itemCheckedNoArrow =
		_uses(s.itemCheckedNoArrow, {
			      bgImg = fiveItemPressedBox,
			      check = {
					align = ITEM_ICON_ALIGN,
					padding = BUTTON_PADDING,
					img = _loadImage(self, "Icons/icon_check_5line.png")
			      }
		      })


	-- locked menu item (with loading animation)
	s.locked = {}
	s.locked.item = _uses(s.pressed.item, {
					arrow = smallSpinny
			})

	s.locked.itemplay = _uses(s.locked.item)
	s.locked.itemadd = _uses(s.locked.item)

	-- menu item choice
	s.item.choice = {}
	s.item.choice.font = _boldfont(TEXTMENU_FONT_SIZE)
	s.item.choice.fg = TEXT_COLOR
	s.item.choice.sh = TEXT_SH_COLOR

	-- selected menu item choice
	s.selected.item.choice = {}
	s.selected.item.choice.font = _boldfont(TEXTMENU_FONT_SIZE)
	s.selected.item.choice.fg = SELECT_COLOR
	s.selected.item.choice.sh = SELECT_SH_COLOR

	-- menu value choice
	s.item.value = {}
	s.item.value.font = _boldfont(TEXTMENU_FONT_SIZE)
	s.item.value.fg = TEXT_COLOR
	s.item.value.sh = TEXT_SH_COLOR

	-- selected menu item choice
	s.selected.item.value = {}
	s.selected.item.value.font = _boldfont(TEXTMENU_FONT_SIZE)
	s.selected.item.value.fg = SELECT_COLOR
	s.selected.item.value.sh = SELECT_SH_COLOR

	-- Text areas
	s.textarea = {}
	s.textarea.w = screenWidth
	s.textarea.padding = TEXTAREA_PADDING 
	s.textarea.font = _boldfont(TEXTAREA_FONT_SIZE)
	s.textarea.fg = TEXT_COLOR
	s.textarea.sh = TEXT_SH_COLOR
	s.textarea.align = "left"
	
	-- Text for centering on the screen
	s.centeredtextarea = {}
	s.centeredtextarea.position = LAYOUT_CENTER
	s.centeredtextarea.w = screenWidth
	s.centeredtextarea.padding = { 50, 20, 20, 2 }
	s.centeredtextarea.font = _boldfont(CENTERED_TEXTAREA_FONT_SIZE)
	s.centeredtextarea.text = {}
	s.centeredtextarea.text.align = 'center'
	s.centeredtextarea.align = 'center'
	s.centeredtextarea.lineHeight = 40
	s.centeredtextarea.fg = TEXT_COLOR
	s.centeredtextarea.sh = TEXT_SH_COLOR
	
	-- Scrollbar
	s.scrollbar = {}
	s.scrollbar.w = 34
	s.scrollbar.border = 0
	s.scrollbar.padding = { 0, 24, 0, 24 }
	s.scrollbar.horizontal = 0
	s.scrollbar.bgImg = scrollBackground
	s.scrollbar.img = scrollBar
	s.scrollbar.layer = LAYER_CONTENT_ON_STAGE

	-- Checkbox
	s.checkbox = {}
	s.checkbox.imgOn = _loadImage(self, "Icons/checkbox_on.png")
	s.checkbox.imgOff = _loadImage(self, "Icons/checkbox_off.png")
	s.item.checkbox = {}
	s.item.checkbox.padding = CHECKBOX_RADIO_PADDING
	s.item.checkbox.align = "right"


	-- Radio button
	s.radio = {}
	s.radio.imgOn = _loadImage(self, "Icons/radiobutton_on.png")
	s.radio.imgOff = _loadImage(self, "Icons/radiobutton_off.png")
	s.item.radio = {}
	s.item.radio.padding = CHECKBOX_RADIO_PADDING
	s.item.radio.align = "right"

	-- Slider
	s.slider = {}
	s.slider.border = 5
	s.slider.horizontal = 1
	s.slider.bgImg = sliderBackground
	s.slider.img = sliderBar

	s.sliderMin = {}
	s.sliderMin.img = _loadImage(self, "Icons/slider_icon_negative.png")
	s.sliderMin.border = { 5, 0, 5, 0 }
	s.sliderMax = {}
	s.sliderMax.img = _loadImage(self, "Icons/slider_icon_positive.png")
	s.sliderMax.border = { 5, 0, 5, 0 }

	s.sliderGroup = {}
	s.sliderGroup.border = { 7, 5, 25, 10 }

	-- Text input
	s.textinput = {}
	s.textinput.h = 35
	s.textinput.border = { 8, 0, 8, 0 }
	s.textinput.padding = { 6, 0, 6, 0 }
	s.textinput.font = _boldfont(TEXTINPUT_FONT_SIZE)
	s.textinput.cursorFont = _boldfont(TEXTINPUT_SELECTED_FONT_SIZE)
	s.textinput.wheelFont = _boldfont(TEXTINPUT_FONT_SIZE)
	s.textinput.charHeight = TEXTINPUT_SELECTED_FONT_SIZE + 10
	s.textinput.fg = TEXT_COLOR_BLACK
	s.textinput.wh = { 0x55, 0x55, 0x55 }
	s.textinput.bgImg = textinputBackground
	s.textinput.cursorImg = textinputCursor
--	s.textinput.enterImg = Tile:loadImage(imgpath .. "Icons/selection_right_5line.png")

	-- Keyboard
	s.keyboard = {}
	s.keyboard.w = WH_FILL
	s.keyboard.h = WH_FILL
	s.keyboard.border = { 8, 0, 8, 0 }

	-- Help menu
	s.help = {}
	s.help.w = screenWidth - 6
	s.help.position = LAYOUT_SOUTH
	s.help.padding = 12
	s.help.font = _font(HELP_FONT_SIZE)
	s.help.fg = TEXT_COLOR
	s.help.bgImg = helpBox
	s.help.align = "left"
	s.help.scrollbar = {}
	s.help.scrollbar.w = 0

	-- Help with soft buttons
	s.softHelp = {}
	s.softHelp.w = screenWidth - 6
	s.softHelp.position = LAYOUT_SOUTH
	s.softHelp.padding = { 12, 12, 12, 42 }
	s.softHelp.font = _font(HELP_FONT_SIZE)
	s.softHelp.fg = TEXT_COLOR
	s.softHelp.bgImg = helpBox
	s.softHelp.align = "left"
	s.softHelp.scrollbar = {}
	s.softHelp.scrollbar.w = 0

	s.softButton1 = {}
	s.softButton1.x = 15
	s.softButton1.y = screenHeight - 33
	s.softButton1.w = (screenWidth / 2) - 20
	s.softButton1.h = 28
	s.softButton1.position = LAYOUT_NONE
	s.softButton1.align = "center"
	s.softButton1.font = _font(HELP_FONT_SIZE + 2)
	s.softButton1.fg = SELECT_COLOR

	s.softButton2 = {}
	s.softButton2.x = (screenWidth / 2) + 5
	s.softButton2.y = screenHeight - 33
	s.softButton2.w = (screenWidth / 2) - 20
	s.softButton2.h = 28
	s.softButton2.position = LAYOUT_NONE
	s.softButton2.align = "center"
	s.softButton2.font = _font(HELP_FONT_SIZE + 2)
	s.softButton2.fg = SELECT_COLOR

	s.window = {}
	s.window.w = screenWidth
	s.window.h = screenHeight

	s.errorWindow = {}
	s.errorWindow.w = screenWidth
	s.errorWindow.h = screenHeight
	s.errorWindow.maskImg = popupMask

	-- Popup window with Icon, no borders
	s.popupArt = {}
	s.popupArt.border = { 0, 0, 0, 0 }
	s.popupArt.maskImg = popupMask

	-- Popup window with Icon
	s.popupIcon = {}
	s.popupIcon.border = { 25, 0, 25, 0 }
	s.popupIcon.maskImg = popupMask

	s.popupIcon.text = {}
	s.popupIcon.text.border = { 15, 18, 15, 0 }
	s.popupIcon.text.font = _boldfont(POPUP_TEXT_SIZE_1)
	s.popupIcon.text.fg = TEXT_COLOR
	s.popupIcon.text.lineHeight = POPUP_TEXT_SIZE_1 + 8
	s.popupIcon.text.sh = TEXT_SH_COLOR
	s.popupIcon.text.align = "top"
	s.popupIcon.text.position = LAYOUT_NORTH
	s.popupIcon.text.h = s.popupIcon.text.lineHeight * 2

	s.popupIcon.icon = largeSpinny

	s.popupIcon.text2 = {}
	s.popupIcon.text2.padding = { 0, 0, 0, 26 }
	s.popupIcon.text2.font = _boldfont(POPUP_TEXT_SIZE_2)
	s.popupIcon.text2.fg = TEXT_COLOR
	s.popupIcon.text2.sh = TEXT_SH_COLOR
	s.popupIcon.text2.align = "bottom"
	s.popupIcon.text2.position = LAYOUT_SOUTH
	s.popupIcon.text2.h = 40

	-- wireless icons for menus
	s.wirelessLevel1 = {}
	s.wirelessLevel1.align = "right"
	s.wirelessLevel1.img = _loadImage(self, "Icons/icon_wireless_1_shadow.png")
	s.wirelessLevel2 = {}
	s.wirelessLevel2.align = "right"
	s.wirelessLevel2.img = _loadImage(self, "Icons/icon_wireless_2_shadow.png")
	s.wirelessLevel3 = {}
	s.wirelessLevel3.align = "right"
	s.wirelessLevel3.img = _loadImage(self, "Icons/icon_wireless_3_shadow.png")
	s.wirelessLevel4 = {}
	s.wirelessLevel4.align = "right"
	s.wirelessLevel4.img = _loadImage(self, "Icons/icon_wireless_4_shadow.png")

	-- XXXX need artwork
	s.wiredEthernetLink = {}
	s.wiredEthernetLink.align = "right"
	s.wiredEthernetLink.img = _loadImage(self, "Icons/icon_nowplaying_indicator_w.png")

	s.wiredEthernetNoLink = {}
	s.wiredEthernetNoLink.align = "right"
	s.wiredEthernetNoLink.img = _loadImage(self, "Icons/icon_nowplaying_indicator_b.png")

	-- Special styles for specific window types

	-- Jive Home Window

	-- Here we add an icon to the window title. This uses a function
	-- that is called at runtime, so for example the icon could change
	-- based on time of day
--[[
	This example is not relevant any more, but I have left it here as an example
	of how a style value can be set dynamically using a lua function.

	s.home.window.title.icon.img = 
		function(widget)
			return _loadImage(self, "head_home.png")
		end
--]]


	-- SlimBrowser applet

	--FIXME: assets need replacing
	s.volumeMin = {}
	s.volumeMin.img = _loadImage(self, "Icons/volume_speaker_l.png")
	s.volumeMin.border = { 5, 0, 5, 0 }
	s.volumeMax = {}
	s.volumeMax.img = _loadImage(self, "Icons/volume_speaker_r.png")
	s.volumeMax.border = { 5, 0, 5, 0 }

	s.volume            = {}
	s.volume.horizontal = 1
	s.volume.img        = volumeBar
	s.volume.bgImg      = volumeBackground
	s.volume.align      = 'center'
	s.volume.padding     = { 0, 0, 0, 15 }

	s.volumeGroup = {}
	s.volumeGroup.border = { 0, 5, 0, 10 }

	s.volumePopup = {}
	s.volumePopup.x = 50
	s.volumePopup.y = screenHeight - 100
	s.volumePopup.w = screenWidth - (s.volumePopup.x * 2)
	s.volumePopup.h = 100
	s.volumePopup.bgImg = helpBox
	s.volumePopup.title = {}
	s.volumePopup.title.border = 10
	s.volumePopup.title.fg = TEXT_COLOR
	s.volumePopup.title.font = _boldfont(HELP_FONT_SIZE)
	s.volumePopup.title.align = "center"
	s.volumePopup.title.bgImg = false

	-- FIXME remove these when SlimBrowser is update to use new
	-- Window title api
	s.title.lbutton        = {
		img            = backButton,
		bgImg          = titlebarButtonBox,
		w              = TITLE_BUTTON_WIDTH,
		h              = TITLE_BUTTON_HEIGHT,
		align          = 'center',
		border         = TITLE_BUTTON_PADDING,
	}
       	s.title.rbutton        = {
       		img            = nowPlayingButton,
		bgImg          = titlebarButtonBox,
		w              = TITLE_BUTTON_WIDTH,
		h              = TITLE_BUTTON_HEIGHT,
		align          = 'center',
		border         = TITLE_BUTTON_PADDING,
	}

	s.title.pressed = _uses(s.title, {
		rbutton = {
			bgImg = pressedTitlebarButtonBox,
		},
		lbutton = {
			bgImg = pressedTitlebarButtonBox,
		}
	})

	-- titles with artwork and song info
	s.albumtitle = _uses(s.title)

	-- no mini-icons in fab4 skin
	s.minititle            = _uses(s.title)
	s.internetradiotitle   = _uses(s.minititle)
	s.favoritestitle       = _uses(s.minititle)
	s.mymusictitle         = _uses(s.minititle)
	s.searchtitle          = _uses(s.minititle)
	s.newmusictitle        = _uses(s.minititle)
	s.infobrowsertitle     = _uses(s.minititle)
	s.albumlisttitle       = _uses(s.minititle)
	s.artiststitle         = _uses(s.minititle)
	s.randomtitle          = _uses(s.minititle)
	s.musicfoldertitle     = _uses(s.minititle)
	s.genrestitle          = _uses(s.minititle)
	s.yearstitle           = _uses(s.minititle)
	s.playlisttitle        = _uses(s.minititle)
	s.currentplaylisttitle = _uses(s.minititle)


	-- title buttons
	-- FIXME button is used as a window style too
	s.button = {
		bgImg    = titlebarButtonBox,
		w        = TITLE_BUTTON_WIDTH,
		h        = TITLE_BUTTON_HEIGHT,
		align    = 'center',
		border   = TITLE_BUTTON_PADDING,
	}
	s.pressed.button = _uses(s.button, {
		bgImg = pressedTitlebarButtonBox,
	})

	s.button_none = _uses(s.button, {
		bgImg    = false,
	})

	s.button_back = _uses(s.button, {
		img      = backButton,
	})
	s.pressed.button_back = _uses(s.pressed.button, {
		img      = backButton,
	})

	s.button_go_now_playing = _uses(s.button, {
		img      = nowPlayingButton,
	})
	s.pressed.button_go_now_playing = _uses(s.pressed.button, {
		img      = nowPlayingButton,
	})

	s.button_help = {
		img = helpButton
	}
	s.pressed.button_help = _uses(s.pressed.button, {
		img      = helpButton,
	})


	-- "buttonlike" menu. all items with selection box and icon
	s.buttonmenu = {}
	s.buttonmenu.padding = 0
	s.buttonmenu.w = WH_FILL
	s.buttonmenu.itemHeight = THREE_ITEM_HEIGHT

	s.button = _uses(s.window)
	s.button.menu = _uses(s.buttonmenu)
	s.button.title = _uses(s.title, {
		h = 55
	})

	s.error = _uses(s.window)
	s.error.menu = _uses(s.menu, {
		h = FIVE_ITEM_HEIGHT * 4,
	})
	s.error.title = _uses(s.titleNoRbutton)
	s.error.text = {
		position = LAYOUT_NORTH,
		border  = { 0, 47, 0, 0 },
		padding = { 10, 15, 0, 0 }, 
		bgImg    = titleBox,
		font     = _font(TITLE_FONT_SIZE),
		h        = 47,
		w        = WH_FILL,
		fg       = TEXT_COLOR,
		align    = "center",
		text     = {
			align = 'center',
		},
	}

	s.keyboard = _uses(s.window)
	s.keyboard.title = _uses(s.titleNoRbutton)

	s.help = _uses(s.window)
	s.help.title = _uses(s.titleNoRbutton)

	s.setuplist = _uses(s.window)
	s.setuplist.title = _uses(s.titleNoRbutton)

	s.settings = _uses(s.window)
	s.settings.title = _uses(s.titleNoRbutton)



	-- 3 options per page, text only
	s.buttonitem = {}
	s.buttonitem.order = { "text", "arrow" }
	s.buttonitem.padding = 0
	s.buttonitem.bgImg = threeItemSelectionBox
	s.buttonitem.text = {}
	s.buttonitem.text.w = WH_FILL
	s.buttonitem.text.h = WH_FILL
	s.buttonitem.text.padding = { 8, 0, 0, 0 }
	s.buttonitem.text.align = "left"
	s.buttonitem.text.font = _boldfont(34)
	s.buttonitem.text.fg = SELECT_COLOR
	s.buttonitem.text.sh = SELECT_SH_COLOR
	s.buttonitem.arrow = {
			img     = _loadImage(self, "Icons/selection_right_3line_off.png"), 
			w       = 37,
			h       = WH_FILL,
			padding = { 0, 0, 8, 0}
	}

	s.buttonitemchecked = _uses(s.buttonitem, {
		order = { 'text', 'check', 'arrow' },
		check = {
			img     = _loadImage(self, "Icons/icon_check_3line.png"), 
			w       = 37,
			h       = WH_FILL,
			padding = { 0, 0, 8, 0}
		}
	})

	-- 3 options per page with icon
	s.buttonicon = {
		w = 72,
		h = WH_FILL,
		padding = { 8, 4, 0, 4 },
		img = false
	}
	s.buttoniconitem = _uses(s.buttonitem, {
		order = { "icon", "text", "arrow" },
		icon  = s.buttonicon,
	})

	s.buttoniconitemchecked = _uses(s.buttoniconitem, {
		order = { 'icon', 'text', 'check', 'arrow' },
		check = {
			img     = _loadImage(self, "Icons/icon_check_3line.png"), 
			w       = 37,
			h       = WH_FILL,
			padding = { 2, 0, 18, 10 },
		}
	})
	

	local buttonPressed = { 
		bgImg = threeItemPressedBox 
	}

	s.pressed.buttoniconitem          = _uses(s.buttoniconitem, buttonPressed)
	s.pressed.buttoniconitemchecked   = _uses(s.buttoniconitemchecked, buttonPressed)

	-- window with one option in "button" style
	s.onebutton = _uses(s.setup)
	s.onebutton.menu = _uses(s.buttonmenu, {
			position = LAYOUT_SOUTH,
			h = THREE_ITEM_HEIGHT
		})

	s.onebutton.text = {}
	s.onebutton.text.w = screenWidth
	s.onebutton.text.position = LAYOUT_NORTH
	s.onebutton.text.padding = { 16, 72, 35, 2 }
	s.onebutton.text.font = _font(36)
	s.onebutton.text.lineHeight = 40
	s.onebutton.text.fg = TEXT_COLOR
	s.onebutton.text.sh = TEXT_SH_COLOR
	
	-- menus with artwork and song info
	-- FIXME: this needs to be tweaked for Fab4Skin
	s.albummenu = {}
	s.albummenu.padding = 0
	s.albummenu.position = LAYOUT_SOUTH
	s.albummenu.h = FIVE_ITEM_HEIGHT * 5

	s.albummenu.itemHeight = FIVE_ITEM_HEIGHT
	s.albummenu.fg = {0xbb, 0xbb, 0xbb }
	s.albummenu.font = _boldfont(250)

	s.album = {}
	s.album.menu = _uses(s.albummenu)
	s.album.title = _uses(s.albumtitle)

	s.multilinemenu = _uses(s.albummenu)

	-- items 5 per page with artwork two lines text
	s.albumitem = {}
	s.albumitem.order = { "icon", "text", "arrow" }
	s.albumitem.padding = MENU_ALBUMITEM_PADDING
	s.albumitem.text = {
		w = WH_FILL,
		h = WH_FILL,
		padding = MENU_ALBUMITEM_TEXT_PADDING,
		font = _font(ALBUMMENU_SMALL_FONT_SIZE),
		line = {
			{
				font = _boldfont(ALBUMMENU_FONT_SIZE),
				height = ALBUMMENU_FONT_SIZE + 2
			}
		},
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
	}
	s.albumitem.arrow = {
		img     = _loadImage(self, "Icons/selection_right_5line.png"), 
		w       = 30,
		h       = WH_FILL,
		padding = { 0, 0, 3, 0}
	}
	s.albumitem.icon = {
		w = THUMB_SIZE,
		h = WH_FILL,
		padding = { 8, 1, 8, 1 },
		-- FIXME: no_artwork image needed in correct size for Fab4Skin; for now, disable it
		img = _loadImage(self, "Icons/menu_album_noartwork_43.png")
	}

	local checkedStyle = {
	      		order = { "icon", "text", "check", "arrow" },
			check = {
				align = "right",
				img = _loadImage(self, "Icons/icon_check_5line.png")
			}
	}
	
	s.multilineitem = _uses(s.albumitem, {
					order = {'text', 'arrow'}
				})
	-- checked albummenu item
	s.albumchecked = _uses(s.albumitem, checkedStyle)

	s.multilinechecked = _uses(s.albumchecked, {
					order = {'text', 'check' },
				})

	-- styles for choose player menu
	s.chooseplayer        = _uses(s.buttoniconitem)
	s.chooseplayerchecked = _uses(s.chooseplayer, checkedStyle)

	s.albumitemplay = _uses(s.albumitem)
	s.albumitemadd  = _uses(s.albumitem)

	s.popupToast = _uses(s.albumitem, 
		{
			order = { 'icon', 'text', 'textarea' },
			textarea = { 
				w = WH_FILL, 
				h = WH_FILL, 
				padding = { 12, 20, 12, 12 } 
			},
			text = { 
				padding = { 6, 15, 8, 8 },
				align = 'top-left',
				w = WH_FILL,
				h = WH_FILL
			},
			icon = { 
				align = 'top-left', 
				border = { 12, 12, 0, 0 } 
			}
		}
	)

	s.albumitemNoArrow = {}
	s.albumitemNoArrow.order = { "text" }
	s.albumitemNoArrow.text = {}
	s.albumitemNoArrow.text.w = WH_FILL
	s.albumitemNoArrow.text.padding = MENU_ALBUMITEM_TEXT_PADDING
	s.albumitemNoArrow.text.align = "top-left"
	s.albumitemNoArrow.text.font = _font(ALBUMMENU_FONT_SIZE)
	s.albumitemNoArrow.text.lineHeight = ALBUMMENU_FONT_SIZE + 4
	s.albumitemNoArrow.text.line = {
		{
			font = _boldfont(ALBUMMENU_FONT_SIZE),
			height = ALBUMMENU_FONT_SIZE + 2
		}
	}
	s.albumitemNoArrow.text.fg = TEXT_COLOR
	s.albumitemNoArrow.text.sh = TEXT_SH_COLOR

	s.multilineitemNoArrow = _uses(s.albumitemNoArrow)

	s.selected.albumitemNoArrow = _uses(s.albumitemNoArrow)
	s.selected.multilineitemNoArrow = _uses(s.multilineitemNoArrow)

	-- selected item with artwork and song info
	s.selected.albumitem = _uses(s.albumitem)
	local pressedAlbumBox = {
		bgImg = fiveItemPressedBox,
		play = {
			img    = _loadImage(self, "Icons/selection_right_3line_on.png"),
		},
	}

	s.pressed.albumitem         = _uses(s.albumitem, pressedAlbumBox)
	s.pressed.albumchecked      = _uses(s.albumchecked, pressedAlbumBox)
	s.pressed.albumitemNoArrow = _uses(s.albumitemNoArrow, pressedAlbumBox)

	s.selected.multilineitem = _uses(s.selected.albumitem, {
				order = { 'text', 'play' },
			})

	s.selected.albumchecked = _uses(s.selected.albumitem, {
	      		order = { "icon", "text", "check", "arrow" },
			arrow = {
				img = _loadImage(self, "Icons/selection_right_5line.png")
			},
			check = {
				align = "right",
				img = _loadImage(self, "Icons/icon_check_5line.png")
			}
	})
	s.selected.multilinechecked = _uses(s.selected.multilineitem, {
	      		order = { "text", "check", "arrow" },
			arrow = {
				img = _loadImage(self, "Icons/selection_right_5line.png")
			},
			check = {
				align = "right",
				img = _loadImage(self, "Icons/icon_check_5line.png")
			}
	})

	s.pressed.chooseplayer        = _uses(s.chooseplayer, buttonPressed)
	s.pressed.chooseplayerchecked = _uses(s.chooseplayerchecked, buttonPressed)

	-- locked item with artwork and song info
	s.locked.albumitem = {}
	s.locked.albumitem.text = {}
	s.locked.albumitem.text.fg = SELECT_COLOR
	s.locked.albumitem.text.sh = SELECT_SH_COLOR

	-- waiting item with spinny
	s.albumitemwaiting = _uses(s.albumitem, {
		icon = smallSpinny,
	})

	s.selected.albumitemwaiting = _uses(s.waiting)


	-- titles with artwork and song info
	s.nowplayingtitle = {}
	s.nowplayingtitle.position = LAYOUT_NORTH
	s.nowplayingtitle.bgImg = titleBox
	s.nowplayingtitle.order = { "lbutton", "text", "rbutton" }
	s.nowplayingtitle.w = screenWidth
	s.nowplayingtitle.h = THUMB_SIZE + 1
	s.nowplayingtitle.border = 4
	s.nowplayingtitle.text = {}
	s.nowplayingtitle.text.padding = { 10, 8, 8, 9 }
	s.nowplayingtitle.text.align = "top-left"
	s.nowplayingtitle.text.font = _font(22)
	s.nowplayingtitle.text.lineHeight = 24
	s.nowplayingtitle.text.line = {
		{
			font = _boldfont(22),
			height = 22
		}
	}
	s.nowplayingtitle.text.fg = SELECT_COLOR
	s.nowplayingtitle.icon = {}
	s.nowplayingtitle.icon.hide = 1

	-- menus with artwork and song info
	s.nowplayingmenu = {}
	s.nowplayingmenu.padding = 2
	s.nowplayingmenu.itemHeight = 61

	-- items with artwork and song info
	--s.nowplayingitem.h = 60
	s.nowplayingitem = {}
	s.nowplayingitem.order = { "icon", "text", "arrow" }
	s.nowplayingitem.text = {}
	s.nowplayingitem.text.w = WH_FILL
	s.nowplayingitem.text.padding = { 12, 8, 8, 8 }
	s.nowplayingitem.text.align = "top-left"
	s.nowplayingitem.text.font = _font(24)
	s.nowplayingitem.text.lineHeight = 27
	s.nowplayingitem.text.line = {
		{
			font = _boldfont(24),
			height = 24
		}
	}
	s.nowplayingitem.text.fg = TEXT_COLOR
	s.nowplayingitem.text.sh = TEXT_SH_COLOR
	s.nowplayingitem.icon = {}
	s.nowplayingitem.icon.w = 125
	s.nowplayingitem.icon.h = 125
	s.nowplayingitem.icon.align = "left"
	s.nowplayingitem.icon.padding = { 5, 0, 0, 0 }


	-- selected item with artwork and song info
	s.selected.nowplayingitem = {}
	s.selected.nowplayingitem.text = {}
	s.selected.nowplayingitem.text.fg = SELECT_COLOR
	s.selected.nowplayingitem.text.sh = SELECT_SH_COLOR
	s.selected.nowplayingitem.bgImg = threeItemSelectionBox


	-- locked item with artwork and song info
	s.locked.nowplayingitem = {}
	s.locked.nowplayingitem.text = {}
	s.locked.nowplayingitem.text.fg = SELECT_COLOR
	s.locked.nowplayingitem.text.sh = SELECT_SH_COLOR
	s.locked.nowplayingitem.bgImg = threeItemSelectionBox


	-- now playing menu item
	s.albumcurrent = {}
	s.albumcurrent.order = { "icon", "play", "text", "arrow" }
	s.albumcurrent.padding = MENU_ALBUMITEM_PADDING
	s.albumcurrent.text = {}
	s.albumcurrent.text.w = WH_FILL
	s.albumcurrent.text.padding = MENU_CURRENTALBUM_TEXT_PADDING
	s.albumcurrent.text.font = _font(ALBUMMENU_FONT_SIZE)
	s.albumcurrent.text.lineHeight = ALBUMMENU_FONT_SIZE + 4
	s.albumcurrent.text.line = {
		{
			font = _boldfont(ALBUMMENU_FONT_SIZE),
			height = ALBUMMENU_FONT_SIZE + 2
		}
	}
	s.albumcurrent.text.fg = TEXT_COLOR
	s.albumcurrent.text.sh = TEXT_SH_COLOR
	s.albumcurrent.icon = {}
	s.albumcurrent.icon.w = THUMB_SIZE
	s.albumcurrent.icon.h = WH_FILL
	s.albumcurrent.icon.align = "left"
	s.albumcurrent.play = {}
	s.albumcurrent.play.align = 'top-left'
	s.albumcurrent.play.img = _loadImage(self, "Icons/icon_nowplaying_indicator_w.png")
	s.albumcurrent.play.padding = { 2, 8, 0, 0 }
	

	-- selected now playing menu item
	s.selected.albumcurrent = {}
	s.selected.albumcurrent.bgImg = threeItemSelectionBox
	s.selected.albumcurrent.text = {}
	s.selected.albumcurrent.text.fg = SELECT_COLOR
	s.selected.albumcurrent.text.sh = SELECT_SH_COLOR
	s.selected.albumcurrent.play = {}
	s.selected.albumcurrent.play.align = 'top-left'
	s.selected.albumcurrent.play.img = _loadImage(self, "Icons/icon_nowplaying_indicator_b.png")
	s.selected.albumcurrent.play.padding = { 2, 8, 0, 0 }


	-- locked now playing menu item (with loading animation)
	s.locked.albumcurrent = {}
	s.locked.albumcurrent.bgImg = threeItemSelectionBox
	s.locked.albumcurrent.text = {}
	s.locked.albumcurrent.text.fg = SELECT_COLOR
	s.locked.albumcurrent.text.sh = SELECT_SH_COLOR

	-- Popup window for current song info
	s.currentsong = {}
	s.currentsong.x = 0
	s.currentsong.y = screenHeight - 93
	s.currentsong.w = screenWidth
	s.currentsong.h = 93
	s.currentsong.bgImg = helpBox
	s.currentsong.font = _font(HELP_FONT_SIZE)
	s.currentsong.albumitem = {}
	s.currentsong.albumitem.border = { 4, 10, 4, 0 }
	s.currentsong.albumitem.icon = { }
	s.currentsong.albumitem.icon.align = "top"

	local POPUP_HEIGHT = 200
	-- Popup window for play/add without artwork
	s.popupplay= {}
	s.popupplay.x = 0
	s.popupplay.y = screenHeight - 96
	s.popupplay.w = screenWidth - 20
	s.popupplay.h = POPUP_HEIGHT

	-- for textarea properties in popupplay
	s.popupplay.padding = { 12, 12, 12, 0 }
	s.popupplay.fg = TEXT_COLOR
	s.popupplay.font = _font(TRACK_FONT_SIZE)
	s.popupplay.align = "top-left"
	s.popupplay.scrollbar = {}
	s.popupplay.scrollbar.w = 0

	s.popupplay.text = {}
	s.popupplay.text.w = screenWidth
	s.popupplay.text.h = POPUP_HEIGHT
	s.popupplay.text.padding = { 20, 20, 20, 20 }
	s.popupplay.text.font = _font(TRACK_FONT_SIZE)
	s.popupplay.text.lineHeight = TRACK_FONT_SIZE + 2
	s.popupplay.text.line = {
		nil,
		{
			font = _boldfont(TRACK_FONT_SIZE),
			height = 32
		}
	}
	s.popupplay.text.fg = TEXT_COLOR
	s.popupplay.text.align = "top-left"

	-- Popup window for information display
	s.popupinfo = {}
	s.popupinfo.x = 0
	s.popupinfo.y = screenHeight - 96
	s.popupinfo.w = screenWidth
	s.popupinfo.h = POPUP_HEIGHT
	s.popupinfo.bgImg = helpBox
	s.popupinfo.text = {}
	s.popupinfo.text.w = screenWidth
	s.popupinfo.text.h = POPUP_HEIGHT
	s.popupinfo.text.padding = { 14, 24, 14, 14 }
	s.popupinfo.text.font = _boldfont(HELP_FONT_SIZE)
	s.popupinfo.text.lineHeight = HELP_FONT_SIZE + 3
	s.popupinfo.text.fg = TEXT_COLOR
	s.popupinfo.text.align = "left"


	-- background style should start at x,y = 0,0
        s.iconbg = {}
        s.iconbg.x = 0
        s.iconbg.y = 0
        s.iconbg.h = screenHeight
        s.iconbg.w = screenWidth
	s.iconbg.border = { 0, 0, 0, 0 }
	s.iconbg.position = LAYOUT_NONE
end -- OLD STYLES




	---- REVIEWED BELOW THIS LINE ----

--------- CONSTANTS ---------

	local _progressBackground = Tile:loadImage(imgpath .. "Alerts/alert_progress_bar_bkgrd.png")

	local _progressBar = Tile:loadHTiles({
		nil,
		imgpath .. "Alerts/alert_progress_bar_body.png",
		imgpath .. "Alerts/progress_bar_line.png",
	})



--------- DEFINES ---------

	local _buttonMenu = {
		padding = 0,
		w = WH_FILL,
		itemHeight = THREE_ITEM_HEIGHT,
	}

	local _buttonItem = {
		order = { "text", "arrow" },
		padding = 0,
		bgImg = threeItemSelectionBox,
		text = {
		w = WH_FILL,
		h = WH_FILL,
		padding = { 8, 0, 0, 0 },
		align = "left",
		font = _boldfont(34),
		fg = SELECT_COLOR,
		sh = SELECT_SH_COLOR,
		},
		arrow = {
			img     = _loadImage(self, "Icons/selection_right_3line_off.png"), 
			w       = 37,
			h       = WH_FILL,
			padding = { 0, 0, 8, 0}
		}
	}


--------- DEFAULT WIDGET STYLES ---------
	--
	-- These are the default styles for the widgets 

	s.window = {
		w = screenWidth,
		h = screenHeight,
	}

	s.popup = _uses(s.window, {
		border = { 25, 0, 25, 0 },
		maskImg = popupMask,
	})

	s.title = {
		h = 47,
		border = 0,
		position = LAYOUT_NORTH,
		bgImg = titleBox,
		order = { "lbutton", "text", "rbutton" },
		text = {
			w = WH_FILL,
			padding = TITLE_PADDING,
			align = "center",
			font = _boldfont(TITLE_FONT_SIZE),
			fg = TEXT_COLOR,
		}
	}

	s.menu = {
		position = LAYOUT_CENTER,
		padding = { 0, 0, 0, 0 },
		itemHeight = 45,
		fg = {0xbb, 0xbb, 0xbb },
		font = _boldfont(250),
	}

	s.item = {
		order = { "text", "arrow" },
		padding = { 4, 0, 0, 0 },
		text = {
			padding = { 6, 5, 2, 5 },
			align = "left",
			w = WH_FILL,
			font = _boldfont(TEXTMENU_FONT_SIZE),
			fg = TEXT_COLOR,
			sh = TEXT_SH_COLOR,
		},
		arrow = {
	      		align = ITEM_ICON_ALIGN,
	      		img = _loadImage(self, "Icons/selection_right_5line.png")
		},
	}

	s.itemplay = _uses(s.item, {
		arrow = {
			img = _loadImage(self, "Icons/selection_play_3line_on.png")
		},
	})

	s.itemadd = _uses(s.item, {
		arrow = {
			img = _loadImage(self, "Icons/selection_add_3line_off.png")
		},
	})


	s.itemChecked = _uses(s.item, {
		order = { "text", "check", "arrow" },
		check = {
			align = ITEM_ICON_ALIGN,
			padding = CHECK_PADDING,
			img = _loadImage(self, "Icons/icon_check_5line.png")
	      	}
	})

	s.itemNoArrow = _uses(s.item, {
		order = { 'text' },
	})
	s.itemCheckedNoArrow = _uses(s.item, {
		order = { 'text', 'check' },
	})

	s.selected = {
		item = _uses(s.item),
		itemChecked = _uses(s.itemChecked),
	}

	s.pressed = {
		item = _uses(s.item, {
			bgImg = fiveItemPressedBox,
		}),
		itemChecked = _uses(s.itemChecked, {
			bgImg = fiveItemPressedBox,
		}),
		itemplay = _uses(s.itemplay, {
			bgImg = fiveItemPressedBox,
		}),
		itemadd = _uses(s.itemadd, {
			bgImg = fiveItemPressedBox,
		}),
		itemNoArrow = _uses(s.itemNoArrow, {
			bgImg = fiveItemPressedBox,
		}),
		itemCheckedNoArrow = _uses(s.itemCheckedNoArrow, {
			bgImg = fiveItemPressedBox,
		}),
	}

	s.locked = {
		item = _uses(s.pressed.item, {
			arrow = smallSpinny
		}),
		itemChecked = _uses(s.pressed.itemChecked, {
			arrow = smallSpinny
		}),
		itemplay = _uses(s.pressed.itemplay, {
			arrow = smallSpinny
		}),
		itemadd = _uses(s.pressed.itemadd, {
			arrow = smallSpinny
		}),
		itemNoArrow = _uses(s.itemNoArrow, {
			arrow = smallSpinny
		}),
		itemCheckedNoArrow = _uses(s.itemCheckedNoArrow, {
			arrow = smallSpinny
		}),
	}

	s.helptext = {
		w = screenWidth - 6,
		position = LAYOUT_SOUTH,
		padding = 12,
		font = _font(HELP_FONT_SIZE),
		fg = TEXT_COLOR,
		bgImg = helpBox,
		align = "left",
		scrollbar = {
			w = 0,
		},
	}

	s.scrollbar = {
		w = 34,
		border = 0,
		padding = { 0, 24, 0, 24 },
		horizontal = 0,
		bgImg = scrollBackground,
		img = scrollBar,
		layer = LAYER_CONTENT_ON_STAGE,
	}

	s.text = {
		w = screenWidth,
		padding = TEXTAREA_PADDING,
		font = _boldfont(TEXTAREA_FONT_SIZE),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "left",
	}


--------- SPECIAL WIDGETS ---------


	-- text input
	s.textinput = {
		h = 35,
		border = { 8, 0, 8, 0 },
		padding = { 6, 0, 6, 0 },
		font = _boldfont(TEXTINPUT_FONT_SIZE),
		cursorFont = _boldfont(TEXTINPUT_SELECTED_FONT_SIZE),
		wheelFont = _boldfont(TEXTINPUT_FONT_SIZE),
		charHeight = TEXTINPUT_SELECTED_FONT_SIZE + 10,
		fg = TEXT_COLOR_BLACK,
		wh = { 0x55, 0x55, 0x55 },
		bgImg = textinputBackground,
		cursorImg = textinputCursor,
--		enterImg = Tile:loadImage(imgpath .. "Icons/selection_right_5line.png"),
	}

	-- keyboard
	-- XXXX pressed button states?
	s.keyboard = {
		w = WH_FILL,
		h = WH_FILL,
		border = { 8, 0, 8, 0 },
	}

	s.keyboard.button = {
        	padding = 0,
		w = 45,
		h= 45,
        	font = _boldfont(18),
        	fg = TEXT_COLOR,
        	bgImg = buttonBox,
        	align = 'center',
	}

	s.keyboard.shift = _uses(s.keyboard.button, {
		bgImg = fiveItemSelectionBox, padding = 2, w = 75, h = 35
	})
	s.keyboard.space = _uses(s.keyboard.shift, {
		padding = 2, w = 100, h = 35
	})
	s.keyboard.back = _uses(s.keyboard.button, {
		img = _loadImage(self, "Icons/Mini/left_arrow.png")
	})
	s.keyboard.qwertyLower = _uses(s.keyboard.button, {
		img = _loadImage(self, "Icons/icon_shift_off.png")
	})
	s.keyboard.qwertyUpper = _uses(s.keyboard.button, {
		img = _loadImage(self, "Icons/icon_shift_on.png")
	})

	s.keyboard.enter = _uses(s.keyboard.shift, {
		img = _loadImage(self, "Icons/Mini/right_arrow.png")
	})
	s.keyboard.search = _uses(s.keyboard.button, {
		img = _loadImage(self, "Icons/Mini/icon_search.png")
	})

	s.keyboard.pressed = {
		shift = _uses(s.keyboard.shift, {
			bgImg = fiveItemSelectionBoxPressed
		}),
		space = _uses(s.keyboard.space, {
			bgImg = fiveItemSelectionBoxPressed
		}),
	}


--------- WINDOW STYLES ---------
	--
	-- These styles override the default styles for a specific window

	-- setup window
	s.setuplist = _uses(s.window)


	-- window with one option in "button" style
	s.onebutton = _uses(s.setuplist)
	s.onebutton.menu = _uses(_buttonMenu, {
			position = LAYOUT_SOUTH,
			h = THREE_ITEM_HEIGHT
	})

	s.onebutton.menu.item = {
		order = { "text", "arrow" },
		padding = 0,
		bgImg = threeItemSelectionBox,
		text = {
			w = WH_FILL,
			h = WH_FILL,
			padding = { 8, 0, 0, 0 },
			align = "left",
			font = _boldfont(34),
			fg = TEXT_COLOR,
			sh = TEXT_SH_COLOR,
			arrow = {
				img = _loadImage(self, "Icons/selection_right_3line_off.png"), 
				w = 37,
				h = WH_FILL,
				padding = { 0, 0, 8, 0},
			}
		}
	}

	s.onebutton.menu.selected = {
		item = _uses(s.onebutton.menu.item)
	}
	s.onebutton.menu.pressed = {
		item = _uses(s.onebutton.menu.item, buttonPressed)
	}

	s.onebutton.text = {
		w = screenWidth,
		position = LAYOUT_NORTH,
		padding = { 16, 72, 35, 2 },
		font = _font(36),
		lineHeight = 40,
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
	}


	-- window with multiple options in "button" style
	s.buttonlist = _uses(s.window)

	s.buttonlist.title = _uses(s.title, {
		h = 55
	})

	s.buttonlist.menu = {
		padding = 0,
		w = WH_FILL,
		itemHeight = THREE_ITEM_HEIGHT,
	}

	s.buttonlist.menu.item = _uses(_buttonItem, {
		order = { "icon", "text", "arrow" },
		icon  = s.buttonicon,
	})

	s.buttonlist.menu.itemChecked = _uses(_buttonItem, {
		order = { 'icon', 'text', 'check', 'arrow' },
		check = {
			img     = _loadImage(self, "Icons/icon_check_3line.png"), 
			w       = 37,
			h       = WH_FILL,
			padding = { 2, 0, 18, 10 },
		}
	})

	s.buttonlist.menu.selected = {
		item = _uses(s.buttonlist.menu.item),
		itemChecked = _uses(s.buttonlist.menu.itemChecked),
	}
	s.buttonlist.menu.pressed = {
		item = _uses(s.buttonlist.menu.item, buttonPressed),
		itemChecked = _uses(s.buttonlist.menu.itemChecked, buttonPressed),
	}

	-- popup "spinny" window
	s.waiting = _uses(s.popup)

	s.waiting.text = {
		border = { 15, 0, 15, 20 },
		font = _boldfont(POPUP_TEXT_SIZE_1),
		fg = TEXT_COLOR,
		lineHeight = POPUP_TEXT_SIZE_1 + 8,
		sh = TEXT_SH_COLOR,
		align = "top",
		position = LAYOUT_NORTH,
		h = (POPUP_TEXT_SIZE_1 + 8 ) * 2,
	}

	s.waiting.subtext = {
		padding = { 0, 0, 0, 26 },
		font = _boldfont(POPUP_TEXT_SIZE_2),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "bottom",
		position = LAYOUT_SOUTH,
		h = 40,
	}

	-- input window (including keyboard)
	-- XXX: needs layout
	s.input = _uses(s.window)

	-- error window
	-- XXX: needs layout
	s.error = _uses(s.window)

	-- update window
	s.update = _uses(s.popup)

	s.update.text = {
		border = { 15, 0, 15, 20 },
		font = _boldfont(POPUP_TEXT_SIZE_1),
		fg = TEXT_COLOR,
		lineHeight = POPUP_TEXT_SIZE_1 + 8,
		sh = TEXT_SH_COLOR,
		align = "top",
		position = LAYOUT_NORTH,
		h = (POPUP_TEXT_SIZE_1 + 8) * 2,
	}

	s.update.subtext = {
		padding = { 0, 0, 0, 30 },
		font = _font(UPDATE_SUBTEXT_SIZE),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "bottom",
		position = LAYOUT_SOUTH,
		h = 40,
	}

	s.update.progress = {
		border = 10,
		position = LAYOUT_SOUTH,
		horizontal = 1,
		bgImg = _progressBackground,
		img = _progressBar,
	}

	-- typical text list window
	-- XXXX todo
	s.textlist = _uses(s.window)

	-- iconlist window
	s.iconlist = _uses(s.window, {
		menu = {
			item = {
				order = { "icon", "text", "arrow" },
				padding = MENU_ALBUMITEM_PADDING,
				text = {
					w = WH_FILL,
					h = WH_FILL,
					padding = MENU_ALBUMITEM_TEXT_PADDING,
					font = _font(ALBUMMENU_SMALL_FONT_SIZE),
					line = {
						{
							font = _boldfont(ALBUMMENU_FONT_SIZE),
							height = ALBUMMENU_FONT_SIZE + 2
						}
					},
					fg = TEXT_COLOR,
					sh = TEXT_SH_COLOR,
				},
				icon = {
					w = THUMB_SIZE,
					h = WH_FILL,
					padding = { 8, 1, 8, 1 },
					img = _loadImage(self, "Icons/menu_album_noartwork_43.png")
				},
				arrow = {
				      align = ITEM_ICON_ALIGN,
					padding = { 8, 1, 8, 1 },
				      img = _loadImage(self, "Icons/selection_right_5line.png")
				},
			},
		},
	})


	s.iconlist.menu.itemChecked = _uses(s.iconlist.menu.item, {
		order = { 'icon', 'text', 'check', 'arrow' },
		check = {
			align = ITEM_ICON_ALIGN,
			padding = CHECK_PADDING,
			img = _loadImage(self, "Icons/icon_check_5line.png")
		},
	})
	s.iconlist.menu.selected = {
                item = _uses(s.iconlist.menu.item),
                itemChecked = _uses(s.iconlist.menu.itemChecked),
        }
        s.iconlist.menu.pressed = {
                item = _uses(s.iconlist.menu.item, buttonPressed),
                itemChecked = _uses(s.iconlist.menu.itemChecked, buttonPressed),
        }
	s.iconlist.menu.locked = {
		item = _uses(s.iconlist.menu.pressed.item, {
			arrow = smallSpinny
		}),
		itemChecked = _uses(s.iconlist.menu.pressed.itemChecked, {
			arrow = smallSpinny
		}),
	}


	-- information window
	s.information = _uses(s.window)


	-- help window (likely the same as information)
	s.help = _uses(s.window)


	--tracklist window
	-- XXXX todo
	-- identical to textlist but has icon in upper left of titlebar
	s.tracklist = _uses(s.textlist)

	s.tracklist.title = _uses(s.title, {
		order = { 'lbutton', 'icon', 'text', 'rbutton' },		
		icon  = {
			w = THUMB_SIZE,
			h = WH_FILL,
			padding = { 8, 1, 8, 1 },
			img = _loadImage(self, "Icons/menu_album_noartwork_43.png")
		},
	})

	--playlist window
	-- identical to iconlist but with some different formatting on the text
	s.playlist = _uses(s.iconlist, {
		menu = {
			item = {
				text = {
					padding = MENU_PLAYLISTITEM_TEXT_PADDING,
					line = {
						{
							font = _boldfont(ALBUMMENU_FONT_SIZE),
							height = ALBUMMENU_FONT_SIZE
						},
						{
							height = ALBUMMENU_SMALL_FONT_SIZE + 2
						},
						{
							height = ALBUMMENU_SMALL_FONT_SIZE + 2
						},
					},	
				},
			},
		},
	})
	s.playlist.menu.itemChecked = _uses(s.playlist.menu.item, {
		order = { 'icon', 'text', 'check', 'arrow' },
		check = {
			align = ITEM_ICON_ALIGN,
			padding = CHECK_PADDING,
			img = _loadImage(self, "Icons/icon_check_5line.png")
		},
	})
	s.playlist.menu.selected = {
                item = _uses(s.playlist.menu.item),
                itemChecked = _uses(s.playlist.menu.itemChecked),
        }
        s.playlist.menu.pressed = {
                item = _uses(s.playlist.menu.item, buttonPressed),
                itemChecked = _uses(s.playlist.menu.itemChecked, buttonPressed),
        }
	s.playlist.menu.locked = {
		item = _uses(s.playlist.menu.pressed.item, {
			arrow = smallSpinny
		}),
		itemChecked = _uses(s.playlist.menu.pressed.itemChecked, {
			arrow = smallSpinny
		}),
	}


	-- toast popup
	s.toast = {
		x = 0,
		y = screenHeight - 93,
		w = screenWidth,
		h = 93,
		bgImg = helpBox,
		font = _font(HELP_FONT_SIZE),
	}

	s.icontoast = _uses(s.toast, {
		xxxx = {
			order = { 'icon', 'text' },
			text = { 
				padding = { 10, 12, 12, 12 } ,
				align = 'top-left',
				w = WH_FILL,
				h = WH_FILL
			},
			icon = { 
				align = 'top-left', 
				border = { 12, 12, 0, 0 },
				img = _loadImage(self, "Icons/menu_album_noartwork_64.png"),
				h = WH_FILL,
				w = 64,
			}
		}
	})


--------- BUTTONS ---------


	-- XXXX could use a factory function
	local _button = {
		bgImg = titlebarButtonBox,
		w = TITLE_BUTTON_WIDTH,
		h = TITLE_BUTTON_HEIGHT,
		align = 'center',
		border = TITLE_BUTTON_PADDING,
	}
	local _pressed_button = _uses(_button, {
		bgImg = pressedTitlebarButtonBox,
	})


	-- invisible button
	s.button_none = _uses(_button, {
		bgImg    = false
	})

	s.button_back = _uses(_button, {
		img      = backButton,
	})
	s.pressed.button_back = _uses(_pressed_button, {
		img      = backButton,
	})

	s.button_go_now_playing = _uses(_button, {
		img      = nowPlayingButton,
	})
	s.pressed.button_go_now_playing = _uses(_pressed_button, {
		img      = nowPlayingButton,
	})

	s.button_help = _uses(_button, {
		img = helpButton,
	})
	s.pressed.button_help = _uses(_pressed_button, {
		img      = helpButton,
	})



	local _buttonicon = {
		w = 72,
		h = WH_FILL,
		padding = { 8, 4, 0, 4 },
		img = false
	}

	s.region_US = _uses(_buttonicon, { 
		img = _loadImage(self, "Icons/icon_region_americas_64.png")
	})
	s.region_XX = _uses(_buttonicon, { 
		img = _loadImage(self, "Icons/icon_region_other_64.png")
	})
	s.wlan = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/icon_wireless_64.png")
	})
	s.wired = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/icon_ethernet_64.png")
	})


--------- ICONS --------

	-- icons used for 'waiting' and 'update' windows
	local _icon = {
		w = WH_FILL,
		align = "center",
		position = LAYOUT_CENTER,
		padding = { 0, 0, 0, 10 }
	}

	s.iconConnecting = _uses(_icon, {
		img = _loadImage(self, "Alerts/wifi_connecting.png"),
		frameRate = 8,
		frameWidth = 120,
	})

	s.iconConnected = _uses(_icon, {
		img = _loadImage(self, "Alerts/connecting_success_icon.png"),
	})

	s.iconSoftwareUpdate = _uses(_icon, {
		img = _loadImage(self, "Icons/icon_firmware_update_100.png"),
	})

	s.iconPower = _uses(_icon, {
		img = _loadImage(self, "Alerts/popup_shutdown_icon.png"),
	})

	s.iconLocked = _uses(_icon, {
		img = _loadImage(self, "Alerts/popup_locked_icon.png"),
	})

	s.iconAlarm = _uses(_icon, {
		img = _loadImage(self, "Alerts/popup_alarm_icon.png"),
	})


	-- button icons, on left of menus
	local _buttonicon = {
		w = 72,
		h = WH_FILL,
		padding = { 8, 4, 0, 4 },
	}

	s.player_transporter = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/transporter.png"),
	})
	s.player_squeezebox = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/squeezebox.png"),
	})
	s.player_squeezebox2 = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/squeezebox.png"),
	})
	s.player_squeezebox3 = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/squeezebox3.png"),
	})
	s.player_boom = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/boom.png"),
	})
	s.player_slimp3 = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/slimp3.png"),
	})
	s.player_softsqueeze = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/softsqueeze.png"),
	})
	s.player_controller = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/controller.png"),
	})
	s.player_receiver = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/receiver.png"),
	})
	s.player_squeezeplay = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/squeezeplay.png"),
	})
	s.player_http = _uses(_buttonicon, {
		img = _loadImage(self, "Icons/Players/http.png"),
	})


	-- indicator icons, on right of menus
	local _indicator = {
		align = "right",
	}

	s.wirelessLevel1 = _uses(_indicator, {
		img = _loadImage(self, "Icons/icon_wireless_1_shadow.png")
	})

	s.wirelessLevel2 = _uses(_indicator, {
		img = _loadImage(self, "Icons/icon_wireless_2_shadow.png")
	})

	s.wirelessLevel3 = _uses(_indicator, {
		img = _loadImage(self, "Icons/icon_wireless_3_shadow.png")
	})

	s.wirelessLevel4 = _uses(_indicator, {
		img = _loadImage(self, "Icons/icon_wireless_4_shadow.png")
	})


--------- ICONBAR ---------

	-- time (hidden off screen)
	s.iconTime = {
		x = screenWidth + 10,
		y = screenHeight + 10,
		layer = LAYER_FRAME,
		position = LAYOUT_NONE,
	}



--------- LEGACY STYLES TO KEEP SLIMBROWSER GOING --------
if true then

	-- XXXX todo

	-- BEGIN NowPlaying skin code
	-- this skin is established in two forms,
	-- one for the Screensaver windowStyle (ss), one for the browse windowStyle (browse)
	-- a lot of it can be recycled from one to the other

	local NP_TRACK_FONT_SIZE = 26

	-- Title
	s.ssnptitle = _uses(s.title, {
		rbutton  = {
			font    = _font(14),
			fg      = TEXT_COLOR,
			bgImg   = titlebarButtonBox,
			w       = TITLE_BUTTON_WIDTH,
			h       = TITLE_BUTTON_HEIGHT,
			padding =  TITLE_BUTTON_PADDING,
			padding = { 10, 0, 10, 0},
			align   = 'center',
		}
	})

	-- nptitle style is the same for all windowStyles
	s.browsenptitle = _uses(s.ssnptitle)
	s.largenptitle  = _uses(s.ssnptitle)


	-- pressed styles
	s.ssnptitle.pressed = _uses(s.ssnptitle, {
		lbutton = {
			bgImg = pressedTitlebarButtonBox,
		},
		rbutton = {
			bgImg = pressedTitlebarButtonBox,
		},
	})

	s.browsenptitle.pressed = _uses(s.ssnptitle.pressed)
	s.largenptitle.pressed = _uses(s.ssnptitle.pressed)

	-- Song
	s.ssnptrack = {
		border = { 4, 0, 4, 0 },
		text = {
			w = WH_FILL,
			padding = { 220, 52, 20, 10 },
			align = "left",
        		font = _font(NP_TRACK_FONT_SIZE),
			lineHeight = NP_TRACK_FONT_SIZE + 4,
			position = LAYOUT_WEST,
			fg = TEXT_COLOR,
        		line = {{
				font = _boldfont(NP_TRACK_FONT_SIZE),
				height = NP_TRACK_FONT_SIZE + 4,
				}},
		},
	}

	-- nptrack is identical between all windowStyles
	s.browsenptrack = _uses(s.ssnptrack)
	s.largenptrack  = _uses(s.ssnptrack)

	-- Artwork
	local ARTWORK_SIZE    = self:getSettings().nowPlayingBrowseArtworkSize
	local SS_ARTWORK_SIZE = self:getSettings().nowPlayingSSArtworkSize
	local browseArtWidth  = ARTWORK_SIZE
	local ssArtWidth      = SS_ARTWORK_SIZE

	s.ssnpartwork = {
		w = ssArtWidth,
		border = { 10, 50, 10, 0 },
		position = LAYOUT_WEST,
		align = "center",
		artwork = {
			align = "center",
			padding = 0,
			-- FIXME: change name to not be specific to icon width in filename
			img = _loadImage(self, "Icons/icon_album_noartwork_336.png"),
		},
	}

	s.browsenpartwork = _uses(s.ssnpartwork)
	s.largenpartwork = _uses(s.ssnpartwork)

	local topPadding = screenHeight/2 + 10
	local rightPadding = screenWidth/2 - 15
	local buttonPadding = { 10, 5, 10, 5 }

	s.ssnpcontrols = {
		order = { 'rew', 'play', 'fwd', 'vol' },
		position = LAYOUT_NONE,
		x = rightPadding,
		y = topPadding,
		bgImg = buttonBox,
		rew = {
			align = 'center',
			padding = buttonPadding,
			img = _loadImage(self, "Player_Controls/icon_toolbar_rew.png"),
		},
		play = {
			align = 'center',
			padding = buttonPadding,
			img = _loadImage(self, "Player_Controls/icon_toolbar_play.png"),
		},
		pause = {
			align = 'center',
			padding = buttonPadding,
			img = _loadImage(self, "Player_Controls/icon_toolbar_pause.png"),
		},
		fwd = {
			align = 'center',
			padding = buttonPadding,
			img = _loadImage(self, "Player_Controls/icon_toolbar_ffwd.png"),
		},
		vol = {
			align = 'center',
			padding = buttonPadding,
			img = _loadImage(self, "Player_Controls/icon_toolbar_vol_up.png"),
		},
	}
	
	s.browsenpcontrols = _uses(s.ssnpcontrols)
	s.largenpcontrols  = _uses(s.ssnpcontrols)

	-- Progress bar
	s.ssprogress = {
		position = LAYOUT_SOUTH,
		padding = { 10, 10, 10, 5 },
		order = { "elapsed", "slider", "remain" },
		elapsed = {
			align = 'right',
		},
		remain = {
			align = 'left',
		},
		text = {
			w = 75,
			align = 'right',
			padding = { 8, 0, 8, 15 },
			font = _boldfont(18),
			fg = { 0xe7,0xe7, 0xe7 },
			sh = { 0x37, 0x37, 0x37 },
		},
	}

	s.ssprogress.elapsed = _uses(s.ssprogress.text)
	s.ssprogress.remain = _uses(s.ssprogress.text)

	s.browseprogress = _uses(s.ssprogress)
	s.largeprogress  = _uses(s.ssprogress)

	s.ssprogressB = {
		horizontal  = 1,
		bgImg       = sliderBackground,
		img         = sliderBar,
		position    = LAYOUT_SOUTH,
		padding     = { 0, 0, 0, 15 },
	}

	s.browseprogressB = _uses(s.ssprogressB)
	s.largeprogressB  = _uses(s.ssprogressB)

	-- special style for when there shouldn't be a progress bar (e.g., internet radio streams)
	s.ssprogressNB = {
		position = LAYOUT_SOUTH,
		padding = { 0, 0, 0, 5 },
		order = { "elapsed" },
		text = {
			w = WH_FILL,
			align = "center",
			padding = { 0, 0, 0, 5 },
			font = _boldfont(18),
			fg = { 0xe7, 0xe7, 0xe7 },
			sh = { 0x37, 0x37, 0x37 },
		},
	}

	s.ssprogressNB.elapsed = _uses(s.ssprogressNB.text)

	s.browseprogressNB = _uses(s.ssprogressNB)
	s.largeprogressNB  = _uses(s.ssprogressNB)


end -- LEGACY STYLES


end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

