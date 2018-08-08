local lang = {
  ruRU = {
    name = 'CSF',
    title = 'Кросс-сервер друзья',
    newCharTitle = 'Добавить нового персонажа (name-server name)',
    newCharAdd = ADD,
    newCharCancel = CANCEL,
    noZone = '(оффлайн)',
    notFound = '(не найден в сообществах)',
    unknownZone = '(неизвестная локация)',
    menuInvite = INVITE,
    menuWhisper = WHISPER,
    menuDelete = REMOVE,
    menuCancel = CANCEL
  },
  enUS = {
    name = 'CSF',
    title = 'Cross Server Friends',
    newCharTitle = 'Add new character (format: name-server)',
    newCharAdd = ADD,
    newCharCancel = CANCEL,
    noZone = '(offline)',
    notFound = '(not found in communities)',
    unknownZone = '(unknown location)',
    menuInvite = INVITE,
    menuWhisper = WHISPER,
    menuDelete = REMOVE,
    menuCancel = CANCEL
  }
};

SBN = {
  hooks = {},
  ui = {separator = 
    {
    			hasArrow = false;
    			dist = 0;
    			isTitle = true;
    			isUninteractable = true;
    			notCheckable = true;
    			iconOnly = true;
    			icon = "Interface\\Common\\UI-TooltipDivider-Transparent";
    			tCoordLeft = 0;
    			tCoordRight = 1;
    			tCoordTop = 0;
    			tCoordBottom = 1;
    			tSizeX = 0;
    			tSizeY = 8;
    			tFitDropDownSizeX = true;
    			iconInfo = {
    				tCoordLeft = 0,
    				tCoordRight = 1,
    				tCoordTop = 0,
    				tCoordBottom = 1,
    				tSizeX = 0,
    				tSizeY = 8,
    				tFitDropDownSizeX = true
    		}
    }
  },
  elements = {},
  lang = lang[GetLocale()] or lang['enUS'],
  misc = {
    listItemHeight = 34,
    tabIndex = -1,
    buttons = 10
  }
};

SBN_Settings = SBN_Settings or { friends = {} };

SBN.addNewChar = function(name)
  local arr = { strsplit("-", name) };
  onlyName = arr[1];
  if onlyName == '' then
    return;
  end
  arr[1] = nil;
  server = arr[2] or GetRealmName();
  info = {
    fullname = name,
    name = onlyName,
    server = server,
    zone = nil,
    data = strlower(name:gsub("%s+", ""))
  };
  table.insert(SBN_Settings.friends, info);
  SBN.update();
end;

SBN.updateFriendList = function()
  SBN.ui.list.range = #SBN_Settings.friends;
  local offset = math.floor(math.abs(SBN.ui.list.scrollBar:GetValue()));
  for i = 1, #SBN.ui.list.items do
    local button = SBN.ui.list.items[i];
    local friend = SBN.getFriendByIndex(i + offset);
    if friend == nil then
      button:Hide();
    else
      button:Show();
      button.name:SetText(friend.name .. ' (' .. friend.server .. ')');
      button.info:SetText(friend.zone == nil and SBN.getSubText(friend.online) or friend.zone);
      if friend.online == 1 then
        button.status:SetTexture(FRIENDS_TEXTURE_ONLINE);
      else
        button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE);
      end;
      button.friend = friend;
      --button.name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
    end;
  end;
end;

SBN.getSubText = function(status)
  if status == -1 then
    return SBN.lang.notFound;
  end;
  if status == 0 then
    return SBN.lang.noZone;
  end;

  return SBN.lang.unknownZone;
end;

SBN.friendInvite = function(button)
  if button.friend ~= nil then
    InviteUnit(button.friend.data);
  end;
end;

SBN.getFriendByIndex = function(id)
  if id == 0 or id > #SBN_Settings.friends then
    return nil;
  end;

  return SBN_Settings.friends[id];
end;

SBN.update = function()
  for id, friend in pairs(SBN_Settings.friends) do
    SBN_Settings.friends[id].online = -1;
    SBN_Settings.friends[id].zone = nil;
  end;
  
  local maxValue = #SBN_Settings.friends - #SBN.ui.list.items;
  SBN.ui.list.scrollBar:SetMinMaxValues(0, maxValue < 0 and 0 or maxValue);
  
  if C_Club.IsRestricted() == 1 or C_Club.IsEnabled() ~= true then
    SBN.updateFriendList();
    return;
  end;

  local clubs = C_Club.GetSubscribedClubs();
  if clubs == nil then
    SBN.updateFriendList();
    return;
  end;

  for id, club in pairs(clubs) do
    if club ~= nil and club.clubType == 1 then -- do not check guild, battle.net
      local memberIds = C_Club.GetClubMembers(club.clubId);
      for i, memberId in pairs(memberIds) do
        local member = C_Club.GetMemberInfo(club.clubId, memberId);
        if member ~= nil then
          SBN.updateStatusSlug(strlower(member.name or ''), member.zone);
        end;
      end;
    end;
  end;

  -- C_Club.GetClubMembers(114444492)
  -- C_Club.GetMemberInfo(114444492, 2591)
  
  friends = SBN_Settings.friends;
  table.sort(friends, function (left, right)
    return left.online > right.online;
  end);
  SBN_Settings.friends = friends;
  
  SBN.updateFriendList();
end;

SBN.updateStatusSlug = function(name, zone)
  for id, friend in pairs(SBN_Settings.friends) do
    if friend.data == name then
      SBN_Settings.friends[id].online = zone == nil and 0 or 1;
      SBN_Settings.friends[id].zone = zone == nil and '' or zone;
    end;
  end;
end;

SBN.showMenu = function(button)
  UIDropDownMenu_Initialize(_G['CrossServerFriendsDropDown'], function()
    local info = UIDropDownMenu_CreateInfo();
    info.notCheckable, info.isTitle, info.text = true, true, button.friend.name;
    UIDropDownMenu_AddButton(info);

    info = UIDropDownMenu_CreateInfo();
    info.notCheckable, info.text, info.func = true, SBN.lang.menuInvite, function()
      InviteUnit(button.friend.data);
    end;
    UIDropDownMenu_AddButton(info);

    info.text, info.func = SBN.lang.menuWhisper, function()
      ChatFrame_SendTell(button.friend.data);
    end;
    UIDropDownMenu_AddButton(info);

    UIDropDownMenu_AddSeparator();

    info.text, info.func = SBN.lang.menuDelete, function()
      friend = button.friend;
      for i, f in ipairs(SBN_Settings.friends) do
        if friend.fullname == f.fullname then
          table.remove(SBN_Settings.friends, i);
          SBN.update();
          return;
        end;
      end;
    end;
    UIDropDownMenu_AddButton(info);

    UIDropDownMenu_AddSeparator();
    info.text, info.func = SBN.lang.menuCancel, nil;
    UIDropDownMenu_AddButton(info);
  end, 'MENU');
 
  ToggleDropDownMenu(1, nil, _G['CrossServerFriendsDropDown'], 'cursor');
end;

-- New tab in "Social".
FriendsFrame.numTabs = FriendsFrame.numTabs + 1;
SBN.misc.tabIndex = FriendsFrame.numTabs;
local SBNTabButton = CreateFrame('Button', 'FriendsFrameTab' .. (SBN.misc.tabIndex), FriendsFrame, 'FriendsFrameTabTemplate');
SBNTabButton:SetText(SBN.lang.name);
SBNTabButton:SetID(SBN.misc.tabIndex);
SBNTabButton:SetScript('OnEvent', FriendsFrame_Update);
SBNTabButton:SetPoint('LEFT', _G['FriendsFrameTab' .. (SBN.misc.tabIndex - 1)], 'RIGHT', -15, 0)

-- Creating content tab in "Social"
local SBNTabContent = CreateFrame('Button', 'FriendsFrameBattleNetContent', FriendsFrame);
SBNTabContent:SetPoint("TOPLEFT", 6, -61);
SBNTabContent:SetWidth(324);
SBNTabContent:SetHeight(346);
SBNTabContent:Hide();
SBN.ui.TabContent = SBNTabContent;
local SBNList = CreateFrame('ScrollFrame', 'FriendsFrameBattleNetList', SBNTabContent, 'HybridScrollFrameTemplate');
SBNList:SetPoint('TOPLEFT', 0, 0);
SBNList:SetWidth(324);
SBNList:SetHeight(336);
SBNList:SetScript('OnVerticalScroll', function(self, offset)
	 FauxScrollFrame_OnVerticalScroll(self, offset, SBN.misc.listItemHeight, update)
end)

SBNList.stepSize = 1; -- required for mouse whell
SBNList.range    = #SBN_Settings.friends;
SBNList.buttonHeight = SBN.misc.listItemHeight;
SBN.ui.list = SBNList;

local SBNListSlider = CreateFrame('Slider', 'FriendsFrameBattleNetListScrollBar', SBNList, 'MinimalHybridScrollBarTemplate');
SBNListSlider:SetPoint('TOPRIGHT', 0, -18);
SBNListSlider:SetOrientation('VERTICAL');
-- Либо я что-то не понимаю, либо слайдер делал какой-то мудак.
SBNListSlider:SetHeight(336 - 18 * 2);
SBNListSlider:SetScript('OnValueChanged', function ()
  SBN.updateFriendList(); -- only UI.
end);


-- Creating button list.
SBNList.items = {};
for i = 1, SBN.misc.buttons do
  local item = CreateFrame('Button', 'FriendsFrameBattleNetListButton' .. i, SBNList, 'SBNFriendTemplate');
	 item:SetPoint('TOPLEFT', SBNList, 0, -SBN.misc.listItemHeight * (i - 1));
  item:SetSize(302, SBN.misc.listItemHeight);
  item:Show();
  item.id = i;
  --item.gameIcon:Hide();
  item:SetScript('OnClick', function(self, btn) if btn == 'RightButton' then SBN.showMenu(self); end; end);
  table.insert(SBNList.items, item);
end

-- Add new friend button.
local AddButton = CreateFrame('Button', 'FriendsFrameBattleNetAdd', SBNTabContent, 'UIPanelButtonTemplate');
AddButton:SetSize(131, 21);
AddButton:SetPoint('BOTTOMLEFT', SBNList, -2, -23);
AddButton:SetText(SBN.lang.newCharAdd);
AddButton:SetScript('OnClick', function() StaticPopup_Show('SBN_NEW_CHAR_ADD') end);
AddButton:Show();

-- Popup with adding new friend.
StaticPopupDialogs['SBN_NEW_CHAR_ADD'] = {
  text = SBN.lang.newCharTitle,
  button1 = SBN.lang.newCharAdd,
  button2 = SBN.lang.newCharCancel,
  OnAccept = function(self)
    SBN.addNewChar(self.editBox:GetText());
  end,
  EditBoxOnEnterPressed = function(self)
	  	local parent = self:GetParent();
	  	SBN.addNewChar(parent.editBox:GetText());
	  	parent:Hide();
  end,
  EditBoxOnEscapePressed = function(self)
	  	self:GetParent():Hide();
  end,
  timeout = 0,
  whileDead = true,
  hasEditBox = true,
	 exclusive = true,
  preferredIndex = 3
};

-- Hook: switch friends tabs.
SBN.hooks.FriendsFrame_Update = FriendsFrame_Update;

FriendsFrame_Update = function(...)
  if (FriendsFrame.selectedTab == SBN.misc.tabIndex) then
    FriendsFrameIcon:SetTexture('Interface/FriendsFrame/Battlenet-Portrait');
    FriendsFrameTitleText:SetText(SBN.lang.title);
    FriendsFrameInset:SetPoint('TOPLEFT', 4, -60);
    FriendsFrame_ShowSubFrame(SBN.lang.title); -- hide some trash.
    SBN.ui.TabContent:Show();
    SBN.update();
  else
    SBN.ui.TabContent:Hide();
  end
  SBN.hooks.FriendsFrame_Update(...);
end

-- Fire update of all friends frames.
FriendsFrame_Update();
