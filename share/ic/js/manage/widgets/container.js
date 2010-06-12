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
        var Module;

        Module = function (config) {
            Module.superclass.constructor.apply(this, arguments);
        };

        Module.NAME = "ic_manage_container";
        Module.STATE_PROPERTIES = {
            'kind': 1,
            'sub_kind': 1,
            'args': 1
        };
        Module.ATTRS = {
            layout: {        // the layout manager i'm a child of
                value: null
            },
            current: {       // my current widget
                value: null
            },
            previous: {      // my previous widget
                value: null
            },
            prefix: {        // a prefix for history state variables 
                value: null  //  to distinguish this object from its siblings
            },
            state: {         // my state, used by history to drive my content
                value: null,
                setter: function(new_state) {
                    var old_state = Y.HistoryLite.get();
                    var sp = Module.STATE_PROPERTIES;
                    // we wipe out all the prior state properties to start fresh
                    Y.each(old_state, function (v, k, obj) {
                        if (sp[k]) {
                            obj[k] = null;
                        }
                    });
                    // we only allow our STATE_PROPERTIES, no others
                    Y.each(new_state, function (v, k, obj) {
                        if (!sp[k]) {
                            delete obj[k];
                        }
                    });
                    return Y.merge(old_state, new_state);
                }
            }
        };

        Y.extend(
            Module,
            Y.Widget,
            {
                _cache: {},

                initializer: function (config) {
                    Y.log("manage container initializer");
                    this.render(config.render_to);
                },

                destructor: function () {
                    this._cache = null;
                },

                renderUI: function () {
                    Y.log('container::renderUI');
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
                    Y.log('container::bindUI');
                    this.after('currentChange', this._afterCurrentWidgetChange);
                    this.after('previousChange', this._afterPreviousWidgetChange);
                    this.after('stateChange', this._afterStateChange);
                    Y.on('history-lite:change', Y.bind(this._onHistoryChange, this));
                },

                syncUI: function () {
                    Y.log('container::syncUI');

                    // update the state from the history
                    this.set('state', this.getRelaventHistory());
                },

                isEmpty: function (obj) {
                    for(var i in obj) { 
                        return false; 
                    } 
                    return true;
                },


                areEqualObjects: function(a, b) {
                    if (typeof(a) != typeof(b)) {
                        return false;
                    }
                    var allkeys = {};
                    for (var i in a) {
                        allkeys[i] = 1;
                    }
                    for (var i in b) {
                        allkeys[i] = 1;
                    }
                    for (var i in allkeys) {
                        if (a.hasOwnProperty(i) != b.hasOwnProperty(i)) {
                            if ((a.hasOwnProperty(i) && typeof(b[i]) == 'function') ||
                                (a.hasOwnProperty(i) && typeof(b[i]) == 'function')) {
                                continue;
                            } else {
                                return false;
                            }
                        }
                        if (typeof(a[i]) != typeof(b[i])) {
                            return false;
                        }
                        if (typeof(a[i]) == 'object') {
                            if (!this.areEqualObjects(a[i], b[i])) {
                                return false;
                            }
                        } else {
                            if (a[i] !== b[i]) {
                                return false;
                            }
                        }
                    }
                    return true;
                },

                getRelaventHistory: function() {
                    var sp = Module.STATE_PROPERTIES;
                    var prefix = this.get('prefix');
                    var history = Y.HistoryLite.get();
                    var rh = {}; // relavent history
                    Y.each(sp, function (v, k, obj) {
                        if (typeof history[prefix + k] !== undefined) {
                            rh[k] = history[prefix + k];
                        }
                    });
                    return rh;
                },

                stateMatchesHistory: function() {
                    var state = this.get('state');
                    // first check to ensure state has been initialized
                    if (typeof(state) != 'object') {
                        return false;
                    }
                    var rh = this.getRelaventHistory();
                    return this.areEqualObjects(state, rh);
                },

                loadWidget: function (e) {
                    Y.log('container::loadWidget');
                    Y.log("function id: " + e.target.get("id"), "debug");
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

                    // log this action with the history manager, 
                    //  and let it load the widget
                    this.set('state', load_widget_config);
                    Y.HistoryLite.add(this._addMyHistoryPrefix(this.get('state')));
                },

                unloadWidget: function () {
                    var empty = Y.Node.create('<div id="manage_menu_item-empty"></div>');
                    this.loadWidget({target: empty});
                },

                _doLoadWidget: function (config) {
                    Y.log("container::_doLoadWidget");
                    Y.log("loadWidget this: " + this);
                    Y.log("loadWidget kind: " + config.kind);
                    Y.log("loadWidget sub_kind: " + config.sub_kind);
                    Y.log("loadWidget args: " + config.args);

                    this.set('previous', this.get('current'));
                    var new_widget = null;

                    if (config.kind === "dashboard") {
                        if (! this._cache["dashboard"]) {
                            Y.log("instantiating dashboard...");
                            this._cache["dashboard"] = new Y.IC.ManageDashboard();
                            this._cache["dashboard"].render( this.get("contentBox") );
                        }

                        new_widget = this._cache["dashboard"];
                    }
                    else if (config.kind === "function") {
                        if (! this._cache[config.args]) {
                            Y.log("instantiating function: " + config.args + "...");
                            var splits     = config.args.split("-", 2);
                            var code       = splits[0];
                            Y.log("code: " + code);
                            if (config.sub_kind === "list") {
                                this._cache[config.args] = new Y.IC.ManageFunctionExpandableList(
                                    {
                                        code: code,
                                        expandable: false
                                    }
                                );
                                this._cache[config.args].render( this.get("contentBox") );
                                this._cache[config.args].hide();
                            }
                            else if (config.sub_kind === "detail") {
                                var addtl_args = splits[1] + "";
                                Y.log("addtl_args: " + addtl_args);
                                this._cache[config.args] = new Y.IC.ManageFunctionDetail(
                                    {
                                        code: code,
                                        addtl_args: addtl_args
                                    }
                                );
                                this._cache[config.args].render( this.get("contentBox") );
                                this._cache[config.args].hide();
                            }
                            else {
                            }
                        }

                        new_widget = this._cache[config.args];
                    }
                    else if (config.kind === "empty") {
                        Y.log('container::_doLoadWidget - Unloading -- EMPTY');
                        this._cache["empty"] = null;
                        new_widget = null;
                    }
                    else {
                        Y.log("Load widget called with undefined/unrecognized kind.  Doing nothing.  kind: " + config.kind);
                        return;
                    }

                    this.set('current', new_widget);
                },

                _addMyHistoryPrefix: function (o) {
                    var copy = Y.merge(o);
                    var prefix = this.get('prefix');
                    var hp = Module.STATE_PROPERTIES;
                    Y.each(copy, function (v, k, obj) {
                        // verify that it isn't already prefixed
                        if (k.indexOf(prefix) !== 0) {
                            // only modify my history properties
                            if (hp[k]) {
                                delete obj[k];
                                obj[prefix + k] = v;
                            }
                        }
                    });
                    return copy;
                },

                _stripMyHistoryPrefix: function (o) {
                    var copy = Y.merge(o);
                    var prefix = this.get('prefix');
                    var hp = Module.STATE_PROPERTIES;
                    Y.each(copy, function (v, k, obj) {
                        // continue if not prefixed
                        if (k.indexOf(prefix) === 0) {
                            // only modify my history properties
                            if (hp[k]) {
                                delete obj[k];
                                obj[k.substring(prefix.length)] = v;
                            }
                        }
                    });
                    return copy;
                },

                _afterStateChange: function (e) {
                    Y.log('container::_afterStateChange');
                    Y.log('state: ' + Y.QueryString.stringify(this.get('state')));
                    var state = this.get('state');
                    this._doLoadWidget(state);
                },

                _onHistoryChange: function (e) {
                    Y.log('container::_onHistoryChange');
                    if ( ! this.stateMatchesHistory() ) {
                        this.set('state', this.getRelaventHistory());
                    }
                },

                _showWidget: function (widget) {
                    Y.log('container::_showWidget');
                    try {
                        widget.enable();
                        widget.show();
                    } catch (err) {
                        Y.log(err); // widget is probably null or not a Widget subclass
                        // NA: i think we should write an error message to the screen,
                        //     reload the previous widget, 
                        //     and remove this widget from the cache.
                        //     maybe just go back one entry in the history?
                    }
                },

                _hideWidget: function (widget) {
                    Y.log('container::_hideWidget');
                    try {
                        Y.log("hiding widget: " + widget);
                        widget.hide();
                        widget.disable();
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
        Y.IC.ManageContainer = Module;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-dashboard",
            "ic-manage-widget-function",
            "widget"
        ]
    }
);

