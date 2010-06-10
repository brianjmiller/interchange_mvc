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
        };

        Y.mix(
            ManageContainer,
            {
                NAME: "ic_manage_container",
                ATTRS: {
                    current: {
                        value: null
                    },
                    previous: {
                        value: null
                    },
                    state: {
                        value: null,
                        setter: function(new_state) {
                            var old_state = Y.HistoryLite.get();
                            // at the container level, 
                            // we wipe out all the history properties to start fresh
                            Y.each(old_state, function (v, k, obj) {
                                obj[k] = null;
                            });
                            var merged_state = Y.merge(old_state, new_state);
                        }
                    }
                }
            }
        );

        Y.extend(
            ManageContainer,
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
                    this.after('stateChange', this._updateFromHistory);
                    Y.on('history-lite:change', Y.bind(this._onHistoryChange, this));
                },

                syncUI: function () {
                    Y.log('container::syncUI');

                    // update the state from the history
                    // this assumes that this is the only one container on the page
                    // and that it's always on the page
                    var bookmarked_state = Y.HistoryLite.get();
                    if (this.isEmpty(bookmarked_state)) bookmarked_state.kind = 'dashboard';
                    this.set('state', bookmarked_state);
                    Y.HistoryLite.add(bookmarked_state);
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
                            return false;
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
                    Y.HistoryLite.add(this.get('state'));
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
                    else {
                        Y.log("Invalid load widget call, unrecognized kind: " + config.kind, "error");
                    }

                    this.set('current', new_widget);
                },

                _updateFromHistory: function (e) {
                    Y.log('container::_updateFromHistory');
                    Y.log('history state: ' + this.get('state'));
                    var state = this.get('state');
                    this._doLoadWidget(state);
                },

                _onHistoryChange: function (e) {
                    Y.log('container::_onHistoryChange');
                    var state = this.get('state');
                    var history = Y.HistoryLite.get();
                    if ( ! this.areEqualObjects(history, state) ) {
                        this.set('state', history);
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
                        alert('sorry! we could not enable/show the widget');
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
                        alert('sorry! we were unable to hide/disable the widget');                        
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
            "ic-manage-widget-dashboard",
            "ic-manage-widget-function",
            "widget"
        ]
    }
);

