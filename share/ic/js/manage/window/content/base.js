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
    "ic-manage-window-content-base",
    function(Y) {
        var ManageWindowContentBase; 

        ManageWindowContentBase = function (config) {
            ManageWindowContentBase.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentBase,
            {
                NAME: "ic_manage_content_base",
                ATTRS: {
                    visible: {
                        value: false
                    },

                    //
                    // the content description is ultimately used to set the
                    // header of the containing window pane by setting its
                    // description attribute
                    //
                    description: {
                        value: null
                    },

                    //
                    // message content to display in pane's header message area
                    //
                    message: {
                        value: null
                    },

                    //
                    // set of actions to display as buttons in the pane's 
                    // header
                    //
                    actions: {
                        value: null
                    },

                    // currently selected layout that we want displaying our pieces
                    layout: {
                        value: null
                    }
                }
            }
        );
        Y.extend(
            ManageWindowContentBase,
            Y.Widget,
            {
                // the pane that holds this content, used to access the layouts
                // and header where our content will be displayed
                _containing_pane: null,

                // cache of the pieces we'll plug into the chosen layout
                _pieces: null,

                initializer: function (config) {
                    //Y.log("manage_window_content_base::initializer");
                    if (config._pane) {
                        this._containing_pane = config._pane;
                    }

                    this._pieces = {};

                    this.on(
                        "show",
                        Y.bind( this._onShow, this )
                    );
                    this.on(
                        "hide",
                        Y.bind( this._onHide, this )
                    );
                    this.on(
                        "force_reload",
                        Y.bind( this._onForceReload, this )
                    );
                    this.after(
                        "descriptionChange",
                        Y.bind(this._afterDescriptionChange, this)
                    );
                    this.after(
                        "messageChange",
                        Y.bind(this._afterMessageChange, this)
                    );
                    this.after(
                        "actionsChange",
                        Y.bind(this._afterActionsChange, this)
                    );
                    this.on(
                        "layoutChange",
                        Y.bind(this._onLayoutChange, this)
                    );
                },

                _onShow: function (e) {
                    //Y.log("manage_window_content_base::_onShow: " + this);

                    this.set("visible", true);
                    this._setPaneDescription();
                    this._setPaneMessage();
                    this._setPaneActions();
                    this._setPaneLayout(this.get("layout"));
                },

                _onForceReload: function (e) {
                    //Y.log("manage_window_content_base::_onForceReload");

                    if (! this.get("visible")) {
                        this.fire("show");
                    }
                },

                _onHide: function (e) {
                    //Y.log("manage_window_content_base::_onHide: " + this + ' - ' + this.get("description"));

                    this.set("visible", false);
                },

                _afterDescriptionChange: function (e) {
                    //Y.log("manage_window_content_base::_afterDescriptionChange");
                    if (this.get("visible")) {
                        this._setPaneDescription();
                    }
                },

                _afterMessageChange: function (e) {
                    //Y.log("manage_window_content_base::_afterMessageChange");
                    if (this.get("visible")) {
                        this._setPaneMessage();
                    }
                },

                _afterActionsChange: function (e) {
                    //Y.log("manage_window_content_base::_afterActionsChange");
                    if (this.get("visible")) {
                        this._setPaneActions();
                    }
                },

                _onLayoutChange: function (e) {
                    //Y.log("manage_window_content_base::_onLayoutChange");
                    //Y.log("manage_window_content_base::_onLayoutChange - this: " + this);
                    //Y.log("manage_window_content_base::_onLayoutChange - visible: " + this.get("visible"));
                    //Y.log("manage_window_content_base::_onLayoutChange - newVal: " + e.newVal);
                    if (this.get("visible")) {
                        this._setPaneLayout(e.newVal);
                    }
                },

                _setPaneDescription: function () {
                    //Y.log("manage_window_content_base::_setPaneDescription");
                    if (this._containing_pane && this.get("description") !== null) {
                        //Y.log("manage_window_content_base::_setPaneDescription - setting pane description: " + this.get("description"));

                        this._containing_pane.set("description", this.get("description"));
                    }
                },

                _setPaneMessage: function () {
                    //Y.log("manage_window_content_base::_setPaneMessage");
                    if (this._containing_pane && this.get("message") !== null) {
                        //Y.log("manage_window_content_base::_setPaneMessage - setting pane message: " + this.get("message"));

                        this._containing_pane.set("message", this.get("message"));
                    }
                },

                _setPaneActions: function () {
                    //Y.log("manage_window_content_base::_setPaneActions");
                    if (this._containing_pane && this.get("actions") !== null) {
                        //Y.log("manage_window_content_base::_setPaneActions - setting pane actions: " + this.get("actions"));

                        this._containing_pane.set("actions", this.get("actions"));
                    }
                },

                _setPaneLayout: function (layout) {
                    //Y.log("manage_window_content_base::_setPaneLayout: " + this);
                    //Y.log("manage_window_content_base::_setPaneLayout - layout: " + layout);
                    if (this._containing_pane && layout !== null) {
                        //Y.log("manage_window_content_base::_setLayout - setting pane layout: " + this.get("layout"));
                        this._installPieces(layout);

                        this._containing_pane.set("displayed_layout", layout);
                    }
                },

                _installPieces: function (layout) {
                    //Y.log("manage_window_content_base::_installPieces");
                    if (this._containing_pane && this._pieces !== null) {
                        var chosen_layout_name;
                        if (layout) {
                            chosen_layout_name = layout;
                        }
                        else {
                            chosen_layout_name = this.get("layout");
                        }

                        var chosen_layout = this._containing_pane._layouts[ chosen_layout_name ];
                        //Y.log("manage_window_content_base::_installPieces - chosen_layout: " + chosen_layout);

                        var unit_locations = [ "body", "header" ];

                        // this goes by the layout's units not piece keys cause we could be
                        // caching pieces that aren't currently installed
                        Y.each(
                            chosen_layout.get("unit_names"),
                            function (v, i, a) {
                                Y.log("_installPieces each - v: " + v);
                                var unit = chosen_layout._layout.getUnitByPosition(v);

                                Y.each(
                                    unit_locations,
                                    function (iv, ii, ia) {
                                        Y.log("_installPieces each - iv: " + iv);
                                        var location;
                                        if (iv === "header" && unit[iv]) {
                                            location = Y.one( unit[iv].childNodes[0] );
                                        }
                                        else {
                                            location = Y.one( unit[iv] );
                                        }
                                        Y.log("_installPieces each - location: " + location);

                                        if (location) {
                                            var piece_name = chosen_layout_name + '_' + v + '_' + iv;
                                            Y.log("_installPieces each - piece_name: " + piece_name);

                                            if (this._pieces[piece_name]) {
                                                location.setContent(this._pieces[piece_name]);
                                            }
                                        }
                                    },
                                    this
                                );
                            },
                            this
                        );
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentBase = ManageWindowContentBase;
    },
    "@VERSION@",
    {
        requires: [
            "widget"
        ]
    }
);
