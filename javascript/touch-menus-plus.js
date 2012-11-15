// touch-menus-plus.js
// Eric Knibbe
// Makes navigation links with drop-down menus usable on iOS by only enabling
// the link if its submenu is visible. This is only required if JavaScript is
// used to hide and show submenus, since iOS accounts for CSS-based menus by
// preventing a :hover region's links from activating until any divs it'll
// reveal are displayed.
// Assumes your menu's items are <li> elements each containing an <a> followed
// by a <div> containing the submenu.
// This script must be loaded after the menu markup.

// Change this to your menu's id value
menuId = 'nav';

if(RegExp(" Mobile\\b").test(navigator.userAgent) && RegExp(" AppleWebKit/").test(navigator.userAgent)) {
	var menuItems = document.getElementById(menuId).getElementsByTagName('li');
	for (var item = menuItems[0]; item != null; item = item.nextSibling) {
		if (item.nodeName === "LI") {
			var itemChildren = item.childNodes;
			var itemAnchors = new Array();
			var itemSubs = new Array();
			for (var itemChild = itemChildren[0]; itemChild != null; itemChild = itemChild.nextSibling) {
				if (itemChild.nodeName === "A") {
					itemAnchors.push(itemChild);
				} else if (itemChild.nodeName === "DIV") {
					itemSubs.push(itemChild);
				}
			}
			if (itemAnchors.length > 0 && itemSubs.length > 0) {
				itemAnchors[0].type = itemAnchors[0].getAttribute('href');
				itemAnchors[0].href = '#';
				var defaultSubmenuStyle = getComputedStyle(itemSubs[0], '');
				itemSubs[0].defaultDisplay = defaultSubmenuStyle.getPropertyValue('display');
				itemSubs[0].defaultLeft = defaultSubmenuStyle.getPropertyValue('left');
				itemSubs[0].defaultOverflow = defaultSubmenuStyle.getPropertyValue('overflow');
				itemSubs[0].defaultRight = defaultSubmenuStyle.getPropertyValue('right');
				itemSubs[0].defaultVisibility = defaultSubmenuStyle.getPropertyValue('visibility');
				item.ontouchstart = function(){
					var itemAnchor = this.getElementsByTagName('a')[0];
					var itemSub = this.getElementsByTagName('div')[0];
					var currentSubmenuStyle = getComputedStyle(itemSub, '');
					if ((currentSubmenuStyle.getPropertyValue('display') !== itemSub.defaultDisplay) ||
							(currentSubmenuStyle.getPropertyValue('left') !== itemSub.defaultLeft) ||
							(currentSubmenuStyle.getPropertyValue('overflow') !== itemSub.defaultOverflow) ||
							(currentSubmenuStyle.getPropertyValue('right') !== itemSub.defaultRight) ||
							(currentSubmenuStyle.getPropertyValue('visibility') !== itemSub.defaultVisibility)) {
						itemAnchor.href = itemAnchor.getAttribute('type');
						itemAnchors[0].type = '';
					}
				};
			}
		}
	}
}
