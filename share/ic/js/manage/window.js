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
        var ManageWindow;

        // Constructor //
        ManageWindow = function (config) {
            ManageWindow.superclass.constructor.apply(this, arguments);
        };

        // Static //
        Y.mix(
            ManageWindow,
            {
                NAME: "ic_manage_window",
                ATTRS: {
                }
            }
        );

        // Prototype //
        Y.extend(
            ManageWindow,
            Y.Base,
            {
                // Instance Members //
                _menu:         null,
                _container:    null,
                _subcontainer: null,

                // Base Methods //
                initializer: function (config) {
                    var YAHOO = Y.YUI2;

                    var menu_unit;
                    var container_unit;

                    var layout = new YAHOO.widget.Layout(
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
                                    width: 250,
                                    zIndex: 0
                                },
                                {
                                    position: "center",
                                    zIndex: 1,
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
                    layout.on(
                        "render",
                        function () {
                            var center = layout.getUnitByPosition("center").get("wrap");

                            var inner_layout = new YAHOO.widget.Layout(
                                center,
                                {
                                    parent: layout,
                                    units: [
                                        {
                                            position: "top",
                                            body: "manage_menu",
                                            height: 26,
                                            zIndex: 2,
                                            scroll: null
                                        },
                                        {
                                            position: "center",
                                            body: "manage_window",
                                            zIndex: 0,
                                            scroll: true
                                        }
                                    ]
                                }
                            );
                            inner_layout.render();

                            // need to let the nodemenu's dropdowns spill into the the next unit
                            Y.one(inner_layout.getUnitByPosition("top").body).addClass('allow-overflow');

                            // leave the unit's wrapper and body alone,
                            //  and instead render into the body element
                            menu_unit = inner_layout.getUnitByPosition("top").body.childNodes[0];
                            container_unit = inner_layout.getUnitByPosition("center").body.childNodes[0];
                        }
                    );
                    layout.render();

                    this._menu      = new Y.IC.ManageMenu(
                        {
                            render_to: menu_unit
                        }
                    );
                    this._container = new Y.IC.ManageContainer(
                        {
                            render_to: container_unit
                        }
                    );

                    var loadWidget = Y.bind(this._container._doLoadWidget, this._container);
                    var onSubmenuMousedown = function(e) {
                        // hide the submenu after a selection (why is this necessary?)
                        //  maybe because the menu uses anchors instead of hrefs?  
                        //  could try switching the menu init to build empty hrefs, and 
                        //  then be careful to capture and stop event propagation on click...
                        // instead, this just forces a submenu hide, but the _node.offsetParent is ugly
                        Y.one(e.target._node.offsetParent).addClass('yui3-menu-hidden');
                        loadWidget(e);
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
                        "mousedown",
                        loadWidget,
                        this._container.get("boundingBox"),
                        'a.manage_function_link'
                        //this._menu
                    );
                },

                destructor: function () {
                    this._menu         = null;
                    this._container    = null;
                    this._subcontainer = null;
                }

                // Public Methods //

                // Private Methods //
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
            "yui2-layout",
            "yui2-resize",
            "yui2-animation"
        ]
    }
);
