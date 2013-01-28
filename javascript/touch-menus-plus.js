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

// Change this to your menu's "id" value
var menuId = 'nav';

function handle_touchstart(item) {
	return function () {
		var itemAnchor = item.getElementsByTagName('a')[0],
				itemSub = item.getElementsByTagName('div')[0],
				currentSubmenuStyle = window.getComputedStyle(itemSub, '');
		if ((currentSubmenuStyle.getPropertyValue('display') !== itemSub.defaultDisplay) ||
				(currentSubmenuStyle.getPropertyValue('left') !== itemSub.defaultLeft) ||
				(currentSubmenuStyle.getPropertyValue('overflow') !== itemSub.defaultOverflow) ||
				(currentSubmenuStyle.getPropertyValue('right') !== itemSub.defaultRight) ||
				(currentSubmenuStyle.getPropertyValue('visibility') !== itemSub.defaultVisibility)) {
			itemAnchor.href = itemAnchor.getAttribute('type');
		}
	};
}

if (navigator.userAgent.match(/iPhone|iPod|iPad/i)) {
	var menuItems = document.getElementById(menuId).getElementsByTagName('li');
	var item = null;
	for (item = menuItems[0]; item !== null; item = item.nextSibling) {
		if (item.nodeName === "LI") {
			var itemChild, itemAnchor, itemSub = null;
			for (itemChild = item.childNodes[0]; itemChild !== null; itemChild = itemChild.nextSibling) {
				if (itemChild.nodeName === "A") {
					itemAnchor = itemChild;
				} else if (itemChild.nodeName === "DIV") {
					itemSub = itemChild;
				}
				if (itemAnchor !== null && itemSub !== null) {
					var defaultSubmenuStyle = window.getComputedStyle(itemSub, '');
					itemAnchor.type = itemAnchor.getAttribute('href');
					itemAnchor.href = '#';
					itemSub.defaultDisplay = defaultSubmenuStyle.getPropertyValue('display');
					itemSub.defaultLeft = defaultSubmenuStyle.getPropertyValue('left');
					itemSub.defaultOverflow = defaultSubmenuStyle.getPropertyValue('overflow');
					itemSub.defaultRight = defaultSubmenuStyle.getPropertyValue('right');
					itemSub.defaultVisibility = defaultSubmenuStyle.getPropertyValue('visibility');
					item.ontouchstart = handle_touchstart(item);
					break;
				}
			}
		}
	}
}
