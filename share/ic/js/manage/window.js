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
        var Module;

        // Constructor //
        Module = function (config) {
            Module.superclass.constructor.apply(this, arguments);
        };

        // Static //
        Y.mix(
            Module,
            {
                NAME: "ic_manage_window",
                HISTORY_PROPERTIES: {
                    'lc': 1  /*
                              * layout-center, possible values:
                              *  lc: 'maxdv' // max center unit
                              *  lc: 'maxdt' // max top unit
                              *  lc: 'dtdv'  // top at 152
                              */
                },
                ATTRS: {
                    state: {
                        value: null,
                        setter: function(new_state) {
                            var old_state = Y.HistoryLite.get();
                            // wipe out all my history properties to start fresh
                            var my_hist_props = Module.HISTORY_PROPERTIES;
                            Y.each(old_state, function (v, k, obj) {
                                if (my_hist_props[k]) {
                                    obj[k] = null;
                                }
                            });
                            var merged_state = Y.merge(old_state, new_state);
                        }
                    }

                }
            }
        );

        // Prototype //
        Y.extend(
            Module,
            Y.Base,
            {
                // Instance Members //
                _menu:          null,
                _dt_container:  null,
                _dv_container:  null,
                _outer_layout:  null,
                _left_layout:   null,
                _center_layout: null,

                /* 
                 * Need to add history-lite.
                 * if there is no history, load a default
                 *  - which is the max center unit, loading a dashboard
                 * if there is history, look for layout params
                 *  - layout_center: 'maxdv' // max center unit
                 *    layout_center: 'maxdt' // max top unit
                 *    layout_center: 'dtdv'  // top at 152
                 *
                 * so add resize methods to be controlled by state
                 * and if this works, abstract the history out into a generic module all IC widgets can extend
                 */

                // Base Methods //
                initializer: function (config) {
                    var YAHOO = Y.YUI2;
                    var _this = this;
                    this._outer_layout = new YAHOO.widget.Layout(
                        {
                            units: [
                                {
                                    position: "top",
                                    height: 30,
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
                    this._outer_layout.on(
                        "render",
                        function () {
                            var left = _this._outer_layout.getUnitByPosition("left").get("wrap");
                            _this._left_layout = new YAHOO.widget.Layout(
                                left,
                                {
                                    parent: _this._outer_layout,
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
                            _this._left_layout.on('render', function() {
                                var menu_unit = this.getUnitByPosition("top").body.childNodes[0];
                                _this._menu = new Y.IC.ManageMenu(
                                    {
                                        orientation: 'vertical',
                                        render_to: menu_unit
                                    }
                                );
                            });
                            _this._left_layout.render();
                            // need to let the nodemenu's dropdowns spill into the the next unit
                            var cbody = Y.one(_this._left_layout.getUnitByPosition("top").body);
                            cbody.addClass('allow-overflow');
                            Y.one(cbody._node.parentNode.parentNode.parentNode).addClass('allow-overflow');
                        }
                    ),
                    this._outer_layout.on(
                        "render",
                        function () {
                            var center = _this._outer_layout.getUnitByPosition("center").get("wrap");
                            var layout_region = Y.DOM.region(center);  // used to initially render the top
                                                                       // unit to the max available hide
                                                                       // effectively hiding the detail view
                            _this._center_layout = new YAHOO.widget.Layout(
                                center,
                                {
                                    parent: _this._outer_layout,
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
                            _this._center_layout.render();
                        }
                    );
                    this._outer_layout.render();

/*
                            _this._center_layout.on('render', function() { 
                                // leave the unit's wrapper and body alone,
                                //  and instead render into the element contained by the body
                                var dt_container_unit = this.getUnitByPosition("top").body.childNodes[0];
                                _this._dt_container = new Y.IC.ManageContainer(
                                    {
                                        render_to: dt_container_unit,
                                        layout: _this._center_layout
                                    }
                                );
                                var dv_container_unit = this.getUnitByPosition("center").body.childNodes[0];
                                _this._dv_container = new Y.IC.ManageContainer(
                                    {
                                        render_to: dv_container_unit,
                                        layout: _this._center_layout
                                    }
                                );
                            });
*/

                    var loadWidgetIntoDataTable, loadWidgetIntoDetailView;
                    var onSubmenuMousedown = function(e) {
                        // hide the submenu after a selection
                        //  this seems to be necessary because there's no default action
                        //  when clicking an empty anchor (we only listen for mousedown)
                        menu_nav_node = _this._menu.get("boundingBox")
                        var menuNav = menu_nav_node.menuNav;
                        menuNav._hideAllSubmenus(menu_nav_node);
                        var center = _this._outer_layout.getUnitByPosition("center").get("wrap");
                        var layout_region = Y.DOM.region(center);  // used to initially render the top
                        var top = _this._center_layout.getUnitByPosition("top");
                        if (_this._dv_container) {
                            _this._dv_container.unloadWidget();
                        }
                        top.set('height', layout_region.height);
                        if (!_this._dt_container) {
                            var dt_container_unit = _this._center_layout.getUnitByPosition("top").body.childNodes[0];
                            _this._dt_container = new Y.IC.ManageContainer(
                                {
                                    render_to: dt_container_unit,
                                    prefix: '_dt',
                                    layout: _this._center_layout
                                }
                            );
                        }
                        loadWidgetIntoDataTable = Y.bind(_this._dt_container.loadWidget, _this._dt_container);
                        loadWidgetIntoDataTable(e);
                    };
                    var onDetailClick = function(e) {
                        var top = _this._center_layout.getUnitByPosition("top");
                        top.set('height', 152);
                        if (!_this._dv_container) {
                            var dv_container_unit = _this._center_layout.getUnitByPosition("center").body.childNodes[0];
                            _this._dv_container = new Y.IC.ManageContainer(
                                {
                                    render_to: dv_container_unit,
                                    prefix: '_dv',
                                    layout: _this._center_layout
                                }
                            );
                        }
                        loadWidgetIntoDetailView = Y.bind(_this._dv_container.loadWidget, _this._dv_container);
                        loadWidgetIntoDetailView(e);
                    };
                    var onTabPanelClick = function(e) {
                        // ?
                    };

                    Y.delegate(
                        "mousedown",
                        onSubmenuMousedown,
                        this._menu.get("boundingBox"),
                        'em.yui3-menuitem-content'
                        //this._menu
                    );
                    Y.delegate(
                        "mousedown",
                        onSubmenuMousedown,
                        this._menu.get("boundingBox"),
                        'a.yui3-menuitem-content'
                        //this._menu
                    );
                    Y.delegate(
                        "click",
                        onDetailClick,
                        this._outer_layout.getUnitByPosition("center").get("wrap"),
                        'a.manage_function_link'
                        //this._menu
                    );
                    Y.delegate(
                        "click",
                        onTabPanelClick,
                        this._outer_layout.getUnitByPosition("center").get("wrap"),
                        'div.yui3-tab-panel'
                    );
                },

                destructor: function () {
                    this._menu.destroy();
                    this._menu = null;
                    this._dt_container.destroy();
                    this._dt_container = null;
                    this._dt_container.destroy();
                    this._dv_container = null;
                    this._outer_layout = null;
                    this._left_layout = null;
                    this._center_layout = null;
                }

                // Public Methods //

                // Private Methods //
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindow = Module;
    },
    "@VERSION@",
    {
        requires: [
            "base-base",
            "ic-manage-widget-container",
            "ic-manage-widget-menu",
            "yui2-layout",
            "yui2-resize",
            "yui2-animation"
        ]
    }
);
