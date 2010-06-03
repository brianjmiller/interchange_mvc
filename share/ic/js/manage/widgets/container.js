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

                    // the initial widget will always be the dashboard
                    this.loadWidget("manage_menu_item-dashboard");

                    this.render(config.render_to);
                },

                destructor: function () {
                    this._currentWidget = null;
                    this._cachedWidgets = null;
                },

                renderUI: function () {
                    Y.log("showing currentWidget: " + this._currentWidget);
                    this._currentWidget.show();
                },

                loadWidget: function (config) {
                    Y.log("container's loadWidget called: " + config);
                    Y.log("loadWidget this: " + this);
                    var previous_widget = this._currentWidget,
                        new_widget = null
                    ;

                    if (config === "manage_menu_item-dashboard") {
                        if (! this._cachedWidgets["dashboard"]) {
                            Y.log("instantiating dashboard...");
                            this._cachedWidgets["dashboard"] = new Y.IC.ManageDashboard();
                            this._cachedWidgets["dashboard"].render( this.get("contentBox") );
                        }

                        new_widget = this._cachedWidgets["dashboard"];
                    }
                    else {
                        Y.log("invalid load widget config, keeping current widget");
                        if (! this._cachedWidgets[config]) {
                            Y.log("instantiating function: " + config + "...");
                            var code = config.split("-")[2];
                            this._cachedWidgets[config] = new Y.IC.ManageFunction(
                                {
                                    code: code,
                                    constrain: this.get("contentBox")
                                }
                            );
                            this._cachedWidgets[config].render( this.get("contentBox") );
                            this._cachedWidgets[config].hide();
                        }

                        new_widget = this._cachedWidgets[config];

                        //return;
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

                _handleLoadWidget: function (e) {
                    this.loadWidget(e.target.get("id"));
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

