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
        var Clazz = Y.Base.create (
            "ic_manage_window",
            Y.Base,
            [],
            {
                //
                // dealing with two layouts, one outer and one inner
                // (we may add more... or the left layout could
                // move to a stand alone widget), the layouts set up
                // units in which to load the "panes"
                //
                _layouts: {
                    outer: null,
                    left:  null
                },

                //
                // the panes represent the stuff displayed to the user
                // with two panes being essentially fixed (menu+tools)
                // and controlled by us, and the third being just a
                // container which will handle loading and unloading
                // of more interesting content
                //
                _panes: {
                    menu:    null,
                    tools:   null,
                    content: null
                },

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this.on(
                        "contentPaneShowContent",
                        Y.bind(this._onContentPaneShowContent, this)
                    );

                    this._initOuterLayout();
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");
                    Y.each(
                        this._panes,
                        function (v, k, obj) {
                            v.destroy();
                            v = null;
                            delete obj[k];
                        }
                    );
                    Y.each(
                        this._layouts,
                        function (v, k, obj) {
                            v.destroy();
                            v = null;
                            delete obj[k];
                        }
                    );
                    this._panes = null;
                    this._layouts = null;

                    // detach any event handlers ...
                    this.detach("contentPaneShowContent");
                },

                _initOuterLayout: function () {
                    Y.log(Clazz.NAME + "::_initOuterLayout");
                    this._buildOuterLayout("outer");

                    this._layouts.outer.on(
                        "render",
                        Y.bind(this._onOuterLayoutRender, this)
                    );
                    this._layouts.outer.render();
                },

                _buildOuterLayout: function (key) {
                    Y.log(Clazz.NAME + "::_buildOuterLayout");
                    var YAHOO = Y.YUI2;
                    this._layouts[key] = new YAHOO.widget.Layout(
                        {
                            units: [
                                {
                                    position: "top",
                                    height:   46,
                                    zIndex:   0,
                                    body:     "manage_header"
                                },
                                {
                                    position: "left",
                                    body:     "manage_left_layout",
                                    width:    170,
                                    zIndex:   1
                                },
                                {
                                    position: "center",
                                    body:     "manage_window_content_pane",
                                    zIndex:   0,
                                    scroll:   false
                                }
                            ]
                        }
                    );
                },

                _onOuterLayoutRender: function () {
                    Y.log(Clazz.NAME + "::_onOuterLayoutRender");
                    this._layouts.outer.removeListener("render");

                    this._initLeftLayout(
                        this._layouts.outer,   // parent layout
                        "left",                // unit
                        "left"                 // new layout key
                    );

                    this._initContentPane(
                        this._layouts.outer,
                        "center"
                    );

                    //Y.log(Clazz.NAME + "::_onOuterLayoutRender should fire *initial* show content event");
                    this.fire(
                        "contentPaneShowContent",
                        "remote_dashboard",
                        null,
                        "primary"
                    );
                },

                _initLeftLayout: function (parent_layout, unit_name, layouts_key_name) {
                    Y.log(Clazz.NAME + "::_initLeftLayout");
                    this._buildLeftLayout(
                        parent_layout,
                        unit_name,
                        layouts_key_name
                    );

                    this._layouts[layouts_key_name].on(
                        "render", 
                        Y.bind(this._onLeftLayoutRender, this)
                    );

                    this._layouts[layouts_key_name].render();
                },

                _buildLeftLayout: function (parent_layout, unit_name, layouts_key_name) {
                    Y.log(Clazz.NAME + "::_buildLeftLayout");
                    var YAHOO = Y.YUI2;

                    var left_unit = parent_layout.getUnitByPosition(unit_name).get("wrap");

                    this._layouts[layouts_key_name] = new YAHOO.widget.Layout(
                        left_unit,
                        {
                            parent: parent_layout,
                            units: [
                                {
                                    position: "top",
                                    body:     "manage_menu_pane",
                                    header:   "Menu",
                                    height:   210,
                                    zIndex:   2,
                                    scroll:   null
                                },
                                {
                                    position: "center",
                                    header:   "Tools",
                                    body:     "manage_tools_pane",
                                    zIndex:   0
                                }
                            ]
                        }
                    );
                },

                _onLeftLayoutRender: function () {
                    Y.log(Clazz.NAME + "::_onLeftLayoutRender");
                    this._layouts.left.removeListener("render");

                    this._initMenuPane(
                        this._layouts.left,  // layout
                        "top",               // unit
                        "vertical"           // menu orientation
                    );
                    this._initToolsPane(
                        this._layouts.left,  // layout
                        "center"             // unit
                    );
                },

                _initMenuPane: function (layout, unit_position, orientation) {
                    Y.log(Clazz.NAME + "::_initMenuPane");
                    var menu_unit = layout.getUnitByPosition(unit_position).body.childNodes[0];

                    var menu_config = Y.merge(
                        this.get("menu_config"),
                        {
                            orientation: orientation,

                            //
                            // this is 'render_to' instead of 'render' so that we can
                            // control when render is called based on the successful
                            // return of an I/O request to get the rest of the menu's
                            // configuration (eventually it'd be nice to make this
                            // function more like a normal YUI widget)
                            //
                            render_to:   menu_unit
                        }
                    );
                    this._panes.menu = new Y.IC.ManageMenu (menu_config);

                    // need to let the nodemenu's dropdowns spill into the the next unit
                    var cbody = Y.one( layout.getUnitByPosition(unit_position).body );
                    cbody.addClass("allow-overflow");
                    Y.one( cbody._node.parentNode.parentNode.parentNode ).addClass("allow-overflow");

                    // capture the menu events -
                    // 'click' is prevented by the node-menunav plugin, wtf!?
                    // so we use mouse down, but then have to do some clean up..
                    Y.delegate(
                        "mousedown",
                        this._onSubmenuMousedown,
                        this._panes.menu.get("boundingBox"),
                        "em.yui3-menuitem-content, a.yui3-menuitem-content",
                        this
                    );
                },

                _initToolsPane: function (layout, unit_position) {
                    Y.log(Clazz.NAME + "::_initToolsPane");
                    var unit = layout.getUnitByPosition(unit_position);

                    var tools_config = Y.merge(
                        this.get("tools_config"),
                        {
                            window:      this,
                            layout:      layout,
                            layout_unit: unit,
                            render:      unit.body.childNodes[0]
                        }
                    );

                    this._panes.tools = new Y.IC.ManageTools (tools_config);
                },

                _initContentPane: function (layout, unit_position) {
                    Y.log(Clazz.NAME + "::_initContentPane");
                    var unit = layout.getUnitByPosition(unit_position);

                    //
                    // The unit's height includes the header, etc. so to get an accurate
                    // width/height we want to take the displayable region of the body
                    // element contained in the unit
                    //
                    var unit_body_region = Y.one(unit.body).get("region");

                    this._panes.content = new Y.IC.ManageWindowContent (
                        {
                            render: unit.body.childNodes[0],
                            width:  unit_body_region.width,
                            height: unit_body_region.height
                        }
                    );
                },

                _onSubmenuMousedown: function (e) {
                    Y.log(Clazz.NAME + "::_onSubmenuMousedown: " + e.target.get("id") );

                    // hide the submenu after a selection -- there
                    // seems to be a selection bug in here - should
                    // also clear the selection...
                    var menu_nav_node = this._panes.menu.get("boundingBox");

                    var menuNav = menu_nav_node.menuNav;
                    menuNav._hideAllSubmenus(menu_nav_node);

                    // .split doesn't return "the rest" with a limit, so use a capturing regex
                    var matches = e.target.get("id").match("^manage_menu_item-([^-]+)(?:-([^-]+)-([^-]+)(?:-([^-]+)(?:-(.+))?)?)?$");

                    if (Y.Lang.isArray(matches)) {
                        //Y.log(Clazz.NAME + "::_onSubmenuMousedown - matches: " + Y.dump(matches));
                        var kind       = matches[1];
                        var clazz      = matches[2] || "";
                        var action     = matches[3] || "";
                        var addtl_args = matches[4] || "";

                        // TODO: add passing of configuration information
                        this.fire(
                            "contentPaneShowContent",
                            kind,
                            clazz,
                            action,
                            addtl_args
                        );
                    }
                    else {
                        Y.log(Clazz.NAME + "::_onSubmenuMousedown - Unable to parse submenu id: " + e.target.get("id"));
                    }
                },

                _onContentPaneShowContent: function (e, kind, clazz, action, addtl_args) {
                    Y.log(Clazz.NAME + "::_onContentPaneShowContent");
                    var config = {
                        kind:   kind,
                        config: {
                            clazz:      clazz,
                            action:     action,
                            addtl_args: addtl_args
                        }
                    };
                    //Y.log(Clazz.NAME + "::_onContentPaneShowContent: config: " + Y.dump(config));

                    this._panes.content.fire(
                        "showContent",
                        config
                    );
                }
            },
            {
                ATTRS: {
                    menu_config: {
                        value: null
                    },
                    tools_config: {
                        value: null
                    }
                }
            }
        );

        //
        // make all of that into a Singleton so that I can access the
        // window stuff from any module
        //
        var instance = null;
        Y.namespace("IC").ManageWindow = function (config) {
            if (! instance) {
                instance =  new Clazz (config);
            }

            return instance;
        };
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-css",
            "base-base",
            "base-build",
            "yui2-layout",
            "yui2-resize",
            "ic-manage-window-menu",
            "ic-manage-window-tools",
            "ic-manage-window-content"
        ]
    }
);
