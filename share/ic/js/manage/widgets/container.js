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
    "ic-manage-widget-container",
    function(Y) {
        var ManageContainer;

        ManageContainer = function (config) {
            ManageContainer.superclass.constructor.apply(this, arguments);
            this.publish('manageContainer:widgetloaded', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
            this.publish('manageContainer:widgetmetadata', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
            this.publish('manageContainer:widgetshown', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
            this.publish('manageContainer:widgethidden', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
        };

        ManageContainer.NAME = "ic_manage_container";
        ManageContainer.ATTRS = {
            layout: {        // the layout manager i'm a child of
                value: null
            },
            layout_unit: {   // the layout_unit i'm inside
                value: null
            },
            current: {       // my current widget
                value: null
            },
            previous: {      // my previous widget
                value: null
            }
        };

        Y.extend(
            ManageContainer,
            Y.IC.ManageWidget,
            {
                _cache: {},

                STATE_PROPERTIES: {
                    'kind': 1,
                    'sub_kind': 1,
                    'args': 1
                },

                initializer: function (config) {
                    // Y.log("manage container initializer");
                    this.render(config.render_to);
                },

                destructor: function () {
                    this._cache = null;
                },

                renderUI: function () {
                    // Y.log('container::renderUI');
                    /* 
                       currently, the container doesn't add any
                       markup.  it will attach widgets, but that is
                       done elsewhere.  If in the future if the
                       container holds some sort of "widget dock" or
                       iconification of widgets, we would set up that
                       chrome here.
                     */
                },

                bindUI: function () {
                    // Y.log('container::bindUI');
                    this.after('currentChange', this._afterCurrentWidgetChange);
                    this.after('previousChange', this._afterPreviousWidgetChange);
                    this.after('stateChange', this._afterStateChange);
                    Y.on('history-lite:change', Y.bind(this._onHistoryChange, this));
                    Y.on('manageFunction:loaded', Y.bind(function (e) {
                        this.fire('manageContainer:widgetloaded');
                    }, this));
                    Y.on('manageFunction:metadata', Y.bind(function (e) {
                        this.fire('manageContainer:widgetmetadata');
                    }, this));
                },

                syncUI: function () {
                    // Y.log('container::syncUI');
                    var rh = this.getRelaventHistory();
                    this.set('state', rh);
                },

                loadWidget: function (e) {
                    // Y.log('container::loadWidget');
                    // Y.log("function id: " + e.target.get("id"), "debug");
                    // .split doesn't return "the rest" with a limit
                    var matches    = e.target.get("id").match("^([^-]+)-([^-]+)(?:-([^-]+)-(.+))?$");
                    var kind       = matches[2] || '';
                    var sub_kind   = matches[3] || '';
                    var addtl_args = matches[4] || '';

                    var load_widget_config = {
                        kind: kind,
                        sub_kind: sub_kind,
                        args: addtl_args
                    };

                    this.set('state', load_widget_config);
                },

                unloadWidget: function () {
                    var empty = Y.Node.create('<div id="manage_menu_item-empty"></div>');
                    this.loadWidget({target: empty});
                },

                hideCurrentWidget: function () {
                    var widget = this.get('current');
                    if (widget) 
                        this._hideWidget(widget);
                },

                showCurrentWidget: function () {
                    var widget = this.get('current');
                    if (widget) 
                        this._showWidget(widget);
                },

                _afterStateChange: function (e) {
                    // Y.log('container::_afterStateChange - state');
                    // Y.log(this.get('state'));
                    var state = this.get('state');
                    this._doLoadWidget(state);
                    this._notifyHistory();
                },

                _doLoadWidget: function (config) {
                    // Y.log("container::_doLoadWidget");
                    /*
                    Y.log("kind: " + config.kind + 
                          " sub_kind: " + config.sub_kind +
                          " args: " + config.args);
                    */
                    this.set('previous', this.get('current'));
                    var new_widget = null;

                    if (config.kind === "function") {
                        if (! this._cache[config.args]) {
                            // Y.log("instantiating function: " + config.args + "...");
                            var splits     = config.args.split("-", 2);
                            var code       = splits[0];
                            // Y.log("code: " + code);
                            if (config.sub_kind === "list") {
                                this._cache[config.args] = new Y.IC.ManageFunctionExpandableList(
                                    {
                                        code: code,
                                        expandable: false,
                                        prefix: '_ls'
                                    }
                                );
                                this._cache[config.args].render( this.get("contentBox") );
                            }
                            else if (config.sub_kind === "detail") {
                                var addtl_args = splits[1] + "";
                                // Y.log("addtl_args: " + addtl_args);
                                this._cache[config.args] = new Y.IC.ManageFunctionDetail(
                                    {
                                        code: code,
                                        addtl_args: addtl_args,
                                        prefix: '_dx'
                                    }
                                );
                                this._cache[config.args].render( this.get("contentBox") );
                            }
                            else {
                            }
                        }
                        else {
                            // Y.log('pulling the widget from the cache');
                        }
                        new_widget = this._cache[config.args];
                        // Y.log('new_widget vvvvvv');
                        // Y.log(new_widget);
                    }
                    else if (config.kind === "empty") {
                        // Y.log('container::_doLoadWidget - Unloading -- EMPTY');
                        this._cache["empty"] = null;
                        new_widget = null;
                    }
                    else {
                        // Y.log("Load widget called with undefined/unrecognized kind. " +
                        //       "Doing nothing.  kind: " + config.kind);
                        return;
                    }

                    this.set('current', new_widget);
                },

                _showWidget: function (widget) {
                    // Y.log('container::_showWidget');
                    try {
                        widget.enable();
                        widget.show();
                        this.fire('manageContainer:widgetshown');
                    } catch (err) {
                        Y.log(err); // widget is probably null or not a Widget subclass
                        // NA: i think we should write an error message to the screen,
                        //     reload the previous widget, 
                        //     and remove this widget from the cache.
                        //     maybe just go back one entry in the history?
                    }
                },

                _hideWidget: function (widget) {
                    // Y.log('container::_hideWidget');
                    try {
                        widget.disable();
                        widget.hide();
                        this.fire('manageContainer:widgethidden');
                    } catch (err) {
                        Y.log(err); // probably not a Widget subclass
                        // NA: i think we should detach the widget from the dom
                        //     and remove it from the cache...
                    }
                },

                _afterPreviousWidgetChange: function (e) {
                    if (e.newVal) {
                        this._hideWidget(e.newVal);
                    }
                },

                _afterCurrentWidgetChange: function (e) {
                    if (e.newVal) {
                        this._showWidget(e.newVal);
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageContainer = ManageContainer;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-function",
            "ic-manage-widget",
            "event-custom",
            "widget"
        ]
    }
);

