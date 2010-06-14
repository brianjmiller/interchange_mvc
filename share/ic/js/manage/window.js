/*
    Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
       
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see: http://www.gnu.org/licenses/ 
*/

YUI.add(
    "ic-manage-window",
    function (Y) {

        var ManageWindow = Y.Base.create (
            "ic_manage_window",     // module identifier  
            Y.Base,                 // what to extend     
            [Y.IC.HistoryManager],  // classes to mix in  
            {                       // overrides/additions
                // Instance Members //
                _menu:          null,
                _dt_container:  null,
                _dv_container:  null,
                _layouts:       {
                    'outer':  null,
                    'left':   null,
                    'center': null
                },

                STATE_PROPERTIES: {
                    'lc': 1  /*
                              * layout-center, possible values:
                              *  lc: 'maxdv' // max center unit
                              *  lc: 'maxdt' // max top unit
                              *  lc: 'dtdv'  // top at 152
                              */
                },


/*
NAM!!!
break the initializer up into manageable checks, and add member variables for the units.
then add state/history management, and draw an appropriate layout for the state
then add the dashboard layout as a no state/history default
 */
                // Base Methods //
                initializer: function (config) {
                    Y.log('window::initializer');
                    // build the main layout
                    this.buildOuterLayout('outer');
                    this._layouts['outer'].on('render', Y.bind(this.onOuterLayoutRender, this));
                    this._layouts['outer'].render();

                    // listen for widget loaded events 
                    //  and decorate our layout to match the contents
                    Y.on("manageContainer:widgetloaded", function (e) {
                        var container = e.target;
                        var widget = container.get('current');
                        var layout_unit = container.get('layout_unit');
                        if (widget && widget.getHeaderText) {
                            layout_unit.set('header', widget.getHeaderText());
                        }
                    });
                },

                buildOuterLayout: function (key) {
                    Y.log('window::buildOuterLayout');
                    var YAHOO = Y.YUI2;
                    this._layouts[key] = new YAHOO.widget.Layout(
                        {
                            units: [
                                {
                                    position: "top",
                                    height: 26,
                                    zIndex: 0,
                                    body: "manage_header"
                                },
                                {
                                    position: "left",
                                    body: "manage_subcontainer",
                                    width: 170,
                                    zIndex: 1
                                },
                                {
                                    position: "center",
                                    zIndex: 0,
                                    scroll: false
                                },
                                {
                                    position: "bottom",
                                    body: "manage_footer",
                                    zIndex: 0,
                                    height: 40,
                                    resize: true
                                }
                            ]
                        }
                    );
                },

                buildLeftLayout: function (layout, unit, key) {
                    Y.log('window::buildLeftLayout');
                    Y.log('layout -> unit -> key');
                    Y.log(layout);
                    Y.log(unit);
                    Y.log(key);
                    var YAHOO = Y.YUI2;
                    var left = layout.getUnitByPosition(unit).get("wrap");
                    this._layouts[key] = new YAHOO.widget.Layout(
                        left,
                        {
                            parent: layout,
                            units: [
                                {
                                    position: "top",
                                    body: "manage_menu",
                                    header: "Main Menu",
                                    height: 212,
                                    zIndex: 2,
                                    scroll: null
                                },
                                {
                                    position: "center",
                                    body: "manage_quick",
                                    header: "Quick Links",
                                    zIndex: 0
                                }
                            ]
                        }
                    );
                },

                buildCenterLayout: function (layout, unit, key) {
                    Y.log('window::buildCenterLayout');
                    var YAHOO = Y.YUI2;
                    var center = layout.getUnitByPosition(unit).get("wrap");
                    var layout_region = Y.DOM.region(center);  // used to initially render the top
                                                               // unit to the max available hide
                                                               // effectively hiding the detail view
                    this._layouts[key] = new YAHOO.widget.Layout(
                        center,
                        {
                            parent: layout,
                            units: [
                                {
                                    position: "top",
                                    body: "manage_datatable",
                                    header: "Records",
                                    height: layout_region.height,
                                    zIndex: 0,
                                    collapse: true,
                                    animate: false,
                                    scroll: false
                                },
                                {
                                    position: "center",
                                    body: "manage_detail",
                                    header: "Details",
                                    zIndex: 0,
                                    scroll: true
                                }

                            ]
                        }
                    );
                },

                onOuterLayoutRender: function () {
                    Y.log('window::onOuterLayoutRender');
                    Y.bind(
                        this.buildLeftLayout,
                        this,                     // context
                        this._layouts['outer'],   // parent layout
                        'left',                   // unit
                        'left'                    // new layout key
                    )();
                    Y.bind(
                        this.buildCenterLayout, 
                        this,                     // context
                        this._layouts['outer'],   // parent layout
                        'center',                 // unit
                        'center'                  // new layout key
                    )();

                    this._layouts['left'].on('render', Y.bind(this.onLeftLayoutRender, this));
                    this._layouts['center'].on('render', Y.bind(this.onCenterLayoutRender, this));

                    this._layouts['left'].render();
                    this._layouts['center'].render();
                },

                onLeftLayoutRender: function () {
                    Y.log('window::onLeftLayoutRender');
                    Y.bind(
                        this.initMainMenu, 
                        this,                   // context
                        this._layouts['left'],  // layout
                        'top',                  // unit
                        'vertical'              // menu orientation
                    )();
                },

                onCenterLayoutRender: function () {
                    Y.log('window::onCenterLayoutRender');
                    // load from history
                },


                initMainMenu: function(layout, unit, orientation) {
                    Y.log('window::initMainMenu');
                    var menu_unit = layout.getUnitByPosition(unit).body.childNodes[0];
                    this._menu = new Y.IC.ManageMenu(
                        {
                            orientation: orientation,
                            render_to: menu_unit
                        }
                    );

                    // need to let the nodemenu's dropdowns spill into the the next unit
                    var cbody = Y.one(layout.getUnitByPosition(unit).body);
                    cbody.addClass('allow-overflow');
                    Y.one(cbody._node.parentNode.parentNode.parentNode).addClass('allow-overflow');

                    // capture the menu events
                    Y.delegate(
                        "mousedown",
                        this.onSubmenuMousedown,
                        this._menu.get("boundingBox"),
                        'em.yui3-menuitem-content',
                        this
                    );
                    Y.delegate(
                        "mousedown",
                        this.onSubmenuMousedown,
                        this._menu.get("boundingBox"),
                        'a.yui3-menuitem-content',
                        this
                    );
                },

                onSubmenuMousedown: function (e) {
                    Y.log('window::onSubmenuMousedown');
                    // hide the submenu after a selection
                    menu_nav_node = this._menu.get("boundingBox")
                    var menuNav = menu_nav_node.menuNav;
                    menuNav._hideAllSubmenus(menu_nav_node);

                    // maximize the top unit (the datatable)
                    var center = this._layouts['outer'].getUnitByPosition("center").get("wrap");
                    var layout_region = Y.DOM.region(center);
                    var top = this._layouts['center'].getUnitByPosition("top");                        
                    if (this._dv_container) {
                        this._dv_container.unloadWidget();
                    }
                    top.set('height', layout_region.height);

                    // set the header to the content of the menu item that was clicked
                    top.set('header', e.target.get('text'));

                    // if there's no datatable container, create one
                    if (!this._dt_container) {
                        var dt_container_unit = top.body.childNodes[0];
                        this._dt_container = new Y.IC.ManageContainer(
                            {
                                render_to: dt_container_unit,
                                prefix: '_dt',
                                layout: this._layouts['center'],
                                layout_unit: top
                            }
                        );
                    }

                    // load the Widget into the Data Table container
                    Y.bind(this._dt_container.loadWidget, this._dt_container)(e);

                    // capture clicks on the "detail" link of the option column
                    Y.delegate(
                        "click",
                        this.onDetailClick,
                        center,
                        'a.manage_function_link',
                        this
                    );
                },

                onDetailClick: function (e) {
                    Y.log('window::onDetailClick');
                    var top = this._layouts['center'].getUnitByPosition("top");
                    var center = this._layouts['center'].getUnitByPosition("center");

                    // shrink the top unit and show only 3 rows in the datatable, 
                    //  making room for the detail view without closing the datatable
                    top.set('height', 152);
                    if (this._dt_container) {
                        var dt = this._dt_container.get('current');
                        if (dt instanceof Y.YUI2.widget.DataTable) {
                            Y.log('shrink the datatable to 3 rows')
                        }
                    }

                    // if there's no detail view container, create one
                    if (!this._dv_container) {
                        var dv_container_unit = center.body.childNodes[0];
                        this._dv_container = new Y.IC.ManageContainer(
                            {
                                render_to: dv_container_unit,
                                prefix: '_dv',
                                layout: this._layouts['center'],
                                layout_unit: center
                            }
                        );
                    }

                    // load the Widget into the Detail View container
                    Y.bind(this._dv_container.loadWidget, this._dv_container)(e);

                    // capture clicks on the tabs of the detail view
                    /*
                    Y.delegate(
                        "click",
                        onTabPanelClick,
                        center,
                        'div.yui3-tab-panel'
                    );
                    */
                },

                destructor: function () {
                    Y.log('window::destructor');
                    this._menu.destroy();
                    this._menu = null;
                    this._dt_container.destroy();
                    this._dt_container = null;
                    this._dt_container.destroy();
                    this._dv_container = null;
                    this._layouts['left'].destroy();
                    this._layouts['center'].destroy();
                    this._layouts['outer'].destroy();
                    this._layouts['left'] = null;
                    this._layouts['center'] = null;
                    this._layouts['outer'] = null;
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindow = ManageWindow;
    },
    "@VERSION@",
    {
        requires: [
            "base-base",
            "ic-manage-widget-container",
            "ic-manage-widget-menu",
            "ic-history-manager",
            "yui2-layout",
            "yui2-resize",
            "yui2-animation"
        ]
    }
);
