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
    "ic-renderer-tile",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererTile = Y.Base.create(
            "ic_renderer_tile",
            Y.IC.RendererBase,
            [ Y.WidgetParent, Y.WidgetStdMod ],
            {
                _header_node: null,
                _title_node:  null,
                _mesg_node:   null,
                _button_node: null,

                _footer_node: null,

                _action_to_index_map: null,

                _initial_action: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._initial_action = config.initial_action;

                    this.set("width", this.get("advisory_width"));
                    this.set("height", this.get("advisory_height"));

                    this._action_to_index_map = {};
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    // TODO: use class manager
                    this._title_node  = Y.Node.create('<div class="ic_renderer_tile_header_title yui3-u-1-3">Tile Title</div>');
                    this._mesg_node   = Y.Node.create('<div class="ic_renderer_tile_header_mesg yui3-u-1-3"></div>');
                    this._button_node = Y.Node.create('<div class="ic_renderer_tile_header_buttons yui3-u-1-3"></div>');
                    this._header_node = Y.Node.create('<div class="ic_renderer_tile_header yui3-g"></div>');

                    this._header_node.append( this._title_node );
                    this._header_node.append( this._mesg_node );
                    this._header_node.append( this._button_node );

                    Y.each(
                        this.get("actions"),
                        function (v, k, obj) {
                            Y.log(Clazz.NAME + "::renderUI - adding action button: " + v.label);
                            var button = new Y.Button (
                                {
                                    render:   this._button_node,
                                    label:    v.label,
                                    callback: Y.bind(
                                        function () {
                                            Y.log(Clazz.NAME + "::renderUI - button callback: " + k);

                                            this.set("action", k);
                                        },
                                        this
                                    )
                                }
                            );
                        },
                        this
                    );

                    this.set("headerContent", this._header_node );

                    this._footer_node = Y.Node.create('<div></div>');
                    this.set("footerContent", this._footer_node);
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");
                    this.after(
                        "titleChange",
                        function (e) {
                            this._title_node.setContent( this.get("title") );
                        },
                        this
                    );
                    this.after(
                        "selectionChange",
                        Y.bind( this._afterMySelectionChange, this )
                    );
                    this.after(
                        "actionChange",
                        Y.bind( this._afterActionChange, this )
                    );
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");

                    this._title_node.setContent( this.get("title") );

                    // needed this to make sure the body node exists
                    this.set("bodyContent", "");


                    // TODO: the following code has an issue such that the existing displayed
                    //       record is not hidden correctly, fix it
                    var initial_action = this.get("action");
                    //Y.log(Clazz.NAME + "::syncUI - actions: " + Y.dump(this.get("actions")));
                    //if (! Y.Lang.isValue( initial_action ) && Y.Lang.isValue( this.get("actions") )) {
                        //var found = Y.some(
                            //this.get("actions"),
                            //function (v, k, o) {
                                //if (Y.Lang.isValue(v.is_default) && v.is_default) {
                                    //initial_action = k
                                    //return true;
                                //}
                            //}
                        //);
                        //if (! found) {
                            //if (Y.Lang.isValue(this.get("actions").DetailView)) {
                                //initial_action = "DetailView";
                            //}
                        //}
                    //}
                    //else {
                        //// TODO: need to do this only if there is default content
                        ////       and then handle clearing it on first display
                        ////this.set("bodyContent", "Select an action to load content.");
                    //}

                    Y.log(Clazz.NAME + "::syncUI - initial_action: " + Y.dump(initial_action));
                    if (Y.Lang.isValue( initial_action )) {
                        // TODO: is there a more proper YUI way to do this?
                        // get the side effect of setting action
                        this._afterActionChange(
                            {
                                newVal: initial_action
                            }
                        );
                    }
                },

                _afterMySelectionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterMySelectionChange");
                    Y.log(Clazz.NAME + "::_afterMySelectionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterMySelectionChange - e.newVal: " + e.newVal);
                    if (Y.Lang.isValue(e.prevVal)) {
                        e.prevVal.hide();
                    }
                    if (Y.Lang.isValue(e.newVal)) {
                        e.newVal.show();
                    }
                },

                _afterActionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterActionChange");
                    Y.log(Clazz.NAME + "::_afterActionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterActionChange - e.newVal: " + e.newVal);

                    if (! Y.Lang.isValue(this._action_to_index_map[e.newVal])) {
                        this._buildActionContent(e.newVal);
                    }

                    //
                    // see comments in panel.js if this appears to break when a panel
                    // is nested directly inside of a tile
                    //
                    this.selectChild( this._action_to_index_map[e.newVal] );
                    //this.item( this._action_to_index_map[e.newVal] ).set("selected", 2);
                },

                _buildActionContent: function (action_key) {
                    Y.log(Clazz.NAME + "::_buildActionContent");
                    Y.log(Clazz.NAME + "::_buildActionContent - action_key: " + Y.dump(action_key));

                    this._uiSetFillHeight(Y.WidgetStdMod.BODY);

                    var action_data = this.get("actions")[action_key];
                    Y.log(Clazz.NAME + "::_buildActionContent - action_data: " + Y.dump(action_data));

                    var child_constructor = Y.IC.Renderer.getConstructor(action_data.renderer.type);

                    var body_node = this.getStdModNode( Y.WidgetStdMod.BODY );
                    var region    = body_node.get("region");
                    Y.log(Clazz.NAME + "::_buildActionContent - body region: " + Y.dump(region));
                    action_data.renderer.config.render = body_node;
                    action_data.renderer.config.advisory_width  = region.width;
                    action_data.renderer.config.advisory_height = region.height;

                    var new_child = new child_constructor (action_data.renderer.config);

                    this.add(new_child);

                    this._action_to_index_map[action_key] = new_child.get("index");
                },

                //
                // this is overriding the base provided method so that the tile's children
                // (the actions) don't get de-selected when the parent itself is deselected
                // as is the case when a tile is a child of a panel
                //
                _afterParentSelectedChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterParentSelectedChange");
                }
            },
            {
                ATTRS: {
                    title: {
                        value: ""
                    },
                    actions: {
                        value: {}
                    },
                    action: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-tile-css",
            "ic-renderer-base",
            "widget-std-mod",
            "gallery-button"
        ]
    }
);
