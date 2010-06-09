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
                }
            }
        );

        Y.extend(
            ManageContainer,
            Y.Widget,
            {
                _currentWidget: null,
                _cachedWidgets: {},

                initializer: function (config) {
                    Y.log("manage container initializer");

                    var bookmarked_state = Y.History.getBookmarkedState(
                        this.name
                    );
                    var initial_state = bookmarked_state || "dashboard";

                    Y.History.register(
                        this.name, 
                        initial_state
                    ).on("history:moduleStateChange", 
                         Y.bind(this._updateFromHistory, this));

                    this.render(config.render_to);
                },

                destructor: function () {
                    this._currentWidget = null;
                    this._cachedWidgets = null;
                },

                renderUI: function () {
                    // should probably be following the attrs/render/bind/sync pattern, no?
                },

                loadWidget: function (config) {
                    Y.log("container's loadWidget called: " + config);
                    Y.log("loadWidget this: " + this);
                    Y.log("loadWidget kind: " + config.kind);
                    Y.log("loadWidget sub_kind: " + config.sub_kind);
                    Y.log("loadWidget args: " + config.args);
                    var previous_widget = this._currentWidget,
                        new_widget = null
                    ;

                    if (config.kind === "dashboard") {
                        if (! this._cachedWidgets["dashboard"]) {
                            Y.log("instantiating dashboard...");
                            this._cachedWidgets["dashboard"] = new Y.IC.ManageDashboard();
                            this._cachedWidgets["dashboard"].render( this.get("contentBox") );
                        }

                        new_widget = this._cachedWidgets["dashboard"];
                    }
                    else if (config.kind === "function") {
                        if (! this._cachedWidgets[config.args]) {
                            Y.log("instantiating function: " + config.args + "...");
                            var splits     = config.args.split("-", 2);
                            var code       = splits[0];
                            Y.log("code: " + code);
                            if (config.sub_kind === "list") {
                                this._cachedWidgets[config.args] = new Y.IC.ManageFunctionList(
                                    {
                                        code: code,
                                    }
                                );
                                this._cachedWidgets[config.args].render( this.get("contentBox") );
                                this._cachedWidgets[config.args].hide();
                            }
                            else if (config.sub_kind === "detail") {
                                var addtl_args = splits[1] + "";
                                Y.log("addtl_args: " + addtl_args);
                                this._cachedWidgets[config.args] = new Y.IC.ManageFunctionDetail(
                                    {
                                        code: code,
                                        addtl_args: addtl_args
                                    }
                                );
                                this._cachedWidgets[config.args].render( this.get("contentBox") );
                                this._cachedWidgets[config.args].hide();
                            }
                            else {
                            }
                        }

                        new_widget = this._cachedWidgets[config.args];
                    }
                    else {
                        Y.log("Invalid load widget call, unrecognized kind: " + config.kind, "error");
                    }

                    new_widget.enable();

                    // only want to do these if we are reasonably confident
                    // that our new widget will succeed
                    Y.log("previous widget: " + previous_widget);
                    if (previous_widget) {
                        Y.log("hiding previous_widget: " + previous_widget);
                        previous_widget.hide();
                        previous_widget.disable();
                    }

                    this._currentWidget = new_widget;
                    this._currentWidget.show();
                },

                _updateFromHistory: function (state) {
                    Y.log('history state: ' + state);
                    if (state === "dashboard") {
                        // the initial widget will always be the dashboard
                        Y.log(this);
                        this.loadWidget(
                            {
                                kind: "dashboard"
                            }
                        );
                    }
                    else {
                        Y.log(this);
                        this.loadWidget(Y.QueryString.parse(state));
                    }

                },

                _doLoadWidget: function (e) {
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
                    Y.History.navigate(
                        this.name, 
                        Y.QueryString.stringify(load_widget_config)
                    );
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

