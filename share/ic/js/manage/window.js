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
        var MW = Y.Base.create (
            // module identifier  
            "ic_manage_window",

            // what to extend
            Y.Base,

            // classes to mix in
            [
                Y.IC.HistoryManager,
            ],

            // overrides/additions
            {
                ATTRS: {},

                //
                // dealing with two layouts, one outer and one inner
                // (we may add more... or the left layout could
                // move to a stand alone widget), the layouts set up
                // units in which to load the "panes"
                //
                _layouts: {
                    'outer':  null,
                    'left':   null
                },

                //
                // the panes represent the stuff displayed to the user
                // with two panes being essentially fixed (menu+tools)
                // and controlled by us, and the third being just a
                // container which will handle loading and unloading
                // of more interesting content
                //
                _panes: {
                    'menu':    null,
                    'tools':   null,
                    'content': null,
                },

                initializer: function (config) {
                    //Y.log('manage_window::initializer');

                    //Y.log("manage_window::initializer: setting contentPaneShowContent event handler");
                    this.on(
                        "manage_window:contentPaneShowContent",
                        Y.bind(this._onContentPaneShowContent, this)
                    );

                    this._initOuterLayout();
                },

                destructor: function () {
                    //Y.log('manage_window::destructor');
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
                    this.detach("manage_window:contentPaneShowContent");
                },

                _initOuterLayout: function () {
                    //Y.log('manage_window::_initOuterLayout');
                    this._buildOuterLayout('outer');
                    this._layouts['outer'].on(
                        'render',
                        Y.bind(this._onOuterLayoutRender, this)
                    );
                    this._layouts['outer'].render();
                },

                _buildOuterLayout: function (key) {
                    //Y.log('manage_window::_buildOuterLayout');
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
                                    header:   "I'm the header, thanks",
                                    body:     "manage_window_content_pane",
                                    zIndex:   0,
                                    scroll:   false
                                },
                                {
                                    position: "bottom",
                                    body:     "manage_footer",
                                    zIndex:   0,
                                    height:   37,
                                    resize:   false
                                }
                            ]
                        }
                    );
                },

                _onOuterLayoutRender: function () {
                    //Y.log('manage_window::_onOuterLayoutRender');
                    this._layouts['outer'].removeListener('render');

                    this._initLeftLayout(
                        this._layouts['outer'],   // parent layout
                        'left',                   // unit
                        'left'                    // new layout key
                    );

                    this._initContentPane(
                        this._layouts['outer'],
                        'center'
                    );

                    // TODO:  handle deriving initial event configuration from history and passing config
                    //Y.log('window::_onOuterLayoutRender should fire *initial* show content event');
                    this.fire(
                        "manage_window:contentPaneShowContent",
                        'local',
                        'dashboard'
                    );
                },

                _initLeftLayout: function (parent_layout, unit_name, layouts_key_name) {
                    //Y.log('manage_window::_initLeftLayout');
                    this._buildLeftLayout(
                        parent_layout,
                        unit_name,
                        layouts_key_name
                    );

                    this._layouts[layouts_key_name].on(
                        'render', 
                        Y.bind(this._onLeftLayoutRender, this)
                    );

                    this._layouts[layouts_key_name].render();
                },

                _buildLeftLayout: function (parent_layout, unit_name, layouts_key_name) {
                    //Y.log('manage_window::_buildLeftLayout');
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
                    //Y.log('manage_window::_onLeftLayoutRender');
                    this._layouts['left'].removeListener('render');

                    this._initMenuPane(
                        this._layouts['left'],  // layout
                        'top',                  // unit
                        'vertical'              // menu orientation
                    );
                    this._initToolsPane(
                        this._layouts['left'],  // layout
                        'center'                // unit
                    );
                },

                _initMenuPane: function (layout, unit_position, orientation) {
                    //Y.log('manage_window::_initMenuPane');
                    var menu_unit = layout.getUnitByPosition(unit_position).body.childNodes[0];

                    this._panes['menu'] = new Y.IC.ManageMenu(
                        {
                            orientation: orientation,
                            render_to:   menu_unit
                        }
                    );

                    // need to let the nodemenu's dropdowns spill into the the next unit
                    var cbody = Y.one( layout.getUnitByPosition(unit_position).body );
                    cbody.addClass('allow-overflow');
                    Y.one( cbody._node.parentNode.parentNode.parentNode ).addClass('allow-overflow');

                    // capture the menu events -
                    // 'click' is prevented by the node-menunav plugin, wtf!?
                    // so we use mouse down, but then have to do some clean up..
                    Y.delegate(
                        "mousedown",
                        this._onSubmenuMousedown,
                        this._panes['menu'].get("boundingBox"),
                        'em.yui3-menuitem-content, a.yui3-menuitem-content',
                        this
                    );
                },

                _initToolsPane: function (layout, unit_position) {
                    //Y.log('manage_window::_initToolsPane');
                    var unit = layout.getUnitByPosition(unit_position);

                    this._panes['tools'] = new Y.IC.ManageTools(
                        {                            
                            window:      this,
                            layout:      layout,
                            layout_unit: unit,
                            render_to:   unit.body.childNodes[0]
                        }
                    );
                },

                _initContentPane: function (layout, unit_position) {
                    //Y.log('manage_window::_initContentPane');
                    var unit = layout.getUnitByPosition(unit_position);

                    //
                    // The unit's height includes the header, etc. so to get an accurate
                    // width/height we want to take the displayable region of the body
                    // element contained in the unit
                    //
                    var unit_body_region = Y.one(unit.body).get("region");

                    this._panes['content'] = new Y.IC.ManageWindowContent(
                        {
                            header_to: Y.one(unit.header.childNodes[0]),
                            render_to: unit.body.childNodes[0],
                            width:     unit_body_region.width,
                            height:    unit_body_region.height,

                            // we pass this so that it may be passed through
                            // to any layouts the pane uses so that the resize
                            // events get wired up automatically
                            containing_layout: layout
                        }
                    );
                },

                _onSubmenuMousedown: function (e) {
                    //Y.log('manage_window::_onSubmenuMousedown: ' + e.target.get("id") );

                    // hide the submenu after a selection -- there
                    // seems to be a selection bug in here - should
                    // also clear the selection...
                    menu_nav_node = this._panes['menu'].get("boundingBox");

                    var menuNav = menu_nav_node.menuNav;
                    menuNav._hideAllSubmenus(menu_nav_node);

                    // clear the selection
                    Y.later(
                        500,
                        this,
                        function () {
                            var sel = window.getSelection();
                            sel.removeAllRanges();
                        }
                    );

                    // .split doesn't return "the rest" with a limit, so use a capturing regex
                    var matches      = e.target.get("id").match("^([^-]+)-([^-]+)-([^-]+)(?:-([^-]+)(?:-(.+))?)?$");
                    var kind         = matches[2] || '';
                    var manage_class = matches[3] || '';
                    var action       = matches[4] || '';
                    var addtl_args   = matches[5] || '';

                    // TODO: add passing of configuration information
                    this.fire(
                        "manage_window:contentPaneShowContent",
                        kind,
                        manage_class,
                        action,
                        addtl_args
                    );
                },

                _onContentPaneShowContent: function (e, kind, manage_class, action, addtl_args) {
                    //Y.log('manage_window::_onContentPaneShowContent');
                    var config = {
                        kind:         kind,
                        manage_class: manage_class,
                        action:       action,
                        addtl_args:   addtl_args
                    };
                    //Y.log( 'manage_window::_onContentPaneShowContent: config: ' + Y.dump(config));

                    // TODO: add passing of configuration information
                    this._panes['content'].fire(
                        "manage_window_content:showContent",
                        config
                    );
                }
            }
        );

        //
        // make all of that into a Singleton so that I can access the
        // window stuff from any module
        //
        var ManageWindow = function () {
            var mw = new MW(
                {
                    prefix: '_mw'
                }
            );
            this.instance = null;

            var getInstance = function () {
                if (! this.instance) {
                    this.instance = createInstance();
                }
                return this.instance;
            };

            var createInstance = function () {
                return {
                    mw: mw
                };
            };

            return getInstance();
        };
        
        Y.namespace("IC");
        Y.IC.ManageWindow = ManageWindow;
    },
    "@VERSION@",
    {
        requires: [
            "base-base",
            "yui2-layout",
            "yui2-resize",
            "ic-history-manager",
            "ic-manage-window-menu",
            "ic-manage-window-tools",
            "ic-manage-window-content"
        ]
    }
);
