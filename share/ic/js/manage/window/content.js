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
    "ic-manage-window-content",
    function(Y) {
        var ManageWindowContent;

        ManageWindowContent = function (config) {
            ManageWindowContent.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContent,
            {
                NAME: "ic_manage_window_content",
                ATTRS: {
                    description: {
                        value: null
                    },
                    message: {
                        value: null
                    },
                    actions: {
                        value: null
                    },
                    current: {
                        value: null
                    },
                    previous: {
                        value: null
                    },
                    displayed_layout: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContent,
            Y.Widget,
            {
                _header_to:         null,
                _containing_layout: null,

                //
                // cache any content that we've built previously to allow for
                // potential for quick render
                //
                // TODO: need to make this a smarter cache with a limit
                //       on the number that we cache, or some other means
                //       to determine whether a specific piece should be
                //       cached
                //
                _content_cache: {},

                // the content "container" needs to control a set of layouts
                // that will display the content that is loaded, each individual
                // content piece will decide for itself which layout units to
                // use for display, etc.
                //
                // TODO: would be lovely to do lazy instantiation/loading
                //       of these, but I don't have time right now
                //
                _layouts: {
                    full:      null,
                    h_divided: null
                },

                initializer: function (config) {
                    //Y.log("manage_window_content::initializer");
                    if (config.header_to) {
                        this._header_to = config.header_to;
                    }
                    if (config.containing_layout) {
                        this._containing_layout = config.containing_layout;
                    }

                    this.render(config.render_to);
                },

                destructor: function () {
                    Y.log("manage_window_content::destructor");
                },

                renderUI: function () {
                    //Y.log('manage_window_content::renderUI');

                    /*
                        Currently, the container doesn't add any markup. It will attach widgets,
                        but that is done elsewhere. If in the future the container holds some 
                        sort of "widget dock" or iconification of widgets, we would set up that 
                        chrome here.
                    */
                    //this.get("contentBox").setContent("Preparing to load content again...");

                    // TODO: create these using append below when setting up the layouts
                    this.get("contentBox").setContent(
                        '<div id="manage_window_content_layout_full_body" style="z-index: 0;"></div>'
                        + '<div id="manage_window_content_layout_h_divided_top_body" style="z-index: 1;"></div>'
                        + '<div id="manage_window_content_layout_h_divided_center_body" style="z-index: 1;"></div>'
                    );

                    // build a grid with three units, one for the description, one for the message, one for the actions
                    var grid_node = Y.Node.create(
                        '<div class="yui3-g"><div class="yui3-u-1-3 content_header_description"></div><div class="yui3-u-1-3 content_header_message"></div><div class="yui3-u-1-3 content_header_actions"></div></div>'
                    );
                    this._header_to.setContent(grid_node);
                },

                bindUI: function () {
                    //Y.log('manage_window_content::bindUI');

                    //
                    // set up the layouts that the content will put its info in
                    // the content layouts are widgets that wrap YUI2 layout manager
                    // objects
                    //
                    // TODO: need to set the parent layout to the outer layout so
                    //       that resize events are handled properly
                    //
                    this._layouts.full      = new Y.IC.ManageWindowContentLayoutFull(
                        {
                            parent: this._containing_layout,
                            width:  this.get("width"),
                            height: this.get("height")
                        }
                    );
                    this._layouts.h_divided = new Y.IC.ManageWindowContentLayoutHDivided(
                        {
                            parent: this._containing_layout,
                            width:  this.get("width"),
                            height: this.get("height")
                        }
                    );

                    // TODO: can/should these move to syncUI?
                    this._layouts.full.render(this.get("contentBox"));
                    this._layouts.h_divided.render(this.get("contentBox"));

                    this.after(
                        "descriptionChange",
                        Y.bind( this._afterDescriptionChange, this )
                    );
                    this.after(
                        "messageChange",
                        Y.bind( this._afterMessageChange, this )
                    );
                    this.after(
                        "actionsChange",
                        Y.bind( this._afterActionsChange, this )
                    );

                    // run this "on" so that we can always make sure that the layout
                    // isn't hidden by something else and not re-shown by our event
                    this.on(
                        "displayed_layoutChange",
                        Y.bind( this._onDisplayedLayoutChange, this )
                    );

                    this.on(
                        "manage_window_content:showContent",
                        Y.bind( this._onShowContent, this )
                    );
                },

                syncUI: function () {
                    //Y.log('manage_window_content::syncUI');
                },

                _onShowContent: function (e) {
                    //Y.log('manage_window_content::_onShowContent');

                    var config = e.details[0];

                    var kind         = config['kind'];
                    var manage_class = config['manage_class'];

                    var _cache_key = kind + '-' + manage_class;
                    //Y.log('manage_window_content::_onShowContent - _cache_key: ' + _cache_key);

                    var _constructor;
                    var _constructor_args = {
                        _pane:   this,
                        layouts: this._layouts
                    };
                    var _fire_event       = 'show';
                    var _fire_event_args  = {};

                    //
                    // need to check for cache of this content already shown, if exists
                    // need to just restore it, if doesn't we need to init the content
                    // which does whatever it does, and then display it, and need to 
                    // hide whatever current content might be there
                    //
                    //this.get("contentBox").setContent("Preparing to load content..." + _cache_key);

                    //Y.log("manage_window_content::_onShowContent - checking for cache of content - " + _cache_key);
                    if (this._content_cache[_cache_key]) {
                        //Y.log("manage_window_content::_onShowContent - found cache of content - " + _cache_key);

                        // if the last content object shown was this object then they are force reloading
                        // so cause that to happen now
                        //Y.log("manage_window_content::_onShowContent - check for force reload - " + _cache_key);
                        if (this.get("current") === _cache_key) {
                            //Y.log("manage_window_content::_onShowContent - force reload needed - " + this._content_cache[_cache_key]);
                            _fire_event = 'force_reload';
                        }
                        else {
                            //Y.log("manage_window_content::_onShowContent - show from cache (no reload) - " + this._content_cache[_cache_key]);
                        }

                        if (kind === 'function') {
                            _fire_event_args = {
                                base: config['action'],
                                args: config['addtl_args']
                            };
                        }
                    }
                    else {
                        //Y.log("manage_window_content::_onShowContent - content not in cache (need to init) - " + _cache_key);
                        // TODO: make this a map if we get more of them
                        if (kind === 'function') {
                            _constructor = Y.IC.ManageWindowContentFunction.prototype.constructor;

                            _constructor_args.manage_class   = manage_class;

                            _fire_event_args = {
                                base: config['action'],
                                args: config['addtl_args']
                            };
                        }
                        else if (kind === 'local') {
                            _constructor = Y.IC.ManageWindowContentDashboard.prototype.constructor;
                        }
                        else {
                            this.get("contentBox").setContent("Unable to load content: unrecognized kind '" + kind + "'");
                        }

                        this._content_cache[_cache_key] = new _constructor (_constructor_args);
                    }

                    //Y.log("content_cache[" + _cache_key + "]: " + this._content_cache[_cache_key]);

                    if (this.get("current") !== _cache_key) {
                        // TODO: rather than hiding/showing the layouts we should remove/append them from the DOM
                        // hide the layouts and let the content turn back on the one it wants
                        Y.each(
                            this._layouts,
                            function (v, k, obj) {
                                v.hide();
                            }
                        );
                        if (this._content_cache[this.get("current")]) {
                            this._content_cache[this.get("current")].fire('hide');
                        }
                    }

                    if (_fire_event !== "force_reload") {
                        this.set("description", "Loading Content...");
                    }

                    //Y.log("firing event - " + _fire_event + " - " + _cache_key + " - " + this._content_cache[_cache_key]);
                    this._content_cache[_cache_key].fire(
                        _fire_event,
                        _fire_event_args
                    );

                    if (this.get("current") !== _cache_key) {
                        //Y.log("manage_window_content::_onShowContent - setting previous to " + this.get("current"));
                        this.set("previous", this.get("current"));

                        //Y.log("manage_window_content::_onShowContent - setting current to " + _cache_key);
                        this.set("current", _cache_key);
                    }
                    else {
                        //Y.log("manage_window_content::_onShowContent - not updating current/previous");
                    }
                },

                _afterDescriptionChange: function (e) {
                    //Y.log('manage_window_content::_afterDescriptionChange');

                    if (this._header_to) {
                        this._header_to.one("div.content_header_description").setContent(this.get("description"));
                    }
                },

                _afterMessageChange: function (e) {
                    //Y.log('manage_window_content::_afterMessageChange');

                    if (this._header_to) {
                        this._header_to.one("div.content_header_message").setContent(this.get("message"));
                    }
                },

                _afterActionsChange: function (e) {
                    //Y.log('manage_window_content::_afterActionsChange');

                    if (this._header_to) {
                        var action_node = this._header_to.one("div.content_header_actions");
                        // TODO: rather than clearing the content this needs to be smarter
                        //       about building different parts of it
                        action_node.setContent("");

                        var buttons = [];

                        Y.each(
                            this.get("actions"),
                            function (v, i, a) {
                                var add_class;
                                if (Y.Lang.isValue(v.add_class)) {
                                    add_class = v.add_class;
                                }

                                var button = new Y.Button (v);
                                //var button = new Y.ButtonToggle (v);
                                button.get("contentBox").addClass(add_class);

                                this.push(button);
                            },
                            buttons
                        );

                        if (buttons.length) {
                            var button_group = new Y.ButtonGroup (
                                {
                                    label:          "",
                                    children:       buttons,
                                    render:         action_node,

                                    // TODO: this needs to be on a group basis
                                    //alwaysSelected: true
                                }
                            );
                            // TODO: need a way to determine which is selected
                            //button_group.selectChild(0);
                        }
                    }
                },

                _onDisplayedLayoutChange: function (e) {
                    //Y.log('manage_window_content::_onDisplayedLayoutChange');
                    //Y.log('manage_window_content::_onDisplayedLayoutChange - displayed_layout: ' + e.newVal);

                    Y.each(
                        this._layouts,
                        function (v, k, o) {
                            //Y.log('manage_window_content::_onDisplayedLayoutChange - each: ' + k + ', ' + v);
                            if (k !== e.newVal) {
                                v.hide();
                            }
                        },
                        this
                    );

                    if (! this._layouts[ e.newVal ].get("visible")) {
                        this._layouts[ e.newVal ].show();
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContent = ManageWindowContent;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-css",
            "widget",
            "gallery-button-group",
            "gallery-button",
            "gallery-button-toggle",
            "yui2-layout",
            "yui2-resize",
            "ic-manage-window-content-dashboard",
            "ic-manage-window-content-function"
        ]
    }
);
